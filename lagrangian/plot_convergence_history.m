function plot_convergence_history(history, title_str, save_folder, save_plot)
%==========================================================================
% PLOT_CONVERGENCE_HISTORY
% Visualizes the optimization progression. Automatically detects if the
% history contains Augmented Lagrangian constraint data and plots it on a
% logarithmic scale.
%==========================================================================
    f_fig = figure('Color', 'w');
   
    % Force all text renderers to LaTeX for academic formatting
    set(f_fig, 'defaultTextInterpreter', 'latex');
    set(f_fig, 'defaultAxesTickLabelInterpreter', 'latex');
    set(f_fig, 'defaultLegendInterpreter', 'latex');
   
    % Check if the history struct contains ALM constraint violations
    has_constraints = isfield(history, 'max_c') && ~isempty(history.max_c);
   
    % --- Top Plot: Function Value ---
    if has_constraints
        subplot(2, 1, 1);
    end
   
    iters = 1:length(history.f);
    plot(iters, history.f, 'b-', 'LineWidth', 2);
   
    grid on; grid minor;
    set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
   
    % Titles and Labels
    full_title = sprintf('%s - Convergence', title_str);
    title(full_title, 'FontSize', 14);
    ylabel('Function Value ($J$ or $\mathcal{L}_A$)', 'FontSize', 14);
   
    if ~has_constraints
        xlabel('Iteration', 'FontSize', 14);
    end
   
    % --- Bottom Plot: Constraint Violations (If ALM is used) ---
    if has_constraints
        subplot(2, 1, 2);
        outer_iters = 1:length(history.max_c);
       
        % Use a semilogy plot because constraint violations shrink exponentially
        semilogy(outer_iters, history.max_c, 'r-o', 'LineWidth', 2, ...
            'MarkerFaceColor', 'r', 'MarkerSize', 6);
        hold on;
       
        % Plot the convergence tolerance line (1e-4 from augmented_lagrangian)
        yline(1e-4, 'k--', 'Tolerance Limit', 'LineWidth', 1.5, ...
            'LabelHorizontalAlignment', 'left', 'Interpreter', 'latex');
       
        grid on; grid minor;
        set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
        xlabel('Outer ALM Iteration', 'FontSize', 14);
        ylabel('Max Constraint Violation', 'FontSize', 14);
    end
   
    % --- Save Plot Logic ---
    if save_plot
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        % Create a safe filename without special characters or spaces
        safe_name = regexprep(title_str, '[^a-zA-Z0-9]', '_');
        filename = fullfile(save_folder, sprintf('%s_Convergence.png', safe_name));
        exportgraphics(f_fig, filename, 'Resolution', 300);
        fprintf('Saved plot: %s\n', filename);
    end
end