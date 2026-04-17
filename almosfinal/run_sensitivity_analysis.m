function run_sensitivity_analysis(x_nom, lb, ub, params_base, mode, var_names, title_str, save_folder, save_plot)
%==========================================================================
% RUN_SENSITIVITY_ANALYSIS
% Generates combined 2x3 subplot figures for 1D parameter sweeps, Tornado 
% charts, and Gradient Diagnostics. 
% Row 1: Thicknesses | Row 2: Geometric Variables
%==========================================================================

    num_vars = length(x_nom);
    num_steps = 50; % Recommended 50+ to see numerical noise in the derivatives
    
    % Auto-detect which variables are thicknesses vs geometry
    is_thick = startsWith(var_names, 't', 'IgnoreCase', true) | ...
               contains(var_names, 'Thickness', 'IgnoreCase', true);
    idx_thick = find(is_thick);
    idx_geom  = find(~is_thick);
    
    % Preallocate data storage for the sweeps
    mass_data = zeros(num_vars, num_steps);
    energy_data = zeros(num_vars, num_steps);
    def_data = zeros(num_vars, num_steps);
    
    % Evaluate nominal state
    state_nom = run_blade_physics(x_nom, params_base, mode);
    nom_mass = state_nom.mass;
    nom_energy = state_nom.energy;
    nom_def = state_nom.total_deflection;
    
    fprintf('\n--- Starting Sensitivity Analysis (%s mode) ---\n', mode);
    
    % 1. Perform the Parameter Sweeps
    for i = 1:num_vars
        var_sweep = linspace(lb(i), ub(i), num_steps);
        
        for j = 1:num_steps
            x_test = x_nom;
            x_test(i) = var_sweep(j); 
            
            state = run_blade_physics(x_test, params_base, mode);
            
            mass_data(i, j) = state.mass;
            energy_data(i, j) = state.energy;
            def_data(i, j) = state.total_deflection;
        end
        fprintf('Evaluated variable %d/%d: %s\n', i, num_vars, var_names{i});
    end
    
    % 2. Calculate Ranges for Tornado Charts
    delta_mass = max(mass_data, [], 2) - min(mass_data, [], 2);
    delta_energy = max(energy_data, [], 2) - min(energy_data, [], 2);
    delta_def = max(def_data, [], 2) - min(def_data, [], 2);
    
    % --- PLOTTING ---
    plot_combined_tornados(delta_mass, delta_energy, delta_def, var_names, idx_thick, idx_geom, title_str, save_folder, save_plot);
    
    plot_combined_1d_sweeps(mass_data, energy_data, def_data, num_steps, var_names, ...
                            nom_mass, nom_energy, nom_def, idx_thick, idx_geom, title_str, save_folder, save_plot);
                        
    plot_combined_diagnostics(mass_data, energy_data, def_data, num_steps, var_names, idx_thick, idx_geom, title_str, save_folder, save_plot);
end

%==========================================================================
% HELPER PLOTTING FUNCTIONS (2x3 Grids)
%==========================================================================

