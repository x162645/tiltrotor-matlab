function grid = generic_trim_dense_validation_grid()
%GENERIC_TRIM_DENSE_VALIDATION_GRID Frozen post-optimization corridor set.
% These points were selected and frozen after the C2 parameters.  They are
% numerical validation conditions, not external measurements.

d2r=pi/180;
betaDeg=[0;0;30;30;30;30;60;60;60;60;90;90;90];
speedMps=[0;10;15;25;35;45;30;45;60;75;50;70;90];
mode=[repmat({'helicopter_longitudinal'},2,1); ...
    repmat({'conversion_longitudinal'},8,1); ...
    repmat({'airplane_longitudinal'},3,1)];
pointId=arrayfun(@(b,v) sprintf('B%02d_V%03d',b,v), ...
    betaDeg,speedMps,'UniformOutput',false);
condition=arrayfun(@(v,b) struct('V',v,'betaM',b*d2r,'gamma',0), ...
    speedMps,betaDeg,'UniformOutput',false);
grid=table(pointId,betaDeg,speedMps,mode,condition);
grid.Properties.Description=['POST_FREEZE_DENSE_NUMERICAL_VALIDATION_SET; ' ...
    'includes beta 0/90 endpoints and beta 30/60 intermediate stations'];
end
