function [Temps, CaResponse, Results] = TCI_Quantifications (Temps,CaResponse, Stim, time,n)
%% TCI_Quantifications
%   Quantifies YC3.6 responses to thermal stimuli. Calculations include:
%   T*, temp eliciting maximal response, mean Ca response at specified temp
%   bins, Pearson and Spearman Correlation coefficients


global assaytype

%CaResponse.nsub = CaResponse.subset./max(CaResponse.full);

if assaytype ~= 2
    %% Generate data subsets for positive thermotaxis ramps
    [CaResponse.AtTh, Temps.AtTh, ...
        CaResponse.AboveTh, Temps.AboveTh, ...
        CaResponse.Tmax, Temps.Tmax] = deal(NaN(size(Temps.subset)));
    
    for i = 1:size(Temps.subset,2)
        % Temperature bin of Near T(holding)
        Temps.AtTh(1:size(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),1),i) = Temps.subset(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),i);
        CaResponse.AtTh(1:size(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),1),i) = CaResponse.subset(find(Temps.subset(:,i)>=Stim.NearTh(1) & Temps.subset(:,i)<=Stim.NearTh(2)),i);
        
        % Temperature bin of above T(holding)
        Temps.AboveTh(1:size(find(Temps.subset(:,i)>=Stim.AboveTh(1)),1),i) = Temps.subset(find(Temps.subset(:,i)>=Stim.AboveTh(1)),i);
        CaResponse.AboveTh(1:size(find(Temps.subset(:,i)>=Stim.AboveTh(1)),1),i) = CaResponse.subset(find(Temps.subset(:,i)>=Stim.AboveTh(1)),i);
        
        % Temperature bin of near T(max)
        Temps.Tmax(1:size(find(Temps.full(:,i)>=Stim.max(1)-3),1),i) = Temps.full(find(Temps.full(:,i)>=Stim.max(1)-3),i);
        CaResponse.Tmax(1:size(find(Temps.full(:,i)>=Stim.max(1)-3),1),i) = CaResponse.full(find(Temps.full(:,i)>=Stim.max(1)-3),i);
        
    end
    
    %% Calculate and plot linear regression of different temperature windows
    % When calling TCI_ResponseFitting.m, users choose whether to calculate
    % Spearman's or Pearson's correlation using the 3rd input variable.
    % 1 = Pearson's correlation, for quantifying linear correlation
    % 2 = Spearman's correlation, for quantifying monotonic correlations
    
    [Results.rsq.AtTh, Results.Corr.AtTh] = TCI_ResponseFitting(Temps.AtTh, CaResponse.AtTh,2);
    [Results.rsq.AboveThPear, Results.Corr.AboveThPear] = TCI_ResponseFitting(Temps.AboveTh, CaResponse.AboveTh,1);
    [Results.rsq.AboveThSpear, Results.Corr.AboveThSpear] = TCI_ResponseFitting(Temps.AboveTh, CaResponse.AboveTh,2);
    [~, Results.Corr_Instant] = TCI_ResponseFitting(Temps.subset, CaResponse.subset, 3, Stim);
    
    
else
    %% Generate data subsets for negative thermotaxis ramps
    [CaResponse.BelowTh, Temps.BelowTh,...
        CaResponse.Tmin, Temps.Tmin] = deal(NaN(size(Temps.subset)));
    
    for i = 1:size(Temps.subset,2)
        % Temperature bin of descending portion
        Temps.BelowTh(1:size(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),1),i) = Temps.subset(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),i);
        CaResponse.BelowTh(1:size(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),1),i) = CaResponse.subset(find(Temps.subset(:,i)<=(Stim.BelowTh(1)+0.2) & Temps.subset(:,i)>= (Stim.BelowTh(2)-0.2)),i);
        trim(i) = find(Temps.BelowTh(:,i)<=(Stim.BelowTh(2)+.2),1,'last');
        Temps.BelowTh(trim(i)+1:end,i)=NaN;
        CaResponse.BelowTh(trim(i)+1:end,i)=NaN;
        
        
         % Temperature bin of near T(max)
        Temps.Tmin(1:size(find(Temps.full(:,i)<=Stim.min(1)+3),1),i) = Temps.full(find(Temps.full(:,i)<=Stim.min(1)+3),i);
        CaResponse.Tmin(1:size(find(Temps.full(:,i)<=Stim.min(1)+3),1),i) = CaResponse.full(find(Temps.full(:,i)<=Stim.min(1)+3),i);
        
    end
    
    
    %% Calculate and plot linear regression of different temperature windows
    % When calling TCI_ResponseFitting.m, users choose whether to calculate
    % Spearman's or Pearson's correlation using the 3rd input variable.
    % 1 = Pearson's correlation, for quantifying linear correlation
    % 2 = Spearman's correlation, for quantifying monotonic correlations
    set(0,'DefaultFigureVisible','off');
    [Results.rsq.BelowTh, Results.Corr.BelowTh] = TCI_ResponseFitting(Temps.BelowTh, CaResponse.BelowTh,1,strcat(n,'_BelowTh_'));
    set(0,'DefaultFigureVisible','on');
