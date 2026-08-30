function out = rotor_m1_hover_model_form(P, pitchCommand, cfg)
%ROTOR_M1_HOVER_MODEL_FORM Parameterized M1 hover model-form core.
%
% This function separates MODEL FORM from VALIDATION INSTANCE parameters.
% It is intentionally hover-only. It must not be called as a forward-flight,
% conversion, or airplane-mode rotor backend.
%
% cfg.instanceType:
%   'XV15_VALIDATION_INSTANCE' - source-informed XV-15 radial geometry,
%       four-region C81, Corrigan n=1. pitchCommand is theta75 [rad].
%   'GENERIC_NOMINAL_INSTANCE' - reads only the supplied generic P rotor
%       geometry/aero fields. pitchCommand is the existing generic root
%       collective [rad]. cfg.corriganMode may be 'OFF' or 'N1'.
%
% No OARF/WADC target is read by this function.

if nargin < 3 || ~isstruct(cfg) || ~isfield(cfg,'instanceType')
    error('rotor_m1_hover_model_form:ConfigurationRequired', ...
        'Explicit cfg.instanceType is required.');
end
if ~(isscalar(pitchCommand) && isnumeric(pitchCommand) && ...
        isreal(pitchCommand) && isfinite(pitchCommand))
    error('rotor_m1_hover_model_form:InvalidPitch', ...
        'pitchCommand must be a finite real scalar in radians.');
end

instanceType = upper(char(cfg.instanceType));
Pwork = P;
if ~isfield(Pwork.env,'aSound') || isempty(Pwork.env.aSound)
    Pwork.env.aSound = 340.0;
end
corriganMode = 'N1';
if isfield(cfg,'corriganMode') && ~isempty(cfg.corriganMode)
    corriganMode = upper(char(cfg.corriganMode));
end

switch instanceType
    case 'XV15_VALIDATION_INSTANCE'
        if ~strcmp(corriganMode,'N1')
            error('rotor_m1_hover_model_form:FrozenXV15Mode', ...
                'Frozen XV-15 validation identity requires Corrigan N1.');
        end
        Pwork.rotor.R = 3.81;
        Pwork.rotor.Nb = 3;
        Pwork.rotor.rootCut = 0.0875;
        Pwork.rotor.Ib = Pwork.rotor.bladeMass*Pwork.rotor.R^2/3;
        Pwork.rotor.Sblade = Pwork.rotor.bladeMass*Pwork.rotor.R/2;
        aeroMode = 'XV15_C81_CORRIGAN_N1';
        pitchReference = 'THETA75';
    case 'GENERIC_NOMINAL_INSTANCE'
        if ~any(strcmp(corriganMode,{'OFF','N1'}))
            error('rotor_m1_hover_model_form:InvalidCorriganMode', ...
                'Generic cfg.corriganMode must be OFF or N1.');
        end
        required = {'R','Nb','rootCut','chord','twistTip','liftSlope', ...
            'CLmax','CD0','kCD','Omega','nRadial','nAzimuth'};
        for k = 1:numel(required)
            if ~isfield(Pwork.rotor,required{k})
                error('rotor_m1_hover_model_form:MissingGenericParameter', ...
                    'Generic P.rotor.%s is required.',required{k});
            end
        end
        if strcmp(corriganMode,'OFF')
            aeroMode = 'GENERIC_SCALAR_OFF';
        else
            aeroMode = 'GENERIC_SCALAR_CORRIGAN_N1';
        end
        pitchReference = 'ROOT_COLLECTIVE';
    otherwise
        error('rotor_m1_hover_model_form:InvalidInstanceType', ...
            'Unknown cfg.instanceType: %s',instanceType);
end

R = Pwork.rotor.R;
Omega = Pwork.rotor.Omega;
tipSpeed = Omega*R;
rho = Pwork.env.rho;
A = pi*R^2;
r0 = Pwork.rotor.rootCut*R;
rEdges = linspace(r0,R,Pwork.rotor.nRadial+1);
rMid = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
psi = ((0:Pwork.rotor.nAzimuth-1)*(2*pi/Pwork.rotor.nAzimuth)).';
x = rMid/R;

