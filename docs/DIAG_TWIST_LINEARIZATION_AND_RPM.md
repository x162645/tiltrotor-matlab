# [DIAG] XV-15 扭转线性化与验证转速只读诊断

## 范围与口径

- 诊断提交不修改 `model/`、参数、数值或冻结结果。
- “实际记录 rpm”仅指仓库录入的试验点字段中直接存在的 rpm；由 `Vtip` 和 `R` 换算的值不改称试验记录 rpm。
- 浮点数按 MATLAB R2021a `%.17g` 输出，不做显示位数四舍五入。

## 1. 扭转线性化残差

### 1.1 实际送入线性拟合的数据

冻结验证路径在 `analysis/run_xv15_frozen_low_order_validation.m` 中构造：

```matlab
xGeom = linspace(0.0875, 1, 4001).';
theta_deg = 289.98*xGeom.^5 - 892.87*xGeom.^4 + 987.06*xGeom.^3 ...
    - 438.31*xGeom.^2 + 15.695*xGeom + 32.057;
```

因此，实际拟合输入为 4001 点，精确站位定义为
`r/R = 0.0875 + j*(1-0.0875)/4000`，`j=0,...,4000`。这 4001 点是五次多项式求值，不是直接把 51 点 `TWISTA` 表传给 builder。新增脚本逐点打印全部 4001 个 `(r/R, true_deg, fit_deg, residual_deg)`。

仓库来源标注如下：

|内容|报告/定位|仓库录入记录|
|---|---|---|
|冻结验证实际使用的五次多项式|NASA/CR-2017-219486，Appendix A，Figure A-2|`analysis/nasa_metal_twist_deg.m:1-13`；冻结 runner 内同式见 `analysis/run_xv15_frozen_low_order_validation.m:299-301`|
|公开的直接径向表|NASA/TP-2004-212262，Appendix A，CAMRAD II XV-15 reference rotor，`RPROP=0:0.02:1`、51 点 `TWISTA`|`analysis/nasa_metal_twist_reference_table_deg.m:1-15`|

直接录入的 51 点 `TWISTA` 原始记录为：

|r/R|TWISTA (deg)|r/R|TWISTA (deg)|r/R|TWISTA (deg)|
|---:|---:|---:|---:|---:|---:|
|0|34.43|0.02|33.49|0.04|32.45|
|0.06|31.55|0.08|30.79|0.10|30.03|
|0.12|29.03|0.14|28.03|0.16|26.88|
|0.18|25.58|0.20|24.28|0.22|23.03|
|0.24|21.78|0.26|20.43|0.28|18.98|
|0.30|17.53|0.32|16.48|0.34|15.43|
|0.36|14.20|0.38|12.79|0.40|11.38|
|0.42|10.64|0.44|9.90|0.46|9.03|
|0.48|8.03|0.50|7.03|0.52|6.43|
|0.54|5.83|0.56|5.19|0.58|4.51|
|0.60|3.83|0.62|3.31|0.64|2.79|
|0.66|2.30|0.68|1.84|0.70|1.38|
|0.72|0.83|0.74|0.27|0.76|-0.27|
|0.78|-0.82|0.80|-1.37|0.82|-1.86|
|0.84|-2.35|0.86|-2.82|0.88|-3.27|
|0.90|-3.72|0.92|-4.14|0.94|-4.56|
|0.96|-4.98|0.98|-5.40|1.00|-5.82|

### 1.2 实际权重

不是 `UNWEIGHTED`。冻结验证调用者显式传入 4001 个梯形积分权重：

|行|站位|权重|构造|
|---:|---:|---:|---|
|1|0.0875|0.5|先 `ones(size(xGeom))`，再执行 `twistWeights([1 end]) = 0.5`|
|2–4000|从 0.087728125 到 0.999771875|1|`ones(size(xGeom))` 保持不变|
|4001|1|0.5|同一端点赋值|

