function [Temps, CaResponse] = TGRI_Primary ()
%% TGRI_Primary processes simultaneous GCaMP + RFP calcium responses to a variety of thermotaxis ramps
%   [] = TGRI_Primary()
%   This is a stripped down version for plotting and extracting aligned
%   temperature and imaging data
%

%   Version 2.0
%   Version Date: 08-10-23


clear all
close all
warning('off','all'); % Don't display warnings

%% Select .csv file(s) or .mat file containing imaging data
global pathstr
global preprocessed
global newdir


[name, pathstr] = uigetfile2({'*.csv; *.mat'},'Select imaging data','/Users/astrasb/Box/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging','Multiselect','on');

if isequal(name,0)
    error('User canceled analysis session');
end

if ischar(name)
    numfiles = 1;
    filename = {fullfile(pathstr, name)};
else
    numfiles = size(name,2);
    filename = fullfile(pathstr, name);
end

%% Gather Stimulus Protocol Specific Parameters
%[Stim, time, Pname] = Params ();

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
        ans = questdlg('No temp recording was selected. Would you like to plot your traces without a temperature trace?');
        switch ans
            case 'Yes'
                templost = 1;
            case 'No'
                error('User canceled analysis session');
            case 'Cancel'
                error('User canceled analysis session');
        end
    else
            templost = 0;
    end
    if templost<0
    tempname = fullfile(tempp, tempn);
    
    % Import Temperature Log
    opts = detectImportOptions(tempname);
    opts = setvartype(opts,{'Var1','Var2'},'datetime');
    disp('Importing temperature log...');
    fulltemp = readtable(tempname,opts);
    disp('...done');
    end
    % Import calcium responses
    for i=1:numfiles
        [~, UIDs{i}, ~] = fileparts(filename{i});

        if templost < 1
            [temp.full(:,1), temp.full(:,2), ...
            temp.complete(:,1), temp.complete(:,2)]= LoadTrace(filename{i}, fulltemp,Stim, time);
        else
            [temp.full(:,1), temp.full(:,2)] = LoadTrace(filename{i}, [] , Stim, time);

        end
    % Process calcium traces
    if templost < 1
        sz.full = size(temp.full,1);
        sz.complete = size(temp.complete, 1);
       
        CaResponse.full(1:sz.full,i) = temp.full(:,1);
        CaResponse.complete(1:sz.complete, i) = temp.complete(:,1);
    else
        sz.full = size(temp.full,1);
        CaResponse.full(1:sz.full,i) = temp.full(:,1);
    end
   
    % Process temperature traces
    if templost < 1
        Temps.full(1:sz.full,i) = temp.full(:,2);
        Temps.complete(1:sz.complete, i) = temp.complete(:,2);
    else
        Temps.full(1:sz.full,i) = temp.full(:,2);
    end
    clear temp
    % Assign a filename
    disp(filename{1}); % So I can remind myself what I'm analyzing.
    n = inputdlg({'Input new filename'},'Save As',1,{Pname});
    
end

%% Ask which plots to generate
global plotlogic
global analysislogic
global plteach
global pltheat
global pltmulti
global plttvr
global pltadapt
global templost


if templost < 1
plottypes = {'Individual Traces', 'Heatmap', 'Multiple Lines'};

[answer, OK] = listdlg('PromptString','Pick plots to generate', ...
    'ListString', plottypes, 'ListSize', [160 160], ...
    'InitialValue', [1 5]);
answer = plottypes(answer);
% if any(contains(answer, 'None'))
%     plotlogic = 0;
% else
%     plotlogic = 1;
% end
% 
% if any(contains(answer, 'Plots Only'))
%     analysislogic = 0;
% else
%     analysislogic = 1;
% end
plotlogic = 1;
analysislogic = 0;

if any(contains(answer, 'Individual Traces'))
    plteach = 1;
else
    plteach = 0;
end

if any(contains(answer, 'Heatmap'))
    
    pltheat = 1;
else
    pltheat = 0;
end

if any(contains(answer, 'Multiple Lines'))
    pltmulti = 1;
else
    pltmulti = 0;
end

else
    plotlogic = 1;
    analysislogic = 0;
    plteach = 1;
    pltheat = 0;
    pltmulti = 0;
end

% Generate new folder for plots and results
n = n{1};
newdir = fullfile(pathstr,n);
if exist(newdir,'dir') == 0
    status = mkdir(newdir);
end

%% Quantifications

if analysislogic > 1
[Temps, CaResponse, Results] = Quantifications (Temps,CaResponse, Stim, time,n);
end


%% Save Batch Data
if numfiles >1
    save (fullfile(pathstr,strcat(n,'_data.mat')),'CaResponse', 'Temps','UIDs','Stim','time','Pname');
end

%% Plot Data
if plotlogic > 0
    Plots(Temps, CaResponse,Stim, UIDs, n, numfiles, time);
end

    % Save Processed Traces
    V = array2table(CaResponse.full, 'VariableNames',UIDs);
    writetable(V, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','CaResponseTrace');
    
    W = array2table(Temps.full, 'VariableNames',UIDs);
    writetable(W, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','TempTrace');

disp('Finished!');
clear all; close all;
end