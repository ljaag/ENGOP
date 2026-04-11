clc, clear, close all
% --- Main Script: Define and Plot Cheetah Blade ---
% High level parameters
params.H_req  = 0.80;       % Maximum height from ground to stump (m)

% Force parameters
params.F_mag = 1500; % [N]
params.F_angle = 250; % [°]

% Material properties | these can be constant or vectors

params.t = [10, 10, 12, 15, 12, 10, 10]./1000; % [m] Thikness of each section input mm | DV
params.E = 170e9.*ones(1,7);                   % Young's modulous, constant
params.w = 10.*ones(1,7)./100;                 % [m] Section width, can be DV

% Geometric parameters | DV
params.L1 = 0.1;            % Stump connection
params.R2 = 0.1;            % Arch back
params.L3 = 0.1;            % Connect arches
params.R4 = 0.04;           % Arch forward
params.L5 = 0.07;           % Diagonal element
params.R6 = 0.05;           % Heel
params.L7 = 0.1;            % Sole

params.theta2 = -70;        % Sweep angle 1
params.theta3 = 150;        % Sweep angle 2

% Run function
params.res = 500; % number of elements per section
res = params.res;
[bx, by] = blade_structure(params);

disp('Height: ' + string(max(by)))

% --- 1. Plot the prosthesis geometry preliminary ---
plot_blade_segments(bx, by, res);

% --- 2. Assign material properties & Plot Thickness ---
struct_mesh = material_properties([bx; by], params);
plot_blade_thickness(struct_mesh);

% --- 3. Define & Solve structural problem ---
results = solve_blade_deformation_progressive(struct_mesh, params);

% --- 4. Compute stresses ---
stress_data = compute_stresses(struct_mesh, params, results);

% --- 5. Visualize Deformation and Stress ---
plot_def_stress(results, struct_mesh, params, stress_data);


% Validation Deflection
P = params.F_mag;           % Force in N
L = 0.37;                   % Length in m
w = params.w(1);            % Width in m
t = 0.01;                   % Thickness in m
E = params.E(1);            % Young's Modulus in Pa (Assumed for Carbon Fiber)

% Moment of Inertia
I = (w * t^3) / 12;

% Analytical Solutions
delta_analytical = (P * L^3) / (3 * E * I);
U_analytical = (P * delta_analytical) / 2;

fprintf('\nAnalytical Deflection: %.4f m\n', delta_analytical);
fprintf('Simulated (x) Deflection: %.4f m\n', (-results.x_orig(1)+results.x_def(1)));
fprintf('Simulated (y) Deflection: %.4f m\n', (-results.y_orig(1)+results.y_def(1)));
fprintf('Analytical Energy: %.4f J\n', U_analytical);
fprintf('Simulated Energy: %.4f J\n\n', results.energy);


% Base parameters (fixed values)
params_base = params;


% ---------------------------------------------------------
% PHASE 1: Run the Simplified Model
% ---------------------------------------------------------
x0_simp = [0.015, 0.15];
lb_simp = [0.005, 0.05];
ub_simp = [0.020, 0.35];

% Create a handle that locks the mode to 'simplified'
eval_simp = @(x) blade_evaluator(x, params_base, 'simplified');
tic
[x_opt_simp, hist_simp] = damped_bfgs(eval_simp, x0_simp, lb_simp, ub_simp);
toc


% =========================================================================
% PLOT: OPTIMIZED SIMPLIFIED GEOMETRY
% =========================================================================
disp('--- Plotting Optimized Simplified Geometry ---');

% 1. Reconstruct the parameter structure cleanly using our new function
params_simp_plot = update_blade_params(x_opt_simp, params_base, 'simplified');

disp(['Optimized thickness (t): ', num2str(x_opt_simp(1))])
disp(['Optimized Radius 4 (R4): ', num2str(x_opt_simp(2))])

% 2. Generate geometry and plot
params_simp_plot.res = 1000;
[bx_simp, by_simp] = blade_structure(params_simp_plot);

figure('Name', 'Optimized Simplified Geometry');
plot(bx_simp, by_simp, 'k-', 'LineWidth', 5, 'DisplayName', 'Simplified Blade', 'MarkerFaceColor', 'k');
hold on;
yline(0.80, 'r--', 'Target Height (0.80m)', 'LineWidth', 2);
yline(0, 'b-', 'Ground', 'LineWidth', 2);
axis equal; grid on; grid minor;
title('Optimized Simplified Blade Geometry');
xlabel('x (m)'); ylabel('y (m)');
legend('Location', 'best');

plot_blade_segments(bx_simp, by_simp, params_simp_plot.res)

% 3. Compute properties and plot deformation/stress
struct_mesh_simp = material_properties([bx_simp; by_simp], params_simp_plot);
results_simp = solve_blade_deformation_progressive(struct_mesh_simp, params_simp_plot);
stress_data_simp = compute_stresses(struct_mesh_simp, params_simp_plot, results_simp);

plot_def_stress(results_simp, struct_mesh_simp, params_simp_plot, stress_data_simp);

% ---------------------------------------------------------
% PHASE 2: Run the Full Model
% ---------------------------------------------------------
t_start = x_opt_simp(1) * ones(1,7);
L_start = [0.4, 0.1, 0.07, 0.1];
R_start = [x_opt_simp(2), 0.04, 0.05];
theta_start = [180, 150];
x0_full = [t_start, L_start, R_start, theta_start];
lb_full = [0.005 * ones(1,7), 0.05, 0.05, 0.05, 0.05, 0.05, 0.02, 0.02, 90, 90];
ub_full = [0.030 * ones(1,7), 0.9, 0.2, 0.2, 0.2, 0.3, 0.15, 0.15, 270, 270];

% Create a handle that locks the mode to 'full'
eval_full = @(x) blade_evaluator(x, params_base, 'full');

%[x_opt_full, hist_full] = damped_bfgs(eval_full, x0_full, lb_full, ub_full);