switch instanceType
    case 'XV15_VALIDATION_INSTANCE'
        chord_in = 14*ones(size(x));
        inboard = x <= 0.25;
        chord_in(inboard) = -18.4615*x(inboard)+18.6154;
        chord_m = chord_in*0.0254;
        thetaSource_deg = nasa_metal_twist_deg(x);
        theta75Source_deg = nasa_metal_twist_deg(0.75);
        thetaBlade = pitchCommand + ...
            (thetaSource_deg-theta75Source_deg)*pi/180;
    case 'GENERIC_NOMINAL_INSTANCE'
        chord_m = Pwork.rotor.chord*ones(size(x));
        twist = Pwork.rotor.twistTip*(rMid-r0)/max(R-r0,eps);
        thetaBlade = pitchCommand + twist;
end
UT = Omega*rMid;

vi = sqrt(max(Pwork.mass.m*Pwork.env.g/2,1)/(2*rho*A));
zFlap = Pwork.rotor.flapInitial(:);
converged = false;
flapInfo = struct('converged',false,'iterations',0,'residualNorm',Inf);
for iter = 1:Pwork.rotor.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged, break; end
    loads = blade_loads(vi,zFlap);
    lambda1 = -vi/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget = tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
    viNew = 0.5*(vi+viTarget);
    err = abs(viNew-vi)/max(1,abs(vi));
    vi = viNew;
    if err < Pwork.rotor.inducedTol && ...
            flapInfo.residualNorm <= Pwork.rotor.flapResidualTol
        converged = true;
        break;
    end
end
loads = blade_loads(vi,zFlap);
lambda1 = -vi/max(tipSpeed,eps);
momentumThrust = 2*rho*A*tipSpeed*vi*abs(lambda1);
closure = abs(loads.T-momentumThrust)/ ...
    max([abs(loads.T),abs(momentumThrust),1]);
physical = converged && flapInfo.converged && loads.T > 0 && closure <= 2e-4;

out.instanceType = instanceType;
out.modelForm = 'M1_HOVER_RADIAL_BEMT_OPTIONAL_CORRIGAN_N1';
out.corriganMode = corriganMode;
out.pitchReference = pitchReference;
out.pitchCommand = pitchCommand;
out.thrust = loads.T;
out.torque = loads.Q;
out.power = loads.Q*Omega;
out.inducedVelocity = vi;
out.beta0 = zFlap(1);
out.beta1c = zFlap(2);
out.beta1s = zFlap(3);
out.physicalConverged = physical;
out.flapConverged = flapInfo.converged;
out.iterations = iter;
out.inducedClosureResidualRelative = closure;
out.CT = loads.T/(rho*A*tipSpeed^2);
out.CP = loads.Q*Omega/(rho*A*tipSpeed^3);
out.FM = NaN;
if out.CT > 0 && out.CP > 0
    out.FM = out.CT^(3/2)/(sqrt(2)*out.CP);
