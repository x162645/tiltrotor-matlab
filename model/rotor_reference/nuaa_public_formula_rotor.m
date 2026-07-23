function [Fbody,Mbody,out] = nuaa_public_formula_rotor( ...
        x,rotorCtrl,betaM,side,cgShift,P,options)
%NUAA_PUBLIC_FORMULA_ROTOR Independent opt-in public-formula reference.
% Internal model id: NUAA_PUBLIC_FORMULA_REFERENCE.
%
% This implementation follows Sheng et al., Drones 2022, PDF/original
% pages 4-5, Eqs. (4)-(15).  The paper does not publish a complete author
% program.  Every necessary closure is exposed in out.closureClasses and
% documented in docs/NUAA_ROTOR_FORMULA_AUDIT.md.
%
% Body axes: x forward, y right, z down. betaM=0 helicopter mode and
% betaM=pi/2 airplane mode. side=-1 left, side=+1 right. All units are SI.

if nargin < 7
    options = struct();
end
x = x(:);
cgShift = cgShift(:);
if numel(x) < 9 || any(~isfinite(x(1:9))) || ~isreal(x(1:9))
    error('nuaa_public_formula_rotor:InvalidState', ...
        'x must contain at least nine finite real states.');
end
if numel(cgShift) ~= 3 || any(~isfinite(cgShift)) || ~isreal(cgShift)
    error('nuaa_public_formula_rotor:InvalidCgShift', ...
        'cgShift must be a finite real 3-vector.');
end
if ~(side == -1 || side == 1)
    error('nuaa_public_formula_rotor:InvalidSide', ...
        'side must be -1 (left) or +1 (right).');
end
requiredControls = {'collective','cyclicLong'};
for kRequired = 1:numel(requiredControls)
    nameRequired = requiredControls{kRequired};
    if ~isfield(rotorCtrl,nameRequired) || ...
            ~isscalar(rotorCtrl.(nameRequired)) || ...
            ~isfinite(rotorCtrl.(nameRequired)) || ...
            ~isreal(rotorCtrl.(nameRequired))
        error('nuaa_public_formula_rotor:InvalidControl', ...
            'rotorCtrl.%s must be a finite real scalar.',nameRequired);
    end
end

cfg.nRadial = option_value(options,'nRadial',P.rotor.nRadial);
cfg.nAzimuth = option_value(options,'nAzimuth',P.rotor.nAzimuth);
% The public Eq. (13) half-step is retained exactly. Its slower fixed-point
% convergence is given a reference-only iteration budget; this changes no
% aircraft parameter and never alters the production solver.
cfg.inducedMaxIter = option_value(options,'inducedMaxIter', ...
    max(P.rotor.inducedMaxIter,80));
cfg.inducedTol = option_value(options,'inducedTol',P.rotor.inducedTol);
cfg.flapMaxIter = option_value(options,'flapMaxIter',P.rotor.flapMaxIter);
cfg.flapResidualTol = option_value(options,'flapResidualTol', ...
    P.rotor.flapResidualTol);
cfg.flapJacobianStep = option_value(options,'flapJacobianStep', ...
    P.rotor.flapJacobianStep);
cfg.flapNewtonRegularization = option_value(options, ...
    'flapNewtonRegularization',P.rotor.flapNewtonRegularization);
cfg.flapNewtonDamping = option_value(options,'flapNewtonDamping', ...
    P.rotor.flapNewtonDamping);
cfg.flapLineSearchMaxIter = option_value(options, ...
    'flapLineSearchMaxIter',P.rotor.flapLineSearchMaxIter);
cfg.flapDivergenceAngle = option_value(options,'flapDivergenceAngle', ...
    P.rotor.flapDivergenceAngle);
validate_numerical_config(cfg);

Vbody = x(1:3);
omegaBody = x(4:6);
phiBody = x(7);
thetaBody = x(8);
rotDir = side;

