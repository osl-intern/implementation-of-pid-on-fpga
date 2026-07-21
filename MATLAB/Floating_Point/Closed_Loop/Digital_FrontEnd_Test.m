clc;
clear;
close all;

clear ADC_Model
clear CIC_Integrator
clear CIC_Comb
clear FIR_Filter

%% Parameters

R = 21;

controller_cycles = 120;

%% Constant Plant Output

plant_voltage = 3.5;      % Analog voltage

disp('=========================================')
disp(' Digital Front-End Verification')
disp('=========================================')

for cycle = 1:controller_cycles

    %% High-Speed Section

    for i = 1:R

        % ADC
        adc_code = ADC_Model(plant_voltage);

        % CIC Integrator
        integ_out = CIC_Integrator(adc_code);

    end

    %% Low-Speed Section

    % CIC Comb
    cic_out = CIC_Comb(integ_out);

    % Normalize
    cic_norm = CIC_Normalize(cic_out);

    % FIR
    fir_out = FIR_Filter(cic_norm);

    fprintf('Cycle %2d : ',cycle);
    fprintf('ADC = %6d   ',adc_code);
    fprintf('CIC = %12d   ',cic_out);
    fprintf('Norm = %10.4f   ',cic_norm);
    fprintf('FIR = %10.4f\n',fir_out);

end