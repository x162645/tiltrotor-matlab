function definition = build_trim_mode_definition(modeKey, P)
%BUILD_TRIM_MODE_DEFINITION Describe supported GUI trim-mode entries.
% This service intentionally separates enabled production trim from guarded
% scaffolds so the GUI cannot present a longitudinal trim as 6-DOF success.

if nargin < 2 || isempty(P)
    P = params_nominal();
end
if nargin < 1 || isempty(modeKey)
    modeKey = 'longitudinal_symmetric';
end
if isstring(modeKey) && isscalar(modeKey)
    modeKey = char(modeKey);
end

controlNames = get_control_input_names(P);
switch modeKey
    case 'longitudinal_symmetric'
        definition.key = modeKey;
        definition.label = '纵向对称配平';
        definition.enabled = true;
        definition.guarded = false;
        definition.solver = 'trim_symmetric';
        definition.residualNames = {'udot'; 'wdot'; 'qdot'};
        definition.unknownNames = {'theta'; 'collective'; 'cyclicLong'};
        definition.message = '默认生产路径，保持当前纵向对称配平行为。';
    case 'lateral_directional_balance'
        definition.key = modeKey;
        definition.label = '横侧向平衡/导数检查';
        definition.enabled = false;
        definition.guarded = true;
        definition.solver = 'guarded_scaffold';
        definition.residualNames = {'vdot'; 'pdot'; 'rdot'};
        definition.unknownNames = {'lateralCyclic'; 'aileron'; 'rudder'; ...
            'diffCollective'; 'diffCyclic'};
        definition.message = ['横侧向残差和候选控制通道已定义；完整求解尚未启用，' ...
            '不会输出假配平结果。'];
        definition.lateralCyclicAvailable = any(strcmp(controlNames, 'lateralCyclic'));
    case 'full_6dof'
        definition.key = modeKey;
        definition.label = '六自由度联合配平';
        definition.enabled = false;
        definition.guarded = true;
        definition.solver = 'guarded_scaffold';
        definition.residualNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'};
        definition.unknownNames = {'theta'; 'phi'; 'collective'; 'cyclicLong'; ...
            'lateralCyclic'; 'aileron'; 'elevator'; 'rudder'; ...
            'diffCollective'; 'diffCyclic'};
        definition.message = ['六自由度联合配平需要完整未知量、残差和约束定义；' ...
            '当前未启用完整求解。'];
        definition.lateralCyclicAvailable = any(strcmp(controlNames, 'lateralCyclic'));
    otherwise
        error('build_trim_mode_definition:UnknownMode', ...
            'Unknown trim mode %s.', modeKey);
end
definition.activeControlNames = controlNames;
end
