function reduction = build_xv15_c81_low_order_section_aero()
%BUILD_XV15_C81_LOW_ORDER_SECTION_AERO Reduce public XV-15 C81 tables.
%
% Purpose
% -------
% Map the spanwise/Mach-dependent 2-D section-aerodynamic inputs published
% for the NASA CAMRAD II XV-15 baseline model into the scalar parameter form
% used by the present generic low-order rotor model:
%
%   CL = CLmax*tanh(a*(alpha-alpha0L)/CLmax)
%   CD = CD0 + kCD*CL^2
%
% Source
% ------
% NASA/TP-2004-212262, Appendix A, "XV-15 ROTOR AIRFOILS ...
% (C81 TABLES; INTERPOLATED SPANWISE)".  These are PUBLIC REFERENCE-MODEL
% INPUT TABLES, not OARF hover-test measurements and not raw airfoil tunnel
% data.  They are therefore used only as an independent parameter source;
% the OARF Run 15 CT/CP/FM data remain external validation data.
%
% Reduction scope
% ---------------
% - Nominal hover tip speed: 768 ft/s, sound speed 340 m/s.
% - Four published C81 span regions: 0.20-0.55, 0.55-0.80,
%   0.80-0.95, 0.95-1.00 R.
% - Representative Mach for lift uses the c*r^2 weighted mean radius.
% - Representative Mach for drag uses the c*r^3 weighted mean radius.
% - CL-form fit uses alpha=-6:2:12 deg.
% - CD-form fit uses alpha=-4:2:8 deg, avoiding deep/post-stall values while
%   retaining the hover-relevant high-Mach drag rise in the outer blade.
%
% The tabulated values below are linear Mach interpolations of the published
% C81 tables at those representative Mach numbers.  Keeping the compact
% interpolated fit inputs here makes the scalar reduction reproducible
% without copying the complete C81 database into the low-order repository.

%% Published-table reduction points
alphaCL_deg = (-6:2:12).';
alphaCD_deg = (-4:2:8).';

% c*r^2 weighted representative radii and normalized span weights.
rLift = [0.425454619, 0.690257686, 0.879275244, 0.975427257];
wLift = [0.159849420, 0.348330540, 0.348078580, 0.143741460];

% c*r^3 weighted representative radii and normalized span weights.
rDrag = [0.444812736, 0.697534139, 0.881391063, 0.975640689];
wDrag = [0.090112001, 0.318581923, 0.405527652, 0.185778424];

Vtip_mps = 768.0*0.3048;
aSound_mps = 340.0;
Mtip = Vtip_mps/aSound_mps;
MLift = Mtip*rLift;
MDrag = Mtip*rDrag;

% Rows: alphaCL_deg; columns: the four C81 span regions.
CLref = [ ...
 -0.302217256, -0.649499188, -0.628686000, -0.714653780; ...
 -0.136981289, -0.416213937, -0.405805800, -0.441265260; ...
  0.039301871, -0.181452188, -0.146805800, -0.157239880; ...
  0.260000000,  0.033619125,  0.093537200,  0.120777040; ...
  0.483254678,  0.265833062,  0.363895333,  0.426413900; ...
  0.700000000,  0.510285250,  0.626641867,  0.724728100; ...
  0.935000000,  0.725523500,  0.882194200,  0.997760120; ...
  1.010000000,  0.937833062,  1.050687267,  1.149825980; ...
  1.105000000,  1.007290125,  1.139628000,  1.159587920; ...
  1.121745322,  1.069455438,  1.044179067,  1.012483400];

% Rows: alphaCD_deg; columns: the four C81 span regions.  Mach interpolation
% uses the torque-relevant representative radii above.
CDref = [ ...
 0.014000000, 0.009000000, 0.008227614, 0.021406194; ...
 0.014000000, 0.007000000, 0.007113807, 0.008234366; ...
 0.014000000, 0.007000000, 0.006000000, 0.006000000; ...
 0.014000000, 0.007000000, 0.006886193, 0.006000000; ...
 0.014000000, 0.007246939, 0.007886193, 0.009468731; ...
 0.026000000, 0.010000000, 0.011227614, 0.032921679; ...
 0.028000000, 0.014753061, 0.028934717, 0.079624776];

