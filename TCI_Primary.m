function [Temps, CaResponse] = TCI_Primary ()
%% TCI_Primary processes YC3.6 calcium responses to a variety of thermotaxis ramps
%   [] = TCI_Primary()
%
%
%% Revision History
%   4-1-20:     Adapted from an older version of the code by ASB
%   4-2-20:     Added ability to process negative ramps (ASB)
%   4-25-20:    Increased output saved in xlsx file to include metadata and
%                   full traces, to improve downstream import into RStudio.
%   2020-09-10  Results are no longer saved in the .mat file.\
%   2021-02-17  Made updates to analysis and plotting, also put all
%               associated files on GitHub so this revision history is now defunct


warning('off','all'); % Don't display warnings

%% Select .csv file(s) or .mat file containing imaging data
global pathstr
global preprocessed
global newdir


[name, pathstr] = uigetfile2({'*.csv; *.mat'},'Select imaging data','/Users/astrasb/Box Sync/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/','Multiselect','on');


%[name, pathstr] = uigetfile2({'*.csv; *.mat'},'Select imaging data','D:\Hallem Lab\Astra\S stercoralis\','Multiselect','on');

if isequal(name,0)
    error('User canceled analysis session');
end

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
[Stim, time, Pname] = TCI_Params ();

%% Ask which plots to generate
global plotlogic
global plteach
global pltheat
global pltshade
global pltmulti
global plttvr

plottypes = {'Individual Traces', 'Heatmap', 'Shaded Averages', 'Multiple Lines', 'Temp vs Response','None', 'Only Plots'};
[answer, OK] = listdlg('PromptString','Pick plots to generate', ...
    'ListString', plottypes, 'ListSize', [160 160], ...
    'InitialValue', [2 4]);
answer = plottypes(answer);
if any(contains(answer, 'None'))
    plotlogic = 0;
else
    plotlogic = 1;
end

if any(contains(answer, 'Plots Only'))
    analysislogic = 0;
else
    analysislogic = 1;
end

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

if any(contains(answer, 'Shaded Averages'))
    pltshade = 1;
else
    pltshade = 0;
end

if any(contains(answer, 'Multiple Lines'))
    pltmulti = 1;
else
    pltmulti = 0;
end

if any(contains(answer, 'Temp vs Response'))
    plttvr = 1;
else
    plttvr = 0;
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
    [Stim, time, Pname] = TCI_Params ();
end

%% Load and Process Data in .csv file format
if isempty(preprocessed) || preprocessed == 0
    % Need to pick temperature log.
    preprocessed = 0;
    
    %[tempn, tempp] = uigetfile('*.dat', 'Select concatenated temperature readings file',pathstr);
    [tempn, tempp] = uigetfile('*.dat', 'Select concatenated temperature readings file','D:\Hallem Lab\Astra\S stercoralis');
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
    for i=1:numfiles
        [~, UIDs{i}, ~] = fileparts(filename{i});
        [temp.subset(:,1), temp.subset(:,2), temp.full(:,1), temp.full(:,2)]=TCI_LoadTrace(filename{i},tempname, fulltemp,Stim, time);
        sz.subset = size(temp.subset,1);
        sz.full = size(temp.full,1);
        CaResponse.subset(1:sz.subset,i) = temp.subset(:,1);
        Temps.subset(1:sz.subset,i) = temp.subset(:,2);
        CaResponse.full(1:sz.full,i) = temp.full(:,1);
        Temps.full(1:sz.full,i) = temp.full(:,2);
        clear temp
    end
    
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

%% Quantifications
[Temps, CaResponse, Results] = TCI_Quantifications (Temps,CaResponse, Stim, time,n);

%% Save Batch Data
if numfiles >1
    save (fullfile(pathstr,strcat(n,'_data.mat')),'CaResponse', 'Temps','UIDs','Stim','time','Pname');
end

%% Plot Data
if plotlogic > 0
    TCI_Plots(Temps, CaResponse,Stim, UIDs, n, numfiles, Results);
end

%% Save Data
if analysislogic == 1
    global assaytype
    if assaytype ~= 2
        headers={'UIDs','AtTh_Spearmans_R','AboveTh_Spearmans_R','Tstar', 'Maximal_Temp', 'Minimal_Temp', 'ResponseSize_AtThreshold'};
        T=table(UIDs',Results.Corr.AtTh.R',Results.Corr.AboveTh.R',Results.Thresh.temp',Results.maximalTemp', Results.minimalTemp', Results.Thresh.index','VariableNames',headers);
    elseif assaytype == 2
        headers={'UIDs','BelowTh_Pearsons_R', 'Tstar', 'Minimal_Temp',strcat('ResponseSize_',num2str(Stim.Analysis(1)),'C'),strcat('ResponseSize_',num2str(Stim.Analysis(2)),'C'),'ResponseSize_AtThreshold'};
        T=table(UIDs',Results.Corr.BelowTh.R', Results.Thresh.temp', Results.minimalTemp', Results.ResponseBin1', Results.ResponseBin2',Results.Thresh.index','VariableNames',headers);
    end
    writetable(T,fullfile(newdir,strcat(n,'_results.xlsx')), 'Sheet', 1);
    
    % Save Metadata
    Worm_Strain = regexp(name, Pname, 'split');
    Worm_Strain = strtrim(Worm_Strain{1});
    
    U = [struct2table(Stim, 'AsArray',1), struct2table(time, 'AsArray',1)];
    U = addvars(U, string(Worm_Strain), string(Pname), 'Before', 'min', 'NewVariableNames',{'Strain', 'StimulusType'});
    writetable(U, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','Metadata');
    
    % Save Processed Traces
    V = array2table(CaResponse.full, 'VariableNames',UIDs);
    writetable(V, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','CaResponseTrace');
    
    W = array2table(Temps.full, 'VariableNames',UIDs);
    writetable(W, fullfile(newdir, strcat(n,'_results.xlsx')), 'Sheet','TempTrace');
end
disp('Finished Analysis');
clear all; close all;
end