clc
clear

Fs = 0.975238e6;
Ts = 1/Fs;

coeff = readmatrix('FIR_Coefficients.csv');

Hfir = tf(coeff',1,Ts);

disp(Hfir)