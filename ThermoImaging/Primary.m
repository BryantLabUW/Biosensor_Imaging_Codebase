function [Temps, CaResponse] = Primary ()
%% Primary processes fluorescence recordings
%   [] = Primary()
%
%   Version 1.1
%   Version Date: 03-10-26
clear all; close all;
warning('off','all'); % Don't display warnings

% Saving the last filepath for ease.
persistent lastPath
if isempty(lastPath)
    lastPath = pwd;
end

%% Select .csv file(s) or .mat file containing imaging data
global pathstr
global newdir
global plots
global indicator

[name, pathstr] = uigetfile2({'*.csv; *.mat'},'Select imaging data',lastPath,'Multiselect','on');
if isequal(name,0)
    error('User canceled analysis session');
end

% Update persistent variable with the new path
lastPath = pathstr;


if ischar(name)
    numfiles = 1;
    filename = {fullfile(pathstr, name)};
    analysislogic = 0;
else
    numfiles = size(name,2);
    filename = fullfile(pathstr, name);
    analysislogic = 1;
end




%% Gather Stimulus Parameters, Plot Options, and Output Filename
% All collected in a single GUI (TempRampGUI)
[Stim, time, Pname, plots, n, indicator] = TempRampGUI();



%% Load Temperature File(s) -----------------------------------------------
%   Allow the user to select one or more .dat files.
%   If multiple files are selected, concatenate them and save the result.

[tempn, tempp] = uigetfile2('*.dat', ...
    'Select temperature file(s) - select multiple to concatenate', ...
    pathstr, 'Multiselect', 'on');

if isequal(tempn, 0)
    error('User canceled analysis session');
end


if ischar(tempn)
    % ── Single .dat file selected ─────────────────────────────────────────
    tempname = fullfile(tempp, tempn);
    disp('Single temperature file selected, no concatenation needed.');

else
    % ── Multiple .dat files selected: concatenate ─────────────────────────
    numTempFiles = numel(tempn);
    fprintf('User selected %d temperature files. Concatenating...\n', numTempFiles);

    % Read and stack all files
    concat_temp = readtable(fullfile(tempp, tempn{1}));
    for i = 2:numTempFiles
        temp = readtable(fullfile(tempp, tempn{i}));
        concat_temp = [concat_temp; temp]; %#ok<AGROW>
        clear temp
    end

    % Ask for a filename for the concatenated output
    defaultName = strrep(tempn{2}, '.dat', '_concat.dat');
    concatAnswer = inputdlg( ...
        {'Enter filename for concatenated temperature log (must end with .dat)'}, ...
        'Save Concatenated Temperature Log', 1, {defaultName});

    if isempty(concatAnswer)
        error('User canceled analysis session during concatenation save.');
    end

    tempname = fullfile(tempp, concatAnswer{1});
    writetable(concat_temp, tempname);
    fprintf('Concatenated temperature log saved to:\n  %s\n', tempname);
end

%% Import Temperature Log -------------------------------------------------
opts = detectImportOptions(tempname);
opts = setvartype(opts, {'Var1','Var2'}, 'datetime');
disp('Importing temperature log...');
fulltemp = readtable(tempname, opts);
disp('...done');

%% Import calcium responses and process traces
[CaResponse, Temps, UIDs] = LoadTrace(filename, fulltemp, Stim, time);


% Generate new folder for plots and results
newdir = fullfile(pathstr, n);
if exist(newdir, 'dir') == 0
    mkdir(newdir);
end

%% Quantify Data
[Temps, CaResponse, Results] = Quantifications (Temps,CaResponse, Stim, time,n);

%% Plot Data
Plots(Temps, CaResponse, UIDs, n, numfiles, Results);

%% Save Data
if analysislogic == 1
   headers={'UIDs', 'Tstar', 'Maximal_Temp', ...
            'Minimal_Temp'};
        T=table(UIDs', Results.Thresh.temp',Results.maximalTemp',...
            Results.minimalTemp','VariableNames',headers);
end
writetable(T,fullfile(newdir,strcat(n,'_results.xlsx')), 'Sheet', 1);

disp('Finished');
clear all; close all;
end
