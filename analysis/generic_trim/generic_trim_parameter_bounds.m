function bounds = generic_trim_parameter_bounds()
%GENERIC_TRIM_PARAMETER_BOUNDS Frozen auditable PR5B search bounds.

name = {'wingXAC';'rotorPivotZ';'tailIncidence';'tailCLelevator'; ...
    'tailDownwashAlpha'};
path = {'wing.xAC';'rotor.pivotZ';'htail.incidence'; ...
    'htail.CLelevator';'htail.downwashAlpha'};
className = {'GEOMETRY';'GEOMETRY';'GEOMETRY'; ...
    'EFFECTIVE_AERO';'EFFECTIVE_AERO_REJECTED_CORRELATED'};
lower = [-0.4;-0.6;-5*pi/180;1.6;0.30];
upper = [ 0.4; 0.6; 2*pi/180;2.4;0.50];
unit = {'m';'m';'rad';'1/rad';'1'};
formalC1 = [true;true;true;false;false];
formalC2 = [true;true;true;true;false];
sourceClass = repmat({'ASSUMED_MODEL_PARAMETER'},5,1);
claimClass = {'OPTIMIZED_GENERIC';'OPTIMIZED_GENERIC'; ...
    'OPTIMIZED_GENERIC';'CALIBRATED_EFFECTIVE';'CALIBRATED_EFFECTIVE'};
bounds = table(name,path,className,lower,upper,unit,formalC1,formalC2, ...
    sourceClass,claimClass);
end
