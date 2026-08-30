function [Fbody,Mbody,out] = m1_evidence_v1_forward_rotor( ...
        x,rotorCtrl,betaM,side,cgShift,P)
%M1_EVIDENCE_V1_FORWARD_ROTOR Analysis-only forward-flight propagation.
%
% This is NOT a newly validated forward-flight rotor.  It extends the frozen
% M1_EVIDENCE_V1 rotor ingredients through the already-reviewed production
% forward-flight kinematics / Eq.(12)-Eq.(13) low-order structure so that the
% effect of the frozen hover evidence package can be propagated into the
% generic whole-aircraft model.
%
% Frozen M1 ingredients retained:
%   - source-informed radial chord distribution;
%   - nonlinear metal-blade twist, anchored by physical theta75;
%   - NASA-TP four-region C81/local-Mach lookup;
%   - Corrigan n=1 predeclared in-range rotational augmentation;
%   - global momentum induced-velocity closure (not annular M1-C).
%
% Important: an exact zero-speed/zero-cyclic helicopter-hover call is routed
% through an exact copy of the frozen Stage-3 hover equations.  This is an
% identity anchor, not evidence that the forward extension is independently
% validated or mathematically smooth at V=0.  Strict-hover beta1 is not used
% as a physical lateral-load observable; the anchor returns axial thrust and
% reaction torque only, consistent with the completed Eq.(12) limit audit.

x = x(:);
cgShift = cgShift(:);
if numel(x) < 9 || numel(cgShift) ~= 3
    error('m1_evidence_v1_forward_rotor:InvalidInput','Invalid x or cgShift size.');
end
if ~(side == -1 || side == 1)
    error('m1_evidence_v1_forward_rotor:InvalidSide','side must be -1 or +1.');
end
if ~isfield(rotorCtrl,'collective') || ~isfield(rotorCtrl,'cyclicLong')
    error('m1_evidence_v1_forward_rotor:InvalidControl', ...
        'rotorCtrl requires collective and cyclicLong.');
end
if ~isfield(P.env,'aSound') || ~(isfinite(P.env.aSound) && P.env.aSound>0)
    error('m1_evidence_v1_forward_rotor:InvalidSoundSpeed','P.env.aSound required.');
end

Vbody = x(1:3);
omegaBody = x(4:6);
phiBody = x(7);
thetaBody = x(8);
rotDir = side;
R = P.rotor.R;
Omega = P.rotor.Omega;
tipSpeed = Omega*R;
rho = P.env.rho;
A = pi*R^2;

eT = [sin(betaM);0;-cos(betaM)];
eD = [cos(betaM);0; sin(betaM)];
eY = [0;1;0];
rHub0 = [P.rotor.pivotX+P.rotor.RH_hub*sin(betaM); ...
         side*P.rotor.pivotY; ...
         P.rotor.pivotZ-P.rotor.RH_hub*cos(betaM)];
rHub = rHub0-cgShift;
Vhub = Vbody+cross(omegaBody,rHub);
Vaxial = dot(Vhub,eT);
Vlong = dot(Vhub,eD);
Vlat = dot(Vhub,eY);
muLong = Vlong/max(tipSpeed,eps);
muLat = Vlat/max(tipSpeed,eps);
mu = hypot(Vlong,Vlat)/max(tipSpeed,eps);

% Common aircraft control coordinate -> physical pitch at 0.75R under the
% matched M0 linear-twist parameterization.
x75Linear = (0.75-P.rotor.rootCut)/max(1-P.rotor.rootCut,eps);
theta75 = rotorCtrl.collective + P.rotor.twistTip*x75Linear;

exactHoverAnchor = norm(Vbody) <= 1e-13 && norm(omegaBody) <= 1e-13 && ...
    abs(betaM) <= 1e-13 && abs(rotorCtrl.cyclicLong) <= 1e-13;
