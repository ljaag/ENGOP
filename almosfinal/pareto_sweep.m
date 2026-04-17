clc, clear, close all
% =========================================================================
% MAIN_PARETO_SWEEP_ALM
% Generates a high-quality Pareto front for the simplified blade model.
% Uses a dense, structured geometric sweep to map the design space into
% the objective space, clearly distinguishing feasible/unfeasible domains.
% =========================================================================

% --- 1. High-level Parameters ---
params.H_req  = 0.80;        
params.F_mag  = 2500;        
params.F_angle = 260;        

% Material & Geometric Setup
params.t = [10, 10, 12, 15, 12, 10, 10]./1000;
params.E = 170e9 .* ones(1,7);
params.w = 10 .* ones(1,7) ./ 100;

params.L1 = 0.1;  params.R2 = 0.1;  params.L3 = 0.1;
params.R4 = 0.04; params.L5 = 0.07; params.R6 = 0.05;
params.L7 = 0.1;
params.theta2 = -70; params.theta3 = 150;
params.res = 500;

params_base = params;

% Physics Handle
phys_simp = @(x) run_blade_physics(x, params_base, 'simplified');

% Bounds: x = [thickness, R4]
lb_simp = [0.005, 0.05];
ub_simp = [0.020, 0.35];

% =========================================================================
% 2. Structured Geometric Sweep of the Design Space
% =========================================================================
disp('--- Running Dense Geometric Sweep (Please Wait) ---');
N_sweep = 60; % Creates a 60x60 grid (3600 points) for a dense, clean mesh
t_vals = linspace(lb_simp(1), ub_simp(1), N_sweep);
R4_vals = linspace(lb_simp(2), ub_simp(2), N_sweep);

% Preallocate arrays for the mapped objective space
sweep_mass = zeros(N_sweep * N_sweep, 1);
sweep_energy = zeros(N_sweep * N_sweep, 1);
sweep_feasible = false(N_sweep * N_sweep, 1);

idx = 1;
for i = 1:N_sweep
    for j = 1:N_sweep
        x_test = [t_vals(i), R4_vals(j)];
        state = phys_simp(x_test);
        disp(idx)
        % Evaluate standard constraints
        c_test = blade_constraints(state);
       
        sweep_mass(idx) = state.mass;
        sweep_energy(idx) = state.energy;
       
        % Feasible if all constraints are satisfied (<= small tolerance)
        sweep_feasible(idx) = max(c_test) <= 1e-4;
        idx = idx + 1;
    end
end

% =========================================================================
% 3. Augmented Lagrangian Epsilon-Constraint Optimization
% =========================================================================
disp('--- Starting ALM Pareto Boundary Optimization ---');
num_runs = 15;
mass_limits = linspace(2.0, 0.5, num_runs);

pareto_mass = zeros(1, num_runs);
pareto_energy = zeros(1, num_runs);

x0_current = [0.015, 0.15];
pareto_obj = @(state) -1 * state.energy;

for i = 1:num_runs
    EPS_MASS = mass_limits(i);
    fprintf('Optimizing Pareto Point %d/%d (Max Mass: %.3f kg)...\n', i, num_runs, EPS_MASS);
   
    % Dynamic Constraint: Standard constraints + Mass limit
    pareto_con = @(state) [blade_constraints(state); state.mass - EPS_MASS];
   
    % Run ALM
    [x_opt, ~] = augmented_lagrangian(phys_simp, pareto_obj, pareto_con, x0_current, lb_simp, ub_simp);
   
    % Log final state
    final_state = phys_simp(x_opt);
    pareto_mass(i) = final_state.mass;
    pareto_energy(i) = final_state.energy;
   
    % Warm Start
    x0_current = x_opt;
end

disp('--- Optimization Complete. Generating Plot... ---');

