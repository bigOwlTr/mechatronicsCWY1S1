clear;close all;clc;        %Clearing the workspace and any windows

startValue = -10;
endValue = 10;


dataStruct = struct();



figure('Position', [100, 100, 1800, 1200]);
hold on;

yyaxis left

x = 1:240;
for i =startValue:endValue
    if i < 0
        variableName = "cm_"+-1*i+"beamangle";
    else
        variableName = "cm"+i+"beamangle";
    end
    dataStruct.(variableName) = load("C:\Users\colin\Documents\MATLAB\mechatronicsCourseworkY1\beamAngleData/" + variableName);

    dataStruct.(variableName).Average = mean(dataStruct.(variableName).distanceTable.Distance);
    lm = fitlm(x,dataStruct.(variableName).distanceTable.Distance);
    dataStruct.(variableName).SE = lm.Coefficients.SE(2);
    plot(i, dataStruct.(variableName).Average, '^','MarkerEdgeColor', 'b','MarkerFaceColor','b');
end


yyaxis right
for i = startValue:endValue
     if i < 0
        variableName = "cm_" + num2str(-1 * i) + "beamangle";  % For negative i
    else
        variableName = "cm" + num2str(i) + "beamangle";  % For positive i
    end
    plot(i, dataStruct.(variableName).SE, 'o','MarkerEdgeColor', 'r','MarkerFaceColor','r');
end

xlim ([-11,11])

yyaxis left
ylim ([0, 1.5]);  % Start the left y-axis (Average Distance) at 0

yyaxis right
ylim ([-0.001, 0.001]);   % Zoom in on the right y-axis (SE)

xlabel('Edge Position');
yyaxis left
ylabel('Average Distance measured (m)', 'Color', 'b');  % Left y-axis label
yyaxis right
ylabel('Standard Error (SE)', 'Color', 'r');    % Right y-axis label
grid on;