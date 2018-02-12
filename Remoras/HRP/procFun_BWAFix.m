function procFun_BWAFix


% todo: really should be storing all pertinent globals in the REMORA struct
profile on;

global PARAMS REMORA

% some gui stuff here, what do you want done? What files? Etc
% keep it as user input for now
% files = ['CINMS_B_32_disk02.hrp'];

dataID = 'SOCAL_T_02'; % todo, again need to find a better way of doing this
siteName = 'T';
dpln = '02';
projName = 'SOCAL';

PARAMS.proc.path = 'E:\';
ipath = PARAMS.proc.path;
headerfile = fullfile('E:\',  'SOCAL_T_02.prm');
disks = [ 2 ]; 
PARAMS.proc.hrpFiles = arrayfun(@(x) sprintf('%s_disk%02d.hrp',dataID, x),disks,'UniformOutput',false);
files = PARAMS.proc.hrpFiles;
stdOut = fullfile(PARAMS.proc.path,sprintf('%s_stdOut_170830.log',dataID));
diary(stdOut);
opath = { 
    'D:\Fix_df1_170830\';  % one for each decimation factor
%     'D:\Fix_df1_20_100\';
%     'D:\Fix_df1_20_100\' 
};

% dfs = [1,20,100]; % decimation factors
% PARAMS.df = dfs;
% 
% ltsas = [0, 0,0]; % boolean values for whether we want to make corresponding ltsas
% PARAMS.ltsa.ch = 1; % TODO this needs to be an option when making from multichannel data
% REMORA.hrp.tave = [5, 5,5]; % currently these need to be same size as ltsas boolean array...even if not used
% REMORA.hrp.dfreq = [200, 200,5]; % currently these need to be same size as ltsas boolean array...even if not used
dfs = [1]; % decimation factors
PARAMS.df = dfs;

ltsas = [0]; % boolean values for whether we want to make corresponding ltsas
PARAMS.ltsa.ch = 1; % TODO this needs to be an option when making from multichannel data
REMORA.hrp.tave = [5]; % currently these need to be same size as ltsas boolean array...even if not used
REMORA.hrp.dfreq = [200]; % currently these need to be same size as ltsas boolean array...even if not used
PARAMS.ltsa.ftype = 2; % always coming from HRP data for the purpose of this subroutine

fixTimes = false;
PARAMS.dflag = true;
PARAMS.fromProc = true;

% dump some info to user
fprintf('Data ID = %s\nProject = %s\nSite = %s\nDeployment = %s', ...
    dataID, projName, siteName, dpln); 
fprintf('\tParam File = %s\n', headerfile);
fprintf('Decimation factors:\n');
fprintf('\t%d\n', PARAMS.df);
fprintf('LTSAs:\tMake\tTime Bin\tFrequency Bin\n');
arrayfun(@(x,y,z) fprintf('\t%d\t%d\t%d\n',x,y,z),...
    ltsas,REMORA.hrp.tave, REMORA.hrp.dfreq);

fprintf('Processing Disks:\n');
cellfun(@(x) fprintf('\t%s\n', x), PARAMS.proc.hrpFiles);
fprintf('Output Directories:\n'); 
cellfun(@(x) fprintf('\t%s\n',x), opath);

headblk = 12;

% read in metadata from .hrd/.prm file TODO this is stupid and there should
% be a better way of doing it
read_xwavHDRfile(headerfile,0);


rf0 = nan(length(dfs),1); % used for BWA fix 
rfn = nan(length(dfs),1);
% for each disk being processed
for i = 1:size(files, 1)
    PARAMS.error.csl = 0;
    
    inhrp = fullfile(ipath, PARAMS.proc.hrpFiles{i});
    fprintf('Processing Disk %s.......\n', inhrp); 
    
    % check to see if there's a list of modified dirlist times
    disk = disks(i);
    useMod = 0;
    % todo figure out a way here to just take off the file extenstion
    % also todo - would be easier to check for each disk's before doing
    % anything so that user can step away from program
    [ p, r, e ] = fileparts(inhrp);
    modName = sprintf('%s_modifiedDirListTimes.mat', r);
    if exist(fullfile(ipath, modName), 'file') == 2
        % user decision - use changed times?
        useMod = ...
        questdlg(sprintf('Modified directory list times found for disk %s, use?',...
        disk));
    end
    
    % load in directory list times and firmware information
    PARAMS.proc.currHRP = inhrp;
    read_rawHARPdir(inhrp, 0);
    ckFirmware;
    prefix = sprintf('%s_%s_%s_', projName, siteName, dpln);
  
    % for BWA fix
    y = datenum([ PARAMS.head.dirlist(:,2:6) ...
        PARAMS.head.dirlist(:,7)+PARAMS.head.dirlist(:,8)/1000 ]);
    newMetaData = zeros(length(y),2); % [ new rf start (dnum0), number of samples in rf ]
    BWAdata = [];
    BWAcsectInfo = [];
    
    % make necessary directories
%     xwavPaths = mk_directories(ipath, disk, dataID, dfs);
    xwavPaths = mk_directories(opath, disk, dataID, dfs);
    
    % replace dirlist with modified one TODO questdlg is stupid and we
    % should make our own BOOLEAN returning gui so this stupid if statement
    % can be collapsed
    % todo: add somethings with PARAMS.proc.bwFix here
    if useMod
        if strcmp(useMod, 'Yes')
            load_modhdrs(fullfile(ipath, modName));
        elseif fixTimes
            fix_dirlistTimes;
        end
    elseif fixTimes
        fix_dirlistTimes;
    end
    
    1;
    
    % if making ltsas, generate their names and initialize ltsa vars
    % specific to the disk we're on
    ltsaNames = init_disk_ltsaparams(disk, dfs, prefix);
    
    % get the number of raw files per xwav
%     [ndir, xwavNums, rfCounts] = get_rfNums(filename, dfs);
%     rfCounts_copy = rfCounts;


    if 1  % for debugging set range of rf
        j0 = 65101;
        ndir0 = PARAMS.head.nextFile;
        fprintf('------------- Starting processing at Raw File #%d\n', j0);
        fprintf('------------- Ending processing at Raw File #%d\n', ndir0);
    else        
        j0 = 1;
        ndir0 = PARAMS.head.nextFile; 
    end

    [ndir, REMORA.hrp.xwavNums, rfCounts] = get_rfNums(inhrp, dfs, ndir0);
    REMORA.hrp.rfCounts = rfCounts;
    
    % fods (one for each df)
    fod = zeros(1, length(dfs));

    % open raw files
    fid = fopen(inhrp, 'r');
    
    % loop over each raw file
    currXWAV = zeros(1, length(dfs)); % current XWAV being generated

    for j = j0:ndir 
        fprintf('Raw File: %d...\n\n',j);       
        
        % raw file operations, skip to start of raw file
        status = fseek(fid,PARAMS.head.dirlist(j,1)*512,'bof');
        if status ~= 0
            disp(['Error - failed fseek to byte ',num2str(PARAMS.head.dirlist(j,1)*512)])
            fclose('all');
            return
        end
        
        % xwav file reading operations
        if ~PARAMS.cflag % non compression, 4 ch
            % loop over sectors in raw file 
            for m = 1:PARAMS.head.dirlist(j, 10)
                fseek(fid, headblk, 0); % skip over header, assume time is good
                if PARAMS.nch == 4
                    data = fread(fid, PARAMS.nsampPerSect,'uint16')-32767;
                else
                    data = fread(fid, PARAMS.nsampPerSect,'int16');
                end
                fseek(fid,PARAMS.tailblk,0);   % skip over tail bytes (=0 for nchan=1, =4 for nchan=4)
            end
        else        
            % compression
            % read in data for current raw file
            [ data, csectInfo ] = decompressRawHRP_170607(fid,j,PARAMS.ctype);            
            
            % check for decompression weirdness
            [ data, csectInfo ] = validateDecompresssion_170724(data, csectInfo);
            
            if j == ndir
                nrfnext = 0; 
            else
                nrfnext = 1; % number of raw files to read timing info from for BWA fix
            end
                
            [ data, newTime0, nGoodSamp, BWAdata, BWAcsectInfo ] = ...
                fixBWA_170816(j,fid,data, csectInfo, BWAdata, BWAcsectInfo, nrfnext );
            
            newMetaData(j,:) = [ newTime0, nGoodSamp ];

            
        end
        
        % loop over each decimation factor
        for k = 1:length(dfs)
            

            % make new xwav file
            if mod(j-1, rfCounts(k)) == 0 
                                
                % inc. XWAV # currently making
                currXWAV(k) = currXWAV(k) + 1;
                                                      
                % for BWA fix
                rfn(k)=j-1;
                
                if currXWAV(k) ~= 1
                
                    % do something
                    frewind(fod(k));
                    % should make more flexible...what if we wrap so much we lose an
                    % entire RF?

                    gsamps = newMetaData(rf0(k):rfn(k),2)./dfs(k);
                    gtimes = newMetaData(rf0(k):rfn(k),1);
                    fs = PARAMS.head.samplerate/dfs(k);
                    if sum(rem(gsamps,1))~= 0
                        fprintf('Partial number of decimated samps rounding up!\n');
                        gsamps = ceil(gsamps); % decimate rounds up
                    end
                    write_XWAVhead_BWFix_170620(fod(k), REMORA.hrp.rfCounts(k), gtimes, gsamps,fs);
                    
                    [offn,~,~,~] = fopen(fod(k)); % get old filename                        

                    ST = fclose(fod(k));
                    if ST < 0
                        fprintf('Could not close file %s\n', offn); 
                        return
                    end
                    
                    % change filename to include new timing                             
                    timew = datestr(gtimes(1),'HHMMSS');
                    datew = datestr(gtimes(1),'yymmdd');
                     if dfs(k) ~= 1
                        nofn = sprintf('%s%s_%s_df%d.x.wav', prefix,datew,timew,dfs(k));
                    else
                        nofn = sprintf('%s%s_%s.x.wav', prefix,datew,timew);
                    end                                           
                    noffn = fullfile(xwavPaths{1, k},nofn);
                    % if names don't match, rename output file!
                    if ~strcmp(offn, noffn)
                        movefile(offn, noffn);
                    end

                    rf0(k)=j;               
                else
                    rf0(k)=j;
                end
                
                % first raw file header in XWAV
%                 fhdr = rfCounts(k) * (currXWAV(k)-1) + 1;
                fhdr = j;
         
                1;
                
                % create XWAV file name
                date = num2str(PARAMS.head.dirlist(fhdr,2:4),'%02d');
                time = num2str(PARAMS.head.dirlist(fhdr,5:7),'%02d');
                % add df to filename if df not 1
                if dfs(k) ~= 1
                    name = sprintf('%s%s_%s_df%d.x.wav', prefix,date,time,dfs(k));
                else
                    name = sprintf('%s%s_%s.x.wav', prefix,date,time);
                end
                % open new xwav
                fod(k) = fopen(fullfile(xwavPaths{1, k}, name), 'w');
                
                % change nrf for the last file if needed
%                 if currXWAV(k) == REMORA.hrp.xwavNums(k)
                if ndir-j < REMORA.hrp.rfCounts(k)
                    REMORA.hrp.rfCounts(k) = ndir - j + 1; 
                end
                
                if PARAMS.dflag
                    fprintf('\nFilename: %s \nXWAV file %s out of %s\n', ...
                        name, num2str(currXWAV(k)), num2str(REMORA.hrp.xwavNums(k)));
                end
                
                % write XWAV header info
                write_XWAVhead_modified(fod(k),fhdr,REMORA.hrp.rfCounts(k),k);
            end
             
% this doesn't work right, we're resetting data so not decimating original
% data anymore
%             if dfs(k) ~= 1
%                 data = decimate(data, dfs(k));
%             end
            
%             % finally, write to xwav
%             fwrite(fod(k),data,'int16');
            
            fwrite(fod(k),decimate(data, dfs(k)),'int16');
            
            % if making ltsas
            if ltsas(k)
                
                % globalize data for access in ltsa subroutines
                PARAMS.proc.data = data;
                PARAMS.proc.df = dfs(k);
                PARAMS.ltsa.rfNum = j;
                
%                 % update ltsa sample rate to suit this decimation factor
%                 PARAMS.ltsa.fs = PARAMS.fs/dfs(k);
%                 PARAMS.ltsa.sampPerAve = PARAMS.ltsa.tave * PARAMS.ltsa.fs;
                
                % if making a new ltsa, start with writing the header
                if j == 1
                    
                    % globalize some more data
%                     PARAMS.ltsa.outdir = xwavPaths{1, k};
%                     PARAMS.ltsa.outfile = ltsaNames{k, :};
%                     PARAMS.ltsa.fod = fopen(fullfile(PARAMS.ltsa.outdir, ...
%                         PARAMS.ltsa.outfile),'w');
%                     
%                     fprintf('\nFilename: %s\n', PARAMS.ltsa.outfile);

                    REMORA.hrp.outdir{k} = xwavPaths{1, k};
                    REMORA.hrp.outfile{k} = ltsaNames{k, :};
                    REMORA.hrp.fod(k) = fopen(fullfile(REMORA.hrp.outdir{k}, ...
                        REMORA.hrp.outfile{k}),'w');
                    
                    fprintf('\nFilename: %s\n', REMORA.hrp.outfile{k});
                    
                    % todo eventually want to pass in the rf numbers from
                    % which this ltsa is being created. For the time being,
                    % it's handled by init_file_ltsaparams
%                     tic
                    init_file_ltsaparams(prefix, ndir, k, 1);
%                     disp('time for init file ltsaparams to run');
%                     toc
                    
%                     tic
                    write_ltsahead;
%                     disp('time for write ltsahead to run');
%                     toc
                end
                
                init_file_ltsaparams(prefix, ndir, k, 0);
%                 tic

                % seek to correct byte in output file
                fseek(REMORA.hrp.fod(k),REMORA.hrp.byteloc{k}(j, 1),'bof');
                
                % loop over number of averages
                for n = 1:REMORA.hrp.nave(k)
                                       
                    % grab correct slice of data for the average
                    ltsa_data = data((n-1)*REMORA.hrp.sampPerAve(k) + 1:n*REMORA.hrp.sampPerAve(k));
                    ltsa_data = double(int16(ltsa_data));
                    
                    calc_ltsa(ltsa_data);
    %                 disp('time for calc ltsa to run');
    %                 toc
                end
            end
            
            % for BWA fix, last xwav of disk
            if j == ndir
                % do something
                frewind(fod(k));
                % should make more flexible...what if we wrap so much we lose an
                % entire RF?
                
                rfn(k) = ndir;
                gsamps = newMetaData(rf0(k):rfn(k),2)./dfs(k);
                gtimes = newMetaData(rf0(k):rfn(k),1);
                fs = PARAMS.head.samplerate/dfs(k);
                if sum(rem(gsamps,1))~= 0
                    fprintf('Partial number of decimated samps rounding up!\n');
                    gsamps = ceil(gsamps); % decimate rounds up
                end
                write_XWAVhead_BWFix_170620(fod(k), REMORA.hrp.rfCounts(k), gtimes, gsamps,fs);
                [offn,~,~,~] = fopen(fod(k)); % get old filename

                ST = fclose(fod(k));
                if ST < 0
                    fprintf('Could not close file %s\n', offn);
                    return
                end
                
                % change filename to include new timing
                
                timew = datestr(gtimes(1),'HHMMSS');
                datew = datestr(gtimes(1),'yymmdd');
                if dfs(k) ~= 1
                    nofn = sprintf('%s%s_%s_df%d.x.wav', prefix,datew,timew,dfs(k));
                else
                    nofn = sprintf('%s%s_%s.x.wav', prefix,datew,timew);
                end
                noffn = fullfile(xwavPaths{1, k},nofn);
                % if names don't match, rename output file!
                if ~strcmp(offn, noffn)
                    movefile(offn, noffn);
                end
            end
            
        end
        
    end
    fclose(fid);
end
fclose('all');

% reset fromProc variable so other triton functions can be used normally
PARAMS = rmfield(PARAMS, 'fromProc');

profile off;
profsave(profile('info'), opath{1}); % put it in first xwav directory
diary off
end


