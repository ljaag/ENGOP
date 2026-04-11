function J = blade_objective(state)
%==========================================================================
% BLADE_OBJECTIVE
% Calculates the primary objective cost based on the physics state.
%==========================================================================
    % Minimize energy and penalize deflection
    %J = -1 * state.energy + 1000 * state.total_deflection;
    
    Deflection_Multiplier = 9e4; % Balance between deflection and stiffness

    alpha_weight = 0.5;  % 0 <-- y direction min defl
                         % 1 <-- x direction min defl

    weighted_deflection = (alpha_weight * state.def_x^2) + ((1 - alpha_weight) * state.def_y^2);

    J = -1 * state.energy + Deflection_Multiplier * weighted_deflection;

end



% --- Previous objective function attempts ---
% Weighted sum
%J = -1 * state.energy + 1000 * state.total_deflection;

% Separated x & y deflection weighted sum
% Deflection_Multiplier = 9e4; % Balance between deflection and stiffness
% 
% alpha_weight = 0.5;  % 0 <-- y direction min defl
%                      1 <-- x direction min defl
% 
% weighted_deflection = (alpha_weight * state.def_x^2) + ((1 - alpha_weight) * state.def_y^2);
% 
% J = -1 * state.energy + Deflection_Multiplier * weighted_deflection;
