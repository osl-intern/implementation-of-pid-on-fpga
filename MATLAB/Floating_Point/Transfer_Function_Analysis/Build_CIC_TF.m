clc
clear

Fs = 0.975238e6;
Ts = 1/Fs;

R = 21;
N = 5;
M = 1;

num = [1 zeros(1,R-1) -1];
den = [1 -1];

Hcic = tf(1,1,Ts);

for k = 1:N
    Hcic = Hcic * tf(num,den,Ts);
end

Hcic = Hcic/(R^N);

disp(Hcic)