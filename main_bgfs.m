clc, clear, close all
% --- Main Script: Define and Plot Cheetah Blade ---
% High level parameters
params.H_req  = 0.80;       % Maximum height from ground to stump (m)

% Force parameters
params.F_mag = 1500; % [N]
params.F_angle = 270; % [°] 

% Material properties | these can be constant or vectors
a = 5;
b = 40;
r = a + (b-a).*rand(7,1);

params.t = [10, 10, 12, 15, 12, 10, 10]./1000; %r./1000;% [10, 10, 12, 15, 12, 10, 10]./1000; % [m] Thikness of each section input mm | DV
params.E = 170e9.*ones(1,7);         % Young's modulous, constant
%params.I = ones(1,7);         % Area moment of inertia, constant
params.w = 10.*ones(1,7)./100;         % [m] Section width, can be DV

% Geometric parameters | DV
params.L1 = 0.1;            % Stump connection
params.R2 = 0.1;            % Arch back
params.L3 = 0.1;            % Connect arches
params.R4 = 0.04;           % Arch forward
params.L5 = 0.07;           % Diagonal element
params.R6 = 0.05;           % Heel
params.L7 = 0.1;            % Sole



% c = 0.01;
% d = 0.7;
% g = c + (d-c).*rand(7,1);
% 
% params.L1 = g(1);            % Stump connection
% params.R2 = g(2);            % Arch back
% params.L3 = g(3);            % Connect arches
% params.R4 = g(4);           % Arch forward
% params.L5 = g(5);           % Diagonal element
% params.R6 = g(6);           % Heel
% params.L7 = g(7);            % Sole

params.theta2 = -70;        % Sweep angle 1
params.theta3 = 150;        % Sweep angle 2

% Run function
params.res = 1000; % number of elements per section
res = params.res;
[bx, by] = blade_structure(params);

% Plotting the prosthesis geometry preliminary
figure
%subplot(1, 3, 1);
hold on
for i = 0:6 % Replace with section lengths
    plot(bx(1+res*i:res*(i+1)), by(1+res*i:res*(i+1)), 'LineWidth', 4, DisplayName=['Section: ', num2str(i+1)]);
end
axis equal; grid on; 
title('Paralympic Sprinting Leg (Cheetah Blade) Model');
xlabel('x (m)'); ylabel('y (m)');
legend;
disp('Height: ' + string(max(by)))

% - Assign material properties - 

struct_mesh = material_properties([bx; by], params);

figure
%subplot(1, 3, 2);
scatter(struct_mesh.x, struct_mesh.y, 10000*struct_mesh.t, struct_mesh.t, "filled", MarkerEdgeColor="none")
colorbar;
axis equal; grid on; 
title('Paralympic Sprinting Leg (Cheetah Blade) thickness');
xlabel('x (m)'); ylabel('y (m)');


% - Define & Solve structural problem -
results = solve_blade_deformation_progressive(struct_mesh, params);
% - Visualize - 


figure
%subplot(1, 3, 3);
plot(results.x_orig, results.y_orig, "b:", 'LineWidth', 1.5, 'DisplayName', 'Original Shape');
hold on; 
plot(results.x_def, results.y_def, "r-", 'LineWidth', 2, 'DisplayName', 'Deformed Shape');

% Re-calculating idx_fixed to identify the "grounded" points
L_total = struct_mesh.s(end);
s_fixed_start = (L_total - params.L7) + (1.0 * params.L7); 
idx_fixed = find(struct_mesh.s >= s_fixed_start, 1, 'first');

locked_x = results.x_orig(idx_fixed:end);
locked_y = results.y_orig(idx_fixed:end);
scatter(locked_x, locked_y, 30, 'k', 'filled', 'MarkerFaceAlpha', 0.4, 'DisplayName', 'Locked Toe');

% Force Vector Arrow
Fx = params.F_mag * cosd(params.F_angle);
Fy = params.F_mag * sind(params.F_angle);

