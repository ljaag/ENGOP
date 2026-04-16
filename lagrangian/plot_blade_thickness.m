function plot_blade_thickness(struct_mesh, title_str, save_folder, save_plot)
%==========================================================================
% PLOT_BLADE_THICKNESS
% Visualizes the thickness distribution along the blade.
% Includes academic formatting, auto-saving, and full LaTeX rendering.
%==========================================================================
    f = figure('Color', 'w');
   
    % Force all text renderers in this specific figure to LaTeX
    set(f, 'defaultTextInterpreter', 'latex');
    set(f, 'defaultAxesTickLabelInterpreter', 'latex');
    set(f, 'defaultLegendInterpreter', 'latex');
    set(f, 'defaultColorbarTickLabelInterpreter', 'latex');
   
    % Scale visualization thickness, but plot actual values in mm on colorbar
    scatter(struct_mesh.x, struct_mesh.y, 10000 * struct_mesh.t, struct_mesh.t * 1000, ...
        "filled", "MarkerEdgeColor", "none", "LineWidth", 0.25);
   
    ylim([min(struct_mesh.y)-0.05, max(struct_mesh.y)+0.05 ]);


    cb = colorbar;
    cb.Label.String = 'Thickness (mm)';
   
    % Academic Formatting
    axis equal;
    grid on;
    set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
   
    % Parameterized Title and Labels
    full_title = sprintf('%s - Thickness', title_str);
    title(full_title, 'FontSize', 14);
    xlabel('$x$ (m)', 'FontSize', 14);
    ylabel('$y$ (m)', 'FontSize', 14);
    
    % Save Plot Logic
    if save_plot
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        safe_name = regexprep(title_str, '[^a-zA-Z0-9]', '_');
        filename = fullfile(save_folder, sprintf('%s_Thickness.png', safe_name));
        exportgraphics(f, filename, 'Resolution', 300);
        fprintf('Saved plot: %s\n', filename);
    end
end