`model/parameter_sets/build_xv15_v1_hover_validation_instance.m:208-222` 使用

```matlab
twistTipEq = sum(weights.*dx.*dtheta)/sum(weights.*dx.^2);
```

其中 `dx` 是相对 0.75R 的 rootCut-to-tip 归一化坐标。若调用者不提供 `sourceData.twist.weights`，builder 才在 `:458-462` 建立全 1 权重；本次冻结验证没有走该分支。

### 1.3 拟合结果

拟合直线以 `u=r/R` 表示为 `theta_fit_deg(u) = slope*u + intercept`：

|量|MATLAB 实际值|
|---|---:|
|`twistTipEq_rad`，归一化 rootCut→tip 总变化|-0.63439075874023942|
|`twistTipEq_deg`|-36.347913037917763|
|斜率，rad/(r/R)|-0.695222749304372|
|斜率，deg/(r/R)|-39.833329356622201|
|截距，rad|0.52139572193469907|
|截距，deg|29.873774323034898|
|代码保留的普通 RMS，rad|0.039816758967958256|
|代码保留的普通 RMS，deg|2.2813322427536797|
|代码保留的加权 RMS，rad|0.039806808580173457|
|代码保留的加权 RMS，deg|2.2807621275290919|
|代码保留的最大绝对残差，rad|0.074988866785743402|
|代码保留的最大绝对残差，deg|4.2965455772918562|

### 1.4 逐点残差

残差定义与代码一致：`真实扭转 - 拟合直线`。新增脚本的最后 4001 行逐点打印：

```text
radial_residuals (rR, true_deg, fit_deg, true_minus_fit_deg)
```

首点和末点核对值为：

|r/R|真实扭转 (deg)|拟合值 (deg)|残差 (deg)|
|---:|---:|---:|---:|
|0.087499999999999994|30.684903581622315|26.388358004330456|4.2965455772918562|
|1|-6.3880000000000408|-9.9595550335873035|3.5715550335872628|

完整逐点输出由 `analysis/diagnose_xv15_twist_equivalent_collective_offset.m` 产生；脚本返回同样的 4001 元素 `rR`、`thetaSource_deg`、`thetaFit_deg` 和 `residual_deg` 数组。

## 2. 转速

### 2.1 试验点是否直接记录实际 rpm

仓库中的 OARF Run 14、Run 15 和 WADC 试验点录入均无 rpm 字段；只有 `Vtip_fps`（WADC 另有 `Mtip`）。因此逐点状态如下。

