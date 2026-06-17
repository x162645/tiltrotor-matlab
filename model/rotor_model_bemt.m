function [Fbody, Mbody, out] = rotor_model_bemt(x, rotorCtrl, betaM, side, cgShift, P)
%ROTOR_MODEL_BEMT 倾转旋翼叶素/动量模型。
%
% side = -1：左旋翼；side = +1：右旋翼。
% rotorCtrl.collective：该侧总距，rad。
% rotorCtrl.cyclicLong：该侧纵向周期变距，rad。
%
% 对应论文式(4)~(15)的机理链路。挥舞采用一阶谐波准定常闭合。

x = x(:);
Vbody = x(1:3);
omegaBody = x(4:6);

if ~(side == -1 || side == 1)
    error('side 必须取 -1（左）或 +1（右）。');
end

% 论文采用右旋翼逆时针、左旋翼顺时针。这里用相反符号表示转向。
rotDir = side;

% 短舱未倾转时推力向上；90度时推力向前。
eT = [sin(betaM); 0; -cos(betaM)];
eD = [cos(betaM); 0;  sin(betaM)];
eY = [0; 1; 0];

% 旋翼轮毂相对于机体参考重心的位置。
rHub0 = [P.rotor.pivotX + P.mass.RH*sin(betaM);
         side*P.rotor.pivotY;
         P.rotor.pivotZ - P.mass.RH*cos(betaM)];

rHub = rHub0 - cgShift;

% 刚体点速度：V_h = V_CG + omega x r_h。
Vhub = Vbody + cross(omegaBody, rHub);

Vaxial = dot(Vhub, eT);
Vlong  = dot(Vhub, eD);
Vlat   = dot(Vhub, eY);

tipSpeed = P.rotor.Omega * P.rotor.R;
muLong = Vlong / max(tipSpeed, eps);
muLat  = Vlat  / max(tipSpeed, eps);

% 一阶谐波准定常挥舞。正 a1 使推力向 eD 倾斜。
a1 = P.rotor.flapCyclicGain*rotorCtrl.cyclicLong ...
   + P.rotor.flapMuGain*muLong ...
   + P.rotor.flapQGain*omegaBody(2)/P.rotor.Omega;

b1 = P.rotor.flapLatMuGain*muLat ...
   - P.rotor.flapPGain*omegaBody(1)/P.rotor.Omega;

a1 = min(max(a1, -P.rotor.flapMax), P.rotor.flapMax);
b1 = min(max(b1, -P.rotor.flapMax), P.rotor.flapMax);

eTeff = eT + tan(a1)*eD + tan(b1)*eY;
eTeff = eTeff / norm(eTeff);

A = pi*P.rotor.R^2;

% 悬停量级初值。诱导速度定义为沿正推力轴对应的等效入流标量。
vi = sqrt(max(P.mass.m*P.env.g/2, 1)/(2*P.env.rho*A));

for iter = 1:P.rotor.inducedMaxIter
    loads = blade_loads(vi);

    Vplane = hypot(Vlong, Vlat);
    denom = 2*P.env.rho*A*sqrt(Vplane^2 + (Vaxial + vi)^2);
    viTarget = max(loads.T, 0) / max(denom, 1e-8);

    viNew = (1 - P.rotor.inducedRelax)*vi ...
          + P.rotor.inducedRelax*viTarget;

    if abs(viNew - vi) < P.rotor.inducedTol*max(1, abs(vi))
        vi = viNew;
        break;
    end
    vi = viNew;
end

loads = blade_loads(vi);

% 旋翼盘内阻力分量由叶素积分给出；主推力沿挥舞后的桨盘法向。
Fbody = loads.T*eTeff + loads.Hlong*eD + loads.Hlat*eY;

% 旋翼反扭矩与旋转方向相反。
Mreaction = -rotDir*loads.Q*eT;

% 可选旋翼陀螺力矩。
Hrot = rotDir*P.rotor.Jpolar*P.rotor.Omega*eT;
Mgyro = -cross(omegaBody, Hrot);

Mbody = cross(rHub, Fbody) + Mreaction + Mgyro;

out.side = side;
out.rotDir = rotDir;
out.rHub = rHub;
out.Vhub = Vhub;
out.Vaxial = Vaxial;
out.Vlong = Vlong;
out.Vlat = Vlat;
out.muLong = muLong;
out.muLat = muLat;
out.a1 = a1;
out.b1 = b1;
out.eT = eT;
out.eTeff = eTeff;
out.thrust = loads.T;
out.torque = loads.Q;
out.Hlong = loads.Hlong;
out.Hlat = loads.Hlat;
out.inducedVelocity = vi;
out.iterations = iter;
out.F = Fbody;
out.M = Mbody;

    function loads = blade_loads(viMean)
        % 中点积分比直接使用端点更稳定。
        r0 = P.rotor.rootCut*P.rotor.R;
        rEdges = linspace(r0, P.rotor.R, P.rotor.nRadial + 1);
        rMid = 0.5*(rEdges(1:end-1) + rEdges(2:end));
        dr = diff(rEdges);

        psi = (0:P.rotor.nAzimuth-1)*(2*pi/P.rotor.nAzimuth);

        Tsum = 0;
        Qsum = 0;
        HvecSum = [0; 0];

        for ia = 1:numel(psi)
            az = psi(ia);

            % 物理切向单位向量。rotDir 控制左右旋翼转向。
            etD = -rotDir*sin(az);
            etY =  rotDir*cos(az);

            % 叶素平面内平移速度在切向方向的投影。
            VtanTrans = Vlong*etD + Vlat*etY;

            for ir = 1:numel(rMid)
                r = rMid(ir);
                xR = r/P.rotor.R;

                twist = P.rotor.twistTip*(r-r0)/max(P.rotor.R-r0, eps);

                % v2 中周期变距通过桨盘倾斜闭合，避免在叶素桨距中重复计入。
                thetaBlade = rotorCtrl.collective + twist;

                UT = P.rotor.Omega*r + VtanTrans;

                inflowShape = 1 + P.rotor.inflowHarmonic*xR*cos(az);
                inflowShape = max(inflowShape, 0.05);
                viField = viMean*inflowShape;

                UP = Vaxial + viField;

                W = hypot(UT, UP);
                phiInflow = atan2(UP, max(abs(UT), 1e-8));

                alphaBlade = thetaBlade - phiInflow;

                CL = P.rotor.CLmax*tanh( ...
                    P.rotor.liftSlope*alphaBlade/P.rotor.CLmax);
                CD = P.rotor.CD0 + P.rotor.kCD*CL^2;

                qElem = 0.5*P.env.rho*W^2;
                dL = qElem*P.rotor.chord*CL*dr(ir);
                dD = qElem*P.rotor.chord*CD*dr(ir);

                dT = dL*cos(phiInflow) - dD*sin(phiInflow);
                dH = dD*cos(phiInflow) + dL*sin(phiInflow);
                dQ = r*dH;

                Tsum = Tsum + dT;
                Qsum = Qsum + dQ;

                % dH 方向与叶素运动切向方向相反。
                HvecSum = HvecSum - dH*[etD; etY];
            end
        end

        factor = P.rotor.Nb/P.rotor.nAzimuth;

        loads.T = factor*Tsum;
        loads.Q = factor*Qsum;
        loads.Hlong = factor*HvecSum(1);
        loads.Hlat  = factor*HvecSum(2);
    end
end
