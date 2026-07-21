clc;
clear;
close all;

%% ==========================================================
% Pattern Search (With Settling Time Constraint)
% ==========================================================

x0 = [1 20000 5e-6];

lb = [0 1000 0];
ub = [20 500000 1e-4];

options = optimoptions('patternsearch',...
    'Display','iter',...
    'UseCompletePoll',true,...
    'UseCompleteSearch',true,...
    'MaxIterations',100,...
    'MaxFunctionEvaluations',1000,...
    'MeshTolerance',1e-6,...
    'StepTolerance',1e-6);

[xbest,fval] = patternsearch(@PID_CostFunction_Settling,...
    x0,...
    [],[],[],[],...
    lb,ub,...
    [],...
    options);

disp(' ')
disp('=========== BEST CONTROLLER ===========')

fprintf('Kp = %.8f\n',xbest(1));
fprintf('Ki = %.8f\n',xbest(2));
fprintf('Kd = %.10f\n',xbest(3));

fprintf('Cost = %.6f\n',fval);

best = PID_RunSimulation(xbest(1),xbest(2),xbest(3));

disp(best)

figure
plot(best.Time*1e6,best.Response,'LineWidth',2)
grid on
xlabel('Time (\mus)')
ylabel('Plant Output (V)')
title('Pattern Search (With Settling Constraint)')