% ctrl_figure_stuff
function ctrl_figure_stuff(input, k)

global REMORA PARAMS

switch input
    
    case 'get'
        set(REMORA.fig.disk_handles{k}, 'String', uigetdir);
        
    case 'ctn_disk'
        % get string from each of the disk fields
        blanks = false;
        for k = 1:length(REMORA.hrp.dfs)
            str = get(REMORA.fig.disk_handles{k}, 'String');
            if isempty(str)
                set(REMORA.fig.disk_handles{k}, 'BackgroundColor', 'red');
                blanks = true;
            else
                set(REMORA.fig.disk_handles{k}, 'BackgroundColor', 'white');
            end
            REMORA.hrp.saveloc{k} = str;
        end
        
        % if missing fields
        if blanks 
            return
        end
        
        % close and resume
        uiresume(REMORA.fig.hrp);
        close(REMORA.fig.hrp);
        REMORA.fig = rmfield(REMORA.fig, 'browsebois');
        REMORA.fig = rmfield(REMORA.fig, 'disk_handles');   
        
    case 'ctn_ltsa'
        REMORA.hrp.ltsas = zeros(1, 3);
        REMORA.hrp.tave = zeros(1, 3);
        REMORA.hrp.dfreq = zeros(1, 3);
        
        % check whether or not each radio button is activated
        blanks = false;
        for k = 1:length(REMORA.hrp.dfs)
            state = get(REMORA.fig.radio{k}, 'Value');
            REMORA.hrp.ltsas(k) = state;
            
            if state
                tave = get(REMORA.fig.tave_fig{k}, 'String');
                dfreq = get(REMORA.fig.dfreq_fig{k}, 'String');
                
                if isempty(tave)
                    blanks = true;
                    set(REMORA.fig.tave_fig{k}, 'BackgroundColor', 'red');
                else
                    REMORA.hrp.tave(k) = str2num(tave);
                    set(REMORA.fig.tave_fig{k}, 'BackgroundColor', 'white');
                end
                if isempty(dfreq)
                    blanks = true;
                    set(REMORA.fig.dfreq_fig{k}, 'BackgroundColor', 'red');
                else
                    REMORA.hrp.dfreq(k) = str2num(dfreq);
                    set(REMORA.fig.dfreq_fig{k}, 'BackgroundColor', 'white');
                end
            end
        end
        if blanks
            return
        end
        
        % close figure and clear unnecessary figure fields
        uiresume(REMORA.fig.hrp);
        close(REMORA.fig.hrp);
        
        REMORA.fig = rmfield(REMORA.fig,'dfreq_fig');
        REMORA.fig = rmfield(REMORA.fig, 'tave_fig');
        REMORA.fig = rmfield(REMORA.fig, 'radio');

    case 'rad_rf'
        state = get(REMORA.fig.wholeradio, 'Value');
        
        % if whole disk selected disable edit boxes
        if state 
            set(REMORA.fig.start,'Enable','off');
            set(REMORA.fig.end,'Enable','off');
        else
            set(REMORA.fig.start,'Enable','on');
            set(REMORA.fig.end,'Enable','on');
        end
                
    case 'ctn_rf'
        state = get(REMORA.fig.wholeradio, 'Value');
        sk = get(REMORA.fig.skip, 'String');
        blanks = false;
        
        % if we want whole disk processed
        if state
            REMORA.hrp.rf_start = 1;
            REMORA.hrp.rf_end = 0;
        else
            s = get(REMORA.fig.start, 'String');
            e = get(REMORA.fig.end, 'String');
            
            if isempty(s)
                set(REMORA.fig.start,'BackgroundColor','red');
                blanks = true;
            else 
                set(REMORA.fig.start,'BackgroundColor','white');
                REMORA.hrp.rf_start = str2num(s);
            end
            if isempty(e)
                set(REMORA.fig.end,'BackgroundColor','red');
                blanks = true;
            else
                set(REMORA.fig.end,'BackgroundColor','white');
                REMORA.hrp.rf_end = str2num(e);
            end        
        end
        
        % assign rf #s to skip
        if isempty(sk)
                REMORA.hrp.rf_skip = [];
            else 
                sk = strsplit(sk, {',',', '});
                REMORA.hrp.rf_skip = [];
                for k = 1:length(sk)
                    rf = str2num(sk{k});
                    REMORA.hrp.rf_skip = [REMORA.hrp.rf_skip, rf];
                end
        end
        
        % return for rest of numbers or continue; clear REMORA fields
        if blanks
            return;
        end
        
        uiresume(REMORA.fig.hrp);
        close(REMORA.fig.hrp);
        
        REMORA.fig = rmfield(REMORA.fig, 'wholeradio');
        REMORA.fig = rmfield(REMORA.fig, 'end');
        REMORA.fig = rmfield(REMORA.fig, 'start');
        REMORA.fig = rmfield(REMORA.fig, 'skip');
        
   case 'enb' 
        state = get(REMORA.fig.fix_rad, 'Value');
        if state
            set(REMORA.fig.fix_files_rad, 'Enable', 'on');
        else
            set(REMORA.fig.fix_files_rad, 'Enable', 'off');
            set(REMORA.fig.fix_files_rad, 'Value', 0);
        end 
        
    case 'save'
        % don't want to save figure handles so temporarily remove
        temp = REMORA.fig;
        REMORA = rmfield(REMORA,'fig');
            
        try
            name = 'my_procparams';
            [savefile, savepath] = uiputfile('*.mat', 'Save file',name);
            save(fullfile(savepath, savefile), 'REMORA', 'PARAMS');
        catch
            disp('Invalid file selected or cancel button pushed.')
        end  
        % fix REMORA field
        REMORA.fig = temp;

    case 'go'
        REMORA.hrp.fixTimes = get(REMORA.fig.fix_rad, 'Value');
        REMORA.hrp.rmfifo = get(REMORA.fig.rmfifo_rad, 'Value');
        REMORA.hrp.resumeDisk = get(REMORA.fig.resume_rad, 'Value');
        PARAMS.dflag = get(REMORA.fig.disp_rad, 'Value');
        REMORA.hrp.diary_bool = get(REMORA.fig.diary_rad, 'Value');
        REMORA.hrp.use_mod = get(REMORA.fig.fix_files_rad, 'Value');
        
        uiresume(REMORA.fig.hrp);
        close(REMORA.fig.hrp);
        
        REMORA.fig = rmfield(REMORA.fig, 'fix_rad');
        REMORA.fig = rmfield(REMORA.fig, 'rmfifo_rad');
        REMORA.fig = rmfield(REMORA.fig, 'resume_rad');
        REMORA.fig = rmfield(REMORA.fig, 'disp_rad');
        REMORA.fig = rmfield(REMORA.fig, 'diary_rad');
        REMORA.fig = rmfield(REMORA.fig, 'fix_files_rad');

end