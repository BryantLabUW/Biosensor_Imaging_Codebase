function concatenate_ATEC_Temp_Log()
% Concatenates multiple ATEC Temperature Logs together, saves as a primary
% .csv file for the day.
%
%%  Revision History
%   10-5-19 Created by ASB

%% Code
% Get user to select the data files to be analyzed.
[name, pathstr] = uigetfile('*.dat','Select temperature logs','/Users/Batcave/Box Sync/Lab_Hallem/Astra/Data/Calcium Imaging','MultiSelect','on');
filename = fullfile(pathstr, name);
if isequal(name,0)
    error('User canceled analysis session');
elseif size(name,2)==1
    error('User only selected a single .dat file');
else
    disp(('User selected some files'));
end

  %% Import Temperature Data
concat_temp = readtable(filename{1});
for i = 2:size(name,2)  
temp = readtable(filename{i});
concat_temp = [concat_temp; temp];
clear temp
end

answer = inputdlg({'Input new filename, make sure to end with .dat'},'Save As',1,name(2));
writetable(concat_temp,fullfile(pathstr,answer{1}));
disp('Finished');
end