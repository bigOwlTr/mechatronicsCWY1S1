% Clear workspace and close figures
clear; close all; clc;

% Load data
window5 = load("rollingAvgData/1m5windowUncalib.mat");
window10 = load("rollingAvgData/1m10windowUncalib.mat");
window25 = load("rollingAvgData/1m25windowUncalib.mat");
window50 = load("rollingAvgData/1m50windowUncalib.mat");

% Create figure with specified size
figure('Units', 'inches', 'Position', [0, 0, 6, 4]);

% Set font size for axes
set(gca, 'FontSize', 12);

% Plot rolling averages with increased line width
hold on;
plot(window5.distanceTable.Time, window5.distanceTable.RollingAvg, 'b', 'LineWidth', 1.5, 'DisplayName', '5-window');
plot(window10.distanceTable.Time, window10.distanceTable.RollingAvg, 'g', 'LineWidth', 1.5, 'DisplayName', '10-window');
plot(window25.distanceTable.Time, window25.distanceTable.RollingAvg, 'm', 'LineWidth', 1.5, 'DisplayName', '25-window');
plot(window50.distanceTable.Time, window50.distanceTable.RollingAvg, 'r', 'LineWidth', 1.5, 'DisplayName', '50-window');
hold off;

% Label axes with increased font size
xlabel('Time [s]', 'FontSize', 12);
ylabel('Distance [m]', 'FontSize', 12);

% Add legend with increased font size
legend('show', 'FontSize', 12);