function plot_combined_tornados(delta_mass, delta_energy, delta_def, var_names, idx_thick, idx_geom, title_str, save_folder, save_plot)
    f = figure('Color', 'w', 'Position', [100, 100, 1500, 800]); % Taller for 2 rows
    set_latex_defaults(f);
    
    groups = {idx_thick, idx_geom};
    row_titles = {' ', ' '};
    
    for g = 1:2
        idx = groups{g};
        if isempty(idx), continue; end
        
        names = var_names(idx);
        row_offset = (g-1)*3; % Shifts to bottom row for g=2
        
        % --- Mass ---
        subplot(2, 3, row_offset + 1);
        [s_mass, sort_mass] = sort(delta_mass(idx), 'ascend');
        barh(s_mass, 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
        format_tornado_axes(names(sort_mass), sprintf('Mass %s', row_titles{g}));
        
        % --- Energy ---
        subplot(2, 3, row_offset + 2);
        [s_energy, sort_energy] = sort(delta_energy(idx), 'ascend');
        barh(s_energy, 'FaceColor', [0.8 0.4 0.2], 'EdgeColor', 'k');
        format_tornado_axes(names(sort_energy), sprintf('Strain Energy %s', row_titles{g}));
        
        % --- Deflection ---
        subplot(2, 3, row_offset + 3);
        [s_def, sort_def] = sort(delta_def(idx), 'ascend');
        barh(s_def, 'FaceColor', [0.4 0.7 0.4], 'EdgeColor', 'k');
        format_tornado_axes(names(sort_def), sprintf('Deflection %s', row_titles{g}));
    end
    
    sgtitle(sprintf('%s - Sensitivity Tornado Charts', title_str), 'FontSize', 16, 'Interpreter', 'latex');
    save_figure_logic(f, [title_str, ' Tornados'], save_folder, save_plot);
end

function plot_combined_1d_sweeps(mass_data, energy_data, def_data, num_steps, var_names, nom_mass, nom_energy, nom_def, idx_thick, idx_geom, title_str, save_folder, save_plot)
    f = figure('Color', 'w', 'Position', [100, 100, 1500, 800]);
    set_latex_defaults(f);
    normalized_x = linspace(0, 1, num_steps);
    
    % Global distinct colors and cyclic line styles
    all_colors = turbo(length(var_names));
    styles = {'-', '--', ':', '-.'}; 
    
    groups = {idx_thick, idx_geom};
    row_titles = {'Thicknesses', 'Geometry'};
    
    for g = 1:2
        idx = groups{g};
        if isempty(idx), continue; end
        row_offset = (g-1)*3;
        
        % --- Mass ---
        subplot(2, 3, row_offset + 1); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, mass_data(i, :), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty);
        end
        yline(nom_mass, 'k--', 'Nominal', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Mass (kg) %s', row_titles{g}));
        
        % --- Energy ---
        subplot(2, 3, row_offset + 2); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, energy_data(i, :), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty);
        end
        yline(nom_energy, 'k--', 'Nominal', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Strain Energy (J) %s', row_titles{g}));
        
        % --- Deflection ---
        subplot(2, 3, row_offset + 3); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, def_data(i, :), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty, 'DisplayName', var_names{i});
        end
        yline(nom_def, 'k--', 'Nominal', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Deflection (m) %s', row_titles{g}));
        legend('Location', 'eastoutside', 'FontSize', 11, 'Interpreter', 'none');
    end
    
    sgtitle(sprintf('%s - 1D Parameter Sweeps', title_str), 'FontSize', 16, 'Interpreter', 'latex');
    save_figure_logic(f, [title_str, ' 1D Sweeps'], save_folder, save_plot);
end

function plot_combined_diagnostics(mass_data, energy_data, def_data, num_steps, var_names, idx_thick, idx_geom, title_str, save_folder, save_plot)
    f = figure('Color', 'w', 'Position', [100, 100, 1500, 800]);
    set_latex_defaults(f);
    normalized_x = linspace(0, 1, num_steps);
    
    all_colors = turbo(length(var_names));
    styles = {'-', '--', ':', '-.'}; 
    
    groups = {idx_thick, idx_geom};
    row_titles = {' ', ' '};
    
    for g = 1:2
        idx = groups{g};
        if isempty(idx), continue; end
        row_offset = (g-1)*3;
        
        % --- Mass ---
        subplot(2, 3, row_offset + 1); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, gradient(mass_data(i, :), normalized_x), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty);
        end
        yline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Grad $d$(Mass)/$dx$ %s', row_titles{g}));
        
        % --- Energy ---
        subplot(2, 3, row_offset + 2); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, gradient(energy_data(i, :), normalized_x), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty);
        end
        yline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Grad $d$(Energy)/$dx$ %s', row_titles{g}));
        
        % --- Deflection ---
        subplot(2, 3, row_offset + 3); hold on;
        for k = 1:length(idx)
            i = idx(k); sty = styles{mod(k-1, length(styles)) + 1};
            plot(normalized_x, gradient(def_data(i, :), normalized_x), 'LineWidth', 2, 'Color', all_colors(i,:), 'LineStyle', sty, 'DisplayName', var_names{i});
        end
        yline(0, 'k-', 'Zero Gradient', 'LineWidth', 1.5, 'HandleVisibility', 'off');
        format_sweep_axes(sprintf('Grad $d$(Defl.)/$dx$ %s', row_titles{g}));
        legend('Location', 'eastoutside', 'FontSize', 11, 'Interpreter', 'none');
    end
    
    sgtitle(sprintf('%s - Trait Diagnostics (Derivatives)', title_str), 'FontSize', 16, 'Interpreter', 'latex');
    save_figure_logic(f, [title_str, ' Diagnostics'], save_folder, save_plot);
end

%==========================================================================
% REUSABLE UTILITIES
%==========================================================================

function format_tornado_axes(sorted_names, metric_name)
    grid on; grid minor;
    set(gca, 'YTick', 1:length(sorted_names), 'YTickLabel', sorted_names, ...
        'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on', 'TickLabelInterpreter', 'none');
    xlabel('$\Delta$ (Max - Min)', 'FontSize', 12);
    title(metric_name, 'FontSize', 14, 'Interpreter', 'latex');
end

function format_sweep_axes(y_label_str)
    grid on; grid minor;
    set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');
    xlabel('Norm. Range ($0 \rightarrow 1$)', 'FontSize', 12);
    ylabel(y_label_str, 'FontSize', 12, 'Interpreter', 'latex');
end

function set_latex_defaults(fig_handle)
    set(fig_handle, 'defaultTextInterpreter', 'latex');
    set(fig_handle, 'defaultAxesTickLabelInterpreter', 'latex');
    set(fig_handle, 'defaultLegendInterpreter', 'latex');
    set(fig_handle, 'defaultColorbarTickLabelInterpreter', 'latex');
end

function save_figure_logic(fig_handle, title_str, save_folder, save_plot)
    if save_plot
        if ~exist(save_folder, 'dir')
            mkdir(save_folder);
        end
        safe_name = regexprep(title_str, '[^a-zA-Z0-9]', '_');
        filename = fullfile(save_folder, sprintf('%s.png', safe_name));
        exportgraphics(fig_handle, filename, 'Resolution', 300);
        fprintf('Saved plot: %s\n', filename);
    end
end