if exactHoverAnchor
    anchor = frozen_hover_anchor(theta75);
    nDisk = eT;
    Fbody = anchor.thrust*nDisk;
    Mreaction = -rotDir*anchor.torque*eT;
    Marm = cross(rHub,Fbody);
    Mbody = Marm+Mreaction;
    out = base_output();
    out.propagationBranch = 'EXACT_FROZEN_HOVER_IDENTITY_ANCHOR';
    out.hoverAnchorUsed = true;
    out.theta75 = theta75;
    out.theta75Deg = theta75*180/pi;
    out.beta0 = anchor.zFlap(1);
    out.beta1c = anchor.zFlap(2);
    out.beta1s = anchor.zFlap(3);
    out.zFlap = anchor.zFlap;
    out.nDisk = nDisk;
    out.eTeff = nDisk;
    out.thrust = anchor.thrust;
    out.torque = anchor.torque;
    out.Hlong = 0;
    out.Hlat = 0;
    out.inducedVelocity = anchor.inducedVelocity_mps;
    out.inducedVelocityError = anchor.inducedVelocityError;
    out.inducedClosureResidual = anchor.closureResidual;
    out.inducedClosureResidualRelative = anchor.closureResidualRelative;
    out.inducedClosureResidualRelativeTolerance = 2e-4;
    out.inducedSequenceConverged = anchor.inducedSequenceConverged;
    out.flapConverged = anchor.flapConverged;
    out.closureResidualSatisfied = anchor.closureResidualRelative <= 2e-4;
    out.physicalBranchSupported = anchor.thrust > 0;
    out.physicalConverged = anchor.physicalConverged;
    out.physicalStatus = anchor.physicalStatus;
    out.coupledConverged = anchor.inducedSequenceConverged;
    out.numericalConverged = anchor.inducedSequenceConverged;
    out.iterations = anchor.iterations;
    out.mu = 0;
    out.lambda0 = 0;
    out.lambda1 = -anchor.inducedVelocity_mps/max(tipSpeed,eps);
    out.CTFinal = anchor.thrust/(0.5*rho*A*tipSpeed^2);
    out.CT = out.CTFinal;
    out.alphaClampCount = anchor.alphaClampCount;
    out.machClampCount = anchor.machClampCount;
    out.KLMinApplied = anchor.KLMinApplied;
    out.KLMaxApplied = anchor.KLMaxApplied;
    out.stallDelayApplyCount = anchor.stallDelayApplyCount;
    out.inflowModel = 'FROZEN_STAGE3_NUAA_EQ12_FIRST_HARMONIC';
    out.Marm = Marm;
    out.Mreaction = Mreaction;
    out.Mgyro = zeros(3,1);
    out.Hrot = zeros(3,1);
    out.F = Fbody;
    out.M = Mbody;
    return;
end

vi = sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
zFlap = P.rotor.flapInitial(:);
if numel(zFlap) ~= 3
    error('m1_evidence_v1_forward_rotor:InvalidFlapInitial', ...
        'P.rotor.flapInitial must contain three harmonics.');
end
coupledConverged = false;
viError = Inf;
flapInfo = struct('converged',false,'residualNorm',Inf,'iterations',0);
positiveThrustGuardEverActive = false;
for iter = 1:P.rotor.inducedMaxIter
    [zFlap,flapInfo] = solve_flap(vi,zFlap);
    if ~flapInfo.converged
        error('m1_evidence_v1_forward_rotor:FlapNotConverged', ...
            'M1 propagation flapping failed for side %+d.',side);
    end
    loads = blade_loads(vi,zFlap);
    lambda0 = -Vaxial/max(tipSpeed,eps);
    lambda1 = lambda0-vi/max(tipSpeed,eps);
    CTiter = max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    denom = sqrt(lambda1^2+mu^2);
    viTarget = tipSpeed*CTiter/(4*max(denom,1e-12));
    viNew = 0.5*(vi+viTarget);
    viError = abs(viNew-vi)/max(1,abs(vi));
    positiveThrustGuardEverActive = positiveThrustGuardEverActive || loads.T<0;
    vi = viNew;
    if viError < P.rotor.inducedTol && ...
            flapInfo.residualNorm <= P.rotor.flapResidualTol
        coupledConverged = true;
        break;
    end
