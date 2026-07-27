function xdot = dynamic_model(x,u,kappa,p)

vx   = x(1);
vy   = x(2);
r    = x(3);
ey   = x(4);
epsi = x(5);

Tlong = u(1);
delta = u(2);

vxSafe = max(vx,p.minimumModelSpeed);

alphaF = atan2(vy + p.lf*r,vxSafe) - delta;
alphaR = atan2(vy - p.lr*r,vxSafe);

Fyf = -p.Cf*alphaF;
Fyr = -p.Cr*alphaR;

Fdrive = p.eta*Tlong/p.Rw;

Fresistance = ...
    p.Crr*p.m*p.g + ...
    0.5*p.rho*p.Cd*p.area*vx*abs(vx);

vxDot = vy*r + ...
    (Fdrive*cos(delta) ...
    - Fyf*sin(delta) ...
    - Fresistance)/p.m;

vyDot = -vx*r + ...
    (Fyf*cos(delta) ...
    + Fyr ...
    + Fdrive*sin(delta))/p.m;

rDot = ...
    (p.lf*Fyf*cos(delta) ...
    - p.lr*Fyr ...
    + p.lf*Fdrive*sin(delta))/p.Iz;

eyDot = vy + vx*epsi;
epsiDot = r - vx*kappa;

xdot = [vxDot;vyDot;rDot;eyDot;epsiDot];
end