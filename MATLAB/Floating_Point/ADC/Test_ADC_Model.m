clc;
clear;
close all;

%% Test Voltages

Vin = [-12 -10 -5 -2 -1 0 1 2 5 10 12];

fprintf('\n');
disp('================ ADC TEST ================')
fprintf('%10s %15s\n','Voltage','ADC Code')
disp('------------------------------------------')

for k = 1:length(Vin)

    code = ADC_Model(Vin(k));

    fprintf('%10.3f %15d\n',Vin(k),code);

end

disp('==========================================')