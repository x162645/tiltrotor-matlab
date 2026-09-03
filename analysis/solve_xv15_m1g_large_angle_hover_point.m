function out = solve_xv15_m1g_large_angle_hover_point(P,theta75_deg,sectionMode,closureOpts)
%SOLVE_XV15_M1G_LARGE_ANGLE_HOVER_POINT Reusable analysis-only M1-G rotor point.
%
% Component-level boundary:
%   source-informed XV-15 metal-blade radial chord/nonlinear twist
%   + four-region C81/local Mach section aerodynamics
%   + optional frozen Corrigan n=1 rotational correction
%   + Stahlhut-inspired steady axial large-angle local inflow closure.
%
% No XV-15 performance target enters this function.  The function is not a
% production rotor replacement and is restricted to steady axial/hover flow.

if nargin < 3 || isempty(sectionMode), sectionMode = 'CORRIGAN_GENERIC_N1'; end
if nargin < 4, closureOpts = struct(); end

R = P.rotor.R;
Omega = P.rotor.Omega;
r0 = P.rotor.rootCut*R;
rEdges = linspace(r0,R,P.rotor.nRadial+1);
y = 0.5*(rEdges(1:end-1)+rEdges(2:end));
dr = diff(rEdges);
x = y/R;

chord_in = 14*ones(size(x));
inboard = x <= 0.25;
chord_in(inboard) = -18.4615*x(inboard)+18.6154;
chord_m = chord_in*0.0254;
twist = nasa_metal_twist_deg(x);
twist75 = nasa_metal_twist_deg(0.75);
theta = (theta75_deg+twist-twist75)*pi/180;

if ~isfield(P.env,'aSound'), P.env.aSound = 340.0; end
S = struct();
S.rRatio = x;
S.y_m = y;
S.dr_m = dr;
S.chord_m = chord_m;
S.theta_rad = theta;
S.R_m = R;
S.Omega_radps = Omega;
S.Nb = P.rotor.Nb;
S.rho_kgm3 = P.env.rho;
S.aSound_mps = P.env.aSound;
S.Vinf_mps = 0;

aeroFcn = @(a,M,rr,cc) section_aero(a,M,rr,cc,R,sectionMode);
la = rotor_inflow_closure_large_angle_local(S,aeroFcn,closureOpts);

out = la;
out.thrust = la.thrust_N;
out.torque = la.torque_Nm;
out.physicalConverged = la.allSectionsConverged && ...
    isfinite(la.thrust_N) && la.thrust_N > 0 && ...
    isfinite(la.torque_Nm) && la.torque_Nm > 0;
out.physicalStatus = 'M1_G_NOT_PHYSICALLY_CONVERGED';
if out.physicalConverged, out.physicalStatus = 'SUPPORTED'; end
out.iterations = NaN;
out.inducedVelocity_mps = mean(la.vi_mps(isfinite(la.vi_mps)));
out.closureResidualRelative = la.maxAbsRootResidual;
out.KLMinApplied = NaN;
out.KLMaxApplied = NaN;
out.stallDelayApplyCount = NaN;
out.alphaClampCount = NaN;
out.machClampCount = NaN;
out.modelIdentity = 'M1_G_LARGE_ANGLE_LOCAL_CLOSURE';
out.sectionMode = sectionMode;
out.claimBoundary = ['ANALYSIS_ONLY_STEADY_AXIAL_STAHLHUT_STYLE_LOCAL_CLOSURE_' ...
    'NO_TARGET_FIT_NOT_NONLOCAL_WAKE'];
end

function [CL,CD,meta] = section_aero(alpha,Mach,rRatio,chord_m,R,mode)
mode = upper(char(mode));
switch mode
    case 'CORRIGAN_GENERIC_N1'
        [CL,CD,meta] = xv15_c81_corrigan_stall_delay(alpha,Mach,rRatio,chord_m,R, ...
            'CORRIGAN_GENERIC_N1');
    case 'OFF'
        [CL,CD,meta] = xv15_c81_corrigan_stall_delay(alpha,Mach,rRatio,chord_m,R,'OFF');
    otherwise
        error('solve_xv15_m1g_large_angle_hover_point:UnknownSectionMode', ...
            'Unknown section mode %s.',mode);
end
end

function theta_deg = nasa_metal_twist_deg(x)
theta_deg = 289.98*x.^5-892.87*x.^4+987.06*x.^3-438.31*x.^2+15.695*x+32.057;
end