% =========================================================================
% 4. High-Quality Plot Generation
% =========================================================================
f = figure('Name', 'Structured Sweep Pareto Front', 'Color', 'w', 'Position', [100, 100, 900, 600]);

% Force LaTeX rendering
set(f, 'defaultTextInterpreter', 'latex');
set(f, 'defaultAxesTickLabelInterpreter', 'latex');
set(f, 'defaultLegendInterpreter', 'latex');
hold on;

% Extract logical indices for clean plotting
idx_feas = sweep_feasible;
idx_inf = ~sweep_feasible;

% --- A. Plot Unfeasible Region (Soft Grey Curvilinear Mesh) ---
% Alpha blending at 0.5 allows the intersecting grid lines of the sweep to show
scatter(sweep_mass(idx_inf), sweep_energy(idx_inf), 15, [0.85 0.85 0.85], ...
    'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Unfeasible Designs');

% --- B. Plot Feasible Region (Solid Green Curvilinear Mesh) ---
scatter(sweep_mass(idx_feas), sweep_energy(idx_feas), 20, [0.2 0.8 0.2], ...
    'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Feasible Designs');

% --- C. Plot ALM Pareto Boundary (Bold Line + Markers) ---
plot(pareto_mass, pareto_energy, '-k', 'LineWidth', 2.5, 'DisplayName', 'Optimal Pareto Boundary');
scatter(pareto_mass, pareto_energy, 60, 'b', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0, ...
    'DisplayName', 'ALM Optimized Solutions');

% --- D. Academic Formatting ---
grid on;
grid minor;
title('Pareto Front: Mass vs. Strain Energy (Structured Sweep)', 'FontSize', 16);
xlabel('Mass (kg) [Minimize $\leftarrow$]', 'FontSize', 14);
ylabel('Strain Energy (J) [Maximize $\uparrow$]', 'FontSize', 14);

% Legend formatting
leg = legend('Location', 'southeast', 'FontSize', 12);
leg.ItemTokenSize = [25, 18];

% Clean up axes
set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on', 'Layer', 'top');

