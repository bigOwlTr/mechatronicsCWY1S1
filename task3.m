classdef task3 < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        RollingAverageEditField         matlab.ui.control.NumericEditField
        RollingAverageEditFieldLabel    matlab.ui.control.Label
        CurrentFrequencyEditField       matlab.ui.control.NumericEditField
        CurrentFrequencyEditFieldLabel  matlab.ui.control.Label
        StopButton                      matlab.ui.control.Button
        StartButton                     matlab.ui.control.Button
        TargetFrequencyEditField        matlab.ui.control.NumericEditField
        TargetFrequencyEditFieldLabel   matlab.ui.control.Label
        AlarmThresholdEditField         matlab.ui.control.NumericEditField
        AlarmThresholdEditFieldLabel    matlab.ui.control.Label
        CenterPanel                     matlab.ui.container.Panel
        RecordMeasurementButton         matlab.ui.control.Button
        ClearMeasurementButton          matlab.ui.control.Button
        SaveMeasurementButton           matlab.ui.control.Button
        RecordingsTable                 matlab.ui.control.Table
        UIAxes                          matlab.ui.control.UIAxes
        RightPanel                      matlab.ui.container.Panel
        Switch4                         matlab.ui.control.Switch
        Switch4Label                    matlab.ui.control.Label
        AlarmSwitch                     matlab.ui.control.Switch
        AlarmSwitchLabel                matlab.ui.control.Label
        Switch2                         matlab.ui.control.Switch
        Switch2Label                    matlab.ui.control.Label
        RollingAvgValueEditFieldLabel   matlab.ui.control.Label
        RollingAvgValueEditField        matlab.ui.control.NumericEditField
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
        MeasurementWorker;            %store the parallel measurement task
        ArduinoWorker;
        AlarmWorker;
        DataQueue;                  % queu for parallel communication
        MeasurementLoop;
        IsMeasuring = false;        %measurement status flag            
        MeasurementBuffer = [];     %creates the rolling buffer
        BufferSize = 0;
        RollingAverage  = 0;        %initialises the rolling avg as 0
        callibrationFactor = 1/0.99016;       %callibration factor
        callibrationOffset = 3.9611/1000;     %callibration offset converted back to mm 
        InputUpdateTimer            %timer to check for input changes
        CurrentFrequency = 0;      %store prev freq
        IsAlarm = false;
    end

    % Callbacks that handle component events
    methods (Access = private)
        function startMeasurements(app)
            try
                if app.IsMeasuring
                    disp('Measurements already running.');
                    return;
                end
        
                app.DataQueue = parallel.pool.DataQueue;
                afterEach(app.DataQueue, @(data)updatePlotCallback(app, data));
        
                frequency = app.TargetFrequencyEditField.Value;
                if frequency <= 0
                    uialert(app.UIFigure, 'Frequency must be greater than 0.', 'Invalid input');
                    return;
                end
        
                app.IsMeasuring = true;
                app.CurrentFrequency = frequency;
                disp(['Starting measurement loop with frequency: ', num2str(frequency)]);

        
                app.MeasurementLoop = parfeval(@app.measurementLoop, 0, app.DataQueue, frequency);
                %app.ArduinoWorker = parfeval(gcp, @arduinoWorker, 0, app.DataQueue);
                disp('Measurement task started.');
            catch exception
                app.IsMeasuring = false;
                uialert(app.UIFigure, ['Error: ', exception.message], 'Measurement Error');
            end
        end


        function stopMeasurements(app)      %function to stop measuring

            app.IsMeasuring = false;        %sets the ismeasuring flag to false

            if ~isempty(app.MeasurementLoop)    %cancel the parallel task if running
                cancel(app.MeasurementLoop);
                app.MeasurementLoop = [];
                disp('Measurement task stopped.');
            end
        end

    
        function updatePlotCallback(app, data)      %updates plot and output
            app.CurrentFrequencyEditField.Value = 1 / data(1);  %update freq

            if isempty(app.UIAxes.Children)
                % initialize the plot
                line = plot(app.UIAxes, 0, data(2), '-');
                app.UIAxes.XLim = [0 5*app.CurrentFrequency]; 
                app.UIAxes.YLimMode = 'auto';
                app.UIAxes.XLimMode = 'manual'; 
            else
                %update existing plot
                line = app.UIAxes.Children(1);
                newX = line.XData(end) + 1; 
                line.XData = [line.XData newX];
                line.YData = [line.YData data(2)]; 
        
                    %x axis so that it scrolls
                if newX > app.UIAxes.XLim(2)
                    app.UIAxes.XLim = [newX - 5*app.CurrentFrequency, newX]; %scroll so that it takes 5 sec to cross window
                end
        
                app.UIAxes.YLimMode = 'auto';
            end
        
            %update the rolling average
            app.updateBuffer(data(2));
        end


        function updateBuffer(app, newReading)     %updates the rolling buffer
             app.MeasurementBuffer = [app.MeasurementBuffer, newReading];   %add current reading to buffer
             app.BufferSize = app.RollingAverageEditField.Value;
             if length(app.MeasurementBuffer) > app.BufferSize
                 app.MeasurementBuffer = app.MeasurementBuffer(length(app.MeasurementBuffer)-app.BufferSize+1:end);      %reduce buffer to desired size
             end
             app.RollingAverage = mean(app.MeasurementBuffer);
             app.RollingAvgValueEditField.Value = app.RollingAverage;
         end

        %the parallel measurement loop
        function measurementLoop(~, dataQueue, frequency )
             try
                % Arduino and sensor setup

                arduinoObj = arduino('COM3', 'Uno', 'Libraries', 'Ultrasonic');
                ultrasonicObj = ultrasonic(arduinoObj, 'D11', 'D12');
                disp('Measurement loop started');
            catch exception
                disp(['Error initializing Arduino: ', exception.message]);
                return; % Exit the loop if initialization fails
            end
            period = 1 / frequency;  
            timerStart = tic;    %start the timer

            try
                while true
                    elapsedTime = toc(timerStart);


                    if elapsedTime >= period
                        timerStart = tic;

                        try
                            currentDistance = readDistance(ultrasonicObj); %measurement
                        catch exception
                            disp(['Error reading distance: ', exception.message]);
                            currentDistance = NaN; %nan for failed measurements
                        end

                        %send data
                        if currentDistance >=0.02 && currentDistance <= 2
                            send(dataQueue, [elapsedTime, currentDistance]);
                        else 
                            currentDistance = NaN;
                            send(dataQueue, [elapsedTime, currentDistance]);
                        end
                    else
                        pause(0.001); % Prevent busy waiting
                    end
                end
            catch exception
                disp(['Error in measurement loop: ', exception.message]);
            end

            % Cleanup
            try
                delete(arduinoObj);
            catch
                disp('Failed to delete Arduino object.');
            end
        end

        %function alarmLoop(app)
        % 
        %     while app.IsAlarm
        % 
        %         alarmThreshold = app.AlarmThresholdEditField.Value;
        %         if app.RollingAverage <= alarmThreshold
        % 
        %             alarmMaxRatio = alarmThreshold/0.02;
        %             alarmRatio = alarmThreshold/app.RollingAverage;
        %             alarmFactor = alarmRatio/alarmMaxRatio;
        %             potentiometerVoltage = readVoltage(a, 'A3');
        %             voltageFraction = potentiometerVoltage/5;
        % 
        %             maxFreq = 100*voltageFraction;
        %             currentFreq = maxFreq*alarmFactor;
        %             currentPeriod = 1/currentFreq;
        % 
        %             writeDigitalPin(app.arduinoObj, 'D13', 1)
        %             pause(currentPeriod/2)
        %             writeDigitalPin(app.arduinoObj, 'D13', 0)
        %             pause(currentPeriod/2)
        % 
        % 
        %         end
        %     end
        % 
        % 
        % end



        % 
        % function measurementWorker(~, dataQueue, frequency) %measurement worker
        %     disp('Measurement worker started.')
        %     period = 1/frequency;
        % 
        %     try 
        %         while true 
        %             elapsedTime = toc(timerStart);
        % 
        %             if elapsedTime >= period
        %                 timerStart = tic;
        %                 send(dataQueue, struct('action', 'measure'));
        % 
        %                 response = poll(dataQueue, 1);
        %                 if isfield(response, 'type') && strcmp(response.type, 'measurement')
        %                     currentDistance = response.distance;
        % 
        %                     if currentDistance >= 0.02 && currentDistance <= 2
        %                         send(dataQueue, [elapsedTime, currentDistance]);
        %                     else
        %                         send(dataQueue, [elapsedTime, NaN]);
        %                     end
        %                 end
        %             else 
        %                 pause(0.001);
        %             end
        %         end
        %     catch exception
        %         disp(['Error in measurement worker: ', exception.message])
        %     end
        % end
        % 
        % 
        % function alarmWorker(app, dataQueue)    %alarm worker
        %      while app.IsAlarm      %while alarm is true
        %         disp('Alarm worker has started.')
        %         send(dataQueue, struct('action', 'readVoltage'));
        %         response = poll(dataQueue, 1); %wait for voltage
        % 
        %         if isfield(response, 'type') && strcmp(response.type, 'voltage')
        %             potentiometerVoltage = response.value;  %if voltage recieved turn it into voltage fraction
        %             voltageFraction = potentiometerVoltage / 5;
        % 
        %             alarmThreshold = app.AlarmThresholdEditField.Value;
        %             if app.RollingAverage <= alarmThreshold
        %                 alarmMaxRatio = alarmThreshold / 0.02;
        %                 alarmRatio = alarmThreshold / app.RollingAverage;
        %                 alarmFactor = alarmRatio / alarmMaxRatio;
        % 
        %                 maxFreq = 25 * voltageFraction;
        %                 currentFreq = maxFreq * alarmFactor;
        %                 currentPeriod = 1 / currentFreq;
        % 
        %                 send(dataQueue, struct('action', 'led', 'state', 1));
        %                 pause(currentPeriod / 2);
        %                 send(dataQueue, struct('action', 'led', 'state', 0));
        %                 pause(currentPeriod / 2);
        %             end
        %         end
        %     end
        % end
        % 
        % 
        % function arduinoWorker(~, dataQueue)    %lightweight worker that controls the arduino
        %     try
        %         arduinoObj = arduino('COM3', 'Uno', 'Libraries', 'Ultrasonic');     %initialise arduino and ultrasoic obj
        %         ultrasonicObj = ultrasonic(arduinoObj, 'D11', 'D12');
        %         disp('Arduino Worker Started');
        %     catch exception
        %         disp(['Error initialising arduino: ', exception.message])
        %     end
        % 
        %     ledState = 0;   %set led state to off
        % 
        %     try
        %         while true
        %             if dataQueue.NumMessages > 0    %check that there are messages to the worker
        %                 command = poll(dataQueue, 1);
        %                 if isfield(command, 'action')   %if the command is an action
        %                     switch command.action
        %                         case 'measure'  %if measure command
        %                             try
        %                                 currentDistance = readDistance(ultrasonicObj);      %measure current distance
        %                                 send(dataQueue, struct('type', 'measurement', 'distance', currentDistance));    %write to dataqueue
        %                             catch
        %                                 send(dataQueue, struct('type', 'measurement', 'distance', NaN));                %write to dataqueue
        %                             end
        % 
        %                         case 'led'              %led command
        %                             ledState = command.state;
        %                             writeDigitalPin(arduinoObj,'D13',ledState);         %set led to on or off depending on command state
        % 
        %                         case 'readVoltage'          %read voltage command
        %                             voltage = readVoltage(arduinoObj, 'A3');
        %                             send(dataQueue, struct('type', 'voltage', 'value', voltage));    %write to dataqueue
        % 
        %                         otherwise 
        %                             disp('Unknown function')
        %                     end
        %                 end
        %                 pause(0.001);  %prevent cpu running full throttle waiting
        %             end
        %         end
        %     catch exception
        %         disp(['Error in Arduino worker: ', exception.message]);
        %     end
        %     try
        %         delete(arduinoObj);
        %     catch exception
        %         disp('Failed to delete Arduino obkect.');
        %     end
        % end


        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, ~)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {480, 480, 480};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {480, 480};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {220, '1x', 220};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

    % Component initialization
    methods (Access = private)

            % Callback for StartButton
            function StartButtonPushed(app, ~)
                app.startMeasurements();  % Starts the measurement process
            end

            % Callback for StopButton
            function StopButtonPushed(app, ~)
                app.stopMeasurements();  % Stops the measurement process
            end

            % Callback for RecordMeasurementButton
            function RecordMeasurementButtonPushed(app, ~)
                currentMeasurement = app.RollingAverage;
                if ~isnan(currentMeasurement)
                    currentTime = datetime('now');%get current datestamp
                    currentTimeStr = datestr(currentTime, 'yyyy-mm-dd HH:MM:SS');  %convert to a string
                
                    newRow = {currentTimeStr, currentMeasurement};  %new row to add

                    app.RecordingsTable.Data = [app.RecordingsTable.Data; newRow];  %append to existing table
                else
                    uialert(app.UIFigure, 'Measurement is invalid (NaN).', 'Recording Error');
                end
            end

            % Callback for ClearMeasurementButton
            function ClearMeasurementButtonPushed(app, ~)
                app.RecordingsTable.Data = {};       
            end

            %callback for SaveMeasurementButton
            function SaveMeasurementButtonPushed(app, ~)
                tableData = app.RecordingsTable.Data;
                if ~isempty(tableData)
       
                    [fileName, filePath] = uiputfile('*.csv', 'Save Table as CSV');
                    fullFilePath = [filePath, fileName];
                    if isequal(fileName, 0)
                        return;
                    else
                        try
                            tableData(:, 1) = cellfun(@string, tableData(:, 1), 'UniformOutput', false);  %timestamps are string
                            tableData(:, 2) = cellfun(@double, tableData(:, 2), 'UniformOutput', false);  %distances are numeric
                            
                           %create table
                            T = cell2table(tableData, 'VariableNames', {'Timestamp', 'Distance(m)'});
                            
                            % write table
                            writetable(T, fullFilePath);
                            
                            %show success message
                            uialert(app.UIFigure, 'Table data saved successfully!', 'Save Complete');
                        catch ME
                            %error message
                            uialert(app.UIFigure, ['Failed to save file: ', ME.message], 'Save Error');
                        end
                    end
                else
                    %handles if table is empty
                    uialert(app.UIFigure, 'No data to save. The table is empty.', 'Save Error');
                end
            end
        
            function AlarmSwitchValueChanged(app, ~)
                app.IsAlarm = app.AlarmSwitch.Value;
                if app.IsAlarm
                    app.AlarmWorker = parfeval(gcp, @alarmWorker, 0, dataQueue);
                else
                    app.AlarmWorker = [];
                end   
            end

   
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [50 50 1000 500];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {220, '1x', 220};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.LeftPanel);
            app.GridLayout2.ColumnWidth = {'fit', 'fit'};
            app.GridLayout2.RowHeight = {'1x', 22.03, '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', 'fit'};

            % Create TargetFrequencyEditFieldLabel
            app.TargetFrequencyEditFieldLabel = uilabel(app.GridLayout2);
            app.TargetFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.TargetFrequencyEditFieldLabel.Layout.Row = 3;
            app.TargetFrequencyEditFieldLabel.Layout.Column = 1;
            app.TargetFrequencyEditFieldLabel.Text = 'Target Frequency';

            % Create TargetFrequencyEditField
            app.TargetFrequencyEditField = uieditfield(app.GridLayout2, 'numeric');
            app.TargetFrequencyEditField.Layout.Row = 3;
            app.TargetFrequencyEditField.Layout.Column = 2;
            app.TargetFrequencyEditField.Value = 10;

            % Create StartButton
            app.StartButton = uibutton(app.GridLayout2, 'push');
            app.StartButton.Layout.Row = 1;
            app.StartButton.Layout.Column = 1;
            app.StartButton.Text = 'Start';
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout2, 'push');
            app.StopButton.Layout.Row = 1;
            app.StopButton.Layout.Column = 2;
            app.StopButton.Text = 'Stop';
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);

            % Create CurrentFrequencyEditFieldLabel
            app.CurrentFrequencyEditFieldLabel = uilabel(app.GridLayout2);
            app.CurrentFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.CurrentFrequencyEditFieldLabel.Layout.Row = 4;
            app.CurrentFrequencyEditFieldLabel.Layout.Column = 1;
            app.CurrentFrequencyEditFieldLabel.Text = 'Current Frequency';

            % Create CurrentFrequencyEditField
            app.CurrentFrequencyEditField = uieditfield(app.GridLayout2, 'numeric');
            app.CurrentFrequencyEditField.Editable = 'off';
            app.CurrentFrequencyEditField.Layout.Row = 4;
            app.CurrentFrequencyEditField.Layout.Column = 2;

            % Create RollingAverageEditFieldLabel
            app.RollingAverageEditFieldLabel = uilabel(app.GridLayout2);
            app.RollingAverageEditFieldLabel.HorizontalAlignment = 'right';
            app.RollingAverageEditFieldLabel.Layout.Row = 5;
            app.RollingAverageEditFieldLabel.Layout.Column = 1;
            app.RollingAverageEditFieldLabel.Text = 'Rolling Avg Window ';

            % Create RollingAverageEditField
            app.RollingAverageEditField = uieditfield(app.GridLayout2, 'numeric');
            app.RollingAverageEditField.Layout.Row = 5;
            app.RollingAverageEditField.Layout.Column = 2;
            app.RollingAverageEditField.Value = 10;

            % Create RollingAvgValueEditFieldLabel
            app.RollingAvgValueEditFieldLabel = uilabel(app.GridLayout2);
            app.RollingAvgValueEditFieldLabel.HorizontalAlignment = 'right';
            app.RollingAvgValueEditFieldLabel.Layout.Row = 6;
            app.RollingAvgValueEditFieldLabel.Layout.Column = 1;
            app.RollingAvgValueEditFieldLabel.Text = 'Rolling Avg';


            % Create RollingAvgValueEditField
            app.RollingAvgValueEditField = uieditfield(app.GridLayout2, 'numeric');
            app.RollingAvgValueEditField.Editable = 'off';
            app.RollingAvgValueEditField.Layout.Row = 6;
            app.RollingAvgValueEditField.Layout.Column = 2;

             % Create AlarmThresholdEditFieldLabel
            app.AlarmThresholdEditFieldLabel = uilabel(app.GridLayout2);
            app.AlarmThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.AlarmThresholdEditFieldLabel.Layout.Row = 7;
            app.AlarmThresholdEditFieldLabel.Layout.Column = 1;
            app.AlarmThresholdEditFieldLabel.Text = 'Alarm Threshold';


            % Create AlarmThresholdEditField
            app.AlarmThresholdEditField = uieditfield(app.GridLayout2, 'numeric');
            app.AlarmThresholdEditField.Layout.Row = 7;
            app.AlarmThresholdEditField.Layout.Column = 2;

            % Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.CenterPanel);
            title(app.UIAxes, 'Measured Distance')
            xlabel(app.UIAxes, 'Recording Index')
            ylabel(app.UIAxes, 'Distance (m)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [5 5 540 300];
            

            % Create RecordingsTable
            app.RecordingsTable = uitable(app.CenterPanel);
            app.RecordingsTable.Position = [155 315 390 175];
            app.RecordingsTable.ColumnName = {'Timestamp', 'Distance'};
            app.RecordingsTable.ColumnEditable = [false false];

            % Create RecordMeasurementButton
            app.RecordMeasurementButton = uibutton(app.CenterPanel, 'push');
            app.RecordMeasurementButton.Position = [15 460 125 30];
            app.RecordMeasurementButton.Text = 'Record Measurement';
            app.RecordMeasurementButton.ButtonPushedFcn = createCallbackFcn(app, @RecordMeasurementButtonPushed, true);

             % Create ClearMeasurementButton
            app.ClearMeasurementButton = uibutton(app.CenterPanel, 'push');
            app.ClearMeasurementButton.Position = [15 415 125 30];
            app.ClearMeasurementButton.Text = 'Clear Measurements';
            app.ClearMeasurementButton.ButtonPushedFcn = createCallbackFcn(app, @ClearMeasurementButtonPushed, true);

              % Create SaveMeasurementButton
            app.SaveMeasurementButton = uibutton(app.CenterPanel, 'push');
            app.SaveMeasurementButton.Position = [15 370 125 30];
            app.SaveMeasurementButton.Text = 'Save Measurements';
            app.SaveMeasurementButton.ButtonPushedFcn = createCallbackFcn(app, @SaveMeasurementButtonPushed, true);


            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create Switch2Label
            app.Switch2Label = uilabel(app.RightPanel);
            app.Switch2Label.HorizontalAlignment = 'center';
            app.Switch2Label.Position = [132 377 47 22];
            app.Switch2Label.Text = 'Switch2';

            % Create Switch2
            app.Switch2 = uiswitch(app.RightPanel, 'slider');
            app.Switch2.Position = [132 414 45 20];

            % Create AlarmSwitchLabel
            app.AlarmSwitchLabel = uilabel(app.RightPanel);
            app.AlarmSwitchLabel.HorizontalAlignment = 'center';
            app.AlarmSwitchLabel.Position = [36 378 36 22];
            app.AlarmSwitchLabel.Text = 'Alarm';

            % Create AlarmSwitch
            app.AlarmSwitch = uiswitch(app.RightPanel, 'slider');
            app.AlarmSwitch.Position = [30 415 45 20];
            app.AlarmSwitch.ValueChangedFcn = createCallbackFcn(app, @AlarmSwitchValueChanged, true);

            % Create Switch4Label
            app.Switch4Label = uilabel(app.RightPanel);
            app.Switch4Label.HorizontalAlignment = 'center';
            app.Switch4Label.Position = [29 282 47 22];
            app.Switch4Label.Text = 'Switch4';

            % Create Switch4
            app.Switch4 = uiswitch(app.RightPanel, 'slider');
            app.Switch4.Position = [29 319 45 20];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';

        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = task3

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
             

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            app.stopMeasurements();
            % Delete UIFigure when app is deleted

            
            delete(app.UIFigure)
        end
    end
end