% proc_gui

global REMORA PARAMS

% use preloaded parameters file
use_param = questdlg('Load processing parameter file?', 'Param load', ...
    'Yes', 'Yes; resume processing', 'No', 'Yes');
if ~isempty(findstr(use_param, 'Yes'))
   [file, path] = uigetfile('.mat', 'Select a processing parameter file.');
   load(fullfile(path, file));
   if strcmp(use_param, 'Yes; resume processing')
       REMORA.hrp.resumeDisk = 1;
   end
else 
   % collect processing parameters
   figure_stuff;
end

% if you didn't load in a file with disk info
if ~isfield(PARAMS, 'xhd')
    % load hrp files 
    [files, path] = uigetfile('*.hrp', 'MultiSelect', 'on', 'Select HRP disks for processing');
    files = char(files);
    
    % pull out data ID from files
    pattern = '^[\w-_]+(?=_disk)';
    dataID = regexp(files(1, :), pattern, 'match');
    dataID = char(dataID(1, :));

    % pull out disk numbers from files
    disks = [];
    for k = 1:size(files, 1)
        pattern = 'disk(\d{2})';
        num = regexp(files(k, :), pattern, 'tokens');
        disks = [disks; char(num{1})];
    end
    
    % instrument/deployment info
    prompt = {'Experiment name (8 chars):';...
        'Site name (4 chars):';'Instrument ID (4 chars):';...
        'Longitude in degrees minutes:';...
        'Latitude in degrees minutes:';...
        'Depth in meters:'};
    title = 'Deployment Info';
    info = inputdlg(prompt, title);
    
    PARAMS.xhd.ExperimentName = info{1};
    PARAMS.xhd.SiteName = info{2};
    PARAMS.xhd.InstrumentID = info{3};
    PARAMS.xhd.Longitude = str2num(info{4});
    PARAMS.xhd.Latitude = str2num(info{5});
    PARAMS.xhd.Depth = str2num(info{6});

    % globalize file info
    REMORA.hrp.files = files; % used to be PARAMS.proc.hrpFiles
    REMORA.hrp.path = path; % used to be PARAMS.proc.path
    REMORA.hrp.disks = disks;
    REMORA.hrp.dataID = dataID;
    REMORA.hrp.proc_save = fullfile(REMORA.hrp.path, 'processing_files');
    
    % LTSA channel default - TODO change this so that different ch LTSAS
    % can be made
     PARAMS.ltsa.ch = 1;
    
    % save your current parameters (disk + processing params)?
    save_param = questdlg('Save your current parameters?');
    if strcmp(save_param, 'Yes')
        try
            % make processing directory for log, errors, resume, etc
            if exist(REMORA.hrp.proc_save) ~= 7
                mkdir(REMORA.hrp.proc_save);
            end
       
            name = fullfile(REMORA.hrp.proc_save, sprintf('%s_procparams_diskinfo', dataID));
            savefile = uiputfile('*.mat', 'Save file',name);
            save(fullfile(REMORA.hrp.proc_save, savefile), 'REMORA', 'PARAMS');
        catch
            disp('Invalid file selected or cancel button pushed.')
        end
    end
end

% % globalize 
% 
% % file info
% REMORA.hrp.files = files; % used to be PARAMS.proc.hrpFiles
% REMORA.hrp.path = path; % used to be PARAMS.proc.path
% REMORA.hrp.disks = disks;
% REMORA.hrp.dataID = dataID;
%REMORA.hrp.headerfile = headerfile;

% % bools
% REMORA.hrp.rmfifo = rmfifo;
% REMORA.hrp.fixTimes = fixTimes;
% REMORA.hrp.resumeDisk = resumeDisk;
% REMORA.hrp.diary = diary_bool;

% rf start/end
% REMORA.hrp.rf_end = rf_end;
% REMORA.hrp.rf_start = rf_start;

% vectors
% REMORA.hrp.dfs = dfs;
% REMORA.hrp.ltsas = ltsas;
% REMORA.hrp.tave = tave;
% REMORA.hrp.dfreq = dfreq;




