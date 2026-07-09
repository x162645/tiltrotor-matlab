function P13 = params_berger13()
%PARAMS_BERGER13 Parameters for the isolated Berger-inspired scaffold.
% Values in P13.nacelle are research placeholders for interface development;
% they are not XV-15 or Berger-validated data.

d2r = pi/180;
Pbase = params_nominal();
Pbase.control.enableLateralCyclic = true;
Pbase.control.lateralCyclicTheta1cMapping = 'rotDir';

P13.base = Pbase;
P13.nacelle.I = 250;
P13.nacelle.D = 900;
P13.nacelle.K = 0;
P13.nacelle.betaMin = 0*d2r;
P13.nacelle.betaMax = 90*d2r;
P13.nacelle.betaDotLim = 20*d2r;
P13.nacelle.torqueLim = 5.0e4;
P13.nacelle.parameterSource = 'RESEARCH_PLACEHOLDER';

P13.linear.dx = [Pbase.linear.dx(:); 1e-4; 1e-4; 1e-4; 1e-4];
P13.linear.du = [control_steps_8(Pbase); 10; 10];
end

function du8 = control_steps_8(Pbase)
du = Pbase.linear.du(:);
if numel(du) == 8
    du8 = du;
else
    du8 = [du(1:4); du(4); du(5:7)];
end
end
