function stress_results = compute_stresses(structure, params, results)
    % --- Extract geometry and forces ---
    N = length(structure.x);
    t = structure.t;
    w = structure.w; 
    M = results.M;   % Internal moment
    
    % Applied Force components
    Fx = params.F_mag * cosd(params.F_angle);
    Fy = params.F_mag * sind(params.F_angle);
    
    % --- Pre-allocate arrays ---
    sigma_bending = zeros(1, N);
    sigma_axial = zeros(1, N);
    
    % --- Loop through nodes to calculate stress ---
    for i = 1:N
        % 1. Local Properties
        A = w(i) * t(i);           % Cross-sectional area
        I = (w(i) * t(i)^3) / 12;  % Moment of Inertia 
        c = t(i) / 2;              % Distance to outer fiber
        
        % 2. Calculate local tangent angle for Axial Force
        if i < N
            dx = structure.x(i+1) - structure.x(i);
            dy = structure.y(i+1) - structure.y(i);
        else
            dx = structure.x(i) - structure.x(i-1);
            dy = structure.y(i) - structure.y(i-1);
        end
        theta_local = atan2(dy, dx);
        
        % 3. Project Global Force to Local Tangent (Axial Force)
        % F_tangent = Fx*cos(theta) + Fy*sin(theta)
        F_tangent = Fx * cos(theta_local) + Fy * sin(theta_local);
        
        % 4. Individual Stress Components
        sigma_bending(i) = abs(M(i) * c / I);
        sigma_axial(i) = F_tangent / A;
    end
    
    % Total maximum stress at each node (Absolute value for worst-case)
    stress_results.sigma_max = sigma_bending + abs(sigma_axial);
    stress_results.bending = sigma_bending;
    stress_results.axial = sigma_axial;
end