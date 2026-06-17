function [Ftotal, Mtotal, info] = total_forces_moments(x, uCtrl, betaM, P)
%TOTAL_FORCES_MOMENTS 汇总全部气动力、推进力和相应力矩。
% 重力不在本函数加入，由 tiltrotor_eom.m 单独处理。

x = x(:);
uCtrl = uCtrl(:);
validate_inputs(x, uCtrl, betaM, P);

mp = mass_properties(betaM, P);

collective = uCtrl(1);
diffCollective = uCtrl(2);
cyclic = uCtrl(3);
diffCyclic = uCtrl(4);

ctrlRight.collective = collective + diffCollective;
ctrlRight.cyclicLong = cyclic + diffCyclic;

ctrlLeft.collective = collective - diffCollective;
ctrlLeft.cyclicLong = cyclic - diffCyclic;

% 对操纵量进行物理限幅。
ctrlRight.collective = clamp(ctrlRight.collective, P.control.collectiveLim);
ctrlLeft.collective  = clamp(ctrlLeft.collective,  P.control.collectiveLim);
ctrlRight.cyclicLong = clamp(ctrlRight.cyclicLong, P.control.cyclicLim);
ctrlLeft.cyclicLong  = clamp(ctrlLeft.cyclicLong,  P.control.cyclicLim);

[FrotL, MrotL, rotL] = rotor_model_bemt( ...
    x, ctrlLeft, betaM, -1, mp.cgShift, P);

[FrotR, MrotR, rotR] = rotor_model_bemt( ...
    x, ctrlRight, betaM, +1, mp.cgShift, P);

[Fwing, Mwing, wing] = wing_model( ...
    x, uCtrl, betaM, mp.cgShift, rotL, rotR, P);

[Ffus, Mfus, fus] = fuselage_model(x, mp.cgShift, P);

elevator = clamp(uCtrl(6), P.control.elevatorLim);
rudder = clamp(uCtrl(7), P.control.rudderLim);

[Fht, Mht, htail] = horizontal_tail_model( ...
    x, elevator, mp.cgShift, P);

[Fvt, Mvt, vtail] = vertical_tail_model( ...
    x, rudder, mp.cgShift, P);

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
