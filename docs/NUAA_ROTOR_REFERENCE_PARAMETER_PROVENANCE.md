# 南航公开公式旋翼参考模型参数来源

本表只记录参考模型新增或读取的参数。数值来自当前通用概念模型时，目的仅为
同参数比较，不意味着来自南航论文、XV-15 或试验数据。

|参数|代码变量|当前值/规则|单位|分类|来源与用途|风险|
|---|---|---:|---|---|---|---|
|旋翼半径|`P.rotor.R`|3.80|m|`SHARED_CURRENT_PARAMETER`|当前概念模型；同参数比较|非型号确认值|
|根切比|`P.rotor.rootCut`|0.18|1|`SHARED_CURRENT_PARAMETER`|当前概念模型；气动积分起点|不等于挥舞铰偏置|
|桨叶数|`P.rotor.Nb`|3|1|`SHARED_CURRENT_PARAMETER`|当前概念模型|来源不能由数值相同反推|
|弦长|`P.rotor.chord`|0.38|m|`SHARED_CURRENT_PARAMETER`|当前概念模型|无径向分布|
|线性扭转|`P.rotor.twistTip`|-6|deg|`SHARED_CURRENT_PARAMETER`|当前概念模型|不能代表真实非线性扭转|
|转速|`P.rotor.Omega`|62|rad/s|`SHARED_CURRENT_PARAMETER`|当前概念模型|无短舱角调度|
|单桨叶质量|`P.rotor.bladeMass`|45|kg|`ASSUMED_MODEL_PARAMETER`|当前概念假设|对挥舞幅值敏感|
|质量分布|`P.rotor.bladeMassDistribution`|均匀全展向|-|`ASSUMED_MODEL_PARAMETER`|当前概念假设|真实根部与结构分布未知|
|挥舞惯量|`P.rotor.Ib`|`m_b R^2/3`|kg m2|`DERIVED`|由均匀质量分布推导|受质量假设控制|
|一阶质量矩|`P.rotor.Sblade`|`m_b R/2`|kg m|`DERIVED`|由均匀质量分布推导|重力相位敏感|
|升力斜率|`P.rotor.liftSlope`|5.7|1/rad|`SHARED_CURRENT_PARAMETER`|同参数低阶翼型闭合|无 Mach/Re 依赖|
|最大升力系数|`P.rotor.CLmax`|1.35|1|`SHARED_CURRENT_PARAMETER`|双曲正切限幅|非试验极曲线|
|零升阻力|`P.rotor.CD0`|0.011|1|`SHARED_CURRENT_PARAMETER`|二次阻力极曲线|非试验极曲线|
|二次阻力系数|`P.rotor.kCD`|0.012|1|`SHARED_CURRENT_PARAMETER`|二次阻力极曲线|非试验极曲线|
|径向格点|`options.nRadial`|默认与当前模型相同|1|`NUMERICAL_IMPLEMENTATION_CHOICE`|同参数基准；另做收敛扫描|离散误差需量化|
|方位格点|`options.nAzimuth`|默认与当前模型相同|1|`NUMERICAL_IMPLEMENTATION_CHOICE`|同参数基准；另做收敛扫描|谐波误差需量化|
|诱导迭代容差|`options.inducedTol`|默认与当前模型相同|1|`NUMERICAL_IMPLEMENTATION_CHOICE`|收敛判据|非物理参数|
|诱导松弛|固定半步更新|0.5|1|`EXACT_PUBLIC_FORMULA`|Drones 2022 PDF 5，式(13)后文字|只适用于公开迭代结构|
|挥舞残差容差|`options.flapResidualTol`|默认与当前模型相同|1|`NUMERICAL_IMPLEMENTATION_CHOICE`|谐波平衡收敛|非物理参数|
|铰偏置|未实现|未知|m|`UNKNOWN`|论文未公开|限制挥舞解释|
|桨毂刚度|未实现|未知|N m/rad|`UNKNOWN`|论文未公开|限制刚性旋翼适用性|
|结构阻尼|未实现|未知|N m s/rad|`UNKNOWN`|论文未公开|不能分析瞬态桨叶模态|
|负推力诱导分支|未实现|未知|-|`NOT_IMPLEMENTED`|论文未公开|风车/自转不可用|

