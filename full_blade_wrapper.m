function [J, c, ceq] = full_blade_wrapper(x, params_base)
    % 1. Unpack all 16 design variables
    params = params_base;
    params.t(1:7) = x(1:7);
    params.L1 = x(8); params.L3 = x(9); params.L5 = x(10); params.L7 = x(11);
    params.R2 = x(12); params.R4 = x(13); params.R6 = x(14);
    params.theta2 = x(15); params.theta3 = x(16);
   
    % 2. Run Models
    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
    stress_data = compute_stresses(struct_mesh, params, results);
   
    % 3. Objective
    w1 = 1; w2 = 1000;
    energy = results.energy;
    total_deflection = sqrt((results.x_def(1) - results.x_orig(1))^2 + (results.y_def(1) - results.y_orig(1))^2);
    J = -w1 * energy + w2 * total_deflection;
   
    % % 4. Constraints
    % max_stress = 600e6;
    % max_deflection = 0.15;
    % 
    % c(1) = max(stress_data.sigma_max) - max_stress;
    % c(2) = total_deflection - max_deflection;
    % ceq(1) = max(results.y_orig) - 0.80;

    % 4. Normalized costraints
    max_allowable_stress = 600e6;
    max_allowable_deflection = 0.15;
    target_height = 0.80;
    height_tolerance = 0.005;

    max_actual_stress = max(stress_data.sigma_max);
    actual_height = max(results.y_orig);

    % Ineq
    % Normalized stress
    c(1) = (max_actual_stress / max_allowable_stress) - 1;
    c(2) = (total_deflection / max_allowable_deflection) - 1;
    c(3) = (abs(actual_height - target_height) / height_tolerance) - 1;

    % Eq
    ceq = [];
end
