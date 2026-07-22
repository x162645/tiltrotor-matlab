# 13×10 参数来源与可信度

|参数/关系|当前值或形式|分类|来源与适用边界|
|-|-|-|-|
|13 状态/10 输入结构|9 刚体+4 短舱；10 输入|DERIVED|从 Berger 状态结构中低阶选取；不是 51 状态数值复现|
|短舱角语义|0°直升机、90°飞机|PROJECT_CONVENTION|项目既有约定；与 Berger 相反|
|`omegaN`|4 rad/s|RESEARCH_PLACEHOLDER|无型号级执行器辨识；仅作灵敏度基准|
|`zeta`|0.8|RESEARCH_PLACEHOLDER|同上|
|短舱惯量 `I`|250 kg·m²|RESEARCH_PLACEHOLDER|概念值；敏感性扫描，不作型号结论|
|角/速率/加速度/力矩限幅|代码中显式参数|ASSUMED_MODEL_PARAMETER / RESEARCH_PLACEHOLDER|用于研究限幅与故障；非鉴定数据|
|移动组件质量与轨迹|继承概念模型并左右等分|DERIVED + ASSUMED_MODEL_PARAMETER|对称极限保持既有质量属性|
|左右半翼滑流面积|继承 NUAA 物理基线区域模型|ASSUMED_MODEL_PARAMETER|左右独立求值；非风洞校准|
|`lateralCyclicScale`|1|ASSUMED_MODEL_PARAMETER|显式研究映射，扫描 0.5–1.5|
|命令延迟|外部历史上下文|ASSUMED_MODEL_PARAMETER|不是 13 状态内部动态|
|故障开关|卡滞/冻结/速率下降|RESEARCH_SCENARIO|离散研究情景，不是故障率数据|

文献依据：Berger 博士论文 PDF 90–91 页（原文 55–56，第 2.1.3.1/2.1.3.2 节，图 2.15、表 2.2）支持短舱作为翼尖转动自由度；PDF 93–95 页（原文 58–60，第 2.1.3.3 节，图 2.16/2.17）支持 51 状态/10 输入结构及角指令经 PID 产生两侧力矩。文献没有给出本项目上述占位参数的型号真值。
