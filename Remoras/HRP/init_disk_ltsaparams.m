function ltsaNames = init_disk_ltsaparams(disk, dfs, prefix)

% will initialize parameters for ltsa creation that are specific to the
% disk that is being processed
% fairlie reese 19/07/2017

global PARAMS REMORA

% information pulled from ckFirmware
PARAMS.ltsa.nBits = PARAMS.nBits;
PARAMS.ltsa.nch = PARAMS.nch;
PARAMS.ltsahd.nsectPerRawFile = PARAMS.nsectPerRawFile; 

% compute dbtype
if PARAMS.ltsa.nBits == 16
    PARAMS.ltsa.dbtype = 'int16';
elseif PARAMS.ltsa.nBits == 32
    PARAMS.ltsa.dbtype = 'int32';
else
    disp_msg('PARAMS.ltsa.nBits = ')
    disp_msg(PARAMS.ltsa.nBits)
    disp_msg('not supported')
    return
end

% number of samples per data 'block' HARP=1sector(512bytes), ARP=64kB
% HARP data => 12 byte header
% this block pulled from ck_ltsaparams, but don't need other dtypes bc
% always coming from raw files in procstream so left out outer if else
% block
if PARAMS.ltsa.nch == 1
    PARAMS.ltsa.blksz = (512 - 12)/2; % number bytes per sector / bytes per sample
elseif PARAMS.ltsa.nch == 4
    PARAMS.ltsa.blksz = (512 - 12 - 4)/2; 
else
    disp_msg('ERROR -- number of channels not 1 nor 4')
    disp_msg(['nchan = ',num2str(PARAMS.ltsa.nch)])
end

% ltsa version number
PARAMS.ltsa.ver = 4;

% make file names for each of the ltsas generated for the disk
ltsaNames = cell(length(dfs), 1);
for i = 1:length(dfs)
    for c = 1:length(REMORA.hrp.ch)
        p = sprintf('%sdisk_%s_%is_%iHz',prefix,disk,...
            REMORA.hrp.tave(i),REMORA.hrp.dfreq(i));
        if dfs(i) ~= 1
            p = sprintf('%s_df%i',p,dfs(i));
        end
        if PARAMS.nch ~= 1
            p = sprintf('%s_ch%i',p,REMORA.hrp.ch(c));
        end

        ltsaNames{i, c} = sprintf('%s.ltsa',p);
    end
end

% create empty struct fields to fill in later 
% variables with len(dfs) fields
REMORA.hrp.window = cell(1, length(REMORA.hrp.dfs));
REMORA.hrp.overlap = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.noverlap = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.outdir = cell(1, length(REMORA.hrp.dfs));
REMORA.hrp.outfile = cell(length(REMORA.hrp.dfs),length(REMORA.hrp.ch));
REMORA.hrp.fod = zeros(length(REMORA.hrp.dfs),length(REMORA.hrp.ch));
REMORA.hrp.sampPerAve = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.nfft = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.fs = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.nfreq = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.cfact = zeros(1, length(REMORA.hrp.dfs));

% variables with fields for each rf 
REMORA.hrp.byteloc = cell(1, length(REMORA.hrp.dfs));
REMORA.hrp.nave = zeros(1, length(REMORA.hrp.dfs));
REMORA.hrp.fname = cell(1, length(REMORA.hrp.dfs));


end