function c = blade_constraints(state)
%==========================================================================
% BLADE_CONSTRAINTS: Stiffness
%==========================================================================

% Standard safety limits
    c(1) = (state.max_actual_stress / 500e6) - 1; % Stress <= 500 MPa

    



    %-------------------
    % Basic COnstraints   -> Always
    %-------------------
    % Positive theta 5
    c(2) = -state.theta5 / 90;

    % Minimum L1 length
    minL1 = 0.025;
    c(3) =(minL1-state.L1) / minL1;
    
    % "x" limits
    ext_x_max = 0.4;
    ext_x_min = -0.4;
    c(4) = (state.max_x - ext_x_max) / ext_x_max;
    c(5) = (ext_x_min - state.min_x) / abs(ext_x_min);

    % "y" limits
    c(6) = (state.max_y - state.H_req)/ state.H_req; % top
    min_req_clearance = 0.02;
    c(7) = (min_req_clearance - state.min_clearance) / min_req_clearance;

    % Sole limits (element must sit within x = 0)
    c(8) = state.sole_min_x / 0.1;
    c(9) = -state.sole_max_x / 0.1;

end

%==========================================================================
% BLADE_CONSTRAINTS
% Calculates the inequality constraints g(x) <= 0.
% Values > 0 indicate a violation.
%==========================================================================
    % % c(1): Maximum stress constraint (normalized)
    % c(1) = (state.max_actual_stress / 500e6) - 1;
    % 
    % % c(2): L1 height physical constraint (L1 must be >= 0.01)
    % c(2) = 0.01 - state.L1;
    % % c(3): displacement limits
    % % alpha_weight = 0.4;  % 0 <-- consider y deflection
    % %                      % 1 <-- consider x deflection
    % % deflection = ((alpha_weight * state.def_x)^2 + ((1 - alpha_weight) * state.def_y)^2);
    % % % Still need to define the limits
    % % c(3) = deflection/0.001 - 1; % Less than 
    % % c(4) = 1 - deflection/0.1; % Greater than


%==========================================================================
% BLADE_CONSTRAINTS: Stiffness
%==========================================================================

% % Standard safety limits
%     c(1) = (state.max_actual_stress / 500e6) - 1; % Stress <= 500 MPa
%     c(2) = 0.01 - state.L1;                       % L1 >= 0.01


%==========================================================================
% BLADE_CONSTRAINTS: Specific energy
%==========================================================================

    % c(1) = (state.max_actual_stress / 600e6) - 1;  % Stress <= 600 MPa
    % c(2) = (state.total_deflection / 0.12) - 1;    % Deflection <= 0.12 m
    % c(3) = 0.01 - state.L1;                        % L1 >= 0.01

%==========================================================================
% BLADE_CONSTRAINTS: Uniform stress
%==========================================================================
    
    % % Upper bound so the optimizer doesn't uniformly distribute
    % % stress at a failure point (1000 MPa everywhere)
    % c(1) = (state.max_actual_stress / 500e6) - 1;
    % c(2) = 0.01 - state.L1;
    
%==========================================================================
% BLADE_CONSTRAINTS: epsilo-Constraint
%==========================================================================

    % global EPSILON_MASS; % Pulled from the main script loop
    % 
    % % Decoupled mass limit: Mass <= EPSILON_MASS
    % c(1) = state.mass - EPSILON_MASS;
    % 
    % % Standard safety limits
    % c(2) = (state.max_actual_stress / 600e6) - 1;
    % c(3) = 0.01 - state.L1;

%==========================================================================

% % Displacement limits (meters) 
% D_min = 0.08; % Must deflect AT LEAST 8 cm 
% D_max = 0.12; % Example: Must deflect NO MORE THAN 12 cm 
% % c(1): Upper limit constraint (Violated if deflection > D_max) 
% c(1) = (state.total_deflection / D_max) - 1; % 
% % c(2): Lower limit constraint (Violated if deflection < D_min) 
% c(2) = 1 - (state.total_deflection / D_min);  


% min_required_clearance = 0.02;
% c(4) = min_required_clearance - state.min_clearance;