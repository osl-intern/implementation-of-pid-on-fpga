clc;
clear;
close all;

clear CIC_Integrator
clear CIC_Comb

R = 21;

disp('==============================')
disp(' CIC Normalization Test')
disp('==============================')

for k = 1:200

    adc = int16(100);

    integ = CIC_Integrator(adc);

    if mod(k,R)==0

        cic_raw = CIC_Comb(integ);

        cic_norm = CIC_Normalize(cic_raw);

        fprintf('Sample %3d : Raw = %12d   Normalized = %10.6f\n',...
            k,cic_raw,cic_norm);

    end

end