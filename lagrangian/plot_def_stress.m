function plot_def_stress(results, struct_mesh, params, stress_data, title_str, save_folder, save_plot)
%==========================================================================
% PLOT_DEFORMATION_AND_STRESS
% Plots the original shape, the deformed shape colored by the maximum
% stress, the locked toe points, and the applied load vector.
% Includes academic formatting, parametric titles, auto-saving, and
% full LaTeX rendering.
%==========================================================================
    f = figure('Color', 'w'); % Academic white background
   
    % Force all text renderers in this specific figure to LaTeX
    set(f, 'defaultTextInterpreter', 'latex');
    set(f, 'defaultAxesTickLabelInterpreter', 'latex');
    set(f, 'defaultLegendInterpreter', 'latex');
    set(f, 'defaultColorbarTickLabelInterpreter', 'latex');

    hold on;
   
    % 1. Plot Original Shape (Dashed black line for contrast)
    plot(results.x_orig, results.y_orig, "k--", 'LineWidth', 1.5, 'DisplayName', 'Original Shape');
   
    % 2. Plot Deformed Shape with Stresses (Convert Pa to MPa)
    scatter(results.x_def, results.y_def, 25, stress_data.sigma_max / 1e6, "filled", ...
        "MarkerEdgeColor", "none", 'DisplayName', 'Deformed Shape (Stress)');
   ylim([min(results.y_def)-0.05, max(results.y_def)+0.05 ]);
    % Colorbar formatting
    cb = colorbar('location', 'eastoutside');
    cb.Label.String = 'Max Stress (MPa)';
    cb.Label.Interpreter = 'latex';

    % 3. Identify and plot the "grounded" points (Locked Toe)
    L_total = struct_mesh.s(end);
    s_fixed_start = (L_total - params.L7) + (1.0 * params.L7);
    idx_fixed = find(struct_mesh.s >= s_fixed_start, 1, 'first');
   
    locked_x = results.x_orig(idx_fixed:end);
    locked_y = results.y_orig(idx_fixed:end);
    scatter(locked_x, locked_y, 40, 'r', 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Locked Toe');
   
    % 4. Force Vector Arrow
    Fx = params.F_mag * cosd(params.F_angle);
    Fy = params.F_mag * sind(params.F_angle);
   
    arrow_scale = 0.15 / params.F_mag;
    quiver(results.x_def(1), results.y_def(1), Fx, Fy, arrow_scale, ...
        'Color', [0 0.5 0], 'LineWidth', 2.0, 'MaxHeadSize', 1.5, 'DisplayName', 'Applied Load');

    % Academic Formatting
    axis equal;
    grid on; 
    grid minor;
    set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
   
    % Parameterized Title (Algorithm type + Force and Angle)
    full_title = sprintf('%s ($F = %g$ N at $%g^\\circ$)', title_str, params.F_mag, params.F_angle);
    title(full_title, 'FontSize', 14);
   
    xlabel('$x$ (m)', 'FontSize', 14);
    ylabel('$y$ (m)', 'FontSize', 14);
   
    % Legend formatting
    leg = legend('Location', 'best', 'FontSize', 11);
    leg.ItemTokenSize = [20, 18];
   
    % 5. Save Plot Logic
    if save_plot
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        % Create a safe filename without special characters or spaces
        safe_name = regexprep(title_str, '[^a-zA-Z0-9]', '_');
        filename = fullfile(save_folder, sprintf('%s_DefStress.png', safe_name));
        exportgraphics(f, filename, 'Resolution', 300);
        fprintf('Saved plot: %s\n', filename);
    end
end