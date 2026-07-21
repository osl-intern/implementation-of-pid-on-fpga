clc;
clear;
close all;

%% ==========================================================
% Pattern Search (No Settling Time Constraint)
% ==========================================================

% Starting point from Grid Search
x0 = [1 20000 5e-6];

% Lower Bounds
lb = [0 1000 0];

% Upper Bounds
ub = [20 500000 1e-4];

%% Pattern Search Options

options = optimoptions('patternsearch',...
    'Display','iter',...
    'UseCompletePoll',true,...
    'UseCompleteSearch',true,...
    'MaxIterations',100,...
    'MaxFunctionEvaluations',1000,...
    'MeshTolerance',1e-6,...
    'StepTolerance',1e-6);

%% Run Optimization

[xbest,fval] = patternsearch(@PID_CostFunction,...
    x0,...
    [],[],[],[],...
    lb,ub,...
    [],...
    options);

%% Display

disp(' ')
disp('=========== BEST CONTROLLER ===========')

fprintf('Kp = %.8f\n',xbest(1));
fprintf('Ki = %.8f\n',xbest(2));
fprintf('Kd = %.10f\n',xbest(3));

fprintf('Cost = %.6f\n',fval);

%% Verify

best = PID_RunSimulation(xbest(1),xbest(2),xbest(3));

disp(best)

figure
plot(best.Time*1e6,best.Response,'LineWidth',2)
grid on
xlabel('Time (\mus)')
ylabel('Plant Output (V)')
title('Pattern Search (No Settling Constraint)')