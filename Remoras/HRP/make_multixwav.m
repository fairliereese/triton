% make_multixwav.m
%
% script to run write_hrp2xwavs over many hrp files to make xwavs

cflag = 0;

% which files to process?
hrp_dir = uigetdir(pwd, 'Select HRP file directory');
files = cellstr(ls(horzcat(hrp_dir, '\*hrp')));
if hrp_dir == 0 % if cancel button pushed
    disp_msg('Cancel button pushed')
    cflag = 1;
end

% header
[header, path] = uigetfile('*.hdr', 'Select XWAV header file');
header_path = fullfile(path, header);
if header == 0	% if cancel button pushed
    disp_msg('Cancel button pushed')
    cflag = 1;
end
    
% out dir
out_dir = uigetdir(pwd, 'Select Directory to output XWAVS');
if out_dir == 0	% if cancel button pushed
    disp_msg('Cancel button pushed')
    cflag = 1;
end

% display obtained names in message window
disp_msg(['Input file directory = ',hrp_dir])
disp_msg(['XWAV Header FileName = ',header_path])
disp_msg(['XWAV DirectoryName = ',out_dir])
d = 1;  % display progress info

% do we want to save output?
logflag = 1;
if logflag == 1
    % read XWAV header file info - need this first
    read_xwavHDRfile(header_path,0);
    %
    % remove blanks
    ename = deblank(PARAMS.xhd.ExperimentName);
    sname = deblank(PARAMS.xhd.SiteName);
    if strcmp(sname,'XXXX')
        prefix = [ename,'_'];
    else
        prefix = [ename,'_',sname,'_'];
    end
    
    if ispc % if PC/Windows OS
        fname = [out_dir,'\',prefix,'log'];
    else
        fname = [outdir,prefix, 'log'];
    end
  
    % start logging
    diary(fname);
end

% loop through each file and run the conversion
if ~cflag
    for i=1:length(files)
        file = char(fullfile(hrp_dir,files(i)));
        write_hrp2xwavs(file,header_path,out_dir,d)
    end
end

% finish logging
if logflag == 1
    diary off;
end
 
