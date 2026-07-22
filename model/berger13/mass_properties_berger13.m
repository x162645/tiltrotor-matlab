function mp = mass_properties_berger13(betaML, betaMR, P13)
%MASS_PROPERTIES_BERGER13 Parameterized left/right moving-mass correction.
% The symmetric limit is exactly the reviewed legacy mass-properties model.

betaAvg = 0.5*(betaML+betaMR);
baseAvg = mass_properties(betaAvg,P13.base);
cfg = P13.movingComponents;
mL = cfg.left.mass;
mR = cfg.right.mass;
radius = cfg.radius;
P = P13.base;

rL = component_position(betaML,-1,radius,P);
rR = component_position(betaMR,+1,radius,P);
rLAvg = component_position(betaAvg,-1,radius,P);
rRAvg = component_position(betaAvg,+1,radius,P);

nominalCombinedCG = (mL*rLAvg+mR*rRAvg)/(mL+mR);
actualCombinedCG = (mL*rL+mR*rR)/(mL+mR);
cgCorrection = (mL+mR)/P.mass.m * ...
    (actualCombinedCG-nominalCombinedCG);
cgShift = baseAvg.cgShift + cgCorrection;

Icorrection = point_inertia(mL,rL-cgShift) + ...
    point_inertia(mR,rR-cgShift) - ...
    point_inertia(mL,rLAvg-baseAvg.cgShift) - ...
    point_inertia(mR,rRAvg-baseAvg.cgShift);
I = 0.5*(baseAvg.I+Icorrection + (baseAvg.I+Icorrection).');
principalMoments = eig(I);
if any(principalMoments <= 0)
    error('mass_properties_berger13:NonPositiveDefinite', ...
        'Parameterized asymmetric inertia is not positive definite.');
end

mp.mass = P.mass.m;
mp.cgShift = cgShift;
mp.I = I;
mp.principalMoments = principalMoments;
mp.radiusOfGyration = sqrt(principalMoments/P.mass.m);
mp.inertiaSymmetryError = norm(I-I.','fro');
mp.minInertiaEigenvalue = min(principalMoments);
mp.betaML = betaML;
mp.betaMR = betaMR;
mp.betaMAvg = betaAvg;
mp.baseAverage = baseAvg;
mp.componentPositions.left = rL;
mp.componentPositions.right = rR;
mp.componentContributions.left = point_inertia(mL,rL-cgShift);
mp.componentContributions.right = point_inertia(mR,rR-cgShift);
mp.asymmetricCorrection = Icorrection;
mp.localInertiaCorrectionImplemented = ...
    cfg.localInertiaCorrectionImplemented;
mp.parameterSources = cfg.parameterSources;
end

function r = component_position(betaM,side,radius,P)
r = [P.rotor.pivotX+radius*sin(betaM); ...
     side*P.rotor.pivotY; ...
     P.rotor.pivotZ-radius*cos(betaM)];
end

function I = point_inertia(mass,r)
I = mass*((r.'*r)*eye(3)-r*r.');
end
