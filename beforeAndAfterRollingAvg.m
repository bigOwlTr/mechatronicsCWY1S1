%clear workspace and close figures
clear; close all; clc;

%load data
data = load("1mNoCalib.mat");


figure(1);
set(gcf, 'Position', [100, 100, 700, 700]);  %set figure size 
set(gca, 'FontSize', 24);
set(gca, 'GridLineStyle', '-', 'GridAlpha', 0.1, 'LineWidth', 2);
hold on;
plot(data.distanceTable.Time, data.distanceTable.Distance, 'k', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Distance (m)');
ylim([0.975 1.025])

hold off;

figure(2);
set(gcf, 'Position', [100, 100, 700, 700]);  %set figure size 
set(gca, 'FontSize', 24);
set(gca, 'GridLineStyle', '-', 'GridAlpha', 0.1, 'LineWidth', 2);
hold on;
plot(data.distanceTable.Time, data.distanceTable.RollingAvg, 'k', 'LineWidth', 2);

ylim([0.975 1.025])
xlabel('Time (s)');
ylabel('Distance (m)');
hold off;

