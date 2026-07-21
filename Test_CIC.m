clc;
clear;
close all;

clear CIC_Integrator
clear CIC_Comb

R = 21;

disp('==============================')
disp(' Complete CIC Test')
disp('==============================')

for k = 1:500

    % Constant ADC input
    adc = int16(100);

    % Integrator (runs every sample)
    integ = CIC_Integrator(adc);

    % Decimate
    if mod(k,R)==0

        cic_out = CIC_Comb(integ);

        fprintf('Sample %3d --> CIC Output = %12d\n',k,cic_out);

    end

end