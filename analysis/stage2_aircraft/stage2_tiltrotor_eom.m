function [xdot,out] = stage2_tiltrotor_eom(modelIdentity,x,uCtrl,betaM,P)
%STAGE2_TILTROTOR_EOM Exact production rigid-body equations with stage-2 rotor backend.
x=x(:); uCtrl=uCtrl(:);
[Fap,Map,componentInfo]=stage2_total_forces_moments(modelIdentity,x,uCtrl,betaM,P);
mp=componentInfo.massProperties; mass=mp.mass;
Vbody=x(1:3); omega=x(4:6); phi=x(7); theta=x(8);
Fg=mass*P.env.g*[-sin(theta);sin(phi)*cos(theta);cos(phi)*cos(theta)];
Ftotal=Fap+Fg; Mtotal=Map;
Vdot=Ftotal/mass-cross(omega,Vbody);
omegaDot=mp.I\(Mtotal-cross(omega,mp.I*omega));
ct=cos(theta); if abs(ct)<1e-6, ct=sign(ct+eps)*1e-6; end
tt=sin(theta)/ct;
T321=[1,sin(phi)*tt,cos(phi)*tt;0,cos(phi),-sin(phi);0,sin(phi)/ct,cos(phi)/ct];
eulerDot=T321*omega; xdot=[Vdot;omegaDot;eulerDot];
out.FaeroProp=Fap; out.Fgravity=Fg; out.Ftotal=Ftotal; out.Mtotal=Mtotal;
out.massProperties=mp; out.components=componentInfo;
out.physicalConverged=componentInfo.physicalConverged;
out.physicalBranchSupported=componentInfo.physicalBranchSupported;
out.physicalStatus=componentInfo.physicalStatus; out.xdot=xdot;
out.stage2ModelIdentity=char(modelIdentity);
end