end

%% Calculate Temperature at which point trace deviates from F0 response by 3*STD of F0 response for time it takes to change 0.25C
% The amount of time the absolute value of the trace should be above threshold should reflect 0.25 degree C
% Calculate based on ramp rate such that:
% If ramp rate is 0.025C/s, the time it would take to increase 0.25C is 10
% seconds. Remember that the imaging data was downsampled to a frame rate
% of 1 frame/sec.
for i = 1:size(Temps.subset,2)
    base(i)=mean(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
    stdbase(i)=std(CaResponse.subset(find(Temps.subset(:,i)<=(Stim.F0+.2) & Temps.subset(:,i) >= (Stim.F0 - 0.2)),i));
    threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));
end

n_expt = size(CaResponse.subset,2);
disp(strcat('number of recordings: ',num2str(n_expt)));

N = 0.25/time.rampspeed; % required number of consecutive numbers following a first one

if assaytype ~= 2
    % RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
    II = arrayfun(@(x)(find(CaResponse.subset(:,x)>=threshold(x) | CaResponse.subset(:,x)<=-threshold(x))), [1:n_expt], 'UniformOutput', false);
    kk = arrayfun(@(x)([true;diff(II{x})~=1]), [1:n_expt], 'UniformOutput', false);
    ss = arrayfun(@(x)(cumsum(kk{x})), [1:n_expt], 'UniformOutput', false);
    xx = arrayfun(@(x)(histc(ss{x},1:ss{x}(end))), [1:n_expt], 'UniformOutput', false);
    idxx = arrayfun(@(x)(find(kk{x})), [1:n_expt], 'UniformOutput', false);
    outt = arrayfun(@(x)(II{x}(idxx{x}(xx{x} >= N))), [1:n_expt], 'UniformOutput', false);
    
else
    % RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
    % Only look for threshold during the negative temp ramp
    II = arrayfun(@(x)(find(CaResponse.subset(time.soak:end,x)>=threshold(x) | CaResponse.subset(time.soak:end,x)<=-threshold(x))), [1:n_expt], 'UniformOutput', false);
    kk = arrayfun(@(x)([true;diff(II{x})~=1]), [1:n_expt], 'UniformOutput', false);
    ss = arrayfun(@(x)(cumsum(kk{x})), [1:n_expt], 'UniformOutput', false);
    xx = arrayfun(@(x)(histc(ss{x},1:ss{x}(end))), [1:n_expt], 'UniformOutput', false);
    idxx = arrayfun(@(x)(find(kk{x})), [1:n_expt], 'UniformOutput', false);
    outt = arrayfun(@(x)(II{x}(idxx{x}(xx{x} >= N))), [1:n_expt], 'UniformOutput', false);
    outt = arrayfun(@(x)(outt{x}+time.soak), [1:n_expt], 'UniformOutput', false);
end

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

%% Calculate temperature that elicits most negative response
[m, I] = min(CaResponse.subset,[],1,'linear');
Results.minimalTemp = Temps.subset(I);

Tmin_temp = median(Results.minimalTemp, 'omitnan');
disp(strcat('Median Tmin: ',num2str(Tmin_temp)));

%% Determine whether miminal temp is above or below Tc
Results.Tmin_category = Results.minimalTemp > Stim.F0+1;

%% Calculate average CaResponse at given temperature bins
for i = 1:n_expt
    Results.ResponseBin1(i) = median(CaResponse.subset(find(Temps.subset(:,i)>=Stim.Analysis(1)-.2 & Temps.subset(:,i)<=Stim.Analysis(1)+.2),i));
    
    Results.ResponseBin2(i) = median(CaResponse.subset(find(Temps.subset(:,i)>=Stim.Analysis(2)-.2 & Temps.subset(:,i)<=Stim.Analysis(2)+.2),i));
end

%% Calculate average CaResponse at at holding temp during prestimulus period
for i = 1:n_expt
    Results.Holding(i) = median(CaResponse.prestim(find(Temps.prestim(:,i)>=Stim.holding-.2 & Temps.prestim(:,i)<=Stim.holding+.2),i));
end


%% Calculate average CaResponse at max temperature
for i = 1:n_expt
    Results.MaxTempResponse(i) = median(CaResponse.subset(find(Temps.subset(:,i)>=Stim.max-.2 & Temps.subset(:,i)<=Stim.max+.2),i));
end

