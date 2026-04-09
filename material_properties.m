function structure = material_properties(coords, params)
%==========================================================================
% Assigns the material properties to each point in the blade.
%
%   INPUTS:
%       coords : [bx; by] matrix (2 x N) from blade_structure
%       params : Struct containing:
%                .t (1x7 vector of thicknesses)
%                .L (1x7 vector of segment lengths)
%                .E (Young's Modulus)
%                .w (Constant width)
%==========================================================================

    bx = coords(1,:);
    by = coords(2,:);
    N  = length(bx);
    
    % Arc Lengths and Boundaries
    theta5_deg = 90 - (params.theta2 + params.theta3);
    L_vector = [params.L1, abs(params.R2*deg2rad(params.theta2)), params.L3, ...
                abs(params.R4*deg2rad(params.theta3)), params.L5, ...
                abs(params.R6*deg2rad(theta5_deg)), params.L7];
    
    s_points = [0, cumsum(sqrt(diff(bx).^2 + diff(by).^2))];
    boundaries = [0, cumsum(L_vector)];
    
    % Control Points for the "Trapezoidal" Transition
    % two points per segment to define the 'Constant Core'
    s_control = [];
    t_control = [];
    w_control = [];
    E_control = [];

    for i = 1:7
        L_seg = L_vector(i);
        
        % 1. Prevent exactly zero lengths from creating duplicate points
        if L_seg < 1e-9
            continue;
        end
        
        % 2. Fix ordering (0.2 instead of 0.8) so points go forward (20% then 80%)
        trans = 0.2 * L_seg; 
        
        % Points at 20% and 80% of THIS segment
        s_control = [s_control, boundaries(i) + trans, boundaries(i+1) - trans];
        
        % The value is the same at both ends of the segment core
        t_control =[t_control, params.t(i), params.t(i)];
        w_control =[w_control, params.w(i), params.w(i)];
        E_control =[E_control, params.E(i), params.E(i)];
    end

    % Interpolation for thickness taper
    % 'linear' creates the ramp, 'extrap' handles the very start/end
    structure.t = interp1(s_control, t_control, s_points, 'linear', 'extrap');
    structure.w = interp1(s_control, w_control, s_points, 'linear', 'extrap');
    structure.E = interp1(s_control, E_control, s_points, 'linear', 'extrap');

    % 4. Final Calculations
    structure.x = bx;
    structure.y = by;
    structure.s = s_points;
    structure.I = (structure.w .* (structure.t.^3)) ./ 12; % Rectangle

end