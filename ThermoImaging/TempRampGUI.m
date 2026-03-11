function [Stim, time, Pname, plots, n, indicator] = TempRampGUI()
%% TempRampGUI
%   GUI for selecting or customising thermal stimulus parameters used in
%   calcium imaging experiments.  Replaces the listdlg-based Params() flow
%   with a fully interactive uifigure.
%
%   Returns Stim, time, Pname, plots, output filename n, and indicator index.
%
%   Usage:
%       [Stim, time, Pname, plots, n, indicator] = TempRampGUI();
%
%   Version 3.0  |  Based on Params v1.0 (07-24-23)

%% -- Variable definitions ------------------------------------------------
% F0         : baseline temperature (degrees C)
% soak       : duration (sec) at coolest point before data export begins
% stimdur    : duration (sec) from start of F0 to end of upward ramp
% rampspeed  : rate of warming, in degrees C per second
% pad        : prestimulus time (sec) to include (typically 0, 60, or 120)

%% -- Preset definitions --------------------------------------------------
presets(1).label     = 'Parasite Heating (23-20-40-23)';
presets(1).Pname     = '20to40_Th23';
presets(1).F0        = 20;
presets(1).soak      = 120;
presets(1).stimdur   = 880;
presets(1).rampspeed = 0.025;
presets(1).pad       = 120;

presets(2).label     = 'Parasite Heating (26-20-40-26)';
presets(2).Pname     = '20to40_Th26';
presets(2).F0        = 20;
presets(2).soak      = 120;
presets(2).stimdur   = 880;
presets(2).rampspeed = 0.025;
presets(2).pad       = 120;

presets(3).label     = 'Pristy (20-15-30-20)';
presets(3).Pname     = 'P. pacificus';
presets(3).F0        = 15;
presets(3).soak      = 120;
presets(3).stimdur   = 360;
presets(3).rampspeed = 0.05;
presets(3).pad       = 0;

presets(4).label     = 'Custom';
presets(4).Pname     = '';
presets(4).F0        = 20;
presets(4).soak      = 120;
presets(4).stimdur   = 880;
presets(4).rampspeed = 0.025;
presets(4).pad       = 0;

nPresets   = numel(presets);
dropLabels = {presets.label};

%% -- Output variables ----------------------------------------------------
Stim  = [];
time  = [];
Pname = '';
plots = struct('plteach', 0, 'pltheat', 0, 'pltmulti', 0);
n     = '';
indicator   = 1;

%% -- Colours & dimensions ------------------------------------------------
CLR_BG     = [0.96 0.97 0.99];
CLR_HEADER = [0.13 0.33 0.55];
CLR_PANEL  = [1.00 1.00 1.00];
CLR_ACCENT = [0.18 0.55 0.18];
CLR_ERR    = [0.80 0.10 0.10];
CLR_OK     = [0.10 0.50 0.10];
CLR_CANCEL = [0.65 0.10 0.10];

FIG_W = 560;

% Shared horizontal margins
M  = 15;           % outer margin
IW = FIG_W - 2*M; % inner panel width

% ---- Layout: define each section's bottom edge, working upward ----------
y = M;   % start at bottom margin

% Status label
statusH = 28;
yStatus = y;
y = y + statusH + 8;

% Button row (Confirm + Cancel on same row)
btnH1 = 46;
yBtn1 = y;
y = y + btnH1 + 10;

% Hint label
hintH = 24;
yHint = y;
y = y + hintH + 8;

% Filename panel
fnH = 76;
yFn = y;
y = y + fnH + 10;

% Indicator panel
indH = 76;
yInd = y;
y = y + indH + 10;

% Plot selection panel
pltH = 120;
yPlt = y;
y = y + pltH + 10;

% Parameter panel — height derived from row count so nothing overlaps the title
rowH   = 32;
rowGap = 8;
nPrmRows = 6;                                    % must match number of ROWS entries below
titleBarH = 28;                                  % clearance for uipanel title bar
bottomPad = 10;
prmH   = nPrmRows * (rowH + rowGap) + titleBarH + bottomPad;
innerH = nPrmRows * (rowH + rowGap) + bottomPad; % usable space below title
yPrm = y;
y = y + prmH + 10;

