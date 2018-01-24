function ckFirmware()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sets variable values based on what firmware version the HRP file comes
% from
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global PARAMS
vnum = PARAMS.head.firmwareVersion;
%vnum = 'V2.10L';

% make sure we switch back to correct directory after reading table in
curr_dir = pwd;
path = fileparts(which('triton'));
cd(fullfile(path, 'Remoras\HRP'));

fwTable = readtable('table_ckFirmware.csv', 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f');

fwCell = table2cell(fwTable);

% loop through rows of table to find matching vnum entry
for i = 1:size(fwCell, 1) 
    if any(findstr(vnum, fwCell{i, 1})) == 1
        vInd = i; % firmware version row index
    end
end

PARAMS.cflag = fwCell{vInd, 2}; % 2 = cflag ind
PARAMS.ctype = fwCell{vInd, 3}; % 3 = ctype ind
PARAMS.nch = fwCell{vInd, 4}; % 4 = nch ind
PARAMS.fs = fwCell{vInd, 5}; % 5 = sample rate ind
PARAMS.SATA_bool = fwCell{vInd, 6}; % 6 = SATA_bool ind
PARAMS.nsampPerRawFile = fwCell{vInd, 7}; % 7 = samples/raw file ind
PARAMS.nsampPerSect = fwCell{vInd, 8}; % 8 = samples/sector ind
PARAMS.nBits = fwCell{vInd, 9}; % 9 = bits per sample
PARAMS.nsectPerRawFile = fwCell{vInd, 10};  % 10 = sectors/raw file
PARAMS.nBytesPerSect = fwCell{vInd, 11}; % 11 = bytes/sect
PARAMS.compressionFactor = fwCell{vInd, 12}; % 12 = compression factor
PARAMS.tailblk = fwCell{vInd, 13}; % 13 = 0 padding on tail

% Things to print out if issues are encountered
% disp(vnum);
% 
% fprintf('cflag : %d \n', PARAMS.cflag);
% fprintf('ctype : %d \n', PARAMS.ctype);
% fprintf('fs : %d \n', PARAMS.fs);
% fprintf('nch : %d \n', PARAMS.nch);
% fprintf('nsampPerRawFile : %d \n', PARAMS.nsampPerRawFile);
% fprintf('nsampPerSect : %d \n', PARAMS.nsampPerSect);
% fprintf('nBits : %d \n', PARAMS.nBits);
% fprintf('nsectPerRawFile : %d \n', PARAMS.nsectPerRawFile);
% fprintf('compressionFactor : %d \n', PARAMS.compressionFactor);
% fprintf('tailblk : %d \n', PARAMS.tailblk);

cd(curr_dir);

end