% Calculate a visual scale so the arrow doesn't dwarf the blade
arrow_scale = 0.05 / params.F_mag; 
quiver(results.x_def(1), results.y_def(1), Fx, Fy, arrow_scale, ...
    'Color', [0 .5 0], 'LineWidth', 2.5, 'MaxHeadSize', 2, 'DisplayName', 'Applied Load');


axis equal; grid minor; 
title(['Blade Deflection: F = ', num2str(params.F_mag), ' N at ', num2str(params.F_angle), '°']);
xlabel('x (m)'); ylabel('y (m)');
legend('Location', 'northwest');



% Compute stresses

stress_data = compute_stresses(struct_mesh, params, results);




%figure

scatter(results.x_def, results.y_def, 20, stress_data.sigma_max, "filled", MarkerEdgeColor="none")
axis equal; grid on; grid minor;
colorbar(location="eastoutside");



% Validation Deflection
P = params.F_mag;           % Force in N
L = 0.37;           % Length in m
w = params.w(1);           % Width in m
t = 0.01;           % Thickness in m
E = params.E(1);          % Young's Modulus in Pa (Assumed for Carbon Fiber)

% Moment of Inertia
I = (w * t^3) / 12;

% Analytical Solutions
delta_analytical = (P * L^3) / (3 * E * I);
U_analytical = (P * delta_analytical) / 2;

fprintf('Analytical Deflection: %.4f m\n', delta_analytical);
fprintf('Simulated (x) Deflection: %.4f m\n', (-results.x_orig(1)+results.x_def(1)));
fprintf('Simulated (y) Deflection: %.4f m\n', (-results.y_orig(1)+results.y_def(1)));
fprintf('Analytical Energy: %.4f J\n', U_analytical);
fprintf('Simulated Energy: %.4f J\n', results.energy);



% Base parameters (fixed values)
params_base = params;


% Base parameters
params_base.H_req = 0.80;


% ---------------------------------------------------------
% PHASE 1: Run the Simplified Model
% ---------------------------------------------------------
x0_simp = [0.015, 0.40, 0.15];
lb_simp = [0.005, 0.10, 0.05];
ub_simp = [0.080, 1.0, 0.25];



% Create a handle that locks the mode to 'simplified'
eval_simp = @(x) blade_evaluator(x, params_base, 'simplified');
tic
[x_opt_simp, hist_simp] = damped_bfgs(eval_simp, x0_simp, lb_simp, ub_simp);
toc


% =========================================================================
% PLOT: OPTIMIZED SIMPLIFIED GEOMETRY
% =========================================================================
disp('--- Plotting Optimized Simplified Geometry ---');

% 1. Reconstruct the parameter structure from the optimized variables
params_simp_plot = params_base;
params_simp_plot.t = x_opt_simp(1) * ones(1,7);
params_simp_plot.L1 = x_opt_simp(2);            
params_simp_plot.R4 = x_opt_simp(3);            
params_simp_plot.theta2 = -90;          

% "Turn off" the other sections
tiny = 1e-3;
params_simp_plot.L3 = tiny; params_simp_plot.R2 = 0.02; params_simp_plot.theta3 = 180;
params_simp_plot.L5 = tiny; params_simp_plot.R6 = tiny; params_simp_plot.L7 = tiny;

params_simp_plot.res = 1000;
[bx_simp, by_simp] = blade_structure(params_simp_plot);

figure('Name', 'Optimized Simplified Geometry');
plot(bx_simp, by_simp, 'k-', 'LineWidth', 5, 'DisplayName', 'Simplified Blade');
hold on;
yline(0.80, 'r--', 'Target Height (0.80m)', 'LineWidth', 2);
yline(0, 'b-', 'Ground', 'LineWidth', 2);
axis equal;
grid on; grid minor;
title('Optimized Simplified Blade Geometry');
xlabel('x (m)'); ylabel('y (m)');
legend('Location', 'best');



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