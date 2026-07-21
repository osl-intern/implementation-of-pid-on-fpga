clc
clear
close all

%% ==========================================================
% Symbolic PID + Plant + Equivalent Decimation
%% ==========================================================


%% Symbolic Variables
syms z Kp Ki Kd

Ts = 1/0.975238e6;

%% ==========================================================
% Plant
%% ==========================================================

b = [0 ...
     0.00504359440518940 ...
     0.00484086584166143];

a = [1 ...
    -1.87433774280118 ...
     0.884222203048027];

G_num = poly2sym(b,z);
G_den = poly2sym(a,z);

G = G_num/G_den;
%% ==========================================================
% Load Equivalent Decimation Filter
%% ==========================================================

load Heq.mat

last = find(abs(heq)>1e-8,1,'last');

heq = heq(1:last);

H_num = poly2sym(heq,z);

H = H_num;      % FIR denominator = 1

%% ==========================================================
% Symbolic PID
%% ==========================================================

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

C = simplify(C);

%% ==========================================================
% Open Loop
%% ==========================================================

L = simplify(C*G*H);

disp('====================================')
disp('OPEN LOOP TF')
disp('====================================')

pretty(L)

%% ==========================================================
% Closed Loop
%% ==========================================================

T = simplify(L/(1+L));

disp('====================================')
disp('CLOSED LOOP TF')
disp('====================================')

pretty(T)

%% ==========================================================
% Numerator / Denominator
%% ==========================================================

[num,den] = numden(T);

den = collect(den,z);

coeff = coeffs(den,z,'All');

for i = 1:length(coeff)
    coeff(i) = collect(coeff(i),[Kp Ki Kd]);
end

disp('====================================')
disp('Polynomial Coefficients')
disp('====================================')

for i = 1:length(coeff)

    fprintf('\nCoefficient of z^%d\n',length(coeff)-i);

    pretty(coeff(i))

end

num = expand(num);

den = collect(den,z);

coeff = coeffs(den,z,'All');

for i = 1:length(coeff)
    coeff(i) = collect(coeff(i),[Kp Ki Kd]);
end

disp('====================================')
disp('Characteristic Polynomial')
disp('====================================')



%% ==========================================================
% Polynomial Coefficients
%% ==========================================================

coeff = coeffs(collect(den,z),z,'All');

disp('====================================')
disp('Polynomial Coefficients')
disp('====================================')

disp(coeff.')

%% ==========================================================
% Save Symbolic Characteristic Polynomial
%% ==========================================================

save('CharacteristicPolynomial.mat', ...
    'coeff', ...
    'Kp', ...
    'Ki', ...
    'Kd');

disp('Characteristic polynomial saved successfully.')