function [Temps, CaResponse, Results] = TCI_Quantifications (Temps,CaResponse, Stim, time,n)
%% TCI_Quantifications
%   Quantifies YC3.6 responses to thermal stimuli. Calculations include:
%   T*, temp eliciting maximal response, mean Ca response at specified temp
%   bins, Pearson and Spearman Correlation coefficients
%
%   Version 1.2
%   Version Date: 9-6-20
%
%% Revision History
%   04-01-20    Forked from older version by ASB
%   04-02-20    Renamed a bunch of variables to make more accessible.
%   09-08-20    Changed procedure for detecting threshold such that if
%               calcium trace does not cross threshold, NaN is returned.

global assaytype

CaResponse.nsub = CaResponse.subset./max(CaResponse.full);

if assaytype ~= 2
    %% Generate data subsets for positive thermotaxis ramps
    [CaResponse.AtTh, Temps.AtTh, ...
        CaResponse.AboveTh, Temps.AboveTh] = deal(NaN(size(Temps.subset)));
    
    for i = 1:size(Temps.subset,2)
        % Temperature bin of Near T(holding)
        Temps.AtTh(1:size(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),1),i) = Temps.subset(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),i);
        CaResponse.AtTh(1:size(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),1),i) = CaResponse.nsub(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),i);
        
        % Temperature bin of above T(holding)
        Temps.AboveTh(1:size(find(Temps.subset(:,i)>=Stim.AboveTh(1)),1),i) = Temps.subset(find(Temps.subset(:,i)>=Stim.AboveTh(1)),i);
        CaResponse.AboveTh(1:size(find(Temps.subset(:,i)>=Stim.AboveTh(1)),1),i) = CaResponse.nsub(find(Temps.subset(:,i)>=Stim.AboveTh(1)),i);
        
    end
    
    %% Calculate Temperature at which point Experimental trace rises above 3*STD of control trace for at least N seconds
    % Ramp rate is 0.025C/s, so the time it would take to increase 1C is 40 seconds, which equals 80 frames.
    % Define threshold for calcium response as 3*std of Stim.F0 response.
    %     for i = 1:size(Temps.subset,2)
    %         base(i)=mean(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
    %         stdbase(i)=std(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
    %         threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));
    %
    %         % Only look for threshold during the upwards temperature ramp
    %         if ~isempty(find((CaResponse.subset(time.soak:end,i))>=threshold(i),1,'first'))
    %         Results.Thresh.index(i) = find((CaResponse.subset(time.soak:end,i))>=threshold(i),1,'first');
    %         Results.Thresh.temp(i) = (Temps.subset(Results.Thresh.index(i)+(time.soak-1),i));
    %         else
    %             Results.Thresh.index(i) = NaN;
    %             Results.Thresh.temp(i) = NaN;
    %         end
    %     end
    
    % Only look for threshold during the upwards temperature ramp
    for i = 1:size(Temps.subset,2)
        base(i)=mean(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
        stdbase(i)=std(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
        threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));
    end
    
    n_expt = size(CaResponse.subset,2);
    disp(strcat('number of recordings: ',num2str(n_expt)));

    N = 20; % required number of consectuive numbers following a first one (with a 500 ms frame rate, this is N*2 seconds)
    
    % RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
    II = arrayfun(@(x)(find(CaResponse.subset(:,x)>=threshold(x) | CaResponse.subset(:,x)<=-threshold(x))), [1:n_expt], 'UniformOutput', false);
    kk = arrayfun(@(x)([true;diff(II{x})~=1]), [1:n_expt], 'UniformOutput', false);
    ss = arrayfun(@(x)(cumsum(kk{x})), [1:n_expt], 'UniformOutput', false);
    xx = arrayfun(@(x)(histc(ss{x},1:ss{x}(end))), [1:n_expt], 'UniformOutput', false);
    idxx = arrayfun(@(x)(find(kk{x})), [1:n_expt], 'UniformOutput', false);
    outt = arrayfun(@(x)(II{x}(idxx{x}(xx{x} >= N))), [1:n_expt], 'UniformOutput', false);
    
    
    % Find Calcium Response at Temperature Thresh
    for x = 1:n_expt
        
        if ~isempty(outt{x})
            Results.Thresh.index(x) = CaResponse.subset(outt{x}(1),x);
        else
            Results.Thresh.index(x) = NaN;
        end
    end
    
    % Get Temperature Threshold
    for x = 1:n_expt
        
        if ~isempty(outt{x})
            Results.Thresh.temp(x) = Temps.subset(outt{x}(1),x);
        else
            Results.Thresh.temp(x) = NaN;
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
Results.Thresh_temp = median(Results.Thresh.temp, 'omitnan');
disp(strcat('Median T*: ',num2str(Results.Thresh_temp)));

