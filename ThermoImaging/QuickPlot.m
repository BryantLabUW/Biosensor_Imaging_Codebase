function [] = QuickPlot()
% TRCaMP_QuickPlot - Plot calcium imaging and temperature data without
% sophisticated analysis
%
% This function loads and plots raw calcium imaging data and temperature logs
% without using the binned parameters from TCI_Params.
%
% Inputs:
%   filename - Path to .csv file containing calcium imaging data
%   tempname - Path to .dat file containing temperature log
%   plotTitle - (Optional) Title for the plot
%

%% Select then import calcium imaging file
[name, pathstr] = uigetfile2({'*.csv'},'Select imaging data');
filename = fullfile(pathstr, name);

if isequal(name,0)
    error('User canceled analysis session');
end

global indicator

% Have user specify which indicator, then parse datafile to separate the appropriate signals.
if ~exist('tmp')
    [tmp, ok] = listdlg('PromptString','Which indicator are you using?',...
        'SelectionMode','single',...
        'ListString',{'YC3.60','GCaMP + RFP', 'GCaMP only', ...
        'RCaMP + GFP', 'RCaMP only', 'FlincG3'}, ...
        'InitialValue', [1]);
    if ok<1
        error('User canceled analysis session');
    end
    switch tmp
        case 1 % YC3.60
            ch1 = 4;
            ch2 = 5;
        case 2 % GCaMP + RFP
            ch1 = 4;
            ch2 = 5;
        case 3 % GCaMP only
            ch1 = 4;
        case 4 % RCaMP + GFP
            ch1 = 5;
            ch2 = 4;
        case 5 % RCaMP only
            ch1 = 4;
        case 6 % FlincG3
            ch1 = 4;
    end
end

% Import calcium imaging data
fulltable = readtable(filename);

%% Load Dual Channel or Single Channel Imaging Data
    if ismember(tmp, [1, 2, 4])
        % Dual Channel
        roi1.ch1 = fulltable{2:2:end,ch1};
        roi1.ch2 = fulltable{2:2:end,ch2};

        roi2.ch1 = fulltable{3:2:end,ch1};
        roi2.ch2 = fulltable{3:2:end,ch2};

        Channel1 = (roi1.ch1-roi2.ch1);
        Channel2 = (roi1.ch2-roi2.ch2);

        Ch_ratio = Channel1./Channel2;
    else
        % Single Channel
        roi1.ch1 = fulltable{2:2:end,ch1};
        roi2.ch1 = fulltable{3:2:end,ch1};

        Channel1 = (roi1.ch1-roi2.ch1);
        Ch_ratio = Channel1;

    end


