function [J, c, ceq] = ga_evaluator_cache(x, params_base, mode)
%==========================================================================
% GA_EVALUATOR_CACHE
% Evaluates the physics once per unique 'x'. Uses a dictionary map to
% store the entire population's results so they survive between the
% objective evaluation phase and the constraint evaluation phase.
%==========================================================================
   
    % persistent dictionary to store multiple cached evaluations
    persistent cache_map
   
    % Initialize the dictionary if it doesn't exist yet
    if isempty(cache_map)
        cache_map = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    % Create a highly precise string representation of 'x' to act as the dictionary key
    % %.15g ensures floating point differences are captured
    x_key = sprintf('%.15g_', x);

    % 1. Check if 'x' is already in our dictionary
    if isKey(cache_map, x_key)
        % Cache hit! Extract the saved structure and return
        cached_data = cache_map(x_key);
        J   = cached_data.J;
        c   = cached_data.c;
        ceq = cached_data.ceq;
        return;
    end

    % 2. Cache miss! It's a new 'x'. Run the full physics engine.
    state = run_blade_physics(x, params_base, mode);
   
    % 3. Calculate objective and constraints
    J = blade_objective(state);
    c = blade_constraints(state);
    ceq = []; % No equality constraints in our formulation

    % Force 'c' to be a column vector to prevent GA dimension errors
    c = c(:);

    % 4. Save these results into the dictionary for the constraint phase
    cached_data.J   = J;
    cached_data.c   = c;
    cached_data.ceq = ceq;
   
    cache_map(x_key) = cached_data;
end