% Stimulus selector panel
selH = 76;
ySel = y;
y = y + selH + 10;

% Header
hdrH = 58;
yHdr = y;
y = y + hdrH + M;  % top margin

% FIG_H is derived from actual content height — nothing gets clipped
FIG_H = y;

%% -- Figure --------------------------------------------------------------
screenSize = get(0, 'ScreenSize');   % [1 1 screenW screenH]
figX = 10;                           % 10 px from left edge
figY = screenSize(4) - FIG_H - 10;  % 10 px from top edge

fig = uifigure( ...
    'Name',     'Thermal Stimulus Parameters', ...
    'Position', [figX figY FIG_W FIG_H], ...
    'Color',    CLR_BG, ...
    'Resize',   'off');

%% -- Header --------------------------------------------------------------
hdrPanel = uipanel(fig, ...
    'Position',        [M yHdr IW hdrH], ...
    'BackgroundColor', CLR_HEADER, ...
    'BorderType',      'none');
uilabel(hdrPanel, ...
    'Text',               'Thermal Stimulus Configuration', ...
    'FontSize',           17, 'FontWeight', 'bold', ...
    'FontColor',          [1 1 1], ...
    'HorizontalAlignment','center', ...
    'Position',           [0 8 IW 36]);

%% -- Stimulus selector ---------------------------------------------------
selPanel = uipanel(fig, ...
    'Title',           'Stimulus Preset', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'Position',        [M ySel IW selH], ...
    'BackgroundColor', CLR_PANEL);

uilabel(selPanel, ...
    'Text',     'Select stimulus:', ...
    'FontSize', 12, ...
    'Position', [12 16 130 26]);

dd = uidropdown(selPanel, ...
    'Items',           dropLabels, ...
    'Value',           dropLabels{1}, ...
    'FontSize',        12, ...
    'Position',        [150 16 IW-165 26], ...
    'ValueChangedFcn', @onDropdown);

%% -- Parameter panel -----------------------------------------------------
prmPanel = uipanel(fig, ...
    'Title',           'Stimulus Parameters', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'Position',        [M yPrm IW prmH], ...
    'BackgroundColor', CLR_PANEL);

ROWS = { ...
  'Baseline Temp (F0)',  'deg C',      'F0';        ...
  'Baseline Soak Time',  'sec',        'soak';      ...
  'Ramp Duration',       'sec',        'stimdur';   ...
  'Ramp Speed',          'deg C/sec',  'rampspeed'; ...
  'Pre-stimulus Time',   'sec',        'pad';       ...
  'Profile Name',        '',           'Pname';     ...
};

xLbl = 14;  wLbl = 175;
xFld = 196; wFld = 220;  % numeric field width
xUnt = 422; wUnt = IW - 422 - 14; % unit label fills to panel edge

handles = struct();

for i = 1:nPrmRows
    yBot = innerH - i*(rowH + rowGap) + rowGap;

    uilabel(prmPanel, ...
        'Text',               ROWS{i,1}, ...
        'FontSize',           12, ...
        'HorizontalAlignment','right', ...
        'Position',           [xLbl yBot wLbl rowH]);

    if strcmp(ROWS{i,3}, 'Pname')
        ef = uieditfield(prmPanel, 'text', ...
            'FontSize',           12, ...
            'HorizontalAlignment','left', ...
            'Position',           [xFld yBot IW-xFld-14 rowH]);
    else
        ef = uieditfield(prmPanel, 'numeric', ...
            'FontSize',           12, ...
            'HorizontalAlignment','center', ...
            'Position',           [xFld yBot wFld rowH]);
        uilabel(prmPanel, ...
            'Text',     ROWS{i,2}, ...
            'FontSize', 11, ...
            'FontColor',[0.45 0.45 0.45], ...
            'Position', [xUnt yBot wUnt rowH]);
    end
    handles.(ROWS{i,3}) = ef;
end

%% -- Plot selection panel ------------------------------------------------
pltPanel = uipanel(fig, ...
    'Title',           'Plots to Generate', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'Position',        [M yPlt IW pltH], ...
    'BackgroundColor', CLR_PANEL);

