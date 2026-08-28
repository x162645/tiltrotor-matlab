function [viDown, meta] = xv15_landgrebe_biot_savart_inflow(rEval_m,rEdges_m,gammaMid_m2ps,CT,sigma,thetaTw_deg,Nb,R_m,wakeTurns,segmentsPerRev)
%XV15_LANDGREBE_BIOT_SAVART_INFLOW Prescribed-wake nonlocal inflow shape.
%
% This helper is a M1 validation/research diagnostic.  It does not modify
% production M0/M1 rotor functions.
%
% Wake geometry follows the classic Landgrebe hover tip-vortex form as
% summarized in Ramasamy, Gold & Bhagwat (36th ERF, 2010):
%
%   z/R = k1*psi_w                                      0 <= psi_w <= 2*pi/Nb
%       = k1*2*pi/Nb + k2*(psi_w-2*pi/Nb)              otherwise
%   r/r0 = A + (1-A)*exp(-gamma*psi_w)
%   A     = 0.78
%   k1    = -0.25*(CT/sigma + 0.001*theta_tw)
%   k2    = -(1.41 + 0.0141*theta_tw)*sqrt(CT/2)
%   gamma = 0.145 + 27*CT
%
% theta_tw is the equivalent root-to-tip twist in degrees.  The XV-15
% metal blade is strongly and nonlinearly twisted, outside much of the
% classic prescribed-wake database.  Therefore the present extension of
% the same contraction/axial trajectory to the discrete inboard trailing
% sheet is an ASSUMED model-form diagnostic, not a claim that the complete
% Landgrebe inboard-sheet model has been reproduced.
%
% The blade is represented by midpoint bound circulation values Gamma(r).
% Kelvin circulation conservation gives one trailing filament at every
% radial panel edge with strength Gamma_left-Gamma_right, including root
% and tip closure to zero circulation.  Each trailing filament is convected
% on the prescribed helix and integrated with the finite straight-segment
% Biot-Savart law.  No fitted vortex-strength multiplier or induced-velocity
% gain is used.
%
% Sign convention: wake age increases downstream, helix azimuth decreases
% behind a positively rotating blade, and z<0 is below the rotor disk.
% viDown is positive for downward induced velocity (-Vz).

rEval_m = rEval_m(:).';
rEdges_m = rEdges_m(:).';
gammaMid_m2ps = gammaMid_m2ps(:).';

if numel(rEdges_m) ~= numel(gammaMid_m2ps)+1
    error('xv15_landgrebe_biot_savart_inflow:SizeMismatch', ...
        'rEdges must have exactly one more element than gammaMid.');
end
if ~(isfinite(CT) && CT > 0)
    error('xv15_landgrebe_biot_savart_inflow:InvalidCT','CT must be positive and finite.');
end
if ~(isfinite(sigma) && sigma > 0)
    error('xv15_landgrebe_biot_savart_inflow:InvalidSolidity','sigma must be positive and finite.');
end
if ~(isfinite(wakeTurns) && wakeTurns > 0 && isfinite(segmentsPerRev) && segmentsPerRev >= 8)
    error('xv15_landgrebe_biot_savart_inflow:InvalidDiscretization','Invalid wake discretization.');
end

Acontract = 0.78;
psi1 = 2*pi/Nb;
k1 = -0.25*(CT/sigma + 0.001*thetaTw_deg);
k2 = -(1.41 + 0.0141*thetaTw_deg)*sqrt(CT/2);
gammaContract = 0.145 + 27*CT;

if ~(isfinite(k1) && isfinite(k2) && isfinite(gammaContract) && gammaContract > 0)
    error('xv15_landgrebe_biot_savart_inflow:InvalidWakeGeometry', ...
        'Landgrebe coefficients are nonfinite or invalid.');
end

% Discrete trailing-vortex strengths from the radial bound-circulation jump.
gammaExtended = [0 gammaMid_m2ps 0];
edgeStrength = gammaExtended(1:end-1)-gammaExtended(2:end);

