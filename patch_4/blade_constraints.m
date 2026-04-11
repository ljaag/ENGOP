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
end