% Get timestamps from imaging data
imagetime = fulltable{2:2:end, 6};
timestamps = datetime(imagetime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSS', 'Format', 'yyyy-MM-dd HH:mm:ss');
relativetime = duration((timestamps(:) - timestamps(1)), 'Format', 'mm:ss.SSSSSSS');

%% Select then import temperature log
[tempn, tempp] = uigetfile2('*.dat', 'Select concatenated temperature readings file',pathstr);
if isequal(tempn,0)
    error('User canceled analysis session');
end
tempname = fullfile(tempp, tempn);

opts = detectImportOptions(tempname);
opts = setvartype(opts,{'Var1','Var2'},'datetime');

disp('Importing temperature log...');
fulltemp = readtable(tempname,opts);
disp('...done');

% Process temperature timestamps
a = datetime(fulltemp{:, 1}, 'InputFormat', 'MM/dd/yyyy', 'Format', 'yyyy-MM-dd HH:mm:ss');
if ~isduration(fulltemp{:, 2})
    b = datetime((fulltemp{:, 2}), 'InputFormat', 'HH:mm:ss', 'Format', 'HH:mm:ss');
    mydatetime = a + timeofday(b);
else
    mydatetime = a + fulltemp{:, 2};
end

% Create timetables for synchronization
imagingdata=timetable(timestamps,Ch_ratio);
templog = timetable(mydatetime, fulltemp{:, 4});

% Subsetting templog to match imaging date
imagingdate = datestr(timestamps(1), 'yyyy-mm-dd');
S = withtol(imagingdate, days(1));
sub_templog = templog(S, :);

% Retime data to secondly averages
lossyID = retime(imagingdata, 'secondly', 'mean');
lossyTL = retime(sub_templog, 'secondly', 'mean');

% Fill in missing values
lossyID = retime(lossyID, 'secondly', 'nearest');
lossyTL = retime(lossyTL, 'secondly', 'nearest');

% Align imaging and temperature log data
AlignedData = synchronize(lossyID, lossyTL, 'intersection');
if isempty(AlignedData)
    error('No overlap between image times and temperature times. Likely gave Matlab the wrong ATEC Temp Log');
end

% Extract aligned data
dblAlignedData = AlignedData.Variables;
Ca_raw = dblAlignedData(:, 1);
Temp_raw = dblAlignedData(:, 6);

% Calculate baseline using mean of the entire trace
baselinecorrection = mean(Ca_raw);

% Apply baseline correction
correctedCa = ((Ca_raw - baselinecorrection) / baselinecorrection) * 100;

% Create figure
fig = figure;
movegui('northeast');

% Plot Neural Trace
ax.up = subplot(3, 1, [1:2]);
plot(correctedCa, 'k');
xlim([0, length(correctedCa)]);
ylim([floor(min(correctedCa)), ceil(max(correctedCa))]);
ylabel('dR/R0 (%)');
title([name, ' - Minimally Processed Calcium Response'], 'Interpreter', 'none');

% Plot Temperature trace
ax.dwn = subplot(3, 1, 3);
plot(Temp_raw, 'Color', 'k');
set(gca, 'xtickMode', 'auto');
ylim([floor(min(Temp_raw)), ceil(max(Temp_raw))]);
xlim([0, length(Temp_raw)]);
ylabel('Temperature (celsius)', 'Color', 'k');
xlabel('Time (seconds)');

% Allow manual adjustment of axes
setaxes = 1;
while setaxes > 0
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes', 'No', 'No');
    switch answer
        case 'Yes'
            setaxes = 1;
            vals = inputdlg({'X Min', 'X Max', 'Y Min Upper', 'Y Max Upper', 'Y Min Lower', 'Y Max Lower'}, ...
                'New X/Y Axes', [1 35; 1 35; 1 35; 1 35; 1 35; 1 35], ...
                {num2str(ax.up.XLim(1)) num2str(ax.up.XLim(2)) num2str(ax.up.YLim(1)) num2str(ax.up.YLim(2)) num2str(ax.dwn.YLim(1)) num2str(ax.dwn.YLim(2))});
            if isempty(vals)
                setaxes = -1;
            else
                ax.up.XLim(1) = str2double(vals{1});
                ax.up.XLim(2) = str2double(vals{2});
                ax.dwn.XLim(1) = str2double(vals{1});
                ax.dwn.XLim(2) = str2double(vals{2});
                ax.up.YLim(1) = str2double(vals{3});
                ax.up.YLim(2) = str2double(vals{4});
                ax.dwn.YLim(1) = str2double(vals{5});
                ax.dwn.YLim(2) = str2double(vals{6});
            end
        case 'No'
            setaxes = -1;
        otherwise
            setaxes = -1;
    end
end

%% Save figure

% Create output directory if not exists
newdir = fullfile(pathstr, 'RawPlots');
if ~exist(newdir, 'dir')
    mkdir(newdir);
end

exportgraphics(gcf, fullfile(newdir, [name, '_raw.pdf']), 'ContentType', 'vector');

% Save data to Excel file
T = table((1:length(correctedCa))', correctedCa, Temp_raw, 'VariableNames', {'Time_s', 'dR_R0_percent', 'Temperature_C'});
writetable(T, fullfile(newdir, [name, '_raw_data.xlsx']));

disp(['Plot and data saved to ' newdir]);
end
