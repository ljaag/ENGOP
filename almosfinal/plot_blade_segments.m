function plot_blade_segments(bx, by, res, title_str, save_folder, save_plot)
%==========================================================================
% PLOT_BLADE_SEGMENTS
% Plots the 7 individual segments of the original blade geometry.
% Includes academic formatting, auto-saving, and full LaTeX rendering.
%==========================================================================
    f = figure('Color', 'w');
   
    % Force all text renderers in this specific figure to LaTeX
    set(f, 'defaultTextInterpreter', 'latex');
    set(f, 'defaultAxesTickLabelInterpreter', 'latex');
    set(f, 'defaultLegendInterpreter', 'latex');
    set(f, 'defaultColorbarTickLabelInterpreter', 'latex');
    
   
    hold on;
   
    colors = lines(7); % Distinct standard colors for each segment
   
    for i = 0:6
        plot(bx(1+res*i:res*(i+1)), by(1+res*i:res*(i+1)), ...
            'LineWidth', 4, 'Color', colors(i+1,:), 'DisplayName', sprintf('Section %d', i+1));
    end
   
    % Academic Formatting
    axis equal;
    grid on;
    set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
   
    % Parameterized Title and Labels
    full_title = sprintf('%s - Base Geometry Segments', title_str);
    title(full_title, 'FontSize', 14);
    xlabel('$x$ (m)', 'FontSize', 14);
    ylabel('$y$ (m)', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 11);
   
    % Save Plot Logic
    if save_plot
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        safe_name = regexprep(title_str, '[^a-zA-Z0-9]', '_');
        filename = fullfile(save_folder, sprintf('%s_Segments.png', safe_name));
        exportgraphics(f, filename, 'Resolution', 300);
        fprintf('Saved plot: %s\n', filename);
        filename = fullfile(save_folder, sprintf('%s_Segments.fig', safe_name));
        savefig(f, filename);
        fprintf('Saved FIG plot: %s\n', filename)
    end
end