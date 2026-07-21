clc;
clear;
close all;

clear FIR_Filter

disp('==============================')
disp(' FIR Filter Test')
disp('==============================')

for k = 1:150

    x = 100;

    y = FIR_Filter(x);

    fprintf('Sample %3d : %12.6f\n',k,y);

end