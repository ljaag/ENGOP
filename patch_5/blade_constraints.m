function c = blade_constraints(state)
%==========================================================================
% BLADE_CONSTRAINTS
% Calculates the inequality constraints g(x) <= 0.
% Values > 0 indicate a violation.
%==========================================================================
    % c(1): Maximum stress constraint (normalized)
    c(1) = (state.max_actual_stress / 500e6) - 1;
   
    % c(2): L1 height physical constraint (L1 must be >= 0.01)
    c(2) = 0.01 - state.L1;

    % c(3): displacement limits
    alpha_weight = 0.4;  % 0 <-- consider y deflection
                         % 1 <-- consider x deflection
    deflection = ((alpha_weight * state.def_x)^2 + ((1 - alpha_weight) * state.def_y)^2);
    % Still need to define the limits
    c(3) = deflection/0.001 - 1; % Less than 
    c(4) = 1 - deflection/0.1; % Greater than
end
