%%% Main code
%
% Inputs: -raw accelerometer data files from the ACTIVPAL
%         -logs of the times when the accelerometer was put on and off
%
% Outputs: file describing the times of wear, sedentary, upright, moving,
%          standing, light physical activity (LPA), and moderate-vigorous
%          physical activity (MVPA) for each participant
%
%
% Separating days after midnight
% Rejecting days with less than 10 hours of data
% Output only hour min

clc
clear variables


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User Specific Parameters 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

shortest_day = duration(10,0,0); %(h,m,s) a day with less than 10 hours is not valid
MET_LPA = 1.4; % lower MET limit for Light Physical Activity (LPA)
MET_MVPA = 3; % lower MET limit for Moderate Vigorous Physical Activity (MVPA), also upper MET limit for LPA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% End of Parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




warning('off','MATLAB:table:ModifiedAndSavedVarnames')
another_participant = true;

while another_participant
    % Participant id
    ID = input('Participant id? (type below and press [Enter])\n');
    fprintf('Reading the input files.\n')
    
    % Import the data into a table
    data = readtable(['..\data\ID', num2str(ID), '_data.xlsx']);
    % Import the log into a table
    log = readtable(['..\logs\ID', num2str(ID), '_log.xlsx']);


    %%% Remove the non-wear time
    data(data.NonwearTime_s_ > 0.0001,:) = []; % not zero to account for numerical precision
    
    data(data.time < log.TimeOn(1),:) = []; % remove time before study start
    for log_row = 1:length(log.TimeOn)-1
        off = log.TimeOff(log_row);
        on = log.TimeOn(log_row + 1);
        data((data.time > off) & (data.time < on),:) = []; % remove off time during study
    end
    data(data.time > log.TimeOff(end),:) = []; % remove time after study end
    
    
    %%% Remove days too short
    log.duration = log.TimeOff - log.TimeOn;
    days_start_end_data_rows = ones(1,2); % list of the data rows corresponding to the start and end of each day
    
    day_id = 1;
    log_row = 1;
    wear_time = duration(0,0,0);
    Wear_Time = duration({});
    while log_row <= length(log.TimeOn)
        
        [y,m,d] = ymd(log.TimeOn(log_row));
        while log_row <= length(log.TimeOn) && day(log.TimeOff(log_row)) == d % same day
            wear_time = wear_time + log.duration(log_row);
            log_row = log_row + 1;
        end
        if log_row > length(log.TimeOn) || day(log.TimeOn(log_row)) ~= d
            log_row = log_row - 1;
        elseif day(log.TimeOn(log_row)) == d && day(log.TimeOff(log_row)) ~= d % day goes past midnight
            wear_time = wear_time + datetime(y,m,d+1,0,0,0) - log.TimeOn(log_row);
        end
        
        day_end_data_row = find(data.time <= datetime(y,m,d+1,0,0,0), 1, 'last');
        if wear_time < shortest_day % remove that day
            data(days_start_end_data_rows(day_id,1):day_end_data_row, :) = [];
            day_id = day_id - 1;
        else % keep that day
            days_start_end_data_rows(end,2) = day_end_data_row;
            days_start_end_data_rows(end+1,1) = day_end_data_row + 1;
            Wear_Time(end+1) = wear_time; % store daily wear time
        end
        day_id = day_id + 1;
        
        % add the time past midnight to the day length of the next day
        wear_time = (day(log.TimeOff(log_row)) > d)*( log.TimeOff(log_row) - datetime(y,m,d+1,0,0,0));
        log_row = log_row + 1;
    end
    days_start_end_data_rows(end,:) = [];
    nb_days = length(days_start_end_data_rows(:,1));
    data(days_start_end_data_rows(end,2)+1:end,:) = [];
   
    % Launch an error when the log is longer than the data file
    nb_days_in_data = ceil(days(data.time(end) - data.time(1)));
    if nb_days_in_data < nb_days
        error('There are %i days in the log file but only %i days in the data file.\nThe log must be adapted to the data.\n', nb_days, nb_days_in_data)
    end
    
    
    date = cell(1,nb_days); % date string mm/dd/yyyy
    weekend = false(1,nb_days); % logical array verifying if each day is a weekend day
       
    for day_id = 1:nb_days
        [y,m,d] = ymd(data.time(days_start_end_data_rows(day_id,1)));
        date(day_id) = cellstr([num2str(m), '/', num2str(d), '/', num2str(y)]);

        [~,k] = find(calendar(y,m) == d);
        weekend(day_id) = (k == 1) || (k == 7); % 1 for Sunday or Saturday, 0 otherwise   
    end

    
    
    %%% Calculate new variables

    % Calculate the sampling time by averaging over the first day
    id_log_off_1 = find(data.time <= log.TimeOff(1), 1, 'last');
    sampling_time = round(mean(seconds(data.time(2:id_log_off_1) - data.time(1:id_log_off_1-1))));
    fprintf('Sampling time = %d sec\n\n', sampling_time);
    % sampling_time = 15; % sec
 
    % Calculate MET
    data.MET = data.ActivityScore_MET_s_/sampling_time;

    % Calculate Moving time
    data.Moving = data.SteppingTime_s_ + data.CyclingTime_s_;

    % Calculate Standing time
    data.Standing = data.UprightTime_s_ - data.Moving;

    % Calculate Total Sedentary time
    data.TotalSedentary = data.SedentaryTime_s_ + data.PrimaryLyingTime_s_ + data.SecondaryLyingTime_s_;

    % Calculate Light Physical Activity time
    data.LPA = ((data.MET >= MET_LPA) & (data.MET < MET_MVPA))*sampling_time;

    % Calculate Medium Vigorous Physical Activity time
    data.MVPA = (data.MET >= MET_MVPA)*sampling_time;

    
    %%% Calculate values for each day and over the week
    outputTable = cell2table(cell(nb_days+3,8));
    outputTable.Properties.VariableNames = {'Wear_Time', 'Sedentary', 'Upright', 'Upright_Moving', 'Upright_Standing', 'Upright_Moving_LPA', 'Upright_Moving_MVPA', 'Days'};
    outputTable.Properties.RowNames = [date, cellstr({'Total average', 'Weekday average', 'Weekend average'})];

    % Day per day
    for day_id = 1:nb_days
        fprintf('\n%s\n', date{day_id});
        dayOn = zeros(1,nb_days); dayOn(day_id) = 1;
        outputTable = avg_table(outputTable, data, dayON_rows(days_start_end_data_rows, dayOn), 1, Wear_Time(day_id), day_id);
    end

    fprintf('\nAverage over the study\n');
    outputTable = avg_table(outputTable, data, ones(length(data.time),1), nb_days, Wear_Time, nb_days+1);

    fprintf('\nAverage over week days\n');
    nb_weekend_days = sum(weekend);
    nb_weekdays = nb_days - nb_weekend_days;
    outputTable = avg_table(outputTable, data, dayON_rows(days_start_end_data_rows, ~weekend), nb_weekdays, Wear_Time.*~weekend, nb_days+2);

    fprintf('\nAverage over weekend days\n');
    outputTable = avg_table(outputTable, data, dayON_rows(days_start_end_data_rows, weekend), nb_weekend_days, Wear_Time.*weekend, nb_days+3);


    %%% Output
    writetable(outputTable,['..\outputs\ID', num2str(ID), '_output.xlsx'],'WriteRowNames',true);

    %%% Next participant
    user_input = 0;
    while isempty(user_input) || (user_input(1) ~= 'y' && user_input(1) ~= 'n')
        user_input = input('\nDo you have another participant? [y|n]\n', 's');
        if ~isempty(user_input) && user_input(1) == 'n'
            another_participant = false;
        end
    end
