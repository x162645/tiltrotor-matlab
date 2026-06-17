function trendReport = check_article_trends()
%CHECK_ARTICLE_TRENDS 检查若干关键稳定导数与操纵导数方向。
% 这是趋势诊断，不强制要求所有结果与论文数值相同。

rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(rootDir);
addpath(fullfile(rootDir,'model'));
addpath(fullfile(rootDir,'analysis'));

P = params_nominal();
d2r = pi/180;

x0 = [20;0;0;0;0;0;0;2*d2r;0];
u0 = [12*d2r;0;2*d2r;0;0;0;0];

[A,B] = linearize_numeric(x0,u0,0,P);

names = {
    'dudot/dq';
    'dqdot/dq';
    'dpdot/dp';
    'dwdot/dcollective';
    'dudot/dcyclic';
    'dqdot/dcyclic';
    'dvdot/ddiffCollective';
    'dpdot/ddiffCollective';
    'drdot/ddiffCollective';
    'dpdot/ddiffCyclic';
    'drdot/ddiffCyclic'
};

values = [
    A(1,5);
    A(5,5);
    A(4,4);
    B(3,1);
    B(1,3);
    B(5,3);
    B(2,2);
    B(4,2);
    B(6,2);
    B(4,4);
    B(6,4)
];

expectedSigns = [
     1;
    -1;
    -1;
    -1;
     1;
    -1;
     1;
    -1;
     1;
    -1;
    -1
];

actualSigns = sign(values);
matches = actualSigns == expectedSigns;

trendReport.names = names;
trendReport.values = values;
trendReport.expectedSigns = expectedSigns;
trendReport.actualSigns = actualSigns;
trendReport.matches = matches;
trendReport.matchFraction = mean(matches);

fprintf('\nArticle-trend diagnostic\n');
fprintf('========================\n');
for k = 1:numel(names)
    fprintf('%-28s value=% .6e expected=%+d match=%d\n', ...
        names{k},values(k),expectedSigns(k),matches(k));
end
fprintf('Match fraction: %.3f\n',trendReport.matchFraction);
end