% Dynamically set limits based on the data to frame it perfectly
xlim([min(sweep_mass)-0.1, max(sweep_mass)+0.1]);
ylim([min(sweep_energy)-10, max(sweep_energy)+10]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc, clear, close all
% =========================================================================
% MAIN_VISUALIZE_CONSTRAINTS
% Maps the design space and plots the physical constraints (Stress & Mass)
% as explicit contour lines to visualize the feasible boundaries.
% =========================================================================

% --- 1. High-level Parameters ---
params.H_req  = 0.80;        
params.F_mag  = 2500;        
params.F_angle = 260;        

% Material & Geometric Setup
params.t = [10, 10, 12, 15, 12, 10, 10]./1000;
params.E = 170e9 .* ones(1,7);
params.w = 10 .* ones(1,7) ./ 100;

params.L1 = 0.1;  params.R2 = 0.1;  params.L3 = 0.1;
params.R4 = 0.04; params.L5 = 0.07; params.R6 = 0.05;
params.L7 = 0.1;
params.theta2 = -70; params.theta3 = 150;
params.res = 500;

params_base = params;
phys_simp = @(x) run_blade_physics(x, params_base, 'simplified');

% Bounds
lb_simp = [0.005, 0.05];
ub_simp = [0.020, 0.35];

% =========================================================================
% 2. Structured Meshgrid Sweep
% =========================================================================
disp('--- Sweeping Design Space for Constraints ---');
N = 50; % 50x50 grid
t_vals = linspace(lb_simp(1), ub_simp(1), N);
R4_vals = linspace(lb_simp(2), ub_simp(2), N);

[T_grid, R_grid] = meshgrid(t_vals, R4_vals);

Z_mass = zeros(N, N);
Z_energy = zeros(N, N);
Z_stress = zeros(N, N);

for i = 1:N
    for j = 1:N
        x_test = [T_grid(i,j), R_grid(i,j)];
        state = phys_simp(x_test);
       
        Z_mass(i,j) = state.mass;
        Z_energy(i,j) = state.energy;
        Z_stress(i,j) = state.max_actual_stress / 1e6; % Store in MPa
    end
end

% =========================================================================
% 3. Plot 1: The Design Space Contours (Thickness vs R4)
% =========================================================================
f1 = figure('Name', 'Design Space Constraints', 'Color', 'w', 'Position', [100, 100, 800, 600]);
set(f1, 'defaultTextInterpreter', 'latex');
set(f1, 'defaultAxesTickLabelInterpreter', 'latex');
set(f1, 'defaultLegendInterpreter', 'latex');

hold on;
% 1. Plot the Objective Function (Energy) as the background heatmap
contourf(T_grid * 1000, R_grid, Z_energy, 30, 'LineStyle', 'none');
colormap(parula);
cb = colorbar;
cb.Label.String = 'Strain Energy (J)';
cb.Label.Interpreter = 'latex';
cb.Label.FontSize = 12;

% 2. Plot the Stress Constraint Boundary (The 500 MPa Wall)
[C1, h1] = contour(T_grid * 1000, R_grid, Z_stress, [500, 500], 'r-', 'LineWidth', 3, 'DisplayName', 'Stress Limit (500 MPa)');

% 3. Plot Mass Constraint Lines (e.g., Epsilon Constraints)
[C2, h2] = contour(T_grid * 1000, R_grid, Z_mass, [1.0, 1.0], 'w--', 'LineWidth', 2, 'DisplayName', 'Mass Limit (1.0 kg)');
[C3, h3] = contour(T_grid * 1000, R_grid, Z_mass, [1.5, 1.5], 'k--', 'LineWidth', 2, 'DisplayName', 'Mass Limit (1.5 kg)');

% Academic Formatting
grid on;
title('Design Space: Constraint Boundaries', 'FontSize', 16);
xlabel('Thickness $t$ (mm)', 'FontSize', 14);
ylabel('Radius $R_4$ (m)', 'FontSize', 14);
legend([h1, h2, h3], 'Location', 'northwest', 'FontSize', 12);
set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on', 'Layer', 'top');

% =========================================================================
% 4. Plot 2: Objective Space Colored by Stress
% =========================================================================
f2 = figure('Name', 'Objective Space Constraint Heatmap', 'Color', 'w', 'Position', [950, 100, 800, 600]);
set(f2, 'defaultTextInterpreter', 'latex');
set(f2, 'defaultAxesTickLabelInterpreter', 'latex');
set(f2, 'defaultLegendInterpreter', 'latex');

hold on;
% Flatten arrays for scatter plotting
flat_mass = Z_mass(:);
flat_energy = Z_energy(:);
flat_stress = Z_stress(:);

% Plot all points, colored by their Maximum Stress
scatter(flat_mass, flat_energy, 25, flat_stress, 'filled');

% Use a custom colormap to highlight the danger zone (above 500 MPa)
caxis([100, 700]);
cmp = jet(256);
colormap(cmp);
cb2 = colorbar;
cb2.Label.String = 'Max Stress (MPa)';
cb2.Label.Interpreter = 'latex';
cb2.Label.FontSize = 12;

% Draw a thick black line strictly at the 500 MPa boundary using a trick
% We find where stress is approximately 500
[C4, h4] = contour(Z_mass, Z_energy, Z_stress, [500, 500], 'k-', 'LineWidth', 3, 'DisplayName', '500 MPa Boundary');

grid on; grid minor;
title('Pareto Space: Bounded by Max Stress', 'FontSize', 16);
xlabel('Mass (kg)', 'FontSize', 14);
ylabel('Strain Energy (J)', 'FontSize', 14);
legend(h4, 'Location', 'southeast', 'FontSize', 12);
set(gca, 'FontSize', 12, 'LineWidth', 1.0, 'Box', 'on');