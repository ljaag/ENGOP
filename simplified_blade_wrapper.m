function [J, c, ceq] = simplified_blade_wrapper(x, params_base)
    % 1. Unpack 2 variables
    t_val = x(1);
    R_val = x(2);
   
    % 2. Map to the 7-segment parameter structure
    params = params_base;
    params.t = t_val * ones(1,7); % Uniform thickness
    params.L1 = 0.4;              % Fixed Stump Length
    params.R2 = R_val;            % Variable Radius for the "C"
    params.theta2 = 180;          % 180 degrees creates the "C" shape
   
    % "Turn off" the other sections by making them negligibly small
    tiny = 1e-5;
    params.L3 = tiny; params.R4 = tiny; params.theta3 = tiny;
    params.L5 = tiny; params.R6 = tiny; params.L7 = tiny;
   
    % 3. Run Models
    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
    stress_data = compute_stresses(struct_mesh, params, results);
   
    % 4. Objective (Minimize Deflection, Maximize Energy)
    w1 = 1; w2 = 1000;
    energy = results.energy;
    total_deflection = sqrt((results.x_def(1) - results.x_orig(1))^2 + (results.y_def(1) - results.y_orig(1))^2);
    J = -w1 * energy + w2 * total_deflection;
   
    % % 5. Constraints
    % max_stress = 600e6;
    % c(1) = max(stress_data.sigma_max) - max_stress; % Max stress constraint
    % 
    % % Equality constraint: Height must equal 0.8m
    % % A penalty method will be applied to this constraint
    % ceq(1) = max(results.y_orig) - 0.80;

    % 5. Normalized costraints
    max_allowable_stress = 600e6;
    max_actual_stress = max(stress_data.sigma_max);
    actual_height = max(results.y_orig);
    target_height = 0.80;
    height_tolerance = 0.005;

    % Ineq
    % Normalized stress
    c(1) = (max_actual_stress / max_allowable_stress) - 1;
    c(2) = (abs(actual_height - target_height) / height_tolerance)-1;

    % Eq
    ceq = [];

end
