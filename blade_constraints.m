function [c, ceq] = blade_constraints(x_opt, params_base)
    % 1. Unpack variables & run model (Same as objective function)
    params = params_base;
    params.t(1:7) = x_opt(1:7);
    params.L1 = x_opt(8); params.L3 = x_opt(9); params.L5 = x_opt(10); params.L7 = x_opt(11);
    params.R2 = x_opt(12); params.R4 = x_opt(13); params.R6 = x_opt(14);
    params.theta2 = x_opt(15); params.theta3 = x_opt(16);


    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
    stress_data = compute_stresses(struct_mesh, params, results);
   
    % --- Limits ---
    max_allowable_stress = 600e6; % 600 MPa (Example for Carbon Fiber)
    max_allowable_deflection = 0.15; % 15 cm
    target_height = 0.80; % 80 cm
   
    % --- Inequality Constraints (c <= 0) ---
    max_actual_stress = max(stress_data.sigma_max);
    actual_deflection = sqrt((results.x_def(1) - results.x_orig(1))^2 + (results.y_def(1) - results.y_orig(1))^2);
   
    c(1) = max_actual_stress - max_allowable_stress;   % Stress constraint
    c(2) = actual_deflection - max_allowable_deflection; % Deflection constraint
   
    % --- Equality Constraints (ceq == 0) ---
    actual_height = max(results.y_orig);
    ceq(1) = actual_height - target_height; % Height constraint
end