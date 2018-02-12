function make_xwavnames(rfCounts, prefix)

% will get the names of xwav files corresponding to each raw file put in an
% ltsa

global PARAMS REMORA

% number of raw files on disk
nrf = length(PARAMS.head.dirlist); 

% for each raw file and decimation factor, generate the name of the xwav 
% that the raw file came from
for i = 1:length(REMORA.hrp.dfs)
    for j = 1:nrf
        
        % need a new file name
        if mod(j-1, rfCounts(i)) == 0
            
            % different file names for df = 1
            % create XWAV file name
            date = num2str(PARAMS.head.dirlist(j,2:4),'%02d');
            time = num2str(PARAMS.head.dirlist(j,5:7),'%02d');
            
            % add df to filename if df not 1
            if dfs(k) ~= 1
                name = sprintf('%s%s_%s_df%d.x.wav', prefix,date,time,...
                    REMORA.hrp.dfs(i));
            else
                name = sprintf('%s%s_%s.x.wav', prefix,date,time);
            end
        end   

    end
end