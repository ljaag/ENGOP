function result = solve_blade_deformation(structure, params)
%==========================================================================
% Accounts for the individual deflection of all nodes in the 7-section blade.
% Respects the specific geometry of each section using path-integration.
%==========================================================================

    % Force Vector
    Fx = params.F_mag * cosd(params.F_angle);
    
    Fy = params.F_mag * sind(params.F_angle);
    
    
    % Sole fixed condition
    L_total = structure.s(end);
    L7 = params.L7;
    s_fixed_start = (L_total - L7) + (1.0 * L7); % compute when to fix
    idx_fixed = find(structure.s >= s_fixed_start, 1, 'first');
    
    N = length(structure.x);
    dx = zeros(1, N);
    dy = zeros(1, N);
    
    % Calculate Global Moment at all points (Relative to Load Point Node 1)
    % M = Fx * DeltaY - Fy * DeltaX
    Mx = Fx * (structure.y - structure.y(1));
    My = Fy * (structure.x - structure.x(1));
    M = Mx - My;
    
    % Rigidity
    EI = structure.E .* structure.I;
    
    % From Fixed Support to each Node
    % To make this efficient (Vectorized), we pre-calculate common terms
    ds = [0, diff(structure.s)]; % incremental arc lengths
    curvature_term = (M ./ EI) .* ds;
    
    % We integrate BACKWARDS from the fixed support to the stump
    % because the toe is our (0,0,0) reference for displacement.
    for i = idx_fixed-1 : -1 : 1
        % We only integrate from idx_fixed to the current node i
        range = i:idx_fixed;
        
        % Moment arm for the Unit Load at node i
        % m_xi = (y_s - y_i), m_yi = -(x_s - x_i)
        mx = (structure.y(range) - structure.y(i));
        my = -(structure.x(range) - structure.x(i));
        
        % Castigliano's Integration (Trapz-like summation)
        dx(i) = sum((M(range) ./ EI(range)) .* mx .* ds(range));
        dy(i) = sum((M(range) ./ EI(range)) .* my .* ds(range));
    end
    
    % 5. Store Results
    result.x_orig = structure.x;
    result.y_orig = structure.y;
    result.x_def  = structure.x + dx;
    result.y_def  = structure.y + dy;
    
    % Total Energy Storage (Integral of M^2 / 2EI over the whole length)
    result.energy = sum( (M(1:idx_fixed).^2 ./ (2 .* EI(1:idx_fixed))) .* ds(1:idx_fixed) );
    
    result.M = M;



end