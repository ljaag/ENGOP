function compare_results(x_design1, x_design2, params_base, mode1, mode2, name1, name2)
%==========================================================================
% Evaluates two different designs through the physics engine and prints
% a side-by-side comparison of their true physical performance.
%==========================================================================

    % Run both designs through the physics engine to get their true 'state'
    state1 = run_blade_physics(x_design1, params_base, mode1);
    state2 = run_blade_physics(x_design2, params_base, mode2);
   
    % Calculate Specific Energy (Energy / Mass)
    spec_energy1 = state1.energy / state1.mass;
    spec_energy2 = state2.energy / state2.mass;

    % 3. Print the Comparison Table
    fprintf('\n======================================================\n');
    fprintf('                 DESIGN COMPARISON                    \n');
    fprintf('======================================================\n');
    fprintf('%-20s | %-12s | %-12s\n', 'Metric', name1, name2);
    fprintf('------------------------------------------------------\n');
   
    fprintf('%-20s | %-12.3f | %-12.3f\n', 'Mass (kg)', state1.mass, state2.mass);
    fprintf('%-20s | %-12.1f | %-12.1f\n', 'Strain Energy (J)', state1.energy, state2.energy);
    fprintf('%-20s | %-12.1f | %-12.1f\n', 'Specific Energy (J/kg)', spec_energy1, spec_energy2);
    fprintf('%-20s | %-12.1f | %-12.1f\n', 'Max Stress (MPa)', state1.max_actual_stress/1e6, state2.max_actual_stress/1e6);
    fprintf('%-20s | %-12.3f | %-12.3f\n', 'Deflection (m)', state1.total_deflection, state2.total_deflection);
    fprintf('======================================================\n\n');
   
    % Declare the winner based on structural efficiency
    if spec_energy1 > spec_energy2
        fprintf('Winner by Specific Energy: %s\n', name1);
    else
        fprintf('Winner by Specific Energy: %s\n', name2);
    end
end