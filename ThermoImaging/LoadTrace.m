function [full_cAD, full_temp] = LoadTrace(filename, fulltemp, Stim, time)
%% LoadTrace
%   Loads a single imaging trace
%   [full_cAD, full_temp] = LoadTrace(filename, tempname, fulltemp, Stim, time)

global indicator

% Have user specify which indicator, then parse datafile to separate the appropriate signals.
if ~exist('tmp')
    [tmp, ok] = listdlg('PromptString','Which indicator are you using?',...
        'SelectionMode','single',...
        'ListString',{'YC3.60','GCaMP + RFP', 'GCaMP only', ...
        'RCaMP + GFP', 'RCaMP only', 'FlincG3'}, ...
        'InitialValue', [1]);
    if ok<1
        error('User canceled analysis session');
    end
    switch tmp
        case 1 % YC3.60
            ch1 = 4;
            ch2 = 5;
        case 2 % GCaMP + RFP
            ch1 = 4;
            ch2 = 5;
        case 3 % GCaMP only
            ch1 = 4;
        case 4 % RCaMP + GFP
            ch1 = 5;
            ch2 = 4;
        case 5 % RCaMP only
            ch1 = 4;
        case 6 % FlincG3
            ch1 = 4;
    end
end

numfiles = size(filename,2);
[~, UIDs, ~]  = arrayfun(@fileparts, filename);


allthedata=cellfun(@readtable,filename, 'UniformOutput',false);
tracelengths= cellfun(@(x)(size(x, 1)), allthedata);

[full_cAD, full_temp] = deal(NaN(max(tracelengths), numfiles));


for i=1:numfiles
    fulltable = allthedata{i};

    %% Load Dual Channel or Single Channel Imaging Data
    if ismember(tmp, [1, 2, 4])
        % Dual Channel
        roi1.ch1 = fulltable{2:2:end,ch1};
        roi1.ch2 = fulltable{2:2:end,ch2};

        roi2.ch1 = fulltable{3:2:end,ch1};
        roi2.ch2 = fulltable{3:2:end,ch2};

        Channel1 = (roi1.ch1-roi2.ch1);
        Channel2 = (roi1.ch2-roi2.ch2);

        Ch_ratio = Channel1./Channel2;
    else
        % Single Channel
        roi1.ch1 = fulltable{2:2:end,ch1};
        roi2.ch1 = fulltable{3:2:end,ch1};

        Channel1 = (roi1.ch1-roi2.ch1);
        Ch_ratio = Channel1;

    end

    %% Extract timestamps and make imaging datatable
    imagetime = fulltable{2:2:end,6};
    timestamps= datetime(imagetime,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSSSSSS','Format','yyyy-MM-dd HH:mm:ss');
    relativetime=duration((timestamps(:)-timestamps(1)),'Format','mm:ss.SSSSSSS');
    imagingdata=timetable(timestamps,Ch_ratio);

    %% Import and process temperature log
    if ~isempty(fulltemp)
        a = datetime(fulltemp{:,1},'InputFormat','MM/dd/yyyy','Format','yyyy-MM-dd HH:mm:ss');
        if ~isduration(fulltemp{:,2})
            b = datetime((fulltemp{:,2}),'InputFormat','HH:mm:ss','Format','HH:mm:ss');
            mydatetime = a + timeofday(b);
        else
            mydatetime = a + fulltemp{:,2};
        end

        % subselecting temperature log so that retime doesn't add all the
        % times/dates between discontinuous recording days
        templog = timetable(mydatetime,fulltemp{:,4});
        imagingdate = datestr(timestamps(1),'yyyy-mm-dd');
        S = withtol(imagingdate,days(1));
        sub_templog = templog(S,:);

    else
        sub_templog = timetable(imagingdata.timestamps, linspace(0,1,length(GFP_RFP_ratio))'); %Make up a temperature log for plotting

    end
    %% Compress Data for easy plotting
    lossyID=retime(imagingdata,'secondly','mean');
    lossyTL=retime(sub_templog,'secondly','mean');

    % If there are missing values due to the secondly averaging above not
    % matching to a specific time, these next two lines will fill in those
    % values.
    lossyID=retime(lossyID,'secondly','nearest');
    lossyTL=retime(lossyTL,'secondly', 'nearest');

    %% Align Imaging and Temperature Log Data
    AlignedData = synchronize(lossyID,lossyTL,'intersection');
    if isempty(AlignedData)
        error('No overlap between image times and temperature times. Likely gave Matlab the wrong ATEC Temp Log');
    end

    %% Extract aligned data
    dblAlignedData = AlignedData.Variables;

    %% Generate variables for saving and export
    if ~isempty(fulltemp) 
        IND=find(dblAlignedData(:,2)<=(Stim.F0+0.4) & dblAlignedData(:,2)>=(Stim.F0-0.6));
        ibins = [1 ; find(diff(IND)>1); size(IND,1)];
        ibins = ibins(IND(ibins)< (time.soak + time.stimdur)); % solves the problem from the next line down - prestim period should be before the stimulus, not after
        [M, I] = max(diff(ibins)); %this uses the largest block of time near F0, which can break if the poststim period is longer than the prestim period.
        indeces = [IND(ibins(I)+1):IND(ibins(I+1))];
        base=dblAlignedData(indeces,:);
        baselinecorrection = mean(base(:,1));

        correctedAlignedData=((dblAlignedData(:,1)-baselinecorrection)/baselinecorrection)*100;

        if ((indeces(end))-time.soak(1))-time.pad(1)<=0
            temp = correctedAlignedData;
            full_cAD(abs(((indeces(end))-time.soak(1))-time.pad(1))+1:abs(((indeces(end))-time.soak(1))-time.pad(1))+size(temp,1),i)= temp;
            full_temp(abs(((indeces(end))-time.soak(1))-time.pad(1))+1:abs(((indeces(end))-time.soak(1))-time.pad(1))+size(temp,1),i) = dblAlignedData(:,6);
            warning(['Recording ', UIDs{i},' is shorter than expected. It is truncated at the start of the experiment']);
        else
            temp = correctedAlignedData(((indeces(end)-time.soak(1)) - time.pad(1)):end);
            full_cAD(1:size(temp,1),i) = temp;
            full_temp(1:size(temp,1),i) = dblAlignedData((((indeces(end)-time.soak(1))-time.pad(1)):end),6);
        end
    else
        full_cAD(1:length(dblAlignedData),i) = dblAlignedData(:,1);
        full_temp(1:length(dblAlignedData),i) = dblAlignedData(:,6);

    end
end
