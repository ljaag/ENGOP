function [x_opt, history] = custom_penalty_gradient_descent(obj_wrapper, x0, lb, ub)
    % --- Algorithm Parameters ---
    max_outer_iter = 10;   % Penalty updates
    max_inner_iter = 25;   % Gradient descent steps per penalty
    alpha = 1e-4;          % Learning rate (step size)
    delta = 1e-6;          % Finite difference step
    R = 10;                % Initial Penalty factor
    penalty_multiplier = 5;% How much R grows each outer loop
   
    num_vars = length(x0);
    x_current = x0;
    history.x = []; history.f = [];
   
    for outer = 1:max_outer_iter
        for inner = 1:max_inner_iter
            % 1. Evaluate current Penalty Function, P(x)
            [J, c, ceq] = obj_wrapper(x_current);
           
            % P(x) = J(x) + R * sum(max(0, c)^2) + R * sum(ceq^2)
            penalty_term = R * sum(max(0, c).^2) + R * sum(ceq.^2);
            P_current = J + penalty_term;
           
            % Store history for reporting
            history.x = [history.x; x_current];
            history.f = [history.f; P_current];
           
            % 2. Calculate Gradient using Finite Differences
            grad = zeros(1, num_vars);
            for i = 1:num_vars
                x_forward = x_current;
                x_forward(i) = x_forward(i) + delta;
               
                [J_fw, c_fw, ceq_fw] = obj_wrapper(x_forward);
                P_forward = J_fw + R * sum(max(0, c_fw).^2) + R * sum(ceq_fw.^2);
               
                grad(i) = (P_forward - P_current) / delta;
            end
           
            % 3. Update Variables (Gradient Descent Step)
            x_new = x_current - alpha * grad;
           
            % 4. Enforce Bounds (lb, ub)
            x_new = max(lb, min(ub, x_new));
           
            disp(norm(x_new - x_current))
            disp(outer*inner)
            % Convergence check for inner loop
            if norm(x_new - x_current) < 1e-5
                break;
            end
            x_current = x_new;
        end
        % Increase penalty factor to enforce constraints strictly
        R = R * penalty_multiplier;
    end
    x_opt = x_current;
end