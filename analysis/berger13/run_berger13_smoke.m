function summary = run_berger13_smoke()
%RUN_BERGER13_SMOKE Lightweight smoke check for the 13x10 scaffold.

P13 = params_berger13();
d2r = pi/180;
x13 = [40; 0; 0; 0; 0; 0; 0; 0; 0; 90*d2r; 90*d2r; 0; 0];
u10 = [8*d2r; 0; 0; 0; 1*d2r; 0; -2*d2r; 0; 0; 0];

[xdot, out] = tiltrotor_eom_13x10(x13, u10, P13);
[A, B, lin] = linearize_13x10_numeric(x13, u10, P13);

summary.xdot = xdot;
summary.ASize = size(A);
summary.BSize = size(B);
summary.linearization = lin;
summary.components13 = out.components13;
summary.allPassed = isreal(xdot) && all(isfinite(xdot)) && ...
    isequal(size(A), [13 13]) && isequal(size(B), [13 10]) && lin.finite;

fprintf('\nBerger13 smoke check\n');
fprintf('====================\n');
fprintf('A size: %d x %d\n', size(A,1), size(A,2));
fprintf('B size: %d x %d\n', size(B,1), size(B,2));
fprintf('All passed: %d\n', summary.allPassed);
end
