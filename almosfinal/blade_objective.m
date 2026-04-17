function J = blade_objective(state)
%==========================================================================
% BLADE_OBJECTIVE
% Contains various normalized objective functions for the ALM solver.
% Uncomment the specific objective you wish to use.
%
% NORMALIZATION FACTORS:
%   Energy: ~100 Joules
%   Mass: ~1.5 kg
%   Deflection: ~0.1 meters
%   Stress Variance: ~1e14 Pa^2
%==========================================================================

    % ---------------------------------------------------------------------
    % 1. EPSILON-CONSTRAINT (Pure Energy - Active by default)
    % ---------------------------------------------------------------------
    % Purely maximize energy. Mass limits are handled in the constraints.
    % Divide by 100 J so the objective is around -1.0 to -2.0.
    
    % J = -(state.energy / 100);

    
    % ---------------------------------------------------------------------
    % 2. SPECIFIC ENERGY (Energy to Mass Ratio)
    % ---------------------------------------------------------------------
    % Maximize energy return per kilogram of material.
    % A typical good value is ~100 J/kg, so divide by 100.
    
    % spec_energy = state.energy / state.mass;
    % J = -(spec_energy / 100);

    
    % ---------------------------------------------------------------------
    % 3. UNIFORM STRESS & MINIMUM MASS
    % ---------------------------------------------------------------------
    % Minimize Mass and Variance of Stress so material is used efficiently.
    % Mass is already O(1), but divide by 1.5 to center it at 1.0.
    % Stress variance is massive (Pa^2), so divide by 1e14 to normalize.
    
    % norm_mass = state.mass / 1.5;
    % norm_variance = state.stress_variance / 1e14;
    % 
    % J = norm_mass + norm_variance;

    
    % ---------------------------------------------------------------------
    % 4. STIFFNESS (Target Deflection + Mass)
    % ---------------------------------------------------------------------
    % Force the blade to hit exactly 0.10m of deflection while minimizing mass.
    % Normalize the deflection error by dividing by the 0.10 target.
    
    % target_deflection = 0.10;
    % error_deflection = (state.total_deflection - target_deflection) / target_deflection;
    % norm_mass = state.mass / 1.5;
    % 
    % % You can adjust W1 and W2, but since both terms are normalized to ~1.0, 
    % % a 1-to-1 ratio (W1=1, W2=1) provides a highly balanced optimization.
    % W1 = 1.0; 
    % W2 = 1.0; 
    % 
    % J = W1 * (error_deflection)^2 + W2 * norm_mass;


    % ---------------------------------------------------------------------
    % 5. WEIGHTED SUM: ENERGY & DEFLECTION (Directional)
    % ---------------------------------------------------------------------
    % Maximize energy while minimizing deflection in a specific direction.
    % Alpha determines direction: 0 = y-direction, 1 = x-direction.
    
    alpha_weight = 0.5;  

    % Normalize deflections by an assumed maximum of 0.1 meters
    norm_def_x = state.def_x / 0.1;
    norm_def_y = state.def_y / 0.1;

    weighted_deflection = (alpha_weight * norm_def_x)^2 + ((1 - alpha_weight) * norm_def_y)^2;
    norm_energy = state.energy / 100;

    % Because both are now normalized to ~1.0, you don't need a massive 
    % 8e4 multiplier anymore. A small weight will perfectly balance them.
    Deflection_Weight = 2.0; 

    J = -norm_energy + Deflection_Weight * weighted_deflection;

end