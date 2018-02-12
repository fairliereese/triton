% get_proc_params.m

global PARAMS REMORA

% load hrp files 
[files, path] = uigetfile('*.hrp', 'MultiSelect', 'on', 'Select HRP disks for processing');

% pull out data ID from files
pattern = '^[\w-_]+(?=_disk)';
dataID = regexp(files{1}, pattern, 'match');
dataID = char(dataID(1));

% pull out disk numbers from files
disks = [];
for k = 1:length(files)
    pattern = 'disk(\d{2})';
    num = regexp(files{k}, pattern, 'tokens');
    disks = [disks; char(num{1})];
end

% find and load the headerfile
headerfile = fullfile(path, sprintf('%s.prm', dataID'));


