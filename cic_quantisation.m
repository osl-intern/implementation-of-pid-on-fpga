%% ==========================================================
% Quantize FIR Coefficients (Q2.16)
%% ==========================================================

clear
clc

%% Read Floating Coefficients

T = readtable('FIR_Coefficients.csv');

coeff = T.Var1;

%% Keep only first 23 coefficients (Symmetric FIR)

coeff = coeff(1:23);

%% Fixed-Point Settings

F = fimath( ...
    'RoundingMethod','Nearest', ...
    'OverflowAction','Saturate', ...
    'ProductMode','FullPrecision', ...
    'SumMode','FullPrecision');

T_COEFF = numerictype(1,18,16);     % Q2.16

coeff_fix = fi(coeff,T_COEFF,F);

%% Print Floating and Quantized Values

fprintf('\n');
disp('============= FIR FIXED COEFFICIENTS =============');
fprintf('Q Format : Q2.16\n\n');

for k = 1:23

    fprintf('coeff%-2d = %.15f;\n', ...
        k-1,...
        double(coeff_fix(k)));

end

disp('==================================================');

fprintf('\n');
disp('=========== INTEGER VALUES (Q2.16) ===========');

for k = 1:23

    intval = round(double(coeff_fix(k))*2^16);

    fprintf('coeff%-2d = %d;\n',k-1,intval);

end

disp('==============================================');

fprintf('\n');
disp('=========== BINARY VALUES (18 bits) ===========');

for k = 1:23

    fprintf('coeff%-2d = %s;\n',...
        k-1,...
        bin(coeff_fix(k)));

end

disp('===============================================');