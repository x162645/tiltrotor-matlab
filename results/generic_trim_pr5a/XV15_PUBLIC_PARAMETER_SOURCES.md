# XV-15 公开参数来源

参数集 `GENERIC_MODEL_WITH_XV15_PUBLIC_OVERLAY` 是部分、显式 opt-in 的公开值覆盖层，不是完整 XV-15 模型。

主要一手来源：NASA TM X-62407（1975，Tilt Rotor Project Office Staff，Martin Maisel 协调）与 NASA TM-81244（1980，Dugan、Erhart、Schroers）。书目信息由 NASA NTRS 条目与报告扉页交叉核对。每行保留题名、报告号、作者、年份、PDF 页、印刷页、原单位、换算和适用构型。

未列字段沿用通用基线，并标记 `INHERITED_GENERIC_NOT_XV15`。旋翼转速只采用 565 rpm 直升机/悬停参考；公开的 458 rpm 飞机值无法由当前单标量接口同时表达。

## 覆盖清单

|codePath|valueSI|unitSI|claimClass|reportNumber|authors|publicationYear|sourceFile|pdfPage|printedPage|manualReview|
|---|---|---|---|---|---|---|---|---|---|---|
|mass.m|5896.70081|kg|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|11|5|false|
|mass.I0|57486.6810093|kg m^2|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|mass.KI|1639.96697591|kg m^2/rad|XV15_DERIVED|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|true|
|mass.I0|19388.1966611|kg m^2|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|mass.KI|949.454565002|kg m^2/rad|XV15_DERIVED|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|true|
|mass.I0|67112.9884424|kg m^2|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|mass.KI|-690.512410911|kg m^2/rad|XV15_DERIVED|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|true|
|rotor.R|3.81|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|20|17|false|
|rotor.Nb|3|1|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|20|17|false|
|rotor.Omega|59.1666616426|rad/s|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|22|19|true|
|rotor.chord|0.3556|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|20|17|false|
|rotor.twistTip|-0.785398163397|rad|XV15_DIRECT|NASA TM-81244 / AVRADCOM-TR-80-A-15 / A-8343|D. C. Dugan; R. G. Erhart; L. G. Schroers|1980|NASA_TM_81244.pdf|4|2|true|
|rotor.pivotY|4.902708|m|XV15_DERIVED|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|wing.S|15.70061376|m^2|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|wing.b|9.805416|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|true|
|wing.c|1.6002|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|htail.S|4.66837776|m^2|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|htail.c|1.194816|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|vtail.SEach|2.34580176|m^2|XV15_DERIVED|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|true|
|vtail.c|1.133856|m|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|15|12|false|
|control.elevatorLim|[-0.349065850399 0.349065850399]|rad|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|17|14|false|
|control.rudderLim|[-0.349065850399 0.349065850399]|rad|XV15_DIRECT|NASA TM X-62407 / A-5870|Tilt Rotor Project Office Staff; coordinated by Martin Maisel|1975|NASA_TM_X_62407.pdf|17|14|false|

## 声明边界

Partial public XV-15 values only.  Geometry, mass state, coefficient families, component positions, controls, and inertias not listed here remain unknown or inherited generic values.
