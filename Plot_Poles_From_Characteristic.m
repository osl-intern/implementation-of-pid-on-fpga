clc
clear
% close all

%% Load symbolic characteristic polynomial

load CharacteristicPolynomial.mat

%% Select controller

Kp0 = 5;
Ki0 = 100000;
Kd0 = 20e-8;

%% Substitute gains

coeff_num = subs(coeff,[Kp Ki Kd],[Kp0 Ki0 Kd0]);

coeff_num = double(coeff_num(:).');

%% Compute poles

p = roots(coeff_num);

%% Display poles

disp('==========================================')
disp('Closed-loop poles')
disp('==========================================')

disp(p)

%% Stability

if all(abs(p)<1)
    fprintf('\nSYSTEM IS STABLE\n');
else
    fprintf('\nSYSTEM IS UNSTABLE\n');
end

fprintf('\nMaximum |pole| = %.12f\n',max(abs(p)));

%% =====================================================
% Locate the largest pole
%% =====================================================

[~,idxMax] = max(abs(p));

fprintf('\nLargest pole = %.12f %+.12fi\n',...
    real(p(idxMax)),imag(p(idxMax)));

%% =====================================================
% Check repeated poles
%% =====================================================

fprintf('\n==========================================\n');
fprintf('Checking repeated poles\n');
fprintf('==========================================\n');

tol = 1e-8;

for k = 1:length(p)

    n = sum(abs(p(k)-p)<tol);

    if n>1
        fprintf('Pole %2d is repeated %d times\n',k,n);
    end

end

%% =====================================================
% Sensitivity to Kp
%% =====================================================

delta = 1e-3;

coeff2 = subs(coeff,...
    [Kp Ki Kd],...
    [Kp0*(1+delta) Ki0 Kd0]);

coeff2 = double(coeff2(:).');

p2 = roots(coeff2);

fprintf('\n==========================================\n');
fprintf('Pole movement after changing Kp\n');
fprintf('==========================================\n');

for k = 1:length(p)

    d = min(abs(p(k)-p2));

    fprintf('%2d  %.3e\n',k,d);

end

%% =====================================================
% Sensitivity to Ki
%% =====================================================

coeff3 = subs(coeff,...
    [Kp Ki Kd],...
    [Kp0 Ki0*(1+delta) Kd0]);

coeff3 = double(coeff3(:).');

p3 = roots(coeff3);

fprintf('\n==========================================\n');
fprintf('Pole movement after changing Ki\n');
fprintf('==========================================\n');

for k = 1:length(p)

    d = min(abs(p(k)-p3));

    fprintf('%2d  %.3e\n',k,d);

end

%% =====================================================
% Sensitivity to Kd
%% =====================================================

coeff4 = subs(coeff,...
    [Kp Ki Kd],...
    [Kp0 Ki0 Kd0*(1+delta)]);

coeff4 = double(coeff4(:).');

p4 = roots(coeff4);

fprintf('\n==========================================\n');
fprintf('Pole movement after changing Kd\n');
fprintf('==========================================\n');

for k = 1:length(p)

    d = min(abs(p(k)-p4));

    fprintf('%2d  %.3e\n',k,d);

end

%% =====================================================
% Polynomial conditioning
%% =====================================================

fprintf('\n==========================================\n');
fprintf('Polynomial conditioning\n');
fprintf('==========================================\n');

fprintf('Largest coefficient : %.3e\n',max(abs(coeff_num)));
fprintf('Smallest coefficient: %.3e\n',min(abs(coeff_num)));
fprintf('Ratio               : %.3e\n',...
    max(abs(coeff_num))/min(abs(coeff_num)));

%% =====================================================
% Pole Plot
%% =====================================================

figure

plot(real(p),imag(p),'rx',...
    'MarkerSize',10,...
    'LineWidth',2)

hold on

theta = linspace(0,2*pi,1000);

plot(cos(theta),sin(theta),'b','LineWidth',1.5)

plot(real(p(idxMax)),imag(p(idxMax)),...
    'ko',...
    'MarkerSize',14,...
    'LineWidth',2)

axis equal
grid on

xlabel('Real Axis')
ylabel('Imaginary Axis')

title(sprintf('Closed Loop Poles\nKp=%.3f  Ki=%.3f  Kd=%g',Kp0,Ki0,Kd0))

legend('Poles','Unit Circle','Largest Pole')