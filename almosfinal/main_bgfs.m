clc, clear, close all
% =========================================================================
% =========================================================================

% Plotting parameters
save_dir = fullfile(pwd, 'Output_280_weight');
save_op = true;



% High level parameters
params.H_req  = 0.80;       % Maximum height from ground to stump (m)

% Force parameters
params.F_mag = 2500; % [N]
params.F_angle = 280; % [°]

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
% [bx, by] = blade_structure(params);
% 
% % --- 1. Plot the prosthesis geometry preliminary ---
% plot_blade_segments(bx, by, res);
% 
% % --- 2. Assign material properties & Plot Thickness ---
% struct_mesh = material_properties([bx; by], params);
% plot_blade_thickness(struct_mesh);
% 
% % --- 3. Define & Solve structural problem ---
% results = solve_blade_deformation_progressive(struct_mesh, params);
% 
% % --- 4. Compute stresses ---
% stress_data = compute_stresses(struct_mesh, params, results);
% 
% % --- 5. Visualize Deformation and Stress ---
% plot_def_stress(results, struct_mesh, params, stress_data);


% Base parameters (fixed values)
params_base = params;

%% =========================================================================
% Run Simplified Model
% =========================================================================
disp('======================================================');
disp('--- Running Simple Geometry ---');
x0_simp = [0.015, 0.15]; % Initial guess
lb_simp = [0.005, 0.05];
ub_simp = [0.020, 0.35];

% 1. Define the physics handle
phys_simp = @(x) run_blade_physics(x, params_base, 'simplified');

% 2. Run the modified BFGS with separate functions
tic
[x_opt_simp, hist_simp] = augmented_lagrangian(phys_simp, @blade_objective, @blade_constraints, x0_simp, lb_simp, ub_simp);
toc


%% =========================================================================
% PLOT: Optimal Simple Geometry
% =========================================================================


% 1. Reconstruct the parameter structure cleanly using our new function
params_simp_plot = update_blade_params(x_opt_simp, params_base, 'simplified');

disp(['Optimized thickness (t): ', num2str(x_opt_simp(1))])
disp(['Optimized Radius 4 (R4): ', num2str(x_opt_simp(2))])

% 2. Generate geometry and plot
params_simp_plot.res = 1000;
[bx_simp, by_simp] = blade_structure(params_simp_plot);

% figure('Name', 'Optimized Simplified Geometry');
% plot(bx_simp, by_simp, 'k-', 'LineWidth', 5, 'DisplayName', 'Simplified Blade', 'MarkerFaceColor', 'k');
% hold on;
% yline(params.H_req, 'r--', 'Target Height', 'LineWidth', 2);
% yline(0, 'b-', 'Ground', 'LineWidth', 2);
% axis equal; grid on; grid minor;
% title('Optimized Simplified Blade Geometry');
% xlabel('x (m)'); ylabel('y (m)');
% legend('Location', 'best');

% 3. Compute properties and plot deformation/stress
struct_mesh_simp = material_properties([bx_simp; by_simp], params_simp_plot);
results_simp = solve_blade_deformation_progressive(struct_mesh_simp, params_simp_plot);
stress_data_simp = compute_stresses(struct_mesh_simp, params_simp_plot, results_simp);

% New ploting call
plot_blade_segments(bx_simp, by_simp, params_simp_plot.res, 'Simple geometry AL-BFGS', save_dir, save_op)
plot_blade_thickness(struct_mesh_simp, 'Simple geometry AL-BFGS', save_dir, save_op);
plot_def_stress(results_simp, struct_mesh_simp, params_simp_plot, stress_data_simp, 'Simple geometry AL-BFGS', save_dir, save_op);
plot_convergence_history(hist_simp, 'Simple Geometry ALM', save_dir, true)
%% =========================================================================
% Full model run
% =========================================================================
disp('======================================================');
disp('--- Running Full Geometry ---');
t_start = x_opt_simp(1) * ones(1,7); % Warm start
L_start = [0.1, 0.04, 0.1];
R_start = [0.05, 0.05, 0.05];
theta_start = [-70, 130];
x0_full = [t_start, L_start, R_start, theta_start];
lb_full = [0.005 * ones(1,7), 0.02, 0.02, 0.02, 0.02, 0.02, 0.04, -120, 5];
ub_full = [0.080 * ones(1,7), 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, -5, 179.9];

