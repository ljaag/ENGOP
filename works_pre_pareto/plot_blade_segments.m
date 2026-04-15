function plot_blade_segments(bx, by, res)
%==========================================================================
% PLOT_BLADE_SEGMENTS
% Plots the 7 individual segments of the original blade geometry based
% on the resolution per segment.
%==========================================================================
    figure;
    hold on;
   
    % Loop through the 7 segments (0 to 6)
    for i = 0:6
        plot(bx(1+res*i:res*(i+1)), by(1+res*i:res*(i+1)), ...
            'LineWidth', 4, 'DisplayName', ['Section: ', num2str(i+1)]);
    end
   
    axis equal; grid on;
    title('Paralympic Sprinting Leg (Cheetah Blade) Model');
    xlabel('x (m)'); ylabel('y (m)');
    legend;
end