% Equivalent of the paper hub/rotor transforms in the project convention.
eT = [sin(betaM);0;-cos(betaM)];
eD = [cos(betaM);0;sin(betaM)];
eY = [0;1;0];
rHub0 = [P.rotor.pivotX+P.rotor.RH_hub*sin(betaM); ...
         side*P.rotor.pivotY; ...
         P.rotor.pivotZ-P.rotor.RH_hub*cos(betaM)];
rHub = rHub0-cgShift;
Vhub = Vbody+cross(omegaBody,rHub);
Vaxial = dot(Vhub,eT);
Vdisk = Vhub-Vaxial*eT;
Vplane = norm(Vdisk);

% Eq. (5) wind-axis closure. At zero in-plane speed the wind axis is +eD.
if Vplane > 1e-10
    eWind = Vdisk/Vplane;
else
    eWind = eD;
end
eSideWind = -cross(eT,eWind);
eSideWind = eSideWind/max(norm(eSideWind),eps);
tipSpeed = P.rotor.Omega*P.rotor.R;
mu = Vplane/max(tipSpeed,eps);
lambda0 = -Vaxial/max(tipSpeed,eps);
A = pi*P.rotor.R^2;

% Same-parameter-first initial value; it is a numerical initial guess only.
vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*P.env.rho*A));
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('nuaa_public_formula_rotor:InvalidFlapInitial', ...
        'P.rotor.flapInitial must be [beta0;beta1c;beta1s].');
end

coupledConverged = false;
inducedHistory = NaN(cfg.inducedMaxIter,5);
flapInfo = empty_flap_info();
for inducedIter = 1:cfg.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged
        error('nuaa_public_formula_rotor:FlapNotConverged', ...
            ['Public-formula harmonic flapping solve failed on side %+d: ' ...
             '%s, residual %.3e.'],side,flapInfo.exitStatus, ...
            flapInfo.residualNorm);
    end
    loads = blade_loads(vi,zFlap);

    % Eqs. (12)-(13). CT normalization is an explicitly documented closure.
    CT = loads.T/(0.5*P.env.rho*A*tipSpeed^2);
    lambda1 = lambda0-vi/max(tipSpeed,eps);
    denominator = sqrt(lambda1^2+mu^2);
    denominatorUsed = max(denominator,1e-12);
    if CT < 0
        error('nuaa_public_formula_rotor:NegativeThrustUnsupported', ...
            ['Eqs. (12)-(13) do not publish a negative-thrust/windmill ' ...
             'branch. side=%+d, CT=%.6g.'],side,CT);
    end
    viTarget = tipSpeed*CT/(4*denominatorUsed);
    viNew = 0.5*(vi+viTarget); % exact half-step update stated after Eq. (13)
    viError = abs(viNew-vi)/max(1,abs(vi));
    inducedHistory(inducedIter,:) = ...
        [vi,viTarget,viNew,viError,flapInfo.residualNorm];
    vi = viNew;
    if viError <= cfg.inducedTol && ...
            flapInfo.residualNorm <= cfg.flapResidualTol
        coupledConverged = true;
        break;
    end
end
if ~coupledConverged
    error('nuaa_public_formula_rotor:InducedNotConverged', ...
        ['Public-formula induced/flap iteration failed on side %+d: ' ...
         'vi error %.3e, flap residual %.3e.'], ...
        side,viError,flapInfo.residualNorm);
end
loads = blade_loads(vi,zFlap);

beta0 = zFlap(1);
beta1c = zFlap(2);
beta1s = zFlap(3);
nDiskRaw = eT-beta1c*eWind-rotDir*beta1s*eSideWind;
nDisk = nDiskRaw/max(norm(nDiskRaw),eps);
FinPlane = loads.Hwind*eWind+loads.Hside*eSideWind;
Fbody = loads.T*nDisk+FinPlane;

% Eqs. (14)-(15): explicit basis transform and actual-CG arm moment.
Mreaction = -rotDir*loads.Q*eT;
Marm = cross(rHub,Fbody);
Mbody = Marm+Mreaction;

