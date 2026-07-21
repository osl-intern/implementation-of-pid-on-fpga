function y = CIC_Comb(x)
global CURRENT_CYCLE
% ============================================================
% CIC_Comb.m
%
% 5-Stage CIC Comb Filter
%
% Input :
%   x -> Decimated Integrator Output
%
% Output:
%   y -> CIC Output
%
% Runs at 975.238 kSPS
% ============================================================

persistent d1 d2 d3 d4 d5
persistent comb1_hist comb2_hist comb3_hist comb4_hist comb5_hist
persistent comb_idx

%-------------------------------------------------------
% Range Tracking
%-------------------------------------------------------

persistent min_in max_in min_nz_in

persistent min_c1 max_c1 min_nz_c1
persistent min_c2 max_c2 min_nz_c2
persistent min_c3 max_c3 min_nz_c3
persistent min_c4 max_c4 min_nz_c4
persistent min_c5 max_c5 min_nz_c5

if isempty(d1)
    min_in = inf; max_in = -inf; min_nz_in = inf;

    min_c1 = inf; max_c1 = -inf; min_nz_c1 = inf;
    min_c2 = inf; max_c2 = -inf; min_nz_c2 = inf;
    min_c3 = inf; max_c3 = -inf; min_nz_c3 = inf;
    min_c4 = inf; max_c4 = -inf; min_nz_c4 = inf;
    min_c5 = inf; max_c5 = -inf; min_nz_c5 = inf;

    d1 = 0;
    d2 = 0;
    d3 = 0;
    d4 = 0;
    d5 = 0;

    comb1_hist = [];
    comb2_hist = [];
    comb3_hist = [];
    comb4_hist = [];
    comb5_hist = [];

    comb_idx = 0;

end

global CURRENT_CYCLE

if CURRENT_CYCLE == 1000    % or controller_cycles if you pass it
    fprintf('Comb1 Input          = %.0f\n', x);
end

c1 = x - d1;
min_in = min(min_in,x);
max_in = max(max_in,x);

if x~=0
    min_nz_in = min(min_nz_in,abs(x));
end

min_c1 = min(min_c1,c1);
max_c1 = max(max_c1,c1);

if c1~=0
    min_nz_c1 = min(min_nz_c1,abs(c1));
end
d1 = x;

c2 = c1 - d2;
min_c2 = min(min_c2,c2);
max_c2 = max(max_c2,c2);
if c2~=0
    min_nz_c2=min(min_nz_c2,abs(c2));
end
d2 = c1;

c3 = c2 - d3;
min_c3 = min(min_c3,c3);
max_c3 = max(max_c3,c3);
if c3~=0
    min_nz_c3=min(min_nz_c3,abs(c3));
end
d3 = c2;

c4 = c3 - d4;
min_c4 = min(min_c4,c4);
max_c4 = max(max_c4,c4);
if c4~=0
    min_nz_c4=min(min_nz_c4,abs(c4));
end
d4 = c3;

c5 = c4 - d5;
min_c5 = min(min_c5,c5);
max_c5 = max(max_c5,c5);
if c2~=0
    min_nz_c5=min(min_nz_c5,abs(c5));
end
d5 = c4;

y = c5;

comb_idx = comb_idx + 1;

comb1_hist(comb_idx) = c1;
comb2_hist(comb_idx) = c2;
comb3_hist(comb_idx) = c3;
comb4_hist(comb_idx) = c4;
comb5_hist(comb_idx) = c5;

if evalin('base','exist(''PRINT_CIC_COMB_RANGE'',''var'')')

    fprintf('\n');
    disp('================== CIC COMB ==================');

    fprintf('%-15s %15s %15s %18s\n',...
        'Variable','Minimum','Maximum','Min Non-Zero');

    disp('----------------------------------------------------------------');

    fprintf('Comb1 Input %10.0f %15.0f %18.0f\n',min_in,max_in,min_nz_in);

    fprintf('Comb1 Out   %10.0f %15.0f %18.0f\n',min_c1,max_c1,min_nz_c1);
    fprintf('Comb2 Out   %10.0f %15.0f %18.0f\n',min_c2,max_c2,min_nz_c2);
    fprintf('Comb3 Out   %10.0f %15.0f %18.0f\n',min_c3,max_c3,min_nz_c3);
    fprintf('Comb4 Out   %10.0f %15.0f %18.0f\n',min_c4,max_c4,min_nz_c4);
    fprintf('Comb5 Out   %10.0f %15.0f %18.0f\n',min_c5,max_c5,min_nz_c5);

    disp('==============================================================');

    evalin('base','clear PRINT_CIC_COMB_RANGE');

end



if evalin('base','exist(''PRINT_CIC_COMB_PLOT'',''var'')')

    figure;

    plot(comb1_hist); hold on;
    plot(comb2_hist);
    plot(comb3_hist);
    plot(comb4_hist);
    plot(comb5_hist);

    grid on;

    legend('Comb1','Comb2','Comb3','Comb4','Comb5');

    title('Floating Point Comb Outputs');

    evalin('base','clear PRINT_CIC_COMB_PLOT');

end
end