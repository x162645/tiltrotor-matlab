# PR51 物理纠偏报告

- 原 HEAD：`247e3a4b46d39b375152fd5fa8bea9e7a4ba9e74`
- 修正 HEAD：`587a0d3755bdcdc808324827ac131ebc939ad042`
- 路线：`PRESCRIBED_NACELLE_MOTION_TO_RIGID_BODY_ONE_WAY`
- 实际 CG：所有旋翼、机翼、机身、平尾、垂尾力矩统一关于 actual total CG。
- 质量属性：6000=5100+450+450 kg；42°/48° 点质量矩残差 2.84e-14 kg m，惯量重构残差 0。
- 故障：command freeze 与 kinematic lock 分离；mechanical jam 未实现。
- 测试：PR3 聚焦 17/17；完整 run_all_checks 通过；checkcode 0。
