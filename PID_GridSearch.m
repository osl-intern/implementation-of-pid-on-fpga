clc;
clear;
close all;

%% ==========================================================
% PID GRID SEARCH
% ===========================================================

disp('===========================================')
disp('      PID GRID SEARCH STARTED')
disp('===========================================')

%% Search Space

Kp_list = 2:1:8;

Ki_list = 60000:20000:220000;

Kd_list = 0:5e-6:4e-5;

%% Total Simulations

total_runs = length(Kp_list) * ...
             length(Ki_list) * ...
             length(Kd_list);

fprintf('Total Simulations = %d\n\n',total_runs);

%% Result Storage

Results = [];

run_number = 0;

best_cost = inf;

%% ==========================================================
% Grid Search
% ===========================================================

for kp = Kp_list

    for ki = Ki_list

        for kd = Kd_list

            run_number = run_number + 1;

            fprintf('Run %4d / %4d   ',run_number,total_runs);

            fprintf('Kp = %.3f   ',kp);
            fprintf('Ki = %.0f   ',ki);
            fprintf('Kd = %.6f\n',kd);

            %% Run Simulation

            result = PID_RunSimulation(kp,ki,kd);

            %% Cost

            cost = PID_CostFunction([kp ki kd]);

            %% Store

            Results = [Results;
                kp ...
                ki ...
                kd ...
                result.Overshoot ...
                result.SettlingTime ...
                result.RiseTime ...
                result.SSE ...
                result.MaxPID ...
                result.MaxDAC ...
                cost];

            %% Best Controller

            if cost < best_cost

                best_cost = cost;

                best_result = result;

                best_kp = kp;
                best_ki = ki;
                best_kd = kd;

                fprintf('   ---> NEW BEST CONTROLLER\n');

            end

        end

    end

end

%% ==========================================================
% Sort Results
% ===========================================================

Results = sortrows(Results,10);

%% ==========================================================
% Convert to Table
% ===========================================================

T = array2table(Results);

T.Properties.VariableNames = ...
{
'Kp',...
'Ki',...
'Kd',...
'Overshoot',...
'SettlingTime',...
'RiseTime',...
'SSE',...
'MaxPID',...
'MaxDAC',...
'Cost'
};

%% Save

writetable(T,'PID_GridSearch_Results.csv');

%% ==========================================================
% Display Top 10
% ===========================================================

disp(' ')
disp('===========================================')
disp('TOP 10 CONTROLLERS')
disp('===========================================')

disp(T(1:10,:))

%% ==========================================================
% Best Controller
% ===========================================================

disp(' ')
disp('===========================================')
disp('BEST CONTROLLER FOUND')
disp('===========================================')

fprintf('Kp = %.6f\n',best_kp);
fprintf('Ki = %.6f\n',best_ki);
fprintf('Kd = %.8f\n',best_kd);

fprintf('\n');

fprintf('Overshoot     = %.3f %%\n',best_result.Overshoot);

fprintf('Rise Time     = %.6e s\n',best_result.RiseTime);

fprintf('Settling Time = %.6e s\n',best_result.SettlingTime);

fprintf('SSE           = %.6e V\n',best_result.SSE);

fprintf('Max PID       = %.2f\n',best_result.MaxPID);

fprintf('Max DAC       = %.2f V\n',best_result.MaxDAC);

disp('===========================================')