function [] = TRCaMP_QuickPlot(filename, tempname, plotTitle)
% TRCaMP_QuickPlot - Plot calcium imaging and temperature data without
% sophisticated analysis or
%
% This function loads and plots raw calcium imaging data and temperature logs
% without using the binned parameters from TCI_Params.
%
% Inputs:
%   filename - Path to .csv file containing calcium imaging data
%   tempname - Path to .dat file containing temperature log
%   plotTitle - (Optional) Title for the plot
%
% Example:
%   PlotRawCalciumTemp('path/to/imaging.csv', 'path/to/templog.dat', 'Neuron Response')

%% Select then import calcium imaging file
[name, pathstr] = uigetfile2({'*.csv'},'Select imaging data');
filename = fullfile(pathstr, name);

if isequal(name,0)
    error('User canceled analysis session');
end

% Import calcium imaging data
fulltable = readtable(filename);

% Parse datafile to separate the RFP and GFP signals from RO1 1 and ROI 2.
roi1.GFP = fulltable{2:2:end,4};
roi1.RFP = fulltable{2:2:end,5};

roi2.GFP = fulltable{3:2:end,4};
roi2.RFP = fulltable{3:2:end,5};

GFP = (roi1.GFP-roi2.GFP);
RFP = (roi1.RFP-roi2.RFP);

GFP_RFP_ratio =  GFP./RFP;

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
imagingdata=timetable(timestamps,GFP_RFP_ratio,roi1.GFP,roi1.RFP,roi2.GFP,roi2.RFP);
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

% Calculate baseline using mean of first 30 seconds (or less if shorter)
baseline_window = min(30, round(size(Ca_raw, 1) * 0.1));
baselinecorrection = mean(Ca_raw(1:baseline_window));

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