cbEach = uicheckbox(pltPanel, ...
    'Text',     'Individual Traces', ...
    'FontSize', 12, ...
    'Value',    0, ...
    'Position', [20 74 200 28]);

cbHeat = uicheckbox(pltPanel, ...
    'Text',     'Heatmap', ...
    'FontSize', 12, ...
    'Value',    0, ...
    'Position', [20 42 200 28]);

cbMulti = uicheckbox(pltPanel, ...
    'Text',     'Multiple Lines', ...
    'FontSize', 12, ...
    'Value',    1, ...
    'Position', [20 10 200 28]);

%% -- Indicator panel -----------------------------------------------------
indLabels = {'YC3.60', 'GCaMP + RFP', 'GCaMP only', ...
             'RCaMP + GFP', 'RCaMP only', 'FlincG3'};

indPanel = uipanel(fig, ...
    'Title',           'Calcium Indicator', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'Position',        [M yInd IW indH], ...
    'BackgroundColor', CLR_PANEL);

uilabel(indPanel, ...
    'Text',     'Select indicator:', ...
    'FontSize', 12, ...
    'Position', [12 16 130 26]);

indDD = uidropdown(indPanel, ...
    'Items',    indLabels, ...
    'Value',    indLabels{1}, ...
    'FontSize', 12, ...
    'Position', [150 16 IW-165 26]);

%% -- Output filename panel -----------------------------------------------
fnPanel = uipanel(fig, ...
    'Title',           'Output Filename', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'Position',        [M yFn IW fnH], ...
    'BackgroundColor', CLR_PANEL);

uilabel(fnPanel, ...
    'Text',     'Save As:', ...
    'FontSize', 12, ...
    'Position', [14 16 80 28]);

fnField = uieditfield(fnPanel, 'text', ...
    'FontSize',           12, ...
    'HorizontalAlignment','left', ...
    'Placeholder',        'Auto-fills from Profile Name if left blank', ...
    'Position',           [100 16 IW-115 28]);

%% -- Hint label ----------------------------------------------------------
hintLbl = uilabel(fig, ...
    'Text',               'Preset loaded - edit any field to customise.', ...
    'FontSize',           11, ...
    'FontColor',          [0.45 0.45 0.45], ...
    'HorizontalAlignment','center', ...
    'Position',           [M yHint IW hintH]);

%% -- Buttons -------------------------------------------------------------
%  Single row: Confirm (2/3 width) | Cancel Analysis (1/3 width)
cancelW = floor(IW / 3);
confirmW = IW - cancelW - 10;

uibutton(fig, 'push', ...
    'Text',            'Confirm', ...
    'FontSize',        14, 'FontWeight', 'bold', ...
    'BackgroundColor', CLR_ACCENT, ...
    'FontColor',       [1 1 1], ...
    'Position',        [M yBtn1 confirmW btnH1], ...
    'ButtonPushedFcn', @onConfirm);

uibutton(fig, 'push', ...
    'Text',            'Cancel Analysis', ...
    'FontSize',        12, 'FontWeight', 'bold', ...
    'BackgroundColor', CLR_CANCEL, ...
    'FontColor',       [1 1 1], ...
    'Tooltip',         'Abort - no parameters will be returned', ...
    'Position',        [M+confirmW+10 yBtn1 cancelW btnH1], ...
    'ButtonPushedFcn', @onCancel);

%% -- Status label --------------------------------------------------------
statusLbl = uilabel(fig, ...
    'Text',               '', ...
    'FontSize',           11, ...
    'FontColor',          CLR_ERR, ...
    'HorizontalAlignment','center', ...
    'Position',           [M yStatus IW statusH]);

%% -- Load first preset and wait -----------------------------------------
loadPreset(1);
uiwait(fig);

