function [] = TCI_analyzeEctopic
%% TCI_analyzeEctopic analyzes and plots Ss-AFD-rGC ectopic expression data, compared to a WT control
%   [] = analyzeEctopic()
%   Calculates thermal threshold in terms of deviation from a baseline.
%   Plots average responses and generates heatmaps.
%   Applied to ectopic expression experiments.
%   Before running this code, users should generate preprocessed .mat files
%   using the TCI_Proprocess.m script.
%
%   Version number: 2.1.0
%   Version date: 2022_03_18

%% Revision History
%
% 2020_09_08    Changed how average plots are generated - now only traces
%               where the calcium trace crosses threshold are included.
%               Also, the threshold calculation is now only run on the
%               rising phase of the temperature ramp - this prevents us
%               from finding differences during the very beginning of the
%               trace.
% 2020_09_10    Renamed TCI_waveform, adding several plotting
%               elements from TCI_Primary, so that this code handles all
%               plotting/analysis for ectopic expression experiments.
%               Note that there is now a separte code for preprocessing
%               data for input into this code. TCI_Preprocessing.
% 2020_10_01    Added quantification of Tmax.
% 2020_10_18    Added plot of inidividual calcium traces, colors set by
%               whether trace crosses threshold.
% 2020_12_04    Changed how threshold is calculated. Previous: 3*RMS of
%               control trace, for at least 6 seconds (12 frames). Now:
%               must exceed the mean of control + 3* std(control) for
%               at least 40 seconds (40 frames, at a rate of 0.025c/S
%               this equals 1 degreeC). By eye, this looks a lot more
%               accurate.
% 2021_01_21    Changed heatmap such that the heamtap rows (individual
%               traces) are now ordered using average linkage distance.
%               Also changed the inputs to the heatmap so that the traces
%               are normalized to the maximum Ca2+ response for the group.

%% Code
global pathstr
global newdir

[name, pathstr] = uigetfile2({'*.mat'},'Select experimental data file','/Users/astrasb/Box/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/Ectopic Expression/pFictive Extended');

filename = {fullfile(pathstr, name)};


%% Load Pre-processed data in .mat format.
Exp = load(filename{1});
Exp.numfiles = size(Exp.CaResponse.subset,2);
n = regexp(name,'_data','split');
n = n{1};
newdir = fullfile(pathstr,n);
if exist(newdir,'dir') == 0
    status = mkdir(newdir);
end

%% Gather Stimulus Protocol Specific Parameters,
% either from Experimental metadata or by asking the user.
if isfield(Exp,'Pname')
    Stim = Exp.Stim;
    time = Exp.time;
    Pname = Exp.Pname;
else
    [Stim, time, Pname] = TCI_Params ();
end

%% Select .mat file containing baseline data
[basename, basepathstr] = uigetfile2({'*.mat'},'Select baseline data file','/Users/astrasb/Box/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/Ectopic Expression/pFictive Extended/XL115','Multiselect','on');
basefilename = {fullfile(basepathstr, basename)};
ctrl_n = regexp(basename,'_data','split');
ctrl_n = ctrl_n{1};
Ctrl = load(basefilename{1});


%% Ask which plots to generate
global plotlogic
global plteach
global pltheat
global pltshade
global pltmulti
global plttvr

plottypes = {'Heatmap', 'Shaded Averages', 'Multiple Lines', 'None', 'Plots Only'};
[answer, OK] = listdlg('PromptString','Pick plots to generate', ...
    'ListString', plottypes, 'ListSize', [160 160], ...
    'InitialValue', [3 5]);
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


