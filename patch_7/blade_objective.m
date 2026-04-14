function J = blade_objective(state)
%==========================================================================
% BLADE_OBJECTIVE: Stiffness
%==========================================================================

    % W1 and W2 are arbitrary weights 
    % Multiply the deflection difference by a large number because
    % deflection values are small (meters) and mass is around 1-2 kg.
    W1 = 1e5;
    W2 = 1.0;

    % Squared error from target deflection (0.10m) + Mass penalty
    J = W1 * (state.total_deflection - 0.10)^2 + W2 * state.mass;


end

%==========================================================================
% BLADE_OBJECTIVE: Weighted sum energy & deflection
%==========================================================================

    % Deflection_Multiplier = 8e4; % Balance between deflection and stiffness
    % 
    % alpha_weight = 0.5;  % 0 <-- y direction min defl
    %                      % 1 <-- x direction min defl
    % 
    % weighted_deflection = (alpha_weight * state.def_x)^2 + ((1 - alpha_weight) * state.def_y)^2;
    % 
    % J = -1 * state.energy + Deflection_Multiplier * weighted_deflection;


%==========================================================================
% BLADE_OBJECTIVE: Stiffness
%==========================================================================

    % % W1 and W2 are arbitrary weights 
    % % Multiply the deflection difference by a large number because
    % % deflection values are small (meters) and mass is around 1-2 kg.
    % W1 = 1e5;
    % W2 = 1.0;
    % 
    % % Squared error from target deflection (0.10m) + Mass penalty
    % J = W1 * (state.total_deflection - 0.10)^2 + W2 * state.mass;

%==========================================================================
% BLADE_OBJECTIVE: Specific energy
%==========================================================================

% Maximize specific energy (Energy / Mass) by minimizing its negative
%    J = -(state.energy / state.mass);

%==========================================================================
% BLADE_OBJECTIVE: Uniform stress
%==========================================================================

    % % Minimize Mass and Variance of Stress.
    % % W_var because variance of stress (Pa^2) will be massive (10^14)
    % W_var = 1e-15;
    % 
    % J = state.mass + W_var * state.stress_variance;


%==========================================================================
% BLADE_OBJECTIVE: epsilo-Constraint
%==========================================================================

    % % Purely maximize energy
    % J = -1 * state.energy;
