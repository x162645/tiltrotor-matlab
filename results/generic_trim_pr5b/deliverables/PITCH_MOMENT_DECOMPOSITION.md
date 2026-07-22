# 俯仰力矩分解

所有力矩均关于 `mass_properties` 返回的实际重心，力臂项使用 `cross(r,F)`。重力通过实际重心施加，因此显式重力矩为零。左右机翼行是诊断拆分，`wing` 行才进入总和。

|pointId|component|MyNm|armMomentMyNm|intrinsicMomentMyNm|rXFromActualCGm|rZFromActualCGm|localSpeedMps|localDynamicPressurePa|localAlphaDeg|elevatorDeg|controlAtLimit|finiteReal|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|B15_V020|rotorLeft|968.83312|968.83312|0|0.16499714|-0.72827771|20|NaN|NaN|0|false|true|
|B15_V020|rotorRight|968.83312|968.83312|0|0.16499714|-0.72827771|20|NaN|NaN|0|false|true|
|B15_V020|wing|-260.92182|NaN|NaN|NaN|NaN|NaN|NaN|NaN|0|false|true|
|B15_V020|fuselage|9.7964604|9.7964604|0|0.17088286|0.096166655|20|245|9.9167695|0|false|true|
|B15_V020|horizontalTail|-1678.269|-1678.269|0|-5.0291171|0.14616666|20|245|9.9167695|0|false|true|
|B15_V020|verticalTail|-8.2718236|NaN|NaN|NaN|NaN|NaN|NaN|NaN|0|false|true|
|B15_V020|TOTAL|2.9031402e-06|NaN|NaN|NaN|NaN|NaN|NaN|NaN|0|false|true|
|B15_V020|gravity_or_CG_effect|0|NaN|NaN|NaN|NaN|NaN|NaN|NaN|0|false|true|
|B45_V035|rotorLeft|3215.6428|3215.6428|0|0.45078057|-0.56328057|35|NaN|NaN|-16.531352|false|true|
|B45_V035|rotorRight|3215.6428|3215.6428|0|0.45078057|-0.56328057|35|NaN|NaN|-16.531352|false|true|
|B45_V035|wing|-1872.8834|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-16.531352|false|true|
|B45_V035|fuselage|92.941604|92.941604|0|0.12045049|0.067049513|35|750.3125|21.751023|-16.531352|false|true|
|B45_V035|horizontalTail|-4585.5792|-4663.5138|77.934619|-5.0795495|0.11704951|35|750.3125|21.751023|-16.531352|false|true|
|B45_V035|verticalTail|-65.76458|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-16.531352|false|true|
|B45_V035|TOTAL|6.5434975e-06|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-16.531352|false|true|
|B45_V035|gravity_or_CG_effect|0|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-16.531352|false|true|
|B75_V040|rotorLeft|-1045.5532|-1045.5532|0|0.61577771|-0.27749714|40|NaN|NaN|-20|true|true|
|B75_V040|rotorRight|-1045.5532|-1045.5532|0|0.61577771|-0.27749714|40|NaN|NaN|-20|true|true|
|B75_V040|wing|-3374.9507|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V040|fuselage|99.55797|99.55797|0|0.091333345|0.016617143|40|980|19.186356|-20|true|true|
|B75_V040|horizontalTail|-1051.9712|-1175.1216|123.15043|-5.1086667|0.066617143|40|980|19.186356|-20|true|true|
|B75_V040|verticalTail|-72.025484|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V040|TOTAL|-6490.4957|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V040|gravity_or_CG_effect|0|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V060|rotorLeft|-524.34002|-524.34002|0|0.61577771|-0.27749714|60|NaN|NaN|-20|true|true|
|B75_V060|rotorRight|-524.34002|-524.34002|0|0.61577771|-0.27749714|60|NaN|NaN|-20|true|true|
|B75_V060|wing|-6957.3137|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V060|fuselage|170.32562|170.32562|0|0.091333345|0.016617143|60|2205|15.401146|-20|true|true|
|B75_V060|horizontalTail|6290.3108|6013.2223|277.08847|-5.1086667|0.066617143|60|2205|15.401146|-20|true|true|
|B75_V060|verticalTail|-122.9253|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V060|TOTAL|-1668.2827|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V060|gravity_or_CG_effect|0|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-20|true|true|
|B75_V080|rotorLeft|-345.60192|-345.60192|0|0.61577771|-0.27749714|80|NaN|NaN|-9.6560033|false|true|
|B75_V080|rotorRight|-345.60192|-345.60192|0|0.61577771|-0.27749714|80|NaN|NaN|-9.6560033|false|true|
|B75_V080|wing|-9360.1778|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-9.6560033|false|true|
|B75_V080|fuselage|133.64106|133.64106|0|0.091333345|0.016617143|80|3920|8.0914444|-9.6560033|false|true|
|B75_V080|horizontalTail|9999.5018|9761.6736|237.82819|-5.1086667|0.066617143|80|3920|8.0914444|-9.6560033|false|true|
|B75_V080|verticalTail|-81.761235|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-9.6560033|false|true|
|B75_V080|TOTAL|-2.060728e-05|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-9.6560033|false|true|
|B75_V080|gravity_or_CG_effect|0|NaN|NaN|NaN|NaN|NaN|NaN|NaN|-9.6560033|false|true|
