%%% Create a summary file combining automatically all output files
%
% The summary gathers the average times of wear, sedentary, upright, moving,
% standing, light physical activity (LPA), and moderate-vigorous physical
% activity (MVPA) of each participant in a single file.
% This Excel file contains three (3) sheets, one for the study averages,
% one for the weekday averages, and one for the weekend averages.

clc
clear variables
warning('off','MATLAB:table:ModifiedAndSavedVarnames')


% Read the content of the folder to find all the output files
folder_info = dir('..\outputs');
ID_table = array2table([Inf], 'VariableNames', {'ID'});
for file_nb = 1:length(folder_info)
    if ~isempty(strfind(folder_info(file_nb).name, 'output'))
        numbers = regexp(folder_info(file_nb).name,'\d*','match');
        ID_table.ID(end+1) = str2double(numbers(1));
    end
end
ID_table = sortrows(ID_table); % sort the participants ID
ID_table = unique(ID_table); % remove the duplicates
nb_participants = length(ID_table.ID)-1;

% Create the three summary tables
nb_days_table = array2table(zeros(nb_participants+1,1));
nb_days_table.Properties.VariableNames = {'Days'};
hm_table = cell2table(cell(nb_participants+1,7));
hm_table.Properties.VariableNames = {'Wear_Time', 'Sedentary', 'Upright', 'Upright_Moving', 'Upright_Standing', 'Upright_Moving_LPA', 'Upright_Moving_MVPA'};
[total_table, weekday_table, weekend_table] = deal([ID_table, hm_table, nb_days_table]);


%%% Add all the participants average values
for participant = 1:nb_participants
    
    id = ID_table.ID(participant);
    
    % Read the corresponding output file
    output = readtable(['..\outputs\ID', num2str(id), '_output.xlsx']);
    
    % Total average table
    total_table(participant, 2:end) = output(strcmp(output.Row, 'Total average'), 2:end);
    % Weekday average table
    weekday_table(participant, 2:end) = output(strcmp(output.Row, 'Weekday average'), 2:end);
    % Weekend average table
    weekend_table(participant, 2:end) = output(strcmp(output.Row, 'Weekend average'), 2:end);
end

%%% Calculate average over participants
total_table = average_table(total_table, nb_participants);
weekday_table = average_table(weekday_table, nb_participants);
weekend_table = average_table(weekend_table, nb_participants);


%%% Create summary file
writetable(total_table, '..\outputs\Summary_LPA_14.xlsx','sheet','total_average','WriteRowNames',true);
writetable(weekday_table, '..\outputs\Summary_LPA_14.xlsx','sheet','weekday_average','WriteRowNames',true);
writetable(weekend_table, '..\outputs\Summary_LPA_14.xlsx','sheet','weekend_average','WriteRowNames',true);

xlswrite('..\outputs\Summary_LPA_14.xlsx', {'Average'}, 'total_average', ['A', num2str(nb_participants+2)]);
xlswrite('..\outputs\Summary_LPA_14.xlsx', {'Average'}, 'weekday_average', ['A', num2str(nb_participants+2)]);
xlswrite('..\outputs\Summary_LPA_14.xlsx', {'Average'}, 'weekend_average', ['A', num2str(nb_participants+2)]);



%%% Functions

% Compute and print the average of the given values
function str = average(col)
    
    minute_sum = 0;
    for day_id = 1:length(col)
        numbers = regexp(col{day_id},'\d*','match');
        minute_sum = minute_sum + str2double(numbers{2}) + 60*str2double(numbers{1});
    end
    minute_avg = round(minute_sum/length(col));
    h = floor(minute_avg/60);
    m = minute_avg - 60*floor(minute_avg/60);
    str = cellstr(sprintf('%dh%02d', h, m));
end 

% Calculate the average moving, sedentary, standing, LPA and MVPA times
% over a given period of time
function tbl = average_table(tbl, nb_participants)

    row = nb_participants+1;
    tbl.Wear_Time(row) = average(tbl.Wear_Time(1:nb_participants));
    tbl.Sedentary(row) = average(tbl.Sedentary(1:nb_participants));
    tbl.Upright(row) = average(tbl.Upright(1:nb_participants));
    tbl.Upright_Moving(row) = average(tbl.Upright_Moving(1:nb_participants));
    tbl.Upright_Standing(row) = average(tbl.Upright_Standing(1:nb_participants));
    tbl.Upright_Moving_LPA(row) = average(tbl.Upright_Moving_LPA(1:nb_participants));
    tbl.Upright_Moving_MVPA(row) = average(tbl.Upright_Moving_MVPA(1:nb_participants)); 
    tbl.Days(row) = mean(tbl.Days(1:nb_participants));
end