%% Calculate Temperature at which point Experimental trace rises above 3*STD of control trace for at least N seconds
% Ramp rate is 0.025C/s, so the time it would take to increase 1C is 40 seconds.
avg_baseline = mean(Ctrl.CaResponse.subset,2,'omitnan');
std_baseline = std(Ctrl.CaResponse.subset,[],2, 'omitnan');
threshold_line = avg_baseline + (std_baseline *3);
avg_expt = mean(Exp.CaResponse.subset,2,'omitnan');
n_expt = size(Exp.CaResponse.subset,2);
N = 40; % required number of consectuive numbers following a first one (remembering that the calcium signal was subsamples to an effective frame rate of 1frame/sec

% RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
II = arrayfun(@(x)(find(Exp.CaResponse.subset(:,x)>=threshold_line)), [1:n_expt], 'UniformOutput', false);
kk = arrayfun(@(x)([true;diff(II{x})~=1]), [1:n_expt], 'UniformOutput', false);
ss = arrayfun(@(x)(cumsum(kk{x})), [1:n_expt], 'UniformOutput', false);
xx = arrayfun(@(x)(histc(ss{x},1:ss{x}(end))), [1:n_expt], 'UniformOutput', false);
idxx = arrayfun(@(x)(find(kk{x})), [1:n_expt], 'UniformOutput', false);
outt = arrayfun(@(x)(II{x}(idxx{x}(xx{x} >= N))), [1:n_expt], 'UniformOutput', false);

% Find Calcium Response at Temperature Thresh
for x = 1:n_expt
    
    if ~isempty(outt{x})
        Txx(x) = Exp.CaResponse.subset(outt{x}(1),x);
    else
        Txx(x) = NaN;
    end
end

% Get Temperature Threshold
for x = 1:n_expt
    
    if ~isempty(outt{x})
        Thresh_tempp(x) = Exp.Temps.subset(outt{x}(1),x);
    else
        Thresh_tempp(x) = NaN;
    end
end




for x = 1:n_expt
    
    if ~isempty(outt{x})
        plot_outt(x) = (outt{x}(1));
    else
        plot_outt(x) = NaN;
    end
end

% Get the average of the individual thresholds (for the Ca Response and Temperature
% trace)
Thresh_temp = median(Thresh_tempp, 'omitnan');
disp(strcat('Median T*: ',num2str(Thresh_temp)));

Tx = median(Txx, 'omitnan');

% Get Temperature eliciting max response during rising phase
[Tmax.vals, Tmax.index] = max(Exp.CaResponse.subset);
Tmax.temp = arrayfun(@(x)(Exp.Temps.subset(Tmax.index(x),x)),[1:n_expt]);

% Remove values for traces where the response doesn't cross threshold
for x = 1:n_expt
    if isnan(Thresh_tempp(x))
        Tmax.temp(x) = NaN;
    end
end

Tmax_temp = median(Tmax.temp, 'omitnan');
disp(strcat('Median Tmax: ',num2str(Tmax_temp)));


% Align the full and subset traces to identify the timing of the threshold
% cross
for i = 1:n_expt
    [~, ia, ~] = intersect(Exp.CaResponse.full(:,i), Exp.CaResponse.subset(:,i), 'stable');
    time_adjustment_index(i) = ia(1) - 1;
end

out = median((plot_outt + time_adjustment_index), 'omitnan');

%% Calculate average CaResponse at given temperature bins
for i = 1:size(Exp.Temps.subset,2)
    Results.ResponseBin1(i) = mean(Exp.CaResponse.subset(find(Exp.Temps.subset(:,i)>=Stim.Analysis(1)-.2 & Exp.Temps.subset(:,i)<=Stim.Analysis(1)+.2),i));
    Results.ResponseBin2(i) = mean(Exp.CaResponse.subset(find(Exp.Temps.subset(:,i)>=Stim.Analysis(2)-.2 & Exp.Temps.subset(:,i)<=Stim.Analysis(2)+.2),i));
end

%% Calculate average CaResponse at max temperature
for i = 1:size(Exp.Temps.subset,2)
    Results.MaxTempResponse(i) = mean(Exp.CaResponse.subset(find(Exp.Temps.subset(:,i)>=Stim.max-.2 & Exp.Temps.subset(:,i)<=Stim.max+.2),i));
end

%% Plotting
% Subset the full list of traces, including only those with a calcium response that
% crosses threshold
index_for_plotting = ~isnan(Thresh_tempp);


disp(('UIDs that did not cross threshold: '));
Exp.UIDs{~index_for_plotting}
disp(strcat('number of traces that cross threshold: ',num2str(sum(~isnan(Thresh_tempp))), '/',num2str(n_expt)));

if plotlogic > 0
% Calculate Mean and SD with non-normalized data
% Note: by including NaN values, if a trace is missing values b/c it is
% truncated, the entire average trace will be truncated to match. To
% change this behavior, switch the nan flag to 'omitnan'
Ca = mean(Exp.CaResponse.full(:,index_for_plotting),2,'omitnan');
err_Ca = std(Exp.CaResponse.full(:,index_for_plotting),[],2,'omitnan');
avg_Tmp = mean(Exp.Temps.full(:,index_for_plotting),2,'omitnan');
err_Tmp = std(Exp.Temps.full(:,index_for_plotting),[],2,'omitnan');

% Calculate mean/sd for non-normalized baseline data
Ca_baseline = mean(Ctrl.CaResponse.full,2,'omitnan');
err_Ca_baseline = std(Ctrl.CaResponse.full,[],2,'omitnan');

% Average shaded plot if there are traces above threshold
if pltshade == 1
    if sum(index_for_plotting) > 0
        MakeTheShadedPlot(Ca, avg_Tmp,err_Ca, err_Tmp, Ca_baseline, err_Ca_baseline, n, Tx, out, Thresh_temp);
    end
end
% Plot each response individually, color coding depending on if it crosses
% threshold
Temp = mean(Exp.Temps.full,2,'omitnan');
Err = std(Exp.Temps.full,[],2,'omitnan');
if pltmulti == 1
    MakeTheMultipleLinePlot(Exp.CaResponse.full, Temp,  Err, Ca_baseline, err_Ca_baseline, n, Tx, out, Thresh_temp, Thresh_tempp);
end

% Plot a heatmap, after first normalizing traces to the maximum calcium
% response amongst all traces.
if pltheat == 1
    if sum(index_for_plotting) > 0
        CaResponse.norm = Exp.CaResponse.subset(:,index_for_plotting)/max(max(Exp.CaResponse.subset(:,index_for_plotting)));
        MakeTheHeatmap(CaResponse.norm'*100, mean(Exp.Temps.subset(:,index_for_plotting),2,'omitnan'), std(Exp.Temps.subset(:,index_for_plotting),[],2,'omitnan'), n, [-20 100]);
    end
end

end
%% Save Data
Exp_Worm_Strain = regexp(name, Pname, 'split');
Exp_Worm_Strain = strtrim(Exp_Worm_Strain{1});
Ctrl_Worm_Strain = regexp(basename, Pname, 'split');
Ctrl_Worm_Strain = strtrim(Ctrl_Worm_Strain{1});

if ~isfield(Exp, "UIDs")
    Exp.UIDs = cell(1, n_expt);
end

if analysislogic == 1
    headers={'Strain_ID','Exp.UIDs','Thresh_time','Thresh_temp','Tmax',strcat('ResponseSize_',num2str(Stim.Analysis(1)),'C'),strcat('ResponseSize_',num2str(Stim.Analysis(2)),'C'), strcat('ResponseSize_',num2str(Stim.max),'C')};
    T=table(repmat(string(Exp_Worm_Strain),[n_expt,1]),Exp.UIDs',plot_outt',Thresh_tempp',Tmax.temp',Results.ResponseBin1', Results.ResponseBin2',Results.MaxTempResponse','VariableNames',headers);
    
    writetable(T,fullfile(newdir,strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet', 1);
    
    % Save Metadata
    U = [struct2table(Stim, 'AsArray',1), struct2table(time, 'AsArray',1)];
    U = addvars(U, strcat(string(Exp_Worm_Strain),'/', string(Ctrl_Worm_Strain)), string(Pname), 'Before', 'min', 'NewVariableNames',{'Strains', 'StimulusType'});
    writetable(U, fullfile(newdir, strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet','Metadata');
    
    % Save Processed Experimental Traces
    V = array2table(Exp.CaResponse.full, 'VariableNames',Exp.UIDs);
    writetable(V, fullfile(newdir, strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet','ExpCaResponseTrace');
    
    % Save Processed Control Traces
    cV = array2table(Ctrl.CaResponse.full, 'VariableNames',Ctrl.UIDs);
    writetable(cV, fullfile(newdir, strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet','CtrlCaResponseTrace');
    
    W = array2table(Exp.Temps.full, 'VariableNames',Exp.UIDs);
    writetable(W, fullfile(newdir, strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet','ExpTempTrace');
    
    cW = array2table(Ctrl.Temps.full, 'VariableNames',Ctrl.UIDs);
    writetable(cW, fullfile(newdir, strcat(Exp_Worm_Strain,'_vs_', Ctrl_Worm_Strain,'_',Pname,'_results.xlsx')), 'Sheet','CtrlTempTrace');
end
close all
disp('Finished!');
end

function []= MakeTheShadedPlot(Ca, avg_Tmp, err_Ca, err_Tmp, Ca_baseline, err_Ca_baseline, n, Tx, out, Thresh_temp)
global newdir

fig = figure;
ax.up = subplot(3,1,[1:2]);
shadedErrorBar([1:size(Ca_baseline,1)], Ca_baseline, err_Ca_baseline, 'k',0);
hold on;
shadedErrorBar([1:size(Ca,1)],Ca,err_Ca,'r',0);
plot(out,Tx,'bo');
hold off;
xlim([0, size(Ca,1)]);
ylim([floor(min(Ca)-max(err_Ca)),ceil(max(Ca)+max(err_Ca))]);
ylim([-10 200]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
hold on; plot(out, Thresh_temp, 'bo')
hold off;
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
ylim([19, 40]);
xlim([0, size(Ca,1)]);
ylabel('Temperature (celcius)','Color','k');
xlabel('Time (seconds)');
currentFigure = gcf;

title(currentFigure.Children(end), strcat(n,'_Averaged Cameleon Response'),'Interpreter','none');

movegui('northeast');
setaxes = 1;
while setaxes>0 % loop through the axes selection until you're happy
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes');
    switch answer
        case 'Yes'
            setaxes=1;
            vals=inputdlg({'X Min','X Max','Y Min Upper', 'Y Max Upper','Y Min Lower', 'Y Max Lower'},...
                'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.up.XLim(1)) num2str(ax.up.XLim(2))  num2str(ax.up.YLim(1)) num2str(ax.up.YLim(2)) num2str(ax.dwn.YLim(1)) num2str(ax.dwn.YLim(2))});
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
            setaxes=-1;
        case 'Cancel'
            setaxes=-1;
    end
end

saveas(gcf, fullfile(newdir,['/', n, '-mean_sd.jpeg']),'jpeg');
saveas(gcf, fullfile(newdir,['/', n, '-mean_sd.eps']),'epsc');

close all
end

function []= MakeTheMultipleLinePlot(Ca, avg_Tmp,  err_Tmp, Ca_baseline, err_Ca_baseline,n, Tx, out, avg_Thresh_temp, Thresh_tempp)
global newdir
index_for_plotting = ~isnan(Thresh_tempp);
C=cbrewer('qual', 'Dark2', 7, 'PCHIP');
set(groot, 'defaultAxesColorOrder', C);
fig = figure;
ax.up = subplot(3,1,[1:2]);
shadedErrorBar([1:size(Ca_baseline,1)], Ca_baseline, err_Ca_baseline, 'k',0);

hold on;
xline(out,'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');

if sum(index_for_plotting)>0
    plot([1:size(Ca,1)],Ca(:,index_for_plotting),'-'); %Plot traces that cross threshold
    plot([1:size(Ca,1)],median(Ca(:,index_for_plotting),2, 'omitnan'),'LineWidth', 2, 'Color', 'k');
end


if sum(~index_for_plotting)>0
    plot([1:size(Ca,1)],Ca(:,~index_for_plotting),'Color', [.5 .5 .5]);
end

hold off;
xlim([0, size(Ca,1)]);
ylim([-20, 250]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
hold on;
xline(out,'LineWidth', 2, 'Color', [0.5 0.5 0.5], 'LineStyle', ':');
hold off;
ylim([10, 41]);
xlim([0, size(Ca,1)]);
ylabel('Temperature (celcius)','Color','k');
xlabel('Time (seconds)');
currentFigure = gcf;

title(currentFigure.Children(end), strcat(n,'_Individual Cameleon Response'),'Interpreter','none');

movegui('northeast');
setaxes = 1;
while setaxes>0 % loop through the axes selection until you're happy
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes');
    switch answer
        case 'Yes'
            setaxes=1;
            vals=inputdlg({'X Min','X Max','Y Min Upper', 'Y Max Upper','Y Min Lower', 'Y Max Lower'},...
                'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.up.XLim(1)) num2str(ax.up.XLim(2))  num2str(ax.up.YLim(1)) num2str(ax.up.YLim(2)) num2str(ax.dwn.YLim(1)) num2str(ax.dwn.YLim(2))});
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
            setaxes=-1;
        case 'Cancel'
            setaxes=-1;
    end
end

saveas(gcf, fullfile(newdir,['/', n, '-multiplot.jpeg']),'jpeg');
saveas(gcf, fullfile(newdir,['/', n, '-multiplot.eps']),'epsc');

close all
end

% function [] = MakeTheHeatmap(Ca, avg_Tmp, err_Tmp, n, range)
%
% global newdir
% global assaytype
%
% figure
% colormap(viridis);
% subplot(3,1,[1:2]);
% imagesc(Ca,range);
% set(gca,'XTickLabel',[]);
% xlim([0, round(size(avg_Tmp,1),-1)]);
% ylabel('Worms');
% colorbar
%
% subplot(3,1,3);
% colors = get(gca,'colororder');
% shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'r',0);
% set(gca,'xtickMode', 'auto');
% ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
% ylim([19, 40]);
% xlim([0, round(size(avg_Tmp,1),-1)]);
% ylabel('Temperature (celcius)','Color','r');
% xlabel('Time (seconds)');
% currentFigure = gcf;
% colorbar
%
% title(currentFigure.Children(end), strcat(n,'_Cameleon Response Heatmap'),'Interpreter','none');
%
% saveas(gcf, fullfile(newdir,['/', n, '-heatmap.eps']),'epsc');
% saveas(gcf, fullfile(newdir,['/', n, '-heatmap.jpeg']),'jpeg');
%
% close all
% end