nSeg = max(ceil(wakeTurns*segmentsPerRev),1);
psiNode = linspace(0,2*pi*wakeTurns,nSeg+1);
contract = Acontract + (1-Acontract)*exp(-gammaContract*psiNode);
zNorm = k1*min(psiNode,psi1) + k2*max(psiNode-psi1,0);

vTotal = zeros(numel(rEval_m),3);
vByEdge = zeros(numel(rEval_m),3,numel(rEdges_m));
vByBlade = zeros(numel(rEval_m),3,Nb);
skippedNearSingular = 0;
activeFilaments = 0;

for ib = 1:Nb
    phi0 = 2*pi*(ib-1)/Nb;
    for ie = 1:numel(rEdges_m)
        G = edgeStrength(ie);
        if abs(G) <= 1e-12
            continue;
        end
        activeFilaments = activeFilaments + 1;
        radius = rEdges_m(ie)*contract;
        phi = phi0-psiNode;
        xNode = radius.*cos(phi);
        yNode = radius.*sin(phi);
        zNode = R_m*zNorm;
        for iseg = 1:nSeg
            A = [xNode(iseg),yNode(iseg),zNode(iseg)];
            B = [xNode(iseg+1),yNode(iseg+1),zNode(iseg+1)];
            r0 = B-A;
            for ip = 1:numel(rEval_m)
                P = [rEval_m(ip),0,0];
                r1 = P-A;
                r2 = P-B;
                c12 = cross(r1,r2);
                c2 = dot(c12,c12);
                n1 = norm(r1);
                n2 = norm(r2);
                scale2 = max([dot(r0,r0),n1^2,n2^2,1]);
                if c2 <= 1e-20*scale2^2 || n1 <= 1e-12 || n2 <= 1e-12
                    skippedNearSingular = skippedNearSingular+1;
                    continue;
                end
                coeff = G/(4*pi)*dot(r0,r1/n1-r2/n2)/c2;
                dv = coeff*c12;
                vTotal(ip,:) = vTotal(ip,:) + dv;
                vByEdge(ip,:,ie) = vByEdge(ip,:,ie) + dv;
                vByBlade(ip,:,ib) = vByBlade(ip,:,ib) + dv;
            end
        end
    end
end

viDown = -vTotal(:,3).';
viDownByEdge = -squeeze(vByEdge(:,3,:));
viDownByBlade = -squeeze(vByBlade(:,3,:));
if any(~isfinite(viDown)) || any(~isfinite(viDownByEdge(:))) || any(~isfinite(viDownByBlade(:)))
    error('xv15_landgrebe_biot_savart_inflow:NonfiniteVelocity', ...
        'Biot-Savart integration produced nonfinite induced velocity.');
end

meta = struct();
meta.sourceClass = 'LANDGREBE_HOVER_GEOMETRY_PLUS_DISCRETE_LIFTING_LINE_BIOT_SAVART';
meta.inboardGeometryClass = 'ASSUMED_UNIFORM_NORMALIZED_CONTRACTION_EXTENSION';
meta.CT = CT;
meta.sigma = sigma;
meta.thetaTw_deg = thetaTw_deg;
meta.Acontract = Acontract;
meta.k1 = k1;
meta.k2 = k2;
meta.gammaContract = gammaContract;
meta.wakeTurns = wakeTurns;
meta.segmentsPerRev = segmentsPerRev;
meta.activeFilaments = activeFilaments;
meta.skippedNearSingular = skippedNearSingular;
meta.edgeStrength_m2ps = edgeStrength;
meta.viDownByEdge_mps = viDownByEdge;
meta.viDownByBlade_mps = viDownByBlade;
meta.rawVz_mps = vTotal(:,3).';
meta.claimBoundary = [ ...
    'NONLOCAL_WAKE_SHAPE_DIAGNOSTIC_NO_OARF_FIT_' ...
    'CLASSIC_LANDGREBE_DATABASE_LIMIT_FOR_HIGHLY_TWISTED_XV15'];
end
