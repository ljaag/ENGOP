clc, clear, close all
%==========================================================================
% MAIN_SENSITIVITY
% Main script to set up and run the sensitivity analysis for the blade
% geometry. Toggles between 'simplified' and 'full' parameter spaces.
%==========================================================================

% --- 1. Base Parameters ---
params.H_req   = 0.80;       % Maximum height from ground to stump (m)
params.F_mag   = 2500;       % Applied Force [N]
params.F_angle = 260;        % Force Angle [°]

% Material & Geometric Setup (Base values)
params.t = [10, 10, 12, 15, 12, 10, 10] ./ 1000; % Thickness [m]
params.E = 170e9 .* ones(1,7);                   % Young's modulus [Pa]
params.w = 10 .* ones(1,7) ./ 100;               % Width [m]

params.L1 = 0.1;  params.R2 = 0.1;  params.L3 = 0.1;
params.R4 = 0.04; params.L5 = 0.07; params.R6 = 0.05;
params.L7 = 0.1;
params.theta2 = -70; params.theta3 = 150;
params.res = 500;

params_base = params;

% --- 2. Select Mode and Define Variables ---
% Change this to 'full' to analyze all 15 variables
mode = 'simplified';

if strcmpi(mode, 'simplified')
    % Nominal values (Update these with your actual optimal results if needed)
    x_nom = [0.015, 0.15];
    lb    = [0.005, 0.05];
    ub    = [0.020, 0.35];
   
    var_names = {'Thickness (t)', 'Radius 4 (R4)'};
   
elseif strcmpi(mode, 'full')
    % Nominal values for full mode (Update with your x_opt_full)
    t_nom = 0.015 * ones(1,7);
    L_nom = [0.1, 0.04, 0.1];
    R_nom = [0.05, 0.05, 0.05];
    theta_nom = [-70, 130];
   
    x_nom = [t_nom, L_nom, R_nom, theta_nom];
    lb    = [0.005 * ones(1,7), 0.02, 0.02, 0.02, 0.02, 0.02, 0.04, -120, 5];
    ub    = [0.080 * ones(1,7), 0.9,  0.9,  0.9,  0.9,  0.9,  0.9,  -5,   179.9];
   
    % Ensure these match the unpacking order in update_blade_params.m
    var_names = {'t1', 't2', 't3', 't4', 't5', 't6', 't7', ...
                 'L3', 'L5', 'L7', 'R2', 'R4', 'R6', 'theta2', 'theta3'};
else
    error('Invalid mode selected.');
end

% --- 3. Run Sensitivity Analysis ---
title_str = sprintf('Sensitivity %s', mode);
save_folder = fullfile(pwd, 'Output');
save_plot = true;

run_sensitivity_analysis(x_nom, lb, ub, params_base, mode, var_names, title_str, save_folder, save_plot);


