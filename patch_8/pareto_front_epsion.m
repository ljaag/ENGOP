clc, clear, close all
%==========================================================================
% MAIN: Epsilon-Constraint Optimization (Pareto Front)
% Decouples Mass and Energy. Maximizes Energy while progressively
% restricting Mass.
%==========================================================================

% --- 1. High-level Parameters ---
params.H_req  = 0.80;        % Maximum height from ground to stump (m)
params.F_mag  = 1500;        % Applied Force [N]
params.F_angle = 260;        % Force Angle [°]

% Material & Geometric Setup (Base values)
params.t = [10, 10, 12, 15, 12, 10, 10]./1000; % Thickness [m]
params.E = 170e9 .* ones(1,7);                 % Young's modulus [Pa]
params.w = 10 .* ones(1,7) ./ 100;             % Width [m]

params.L1 = 0.1;  params.R2 = 0.1;  params.L3 = 0.1;
params.R4 = 0.04; params.L5 = 0.07; params.R6 = 0.05;
params.L7 = 0.1;
params.theta2 = -70; params.theta3 = 150;
params.res = 500;

params_base = params;

% --- 2. Optimization Setup (Simplified Mode) ---
% Design Variables: x = [thickness, R4]
x0_current = [0.015, 0.15]; % Initial guess for the very first run
lb_simp    = [0.005, 0.05];
ub_simp    = [0.020, 0.35];

% Define the physics handle
phys_simp = @(x) run_blade_physics(x, params_base, 'simplified');

% --- 3. Epsilon-Constraint Loop ---
global EPSILON_MASS;

% We will run 10 optimizations, dropping the mass limit from 2.0kg to 0.5kg
num_runs = 20;
mass_limits = linspace(2.0, 0.5, num_runs);

% Preallocate arrays for the Pareto Front
pareto_mass = zeros(1, num_runs);
pareto_energy = zeros(1, num_runs);
pareto_solutions = zeros(num_runs, length(x0_current));

disp('======================================================');
disp('--- Starting Epsilon-Constraint Pareto Generation ---');

for i = 1:num_runs
    EPSILON_MASS = mass_limits(i);
    fprintf('\n--- Run %d/%d: Max Mass Constraint = %.3f kg ---\n', i, num_runs, EPSILON_MASS);
   
    % Run the optimizer
    [x_opt, hist] = damped_bfgs(phys_simp, @blade_objective, @blade_constraints, x0_current, lb_simp, ub_simp);
   
    % Evaluate the final optimized design to log its true performance
    final_state = phys_simp(x_opt);
   
    % Store the results
    pareto_mass(i) = final_state.mass;
    pareto_energy(i) = final_state.energy;
    pareto_solutions(i, :) = x_opt;
   
    % WARM START: Use this optimum as the starting guess for the next
    % tighter mass constraint. This helps BFGS converge much faster!
    x0_current = x_opt;
end

disp('--- Pareto Generation Complete ---');

% --- 4. Plotting the Pareto Front ---
figure('Name', 'Pareto Front: Mass vs. Energy');
plot(pareto_mass, pareto_energy, '-bo', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
grid on; grid minor;
title('Pareto Front: Trade-off between Mass and Strain Energy');
xlabel('Mass (kg) [Minimize]');
ylabel('Strain Energy (J) [Maximize]');

% Highlight the extremes on the plot
hold on;
plot(pareto_mass(1), pareto_energy(1), 'g^', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'DisplayName', 'Heaviest/Most Energy');
plot(pareto_mass(end), pareto_energy(end), 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'DisplayName', 'Lightest/Least Energy');
legend('Location', 'best');

% --- 5. Optional: Compare the Extremes Visually ---
% Plotting the lightest valid blade geometry
lightest_params = update_blade_params(pareto_solutions(end, :), params_base, 'simplified');
[bx_L, by_L] = blade_structure(lightest_params);

% Plotting the heaviest valid blade geometry
heaviest_params = update_blade_params(pareto_solutions(1, :), params_base, 'simplified');
[bx_H, by_H] = blade_structure(heaviest_params);

figure('Name', 'Geometry Comparison');
plot(bx_H, by_H, 'g-', 'LineWidth', 4, 'DisplayName', sprintf('Heaviest (%.2f kg)', pareto_mass(1)));
hold on;
plot(bx_L, by_L, 'r-', 'LineWidth', 4, 'DisplayName', sprintf('Lightest (%.2f kg)', pareto_mass(end)));
yline(params.H_req, 'k--', 'Target Height', 'LineWidth', 1.5);
yline(0, 'k-', 'Ground', 'LineWidth', 1.5);
axis equal; grid on;
title('Epsilon-Constraint: Extreme Pareto Solutions');
xlabel('x (m)'); ylabel('y (m)');
legend('Location', 'best');
