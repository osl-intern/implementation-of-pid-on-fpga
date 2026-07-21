clc;
clear;
close all;

R = 21;

disp('==============================')
disp(' CIC Integrator Test')
disp('==============================')

for k = 1:50

    y = CIC_Integrator(100);

    fprintf('Sample %2d : %12d\n',k,y);

    if mod(k,R)==0
        fprintf('---- Decimation Instant ----\n');
    end

end