end
if ~coupledConverged
    error('m1_evidence_v1_forward_rotor:CoupledNotConverged', ...
        'M1 propagation induced/flap solve failed for side %+d.',side);
end
loads = blade_loads(vi,zFlap);
lambda0 = -Vaxial/max(tipSpeed,eps);
lambda1 = lambda0-vi/max(tipSpeed,eps);
denom = sqrt(lambda1^2+mu^2);
momentumThrust = 2*rho*A*tipSpeed*vi*denom;
closureResidual = loads.T-momentumThrust;
closureScale = max([abs(loads.T),abs(momentumThrust),1]);
closureRelative = abs(closureResidual)/closureScale;
closureTolerance = 2e-4;
physicalBranchSupported = loads.T>0;
physicalConverged = coupledConverged && flapInfo.converged && ...
    closureRelative<=closureTolerance && physicalBranchSupported;
if ~physicalBranchSupported
    physicalStatus = 'UNSUPPORTED_NONPOSITIVE_THRUST_BRANCH';
elseif closureRelative>closureTolerance
    physicalStatus = 'INDUCED_CLOSURE_RESIDUAL_NOT_SATISFIED';
else
    physicalStatus = 'PHYSICAL_CONVERGED';
end

beta0=zFlap(1); beta1c=zFlap(2); beta1s=zFlap(3);
nDiskRaw = eT-beta1c*eD-beta1s*eY;
nDisk = nDiskRaw/max(norm(nDiskRaw),eps);
Fbody = loads.T*nDisk+loads.Hlong*eD+loads.Hlat*eY;
Mreaction = -rotDir*loads.Q*eT;
Hrot = rotDir*P.rotor.Jpolar*Omega*eT;
Mgyro = -cross(omegaBody,Hrot);
Marm = cross(rHub,Fbody);
Mbody = Marm+Mreaction+Mgyro;

