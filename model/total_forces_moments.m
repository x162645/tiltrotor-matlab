function [Ftotal, Mtotal, info] = total_forces_moments(x, uCtrl, betaM, P)
%TOTAL_FORCES_MOMENTS 汇总全部气动力、推进力和相应力矩。
% 重力不在本函数加入，由 tiltrotor_eom.m 单独处理。

x = x(:);
uCtrl = uCtrl(:);
validate_inputs(x, uCtrl, betaM, P);

mp = mass_properties(betaM, P);

ctrl = map_control_inputs(uCtrl, P);

ctrlRight.collective = ctrl.collective + ctrl.diffCollective;
ctrlRight.cyclicLong = ctrl.cyclicLong + ctrl.diffCyclic;
ctrlRight.lateralCyclic = ctrl.lateralCyclic;

ctrlLeft.collective = ctrl.collective - ctrl.diffCollective;
ctrlLeft.cyclicLong = ctrl.cyclicLong - ctrl.diffCyclic;
ctrlLeft.lateralCyclic = ctrl.lateralCyclic;

% 对旋翼侧控制量应用当前模型输入包络。
ctrlRight.collective = clamp(ctrlRight.collective, P.control.collectiveLim);
ctrlLeft.collective  = clamp(ctrlLeft.collective,  P.control.collectiveLim);
ctrlRight.cyclicLong = clamp(ctrlRight.cyclicLong, P.control.cyclicLim);
ctrlLeft.cyclicLong  = clamp(ctrlLeft.cyclicLong,  P.control.cyclicLim);
ctrlRight.lateralCyclic = clamp(ctrlRight.lateralCyclic, P.control.cyclicLim);
ctrlLeft.lateralCyclic  = clamp(ctrlLeft.lateralCyclic,  P.control.cyclicLim);

% 对常规舵面统一应用当前模型输入包络。保留原始命令用于诊断。
uApplied = uCtrl;
uApplied(1) = 0.5*(ctrlRight.collective + ctrlLeft.collective);
uApplied(2) = 0.5*(ctrlRight.collective - ctrlLeft.collective);
uApplied(3) = 0.5*(ctrlRight.cyclicLong + ctrlLeft.cyclicLong);
uApplied(4) = 0.5*(ctrlRight.cyclicLong - ctrlLeft.cyclicLong);
if ctrl.numInputs == 8
    uApplied(5) = 0.5*(ctrlRight.lateralCyclic + ctrlLeft.lateralCyclic);
    uApplied(6) = clamp(ctrl.aileron, P.control.aileronLim);
    uApplied(7) = clamp(ctrl.elevator, P.control.elevatorLim);
    uApplied(8) = clamp(ctrl.rudder, P.control.rudderLim);
else
    uApplied(5) = clamp(ctrl.aileron, P.control.aileronLim);
    uApplied(6) = clamp(ctrl.elevator, P.control.elevatorLim);
    uApplied(7) = clamp(ctrl.rudder, P.control.rudderLim);
end
appliedCtrl = map_control_inputs(uApplied, P);

[FrotL, MrotL, rotL] = rotor_model_bemt( ...
    x, ctrlLeft, betaM, -1, mp.cgShift, P);

[FrotR, MrotR, rotR] = rotor_model_bemt( ...
    x, ctrlRight, betaM, +1, mp.cgShift, P);

[Fwing, Mwing, wing] = wing_model( ...
    x, uApplied, betaM, mp.cgShift, rotL, rotR, P);

[Ffus, Mfus, fus] = fuselage_model(x, mp.cgShift, P);

[Fht, Mht, htail] = horizontal_tail_model( ...
    x, appliedCtrl.elevator, mp.cgShift, P);

[Fvt, Mvt, vtail] = vertical_tail_model( ...
    x, appliedCtrl.rudder, mp.cgShift, P);

Ftotal = FrotL + FrotR + Fwing + Ffus + Fht + Fvt;
Mtotal = MrotL + MrotR + Mwing + Mfus + Mht + Mvt;

% 使用 cell 保存不同字段的异构部件诊断结构体。
info.components = {
    struct('name','rotorLeft',  'F',FrotL,'M',MrotL,'data',rotL);
    struct('name','rotorRight', 'F',FrotR,'M',MrotR,'data',rotR);
    struct('name','wing',       'F',Fwing,'M',Mwing,'data',wing);
    struct('name','fuselage',   'F',Ffus, 'M',Mfus, 'data',fus);
    struct('name','horizontalTail','F',Fht,'M',Mht,'data',htail);
    struct('name','verticalTail','F',Fvt,'M',Mvt,'data',vtail)
};

info.massProperties = mp;
info.commandedControls = uCtrl;
info.appliedControls = uApplied;
info.mappedControls = ctrl;
info.appliedMappedControls = appliedCtrl;
info.appliedRotorControls.left = ctrlLeft;
info.appliedRotorControls.right = ctrlRight;
info.rotorLeft = rotL;
info.rotorRight = rotR;
info.wing = wing;
info.fuselage = fus;
info.horizontalTail = htail;
info.verticalTail = vtail;
info.F = Ftotal;
info.M = Mtotal;

    function y = clamp(value, limits)
        y = min(max(value, limits(1)), limits(2));
    end
end