end
    
%%% Functions

% d is a duration hh:mm:ss
function time_str = HourMinute(d)
    
    h = floor(hours(d));
    m = floor(minutes(d) - 60*h);
    time_str = sprintf('%dh%02d', h, m);
end


% Compute and print the average of the given values
function str = average(values, text, nb_days)
    avg = sum(values)/nb_days;
    str = cellstr(HourMinute(avg));
    fprintf('%s time: %s\n', text, char(str));
end 

% Calculate the average moving, sedentary, standing, LPA and MVPA times
% over a given period of time
function outputTable = avg_table(outputTable, data, rows, nb_days, Wear_Time, table_row)

    outputTable.Wear_Time(table_row) = average(Wear_Time, 'Wear', nb_days);
    outputTable.Sedentary(table_row) = average(duration(0,0,data.TotalSedentary.*rows), 'Sedentary', nb_days);
    outputTable.Upright(table_row) = average(duration(0,0,data.UprightTime_s_.*rows), 'Upright', nb_days);
    outputTable.Upright_Moving(table_row) = average(duration(0,0,data.Moving.*rows), 'Upright Moving', nb_days);
    outputTable.Upright_Standing(table_row) = average(duration(0,0,data.Standing.*rows), 'Upright Standing', nb_days);
    outputTable.Upright_Moving_LPA(table_row) = average(duration(0,0,data.LPA.*rows), 'Upright Moving LPA', nb_days);
    outputTable.Upright_Moving_MVPA(table_row) = average(duration(0,0,data.MVPA.*rows), 'Upright Moving MVPA', nb_days);
    outputTable.Days(table_row) = num2cell(nb_days);
end

% Create a logical rows vector corresponding to the days ON
function rows = dayON_rows(days_start_end_data_rows, day_on)
    
    rows = false(days_start_end_data_rows(end,2),1);
    for day_id = 1:length(day_on)
        if day_on(day_id)
            rows(days_start_end_data_rows(day_id,1):days_start_end_data_rows(day_id,2)) = true;
        end
    end
end