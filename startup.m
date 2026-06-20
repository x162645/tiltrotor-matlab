function startup()
%STARTUP 将项目所需目录加入 MATLAB 搜索路径。

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'model'));
addpath(fullfile(rootDir, 'analysis'));
addpath(fullfile(rootDir, 'services'));
addpath(fullfile(rootDir, 'app'));
addpath(fullfile(rootDir, 'tests'));
addpath(fullfile(rootDir, 'examples'));

resultDir = fullfile(rootDir, 'results');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

fprintf('Tiltrotor forward model v2 paths added.\n');
fprintf('Project root: %s\n', rootDir);
end
