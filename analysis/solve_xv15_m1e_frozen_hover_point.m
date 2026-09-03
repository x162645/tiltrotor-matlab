function out = solve_xv15_m1e_frozen_hover_point(P,theta75_deg)
%SOLVE_XV15_M1E_FROZEN_HOVER_POINT Exact frozen Corrigan-n1 hover equations.
%
% This is an analysis utility factored from the already identity-checked
% Stage-5 copy of the frozen Stage-3 CORRIGAN_GENERIC_N1 branch.  It exists
% only so later transport comparisons can evaluate M1-E and M1-G on the
% same external points without changing the frozen model definition.

mode='CORRIGAN_GENERIC_N1';
R=P.rotor.R; Omega=P.rotor.Omega; tipSpeed=Omega*R; rho=P.env.rho; A=pi*R^2;
r0=P.rotor.rootCut*R; rEdges=linspace(r0,R,P.rotor.nRadial+1);
rMid=0.5*(rEdges(1:end-1)+rEdges(2:end)); dr=diff(rEdges);
psi=((0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth)).'; x=rMid/R;
chord_in=14*ones(size(x)); inboard=x<=0.25; chord_in(inboard)=-18.4615*x(inboard)+18.6154;
chord_m=chord_in*0.0254; thetaSource_deg=nasa_metal_twist_deg(x);
theta75Source_deg=nasa_metal_twist_deg(0.75);
thetaBlade=(theta75_deg+thetaSource_deg-theta75Source_deg)*pi/180; UT=Omega*rMid;
if ~isfield(P.env,'aSound'), P.env.aSound=340.0; end

vi=sqrt(max(P.mass.m*P.env.g/2,1)/(2*rho*A)); zFlap=P.rotor.flapInitial(:); converged=false;
flapInfo=struct('converged',false,'iterations',0,'residualNorm',Inf);
for iter=1:P.rotor.inducedMaxIter
    [zFlap,flapInfo]=solve_flap(vi,zFlap);
    if ~flapInfo.converged, break; end
    loads=blade_loads(vi,zFlap);
    lambda1=-vi/max(tipSpeed,eps);
    CTiter=max(loads.T,0)/(0.5*rho*A*tipSpeed^2);
    viTarget=tipSpeed*CTiter/(4*max(abs(lambda1),1e-12));
    viNew=0.5*(vi+viTarget); err=abs(viNew-vi)/max(1,abs(vi)); vi=viNew;
    if err<P.rotor.inducedTol && flapInfo.residualNorm<=P.rotor.flapResidualTol
        converged=true; break;
    end
end
loads=blade_loads(vi,zFlap); lambda1=-vi/max(tipSpeed,eps);
momentumThrust=2*rho*A*tipSpeed*vi*abs(lambda1);
closure=abs(loads.T-momentumThrust)/max([abs(loads.T),abs(momentumThrust),1]);
physical=converged && flapInfo.converged && loads.T>0 && closure<=2e-4;
out=struct(); out.thrust=loads.T; out.torque=loads.Q; out.physicalConverged=physical;
out.iterations=iter; out.inducedVelocity_mps=vi; out.closureResidualRelative=closure;
out.KLMinApplied=loads.KLMinApplied; out.KLMaxApplied=loads.KLMaxApplied;
out.stallDelayApplyCount=loads.applyCount; out.alphaClampCount=loads.alphaClampCount;
out.machClampCount=loads.machClampCount; out.physicalStatus='M1_E1_NOT_PHYSICALLY_CONVERGED';
if physical, out.physicalStatus='SUPPORTED'; end
out.modelIdentity='M1_E_FROZEN_CORRIGAN_N1';

    function [z,info]=solve_flap(viNow,z0)
        z=z0(:); info=struct('converged',false,'iterations',0,'residualNorm',Inf);
        for kk=1:P.rotor.flapMaxIter
            [res,scale]=flap_residual(z,viNow); rn=res/scale;
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
            if ~all(isfinite(J(:))) || rcond(J.'*J)<1e-14, return; end
            dz=-(J.'*J+P.rotor.flapNewtonRegularization*eye(3))\(J.'*rn);
            step=1; accepted=false;
            for trial=1:P.rotor.flapLineSearchMaxIter
                zc=z+step*dz; betaCheck=zc(1)+zc(2)*cos(psi)+zc(3)*sin(psi);
                if all(isfinite(zc)) && max(abs(betaCheck))<P.rotor.flapDivergenceAngle
                    [rc,sc]=flap_residual(zc,viNow);
                    if norm(rc/sc)<norm(rn), z=zc; accepted=true; break; end
                end
                step=step*P.rotor.flapNewtonDamping;
            end
            if ~accepted, return; end
        end
        [res,scale]=flap_residual(z,viNow); info.iterations=P.rotor.flapMaxIter; info.residualNorm=norm(res/scale);
    end

    function [res,scale]=flap_residual(z,viNow)
        ll=blade_loads(viNow,z); gravityMoment=-P.rotor.Sblade*P.env.g*cos(ll.beta);
        inertialRestoring=P.rotor.Ib*ll.betaDDot+P.rotor.Ib*Omega^2*ll.beta;
        byAz=inertialRestoring-ll.flapMomentByAzimuth-gravityMoment;
        res=[mean(byAz);2*mean(byAz.*cos(psi));2*mean(byAz.*sin(psi))];
        scale=max([max(abs(ll.flapMomentByAzimuth)),max(abs(gravityMoment)),P.rotor.Ib*Omega^2*0.05,1]);
    end

    function ll=blade_loads(viNow,z)
        betaLocal=z(1)+z(2)*cos(psi)+z(3)*sin(psi);
        betaDotLocal=-Omega*(-z(2)*sin(psi)+z(3)*cos(psi));
        betaDDotLocal=-Omega^2*(z(2)*cos(psi)+z(3)*sin(psi));
        viField=viNow.*(1+cos(psi).*(rMid/R));
        UP=viField-betaDotLocal.*rMid; W=hypot(UT,UP); phi=atan2(UP,max(abs(UT),1e-8));
        alpha=thetaBlade-phi; Mach=W/P.env.aSound; chordField=ones(size(alpha)).*chord_m;
        rField=ones(size(alpha)).*x;
        [CL,CD,meta]=xv15_c81_corrigan_stall_delay(alpha,Mach,rField,chordField,R,mode);
        q=0.5*rho*W.^2; dL=q.*chord_m.*CL.*dr; dD=q.*chord_m.*CD.*dr;
        dT=dL.*cos(phi)-dD.*sin(phi); dH=dD.*cos(phi)+dL.*sin(phi); dQ=dH.*rMid;
        factor=P.rotor.Nb/P.rotor.nAzimuth; ringT=factor*sum(dT,1); ringQ=factor*sum(dQ,1);
        ll.T=sum(ringT); ll.Q=sum(ringQ); ll.flapMomentByAzimuth=sum(dT.*rMid,2);
        ll.beta=betaLocal; ll.betaDDot=betaDDotLocal; ll.alphaClampCount=meta.alphaClampCount;
        ll.machClampCount=meta.machClampCount; ll.applyCount=meta.applyCount;
        ll.KLMinApplied=meta.KLMinApplied; ll.KLMaxApplied=meta.KLMaxApplied;
    end
end

function theta_deg=nasa_metal_twist_deg(x)
theta_deg=289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
