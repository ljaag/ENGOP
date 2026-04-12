function J = ga_objective(x, params_base, mode)
%==========================================================================
% GA_OBJECTIVE
% Wrapper for GA. Pulls only the objective cost 'J' from the cache.
%==========================================================================
    [J, ~, ~] = ga_evaluator_cache(x, params_base, mode);
end