out = base_output();
out.propagationBranch = 'FORWARD_EXTENSION_UNVALIDATED_PROPAGATION_ONLY';
out.hoverAnchorUsed = false;
out.theta75 = theta75;
out.theta75Deg = theta75*180/pi;
out.beta0=beta0; out.beta1c=beta1c; out.beta1s=beta1s; out.zFlap=zFlap;
out.nDisk=nDisk; out.eTeff=nDisk;
out.thrust=loads.T; out.torque=loads.Q; out.Hlong=loads.Hlong; out.Hlat=loads.Hlat;
out.inducedVelocity=vi; out.inducedVelocityError=viError;
out.inducedClosureResidual=closureResidual;
out.inducedClosureResidualRelative=closureRelative;
out.inducedClosureResidualRelativeTolerance=closureTolerance;
out.inducedSequenceConverged=coupledConverged;
out.flapConverged=flapInfo.converged;
out.closureResidualSatisfied=closureRelative<=closureTolerance;
out.physicalBranchSupported=physicalBranchSupported;
out.physicalConverged=physicalConverged; out.physicalStatus=physicalStatus;
out.coupledConverged=coupledConverged; out.numericalConverged=coupledConverged;
out.iterations=iter; out.mu=mu; out.lambda0=lambda0; out.lambda1=lambda1;
out.CTFinal=max(loads.T,0)/(0.5*rho*A*tipSpeed^2); out.CT=out.CTFinal;
out.alphaClampCount=loads.alphaClampCount; out.machClampCount=loads.machClampCount;
out.KLMinApplied=loads.KLMinApplied; out.KLMaxApplied=loads.KLMaxApplied;
out.stallDelayApplyCount=loads.applyCount;
out.inflowModel='NUAA_EQ12_FIRST_HARMONIC_FORWARD_PROPAGATION';
out.minUT=loads.minUT; out.maxUT=loads.maxUT;
out.maxAbsAlphaBlade=loads.maxAbsAlphaBlade;
out.positiveThrustGuardActive=loads.T<0;
out.positiveThrustGuardEverActive=positiveThrustGuardEverActive;
out.Marm=Marm; out.Mreaction=Mreaction; out.Mgyro=Mgyro; out.Hrot=Hrot;
out.F=Fbody; out.M=Mbody;

    function b = base_output()
        b = struct();
        b.modelId='M1_EVIDENCE_V1_FORWARD_PROPAGATION';
        b.claimBoundary=[ ...
            'ANALYSIS_ONLY_FORWARD_PROPAGATION_NOT_FORWARD_FLIGHT_VALIDATION_' ...
            'EXACT_HOVER_ANCHOR_RETAINS_FROZEN_M1_IDENTITY'];
        b.side=side; b.rotDir=rotDir; b.rHub=rHub; b.Vhub=Vhub;
        b.Vaxial=Vaxial; b.Vlong=Vlong; b.Vlat=Vlat;
        b.muLong=muLong; b.muLat=muLat; b.eT=eT; b.eD=eD; b.eY=eY;
        b.theta1c=0; b.theta1s=-rotDir*rotorCtrl.cyclicLong;
        b.basisOrthogonalityError=max(max(abs([eT,eD,eY].'*[eT,eD,eY]-eye(3))));
    end

    function [z,info]=solve_flap(viNow,z0)
        z=z0(:);
        info=struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(z,viNow);
            rn=res/scale;
            if norm(rn)<=P.rotor.flapResidualTol
                info.converged=true; info.iterations=kk; info.residualNorm=norm(rn); return;
            end
            J=zeros(3,3);
            for jj=1:3
                h=P.rotor.flapJacobianStep*max(1,abs(z(jj)));
                zp=z; zm=z; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                [rp,~]=flap_residual(zp,viNow); [rm,~]=flap_residual(zm,viNow);
                J(:,jj)=(rp-rm)/(2*h*scale);
            end
            if any(~isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=z+step*dz;
                betaCheck=zc(1)+zc(2)*cos(azimuth_grid())+zc(3)*sin(azimuth_grid());
                if all(isfinite(zc)) && max(abs(betaCheck))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn), z=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow);
        info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
    end

    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z);
        gBody=P.env.g*[-sin(thetaBody); ...
            sin(phiBody)*cos(thetaBody); cos(phiBody)*cos(thetaBody)];
        gT=dot(gBody,eT); gD=dot(gBody,eD); gY=dot(gBody,eY);
        gRadial=gD*cos(ll.psi)+gY*sin(ll.psi);
        gravityMoment=P.rotor.Sblade*(-sin(ll.beta).*gRadial+cos(ll.beta).*gT);
        inertial=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertial-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(ll.psi));2*mean(byAz.*sin(ll.psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)), ...
            P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll=blade_loads(viNow,z)
        r0=P.rotor.rootCut*R;
        edges=linspace(r0,R,P.rotor.nRadial+1);
        rMid=0.5*(edges(1:end-1)+edges(2:end)); dr=diff(edges);
        psi=azimuth_grid().';
        xSpan=rMid/R;
        chordIn=14*ones(size(xSpan));
        ib=xSpan<=0.25; chordIn(ib)=-18.4615*xSpan(ib)+18.6154;
        chord=chordIn*0.0254;
        sourceTwistDeg=nasa_metal_twist_deg(xSpan);
        sourceTwist75Deg=nasa_metal_twist_deg(0.75);
        thetaGeom=theta75+(sourceTwistDeg-sourceTwist75Deg)*pi/180;
        beta=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDot=rotDir*Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDot=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        etD=-rotDir*sin(psi); etY=rotDir*cos(psi);
        VtanTrans=Vlong*etD+Vlat*etY;
        Vrad=Vlong*cos(psi)+Vlat*sin(psi);
        theta1s=-rotDir*rotorCtrl.cyclicLong;
        thetaBlade=thetaGeom+theta1s*sin(psi);
        UT=Omega*rMid+VtanTrans;
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=Vaxial+viField-beta.*Vrad-betaDot.*rMid;
        W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi; Mach=W/P.env.aSound;
        chordField=ones(size(alpha)).*chord;
        rField=ones(size(alpha)).*xSpan;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay( ...
            alpha,Mach,rField,chordField,R,'CORRIGAN_GENERIC_N1');
        q=0.5*rho*W.^2;
        dL=q.*chord.*CL.*dr; dD=q.*chord.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi);
        dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth;
        ll.T=factor*sum(dT(:)); ll.Q=factor*sum(dQ(:));
        Hvec=-[sum(sum(dH.*etD));sum(sum(dH.*etY))];
        ll.Hlong=factor*Hvec(1); ll.Hlat=factor*Hvec(2);
        ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=beta; ll.betaDDot=betaDDot; ll.psi=psi;
        ll.alphaClampCount=meta.alphaClampCount; ll.machClampCount=meta.machClampCount;
        ll.applyCount=meta.applyCount; ll.KLMinApplied=meta.KLMinApplied;
        ll.KLMaxApplied=meta.KLMaxApplied;
        ll.minUT=min(UT(:)); ll.maxUT=max(UT(:));
        ll.maxAbsAlphaBlade=max(abs(alpha(:)));
    end

    function psi=azimuth_grid()
        psi=(0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth);
    end

    function anchor=frozen_hover_anchor(theta75Rad)
        % Exact frozen Stage-3 Corrigan-n=1 hover numerical equations.
        r0=P.rotor.rootCut*R;
        rEdges=linspace(r0,R,P.rotor.nRadial+1);
        rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
        psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).';
        xSpan=rMid/R;
        chordIn=14*ones(size(xSpan));
        ib=xSpan<=0.25; chordIn(ib)=-18.4615*xSpan(ib)+18.6154;
        chord=chordIn*0.0254;
        thetaSourceDeg=nasa_metal_twist_deg(xSpan);
        theta75SourceDeg=nasa_metal_twist_deg(0.75);
        thetaBlade=theta75Rad+(thetaSourceDeg-theta75SourceDeg)*pi/180;
        UT=Omega*rMid;
        viH=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A));
        z=P.rotor.flapInitial(:); conv=false; err=Inf;
        hInfo=struct('converged',false,'residualNorm',Inf);
        for ii=1:P.rotor.inducedMaxIter
            [z,hInfo]=anchor_flap(viH,z);
            if ~hInfo.converged, break; end
            hLoads=anchor_loads(viH,z);
            lam=-viH/max(tipSpeed,eps);
            ct=max(hLoads.T,0)/(0.5*rho*A*tipSpeed^2);
            target=tipSpeed*ct/(4*max(abs(lam),1e-12));
            newVi=0.5*(viH+target);
            err=abs(newVi-viH)/max(1,abs(viH)); viH=newVi;
            if err<P.rotor.inducedTol && hInfo.residualNorm<=P.rotor.flapResidualTol
                conv=true; break;
            end
        end
        hLoads=anchor_loads(viH,z);
        lam=-viH/max(tipSpeed,eps);
        mom=2*rho*A*tipSpeed*viH*abs(lam);
        closureResidual=hLoads.T-mom;
        closure=abs(closureResidual)/max([abs(hLoads.T),abs(mom),1]);
        physical=conv && hInfo.converged && hLoads.T>0 && closure<=2e-4;
        if physical, status='PHYSICAL_CONVERGED';
        elseif hLoads.T<=0, status='UNSUPPORTED_NONPOSITIVE_THRUST_BRANCH';
        elseif closure>2e-4, status='INDUCED_CLOSURE_RESIDUAL_NOT_SATISFIED';
        else, status='NUMERICAL_ITERATION_NOT_CONVERGED'; end
        anchor=struct('thrust',hLoads.T,'torque',hLoads.Q,'zFlap',z, ...
            'inducedVelocity_mps',viH,'inducedVelocityError',err, ...
            'closureResidual',closureResidual,'closureResidualRelative',closure, ...
            'physicalConverged',physical,'physicalStatus',status, ...
            'inducedSequenceConverged',conv,'flapConverged',hInfo.converged, ...
            'iterations',ii,'alphaClampCount',hLoads.alphaClampCount, ...
            'machClampCount',hLoads.machClampCount,'KLMinApplied',hLoads.KLMinApplied, ...
            'KLMaxApplied',hLoads.KLMaxApplied,'stallDelayApplyCount',hLoads.applyCount);

        function [zz,info]=anchor_flap(viNow,z0)
            zz=z0(:); info=struct('converged',false,'iterations',0,'residualNorm',Inf);
            for kk=1:P.rotor.flapMaxIter
                [res,scale]=anchor_residual(zz,viNow); rn=res/scale;
                if norm(rn)<=P.rotor.flapResidualTol
                    info.converged=true; info.iterations=kk; info.residualNorm=norm(rn); return;
                end
                J=zeros(3,3);
                for jj=1:3
                    h=P.rotor.flapJacobianStep*max(1,abs(zz(jj)));
                    zp=zz; zm=zz; zp(jj)=zp(jj)+h; zm(jj)=zm(jj)-h;
                    [rp,~]=anchor_residual(zp,viNow); [rm,~]=anchor_residual(zm,viNow);
                    J(:,jj)=(rp-rm)/(2*h*scale);
                end
                if any(~isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
                dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
                step=1; accepted=false;
                for trial=1:P.rotor.flapLineSearchMaxIter
                    zc=zz+step*dz;
                    bc=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                    if all(isfinite(zc)) && max(abs(bc))<P.rotor.flapDivergenceAngle
                        [rc,sc]=anchor_residual(zc,viNow);
                        if norm(rc/sc)<norm(rn), zz=zc; accepted=true; break; end
                    end
                    step=step*P.rotor.flapNewtonDamping;
                end
                if ~accepted, return; end
            end
            [res,scale]=anchor_residual(zz,viNow);
            info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
        end
        function [res,scale]=anchor_residual(zz,viNow)
            aa=anchor_loads(viNow,zz);
            gravity=-P.rotor.Sblade*P.env.g*cos(aa.beta);
            inertial=P.rotor.Ib*aa.betaDDot+P.rotor.Ib*Omega^2*aa.beta;
            byAz=inertial-aa.flapMomentByAzimuth-gravity;
            res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
            scale=max([max(abs(aa.flapMomentByAzimuth)),max(abs(gravity)), ...
                P.rotor.Ib*Omega^2*0.05,1]);
        end
        function aa=anchor_loads(viNow,zz)
            b=zz(1)+zz(2)*cos(psi)+zz(3)*sin(psi);
            bdot=-Omega*(-zz(2)*sin(psi)+zz(3)*cos(psi));
            bddot=-Omega^2*(zz(2)*cos(psi)+zz(3)*sin(psi));
            vif=viNow.*(1+cos(psi).*(rMid/R));
            up=vif-bdot.*rMid;
            w=hypot(UT,up); ph=atan2(up,max(abs(UT),1e-8));
            al=thetaBlade-ph; ma=w/P.env.aSound;
            cf=ones(size(al)).*chord; rf=ones(size(al)).*xSpan;
            [cl,cd,meta]=xv15_c81_corrigan_stall_delay( ...
                al,ma,rf,cf,R,'CORRIGAN_GENERIC_N1');
            qq=0.5*rho*w.^2;
            dl=qq.*chord.*cl.*dr; dd=qq.*chord.*cd.*dr;
            dt=dl.*cos(ph)-dd.*sin(ph); dh=dd.*cos(ph)+dl.*sin(ph);
            dq=dh.*rMid; factor=P.rotor.Nb/P.rotor.nAzimuth;
            aa.T=sum(factor*sum(dt,1)); aa.Q=sum(factor*sum(dq,1));
            aa.flapMomentByAzimuth=sum(dt.*rMid,2); aa.beta=b; aa.betaDDot=bddot;
            aa.alphaClampCount=meta.alphaClampCount; aa.machClampCount=meta.machClampCount;
            aa.applyCount=meta.applyCount; aa.KLMinApplied=meta.KLMinApplied;
            aa.KLMaxApplied=meta.KLMaxApplied;
        end
    end
end
