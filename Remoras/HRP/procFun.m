function procFun


tic

global PARAMS REMORA

% load in parameters to use in processing
proc_gui;

% profile on;

% numbers that will be the same
headblk = 12;
% ftype and dtype originally from .hdr/.prm files. unlikely we actually
% need them to change so hard coded for now
PARAMS.ltsa.ftype = 2; 
PARAMS.ltsa.dtype = 1; 
PARAMS.fromProc = true;


% make shorter names for all of the global variables
% file info
files = REMORA.hrp.files; % used to be PARAMS.proc.hrpFiles
path = REMORA.hrp.path; % used to be PARAMS.proc.path
disks = REMORA.hrp.disks;
dataID = REMORA.hrp.dataID;
% headerfile = REMORA.hrp.headerfile;

% bools
rmfifo = REMORA.hrp.rmfifo;
fixTimes = REMORA.hrp.fixTimes;
resumeDisk = REMORA.hrp.resumeDisk;
diary_bool = REMORA.hrp.diary_bool;
use_mod = REMORA.hrp.use_mod;

% rf start/end
rf_end = REMORA.hrp.rf_end;
rf_start = REMORA.hrp.rf_start;

% vectors
dfs = REMORA.hrp.dfs;
ltsas = REMORA.hrp.ltsas;

% names of resume disk files
rd_mat = fullfile(path,'resumeDisk.mat');
% rd_struct = fullfile(path,'resumeStruct.mat');
rd_mat_back = fullfile(path,'resumeDisk_back.mat');
% rd_struct_back = fullfile(path,'resumeStruct_BAK.mat');

% enable diary?
if diary_bool
    dfile = fullfile(path, sprintf('%s_log.txt', dataID));
    fclose(fopen(dfile, 'w')); 
    diary(dfile);
end

% check to see whether necessary resume disk files are there
if resumeDisk
    if ~exist(rd_mat_back, 'file')
        disp('Can''t find resume disk mat file. Exiting.');
        return
%     elseif ~exist(rd_struct_back, 'file');
%         disp('Can''t find resume disk param file. Exiting.');
%         return
    else
        fclose('all');
        load(rd_mat_back);
        PARAMS.ltsa = ltsa;
%         rf_start = rf_start_ind;
        clear ltsa
    end
else
    rf_start_ind = rf_start; % which file we're starting processing from
    disk_start = 1;
end     

% read in metadata from .hrd/.prm file TODO this is stupid and there should
% be a better way of doing it
% read_xwavHDRfile(headerfile,0);

% for each disk being processed
for i = disk_start:size(files, 1)
    disk = disks(i, :);

%         % user decision - use changed times?
%         useMod = ...
%         questdlg(sprintf('Modified directory list times found for disk %s, use?',...
%         disk));
%     end
%     
    % load in directory list times and firmware information
    REMORA.hrp.curr = fullfile(path, files(i, :));
    filename = REMORA.hrp.curr;
    
    if isfield(PARAMS, 'head')
        PARAMS = rmfield(PARAMS, 'head');
    end
    
    read_rawHARPdir(filename, 0);
    s = ckFirmware;
    if ~s; fclose all; return; end; % do we have the necessary firmware version?
    
    prefix = sprintf('%s_', dataID);
    
    % change channel information if necessary
    if PARAMS.nch == 1
        REMORA.hrp.ch = 1;
    end
    
    % make necessary directories 
    xwavPaths = mk_directories(disk, dataID, dfs);
    
    % if modified dirlist times already exist in the directory and we want
    % to fix them, load those in 
    modName = sprintf('%s_modifiedDirListTimes.mat', files(i, 1:end-4));
    if exist(fullfile(path, modName), 'file') == 2 && use_mod
        load_modhdrs(fullfile(path, modName));
    elseif fixTimes
        fix_dirlistTimes;
    end
    
    % replace dirlist with modified one TODO questdlg is stupid and we
    % should make our own BOOLEAN returning gui so this stupid if statement
    % can be collapsed
    % todo: add somethings with PARAMS.proc.bwFix here
%     if useMod
%         if strcmp(useMod, 'Yes')
%             load_modhdrs(fullfile(path, modName));
%         elseif fixTimes
%             fix_dirlistTimes;
%         end
%     elseif fixTimes
%         fix_dirlistTimes;
%     end
%     
%     1;
    
    % if making ltsas, generate their names and initialize ltsa vars
    % specific to the disk we're on
    if ltsas(1)
        ltsaNames = init_disk_ltsaparams(disk, dfs, prefix);
    end
    
    % get the number of raw files per xwav
