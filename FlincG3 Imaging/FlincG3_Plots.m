function [] = FlincG3_Plots(Temps, Response, Stim, UIDs, n, numfiles, Results, time)
%% FlincG3_Plots
%   Generates and saves plots of FlincG3 Thermal Imaging
%   FlincG3_Plots(Temps, Response, Stim, UIDs, n, numfiles, Results, time)

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
        DrawThePlots(Temps.full(:,i), Response.full(:,i), UIDs{i});
    end
end
set(0,'DefaultFigureVisible','on');

%% Plot Average Traces and Heat Maps
if numfiles > 1
    % Calculate Mean and SD with non-normalized data
    % Note: by including NaN values, if a trace is missing values b/c it is
    % truncated, the entire average trace will be truncated to match. To
    % change this behavior, switch the nan flag to 'omitnan'
    avg_Response = mean(Response.full,2,'omitnan');
    sd_Response = std(Response.full,[],2,'omitnan');
    avg_Tmp = mean(Temps.full,2,'omitnan');
    sd_Tmp = std(Temps.full,[],2,'omitnan');
    
    % Multiple line plot
    if pltmulti == 1
        MakeTheMultipleLinePlot(Response.full, avg_Tmp, sd_Tmp, n, Results.out);
    end
    
     % Adaptation line plot zoomed on 
     % This data needs to be normalized correctly
    if pltadapt == 1
        MakeTheMultipleLinePlot(Response.Tmax_adjusted, ...
            mean(Temps.Tmax,2,'omitnan'), ...
            std(Temps.Tmax,[],2,'omitnan'), ...
            strcat(n, '_TmaxZoom'), find(mean(Temps.Tmax,2,'omitnan') >= Stim.max, 1, 'first'),...
            find(mean(Temps.Tmax,2,'omitnan') >= Stim.max, 1, 'first')+60);
    end
        
    % Normalize traces to the maximum 
    % response amongst all traces.
    % Used for % Correlation plots and Heatmap with normalized data.
    
    Response.norm = Response.subset/max(max(Response.subset));
    % Note that in some cases the normalization above was adjusted manually,
    % for plotting in a heatmap (using the lines below)
        % i.e. in cases where there is an outlier in the responses that is
        % skewing the color scaling in the heatmap. 
        
        Response.heat = Response.norm;
        Temps.heat = Temps.subset;
    
 
    if pltheat == 1
        setaxes = 1;
        while setaxes>0 % loop through the axes selection until you're happy
            switch assaytype
                case 1
                    range = {'-20', '100'};
            end
            
            answer = inputdlg({'Heatmap Range Min', 'Heatmap Range Max'}, ...
                'Heatmap Parameters', 1, range);
            range = [str2num(answer{1}), str2num(answer{2})];
            
            MakeTheHeatmap(Response.heat'*100, mean(Temps.heat,2,'omitnan'), std(Temps.heat,[],2,'omitnan'), n, range);
            
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
    
        if plttvr == 1
            MakeTheTempVResponsePlot(Temps.AtTh, Response.AtTh, Temps.AboveTh, Response.AboveTh, n, Stim,{'AtTh';'AboveTh'});
        end

end
end







