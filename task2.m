clear;close all;clc;        %Clearing the workspace and any windows

startValue = -10;           %start distance from centre
endValue = 10;              %end distance from centre

dataStruct = struct();      %initialse a struct to store data

%initialise plot with set size and location
figure('Position', [100, 100, 1500, 1200]);
hold on;

yyaxis left %plotting graph for left yaxis
ylim ([0, 1.5]);  %set left ylim
%left yaxis label
ylabel('Average Distance Recorded (m)', 'Color', 'b'); 
xlim ([-11,11])          %set the xlim for the graph
grid on;
set(gca, 'GridLineStyle', '-', 'GridAlpha', 0.1, 'LineWidth', 1.5);
set(gca, 'FontSize', 16);   %tick size 

x = 1:240;  %x values for all measurements
for i =startValue:endValue  %for each distance from centre
    if i < 0    %for the negative distances
        %create file/variable name with _ in place of -
        variableName = "cm_"+-1*i+"beamangle";
    else
        %create file/variable name
        variableName = "cm"+i+"beamangle";
    end
    
    %write the file to same variable in the struct
    dataStruct.(variableName) = load("C:\Users\colin\Documents\MATLAB" + ...
        "\mechatronicsCourseworkY1\beamAngleData/" + variableName);

    %write a mean for each variable averaging the distance
    dataStruct.(variableName).Average = ... 
    mean(dataStruct.(variableName).distanceTable.Distance);
    %fit linear model to the distance data
    lm = fitlm(x,dataStruct.(variableName).distanceTable.Distance);
    %write the se of the linear model to the struct
    dataStruct.(variableName).SE = lm.Coefficients.SE(2);
    %plot the distance averages with a blue triangle marker
    plot(i, dataStruct.(variableName).Average, '^','MarkerEdgeColor', ...
        'b','MarkerFaceColor','b','MarkerSize',7.5);
end

%set yaxis for plotting the right
yyaxis right
ylim ([-0.0005, 0.0005]);  %set right ylim
xlabel('Edge Position from Centre Line (cm)');       %xaxis label
%right yaxis label
ylabel('Standard Error (m)', 'Color', 'r');

for i =startValue:endValue  %for each distance from centre
    if i < 0    %for the negative distances
        %create file/variable name with _ in place of -
        variableName = "cm_"+-1*i+"beamangle";
    else
        %create file/variable name
        variableName = "cm"+i+"beamangle";
    end

    %plot the se with the right y axis as red circle markers
    plot(i, dataStruct.(variableName).SE, 'o','MarkerEdgeColor', ...
        'r','MarkerFaceColor','r','MarkerSize', 7.5);
end