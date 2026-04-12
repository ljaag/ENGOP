function [x_opt, history] = damped_bfgs(physics_fun, obj_fun, con_fun, x0, lb, ub)
%==========================================================================
% Projected Damped BFGS Optimization
% Features:
%   - Handles bounds via projection
%   - Variable Scaling [0, 1] for numerical stability
%   - Powell's Damped BFGS update for noise resilience
%   - Internal penalty calculation for separate obj/con functions
%==========================================================================

    % --- 1. Parameters ---
    max_iter = 300;          
    delta = 1e-4;            % Central finite difference step
    num_vars = length(x0);
    PenaltyWeight = 10000;   % Internal Penalty Weight
    stall_iters = 30;         % "n" iterations to check for stall
    rel_tol = 0.001;         % 0.1% change threshold (0.001 = 0.1%)
   
    % Force column vectors
    lb = lb(:); ub = ub(:); x0 = x0(:);
   
    % Scaling functions
    scale = @(x) (x - lb) ./ (ub - lb);
    unscale = @(x_s) x_s .* (ub - lb) + lb;
   
    % Initialize
    x_scaled = scale(x0);
    B = eye(num_vars); % Initial Hessian Approximation
   
    % Preallocate history
    history.x = zeros(max_iter, num_vars);
    history.f = zeros(max_iter, 1);
   
    disp('Starting Streamlined Damped BFGS...');
   
    % Initial Evaluation
    f_current = eval_penalized(x_scaled, unscale, physics_fun, obj_fun, con_fun, PenaltyWeight);
    grad_current = calc_grad(x_scaled, unscale, physics_fun, obj_fun, con_fun, PenaltyWeight, num_vars, delta);

    % --- 2. Main Optimization Loop ---
    for iter = 1:max_iter
        history.x(iter, :) = unscale(x_scaled)';
        history.f(iter) = f_current;
       
        fprintf('Iter: %3d | Penalized Obj: %.6e\n', iter, f_current);
        current_x = unscale(x_scaled)';
        if length(current_x) >=10
            disp(90-current_x(15)-current_x(16))
        end
        % Step A: Search Direction
        p = -B \ grad_current;
       
        % Normalize step if it explodes
        if norm(p) > 1.0; p = p / norm(p); end
       
        % Step B: Line Search & Projection
        alpha = 1.0;
        step_accepted = false;
       
        while ~step_accepted && alpha > 1e-5
            % Project onto [0, 1] bounds
            x_test = max(0, min(1, x_scaled + alpha * p));
            f_test = eval_penalized(x_test, unscale, physics_fun, obj_fun, con_fun, PenaltyWeight);
           
            % Armijo decrease
            if f_test <= f_current + 1e-6
                step_accepted = true;
            else
                alpha = alpha * 0.5;
            end
        end
       
        % Apply step
        x_new = max(0, min(1, x_scaled + alpha * p));
       
        % Convergence Check
        if norm(unscale(x_new) - unscale(x_scaled)) < 1e-6
            fprintf('Converged successfully at iteration %d.\n', iter);
            x_scaled = x_new;
            break;
        end

        % Plateau Exit Clause
        if iter > stall_iters
            f_old = history.f(iter - stall_iters + 1);
            disp(abs(f_old - f_test) / (abs(f_old) + 1e-12))
            if abs(f_old - f_test) / (abs(f_old) + 1e-12) < rel_tol
                fprintf('Exit: Change < %.2f%% over %d iterations.\n', rel_tol*100, stall_iters);
                x_scaled = x_new; f_current = f_test; 
                break;
            end
        end
       
        % Step D: Evaluate New Gradient
        grad_new = calc_grad(x_new, unscale, physics_fun, obj_fun, con_fun, PenaltyWeight, num_vars, delta);
       
        % Step E: Damped BFGS Update
        s = x_new - x_scaled;
        y = grad_new - grad_current;
       
        Bs = B * s;
        sBs = s' * Bs;
        sy  = s' * y;
       
        % Powell's Dampening
        if sy >= 0.2 * sBs
            theta = 1.0;
        else
            theta = (0.8 * sBs) / (sBs - sy + 1e-12);
        end
       
        r = theta * y + (1 - theta) * Bs;
        sr = s' * r;
       
        if sr > 1e-12
            B = B - (Bs * Bs') / sBs + (r * r') / sr;
        end
       
        % Step F: Advance
        x_scaled = x_new;
        f_current = f_test;
        grad_current = grad_new;
    end
   
    % Clean up arrays
    history.x = history.x(1:iter, :);
    history.f = history.f(1:iter);
    x_opt = unscale(x_scaled)';
end

% --- Helper Functions ---

function f_penalized = eval_penalized(x_s, unscale, physics_fun, obj_fun, con_fun, weight)
    % Convert to real variables
    x_real = unscale(x_s)';
    % Run physics state once
    state = physics_fun(x_real);
    % Calculate separate components
    J = obj_fun(state);
    c = con_fun(state);
    % Apply penalty
    f_penalized = J + weight * sum(max(0, c).^2);
end

function grad = calc_grad(x_s, unscale, physics_fun, obj_fun, con_fun, weight, num_vars, delta)
    grad = zeros(num_vars, 1);
    for i = 1:num_vars
        x_fw = x_s; x_fw(i) = min(1, x_fw(i) + delta);
        f_fw = eval_penalized(x_fw, unscale, physics_fun, obj_fun, con_fun, weight);
       
        x_bw = x_s; x_bw(i) = max(0, x_bw(i) - delta);
        f_bw = eval_penalized(x_bw, unscale, physics_fun, obj_fun, con_fun, weight);
       
        grad(i) = (f_fw - f_bw) / (x_fw(i) - x_bw(i) + 1e-12);
    end
end
