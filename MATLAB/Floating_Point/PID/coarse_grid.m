Kp = 1;
Ki = 20000;
Kd = 5e-6;

Heq = 1;

z = tf('z',Ts);

C = Kp + Ki*Ts/(1-z^-1) + (Kd/Ts)*(1-z^-1);

L = minreal(C*G);

T = feedback(L,1);

pole(T)

[GM,PM,Wcg,Wcp] = margin(L)

GM
PM
20*log10(GM)

