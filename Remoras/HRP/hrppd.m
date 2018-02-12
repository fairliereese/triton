function hrppd(action)
global HANDLES PARAMS
if strcmp(action,'convert_multiHRP2XWAVS')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    make_multixwav;
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'convert_HRP2XWAVS')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    % get HRP input file name
    [fname,fpath]=uigetfile('*.hrp','Select HRP file to convert to XWAVS');
    infilename = [fpath,fname];
    cflag = 0;
    % if the cancel button is pushed
    if strcmp(num2str(fname),'0')
        disp_msg('Cancel button pushed')
        cflag = 1;
    end
    % get HDR XWAV header file name
    [fname,fpath]=uigetfile({'*.hdr;*.prm'}, 'Select XWAV Header file'); 
    hdrfilename = [fpath,fname];
    % if the cancel button is pushed
    if strcmp(num2str(fname),'0')
        disp_msg('Cancel button pushed')
        cflag = 1;
    end
    % get XWAV directory name
    outdir = uigetdir(PARAMS.inpath,'Select Directory to output XWAVs');
    if outdir == 0	% if cancel button pushed
        disp_msg('Cancel button pushed')
        cflag = 1;
    end
    % display obtained names in message window
    disp_msg(['Input FileName = ',infilename])
    disp_msg(['XWAV Header FileName = ',hdrfilename])
    disp_msg(['XWAV DirectoryName = ',outdir])
    d = 1;  % display progress info
    if ~cflag
        write_hrp2xwavs(infilename,hdrfilename,outdir,d)
    end
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'get_HRPhead')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    % need gui input here
    d = 1;      % d=1: display output to command window
    [fname,fpath]=uigetfile('*.hrp','Select HRP file to read disk Header');
    filename = [fpath,fname];
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(fname),'0')
        return
    else % get raw HARP disk header
        read_rawHARPhead(filename,d)
    end

    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'get_HRPdir')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    if isfield(PARAMS, 'head')
        PARAMS = rmfield(PARAMS, 'head');
    end
   
    d = 1;      % d=1: display output to command window
    [fname,fpath]=uigetfile('*.hrp','Select HRP file to read disk Directory');
    filename = [fpath,fname];
    if isfield(PARAMS, 'head')
        PARAMS = rmfield(PARAMS, 'head');
    end
    % if the cancel button is pushed, then no file is loaded so exit this script
    if strcmp(num2str(fname),'0')
        return
    else % get raw HARP disk directory
        read_rawHARPdir(filename,d)
    end
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'ck_dirlist_times')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    
    
    prompt={'Whole directory [0] or One File [1] : '};

    def={num2str(1)};

    dlgTitle='Difftime One HRP Head File or Whole Directory ?';
    lineNo=1;
    AddOpts.Resize='on';
    AddOpts.WindowStyle='normal';
    AddOpts.Interpreter='tex';
    % display input dialog box window
    in=inputdlg(prompt,dlgTitle,lineNo,def,AddOpts);
    if isempty(in)	% if cancel button pushed
        disp_msg('Cancel button pushed')
        return
    else
        fflag = str2num(deal(in{1}));
    end
    
    if fflag == 1   % only one file
        [fname,fpath]=uigetfile('*.hrp','Select HRP HEAD file to Check Directory Listing Times');
        filename = [fpath,fname];
        
        % if the cancel button is pushed, then no file is loaded so exit this script
        if strcmp(num2str(fname),'0')
            disp_msg('Cancel button pushed')
            return
        end
        
        check_dirlist_times(fullfile(fpath, fname))
        
    elseif fflag == 0   % all *.head.hrp in directory
        PARAMS.headall = [];
        PARAMS.inpath = uigetdir(PARAMS.inpath,'Select Directory with *.hrp files');
        if PARAMS.inpath == 0	% if cancel button pushed
            disp_msg('Cancel button pushed')
            return
        else
            d = dir(fullfile(PARAMS.inpath,'*.hrp'));    % hrp head files
            fn = char(d.name);      % file names in directory
            fnsz = size(fn);        % number of data files in directory
            nfiles = fnsz(1);
            
            filenames = [];
            for i = 1:nfiles
                filenames = vertcat(filenames, fullfile(PARAMS.inpath, fn(i, :)));
            end
        end
        
         if nfiles < 1
            disp_msg(['No data files in this directory: ',PARAMS.inpath])
            disp_msg('Pick another directory')
            hrppd('ck_dirlist_times');
         end
         
         check_dirlist_times(filenames)
    else
        disp_msg(' ')
        disp_msg('Error : Choose [1] or [0]')
        disp_msg(['You chose : ',num2str(fflag)])
        disp_msg(' ')
    end
    
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % dialog box
elseif strcmp(action,'plotSectorTimes')
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    
    plot_hrpSectorTimes
    
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');
    
elseif strcmp(action, 'fixtimes')
    set(HANDLES.fig.ctrl, 'Pointer', 'watch');
    set(HANDLES.fig.main, 'Pointer', 'watch');
    set(HANDLES.fig.msg, 'Pointer', 'watch');
    
    fix_dirlistTimes;
    
    set(HANDLES.fig.ctrl, 'Pointer', 'arrow');
    set(HANDLES.fig.main, 'Pointer', 'arrow');
    set(HANDLES.fig.msg, 'Pointer', 'arrow');
    
end

