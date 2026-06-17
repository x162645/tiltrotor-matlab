function Fbody = aero_force_body(D, Y, L, alpha, beta)
%AERO_FORCE_BODY 将风轴阻力、侧力和升力转换到机体系。
% 机体系 x前、y右、z下；D、L 均按正标量输入。

xWind = [cos(alpha)*cos(beta);
         sin(beta);
         sin(alpha)*cos(beta)];

yWind = [-cos(alpha)*sin(beta);
          cos(beta);
         -sin(alpha)*sin(beta)];

zWind = [-sin(alpha);
          0;
          cos(alpha)];

Fbody = -D*xWind + Y*yWind - L*zWind;
end
