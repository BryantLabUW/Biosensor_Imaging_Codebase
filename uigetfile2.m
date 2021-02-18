function [filename, pathname] = uigetfile2(filterspec, title, varargin)
%% uigetfile2
% Wrapper for standard open file dialog box that adds a modal component
% printing the title of the dialog box when run on non-PC computers
% [FILENAME, PATHNAME] = uigetfile2(FILTERSPEC, TITLE)
%
% [FILENAME, PATHNAME] = uigetfile(FILTERSPEC, TITLE, FILE)
%    FILE is a string containing the name to use as the default selection
%
% [FILENAME, PATHNAME] = uigetfile(..., 'MultiSelect', SELECTMODE)
%     specifies if multiple file selection is enabled for the uigetfile
%     dialog. Valid values for SELECTMODE are 'on' and 'off'. If the value of
%     'MultiSelect' is set to 'on', the dialog box supports multiple file
%     selection. 'MultiSelect' is set to 'off' by default.

% Set default values
file = '';
multiselect = 'Multiselect';
selectmode = 'off';

% Parse varargin
if nargin > 2
    if ~strcmp(varargin{1},'Multiselect')
        file = varargin{1};
    end
    if find(contains(varargin, 'Multiselect'))
        selectmode = varargin{find(contains(varargin, 'Multiselect'))+1};
    end
end

if ~ispc
    h = msgbox (title,'','modal');
    uiwait (h);
end

[filename, pathname] = uigetfile(filterspec, title, file, multiselect, selectmode);

