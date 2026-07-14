function definition = build_trim_mode_definition(modeKey, P)
%BUILD_TRIM_MODE_DEFINITION Describe supported GUI trim-mode entries.
% The non-default entries call real solver services. They may return
% success=false with diagnostics, but they are not guarded placeholders.

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
        definition.enabled = true;
        definition.guarded = false;
        definition.solver = 'trim_lateral_directional_balance';
        definition.residualNames = {'vdot'; 'pdot'; 'rdot'};
        if any(strcmp(controlNames, 'lateralCyclic'))
            definition.unknownNames = {'lateralCyclic'; 'diffCollective'; ...
                'diffCyclic'; 'aileron'; 'rudder'};
        else
            definition.unknownNames = {'diffCollective'; 'diffCyclic'; ...
                'aileron'; 'rudder'};
        end
        definition.message = ['基于纵向对称基准点求解 vdot/pdot/rdot，' ...
            '并用小控制量正则化处理横侧向控制欠定问题。'];
        definition.lateralCyclicAvailable = any(strcmp(controlNames, 'lateralCyclic'));
        definition.regularization = 'control_delta_l2';
    case {'full_6dof', 'full_6dof_straight_trim'}
        definition.key = 'full_6dof_straight_trim';
        definition.label = '六自由度联合配平';
        definition.enabled = true;
        definition.guarded = false;
        definition.solver = 'trim_full_6dof_straight';
        definition.residualNames = {'udot'; 'vdot'; 'wdot'; 'pdot'; 'qdot'; 'rdot'};
        if any(strcmp(controlNames, 'lateralCyclic'))
            definition.unknownNames = {'theta'; 'phi'; 'collective'; ...
                'cyclicLong'; 'lateralCyclic'; 'rudder'};
        else
            definition.unknownNames = {'theta'; 'phi'; 'collective'; ...
                'cyclicLong'; 'aileron'; 'rudder'};
        end
        definition.message = ['直线定常六自由度刚体平衡求解 udot/vdot/wdot/' ...
            'pdot/qdot/rdot；不表示外部验证或操稳品质验证。'];
        definition.lateralCyclicAvailable = any(strcmp(controlNames, 'lateralCyclic'));
        definition.regularization = 'small_initial_deviation_l2';
    otherwise
        error('build_trim_mode_definition:UnknownMode', ...
            'Unknown trim mode %s.', modeKey);
end
definition.activeControlNames = controlNames;
end