%% Fit the CURRENT low-order CL form; no OARF performance data are used.
alphaCL_rad = alphaCL_deg*pi/180;
obj = @(q) cl_objective(q, alphaCL_rad, CLref, wLift);
% q = [log(a), alpha0L(rad), log(CLmax)] guarantees positive a and CLmax.
q0 = [log(6.5), -1*pi/180, log(1.2)];
opts = optimset('Display','off','TolX',1e-12,'TolFun',1e-14, ...
    'MaxIter',5000,'MaxFunEvals',20000);
q = fminsearch(obj, q0, opts);
liftSlope = exp(q(1));
alpha0L_rad = q(2);
CLmax = exp(q(3));

CLmodel = zeros(size(CLref));
for j = 1:numel(wLift)
    CLmodel(:,j) = CLmax*tanh(liftSlope*(alphaCL_rad-alpha0L_rad)/CLmax);
end
clResidual = CLmodel-CLref;
clWeightedRms = sqrt(sum(sum((clResidual.^2).*repmat(wLift,numel(alphaCL_rad),1))) / ...
    (numel(alphaCL_rad)*sum(wLift)));

%% Fit the CURRENT quadratic CD form using the fitted CL model.
alphaCD_rad = alphaCD_deg*pi/180;
CLforDrag = CLmax*tanh(liftSlope*(alphaCD_rad-alpha0L_rad)/CLmax);
X = [ones(numel(alphaCD_rad)*numel(wDrag),1), ...
     repmat(CLforDrag.^2,numel(wDrag),1)];
y = CDref(:);
% MATLAB column-major ordering: each CDref column is one span region.
w = kron(wDrag(:),ones(numel(alphaCD_rad),1));
Wsqrt = sqrt(w);
coef = (X.*Wsqrt) \ (y.*Wsqrt);
CD0 = coef(1);
kCD = coef(2);
CDmodel = reshape(X*coef,size(CDref));
cdResidual = CDmodel-CDref;
cdWeightedRms = sqrt(sum(sum((cdResidual.^2).*repmat(wDrag,numel(alphaCD_rad),1))) / ...
    (numel(alphaCD_rad)*sum(wDrag)));

%% Output
reduction = struct();
reduction.sourceClass = 'NASA_CAMRADII_C81_REFERENCE_INPUT_REDUCTION';
reduction.source = 'NASA/TP-2004-212262 Appendix A C81 tables';
reduction.nominalVtip_fps = 768.0;
reduction.Mtip = Mtip;
reduction.rLift = rLift;
reduction.wLift = wLift;
reduction.MLift = MLift;
reduction.rDrag = rDrag;
reduction.wDrag = wDrag;
reduction.MDrag = MDrag;
reduction.alphaCL_deg = alphaCL_deg;
reduction.CLref = CLref;
reduction.alphaCD_deg = alphaCD_deg;
reduction.CDref = CDref;
reduction.liftSlope = liftSlope;
reduction.alpha0L_rad = alpha0L_rad;
reduction.alpha0L_deg = alpha0L_rad*180/pi;
reduction.CLmax = CLmax;
reduction.CD0 = CD0;
reduction.kCD = kCD;
reduction.clWeightedRms = clWeightedRms;
reduction.cdWeightedRms = cdWeightedRms;
reduction.claimBoundary = ['REFERENCE_C81_TO_GENERIC_LOW_ORDER_PARAMETERS_' ...
    'NO_OARF_FIT_NO_RAW_POLAR_TRUTH_CLAIM'];
end

function J = cl_objective(q,alphaRad,CLref,wSpan)
a = exp(q(1));
alpha0 = q(2);
clmax = exp(q(3));
pred = clmax*tanh(a*(alphaRad-alpha0)/clmax);
res = repmat(pred,1,numel(wSpan))-CLref;
J = sum(sum((res.^2).*repmat(wSpan,numel(alphaRad),1))) / ...
    (numel(alphaRad)*sum(wSpan));
end
