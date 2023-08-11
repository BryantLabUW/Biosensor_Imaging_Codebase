function [] = Plots(Temps, CaResponse, Stim, UIDs, n, numfiles, time)
%% TCI_Plots
%   Generates and saves plots of Fluorescent Thermal Imaging
%   TCI_Plots(Temps, CaResponse, Stim, UIDs, n, numfiles, Results, time)
%
%   Version 2.0
%   Version Date: 3-18-22
%
%% Revision History
%   3-31-20:    Forked from older version by ASB
%   2021_01_27  Changed heatmap such that the heamtap rows (individual
%               traces) are now ordered using average linkage distance.
%               Also changed the inputs to the heatmap so that the traces
%               are normalized to the maximum Ca2+ response for the group.

global plotflag
global assaytype
global plteach
global pltheat
global pltmulti
global plttvr
global pltadapt

%% Plot Individual Traces
plotflag = 1 ;
if plteach == 1
    for i = 1:numfiles
        DrawThePlots(Temps.full(:,i), CaResponse.full(:,i), UIDs{i});
    end
end
set(0,'DefaultFigureVisible','on');

%% Plot Average Traces and Heat Maps
if numfiles > 1
    % Calculate Mean and SD with non-normalized data
    avg_Tmp = mean(Temps.full,2,'omitnan');
    sd_Tmp = std(Temps.full,[],2,'omitnan');
    
    % Multiple line plot
    if pltmulti == 1
        MakeTheMultipleLinePlot(CaResponse.full, avg_Tmp, sd_Tmp, n);
    end
        
    % Normalize traces to the maximum calcium
    % response amongst all traces.
    % Used for Heatmap with normalized data
    
    CaResponse.norm = CaResponse.full/max(max(CaResponse.full));
    CaResponse.heat = CaResponse.norm;
    Temps.heat = Temps.full;
    
    if pltheat == 1
        setaxes = 1;
        while setaxes>0 % loop through the axes selection until you're happy
            switch assaytype
                case 1
                    range = {'-20', '100'};
                case 2
                    range = {'-10', '20'};
                case 3
                    range = {'-60', '60'};
            end
            
            answer = inputdlg({'Heatmap Range Min', 'Heatmap Range Max'}, ...
                'Heatmap Parameters', 1, range);
            range = [str2num(answer{1}), str2num(answer{2})];
            
            MakeTheHeatmap(CaResponse.heat'*100, mean(Temps.heat,2,'omitnan'), std(Temps.heat,[],2,'omitnan'), n, range);
            
            answer = questdlg('Adjust Heatmap Params', 'Plot adjustment', 'Yes');
            switch answer
                case 'Yes'
                    setaxes=1;
                    close all
                case 'No'
                    setaxes=-1;
                case 'Cancel'
                    setaxes=-1;
            end
        end
        close all
        
    end

end
end