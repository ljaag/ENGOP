function plot_blade_thickness(struct_mesh)
%==========================================================================
% PLOT_BLADE_THICKNESS
% Visualizes the thickness distribution along the blade using a scatter
% plot where the size and color of the points depend on the thickness 't'.
%==========================================================================
    figure;
   
    % Sizing factor 10000 ensures the points are visible on the plot scale
    scatter(struct_mesh.x, struct_mesh.y, 10000*struct_mesh.t, struct_mesh.t, "filled", "MarkerEdgeColor", "none");
    colorbar;
   
    axis equal; grid on;
    title('Paralympic Sprinting Leg (Cheetah Blade) Thickness');
    xlabel('x (m)'); ylabel('y (m)');
end