```text
OARF_RUN15_POINT07  NOT_RECORDED
OARF_RUN15_POINT08  NOT_RECORDED
OARF_RUN15_POINT09  NOT_RECORDED
OARF_RUN15_POINT10  NOT_RECORDED
OARF_RUN15_POINT11  NOT_RECORDED
OARF_RUN15_POINT12  NOT_RECORDED
OARF_RUN15_POINT13  NOT_RECORDED
OARF_RUN15_POINT14  NOT_RECORDED
OARF_RUN15_POINT15  NOT_RECORDED
OARF_RUN14_POINT15  NOT_RECORDED
OARF_RUN14_POINT16  NOT_RECORDED
OARF_RUN14_POINT17  NOT_RECORDED
OARF_RUN14_POINT18  NOT_RECORDED
OARF_RUN14_POINT19  NOT_RECORDED
OARF_RUN14_POINT20  NOT_RECORDED
OARF_RUN14_POINT21  NOT_RECORDED
OARF_RUN14_POINT22  NOT_RECORDED
OARF_RUN14_POINT23  NOT_RECORDED
OARF_RUN14_POINT24  NOT_RECORDED
OARF_RUN14_POINT25  NOT_RECORDED
OARF_RUN14_POINT26  NOT_RECORDED
OARF_RUN14_POINT27  NOT_RECORDED
WADC_RUN1_POINT01   NOT_RECORDED
WADC_RUN1_POINT02   NOT_RECORDED
WADC_RUN1_POINT03   NOT_RECORDED
WADC_RUN1_POINT04   NOT_RECORDED
WADC_RUN1_POINT05   NOT_RECORDED
WADC_RUN1_POINT06   NOT_RECORDED
WADC_RUN1_POINT07   NOT_RECORDED
WADC_RUN1_POINT08   NOT_RECORDED
WADC_RUN1_POINT09   NOT_RECORDED
WADC_RUN1_POINT10   NOT_RECORDED
WADC_RUN1_POINT11   NOT_RECORDED
WADC_RUN1_POINT12   NOT_RECORDED
WADC_RUN1_POINT13   NOT_RECORDED
WADC_RUN2_POINT01   NOT_RECORDED
WADC_RUN2_POINT02   NOT_RECORDED
WADC_RUN2_POINT03   NOT_RECORDED
WADC_RUN2_POINT04   NOT_RECORDED
WADC_RUN2_POINT05   NOT_RECORDED
WADC_RUN2_POINT06   NOT_RECORDED
WADC_RUN2_POINT07   NOT_RECORDED
WADC_RUN2_POINT08   NOT_RECORDED
WADC_RUN2_POINT09   NOT_RECORDED
WADC_RUN2_POINT10   NOT_RECORDED
WADC_RUN2_POINT11   NOT_RECORDED
WADC_RUN2_POINT12   NOT_RECORDED
WADC_RUN3_POINT01   NOT_RECORDED
WADC_RUN3_POINT02   NOT_RECORDED
WADC_RUN3_POINT03   NOT_RECORDED
WADC_RUN3_POINT04   NOT_RECORDED
WADC_RUN3_POINT05   NOT_RECORDED
WADC_RUN3_POINT06   NOT_RECORDED
WADC_RUN3_POINT07   NOT_RECORDED
WADC_RUN3_POINT08   NOT_RECORDED
WADC_RUN3_POINT09   NOT_RECORDED
WADC_RUN3_POINT10   NOT_RECORDED
WADC_RUN3_POINT11   NOT_RECORDED
WADC_RUN3_POINT12   NOT_RECORDED
```

来源录入：OARF Run 14 与 Run 15 为 NASA/CR-2017-219486 Appendix A Table A-2；WADC 为同报告 Appendix A Table A-3，仓库文件 `analysis/data/xv15_wadc_metal_table_a3.csv`。

### 2.2 验证运行时 `P.rotor.Omega`

三组验证均按 `Omega=(Vtip_fps*0.3048)/3.81` 逐点赋值。以下 rpm 仅是同一模型输入的反算显示值，不是试验点直接记录值。

#### OARF Run 15

|点|Vtip (ft/s)|Omega (rad/s)|反算 rpm|路径|
|---|---:|---:|---:|---|
|07|769.0|61.519999999999996|587.47272594080403|`testPoint.rpm` 由 Vtip 换算后传入 builder|
|08|768.7|61.496000000000002|587.24354282275181|同上|
|09–12|768.4|61.472000000000001|587.01435970469947|同上|
|13–14|768.0|61.440000000000005|586.70878221396299|同上|
|15|767.7|61.416000000000004|586.47959909591066|同上|

结论标签：`TEST_CONDITION_DIRECT_EXPLICIT`；没有走 `REFERENCE_HOVER_DEFAULT_NOT_TEST_POINT_CONFIRMED`。

#### OARF Run 14

|点|Vtip (ft/s)|Omega (rad/s)|反算 rpm|路径|
|---|---:|---:|---:|---|
|15–19|769.4|61.552|587.77830343154051|验证脚本直接 `P.rotor.Omega=Vtip/R`|
|20–21|769.0|61.519999999999996|587.47272594080403|同上|
|22–23|768.7|61.496000000000002|587.24354282275181|同上|
|24–25|768.4|61.472000000000001|587.01435970469947|同上|
|26|768.0|61.440000000000005|586.70878221396299|同上|
|27|767.7|61.416000000000004|586.47959909591066|同上|

