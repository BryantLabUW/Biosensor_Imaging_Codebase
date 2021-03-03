function [] = TCI_Plots(Temps, CaResponse, Stim, UIDs, n, numfiles, Results)
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
global pltshade
global pltmulti
global plttvr

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
    avg_Ca = mean(CaResponse.full,2,'includenan');
    sd_Ca = std(CaResponse.full,[],2,'includenan');
    avg_Tmp = mean(Temps.full,2,'includenan');
    sd_Tmp = std(Temps.full,[],2,'includenan');
    
    % Average shaded plot
    if pltshade == 1
        MakeTheShadedPlot(avg_Ca, avg_Tmp, sd_Ca, sd_Tmp,  n, Results.Tx, Results.out, Results.Thresh_temp);
    end
    
    % Multiple line plot
    if pltmulti == 1
        MakeTheMultipleLinePlot(CaResponse.full, avg_Tmp, sd_Tmp, n, Results.Tx, Results.out, Results.Thresh_temp);
    end
    
    % Normalize traces to the maximum calcium
    % response amongst all traces.
    CaResponse.norm = CaResponse.subset/max(max(CaResponse.subset));
    % Correlation plots and Heatmap with normalized data
    
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
            
            MakeTheHeatmap(CaResponse.norm'*100, mean(Temps.subset,2,'includenan'), std(Temps.subset,[],2,'includenan'), n, range);
            
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

%% The bits that make the figures
% Oh look, an inline script!

function [] = DrawThePlots(T, Ca, name)
global pathstr
global assaytype
global newdir
global plotflag

%% Draw a figure where the calcium trace is a black line
fig=figure;
movegui('northeast');

% plot Calcium Trace
ax.up = subplot(3,1,[1:2]);
plot(Ca,'k');
xlim([0, round(size(Ca,1),-1)]);
ylim([floor(min(Ca)),ceil(max(Ca))]);
ylabel('dR/R0 (%)');

% plot Temperature trace
ax.dwn = subplot(3,1,3);
plot(T,'Color','k');
set(gca,'xtickMode', 'auto');
ylim([floor(min(T)),ceil(max(T))]);
xlim([0, round(size(Ca,1),-1)]);
ylabel('Temperature (celcius)','Color','k');
xlabel('Time (seconds)');

% Give the figure a title
currentFigure = gcf;
if contains(pathstr,{'pASB52', 'Ss AFD'})
    suffix = 'Ss-AFD_';
elseif contains(pathstr,'pASB53')
    suffix = 'Ss-BAG--rGC(35)_';
elseif contains(pathstr,{'pASB55', 'Ss BAG'})
    suffix = 'Ss-BAG_';
elseif contains(pathstr,{'IK890', 'Ce AFD'})
    suffix = 'Ce-AFD_';
elseif contains(pathstr,{'XL115', 'Ce ASE'})
    suffix = 'Ce-ASE_cameleon_';
else
    suffix = '';
end
title(currentFigure.Children(end), [strcat('Recording', {' '},suffix,string(name))],'Interpreter','none');

% Adjust axis values for the plot
if plotflag > 0
    setaxes = 1;
    while setaxes>0 % loop through the axes selection until you're happy
        answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes','No','No for All','Yes');
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
            case 'No for All'
                setaxes=-1;
                plotflag = -1;
                set(0,'DefaultFigureVisible','off');
                disp('Remaining plots generated invisibly.');
        end
    end
end

saveas(gcf, fullfile(newdir,['/',name, '.eps']),'epsc');
saveas(gcf, fullfile(newdir,['/',name, '.jpeg']),'jpeg');


%% Draw a figure where the calcium trace color corresponds to the temperature
fig2 = figure;
%movegui('northeast');

if assaytype == 1
    C=inferno(45-15+1); %Full range of possible temperatures
    TickRange=[1:5:31];
    TickLab={'15','20','25','30','35','40','45'};
elseif assaytype ==2
    C=parula(25-10+1);
    TickRange=[1:5:16];
    TickLab={'10','15','20','25'};
elseif assaytype ==3
    C=inferno(35-5+1); %Full range of possible temperatures
    TickRange=[1:5:31];
    TickLab={'5','10','15','20','25','30','35'};
end
colormap((C));
xx = [1:size(Ca,1)'; 1:size(Ca,1)']';
yy = [Ca, Ca];
zz = zeros (size(xx));
cc = [round((T)-15),round((T))-15];

ax2.up = subplot(4,1,1:3);
hs = surf(xx,yy,zz,cc,'EdgeColor','interp','FaceColor','none','CDataMapping','direct','LineWidth',2);
view(2);
grid off
ylabel('dR/R0 (%)');
colorbar('Ticks',TickRange,'TickLabels',TickLab);

ax2.dwn = subplot(4,1,4);
plot(T);
xlim([0, round(size(Ca,1),-1)]);
ylabel('Temperature (celcius)');
xlabel('Time (seconds)');
colorbar

ax2.up.XLim(1) = ax.up.XLim(1);
ax2.up.XLim(2) = ax.up.XLim(2);
ax2.dwn.XLim(1) = ax.dwn.XLim(1);
ax2.dwn.XLim(2) = ax.dwn.XLim(2);
ax2.up.YLim(1) = ax.up.YLim(1);
ax2.up.YLim(2) = ax.up.YLim(2);
ax2.dwn.YLim(1) = ax.dwn.YLim(1);
ax2.dwn.YLim(2) = ax.dwn.YLim(2);

currentFigure = gcf;
title(currentFigure.Children(end), [strcat('Recording', {' '},suffix,string(name))],'Interpreter','none');

% if plotflag>0
%     % Adjust axis values for the plot
%     setaxes = 1;
%     while setaxes>0 % loop through the axes selection until you're happy
%         answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes','No','No for All','Yes');
%         switch answer
%             case 'Yes'
%                 setaxes=1;
%                 vals=inputdlg({'X Min','X Max','Y Min Upper', 'Y Max Upper','Y Min Lower', 'Y Max Lower'},...
%                     'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.up.XLim(1)) num2str(ax.up.XLim(2))  num2str(ax.up.YLim(1)) num2str(ax.up.YLim(2)) num2str(ax.dwn.YLim(1)) num2str(ax.dwn.YLim(2))});
%                 if isempty(vals)
%                     setaxes = -1;
%                 else
%                     ax2.up.XLim(1) = str2double(vals{1});
%                     ax2.up.XLim(2) = str2double(vals{2});
%                     ax2.dwn.XLim(1) = str2double(vals{1});
%                     ax2.dwn.XLim(2) = str2double(vals{2});
%                     ax2.up.YLim(1) = str2double(vals{3});
%                     ax2.up.YLim(2) = str2double(vals{4});
%                     ax2.dwn.YLim(1) = str2double(vals{5});
%                     ax2.dwn.YLim(2) = str2double(vals{6});
%                 end
%             case 'No'
%                 setaxes=-1;
%             case 'No for All'
%                 setaxes=-1;
%                 plotflag = -1;
%                 set(0,'DefaultFigureVisible','off');
%                 disp('Remaining plots generated invisibly.');
%         end
%     end
% end
saveas(gcf, fullfile(newdir,['/', 'rp_',name, '.jpeg']),'jpeg');
saveas(gcf, fullfile(newdir,['/', 'rp_',name, '.eps']),'epsc');
close all
end

function []= MakeTheShadedPlot(Ca, avg_Tmp, err_Ca, err_Tmp, n, Tx, out, Thresh_temp)
global newdir

fig = figure;
ax.up = subplot(3,1,[1:2]);
shadedErrorBar([1:size(Ca,1)],Ca,err_Ca,'k',0);
hold on;
plot(out,Tx,'bo');
hold off;

xlim([0, size(Ca,1)]);
ylim([floor(min(Ca)-max(err_Ca)),ceil(max(Ca)+max(err_Ca))]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);

hold on; plot(out, Thresh_temp, 'bo')
hold off;

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

function [] = MakeTheHeatmap(Ca, avg_Tmp, err_Tmp, n, range)

global newdir
global assaytype

% Use hierarchical clustering to determine optimal order for rows
% the method for the linkage is: Unweighted average distance (UPGMA), aka
% average linkage clustering
D = pdist(Ca);
tree = linkage(D, 'average');
leafOrder = optimalleaforder(tree, D);

% Reorder Calcium traces to reflect optimal leaf order
Ca = Ca(leafOrder, :);


figure
colormap(viridis);
subplot(3,1,[1:2]);
imagesc(Ca,range);
set(gca,'XTickLabel',[]);
xlim([0, round(size(avg_Tmp,1),-1)]);
ylabel('Worms');
colorbar

subplot(3,1,3);
colors = get(gca,'colororder');
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'r',0);
set(gca,'xtickMode', 'auto');
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
xlim([0, round(size(avg_Tmp,1),-1)]);
ylabel('Temperature (celcius)','Color','r');
xlabel('Time (seconds)');
currentFigure = gcf;
colorbar

title(currentFigure.Children(end), strcat(n,'_Cameleon Response Heatmap'),'Interpreter','none');

movegui('northeast');

saveas(gcf, fullfile(newdir,['/', n, '-heatmap.eps']),'epsc');
saveas(gcf, fullfile(newdir,['/', n, '-heatmap.jpeg']),'jpeg');
end

function [] = MakeTheTempVResponsePlot(Bin1_Temps, Bin1_CaResponse, Bin2_Temps, Bin2_CaResponse, n, Stim,labels)
global newdir
global assaytype

fig = figure;
ax.L = subplot(1,19,1:7);
plot(Bin1_Temps, Bin1_CaResponse,'-');
ylabel('YFP/CFP ratio(%deltaR/R)');xlabel('Temperature (C)');
ylim([-1 1]);
title(labels{1});

ax.R = subplot(1,19,8:19);
plot(Bin2_Temps, Bin2_CaResponse,'-');
set(gca,'YTickLabel',[]); xlabel('Temperature (C)');
ylim([-1 1]);
title(labels{2});

if exist('Stim.NearTh')
    ax.L.XLim = [Stim.NearTh(1) Stim.NearTh(2)];
    ax.L.XTick = [Stim.NearTh(1):2:Stim.NearTh(2)];
    ax.R.XLim = [Stim.AboveTh(1) Stim.max];
    ar.R.XTick = [Stim.AboveTh:5:Stim.max]
elseif exist('Stim.BelowTh')
    ax.L.XLim = [Stim.BelowTh(2) Stim.BelowTh(1)];
    ax.L.XTick = [Stim.BelowTh(2):2:Stim.BelowTh(1)];
end

movegui('northeast');
setaxes = 1;
while setaxes>0 % loop through the axes selection until you're happy
    answer = questdlg('Adjust X/Y Axes?', 'Axis adjustment', 'Yes');
    switch answer
        case 'Yes'
            setaxes=1;
            vals=inputdlg({'X Min Left','X Max Left','Y Min Left', 'Y Max Left','X Min Right','X Max Right','Y Min Right', 'Y Max Right'},...
                'New X/Y Axes',[1 35; 1 35; 1 35;1 35; 1 35;1 35; 1 35;1 35],{num2str(ax.L.XLim(1)) num2str(ax.L.XLim(2))  num2str(ax.L.YLim(1)) num2str(ax.L.YLim(2)) num2str(ax.R.XLim(1)) num2str(ax.R.XLim(2)) num2str(ax.R.YLim(1)) num2str(ax.R.YLim(2))});
            if isempty(vals)
                setaxes = -1;
            else
                ax.L.XLim(1) = str2double(vals{1});
                ax.L.XLim(2) = str2double(vals{2});
                
                ax.L.YLim(1) = str2double(vals{3});
                ax.L.YLim(2) = str2double(vals{4});
                
                ax.R.XLim(1) = str2double(vals{5});
                ax.R.XLim(2) = str2double(vals{6});
                
                ax.R.YLim(1) = str2double(vals{7});
                ax.R.YLim(2) = str2double(vals{8});
            end
        case 'No'
            setaxes=-1;
        case 'Cancel'
            setaxes=-1;
    end
end

saveas(gcf, fullfile(newdir,['/', n, '-Temperature vs CaResponse_lines']),'epsc');
saveas(gcf, fullfile(newdir,['/', n, '-Temperature vs CaResponse_lines']),'jpeg');

close all
end

function []= MakeTheMultipleLinePlot(Ca, avg_Tmp,  err_Tmp, n, Tx, out, avg_Thresh_temp)
global newdir


C=cbrewer('qual', 'Dark2', 7, 'PCHIP');
set(groot, 'defaultAxesColorOrder', C);
fig = figure;
ax.up = subplot(3,1,[1:2]);

hold on;

plot([1:size(Ca,1)],Ca,'-');

plot(out,Tx,'bo');
hold off;
xlim([0, size(Ca,1)]);
ylim([floor(min(min(Ca))),ceil(max(max(Ca)))]);
ylim([-20, 210]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
set(gca,'xtickMode', 'auto');
hold on; plot(out, avg_Thresh_temp, 'bo')
hold off;
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
ylim([19, 41]);
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

