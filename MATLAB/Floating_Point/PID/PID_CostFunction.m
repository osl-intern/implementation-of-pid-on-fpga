function cost = PID_CostFunction(result)

if ~result.Stable
    cost = 1e12;
    return;
end

cost = 0;

% Steady-state error (highest priority)
cost = cost + 1e7*result.SSE^2;

% Overshoot
if result.Overshoot > 10
    cost = cost + 5000*(result.Overshoot-10)^2;
end

% Saturation penalty
cost = cost + 50*result.SatSamples;

end