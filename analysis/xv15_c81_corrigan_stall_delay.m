function [CL, CD, meta] = xv15_c81_corrigan_stall_delay(alphaRad, Mach, rOverR, chord_m, R_m, mode)
%XV15_C81_CORRIGAN_STALL_DELAY Source-traceable rotational stall-delay layer.
%
% This helper wraps the unchanged XV-15 C81 lookup with the simplified
% Corrigan-Schillings rotational stall-delay implementation documented for
% XV-15 by NASA/CR-2016-219086 (Koning, 2016):
%
%   K_L = (1.291*(c/r)^0.0775)^n
%   CL_rot = K_L * CL_C81,  for 0 < alpha < 30 deg and positive CL.
%
% CD is deliberately left equal to the C81 value in this incidence range,
% matching the simplified implementation described by Koning.  The present
% M1 hover points remain below 30 deg, so the published 30--60 deg washout
% branch is outside the actual evaluation domain.
%
% Allowed modes are discrete evidence roles, not a tunable numeric input:
%   OFF                 : no rotational correction.
%   CORRIGAN_GENERIC_N1 : n=1.0, literature-generic first-order variant.
%   KONING_XV15_N1P8    : n=1.8, published XV-15/OARF-correlated variant;
%                         explicitly NOT independent validation evidence.
%
% No OARF CT/CP/FM target is read or used here.

if nargin < 6 || isempty(mode), mode = 'OFF'; end
mode = upper(char(mode));
[CLbase,CD,baseMeta] = xv15_c81_section_lookup(alphaRad,Mach,rOverR);

switch mode
    case 'OFF'
        nExp = 0;
        sourceClass = 'NO_ROTATIONAL_STALL_DELAY';
        independence = 'BASELINE';
    case 'CORRIGAN_GENERIC_N1'
        nExp = 1.0;
        sourceClass = 'GENERAL_CORRIGAN_SCHILLINGS_LITERATURE_DEFAULT';
        independence = 'NOT_SELECTED_FROM_CURRENT_OARF_TARGETS';
    case 'KONING_XV15_N1P8'
        nExp = 1.8;
        sourceClass = 'NASA_CR_2016_219086_XV15_PUBLISHED_CORRELATION';
        independence = 'NONINDEPENDENT_XV15_OARF_CORRELATED_VARIANT';
    otherwise
        error('xv15_c81_corrigan_stall_delay:InvalidMode', ...
            'Unsupported discrete stall-delay mode: %s',mode);
end

alphaDeg = alphaRad*180/pi;
r_m = max(rOverR*R_m,1e-8);
cOverRlocal = chord_m./r_m;
if nExp == 0
    KL = ones(size(CLbase));
else
    KL = (1.291*cOverRlocal.^0.0775).^nExp;
end
applyMask = nExp > 0 & alphaDeg > 0 & alphaDeg < 30 & CLbase > 0;
CL = CLbase;
CL(applyMask) = KL(applyMask).*CLbase(applyMask);

meta = baseMeta;
meta.mode = mode;
meta.nExponent = nExp;
meta.KL = KL;
meta.applyMask = applyMask;
meta.applyCount = nnz(applyMask);
meta.KLMinApplied = NaN;
meta.KLMaxApplied = NaN;
if any(applyMask(:))
    meta.KLMinApplied = min(KL(applyMask));
    meta.KLMaxApplied = max(KL(applyMask));
end
meta.sourceClassRotational = sourceClass;
meta.independence = independence;
meta.claimBoundary = [ ...
    'CORRIGAN_STALL_DELAY_DISCRETE_LITERATURE_VARIANT_' ...
    'NO_CURRENT_OARF_PARAMETER_SEARCH'];
end
