function [Temps, CaResponse, Results] = Quantifications (Temps,CaResponse, Stim, time,n)
%% Quantifications
%   Quantifies fluorescent biosensor responses to thermal stimuli. Assumes
%   a positive thermotaxis ramp.
%   Calculations include:
%   T*, temp eliciting maximal response



%% Calculate Temperature Threshold 
% T* defined as the point the imaging trace deviates from F0 response by 3*STD of F0 response for time it takes to change 0.25C
% The amount of time the absolute value of the trace should be above threshold should reflect 0.25 degree C
% Calculate based on ramp rate such that:
% If ramp rate is 0.025C/s, the time it would take to increase 0.25C is 10
% seconds. Remember that the imaging data was downsampled to a frame rate
% of 1 frame/sec.
for i = 1:size(Temps,2)
    base(i)=mean(CaResponse(find(Temps(:,i)<=(Stim.F0+.2) & Temps(:,i) >= (Stim.F0 - 0.2)),i));
    stdbase(i)=std(CaResponse(find(Temps(:,i)<=(Stim.F0+.2) & Temps(:,i) >= (Stim.F0 - 0.2)),i));
    threshold(i) = (3*abs(stdbase(i))); %+ abs(base(i));
end

n_expt = size(CaResponse,2);
disp(strcat('number of recordings: ',num2str(n_expt)));

N = 0.25/time.rampspeed; % required number of consecutive numbers following a first one

% Look for temp threshold, assuming this is a warming temp ramp
    % RUN THIS FOR EACH INDIVIDUAL EXPERIMENTAL TRACE
    II = arrayfun(@(x)(find(CaResponse(:,x)>=threshold(x) | CaResponse(:,x)<=-threshold(x))), [1:n_expt], 'UniformOutput', false);
    kk = arrayfun(@(x)([true;diff(II{x})~=1]), [1:n_expt], 'UniformOutput', false);
    ss = arrayfun(@(x)(cumsum(kk{x})), [1:n_expt], 'UniformOutput', false);
    xx = arrayfun(@(x)(histc(ss{x},1:ss{x}(end))), [1:n_expt], 'UniformOutput', false);
    idxx = arrayfun(@(x)(find(kk{x})), [1:n_expt], 'UniformOutput', false);
    outt = arrayfun(@(x)(II{x}(idxx{x}(xx{x} >= N))), [1:n_expt], 'UniformOutput', false);

% Find Calcium Response at Temperature Thresh
for x = 1:n_expt

    if ~isempty(outt{x})
        Results.Thresh.index(x) = CaResponse(outt{x}(1),x);
    else
        Results.Thresh.index(x) = NaN;
    end
end

% Get Temperature Threshold
for x = 1:n_expt

    if ~isempty(outt{x})
        Results.Thresh.temp(x) = Temps(outt{x}(1),x);
    else
        Results.Thresh.temp(x) = NaN;
    end
end

for x = 1:n_expt

    if ~isempty(outt{x})
        Results.out(x) = (outt{x}(1));
    else
        Results.out(x) = NaN;
    end
end

% Get the average of the individual thresholds (for the Ca Response and Temperature
% trace)
Results.Thresh_temp = median(Results.Thresh.temp, 'omitnan');
disp(strcat('Median T*: ',num2str(Results.Thresh_temp)));

Results.Tx = median(Results.Thresh.index, 'omitnan');


%% Calculate temperature that elicits maximal response
[m, I] = max(CaResponse,[],1,'linear');
Results.maximalTemp = Temps(I);

Tmax_temp = median(Results.maximalTemp, 'omitnan');
disp(strcat('Median Tmax: ',num2str(Tmax_temp)));

%% Calculate temperature that elicits most negative response
[m, I] = min(CaResponse,[],1,'linear');
Results.minimalTemp = Temps(I);

Tmin_temp = median(Results.minimalTemp, 'omitnan');
disp(strcat('Median Tmin: ',num2str(Tmin_temp)));


end


