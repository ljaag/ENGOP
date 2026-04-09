function J = blade_objective(x_opt, params_base)
    % 1. Unpack the design variables (x_opt) into the params struct
    % Assuming x_opt layout: [t1..t7, L1..L7, R2, R4, R6, theta2, theta3] -> 19 variables total
    params = params_base;
    params.t(1:7) = x_opt(1:7);
    params.L1 = x_opt(8); params.L3 = x_opt(9); params.L5 = x_opt(10); params.L7 = x_opt(11);
    params.R2 = x_opt(12); params.R4 = x_opt(13); params.R6 = x_opt(14);
    params.theta2 = x_opt(15); params.theta3 = x_opt(16);
   
    % 2. Run the model
    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
   
    % 3. Extract metrics
    energy = results.energy;
    deflection_x = abs(results.x_def(1) - results.x_orig(1));
    deflection_y = abs(results.y_def(1) - results.y_orig(1));
    total_deflection = sqrt(deflection_x^2 + deflection_y^2);
   
    % 4. Composite Objective Function
    % Weights (w1, w2) normalize the values so one doesn't dominate the other
    w1 = 1;      % Weight for maximizing energy (negative sign minimizes it)
    w2 = 1000;   % Weight for minimizing deflection (needs to be high as deflection is small)
   
    J = -w1 * energy + w2 * total_deflection;
end