out.modelId = 'NUAA_PUBLIC_FORMULA_REFERENCE';
out.modelNameZh = '南航公开公式旋翼参考模型';
out.defaultRotorPathModified = false;
out.claimBoundary = ['PUBLIC_FORMULA_REFERENCE_WITH_DOCUMENTED_CLOSURES_' ...
    'NOT_AUTHOR_CODE_NOT_XV15_NOT_VALIDATED'];
out.side = side;
out.rotDir = rotDir;
out.rHub = rHub;
out.Vhub = Vhub;
out.Vaxial = Vaxial;
out.Vplane = Vplane;
out.mu = mu;
out.muLong = dot(Vhub,eD)/max(tipSpeed,eps);
out.muLat = dot(Vhub,eY)/max(tipSpeed,eps);
out.lambda0 = lambda0;
out.lambda1 = lambda0-vi/tipSpeed;
out.eT = eT;
out.eD = eD;
out.eY = eY;
out.eWind = eWind;
out.eSideWind = eSideWind;
out.basisOrthogonalityError = ...
    max(max(abs([eT,eWind,eSideWind].'*[eT,eWind,eSideWind]-eye(3))));
out.beta0 = beta0;
out.beta1c = beta1c;
out.beta1s = beta1s;
out.zFlap = zFlap;
out.theta1c = 0;
out.theta1s = -rotDir*rotorCtrl.cyclicLong;
out.nDisk = nDisk;
out.eTeff = nDisk;
out.thrust = loads.T;
out.torque = loads.Q;
out.Hwind = loads.Hwind;
out.Hside = loads.Hside;
out.Hlong = dot(FinPlane,eD);
out.Hlat = dot(FinPlane,eY);
out.inducedVelocity = vi;
out.inducedVelocityField = loads.viField;
out.inducedVelocityError = viError;
out.inducedIterations = inducedIter;
out.inducedHistory = inducedHistory(1:inducedIter,:);
out.inducedConverged = coupledConverged;
out.flap = flapInfo;
out.minUT = loads.minUT;
out.maxUT = loads.maxUT;
out.maxAbsAlphaBlade = loads.maxAbsAlphaBlade;
out.CT = loads.T/(0.5*P.env.rho*A*tipSpeed^2);
out.CQ = loads.Q/(0.5*P.env.rho*A*tipSpeed^2*P.rotor.R);
out.CH = out.Hlong/(0.5*P.env.rho*A*tipSpeed^2);
out.CS = out.Hlat/(0.5*P.env.rho*A*tipSpeed^2);
out.Marm = Marm;
out.Mreaction = Mreaction;
out.Mgyro = zeros(3,1);
out.Hrot = zeros(3,1);
out.F = Fbody;
out.M = Mbody;
out.grid = struct('nRadial',cfg.nRadial,'nAzimuth',cfg.nAzimuth);
out.closureClasses = struct( ...
    'equations4to15','EXACT_PUBLIC_FORMULA', ...
    'airfoilPolar','SHARED_CURRENT_PARAMETER', ...
    'bladeMassDistribution','ASSUMED_MODEL_PARAMETER', ...
    'harmonicBalance','NUMERICAL_IMPLEMENTATION_CHOICE', ...
    'hubWindAxis','STANDARD_CLOSURE', ...
    'elementProjection','STANDARD_CLOSURE', ...
    'negativeThrust','NOT_IMPLEMENTED');

    function [z,info] = solve_flap(viMean,z0)
        z = z0(:);
        info = empty_flap_info();
        for flapIter = 1:cfg.flapMaxIter
            [residual,aux] = flap_residual(z,viMean);
            scaled = residual/aux.scale;
            residualNorm = norm(scaled);
            info.iterations = flapIter;
            info.residual = residual;
            info.residualNorm = residualNorm;
            info.scale = aux.scale;
            if residualNorm <= cfg.flapResidualTol
                info.converged = true;
                info.exitStatus = 'converged';
                info.residualByAzimuth = aux.residualByAzimuth;
                info.aeroMomentByAzimuth = aux.aeroMomentByAzimuth;
                info.gravityMomentByAzimuth = aux.gravityMomentByAzimuth;
                return;
            end
            J = zeros(3,3);
            for j = 1:3
                h = cfg.flapJacobianStep*max(1,abs(z(j)));
                zp = z; zm = z;
                zp(j) = zp(j)+h;
                zm(j) = zm(j)-h;
                rp = flap_residual(zp,viMean);
                rm = flap_residual(zm,viMean);
                J(:,j) = (rp-rm)/(2*h*aux.scale);
            end
            if any(~isfinite(J(:))) || rcond(J.'*J) < 1e-14
                info.exitStatus = 'singular_jacobian';
                return;
            end
            dz = -(J.'*J+cfg.flapNewtonRegularization*eye(3))\ ...
                (J.'*scaled);
            alpha = 1;
            accepted = false;
            for lineIter = 1:cfg.flapLineSearchMaxIter
                zCandidate = z+alpha*dz;
                if valid_flap(zCandidate)
                    [candidateResidual,candidateAux] = ...
                        flap_residual(zCandidate,viMean);
                    if norm(candidateResidual/candidateAux.scale) < ...
                            residualNorm
                        z = zCandidate;
                        accepted = true;
                        break;
                    end
                end
                alpha = alpha*cfg.flapNewtonDamping;
            end
            if ~accepted
                info.exitStatus = 'line_search_failed';
                return;
            end
        end
        [residual,aux] = flap_residual(z,viMean);
        info.iterations = cfg.flapMaxIter;
        info.residual = residual;
        info.residualNorm = norm(residual/aux.scale);
        info.scale = aux.scale;
        info.exitStatus = 'max_iter';
    end

    function tf = valid_flap(z)
        psiCheck = azimuth_grid();
        betaCheck = z(1)+z(2)*cos(psiCheck)+z(3)*sin(psiCheck);
        tf = all(isfinite(z)) && ...
            max(abs(betaCheck)) < cfg.flapDivergenceAngle;
    end

    function [residual,aux] = flap_residual(z,viMean)
        localLoads = blade_loads(viMean,z);
        beta = localLoads.beta;
        gBody = P.env.g*[-sin(thetaBody); ...
            sin(phiBody)*cos(thetaBody); ...
            cos(phiBody)*cos(thetaBody)];
        gT = dot(gBody,eT);
        gWind = dot(gBody,eWind);
        gSide = dot(gBody,eSideWind);
        gRadial = gWind*cos(localLoads.psi)+ ...
            rotDir*gSide*sin(localLoads.psi);
        gravityMoment = P.rotor.Sblade* ...
            (-sin(beta).*gRadial+cos(beta).*gT);
        inertialRestoring = P.rotor.Ib*localLoads.betaDDot+ ...
            P.rotor.Ib*P.rotor.Omega^2*beta;
        residualByAzimuth = inertialRestoring- ...
            localLoads.flapMomentByAzimuth-gravityMoment;
        residual = [mean(residualByAzimuth); ...
            2*mean(residualByAzimuth.*cos(localLoads.psi)); ...
            2*mean(residualByAzimuth.*sin(localLoads.psi))];
        scale = max([max(abs(localLoads.flapMomentByAzimuth)), ...
            max(abs(gravityMoment)), ...
            P.rotor.Ib*P.rotor.Omega^2*0.05,1]);
        aux.scale = scale;
        aux.residualByAzimuth = residualByAzimuth;
        aux.aeroMomentByAzimuth = localLoads.flapMomentByAzimuth;
        aux.gravityMomentByAzimuth = gravityMoment;
    end

    function loads = blade_loads(viMean,z)
        r0 = P.rotor.rootCut*P.rotor.R;
        edges = linspace(r0,P.rotor.R,cfg.nRadial+1);
        rMid = 0.5*(edges(1:end-1)+edges(2:end));
        dr = diff(edges);
        psi = azimuth_grid().';
        beta = z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDot = P.rotor.Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDot = -P.rotor.Omega^2* ...
            (z(2)*cos(psi)+z(3)*sin(psi));
        twist = P.rotor.twistTip*(rMid-r0)/max(P.rotor.R-r0,eps);
        theta1s = -rotDir*rotorCtrl.cyclicLong;
        thetaBlade = rotorCtrl.collective+twist+theta1s*sin(psi);

        % Eqs. (6), (7) and (12) in paper wind-axis coordinates.
        UT = P.rotor.Omega*rMid+rotDir*Vplane*sin(psi);
        viField = viMean.*(1+(rMid/P.rotor.R).*cos(psi));
        UPpaper = tipSpeed*(lambda0-mu.*beta.*cos(psi))- ...
            viField-rMid.*betaDot;
        betaStar = atan2(-UPpaper,UT);
        W2 = UT.^2+UPpaper.^2;
        alphaBlade = thetaBlade-betaStar;

        Cy = P.rotor.CLmax*tanh( ...
            P.rotor.liftSlope*alphaBlade/P.rotor.CLmax);
        Cx = P.rotor.CD0+P.rotor.kCD*Cy.^2;
        dY = 0.5*P.env.rho*W2*P.rotor.chord.*dr;
        dY = dY.*Cy;
        dX = 0.5*P.env.rho*W2*P.rotor.chord.*dr;
        dX = dX.*Cx;
        dT = dY.*cos(betaStar)-dX.*sin(betaStar);
        dQforce = dX.*cos(betaStar)+dY.*sin(betaStar);
        dQmoment = dQforce.*rMid;

        % Standard vector closure for the unpublished dHs/dSs projection.
        etWind = -rotDir*sin(psi);
        etSide = cos(psi);
        HwindByElement = -dQforce.*etWind;
        HsideByElement = -dQforce.*etSide;
        factor = P.rotor.Nb/cfg.nAzimuth;
        loads.T = factor*sum(dT(:));
        loads.Q = factor*sum(dQmoment(:));
        loads.Hwind = factor*sum(HwindByElement(:));
        loads.Hside = factor*sum(HsideByElement(:));
        loads.flapMomentByAzimuth = sum(dT.*rMid,2);
        loads.beta = beta;
        loads.betaDot = betaDot;
        loads.betaDDot = betaDDot;
        loads.psi = psi;
        loads.rMid = rMid;
        loads.viField = viField;
        loads.minUT = min(UT(:));
        loads.maxUT = max(UT(:));
        loads.maxAbsAlphaBlade = max(abs(alphaBlade(:)));
    end

    function psi = azimuth_grid()
        psi = (0:cfg.nAzimuth-1)*(2*pi/cfg.nAzimuth);
    end
end

function value = option_value(options,name,defaultValue)
if isfield(options,name) && ~isempty(options.(name))
    value = options.(name);
else
    value = defaultValue;
end
end

function validate_numerical_config(cfg)
integerFields = {'nRadial','nAzimuth','inducedMaxIter','flapMaxIter', ...
    'flapLineSearchMaxIter'};
for k = 1:numel(integerFields)
    value = cfg.(integerFields{k});
    if ~(isscalar(value) && isfinite(value) && value >= 2 && ...
            value == floor(value))
        error('nuaa_public_formula_rotor:InvalidNumericalConfig', ...
            '%s must be an integer of at least two.',integerFields{k});
    end
end
positiveFields = {'inducedTol','flapResidualTol','flapJacobianStep', ...
    'flapNewtonRegularization','flapNewtonDamping', ...
    'flapDivergenceAngle'};
for k = 1:numel(positiveFields)
    value = cfg.(positiveFields{k});
    if ~(isscalar(value) && isfinite(value) && value > 0)
        error('nuaa_public_formula_rotor:InvalidNumericalConfig', ...
            '%s must be a finite positive scalar.',positiveFields{k});
    end
end
end

function info = empty_flap_info()
info = struct('converged',false,'iterations',0, ...
    'residual',NaN(3,1),'residualNorm',Inf,'scale',NaN, ...
    'exitStatus','not_started','residualByAzimuth',[], ...
    'aeroMomentByAzimuth',[],'gravityMomentByAzimuth',[]);
end
