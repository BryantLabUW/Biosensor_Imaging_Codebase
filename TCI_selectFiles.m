function [filename, tempname, numfiles] = TCI_selectFiles(multi,path)
%% TCI_selectFiles
%   Selects calcium imaging .csv file(s) for processing, plus
%   an associted .dat file containing temperature records from the ATEC
%   Temperature log.
%   [filename, tempname, numfiles] = TCI_selectFiles(multi,path)

%% Revision History
%   10-19-19 Forked from crawl_Cam by ASB

%% Select .csv file(s) or .mat file containing imaging data
[name, pathstr] = uigetfile({'*.csv; *.mat'},'Select imaging data',path,'MultiSelect','on');
[name, pathstr] = uigetfile({'*.csv; *.mat'},'Select imaging data','D:\Hallem Lab\Astra\S stercoralis','MultiSelect','on');

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


if endsWith(filename,'mat')
    % Pre-processed data in .mat format.
    load(filename{1});
    numfiles = size(CaResponse.subset,2);
    preprocessed = 1;
else
    % These are .csv files. Need to pick temperature log.
    preprocessed = 0;
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
        [temp.subset(:,1), temp.subset(:,2), temp.full(:,1), temp.full(:,2)]=TCI_LoadTrace(filename{i},tempname, fulltemp,Stim, time);
        sz.subset = size(temp.subset,1);
        sz.full = size(temp.full,1);
        CaResponse.subset(1:sz.subset,i) = temp.subset(:,1);
        Temps.subset(1:sz.subset,i) = temp.subset(:,2);
        CaResponse.full(1:sz.full,i) = temp.full(:,1);
        Temps.full(1:sz.full,i) = temp.full(:,2);
        clear temp
    end
    
end


end