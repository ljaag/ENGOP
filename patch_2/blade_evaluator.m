function f = blade_evaluator(x, params_base, mode)
%==========================================================================
% UNIFIED BLADE EVALUATOR
% Maps the variables, runs the physics, and returns the penalty cost.
% 'mode' can be 'simplified' (2 vars) or 'full' (16 vars)
%==========================================================================

    params = params_base;

    % --- 1. Mode Selection & Variable Mapping ---
    if strcmpi(mode, 'simplified')
        % Unpack 2 variables: x = [thickness, R2]
        params.t = x(1) * ones(1,7);       
        params.R4 = x(2);            
        params.theta2 = -90;          
       
        % Turn off other sections
        tiny = 1e-3;
        params.L3 = tiny; params.R2 = 0.02; params.theta3 = 180;
        params.L5 = tiny; params.L7 = 0.05;

        

    elseif strcmpi(mode, 'full')
        % Unpack 16 variables
        params.t(1:7) = x(1:7);
        params.L1 = x(8); params.L3 = x(9); params.L5 = x(10); params.L7 = x(11);
        params.R2 = x(12); params.R4 = x(13); params.R6 = x(14);
        params.theta2 = x(15); params.theta3 = x(16);
       
    else
        error('Invalid mode selected. Choose ''simplified'' or ''full''.');
    end
    
    % Eliminate height constraint
    params.L1 = 0;
    [~, by_temp] = blade_structure(params);
    partial_height = max(by_temp) - min(by_temp);
    req_L1 = params.H_req - partial_height;
    params.L1 = req_L1;
    

    % --- 2. Run the Core Physics ---
    % These files remain untouched and oblivious to the optimization
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
    actual_height = max(results.y_orig);
   
    % Normalized constraint penalties
    c_stress = max(0, (max_actual_stress / 500e6) - 1);
    c_height = max(0, 0.01 - req_L1);
   
    % Final composite cost
    Weight = 10000;
    f = J + Weight * (c_stress^2 + c_height^2);
end