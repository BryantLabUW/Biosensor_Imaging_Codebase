function [] = TCI_Plots(Temps, CaResponse, Stim, UIDs, n, numfiles, Results, time)
%% TCI_Plots
%   Generates and saves plots of YC3.6 Thermal Imaging
%   TCI_Plots(Temps, CaResponse, name, n, numfiles)
%
%   Version 1.0
%   Version Date: 3-31-20
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
    % Note: by including NaN values, if a trace is missing values b/c it is
    % truncated, the entire average trace will be truncated to match. To
    % change this behavior, switch the nan flag to 'omitnan'
    avg_Ca = mean(CaResponse.full,2,'omitnan');
    sd_Ca = std(CaResponse.full,[],2,'omitnan');
    avg_Tmp = mean(Temps.full,2,'omitnan');
    sd_Tmp = std(Temps.full,[],2,'omitnan');
    
    % Multiple line plot
    if pltmulti == 1
        MakeTheMultipleLinePlot(CaResponse.full, avg_Tmp, sd_Tmp, n, Results.out);
    end
    
     % Adaptation line plot zoomed on 
     % This data needs to be normalized correctly
    if pltadapt == 1
        if assaytype ~= 2
        MakeTheMultipleLinePlot(CaResponse.Tmax_adjusted, ...
            mean(Temps.Tmax,2,'omitnan'), ...
            std(Temps.Tmax,[],2,'omitnan'), ...
            strcat(n, '_TmaxZoom'), find(mean(Temps.Tmax,2,'omitnan') >= Stim.max, 1, 'first'), ...
            find(mean(Temps.Tmax,2,'omitnan') >= Stim.max-0.1, 1, 'last'));
        else
            MakeTheMultipleLinePlot(CaResponse.Tmin_adjusted, ...
            mean(Temps.Tmin,2,'omitnan'), ...
            std(Temps.Tmin,[],2,'omitnan'), ...
            strcat(n, '_TminZoom'), find(mean(Temps.Tmin,2,'omitnan') <= Stim.min+0.1, 1, 'first'),...
            find(mean(Temps.Tmin,2,'omitnan') <= Stim.min+0.1, 1, 'last'));
        end
    end
        
    % Normalize traces to the maximum calcium
    % response amongst all traces.
    % Used for % Correlation plots and Heatmap with normalized data
    
    CaResponse.norm = CaResponse.subset/max(max(CaResponse.subset));
    
    if assaytype ~= 2
        CaResponse.heat = CaResponse.norm;
        Temps.heat = Temps.subset;
    else
        
        % Align the full and subset traces
        for i = 1:numfiles
            [~, ia, ~] = intersect(CaResponse.full(:,i), CaResponse.subset(:,i), 'stable');
            time_adjustment_index(i) = ia(1) - 1;
        end
        CaResponse.heat = arrayfun(@(x)(CaResponse.full(time_adjustment_index(x):time_adjustment_index(x)+time.pad(4), x)), [1:numfiles], 'UniformOutput', false);
        CaResponse.heat = cell2mat(CaResponse.heat);
        CaResponse.heat =CaResponse.heat/max(max(CaResponse.heat));
        
        Temps.heat = arrayfun(@(x)(Temps.full(time_adjustment_index(x):time_adjustment_index(x)+time.pad(4), x)), [1:numfiles], 'UniformOutput', false);
        Temps.heat = cell2mat(Temps.heat);
    end
 
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
    
    
    if assaytype == 1
        if plttvr == 1
            MakeTheTempVResponsePlot(Temps.AtTh, CaResponse.AtTh, Temps.AboveTh, CaResponse.AboveTh, n, Stim,{'AtTh';'AboveTh'});
            end
        
    elseif assaytype == 2
        if plttvr == 1
            MakeTheTempVResponsePlot(Temps.BelowTh, CaResponse.BelowTh, [], [], n, Stim,{'BelowTh',''});
        end
    elseif assaytype == 3
        if plttvr == 1
            MakeTheTempVResponsePlot(Temps.AtTh, CaResponse.AtTh, Temps.AboveTh, CaResponse.AboveTh, n, Stim,{'AtTh';'AboveTh'});
        end
    end
end
end