clc
clear

Fs = 0.975238e6;
Ts = 1/Fs;

Kp = 0.5; Ki = 10000; Kd = 2e-5;

z = tf('z',Ts);

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

C = minreal(C);

disp(C)