% Create a handle that locks the mode to 'full'
eval_full = @(x) run_blade_physics(x, params_base, 'full');
tic
[x_opt_full, hist_full] = augmented_lagrangian(eval_full, @blade_objective, @blade_constraints, x0_full, lb_full, ub_full);
toc
%% =========================================================================
% PLOT: Full model
% =========================================================================


% 1. Reconstruct the parameter structure cleanly using our new function
params_full_plot = update_blade_params(x_opt_full, params_base, 'full');

disp(['Optimized thicknesses (t): \n', num2str(x_opt_full(1:7))])
disp(['Optimized Radius 4 (R4): \n', num2str(x_opt_full(8:end))])

% 2. Generate geometry and plot
params_full_plot.res = 1000;
[bx_full, by_full] = blade_structure(params_full_plot);
plot_blade_segments(bx_full, by_full, params_full_plot.res, 'Full geometry AL-BFGS', save_dir, save_op)

% Compute properties and plot deformation/stress
struct_mesh_full = material_properties([bx_full; by_full], params_full_plot);
plot_blade_thickness(struct_mesh_full, 'Full geometry AL-BFGS', save_dir, save_op);
results_full = solve_blade_deformation_progressive(struct_mesh_full, params_full_plot);
stress_data_full = compute_stresses(struct_mesh_full, params_full_plot, results_full);

plot_def_stress(results_full, struct_mesh_full, params_full_plot, stress_data_full, 'Full geometry AL-BFGS', save_dir, save_op);


plot_convergence_history(hist_full, 'Full Geometry ALM', save_dir, true)


%% =========================================================================
% Run Genetic Algorithm simple
% =========================================================================
disp('======================================================');
disp('--- Running GA simplified ---');
clear ga_evaluator_cache


% We use the same bounds and initial guess
nvars = length(x0_simp);

% Setup the wrapper
obj_fun_ga = @(x) ga_objective(x, params_base, 'simplified');
nonlcon_fun_ga = @(x) ga_nonlcon(x, params_base, 'simplified');

% Configure GA Options
options_ga = optimoptions('ga', ...
    'Display', 'iter', ...
    'PopulationSize', 20, ...    % Smaller population for quicker testing
    'MaxGenerations', 50, ...    % Max iterations
    'InitialPopulationMatrix', x0_simp, ... % Seed it with our BFGS starting guess
    'UseParallel', false, ...
    'PlotFcn', @gaplotbestf, ...
    'NonlinearConstraintAlgorithm', 'auglag');       

% Run the Genetic Algorithm
tic
[x_opt_ga, fval_ga, exitflag_ga, output_ga] = ga(obj_fun_ga, nvars, [], [], [], [], lb_simp, ub_simp, nonlcon_fun_ga, options_ga);
time_ga = toc;
fprintf('GA Optimization finished in %.2f seconds.\n', time_ga);


%% =========================================================================
% PLOT: Optimized GA Geometry
% =========================================================================

% Reconstruct the parameter structure cleanly
params_ga_plot = update_blade_params(x_opt_ga, params_base, 'simplified');

disp(['GA Optimized thickness (t): ', num2str(x_opt_ga(1))])
disp(['GA Optimized Radius 4 (R4): ', num2str(x_opt_ga(2))])

% Generate geometry and plot
params_ga_plot.res = 1000;
[bx_ga, by_ga] = blade_structure(params_ga_plot);