end
out.KLMinApplied = loads.KLMinApplied;
out.KLMaxApplied = loads.KLMaxApplied;
out.alphaClampCount = loads.alphaClampCount;
out.machClampCount = loads.machClampCount;
out.parameterBoundary = parameter_boundary(instanceType,corriganMode);

    function [z,info] = solve_flap(viNow,z0)
        z = z0(:);
        info = struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk = 1:Pwork.rotor.flapMaxIter
            [res,scale] = flap_residual(z,viNow);
            rn = res/scale;
            if norm(rn) <= Pwork.rotor.flapResidualTol
                info.converged = true;
                info.iterations = kk;
                info.residualNorm = norm(rn);
                return;
            end
            J = zeros(3,3);
            for jj = 1:3
                h = Pwork.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp=z; zm=z; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow);
                [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+Pwork.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
            step=1; accepted=false;
            for trial=1:Pwork.rotor.flapLineSearchMaxIter
                zc=z+step*dz;
                betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && ...
                        max(abs(betaCheck))<Pwork.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn)
                        z=zc; accepted=true; break;
                    end
                end
                step=step*Pwork.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow);
        info.iterations=Pwork.rotor.flapMaxIter;
        info.residualNorm=norm(res/scale);
    end

    function [res,scale] = flap_residual(z,viNow)
        ll=blade_loads(viNow,z);
        gravityMoment=-Pwork.rotor.Sblade*Pwork.env.g*cos(ll.beta);
        inertialRestoring=Pwork.rotor.Ib*ll.betaDDot+ ...
            Pwork.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)), ...
            max(abs(gravityMoment)),Pwork.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll = blade_loads(viNow,z)
        beta=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDot=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDot=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDot.*rMid;
        W=hypot(UT,UP);
        phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi;
        Mach=W/Pwork.env.aSound;
        chordField=ones(size(alpha)).*chord_m;
        rField=ones(size(alpha)).*x;
        switch aeroMode
            case 'XV15_C81_CORRIGAN_N1'
                [CL,CD,meta]=xv15_c81_corrigan_stall_delay( ...
                    alpha,Mach,rField,chordField,R,'CORRIGAN_GENERIC_N1');
                alphaClampCount=meta.alphaClampCount;
                machClampCount=meta.machClampCount;
                KLMinApplied=meta.KLMinApplied;
                KLMaxApplied=meta.KLMaxApplied;
            case {'GENERIC_SCALAR_OFF','GENERIC_SCALAR_CORRIGAN_N1'}
                CLbase=Pwork.rotor.CLmax*tanh( ...
                    Pwork.rotor.liftSlope*alpha/Pwork.rotor.CLmax);
                CD=Pwork.rotor.CD0+Pwork.rotor.kCD*CLbase.^2;
                CL=CLbase;
                KLMinApplied=1; KLMaxApplied=1;
                if strcmp(aeroMode,'GENERIC_SCALAR_CORRIGAN_N1')
                    r_m=max(rField*R,1e-8);
                    KL=1.291*(chordField./r_m).^0.0775;
                    alphaDeg=alpha*180/pi;
                    apply=alphaDeg>0 & alphaDeg<30 & CLbase>0;
                    CL(apply)=KL(apply).*CLbase(apply);
                    if any(apply(:))
                        KLMinApplied=min(KL(apply));
                        KLMaxApplied=max(KL(apply));
                    end
                end
                alphaClampCount=0;
                machClampCount=0;
        end
        q=0.5*rho*W.^2;
        dL=q.*chord_m.*CL.*dr;
        dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi);
        dH=dD.*cos(phi)+dL.*sin(phi);
        dQ=dH.*rMid;
        factor=Pwork.rotor.Nb/Pwork.rotor.nAzimuth;
        ll.T=factor*sum(dT(:));
        ll.Q=factor*sum(dQ(:));
        ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=beta;
        ll.betaDDot=betaDDot;
        ll.alphaClampCount=alphaClampCount;
        ll.machClampCount=machClampCount;
        ll.KLMinApplied=KLMinApplied;
        ll.KLMaxApplied=KLMaxApplied;
    end
end

function theta_deg=nasa_metal_twist_deg(x)
theta_deg=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end

function txt=parameter_boundary(instanceType,corriganMode)
if strcmp(instanceType,'XV15_VALIDATION_INSTANCE')
    txt=['XV15_VALIDATION_PARAMETERS_ONLY_DO_NOT_EXPORT_TO_GENERIC_AIRCRAFT_' ...
        'HOVER_ONLY'];
elseif strcmp(corriganMode,'OFF')
    txt='GENERIC_PARAMS_NOMINAL_M0_LIMIT_IDENTITY_CHECK_HOVER_ONLY';
else
    txt=['GENERIC_PARAMS_NOMINAL_ONLY_CORRIGAN_N1_MODEL_FORM_TRANSFER_' ...
        'NOT_XV15_AIRCRAFT_VALIDATION_HOVER_ONLY'];
end
end
