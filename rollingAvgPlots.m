%clear workspace and close figures
clear; close all; clc;

%load data
window5 = load("rollingAvgData/1m5windowUncalib.mat");
window10 = load("rollingAvgData/1m10windowUncalib.mat");
window25 = load("rollingAvgData/1m25windowUncalib.mat");
window50 = load("rollingAvgData/1m50windowUncalib.mat");

%create figure with specified size
figure('Units', 'inches', 'Position', [0, 0, 6, 4]);

%set font size
set(gca, 'FontSize', 12);
set(gca, 'GridLineStyle', '-', 'GridAlpha', 0.1, 'LineWidth', 1);

%plot rolling averages
hold on;
plot(window5.distanceTable.Time, window5.distanceTable.RollingAvg, 'b', 'LineWidth', 1, 'DisplayName', '5-window');
plot(window10.distanceTable.Time, window10.distanceTable.RollingAvg, 'g', 'LineWidth', 1, 'DisplayName', '10-window');
plot(window25.distanceTable.Time, window25.distanceTable.RollingAvg, 'm', 'LineWidth', 1, 'DisplayName', '25-window');
plot(window50.distanceTable.Time, window50.distanceTable.RollingAvg, 'r', 'LineWidth', 1, 'DisplayName', '50-window');
hold off;

%label axes
xlabel('Time (s)');
ylabel('Distance (m)');

%add legend
legend('show');