%% Measure degree of steady state adaptation, then normalize to Response at Tambient/holding/cultivation 
for i = 1:n_expt
    % For warming temperature ramps, compare first 15 seconds of Stim.max
    % versus final 15. This second locates the temperature bins. See next
    % section for normalization relative to Tambient.
    
    if assaytype ~=2
        temp = (CaResponse.full(find(Temps.full(:,i)>=Stim.max, 1,'first'):find(Temps.full(:,i)>=Stim.max-0.1, 1,'last'),i));
        Results.AdaptBins(1,i) = median(temp(1:15));
        Results.AdaptBins(2,i) = median(temp(61:75));
    else
        % For cooling ramps, compare first 15 seconds versus final 15 sec
        temp = (CaResponse.full(find(Temps.full(:,i)<=Stim.min+0.1, 1,'first'):find(Temps.full(:,i)<=Stim.min+0.1, 1,'last'),i));
        Results.AdaptBins(1,i) = median(temp(1:15));
        Results.AdaptBins(2,i) = median(temp(61:75));
        
        % For cooling ramps, compare 4 time bins, spaced 1 min apart
       
        Results.AdaptBins(3,i) = median(CaResponse.full(220:230,i));
        Results.AdaptBins(4,i) = median(CaResponse.full(340:350,i));
        Results.AdaptBins(5,i) = median(CaResponse.full(460:470,i));
        
        % And get the temps
        
        Results.AdaptBins(6,i) = median(Temps.full(220:230,i));
        Results.AdaptBins(7,i) = median(Temps.full(340:350,i));
        Results.AdaptBins(8,i) = median(Temps.full(460:470,i));

    end   
end

% Normalize relative to Response at Tambient
temp = Results.AdaptBins;
     if assaytype ~=2 
        if assaytype ~= 4
            % If this is a stimulus where holding response is higher than
            % F0, calculate the threshold from the prestim period
            for i = 1:size(Temps.prestim,2)
                base(i)=mean(CaResponse.prestim(find(Temps.prestim(:,i)<=(Stim.holding+.2) & Temps.prestim(:,i) >= (Stim.holding - 0.2)),i));
                stdbase(i)=std(CaResponse.prestim(find(Temps.prestim(:,i)<=(Stim.holding+.2) & Temps.prestim(:,i) >= (Stim.holding - 0.2)),i));
                threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));    
            end
            
            % Renormalized CaResponse.Tmax trace and Early/Late tmax quantifications relative to the mean Tambient response, aka
            % the "base" here
            CaResponse.Tmax_adjusted = CaResponse.Tmax-base;
            Results.AdaptBins(1,:) = Results.AdaptBins(1,:) - base;
            Results.AdaptBins(2,:) = Results.AdaptBins(2,:) - base;
        else   
            % If this is a reversal stimulus, then the holding response is
            % F0 and threshold is as defined above
            CaResponse.Tmax_adjusted = CaResponse.Tmax;
        end 
            % Categorize first 15 seconds of Tmax response
            above = (temp(1,:) >= threshold);
            below = (temp(1,:) <= -threshold)*-1;
            Results.TmaxEarly_Cat = above + below;
            
            % Categorize last 15 seconds of Tmax response
            above = (temp(2,:) >= threshold);
            below = (temp(2,:) <= -threshold)*-1;
            Results.TmaxLate_Cat = above + below; 
     else
         % Stimulus where holding response is higher than
            % F0, so calculate the threshold from the prestim period
            for i = 1:size(Temps.prestim,2)
                base(i)=mean(CaResponse.prestim(find(Temps.prestim(:,i)<=(Stim.holding+.2) & Temps.prestim(:,i) >= (Stim.holding - 0.2)),i));
                stdbase(i)=std(CaResponse.prestim(find(Temps.prestim(:,i)<=(Stim.holding+.2) & Temps.prestim(:,i) >= (Stim.holding - 0.2)),i));
                threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));    
            end
            
            % Renormalized CaResponse.Tmin trace and Early/Late tmin quantifications relative to the mean Tambient response, aka
            % the "base" here. Do *not* normalize other quanitfications of
            % cooling ramp.
            CaResponse.Tmin_adjusted = CaResponse.Tmin-base;
            Results.AdaptBins(1,:) = Results.AdaptBins(1,:) - base;
            Results.AdaptBins(2,:) = Results.AdaptBins(2,:) - base;
            
            % Categorize first 15 seconds of Tmin response
            above = (temp(1,:) >= threshold);
            below = (temp(1,:) <= -threshold)*-1;
            Results.TminEarly_Cat = above + below;
            
            % Categorize last 15 seconds of Tmin response
            above = (temp(2,:) >= threshold);
            below = (temp(2,:) <= -threshold)*-1;
            Results.TminLate_Cat = above + below;
    end   


%% Calculate average CaResponse at F0 temperature
for i = 1:n_expt
    Results.F0TempResponse(i) = median(CaResponse.subset(find(Temps.subset(:,i)>=Stim.F0-.2 & Temps.subset(:,i)<=Stim.F0+.2),i));
end




end


