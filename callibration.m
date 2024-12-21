clear;close all;clc;        %Clearing the workspace and any windows
hold on;

data = struct();        %makes a struct to store variables
averages = [1,20];              %array to store averages

for i = 1:20
    variableName = "mm"+i+"00";
    data.(variableName) = load("C:\Users\colin\Documents\MATLAB\mechatronicsCourseworkY1\callibrationData/"+i+"00");     %imports all the data to the struct
    avgDist = 1000*mean(data.(variableName).distanceTable.Distance);        %calculates avg distance for each distance table and converts to mm
    data.(variableName+"Avg") = avgDist;                        %writes the avg to the data struct
    averages(i) = avgDist;                                      %add the avg to the avg array
end

x = 100:100:2000;                       %Generate x values corresponding to each average
plot(x, x, 'r', 'LineWidth', 1.5);      %red line showing the true distance
plot(x, averages, '^', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');         % Plot as points
xlabel('True Distance (mm)');           %axis labels
ylabel('Measured Distance (mm)');
grid on;                                %draws grid on the graph
axis equal;
xlim([0 2050]);                         %axis limits
ylim([0 2050]);
xticks(0:250:2000);                     %forcing even axis labelling
yticks(0:250:2000); 

linearModel = fitlm(x,averages);        %creating a linear model from the data and the true measurements
disp("Linear model gradient: " + linearModel.Coefficients.Estimate(2) + ...
    "   Linear model intercept: " + linearModel.Coefficients.Estimate(1) + ...
    "   Linear model standard error (%): " + linearModel.Coefficients.SE(2)*100);   %displaying the coefficients of the linear model
hold off;
figure(2)
hold on;

x = 1:240;
for i = 1:20
    variableName = "mm"+i+"00";
    plot(x,data.(variableName).distanceTable.Distance,"LineWidth",1)
end
xlabel('Data Index'); 
ylabel('Measured Distance (mm)');
