function [Temps, CaResponse] = Primary ()
%% Primary processes fluorescence recordings
%   [] = Primary()
%
%   Version 1.0
%   Version Date: 06-13-25

clear all; close all;
warning('off','all'); % Don't display warnings

% Saving the last filepath for ease.
persistent lastPath
if isempty(lastPath)
        lastPath = pwd;
end

%% Select .csv file(s) or .mat file containing imaging data
global pathstr
global preprocessed
global newdir
global plots


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

%% Gather Stimulus Protocol Specific Parameters
[Stim, time, Pname] = Params ();

%% Ask which plots to generate

plottypes = {'Individual Traces', 'Heatmap', 'Multiple Lines'};
[answer, OK] = listdlg('PromptString','Pick plots to generate', ...
    'ListString', plottypes, 'ListSize', [160 160], ...
    'InitialValue', [3]);
answer = plottypes(answer);

if any(contains(answer, 'Individual Traces'))
    plots.plteach = 1;
else
    plots.plteach = 0;
end

if any(contains(answer, 'Heatmap')) 
    plots.pltheat = 1;
else
    plots.pltheat = 0;
end


if any(contains(answer, 'Multiple Lines'))
    plots.pltmulti = 1;
else
    plots.pltmulti = 0;
end


%% Load and Process Data in .mat format
if endsWith(filename,'mat')
    % Pre-processed data in .mat format.
    load(filename{1});
    numfiles = size(CaResponse.subset,2);
    preprocessed = 1;
    n = regexp(name,'_data','split');
    
end

%% Check if for Stimulus Protocol Parameters, load if necessary
if ~exist('Pname')
    [Stim, time, Pname] = Params ();
end

%% Load and Process Data in .csv file format
if isempty(preprocessed) || preprocessed == 0
    % Need to pick temperature log.
    preprocessed = 0;
    
    [tempn, tempp] = uigetfile2('*.dat', 'Select concatenated temperature readings file',pathstr);
    if isequal(tempn,0)
        error('User canceled analysis session');
    end
    tempname = fullfile(tempp, tempn);
    
    % Import Temperature Log
    opts = detectImportOptions(tempname);
    opts = setvartype(opts,{'Var1','Var2'},'datetime');
    disp('Importing temperature log...');
    fulltemp = readtable(tempname,opts);
    disp('...done');
    
    % Import calcium responses and process traces
    [CaResponse, Temps]=LoadTrace(filename,fulltemp,Stim, time);
    
    % Assign a filename
    disp(filename{1}); % So I can remind myself what I'm analyzing.
    n = inputdlg({'Input new filename'},'Save As',1,{Pname});
    
end

% Generate new folder for plots and results
n = n{1};
newdir = fullfile(pathstr,n);
if exist(newdir,'dir') == 0
    status = mkdir(newdir);
end


%% Save Batch Data
if numfiles >1
    save (fullfile(pathstr,strcat(n,'_data.mat')),'CaResponse', 'Temps','UIDs','Stim','time','Pname');
end

%% Plot Data
Plots(Temps, CaResponse, UIDs, n, numfiles);


%% Save Data
    % Save Metadata
    Worm_Strain = regexp(name, Pname, 'split');
    Worm_Strain = strtrim(Worm_Strain{1});
    
    U = [struct2table(Stim, 'AsArray',1), struct2table(time, 'AsArray',1)];
    U = addvars(U, string(Worm_Strain), string(Pname), 'Before', 'min', 'NewVariableNames',{'Strain', 'StimulusType'});
    writetable(U, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','Metadata');
    
    % Save Processed Traces
    V = array2table(CaResponse, 'VariableNames',UIDs);
    writetable(V, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','CaResponseTrace');
    
    W = array2table(Temps, 'VariableNames',UIDs);
    writetable(W, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','TempTrace');
end
disp('Finished');
clear all; close all;
end