% Compute properties and plot deformation/stress
struct_mesh_ga = material_properties([bx_ga; by_ga], params_ga_plot);
results_ga = solve_blade_deformation_progressive(struct_mesh_ga, params_ga_plot);
stress_data_ga = compute_stresses(struct_mesh_ga, params_ga_plot, results_ga);

plot_def_stress(results_ga, struct_mesh_ga, params_ga_plot, stress_data_ga, 'Simple geometry GA', save_dir, save_op);


%% =========================================================================
% Run Genetic Algorithm Full
% =========================================================================
disp('======================================================');
disp('--- Running GA Full ---');
clear ga_evaluator_cache


% We use the same bounds and initial guess
nvars = length(x0_full);

% Setup the wrapper
obj_fun_ga = @(x) ga_objective(x, params_base, 'full');
nonlcon_fun_ga = @(x) ga_nonlcon(x, params_base, 'full');

% Configure GA Options
options_ga = optimoptions('ga', ...
    'Display', 'iter', ...
    'PopulationSize', 60, ...    % Smaller population for quicker testing
    'MaxGenerations', 150, ...    % Max iterations
    'InitialPopulationMatrix', x0_full, ... % Seed it with our BFGS starting guess
    'UseParallel', false, ...
    'PlotFcn', @gaplotbestf, ...
    'NonlinearConstraintAlgorithm', 'auglag');

% Run the Genetic Algorithm
tic
[x_opt_ga, fval_ga, exitflag_ga, output_ga] = ga(obj_fun_ga, nvars, [], [], [], [], lb_full, ub_full, nonlcon_fun_ga, options_ga);
time_ga = toc;
fprintf('GA Optimization finished in %.2f seconds.\n', time_ga);


%% =========================================================================
% PLOT: Optimized GA Geometry FULL
% =========================================================================

% Reconstruct the parameter structure cleanly
params_ga_plot = update_blade_params(x_opt_ga, params_base, 'full');

% Generate geometry and plot
params_ga_plot.res = 1000;
[bx_ga, by_ga] = blade_structure(params_ga_plot);

% Compute properties and plot deformation/stress
struct_mesh_ga = material_properties([bx_ga; by_ga], params_ga_plot);
results_ga = solve_blade_deformation_progressive(struct_mesh_ga, params_ga_plot);
stress_data_ga = compute_stresses(struct_mesh_ga, params_ga_plot, results_ga);

plot_def_stress(results_ga, struct_mesh_ga, params_ga_plot, stress_data_ga, 'Full geometry GA', save_dir, save_op);

%% =========================================================================
% Run BFGS from GA Results
% =========================================================================

disp('======================================================');
disp('--- Running Full Geometry ---');
x0_h = x_opt_ga;
tic

% Create a handle that locks the mode to 'full'
eval_h = @(x) run_blade_physics(x, params_base, 'full');

[x_opt_h, hist_h] = augmented_lagrangian(eval_h, @blade_objective, @blade_constraints, x0_h, lb_full, ub_full);
time_hybrid = toc;
fprintf('h-BFGS Optimization finished in %.2f seconds.\n', time_hybrid);

%% =========================================================================
% PLOT: Hybrid initialization
% =========================================================================


% 1. Reconstruct the parameter structure cleanly using our new function
params_full_plot_h = update_blade_params(x_opt_h, params_base, 'full');

[bx_full, by_full] = blade_structure(params_full_plot_h);


% Compute properties and plot deformation/stress
struct_mesh_full = material_properties([bx_full; by_full], params_full_plot_h);
plot_blade_thickness(struct_mesh_full, 'Full geometry hybrid', save_dir, save_op);
results_full = solve_blade_deformation_progressive(struct_mesh_full, params_full_plot_h);
stress_data_full = compute_stresses(struct_mesh_full, params_full_plot_h, results_full);

plot_def_stress(results_full, struct_mesh_full, params_full_plot_h, stress_data_full, 'Full geometry hybrid', save_dir, save_op)


save('weight_280.mat')