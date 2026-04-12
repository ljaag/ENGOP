function [J, c, ceq] = ga_evaluator_cache(x, params_base, mode)
%==========================================================================
% GA_EVALUATOR_CACHE
% Evaluates the physics once per unique 'x'. If 'ga' asks for the same
% 'x' twice in a row, it returns the cached results to save time.
%==========================================================================
   
    % Persistent variables remember their values between function calls
    persistent last_x cached_J cached_c cached_ceq
    
    x_col = x(:);

    % 1. Check if 'x' is exactly the same as the last time this was called
    if ~isempty(last_x) && isequal(x_col, last_x)
        % Cache hit! Return the saved values immediately.
        J = cached_J;
        c = cached_c;
        ceq = cached_ceq;
        return;
    end

    % 2. Cache miss! It's a new 'x'. Run the full physics engine.
    state = run_blade_physics(x, params_base, mode);
   
    % 3. Calculate objective and constraints
    J = blade_objective(state);
    c = blade_constraints(state);
    ceq = []; % No equality constraints in our formulation

    % 4. Save these results into the persistent memory for the next call
    last_x = x_col;
    cached_J = J;
    cached_c = c;
    cached_ceq = ceq;
end