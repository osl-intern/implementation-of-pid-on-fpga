clc
clear
close all

disp('================ DAC TEST ================')
fprintf('%10s %15s\n','DAC Code','Voltage')
disp('------------------------------------------')

codes = [-2500 -2048 -1024 -500 -1 0 1 500 1024 2047 2500];

for k = 1:length(codes)

    v = DAC_Model(codes(k));

    fprintf('%10d %15.6f\n',codes(k),v);

end

disp('==========================================')