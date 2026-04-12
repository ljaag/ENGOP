function result = solve_blade_deformation_progressive(structure, params)
%==========================================================================
% Accounts for the individual deflection of all nodes in the 7-section blade.
% Respects the specific geometry of each section using path-integration.
% The analysis is progressive to account for large deformations
%==========================================================================
    % Number of load steps for progressive application
    N_steps = 1;
   
    % Incremental Force Vector
    dF_mag = params.F_mag / N_steps;
    dFx = dF_mag * cosd(params.F_angle);
    dFy = dF_mag * sind(params.F_angle);
   
    % Setup fixed boundaries
    L_total = structure.s(end);
    s_fixed_start = (L_total - params.L7) + (1.0 * params.L7);
    idx_fixed = find(structure.s >= s_fixed_start, 1, 'first');
   
    N = length(structure.x);
   
    % Initialize running variables
    current_x = structure.x;
    current_y = structure.y;
    total_energy = 0;
    EI = structure.E .* structure.I;
    ds = [0, diff(structure.s)];
   
    for step = 1:N_steps
        dx_step = zeros(1, N);
        dy_step = zeros(1, N);
       
        % Calculate Global Moment based on CURRENT deformed shape
        Mx = dFx * (current_y - current_y(1));
        My = dFy * (current_x - current_x(1));
        M_step = Mx - My;
       
        % Backwards integration from fixed support
        for i = idx_fixed-1 : -1 : 1
            range = i:idx_fixed;
            % Moment arms updated with new geometry
            mx = (current_y(range) - current_y(i));
            my = -(current_x(range) - current_x(i));
           
            dx_step(i) = sum((M_step(range) ./ EI(range)) .* mx .* ds(range));
            dy_step(i) = sum((M_step(range) ./ EI(range)) .* my .* ds(range));
        end
       
        % Update geometry for the next step
        current_x = current_x + dx_step;
        current_y = current_y + dy_step;
       
        % Accumulate Strain Energy (dU = M^2 / 2EI ds)
        total_energy = total_energy + sum((M_step(1:idx_fixed).^2 ./ (2 .* EI(1:idx_fixed))) .* ds(1:idx_fixed));
    end
   
    % Final Results
    result.x_orig = structure.x;
    result.y_orig = structure.y;
    result.x_def  = current_x;
    result.y_def  = current_y;
    result.energy = total_energy;
   
    % Final Total Moment for stress calculations
    Mx_total = (params.F_mag * cosd(params.F_angle)) * (current_y - current_y(1));
    My_total = (params.F_mag * sind(params.F_angle)) * (current_x - current_x(1));
    result.M = Mx_total - My_total;
end