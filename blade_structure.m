function [totalX, totalY] = blade_structure(params)
%==========================================================================
% Generates a tangentially continuous geometry for a sprinting prosthesis.
%
%   This function constructs the (x,y) coordinates of a multi-segment 
%   "Cheetah Blade" using  tangential inheritance. It ensures that each 
%   segment  connects to the previous one without gaps or kinks.
%   This is done by constructing each segment starting from the end of the
%   previous one.
%
%   INPUTS:
%       sections : Struct array (1xN) defining the blade segments.
%                  Required fields:
%                  .type - String ('line' or 'arc')
%                  .val1 - Scalar: Length (for 'line') or Radius (for 'arc')
%                  .val2 - Scalar: Sweep angle in radians (for 'arc' only)
%
%   OUTPUTS:
%       totalX   : Vector: Concatenated X-coordinates of the blade profile.
%       totalY   : Vector: Concatenated Y-coordinates of the blade profile.
%==========================================================================
    
    % Initialization
    currentPos = [0, 0]; 
    currentAngle = -pi/2; 
    totalX = []; totalY = [];

    sections = param2section(params);
    res = params.res;
    

    for i = 1:length(sections) % String comparison
        type = char(sections(i).type); % Needs char for strcmpi()
        v1 = sections(i).val1; % Radius or length
        v2 = sections(i).val2; % Sweep angle


        if strcmpi(type, 'line')
            % v1 is the length, use currentAngle for direction
            x = linspace(currentPos(1), currentPos(1) + v1*cos(currentAngle), res);
            y = linspace(currentPos(2), currentPos(2) + v1*sin(currentAngle), res);
            
        else
            % Arc center is always normal to starting point
            center = currentPos + v1 * [cos(currentAngle + pi/2), sin(currentAngle + pi/2)];
            % Theta is the arc angle sweep
            theta = linspace(currentAngle - pi/2, currentAngle - pi/2 + v2, res);
            x = center(1) + v1 * cos(theta);
            y = center(2) + v1 * sin(theta);
            % Update the heading for the next segment
            currentAngle = currentAngle + v2;
        end
        
        totalX = [totalX, x]; %#ok<AGROW>
        totalY = [totalY, y]; %#ok<AGROW>
        currentPos = [x(end), y(end)];
    end
    % Shift everything up so that the ground is y = 0
    height_dis = min(totalY);
    totalY = totalY - height_dis;
    
end

%% Helper functions

% Construct structure
function sections = param2section(params)
%==========================================================================
% Transform the parameters into a sectional structure for easier
% implementation.
%
%   TODO
%     - Parametrize for arbitrary geometry sets
%
%   INPUTS:
%       params : Struct array (1xN) defining the blade segments.
%                  Required fields:
%                  .type - String ('line' or 'arc')
%                  .val1 - Scalar: Length (for 'line') or Radius (for 'arc')
%                  .val2 - Scalar: Sweep angle in radians (for 'arc' only)
%
%   OUTPUTS:
%       sections : Struct array (1xn) with the geometric properties of each
%       section
%==========================================================================
    % Initialization
    
    params.theta5 = 90 - params.theta2 - params.theta3 +1e-7;
    %theta5 = 0.0000001; 
    sectionData = {
        'line', params.L1,  -pi/2;                    % Stump connection
        'arc',  -params.R2,  deg2rad(params.theta2);  % Arch back 
        'line', params.L3,  0;                        % Arch connection
        'arc',  params.R4, deg2rad(params.theta3);    % Arch forward
        'line', params.L5,  0;                        % Downwards diagonal
        'arc',  params.R6,  deg2rad(params.theta5);   % Heel
        'line', params.L7,  0                         % Sole
    };
    
    % Convert the cell data into the structured format the function needs
    sections = struct('type', {}, 'val1', {}, 'val2', {});
    for i = 1:size(sectionData, 1)
        sections(i).type = sectionData{i, 1};
        sections(i).val1 = sectionData{i, 2};
        sections(i).val2 = sectionData{i, 3};
    end


    
end

