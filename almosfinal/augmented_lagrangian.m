function [x_opt, history] = augmented_lagrangian(physics_fun, obj_fun, con_fun, x0, lb, ub)
%==========================================================================
% AUGMENTED_LAGRANGIAN
% Outer loop for the ALM method. Manages Lagrange multipliers and penalty
% weights, while delegating the unconstrained minimization to al_inner_bfgs.
%==========================================================================
    % --- 1. ALM Parameters ---
    max_outer_iter = 20;
    tol_c = 1e-4; % Acceptable constraint violation tolerance

    % Force column vectors
    x0 = x0(:); lb = lb(:); ub = ub(:);

    % Initial evaluation to determine the number of constraints
    state0 = physics_fun(x0');
    c0 = con_fun(state0);
    c0 = c0(:);

    % Initialize Multipliers and Penalty
    lambda = zeros(size(c0));
    mu = 10.0;  % Starting penalty weight
    x_opt = x0;
    prev_violation = inf;

    % Preallocate history
    history.x = [];
    history.f = [];
    history.max_c = [];

    fprintf('\n======================================================\n');
    fprintf('--- Starting Augmented Lagrangian Optimization ---\n');

    % --- 2. Outer ALM Loop ---
    for k = 1:max_outer_iter
        fprintf('\n--- ALM Outer Iteration %d (mu = %g) ---\n', k, mu);

        % Define the Augmented Lagrangian function for this specific iteration
        % We pass this to the inner BFGS solver
        AL_fun = @(x) eval_AL(x, physics_fun, obj_fun, con_fun, lambda, mu);

        % Run the Inner BFGS solver
        [x_opt, inner_hist] = al_inner_bfgs(AL_fun, x_opt, lb, ub);

        % Record history
        history.x = [history.x; inner_hist.x];
        history.f = [history.f; inner_hist.f];

        % Evaluate constraints at the newly found local optimum
        state = physics_fun(x_opt');
        c = con_fun(state);
        c = c(:);
       
        max_violation = max(max(c), 0);
        history.max_c = [history.max_c; max_violation];

        fprintf('  -> Max Constraint Violation: %.6e\n', max_violation);

        % Check Outer Convergence
        if max_violation <= tol_c
            fprintf('ALM Converged! Constraints satisfied within tolerance.\n');
            break;
        end

        % Update Lagrange Multipliers (PHR formula for inequality constraints)
        lambda_next = max(0, lambda + mu * c);

        % Update Penalty Parameter
        % If the constraint violation didn't improve by at least 75%, increase mu
        if max_violation > 0.25 * prev_violation
            mu = min(mu * 5, 1e6); % Cap mu to prevent severe ill-conditioning
        end

        lambda = lambda_next;
        prev_violation = max_violation;
    end
    x_opt = x_opt';
end

% --- Helper Function ---
function L_A = eval_AL(x, physics_fun, obj_fun, con_fun, lambda, mu)
    % Evaluates the objective and constraints, returning the Augmented Lagrangian
    state = physics_fun(x');
    J = obj_fun(state);
    c = con_fun(state);
    c = c(:);

    % Powell-Hestenes-Rockafellar (PHR) formula
    penalty_term = sum( (1 / (2 * mu)) * (max(0, lambda + mu * c).^2 - lambda.^2) );
    L_A = J + penalty_term;
end