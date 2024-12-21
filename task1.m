clear;close all;clc;        %Clearing the workspace and any windows

distanceMin = 0.1;         %Measurement range
distanceMax = 2;

callibrationGradient = 0.99016;       %callibration gradient
callibrationFactor = 1/0.99016;       %callibration factor
callibrationOffset = 3.9611/1000;     %callibration offset converted back to mm 

debug = 0;                  %set to 1 for debug console values

frequency = 24;
period = 1/frequency;       %Specify measurement details  
duration = 10;
windowSize = 25;            %Window size for the rolling average applied to the data

totalMeasurements = frequency*duration; %number of measurements to be taken

distanceTable = table(NaN(totalMeasurements,1),NaN(totalMeasurements,1),NaN(totalMeasurements,1),NaN(totalMeasurements,1),'VariableNames',...
    {'Time','Distance','RollingAvg','LoopIterationTime'}); %Initialising table with timestamps prefilled


arduinoObj = arduino('COM3','Uno',"Libraries","Ultrasonic");    %Creating the arduino connection with the ultrasound library
ultrasonicObj = ultrasonic(arduinoObj,'D11','D12');             %Creating the sensor connection

figure; % Initialize the plot
hold on;
distPlot = plot(NaN,NaN,'b','DisplayName','Raw Data');          % empty plot for raw distance
ravgPlot = plot(NaN,NaN,'r','DisplayName','Rolling Average');   % empty plot for rolling average
legend('show');
xlabel('Time [s]');
ylabel('Distance [m]');


pause(1)  %calling pause first time outside main loop to prevent initialisation lag of 0.1s

tic     %starts timer
for i =1:totalMeasurements              %starts for loop for until every planned meaurement is taken

    targetStart = i*(period);

    pauseTime = targetStart - toc;      %how long the pause needs to be until that target time
    pause(pauseTime);                   %doing the pause time to reach targetTime

    timeBefore = toc;                               %time just before distance is measured
    currentDistance = callibrationFactor*readDistance(ultrasonicObj)-callibrationOffset;  %current distance measurement
    timeAfter = toc;                                %time after distance is measured

    if currentDistance >= distanceMin && currentDistance <= distanceMax     %writes the current distance if within the measurement range
        distanceTable.Distance(i) = currentDistance;
    else
        distanceTable.Distance(i) = NaN;                                    %writes not a number if outside range
    end
  
    distanceTable.Time(i) = timeAfter;                                %writes the time immediately after the measurement is made to the table

    if i >= windowSize                                                %prevents rolling average being calculated until sufficient data points known
        rollingAvg = mean(distanceTable.Distance(i-windowSize+1:i));  %calculates the rolling avg and writes it to the table
    else 
        rollingAvg = nan;
    end
    distanceTable.RollingAvg(i)= rollingAvg;

    set(distPlot,'XData',distanceTable.Time(1:i),'YData',distanceTable.Distance(1:i));      %update distance plot
    set(ravgPlot,'XData',distanceTable.Time(1:i),'YData',distanceTable.RollingAvg(1:i));    %update rolling average plot
    drawnow;
    

    if debug == 1
        disp(['Target Start: ',num2str(targetStart,'%5f'), ' Measurement start deviation: ', num2str(timeBefore-targetStart,'%5f'), ' Measurement duration: ',...
            num2str(timeAfter-timeBefore,'%5f'), ' End of loop:',num2str(toc, '%5f'), ' Distance: ',num2str(currentDistance, '%5f')]); %diagnostic display output to console
    end
    
end

