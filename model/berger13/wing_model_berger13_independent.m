function [Fbody,Mbody,out] = wing_model_berger13_independent( ...
        x,uLegacy,betaML,betaMR,cgShift,rotorLeft,rotorRight,P)
%WING_MODEL_BERGER13_INDEPENDENT Reuse reviewed wing regions per side.
% Each half wing is evaluated with its own nacelle angle, induced velocity,
% advance ratio, local rigid-body velocity, area partition, and force arm.

[~,~,leftAll] = wing_model(x,uLegacy,betaML,cgShift, ...
    rotorLeft,rotorLeft,P);
[~,~,rightAll] = wing_model(x,uLegacy,betaMR,cgShift, ...
    rotorRight,rotorRight,P);
leftRegions = leftAll.regions(1:2);
rightRegions = rightAll.regions(3:4);

[Fleft,Mleft] = sum_regions(leftRegions);
[Fright,Mright] = sum_regions(rightRegions);
Fbody = Fleft+Fright;
Mbody = Mleft+Mright;

out.left.betaM = betaML;
out.left.SslipHalf = leftAll.SslipHalf;
out.left.SfreeHalf = leftAll.SfreeHalf;
out.left.regions = leftRegions;
out.left.F = Fleft;
out.left.M = Mleft;
out.right.betaM = betaMR;
out.right.SslipHalf = rightAll.SslipHalf;
out.right.SfreeHalf = rightAll.SfreeHalf;
out.right.regions = rightRegions;
out.right.F = Fright;
out.right.M = Mright;
out.F = Fbody;
out.M = Mbody;
out.usedIndependentAngles = true;
out.usedIndependentWake = true;
out.formulaBoundary = ['side-specific reuse of reviewed NUAA Eq.16-22 ' ...
    'wing regions; no cross-rotor wake interference model'];
end

function [F,M] = sum_regions(regions)
F = zeros(3,1);
M = zeros(3,1);
for k = 1:numel(regions)
    F = F+regions{k}.F;
    M = M+regions{k}.M;
end
end