% =========================================================================
%  CALLBACKS
% =========================================================================
    function onDropdown(~, ~)
        idx = find(strcmp(dropLabels, dd.Value), 1);
        loadPreset(idx);
        if idx == nPresets
            hintLbl.Text = 'Custom mode - enter your own values.';
        else
            hintLbl.Text = 'Preset loaded - edit any field to customise.';
        end
        statusLbl.Text = '';
    end

    function onCancel(~, ~)
        uiresume(fig);
        delete(fig);
        error('User canceled analysis session');
    end

    function onConfirm(~, ~)
        statusLbl.FontColor = CLR_ERR;

        F0_val        = handles.F0.Value;
        soak_val      = handles.soak.Value;
        stimdur_val   = handles.stimdur.Value;
        rampspeed_val = handles.rampspeed.Value;
        pad_val       = handles.pad.Value;
        pname_val     = strtrim(handles.Pname.Value);
        fn_val        = strtrim(fnField.Value);

        % -- Validation ---------------------------------------------------
        if rampspeed_val <= 0
            statusLbl.Text = 'Error: Ramp Speed must be greater than 0.'; return
        end
        if stimdur_val <= 0
            statusLbl.Text = 'Error: Ramp Duration must be greater than 0.'; return
        end
        if soak_val < 0
            statusLbl.Text = 'Error: Soak Time cannot be negative.'; return
        end
        if pad_val < 0
            statusLbl.Text = 'Error: Pre-stimulus Time cannot be negative.'; return
        end
        if isempty(pname_val)
            statusLbl.Text = 'Error: Profile Name cannot be empty.'; return
        end
        if ~cbEach.Value && ~cbHeat.Value && ~cbMulti.Value
            statusLbl.Text = 'Error: Select at least one plot type.'; return
        end

        % -- Populate outputs ---------------------------------------------
        Stim.F0        = F0_val;
        time.soak      = soak_val;
        time.stimdur   = stimdur_val;
        time.rampspeed = rampspeed_val;
        time.pad       = pad_val;
        Pname          = pname_val;

        plots.plteach  = double(cbEach.Value);
        plots.pltheat  = double(cbHeat.Value);
        plots.pltmulti = double(cbMulti.Value);

        % Indicator index (matches original switch-case numbering)
        indicator = find(strcmp(indLabels, indDD.Value), 1);

        % Use Profile Name as filename fallback if left blank
        if isempty(fn_val)
            n = pname_val;
        else
            n = fn_val;
        end

        statusLbl.FontColor = CLR_OK;
        statusLbl.Text = sprintf('Confirmed: "%s"  |  F0=%.1f C  Ramp=%.4f C/s', ...
            Pname, Stim.F0, time.rampspeed);

        printSummary(Stim, time, Pname, plots, n, indicator, indDD.Value);
        pause(0.8);
        uiresume(fig);
        delete(fig);
    end

% =========================================================================
%  HELPER: populate fields from preset index
% =========================================================================
    function loadPreset(idx)
        p = presets(idx);
        handles.F0.Value        = p.F0;
        handles.soak.Value      = p.soak;
        handles.stimdur.Value   = p.stimdur;
        handles.rampspeed.Value = p.rampspeed;
        handles.pad.Value       = p.pad;
        handles.Pname.Value     = p.Pname;
        % Mirror Profile Name into filename field as a convenience default
        fnField.Value           = p.Pname;
    end

end   % TempRampGUI

% =========================================================================
%  Command-Window summary
% =========================================================================
function printSummary(Stim, time, Pname, plots, n, indicator, indName)
    fprintf('\n==========================================\n');
    fprintf('  Stimulus Profile  : %s\n',        Pname);
    fprintf('  Output Filename   : %s\n',        n);
    fprintf('  Baseline Temp     : %.2f C\n',    Stim.F0);
    fprintf('  Soak Time         : %.0f sec\n',  time.soak);
    fprintf('  Ramp Duration     : %.0f sec\n',  time.stimdur);
    fprintf('  Ramp Speed        : %.4f C/sec\n',time.rampspeed);
    fprintf('  Pre-stimulus Time : %.0f sec\n',  time.pad);
    fprintf('  Indicator         : %s (indicator=%d)\n', indName, indicator);
    fprintf('  Plots: Individual=%d  Heatmap=%d  MultiLine=%d\n', ...
        plots.plteach, plots.pltheat, plots.pltmulti);
    fprintf('==========================================\n\n');
end
