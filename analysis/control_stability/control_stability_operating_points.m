function points = control_stability_operating_points()
%CONTROL_STABILITY_OPERATING_POINTS Frozen credible representative cases.
% The points are discrete explicit-mode cases, not a continuous corridor.

d2r = pi/180;
empty = struct('id','','betaMDeg',NaN,'speedMps',NaN, ...
    'mode','','condition',struct());
points = repmat(empty,3,1);

points(1).id = 'B15_V020';
points(1).betaMDeg = 15;
points(1).speedMps = 20;
points(1).mode = 'helicopter_longitudinal';

points(2).id = 'B45_V035';
points(2).betaMDeg = 45;
points(2).speedMps = 35;
points(2).mode = 'conversion_longitudinal';

points(3).id = 'B75_V080';
points(3).betaMDeg = 75;
points(3).speedMps = 80;
points(3).mode = 'airplane_longitudinal';

for k = 1:numel(points)
    points(k).condition = struct('V',points(k).speedMps, ...
        'betaM',points(k).betaMDeg*d2r,'gamma',0);
end
end
