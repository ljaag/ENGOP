function plot_def_stress(results, struct_mesh, params, stress_data)
%==========================================================================
% PLOT_DEFORMATION_AND_STRESS
% Plots the original shape, the deformed shape colored by the maximum
% stress, the locked toe points, and the applied load vector.
%==========================================================================
    figure;
    hold on;
   
    % 1. Plot Original Shape (Dotted blue line)
    plot(results.x_orig, results.y_orig, "b:", 'LineWidth', 1.5, 'DisplayName', 'Original Shape');
   
    % 2. Plot Deformed Shape with Stresses (Scatter plot with color map)
    scatter(results.x_def, results.y_def, 20, stress_data.sigma_max, "filled", ...
        "MarkerEdgeColor", "none", 'DisplayName', 'Deformed Shape (Stress)');
    colorbar('location', 'eastoutside');
   
    % 3. Identify and plot the "grounded" points (Locked Toe)
    L_total = struct_mesh.s(end);
    s_fixed_start = (L_total - params.L7) + (1.0 * params.L7);
    idx_fixed = find(struct_mesh.s >= s_fixed_start, 1, 'first');
   
    locked_x = results.x_orig(idx_fixed:end);
    locked_y = results.y_orig(idx_fixed:end);
    scatter(locked_x, locked_y, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.4, 'DisplayName', 'Locked Toe');
   
    % 4. Force Vector Arrow
    Fx = params.F_mag * cosd(params.F_angle);
    Fy = params.F_mag * sind(params.F_angle);
   
    % Calculate a visual scale so the arrow doesn't dwarf the blade
    arrow_scale = 0.15 / params.F_mag;
    quiver(results.x_def(1), results.y_def(1), Fx, Fy, arrow_scale, ...
        'Color', [0 .5 0], 'LineWidth', 2.5, 'MaxHeadSize', 2, 'DisplayName', 'Applied Load');

    axis equal; grid minor; grid on;
    title(['Blade Deflection & Stress: F = ', num2str(params.F_mag), ' N at ', num2str(params.F_angle), '°']);
    xlabel('x (m)'); ylabel('y (m)');
    legend('Location', 'northwest');
end
