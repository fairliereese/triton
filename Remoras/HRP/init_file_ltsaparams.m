function init_file_ltsaparams(prefix, rfCount, k, c, init)

% will initialize parameters for ltsa creation that are specific to the
% ltsa file that is being made

global PARAMS REMORA

% have to calculate all variables if making a new file
if init
    
    % some data location info
    % TODO depending on what raw files go into this ltsa, index dirlist accordingly!
    PARAMS.ltsa.nrftot = rfCount;
    maxNrawfiles = PARAMS.ltsa.nrftot + 100;          % maximum number of raw files + a few more
    lhsz = 64;         % LTSA header size [bytes]
    rhsz = 64 + 40;    % LTSA rawfile header (directory) size (add 40 bytes for longer (upto 80 char) xwav files names
    datastart = rhsz * maxNrawfiles + lhsz;           % data start location in bytes
    
    % abbreviations to make calls easier
    numxwav = REMORA.hrp.xwavNums(k);
    rfperxwav = REMORA.hrp.rfCounts(k);
    df = REMORA.hrp.dfs(k);
    nsamp = (PARAMS.ltsahd.nsectPerRawFile * PARAMS.ltsa.blksz)...
        / PARAMS.ltsa.nch / df;

    % file info
    PARAMS.ltsa.outdir = REMORA.hrp.outdir{k};
    PARAMS.ltsa.outfile = REMORA.hrp.outfile{k,c};
    PARAMS.ltsa.fod = REMORA.hrp.fod(k,c);
    
    % update ltsa sample rate to suit this decimation factor
    REMORA.hrp.fs(k) = PARAMS.fs/df;
    REMORA.hrp.sampPerAve(k) = REMORA.hrp.tave(k) * REMORA.hrp.fs(k);
    
    % compute nfft (integer)
%     PARAMS.ltsa.nfft = floor(PARAMS.ltsa.fs / PARAMS.ltsa.dfreq);
%     disp_msg(['Number of samples for fft: ', num2str(PARAMS.ltsa.nfft)])
    REMORA.hrp.nfft(k) = floor(REMORA.hrp.fs(k) / REMORA.hrp.dfreq(k));

    % window size and overlap
%     PARAMS.ltsa.window = hanning(PARAMS.ltsa.nfft);
%     PARAMS.ltsa.overlap = 0;
%     PARAMS.ltsa.noverlap = round((PARAMS.ltsa.overlap/100)*PARAMS.ltsa.nfft);
    REMORA.hrp.window{k} = hanning(REMORA.hrp.nfft(k));
    REMORA.hrp.overlap(k) = 0;
    REMORA.hrp.noverlap(k) = round((REMORA.hrp.overlap(k)/100)*REMORA.hrp.nfft(k));

    % compute compression factor
%     PARAMS.ltsa.cfact = PARAMS.ltsa.tave * PARAMS.ltsa.fs / PARAMS.ltsa.nfft;
%     disp_msg(['XWAV to LTSA Compression Factor: ',num2str(PARAMS.ltsa.cfact)])
%     disp_msg(' ')
    REMORA.hrp.cfact(k) = REMORA.hrp.tave(k) * REMORA.hrp.fs(k) / REMORA.hrp.nfft(k);
    disp_msg(['XWAV to LTSA Compression Factor: ',num2str(REMORA.hrp.cfact)])
    disp_msg(' ')

    % compute number of frequencies in each spectral average:
%     if mod(PARAMS.ltsa.nfft,2) % odd
%         PARAMS.ltsa.nfreq = (PARAMS.ltsa.nfft + 1)/2;
%     else        % even
%         PARAMS.ltsa.nfreq = PARAMS.ltsa.nfft/2 + 1;
%     end
    if mod(REMORA.hrp.nfft(k),2) % odd
        REMORA.hrp.nfreq(k) = (REMORA.hrp.nfft(k) + 1)/2;
    else        % even
        REMORA.hrp.nfreq(k) = REMORA.hrp.nfft(k)/2 + 1;
    end
    
    % number of averages in each rf
    REMORA.hrp.nave(k) = ceil(nsamp/(REMORA.hrp.nfft(k) * REMORA.hrp.cfact(k)));

    % how many xwavs go into making up this ltsa?
    PARAMS.ltsa.nxwav = numxwav;

    % initialize some empty vectors to hold rf timing information
    PARAMS.ltsahd.year = zeros(1, rfCount); 
    PARAMS.ltsahd.month = zeros(1, rfCount);
    PARAMS.ltsahd.day = zeros(1, rfCount);
    PARAMS.ltsahd.hour = zeros(1, rfCount);
    PARAMS.ltsahd.minute = zeros(1, rfCount);
    PARAMS.ltsahd.secs = zeros(1, rfCount);
    PARAMS.ltsahd.ticks = zeros(1, rfCount);
    PARAMS.ltsahd.rfileid = zeros(1, rfCount);
    REMORA.hrp.fname{k} = char(zeros(PARAMS.ltsa.nxwav,80)); 

    % loop through directory list of raw HRP file to get timing info
    rfNum = 1;
    for i = 1:rfCount % TODO modify loop boundaries depending on which raw files in dirlist we're using

        % timing information
        PARAMS.ltsahd.year(i) = PARAMS.head.dirlist(i, 2);
        PARAMS.ltsahd.month(i) = PARAMS.head.dirlist(i, 3);
        PARAMS.ltsahd.day(i) = PARAMS.head.dirlist(i, 4);
        PARAMS.ltsahd.hour(i) = PARAMS.head.dirlist(i, 5);
        PARAMS.ltsahd.minute(i) = PARAMS.head.dirlist(i, 6);
        PARAMS.ltsahd.secs(i) = PARAMS.head.dirlist(i, 7);
        PARAMS.ltsahd.ticks(i) = PARAMS.head.dirlist(i, 8); 
        PARAMS.ltsahd.dnumStart(i) = datenum([PARAMS.ltsahd.year(i) PARAMS.ltsahd.month(i)...
                    PARAMS.ltsahd.day(i) PARAMS.ltsahd.hour(i) PARAMS.ltsahd.minute(i) ...
                    PARAMS.ltsahd.secs(i)+(PARAMS.ltsahd.ticks(i)/1000)]);

        % byte locations of data
        if i == 1
            REMORA.hrp.byteloc{k}(i,1) = datastart;
        else
            REMORA.hrp.byteloc{k}(i,1) = REMORA.hrp.byteloc{k}(i-1,1)+...
                REMORA.hrp.nave(k)*REMORA.hrp.nfreq(k)*1;
        end
        
        % make file names for the xwavs 
        if mod(i-1, rfperxwav) == 0

            % reset rf num counter
            rfNum = 1;

            % different file names for df = 1
            % create XWAV file name
            date = num2str(PARAMS.head.dirlist(i,2:4),'%02d');
            time = num2str(PARAMS.head.dirlist(i,5:7),'%02d');

            % add df to filename if df not 1
            if df ~= 1
                name = sprintf('%s%s_%s_df%d.x.wav', prefix,date,time,df);
            else
                name = sprintf('%s%s_%s.x.wav', prefix,date,time);
            end   

            % fix indexing!!! TODO
            % set file name in PARAMS struct
            REMORA.hrp.fname{k}(i, 1:length(name)) = name;

            currName = name;

        % if not generating a new name, just index the cell that has the same
        % name as the current raw file
        else
            REMORA.hrp.fname{k}(i, 1:length(currName)) = currName;
        end

        % raw file information
        PARAMS.ltsahd.rfileid(i) = rfNum;

        rfNum = rfNum + 1;
    end

    disp_msg(['Total number of raw files: ',num2str(PARAMS.ltsa.nrftot)])
    disp_msg(['LTSA version ',num2str(PARAMS.ltsa.ver)])
end

% adjust all PARAMS ltsa parameters to be consistent with the file we're on

% metadata
PARAMS.ltsa.window = REMORA.hrp.window{k};
PARAMS.ltsa.overlap = REMORA.hrp.overlap(k);
PARAMS.ltsa.noverlap = REMORA.hrp.noverlap(k);
PARAMS.ltsa.byteloc = REMORA.hrp.byteloc{k};
PARAMS.ltsa.nave = REMORA.hrp.nave(k);
PARAMS.ltsa.sampPerAve = REMORA.hrp.sampPerAve(k);
PARAMS.ltsa.nfft = REMORA.hrp.nfft(k);
PARAMS.ltsa.fs = REMORA.hrp.fs(k);
PARAMS.ltsa.cfact = REMORA.hrp.cfact(k);
PARAMS.ltsa.nfreq = REMORA.hrp.nfreq(k);
PARAMS.ltsahd.fname = REMORA.hrp.fname{k};
PARAMS.ltsa.tave = REMORA.hrp.tave(k);
PARAMS.ltsa.dfreq = REMORA.hrp.dfreq(k);

% file info
PARAMS.ltsa.outdir = REMORA.hrp.outdir{k};
PARAMS.ltsa.outfile = REMORA.hrp.outfile{k,c};
PARAMS.ltsa.fod = REMORA.hrp.fod(k,c);

end
