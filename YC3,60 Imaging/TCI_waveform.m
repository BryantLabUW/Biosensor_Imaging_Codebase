%% TCI_waveform
%  Calculates thermal threshold in terms of deviation from a baseline.
%  Applied to ecotpic expression experiments.
%
%   Version number: 1.2.0
%   Version date: 2020_09_08

%% Revision History
%
% 2020_09_08    Changed how average plots are generated - now only traces
%               where the calcium trace crosses threshold are included.
%               Also, the threshold calculation is now only run on the
%               rising phase of the temperature ramp - this prevents us
%               from finding differences during the very beginning of the
%               trace.
% 2020_09_10    Note that there is now a separte code for preprocessing
%               data for input into this code. TCI_Preprocessing.

%% Code
global pathstr
global newdir

[name, pathstr] = uigetfile2({'*.mat'},'Select experimental data file','/Users/astrasb/Box Sync/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/');
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
[basename, basepathstr] = uigetfile2({'*.mat'},'Select baseline data file','/Users/astrasb/Box Sync/Lab_Hallem/Astra/Writing/Bryant et al 20xx/Data/Calcium Imaging/','Multiselect','on')
basefilename = {fullfile(basepathstr, basename)};
ctrl_n = regexp(basename,'_data','split');
ctrl_n = ctrl_n{1};
Ctrl = load(basefilename{1});

%% Calculate Temperature at which point Experimental trace rises above 3*RMS of control trace for at least N seconds
% Going for 6 seconds.
avg_baseline = mean(Ctrl.CaResponse.subset,2,'omitnan');
rms_baseline = rms(Ctrl.CaResponse.subset,2);
avg_expt = mean(Exp.CaResponse.subset,2,'omitnan');
n_expt = size(Exp.CaResponse.subset,2);
N = 12; % required number of consectuive numbers following a first one (with a 500 ms frame rate, this is N*2 seconds)

% RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
II = arrayfun(@(x)(find(Exp.CaResponse.subset(:,x)>=rms_baseline*3)), [1:n_expt], 'UniformOutput', false);
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


% Get the average of the individual thresholds
out = mean(plot_outt, 'omitnan')
Tx = mean(Txx, 'omitnan')
Thresh_temp = mean(Thresh_tempp, 'omitnan')

index_for_average_plot = ~isnan(Thresh_tempp)

% Take subset of traces, including only those with a calcium response that
% crosses threshold
Ca = mean(Exp.CaResponse.full(:,index_for_average_plot),2,'includenan');
err_Ca = std(Exp.CaResponse.full(:,index_for_average_plot),[],2,'includenan');
avg_Tmp = mean(Exp.Temps.full(:,index_for_average_plot),2,'includenan');
err_Tmp = std(Exp.Temps.full(:,index_for_average_plot),[],2,'includenan');

% Average shaded plot
fig = figure;
ax.up = subplot(3,1,[1:2]);
shadedErrorBar([1:size(Ca,1)],Ca,err_Ca,'k',0);
hold on; %plot(out(1),Tx,'ro');
%plot(median(plot_outt),median(Txx),'bo')
hold off;
xlim([0, size(Ca,1)]);
ylim([floor(min(Ca)-max(err_Ca)),ceil(max(Ca)+max(err_Ca))]);

set(gca,'XTickLabel',[]);
ylabel('dR/R0 (%)');

ax.dwn = subplot(3,1,3);
shadedErrorBar([1:size(avg_Tmp,1)],avg_Tmp,err_Tmp,'k',0);
hold on;
%plot(mean(plot_outt,'omitnan'),mean(Thresh_tempp,'omitnan'),'ko')
hold off;
set(gca,'xtickMode', 'auto');
ylim([floor(min(avg_Tmp)-max(err_Tmp)),ceil(max(avg_Tmp)+max(err_Tmp))]);
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

%% Save Data
Exp_Worm_Strain = regexp(name, Pname, 'split');
Exp_Worm_Strain = strtrim(Exp_Worm_Strain{1});
Ctrl_Worm_Strain = regexp(basename, Pname, 'split');
Ctrl_Worm_Strain = strtrim(Ctrl_Worm_Strain{1});

headers={'Exp.UIDs','Thresh_temp','Thresh_time','rGC_ID'};
T=table(Exp.UIDs',Thresh_tempp',plot_outt',repmat(string(Exp_Worm_Strain),[n_expt,1]),'VariableNames',headers);

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

close all