结论标签：逐点 Vtip 派生；没有走 `REFERENCE_HOVER_DEFAULT_NOT_TEST_POINT_CONFIRMED`。

#### WADC Stage-5 实际运行的 15 点

|Run/点|Vtip (ft/s)|Omega (rad/s)|反算 rpm|路径|
|---|---:|---:|---:|---|
|1/6|600.8|48.064|458.97739108613149|`P.rotor.Omega=Vtip/R`|
|1/7|598.2|47.856000000000002|456.99113739634464|同上|
|1/8|596.9|47.752000000000002|455.99801055145122|同上|
|1/9–10|595.6|47.648000000000003|455.00488370655779|同上|
|2/6|699.0|55.920000000000002|533.99666506192727|同上|
|2/7–9|701.6|56.128000000000007|535.98291875171412|同上|
|2/10|702.9|56.231999999999999|536.97604559660749|同上|
|3/6|742.2|59.376000000000005|566.99903406146268|同上|
|3/7|743.5|59.480000000000004|567.99216090635616|同上|
|3/8|739.6|59.168000000000006|565.01278037167583|同上|
|3/9–10|740.9|59.271999999999998|566.0059072165692|同上|

结论标签：逐点 Vtip 派生；没有走 `REFERENCE_HOVER_DEFAULT_NOT_TEST_POINT_CONFIRMED`。

### 2.3 默认 565 rpm 受影响点

受影响测试点清单：无。

## 3. 等效总距偏移

脚本对 `residual=true-fit` 在 `rootCut=0.0875` 到 `1` 上做归一化积分。若用拟合直线替代真实分布，表中正值是按对应权重恢复平均真实桨距所需叠加的正总距偏移。

|权重|平均残差/等效总距偏移 (deg)|物理含义|
|---|---:|---|
|不加权|0.05015080839227392|每个径向长度等权时，真实扭转的平均桨距比拟合直线高该值。|
|推力权重，正比于 `(r/R)^2`|0.45494457716938325|按理想化推力径向权重计，拟合直线比真实分布少该等效总距。|
|扭矩权重，正比于 `(r/R)^3`|0.87831481729346217|按理想化扭矩径向权重计，拟合直线比真实分布少该等效总距。|

脚本自测使用一个已知线性输入，MATLAB 实际输出为：

```text
selfTestMeanResidual_unweighted_deg = 0
selfTestMeanResidual_thrust_r2_deg = 0
selfTestMeanResidual_torque_r3_deg = 0
```

脚本只在函数内构造局部数组、计算和打印；不写回参数、不调用旋翼模型、不写文件、不改变冻结结果。

## 4. 身份门禁

任务基线为 `26acaa582358c7358c93f078b3b7fee05f28e9a7`。身份门禁结果：

- `git status --short --untracked-files=no`：空；全部既有跟踪文件与任务基线逐位相同。
- `git diff --quiet HEAD -- model params_nominal.m`：退出码 0。
- `git diff --quiet HEAD -- results validation`：退出码 0；既有验证输出文件逐位未变。
- 新脚本 MATLAB R2021a：退出码 0；4001 点输出均为有限实数；三个自测值均为 0；`checkcode` 问题数 0。
- 完整 `run_all_checks`：28/29 项通过。唯一未通过项是仓库既有 `check_control_stability_assessment` 中固定比较 PR #61 (`99acba44740087fdf3d7cdc82efd191c87cfb2d1`) 的断言；当前任务基线在该历史提交之后已经包含 4 个既有 model 文件，因此该跨历史断言返回非零。该失败与本任务新增文件无重叠。

本任务的逐位身份条件为 `PASS`：`model/`、参数、既有验证脚本和既有验证输出均未改变。新增文件仅为本报告与只读诊断脚本。
