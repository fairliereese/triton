function write_XWAVhead_modified(fod,fhdr,nhrp,fnum)
%
%   useage: >> write_XWAVhead(fod,fhdr,nhrp,fnum)
%   fod == XWAV output file id... should be open from calling program
%   fhdr == first header in raw file corresponding to first data in XWAV
%   nhrp == number of raw files used to make XWAV file (should be 30 or
%   less)
%   fnum == which XWAV is being processed currently. Used to index PARAMS
%   variables correctly. This option is only needed if preparing more than
%   one type of XWAV (ie normal and d10 and d100). 
%   df == array of decimation factors. Usually will just be passed in as 1 to give
%   full range of information; will only be a vector when using batch
%   processing as we may want xwavs of different decimation factors.
%   Indexed accordingly with fnum.
%
%   smw 050920
%
% added fixes for compression data
% based on OneReadMultiWrites code
% 101203 smw
%
%  changed to make compatible with the processing stream code (added the
%  fnum and df parameters and altered code to support it)
%  27.06.2017 fr
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Past history (stolen from wrxwavhd:
% wrxwavhd - write xwav header
%
% stolen from obs2xwav.m
% smw 20 Oct, 2004
%
% 10/18/04 smw - 32-bit, preamp gains, AGC applied.
%
% 10/4/04 smw - ripped off from bin2xwav.m
%
% ripped off of hrp2wav.m which was ripped off from bin2wav.m
%
% convert *.bin (ARP binary) files into *.wav (pseudo wav) files
%
% hardwired for MAWSON ARP data
%
% 6 Aug, 04 smw make two smaller files (fit on CD 700MB) from larger 1GB
% file and put into triton v1.50
%
% 5 Aug, 04 smw update to current header format
%
% 07/22/04 yhl implemented the harp header.  Put arbitary data into the
% header (based on the real information from score 15)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS REMORA

% if from the processing stream, we'll have df in a global
if ~isfield(PARAMS, 'fromProc')
   df = 1;
else
   df = REMORA.hrp.dfs(fnum);
end

% sample rate 
fs = PARAMS.fs/df;

% wav file header parameters
% RIFF Header stuff:
harpsize = nhrp * 32 + 64 - 8;% length of the harp chunk

% HARP Write Header info (one listing per write)
byteloc = (8+4) + (8+16) + 64 + (32 * nhrp) + 8;
% writelength = 1;            % use total number of blocks
% Format Chunk stuff:
fsize = 16;  % format chunk size
fcode = 1;   % compression code (PCM = 1)

PARAMS.nBits = 16;
% number of channels is now read in read_rawHARPhead.m
PARAMS.samp.byte = floor(PARAMS.nBits/8);
PARAMS.xhd.ByteRate = fs * PARAMS.nch * PARAMS.samp.byte;
PARAMS.xhd.BytePerSampleSlice = PARAMS.nch * PARAMS.samp.byte; % ie BlockAlign
PARAMS.xhd.WavVersionNumber = 1;
PARAMS.xgain(1) = 1;


% TODO same ckFirmware thing here 
% number of samples in sector depends on number of channels (ie firmware)
if ~isfield(PARAMS, 'nsampPerSect')
    if PARAMS.nch == 1
        PARAMS.nsampPerSect = 250;
    elseif PARAMS.nch == 4
        PARAMS.nsampPerSect = 248;
    else
        disp_msg('ERROR : Unsupported number of Channels')
        disp_msg(['nch = ',num2str(PARAMS.nch)])
    end
end
% number of bytes per sector
% nbytesPerSect = nsampPerSect * PARAMS.samp.byte;
% number of samples per raw file

% TODO should the following block stay commented out? Most of this 
% info can be gotten from ckFirmware anyway...
if ~isfield(PARAMS, 'nsampPerRawFile')
    if PARAMS.nch == 1
        if fs == 320000
            PARAMS.nsampPerRawFile = 14e6;
        elseif fs <= 200000
            PARAMS.nsampPerRawFile = 15e6;
        else
            errodlg('Unknown Sample Rate!')
        end
    elseif PARAMS.nch == 4
        PARAMS.nsampPerRawFile = 14384000;
    end
end

% TODO same ckFirmware deal with this one
if ~isfield(PARAMS, 'nsectPerRawFile')
    PARAMS.nsectPerRawFile = PARAMS.nsampPerRawFile / PARAMS.nsampPerSect;
end

% number of bytes per raw file
nbytesPerRawFile = PARAMS.samp.byte * PARAMS.nsampPerRawFile;

% number of samples per XWAV file
PARAMS.nsamp = nhrp * PARAMS.nsampPerRawFile / df;
bytelength = PARAMS.nsamp * PARAMS.nBits/8;

wavsize = bytelength+36+harpsize+8;  % required for the RIFF header

% HARP Write Header info (one listing per write)
PARAMS.xhd.byte_loc = 8+4+8+16+64+32+8;

% write xwav file header
%
% RIFF file header
fprintf(fod,'%c','R');
fprintf(fod,'%c','I');
fprintf(fod,'%c','F');
fprintf(fod,'%c','F');
fwrite(fod,wavsize,'uint32');
fprintf(fod,'%c','W');
fprintf(fod,'%c','A');
fprintf(fod,'%c','V');
fprintf(fod,'%c','E');

%
% Format information
fprintf(fod,'%c','f');
fprintf(fod,'%c','m');
fprintf(fod,'%c','t');
fprintf(fod,'%c',' ');
fwrite(fod,fsize,'uint32');
fwrite(fod,fcode,'uint16');
fwrite(fod,PARAMS.nch,'uint16');         
fwrite(fod,fs,'uint32');
fwrite(fod,PARAMS.xhd.ByteRate,'uint32');
fwrite(fod,PARAMS.xhd.BytePerSampleSlice,'uint16');
fwrite(fod,PARAMS.nBits,'uint16');

%
% "harp" chunk
fprintf(fod,'%c', 'h');
fprintf(fod,'%c', 'a');
fprintf(fod,'%c', 'r');
fprintf(fod,'%c', 'p');
fwrite(fod, harpsize, 'uint32');
fwrite(fod, PARAMS.xhd.WavVersionNumber , 'uchar');
fprintf(fod, '%c', PARAMS.head.firmwareVersion);     % 10 char
fprintf(fod, '%c', PARAMS.xhd.InstrumentID);    % 4 char
fprintf(fod, '%c', PARAMS.xhd.SiteName);        % 4 char
fprintf(fod, '%c', PARAMS.xhd.ExperimentName);  % 8 char
fwrite(fod, PARAMS.head.disknumberSector2, 'uchar');

% hardwired for read in xwav with bad values? smw 050126
DiskSerialNumber = '12345678'; % disk serial number
fprintf(fod, '%c', DiskSerialNumber);


fwrite(fod, nhrp, 'uint16');
fwrite(fod, PARAMS.xhd.Longitude, 'int32');
fwrite(fod, PARAMS.xhd.Latitude, 'int32');
fwrite(fod, PARAMS.xhd.Depth, 'int16');
fwrite(fod, 0, 'uchar');   % padding
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');
fwrite(fod, 0, 'uchar');

for k = 1:nhrp
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,2) , 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,3), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,4), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,5), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,6), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,7), 'uchar');
    fwrite(fod, PARAMS.head.dirlist(fhdr+k-1,8), 'uint16');
    % byte location of raw file k in this xwav
    if k > 1
        %         fwrite(fod, byteloc + sum(PARAMS.head.dirlist(fhdr:fhdr+k-2,10))*nbytesPerSect, 'uint32');
        fwrite(fod, byteloc + nbytesPerRawFile * (k-1)/df, 'uint32');
    else
        fwrite(fod, byteloc , 'uint32');
    end

    fwrite(fod, nbytesPerRawFile/df, 'uint32');
    fwrite(fod, PARAMS.nsectPerRawFile/df, 'uint32');
    fwrite(fod, fs, 'uint32');
    fwrite(fod, PARAMS.xgain(1), 'uint8');
    fwrite(fod, 0, 'uchar'); % padding
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
    fwrite(fod, 0, 'uchar');
end

% Data area -- variable length
fprintf(fod,'%c','d');
fprintf(fod,'%c','a');
fprintf(fod,'%c','t');
fprintf(fod,'%c','a');
fwrite(fod,bytelength,'uint32');