%     [ndir, xwavNums, rfCounts] = get_rfNums(filename, dfs);
%     rfCounts_copy = rfCounts;
    [ndir, REMORA.hrp.xwavNums, rfCounts] = get_rfNums(filename, dfs, ...
        rf_start, rf_end);
    REMORA.hrp.rfCounts = rfCounts;
    
    % empty array initialization
    fod = zeros(1, length(dfs)); % fods (one for each df)
    if ~resumeDisk
        currXWAV = zeros(1, length(dfs)); % current XWAV being generated/
        xwav_bytelocs = zeros(1, length(dfs)); % end byte location of most recently
        ltsa_bytelocs = zeros(length(dfs),length(REMORA.hrp.ch)); % written rf for xwav/ltsa
        xwav_names = cell(1, length(dfs));
    end

    % open raw files
    fid = fopen(fullfile(path, files(i, :)));
    
    % loop over each raw file
    for j = rf_start_ind:ndir
        
        % raw file operations, skip to start of raw file
        status = fseek(fid,PARAMS.head.dirlist(j,1)*512,'bof');
        if status ~= 0
            disp(['Error - failed fseek to byte ',num2str(PARAMS.head.dirlist(j,1)*512)])
            fclose('all');
            return
        end
        
        % raw file reading operations
        if ~PARAMS.cflag % non compression, 4 ch
            % create empty data vector 
            data = zeros(PARAMS.nsampPerRawFile, 1);
            ns = PARAMS.nsampPerSect; % shorthand for below use
            % loop over sectors in raw file 
            for m = 1:PARAMS.head.dirlist(j, 10)
                fseek(fid, headblk, 0); % skip over header, assume time is good
                if PARAMS.nch == 4
                    data((m-1)*ns+1:m*ns) = fread(fid,ns,'uint16')-32767;
                else
                    data((m-1)*ns+1:m*ns) = fread(fid,ns,'int16');
                end
                fseek(fid,PARAMS.tailblk,0);   % skip over tail bytes (=0 for nchan=1, =4 for nchan=4)
            end
        else        % compression
            data = decompressRawHRP(fid,j,PARAMS.ctype);
        end

        % remove FIFO noise
        if rmfifo
            data = rmFIFO(data);   
        end
        
        % loop over each decimation factor
        for k = 1:length(dfs)
            % count errors
            PARAMS.error.csl = 0;

            % make new xwav file
%             if mod(j-1, rfCounts(k)) == 0 
            if mod(j-rf_start, rfCounts(k)) == 0 
              
                % inc. XWAV # currently making
                currXWAV(k) = currXWAV(k) + 1; 
                
                % close last xwav file
                if currXWAV(k) ~= 1 && ~resumeDisk
                    fclose(fod(k));
                end
       
                xwav_names{k} = mk_xwav_name(prefix, dfs(k), j);
                
                % open new xwav
                fod(k) = fopen(fullfile(xwavPaths{k}, xwav_names{k}), 'w');
                
                % change nrf for the last file if needed
                if currXWAV(k) == REMORA.hrp.xwavNums(k)
                    REMORA.hrp.rfCounts(k) = ndir - j + 1; 
                end
                
                if PARAMS.dflag
                    fprintf('\nFilename: %s \nXWAV file %d out of %d for df %d \n', ...
                        xwav_names{k}, currXWAV(k),...
                        REMORA.hrp.xwavNums(k), dfs(k));
                end
                
                % write XWAV header info
                write_XWAVhead_modified(fod(k),j,REMORA.hrp.rfCounts(k),k);
            end
             
            % wr_data is the data we'll use to write for this df
            if dfs(k) ~= 1
                wr_data = decimate(data, dfs(k));
