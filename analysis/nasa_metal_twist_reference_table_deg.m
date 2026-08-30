function theta_deg = nasa_metal_twist_reference_table_deg(x)
%NASA_METAL_TWIST_REFERENCE_TABLE_DEG Direct Appendix-A TWISTA interpolation.
%
% Source: NASA/TP-2004-212262 Appendix A CAMRAD II XV-15 reference rotor.
% RPROP = 0:0.02:1 and TWISTA contains the 51 published geometric-twist
% values below. This helper exists only for source-fidelity sensitivity; it
% does not replace the frozen M1 polynomial path by default.

r = (0:0.02:1).';
t = [ ...
 34.43;33.49;32.45;31.55;30.79;30.03;29.03;28.03;26.88;25.58; ...
 24.28;23.03;21.78;20.43;18.98;17.53;16.48;15.43;14.20;12.79; ...
 11.38;10.64;9.90;9.03;8.03;7.03;6.43;5.83;5.19;4.51;3.83;3.31; ...
 2.79;2.30;1.84;1.38;0.83;0.27;-0.27;-0.82;-1.37;-1.86;-2.35; ...
 -2.82;-3.27;-3.72;-4.14;-4.56;-4.98;-5.40;-5.82];

if any(~isfinite(x(:))) || any(x(:) < 0) || any(x(:) > 1)
    error('nasa_metal_twist_reference_table_deg:Domain', ...
        'x must be finite and within 0 <= r/R <= 1.');
end

theta_deg = interp1(r,t,x,'linear');
end
