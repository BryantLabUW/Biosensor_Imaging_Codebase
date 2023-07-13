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

end