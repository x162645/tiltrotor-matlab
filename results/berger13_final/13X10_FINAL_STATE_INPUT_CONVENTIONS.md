# 13×10 状态、输入与符号约定

## 状态

`x13=[u v w p q r phi theta psi betaML betaMR betaMLdot betaMRdot]^T`。

- `u,v,w`：机体系线速度，m/s；机体轴为前、右、下。
- `p,q,r`：机体系滚转、俯仰、偏航角速度，rad/s。
- `phi,theta,psi`：3-2-1 欧拉角，rad。
- `betaML,betaMR`：左右短舱倾转角，rad；本项目 0° 为直升机模式、90° 为飞机模式。
- `betaMLdot,betaMRdot`：左右短舱角速度，rad/s。

Berger 论文的短舱角定义与本项目相反：其 `delta_nac=90°` 为直升机模式、0° 为飞机模式。外部比较必须先转换角度语义。

## 两套互不混淆的输入接口

扭矩接口：`u10_torque=[collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder nacelleTorqueLeft nacelleTorqueRight]^T`，末两项单位 N·m。

角指令接口：`u10_command=[collective diffCollective cyclicLong diffCyclic lateralCyclic aileron elevator rudder betaMLCommand betaMRCommand]^T`，末两项单位 rad。没有任何函数按运行时选项改变第 9/10 输入含义。

`diffCyclic` 是差动纵向周期变距的历史代码名，不是横向周期变距；`lateralCyclic` 是独立、显式 opt-in 的横向通道。

## 对称/差动坐标

`betaSym=(betaML+betaMR)/2`，`betaDiff=(betaMR-betaML)/2`；角速度和指令作同样变换。正 `betaDiff` 表示右短舱角大于左短舱角。状态/输入变换矩阵均有显式可逆性测试。
