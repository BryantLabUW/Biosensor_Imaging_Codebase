function [] = TRGI_Preprocess ()
%% TRGI_Preprocess processes simultaneous GCaMP + RFP calcium responses to a variety of thermosensory stimulus ramps
%   [] = TRGI_Preprocess()
%   This code will generate a .mat file containing processed imaging data
%   that can be quantified by other code.
%
%   Version 1.0
%   Version Date: 07-24-23
%
%% Revision History
%   2023-07-23 Adapted from TCI_Primary (YC3.60 imaging codebase) by ASB


warning('off','all'); % Don't display warnings

%% Select .csv file(s) or .mat file containing imaging data
[name, pathstr] = uigetfile2({'*.csv'},'Select imaging data','/Users/astrasb/Box Sync/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/Ectopic Expression/pFictive Extended','Multiselect','on');

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
[Stim, time, Pname] = Params ();

%% Load and Process Data in .csv file format
[tempn, tempp] = uigetfile('*.dat', 'Select concatenated temperature readings file',pathstr);

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
    [temp.subset(:,1), temp.subset(:,2), temp.full(:,1), temp.full(:,2)]=LoadTrace(filename{i},tempname, fulltemp,Stim, time);
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
n = n{1};

%% Save Batch Data
if numfiles >1
    save (fullfile(pathstr,strcat(n,'_data.mat')),'CaResponse', 'Temps','UIDs','Stim','time','Pname');
end
disp('Finished!');
