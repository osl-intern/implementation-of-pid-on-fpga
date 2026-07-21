clc
clear
close all

%% ==========================================================
% Symbolic Variables
%% ==========================================================

syms z Kp Ki Kd

Ts = 1/0.975238e6;

%% ==========================================================
% Choose Controller
%% ==========================================================

Kp0 = 5;
Ki0 = 1000;
Kd0 = 20e-6;

%% ==========================================================
% Plant
%% ==========================================================

b = [0 ...
     0.00504359440518940 ...
     0.00484086584166143];

a = [1 ...
    -1.87433774280118 ...
     0.884222203048027];

G_tf = tf(b,a,Ts);

G_num = poly2sym(b,z);
G_den = poly2sym(a,z);

G_sym = simplify(G_num/G_den);

%% ==========================================================
% FIR
%% ==========================================================

load Heq.mat

last = find(abs(heq)>1e-8,1,'last');
heq = heq(1:last);

Heq_tf = tf(heq,1,Ts);

H_sym = poly2sym(heq,z);

%% ==========================================================
% PID
%% ==========================================================

C = Kp ...
    + Ki*Ts/(1-z^-1) ...
    + (Kd/Ts)*(1-z^-1);

%% ==========================================================
% Plant poles
%% ==========================================================

disp('======================================')
disp('PLANT POLES')
disp('======================================')

disp(pole(G_tf))

%% ==========================================================
% FIR poles
%% ==========================================================

disp('======================================')
disp('FIR POLES')
disp('======================================')

disp(pole(Heq_tf))

%% ==========================================================
% Case 1 : Plant only
%% ==========================================================

disp('======================================')
disp('CLOSED LOOP : PID + PLANT')
disp('======================================')

L1 = simplify(C*G_sym);

[num1,den1] = numden(L1);

Char1 = expand(num1+den1);

coeff1 = coeffs(collect(Char1,z),z,'All');

coeff1 = double(subs(coeff1,...
    [Kp Ki Kd],...
    [Kp0 Ki0 Kd0]));

coeff1 = coeff1(:).';

p1 = roots(coeff1);

disp(p1)

fprintf('\nMaximum |pole| = %.12f\n',max(abs(p1)));

%% ==========================================================
% Case 2 : FIR only
%% ==========================================================

disp('======================================')
disp('CLOSED LOOP : PID + FIR')
disp('======================================')

L2 = simplify(C*H_sym);

[num2,den2] = numden(L2);

Char2 = expand(num2+den2);

coeff2 = coeffs(collect(Char2,z),z,'All');

coeff2 = double(subs(coeff2,...
    [Kp Ki Kd],...
    [Kp0 Ki0 Kd0]));

coeff2 = coeff2(:).';

p2 = roots(coeff2);

disp(p2)

fprintf('\nMaximum |pole| = %.12f\n',max(abs(p2)));

%% ==========================================================
% Case 3 : Plant + FIR
%% ==========================================================

disp('======================================')
disp('CLOSED LOOP : PID + PLANT + FIR')
disp('======================================')

L3 = simplify(C*G_sym*H_sym);

[num3,den3] = numden(L3);

Char3 = expand(num3+den3);

coeff3 = coeffs(collect(Char3,z),z,'All');

coeff3 = double(subs(coeff3,...
    [Kp Ki Kd],...
    [Kp0 Ki0 Kd0]));

coeff3 = coeff3(:).';

p3 = roots(coeff3);

disp(p3)

fprintf('\nMaximum |pole| = %.12f\n',max(abs(p3)));

%% ==========================================================
% Search for suspicious pole
%% ==========================================================

target = 17.437985;

fprintf('\n======================================\n');
fprintf('SEARCHING FOR %.6f\n',target);
fprintf('======================================\n');

fprintf('\nPlant only:\n');
disp(p1(abs(abs(p1)-target)<1e-3))

fprintf('\nFIR only:\n');
disp(p2(abs(abs(p2)-target)<1e-3))

fprintf('\nPlant + FIR:\n');
disp(p3(abs(abs(p3)-target)<1e-3))