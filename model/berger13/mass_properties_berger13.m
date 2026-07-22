function mp = mass_properties_berger13(betaML, betaMR, P13)
%MASS_PROPERTIES_BERGER13 Reconstruct fixed/moving inertia at actual CG.
% The fixed body is recovered from the average-angle baseline mass moments
% and inertia. Every contribution is then translated to the actual total CG.

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

mTotal = P.mass.m;
mFixed = mTotal-mL-mR;
if mFixed <= 0
    error('mass_properties_berger13:InvalidMassDecomposition', ...
        'Fixed mass must remain positive after moving-mass extraction.');
end

% Recover the fixed-body CG from the reviewed average-angle mass moment.
rFixed = (mTotal*baseAvg.cgShift-mL*rLAvg-mR*rRAvg)/mFixed;
cgShift = (mFixed*rFixed+mL*rL+mR*rR)/mTotal;
massMomentResidual = mTotal*cgShift- ...
    (mFixed*rFixed+mL*rL+mR*rR);

% Remove average moving point masses and translate the remaining fixed-body
% inertia back to its own CG. Local moving-component tensors are UNKNOWN.
IleftBase = point_inertia(mL,rLAvg-baseAvg.cgShift);
IrightBase = point_inertia(mR,rRAvg-baseAvg.cgShift);
IfixedAboutBaseCG = baseAvg.I-IleftBase-IrightBase;
IfixedOwn = IfixedAboutBaseCG- ...
    point_inertia(mFixed,rFixed-baseAvg.cgShift);

IfixedActual = IfixedOwn+point_inertia(mFixed,rFixed-cgShift);
IleftActual = point_inertia(mL,rL-cgShift);
IrightActual = point_inertia(mR,rR-cgShift);
I = IfixedActual+IleftActual+IrightActual;
I = 0.5*(I+I.');
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
mp.massDecomposition.total = mTotal;
mp.massDecomposition.fixed = mFixed;
mp.massDecomposition.left = mL;
mp.massDecomposition.right = mR;
mp.fixedComponent.cg = rFixed;
mp.fixedComponent.inertiaAboutOwnCG = IfixedOwn;
mp.fixedComponent.inertiaAboutActualCG = IfixedActual;
mp.fixedComponent.referenceBeta = betaAvg;
mp.fixedComponent.localInertiaSource = ...
    'DERIVED_RESIDUAL_FROM_AVERAGE_BASELINE';
mp.componentPositions.left = rL;
mp.componentPositions.right = rR;
mp.componentPositions.leftBase = rLAvg;
mp.componentPositions.rightBase = rRAvg;
mp.componentContributions.left = IleftActual;
mp.componentContributions.right = IrightActual;
mp.baselineContributions.left = IleftBase;
mp.baselineContributions.right = IrightBase;
mp.massMomentResidual = massMomentResidual;
mp.inertiaReconstructionResidual = I-(IfixedActual+IleftActual+IrightActual);
mp.asymmetricCorrection = I-baseAvg.I;
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
