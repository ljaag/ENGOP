function params = update_blade_params(x, params_base, mode)
%==========================================================================
% UPDATE_BLADE_PARAMS
% Maps optimization variables to the parameters structure and enforces
% geometric constraints (like the height requirement) uniformly.
%==========================================================================
    params = params_base;

    % --- 1. Mode Selection & Variable Mapping ---
    if strcmpi(mode, 'simplified')
        % Unpack 2 variables: x = [thickness, R4]
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
        params.L3 = x(8); params.L5 = x(9); params.L7 = x(10);
        params.R2 = x(11); params.R4 = x(12); params.R6 = x(13);
        params.theta2 = x(14); 
        % Ensure theta5 is positive
        max_theta3 = 89.9 - params.theta2;
        params.theta3 = min(x(15), max_theta3);
       
    else
        error('Invalid mode selected. Choose ''simplified'' or ''full''.');
    end
   
    % --- 2. Enforce Height Constraint (Adjust L1) ---
    params.L1 = 0;
    [~, by_temp] = blade_structure(params);
    partial_height = max(by_temp) - min(by_temp);
   
    % The required L1 is the difference between target height and current partial height
    params.L1 = params.H_req - partial_height;
end