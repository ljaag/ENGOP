function f = blade_evaluator(x, params_base, mode)
%==========================================================================
% UNIFIED BLADE EVALUATOR
% Maps the variables, runs the physics, and returns the penalty cost.
%==========================================================================

    % --- 1. Update Parameters & Geometry uniformly ---
    params = update_blade_params(x, params_base, mode);

    % --- 2. Run the Core Physics ---
    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
    stress_data = compute_stresses(struct_mesh, params, results);

    % Compute mass
    rho = 1600;
    Area = struct_mesh.w .* struct_mesh.t;
    ds = diff(struct_mesh.s);
    mass = rho * sum(Area(1:end-1) .* ds);

    % --- 3. Calculate Objective & Penalties ---
    energy = results.energy;
    total_deflection = sqrt((results.x_def(1) - results.x_orig(1))^2 + (results.y_def(1) - results.y_orig(1))^2);
   
    J = -1 * energy + 1000 * total_deflection;
   
    max_actual_stress = max(stress_data.sigma_max);
   
    % Normalized constraint penalties
    c_stress = max(0, (max_actual_stress / 500e6) - 1);
    c_height = max(0, 0.01 - params.L1); % Penalize if L1 connection is physically too short
   
    % Final composite cost
    Weight = 10000;
    f = J + Weight * (c_stress^2 + c_height^2);
end