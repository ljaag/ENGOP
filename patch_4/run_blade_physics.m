function state = run_blade_physics(x, params_base, mode)
%==========================================================================
% RUN_BLADE_PHYSICS
% Maps the variables and runs the physics chain ONCE per evaluation.
% Returns a lightweight 'state' struct used by objective and constraints.
%==========================================================================

    % --- 1. Update Parameters & Geometry ---
    params = update_blade_params(x, params_base, mode);

    % --- 2. Run the Core Physics ---
    [bx, by] = blade_structure(params);
    struct_mesh = material_properties([bx; by], params);
    results = solve_blade_deformation_progressive(struct_mesh, params);
    stress_data = compute_stresses(struct_mesh, params, results);

    % --- 3. Bundle the State ---
    state.energy = results.energy;
   
    % Calculate Deflection
    state.def_x = results.x_def(1) - results.x_orig(1);
    state.def_y = results.y_def(1) - results.y_orig(1);
    state.total_deflection = sqrt(state.def_x^2 + state.def_y^2);
    
   
    % Store Max Stress and Height Constraint
    state.max_actual_stress = max(stress_data.sigma_max);
    state.L1 = params.L1;
end