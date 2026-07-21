clc
clear
close all

%% ==========================================================
% Symbolic Variables
%% ==========================================================

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

%% Numeric Plant

G_tf = tf(b,a,Ts);

disp('===================================================')
disp('NUMERIC PLANT')
disp('===================================================')

G_tf

%% Symbolic Plant

G_num = poly2sym(b,z);
G_den = poly2sym(a,z);

G_sym = simplify(G_num/G_den);

disp('===================================================')
disp('SYMBOLIC PLANT')
disp('===================================================')

pretty(G_sym)

%% ==========================================================
% FIR
%% ==========================================================

load Heq.mat

last = find(abs(heq)>1e-8,1,'last');

heq = heq(1:last);

Heq_tf = tf(heq,1,Ts);

disp('===================================================')
disp('NUMERIC FIR')
disp('===================================================')

Heq_tf

H_num = poly2sym(heq,z);

H_sym = simplify(H_num);

disp('===================================================')
disp('SYMBOLIC FIR')
disp('===================================================')

pretty(H_sym)

%% ==========================================================
% Frequency Response Verification (Magnitude + Phase)
%% ==========================================================

fprintf('\n');
disp('===================================================')
disp('VERIFY FIR TRANSFER FUNCTION')
disp('===================================================')

f = 10000;                 % Hz
w = 2*pi*f;

%% Numeric TF

H_tf = squeeze(freqresp(Heq_tf,w));

%% Symbolic TF

z0 = exp(1j*w*Ts);

H_symbolic = double(subs(H_sym,z,z0));

%% Magnitude

fprintf('\nMagnitude\n');
fprintf('Numeric  = %.12f\n',abs(H_tf));
fprintf('Symbolic = %.12f\n',abs(H_symbolic));
fprintf('Error    = %.3e\n',abs(abs(H_tf)-abs(H_symbolic)));

%% Phase

phase_tf  = angle(H_tf)*180/pi;
phase_sym = angle(H_symbolic)*180/pi;

fprintf('\nPhase\n');
fprintf('Numeric  = %.6f deg\n',phase_tf);
fprintf('Symbolic = %.6f deg\n',phase_sym);
fprintf('Error    = %.6f deg\n',phase_tf-phase_sym);

%% Complex Error

fprintf('\nComplex Difference = %.3e\n',abs(H_tf-H_symbolic));

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

L = simplify(C*G_sym*H_sym);

[numL,denL] = numden(L);
%% Verification 1

Char1 = expand(numL + denL);

%% Verification 2

Tsym = simplify(L/(1+L));

[numT,denT] = numden(Tsym);

Char2 = expand(denT);

disp('Difference between both characteristic polynomials')

pretty(expand(Char1-Char2))

numL = expand(numL);

denL = expand(denL);

disp('===================================================')
disp('OPEN LOOP NUMERATOR')
disp('===================================================')

pretty(numL)

disp('===================================================')
disp('OPEN LOOP DENOMINATOR')
disp('===================================================')

pretty(denL)

%% ==========================================================
% TRUE CHARACTERISTIC POLYNOMIAL
%% ==========================================================

CharPoly = expand(numL + denL);
%% ==========================================================
% Check the fixed poles
%% ==========================================================

fixed_roots = [-17.437984919534 ...
    6.5622 ...
    -1.96892];

for k = 1:length(fixed_roots)

    fprintf('\n====================================\n');
    fprintf('Testing z = %.12f\n',fixed_roots(k));

    expr = simplify(subs(CharPoly,z,fixed_roots(k)));

    expr = collect(expr,[Kp Ki Kd]);

    pretty(expr)

end

disp('===================================================')
disp('TRUE CHARACTERISTIC POLYNOMIAL')
disp('===================================================')

pretty(CharPoly)

%% ==========================================================
% Polynomial Coefficients
%% ==========================================================

coeff = coeffs(collect(CharPoly,z),z,'All');

for i = 1:length(coeff)

    coeff(i) = collect(coeff(i),[Kp Ki Kd]);

end

disp('===================================================')
disp('COEFFICIENTS')
disp('===================================================')

for i = 1:length(coeff)

    fprintf('\nCoefficient of z^%d\n',length(coeff)-i);

    pretty(coeff(i))

end

%% ==========================================================
% Save
%% ==========================================================

save CharacteristicPolynomial.mat coeff Kp Ki Kd

disp(' ')
disp('Characteristic Polynomial Saved.')

%% ==========================================================
% Compare Symbolic vs TF Poles
%% ==========================================================

Kp0 = 5;
Ki0 = 1000;
Kd0 = 20e-6;

%% Symbolic poles

coeff_num = subs(coeff,[Kp Ki Kd],[Kp0 Ki0 Kd0]);
coeff_num = double(coeff_num(:));

p_sym = sort(roots(coeff_num));

%% TF poles

z_tf = tf('z',Ts);

C_tf = Kp0 ...
    + Ki0*Ts/(1-z_tf^-1) ...
    + (Kd0/Ts)*(1-z_tf^-1);

Heq_tf = tf(heq,1,Ts);

L_tf = minreal(C_tf*G_tf*Heq_tf);
T_tf = feedback(L_tf,1);

p_tf = sort(pole(T_tf));

fprintf('\n=====================================\n');
fprintf('Number of symbolic poles : %d\n',length(p_sym));
fprintf('Number of TF poles       : %d\n',length(p_tf));

fprintf('\nLargest |pole| (Symbolic) = %.6f\n',max(abs(p_sym)));
fprintf('Largest |pole| (TF)       = %.6f\n',max(abs(p_tf)));

%% Plot comparison

figure
plot(real(p_tf),imag(p_tf),'bo','MarkerSize',8,'DisplayName','TF')
hold on
plot(real(p_sym),imag(p_sym),'rx','MarkerSize',8,'LineWidth',1.5,'DisplayName','Symbolic')

theta = linspace(0,2*pi,500);
plot(cos(theta),sin(theta),'k--','DisplayName','Unit Circle')

axis equal
grid on
legend
title('Pole Comparison: TF vs Symbolic')
xlabel('Real')
ylabel('Imaginary')