Results.Tx = median(Results.Thresh.index, 'omitnan');

% Align the full and subset traces to identify the timing of the threshold
% cross
for i = 1:n_expt
[~, ia, ~] = intersect(CaResponse.full(:,i), CaResponse.subset(:,i), 'stable');
time_adjustment_index(i) = ia(1) - 1;
end

Results.out = median((plot_outt + time_adjustment_index), 'omitnan');
    
    %% Calculate temperature that elicits maximal response
    [m, I] = max(CaResponse.subset,[],1,'linear');
    Results.maximalTemp = Temps.subset(I);
    
    Tmax_temp = median(Results.maximalTemp, 'omitnan');
    disp(strcat('Median Tmax: ',num2str(Tmax_temp)));
    
    %% Calculate and plot linear regression of different temperature windows
    set(0,'DefaultFigureVisible','off');
    [Results.rsq.AtTh, Results.Corr.AtTh] = TCI_ResponseFitting(Temps.AtTh, CaResponse.AtTh,2,strcat(n,'_AtTh_'));
    [Results.rsq.AboveTh, Results.Corr.AboveTh] = TCI_ResponseFitting(Temps.AboveTh, CaResponse.AboveTh,2,strcat(n,'_AboveTh_'));
    
    set(0,'DefaultFigureVisible','on');
    
end

if assaytype == 2
    
    %% Generate data subsets
    [CaResponse.BelowTh, Temps.BelowTh] = deal(NaN(size(Temps.subset)));
    
    for i = 1:size(Temps.subset,2)
        % Temperature bin of descending portion
        Temps.BelowTh(1:size(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),1),i) = Temps.subset(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),i);
        CaResponse.BelowTh(1:size(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),1),i) = CaResponse.nsub(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),i);
        trim(i) = find(Temps.BelowTh(:,i)<=(Stim.BelowTh(2)+.2),1,'last');
        Temps.BelowTh(trim(i)+1:end,i)=NaN;
        CaResponse.BelowTh(trim(i)+1:end,i)=NaN;
    end
    
    %% Calculate and plot linear regression of different temperature windows
    set(0,'DefaultFigureVisible','off');
    [Results.rsq.BelowTh, Results.Corr.BelowTh] = TCI_ResponseFitting(Temps.BelowTh, CaResponse.BelowTh,1,strcat(n,'_BelowTh_'));
    set(0,'DefaultFigureVisible','on');
    
    
    %% Calculate T(thresh) for each recording using Ca Reponse Values
    % Define threshold for calcium response as a deviation 3*std of Stim.F0 response.
    for i = 1:size(Temps.subset,2)
        base(i)=mean(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
        stdbase(i)=std(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
        threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));
        
        % Only look for threshold during the negative temp ramp
        if isempty(find(abs(CaResponse.subset(time.soak:end,i))>=threshold(i),1,'first'))
            Results.Thresh.index(i) = NaN;
            Results.Thresh.temp(i) = NaN;
        else
            Results.Thresh.index(i) = find(abs(CaResponse.subset(time.soak:end,i))>=threshold(i),1,'first'); %Abs gets me any deviation from baseline, large or small
            Results.Thresh.temp(i) = (Temps.subset(Results.Thresh.index(i)+(time.soak-1),i));
        end
    end
end

%% Calculate average CaResponse at given temperature bins
for i = 1:size(Temps.subset,2)
    Results.ResponseBin1(i) = mean(CaResponse.subset(find(Temps.subset(:,i)>=Stim.Analysis(1)-.2 & Temps.subset(:,i)<=Stim.Analysis(1)+.2),i));
    Results.ResponseBin2(i) = mean(CaResponse.subset(find(Temps.subset(:,i)>=Stim.Analysis(2)-.2 & Temps.subset(:,i)<=Stim.Analysis(2)+.2),i));
end

%% Calculate average CaResponse at max temperature
for i = 1:size(Temps.subset,2)
    Results.MaxTempResponse(i) = mean(CaResponse.subset(find(Temps.subset(:,i)>=Stim.max-.2 & Temps.subset(:,i)<=Stim.max+.2),i));
end

%% Calculate average CaResponse at F0 temperature
for i = 1:size(Temps.subset,2)
    Results.F0TempResponse(i) = mean(CaResponse.subset(find(Temps.subset(:,i)>=Stim.F0-.2 & Temps.subset(:,i)<=Stim.F0+.2),i));
end

end


