function cost = PID_CostFunction_Settling(x)

result = PID_RunSimulation(x(1),x(2),x(3));

if ~result.Stable
    cost = 1e12;
    return;
end

cost = 0;

%% Steady-State Error
cost = cost + 1e7*result.SSE^2;

%% Overshoot

if result.Overshoot > 10
    cost = cost + 5000*(result.Overshoot-10)^2;
end

%% Settling Time

if isnan(result.SettlingTime)

    cost = cost + 1e10;

elseif result.SettlingTime > 20e-6

    cost = cost + ...
        1e8*((result.SettlingTime-20e-6)/20e-6)^2;

end

%% Saturation

cost = cost + 50*result.SatSamples;

end