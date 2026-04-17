function [x_opt, history] = al_inner_bfgs(AL_fun, x0, lb, ub)
%==========================================================================
% AL_INNER_BFGS
% Stripped-down damped BFGS that ONLY minimizes the scalar function AL_fun.
%==========================================================================

    % --- 1. Parameters ---
    max_iter = 50;           % Fewer iterations needed per inner loop
    delta = 1e-4;            % Central finite difference step
    num_vars = length(x0);
    stall_iters = 10;        % "n" iterations to check for stall
    rel_tol = 0.005;         % 0.5% change threshold
   
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
   
    % Initial Evaluation
    f_current = AL_fun(unscale(x_scaled));
    grad_current = calc_grad(x_scaled, unscale, AL_fun, num_vars, delta);

    % --- 2. Main Optimization Loop ---
    for iter = 1:max_iter
        history.x(iter, :) = unscale(x_scaled)';
        history.f(iter) = f_current;
       
        fprintf('    Inner Iter: %2d | AL Obj: %.6e\n', iter, f_current);
       
        % =================================================================
        % --- ACTIVE-SET LOGIC ---
        % =================================================================
        tol_bound = 1e-6;
        active_lower = (x_scaled <= tol_bound) & (grad_current > 0);
        active_upper = (x_scaled >= 1 - tol_bound) & (grad_current < 0);
        active_mask = active_lower | active_upper;

        B_eff = B;
        g_eff = grad_current;

        if any(active_mask)
            g_eff(active_mask) = 0;
            B_eff(active_mask, :) = 0;
            B_eff(:, active_mask) = 0;
            active_idx = find(active_mask);
            for k = 1:length(active_idx)
                B_eff(active_idx(k), active_idx(k)) = 1;
            end
        end

        % Search Direction
        p = -B_eff \ g_eff;
       
        % Safeguard: Reset Hessian if the step points uphill
        if g_eff' * p >= 0 && norm(g_eff) > 1e-6
            B = eye(num_vars); B_eff = B;
            if any(active_mask)
                B_eff(active_mask, :) = 0; B_eff(:, active_mask) = 0;
                active_idx = find(active_mask);
                for k = 1:length(active_idx)
                    B_eff(active_idx(k), active_idx(k)) = 1;
                end
            end
            p = -B_eff \ g_eff;
        end
       
        % Normalize step if it explodes
        if norm(p) > 1.0; p = p / norm(p); end
       
        % =================================================================
        % --- LINE SEARCH TO BOUNDARY ---
        % =================================================================
        alpha_max = 1.0;
        for i = 1:num_vars
            if p(i) > 1e-12
                dist = max(0, 1.0 - x_scaled(i)) / p(i);
                if dist < alpha_max; alpha_max = dist; end
            elseif p(i) < -1e-12
                dist = max(0, 0.0 - x_scaled(i)) / p(i);
                if dist < alpha_max; alpha_max = dist; end
            end
        end
       
        if alpha_max < 1e-12; alpha_max = 1.0; end

        alpha = alpha_max;
        step_accepted = false;
       
        % Backtracking line search
        while ~step_accepted && alpha > 1e-6
            x_test = x_scaled + alpha * p;
            x_test = max(0, min(1, x_test));
           
            f_test = AL_fun(unscale(x_test));
           
            if f_test < f_current
                step_accepted = true;
            else
                alpha = alpha * 0.5;
            end
        end
       
        % Fallback recovery
        if ~step_accepted
            p_fallback = -g_eff;
            if norm(p_fallback) > 0; p_fallback = p_fallback / norm(p_fallback); end
           
            x_new = max(0, min(1, x_scaled + 1e-4 * p_fallback));
            f_test = AL_fun(unscale(x_new));
            step_accepted = true;
            B = eye(num_vars);
        else
            x_new = max(0, min(1, x_scaled + alpha * p));
        end
       
        % Convergence Check
        if norm(unscale(x_new) - unscale(x_scaled)) < 1e-6
            x_scaled = x_new;
            break;
        end

        % Plateau Exit Clause
        if iter > stall_iters
            f_old = history.f(iter - stall_iters + 1);
            if abs(f_old - f_test) / (abs(f_old) + 1e-12) < rel_tol
                x_scaled = x_new; f_current = f_test;
                break;
            end
        end
       
        % Evaluate New Gradient
        grad_new = calc_grad(x_new, unscale, AL_fun, num_vars, delta);
       
        % Damped BFGS Update
        s = x_new - x_scaled;
        y = grad_new - grad_current;
       
        Bs = B * s;
        sBs = s' * Bs;
        sy  = s' * y;
       
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
       
        x_scaled = x_new;
        f_current = f_test;
        grad_current = grad_new;
    end
   
    history.x = history.x(1:iter, :);
    history.f = history.f(1:iter);
    x_opt = unscale(x_scaled);
end

% --- Helper Functions ---
function grad = calc_grad(x_s, unscale, AL_fun, num_vars, delta)
    grad = zeros(num_vars, 1);
    for i = 1:num_vars
        x_fw = x_s; x_fw(i) = min(1, x_fw(i) + delta);
        f_fw = AL_fun(unscale(x_fw));
       
        x_bw = x_s; x_bw(i) = max(0, x_bw(i) - delta);
        f_bw = AL_fun(unscale(x_bw));
       
        grad(i) = (f_fw - f_bw) / (x_fw(i) - x_bw(i) + 1e-12);
    end
end