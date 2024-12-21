clear;close all;clc;        %Clearing the workspace and any windows

window5 = load("rollingAvgData/1m5windowUncalib.mat");      %load data
window10 = load("rollingAvgData/1m10windowUncalib.mat");
window25 = load("rollingAvgData/1m25windowUncalib.mat");
window50 = load("rollingAvgData/1m50windowUncalib.mat");

figure;         %open the figure
hold on;

% Plot rolling averages
plot(window5.distanceTable.Time,window5.distanceTable.RollingAvg,'b','DisplayName','5-window');
plot(window10.distanceTable.Time,window10.distanceTable.RollingAvg,'g','DisplayName','10-window');
plot(window25.distanceTable.Time,window25.distanceTable.RollingAvg,'m','DisplayName','25-window');
plot(window50.distanceTable.Time,window50.distanceTable.RollingAvg,'r','DisplayName','50-window');

xlabel('Time [s]');         %axis labels
ylabel('Distance [m]');
legend('show');             %legend
grid on;                    %show grid lines

hold off;
