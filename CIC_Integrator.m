function y = CIC_Integrator(x)
global CURRENT_CYCLE
% ============================================================
% CIC_Integrator.m
%
% 5-Stage CIC Integrator
%
% Input :
%   x  -> Signed ADC sample
%
% Output:
%   y  -> Integrator output
%
% Runs at 20.48 MSPS
% ============================================================

persistent int1 int2 int3 int4 int5
persistent int1_hist int2_hist int3_hist int4_hist int5_hist
persistent int_idx

%-------------------------------------------------------
% Range Tracking
%-------------------------------------------------------

persistent min_i1 max_i1 min_nz_i1
persistent min_i2 max_i2 min_nz_i2
persistent min_i3 max_i3 min_nz_i3
persistent min_i4 max_i4 min_nz_i4
persistent min_i5 max_i5 min_nz_i5

if isempty(int1)
    min_i1 = inf; max_i1 = -inf; min_nz_i1 = inf;
    min_i2 = inf; max_i2 = -inf; min_nz_i2 = inf;
    min_i3 = inf; max_i3 = -inf; min_nz_i3 = inf;
    min_i4 = inf; max_i4 = -inf; min_nz_i4 = inf;
    min_i5 = inf; max_i5 = -inf; min_nz_i5 = inf;

    int1 = 0;
    int2 = 0;
    int3 = 0;
    int4 = 0;
    int5 = 0;

    int1_hist = [];
    int2_hist = [];
    int3_hist = [];
    int4_hist = [];
    int5_hist = [];

    int_idx = 0;

end

%-------------------------------------------------------
% Track Integrator Inputs
%-------------------------------------------------------

in1 = double(x);
in2 = int1;
in3 = int2;
in4 = int3;
in5 = int4;

% Stage 1

min_i1 = min(min_i1,in1);
max_i1 = max(max_i1,in1);
if in1~=0
    min_nz_i1 = min(min_nz_i1,abs(in1));
end

% Stage 2

min_i2 = min(min_i2,in2);
max_i2 = max(max_i2,in2);
if in2~=0
    min_nz_i2 = min(min_nz_i2,abs(in2));
end

% Stage 3

min_i3 = min(min_i3,in3);
max_i3 = max(max_i3,in3);
if in3~=0
    min_nz_i3 = min(min_nz_i3,abs(in3));
end

% Stage 4

min_i4 = min(min_i4,in4);
max_i4 = max(max_i4,in4);
if in4~=0
    min_nz_i4 = min(min_nz_i4,abs(in4));
end

% Stage 5

min_i5 = min(min_i5,in5);
max_i5 = max(max_i5,in5);
if in5~=0
    min_nz_i5 = min(min_nz_i5,abs(in5));
end

int1 = int1 + double(x);

int2 = int2 + int1;

int3 = int3 + int2;

int4 = int4 + int3;

int5 = int5 + int4;

int_idx = int_idx + 1;

int1_hist(int_idx) = int1;
int2_hist(int_idx) = int2;
int3_hist(int_idx) = int3;
int4_hist(int_idx) = int4;
int5_hist(int_idx) = int5;

% Output
y = int5;
%-------------------------------------------------------
% Print Once
%-------------------------------------------------------

if evalin('base','exist(''PRINT_CIC_INT_RANGE'',''var'')')

    fprintf('\n');
    disp('================ CIC INTEGRATOR =================');

    fprintf('%-15s %15s %15s %18s\n',...
        'Stage','Minimum','Maximum','Min Non-Zero');

    disp('----------------------------------------------------------------');

    fprintf('Input 1 %12.0f %15.0f %18.0f\n',min_i1,max_i1,min_nz_i1);
    fprintf('Input 2 %12.0f %15.0f %18.0f\n',min_i2,max_i2,min_nz_i2);
    fprintf('Input 3 %12.0f %15.0f %18.0f\n',min_i3,max_i3,min_nz_i3);
    fprintf('Input 4 %12.0f %15.0f %18.0f\n',min_i4,max_i4,min_nz_i4);
    fprintf('Input 5 %12.0f %15.0f %18.0f\n',min_i5,max_i5,min_nz_i5);

    disp('================================================================');

    evalin('base','clear PRINT_CIC_INT_RANGE');

end

if evalin('base','exist(''PRINT_CIC_INT_PLOT'',''var'')')

    figure;

    plot(int1_hist); hold on;
    plot(int2_hist);
    plot(int3_hist);
    plot(int4_hist);
    plot(int5_hist);

    grid on;

    legend('Int1','Int2','Int3','Int4','Int5');

    title('Floating Point Integrators');

    evalin('base','clear PRINT_CIC_INT_PLOT');

end
end