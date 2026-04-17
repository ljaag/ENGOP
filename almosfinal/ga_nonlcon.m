function [c, ceq] = ga_nonlcon(x, params_base, mode)
%==========================================================================
% GA_NONLCON
% Wrapper for GA. Pulls only the constraints 'c' and 'ceq' from the cache.
%==========================================================================
    [~, c, ceq] = ga_evaluator_cache(x, params_base, mode);
end