%                 wr_data = decimate_partial(data, dfs(k));
            else
                wr_data = data;
            end
            
            % adjust byte we're writing to if resuming processing
            if resumeDisk                
                % open file that we need to update
                fod(k) = fopen(fullfile(xwavPaths{k},xwav_names{k}), 'r+');
                fseek(fod(k), xwav_bytelocs(k), 'bof');
            end
            
            % finally, write to xwav
            fwrite(fod(k),wr_data,'int16');
            
            % if making ltsas
            if ltsas(k)
                
                % reshape data to suit # of channels 
                if PARAMS.nch > 1
                    wr_data = reshape(wr_data, PARAMS.nch,...
                        length(wr_data)/PARAMS.nch);
                end
                
                % loop through each of the desired channels
                for c = 1:length(REMORA.hrp.ch)
                    
                    % current channel to process and data from said channel
                    PARAMS.ltsa.ch = REMORA.hrp.ch(c);   
                    ltsa_data = wr_data(PARAMS.ltsa.ch, :);

                    % globalize data for access in ltsa subroutines
    %                 PARAMS.proc.df = dfs(k);
    %                 PARAMS.ltsa.rfNum = j;

    %                 % update ltsa sample rate to suit this decimation factor
    %                 PARAMS.ltsa.fs = PARAMS.fs/dfs(k);
    %                 PARAMS.ltsa.sampPerAve = PARAMS.ltsa.tave * PARAMS.ltsa.fs;

                    % if making a new ltsa, start with writing the header
                    if j == 1 || resumeDisk

                        REMORA.hrp.outdir{k} = xwavPaths{k};
                        REMORA.hrp.outfile{k,c} = ltsaNames{k, c};

                        % don't erase file contents if resuming
                        if resumeDisk
                            REMORA.hrp.fod(k,c) = fopen(fullfile(REMORA.hrp.outdir{k}, ...
                                REMORA.hrp.outfile{k,c}),'r+');
                        % but do if starting from scratch    
                        else
                            REMORA.hrp.fod(k,c) = fopen(fullfile(REMORA.hrp.outdir{k}, ...
                                REMORA.hrp.outfile{k,c}),'w');
                        end

                        % todo eventually want to pass in the rf numbers from
                        % which this ltsa is being created. For the time being,
                        % it's handled by init_file_ltsaparams
                        init_file_ltsaparams(prefix, ndir, k, c, 1);

                        if j == 1
                            fprintf('\nFilename: %s\n', REMORA.hrp.outfile{k,c});
                            write_ltsahead;
                        end

                    end

                    init_file_ltsaparams(prefix, ndir, k, c, 0);

                    % seek to correct byte in output file
                    fseek(REMORA.hrp.fod(k,c),REMORA.hrp.byteloc{k}(j, 1),'bof');

                    % loop over number of averages
                    for n = 1:REMORA.hrp.nave(k)

                        % grab correct slice of data for the average
                        if n ~= REMORA.hrp.nave(k)
                            ltsa_data_ave = ltsa_data((n-1)*REMORA.hrp.sampPerAve(k)+1:n*REMORA.hrp.sampPerAve(k));
                        else
                            ltsa_data_ave = ltsa_data((n-1)*REMORA.hrp.sampPerAve(k)+1:end);
                        end
                        ltsa_data_ave = double(int16(ltsa_data_ave));              
                        calc_ltsa(ltsa_data_ave);
                    end

                    % finished writing this rf to ltsa; record ending byte loc 
                    ltsa_bytelocs(k,c) = ftell(REMORA.hrp.fod(k,c));  
                end
            end
            % finished writing this rf to xwav; record ending byte loc
            xwav_bytelocs(k) = ftell(fod(k));  
        end
        
        if PARAMS.dflag
           disp(['Raw File : ',num2str(j)])
        end
        
        % after each raw file is completely done being processed, save 
        % byte locations, curr rf #, and curr xwav #
        % backup file from previous iteration
        if exist(rd_mat, 'file')
            copyfile(rd_mat, rd_mat_back);
        end
        ltsa = PARAMS.ltsa;
        rf_start_ind = j+1;
        disk_start = i;
        save(rd_mat, 'rf_start_ind', 'disk_start', 'xwav_bytelocs',...
            'currXWAV', 'ltsa', 'xwav_names');
        clear ltsa;
        
        % reset resumeDisk so we just continue writing for the next raw file
        if resumeDisk
            resumeDisk = false;
        end
    end
    
    fclose(fid);
    
end
fclose('all');

% disable diary if we were using it 
if diary_bool
    diary off;
end

% reset fromProc variable so other triton functions can be used normally
PARAMS = rmfield(PARAMS, 'fromProc');

toc
% profile off;
% profsave(profile('info'), 'normal_profile_results');
end

