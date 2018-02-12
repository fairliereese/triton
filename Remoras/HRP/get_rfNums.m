function [rf_end, numXWAVs, rawFileNums] = get_rfNums(infile, dfs, rf_start, rf_end)

global PARAMS REMORA

% calculate the number of raw files from dirlist 
% if the hrp file is truncated or otherwise missing data
hrp_size = dir(infile);
hrp_size = hrp_size.bytes;

% some aliases to make stuff easier here
partial = hrp_size < 512 * PARAMS.head.dirlist(end, 1);
rf_skip = REMORA.hrp.rf_skip;
skip_num = 0;
ndir = 0;
k = 1;

% rf adjustment (rfs to skip and partial hrp)
if partial || ~isempty(rf_skip)
    while k <= length(PARAMS.head.dirlist)
        
        % if we're skipping this file
        if ismember(k, rf_skip)
            % remove from dirlist
            if k == 1
                PARAMS.head.dirlist = PARAMS.head.dirlist(k+1:end,:);
            else
                PARAMS.head.dirlist = PARAMS.head.dirlist([1:k-1,k+1:end],:);
            end
            % decrement all rf indices since we've now deleted an entry
            % and increment tracker for how many rfs we've removed
            rf_skip = rf_skip - 1;
            fprintf('Removing rf %d from directory list\r\n',k+skip_num);
            skip_num = skip_num + 1;
            
        % rf we can add (not in skip list or beyond end of hrp)
        elseif 512*PARAMS.head.dirlist(k, 1) < hrp_size
            ndir = ndir + 1;
            k = k + 1;
            
        % beyond the end of the hrp
        else
            k = k + 1;
        end
    end
end

% message to display 
if partial 
    fprintf('Partial HRP with %d raw files found.\r\n', ndir);
end


% % partial HRP
% % if hrp_size < 512 * PARAMS.head.dirlist(end, 1)
% %     ndir = 0;
% %     for i = 1:length(PARAMS.head.dirlist) % Todo: replace with find?
% %         if we're skipping this rf during processing
% %         if ismember(i, REMORA.hrp.rf_skip)
% %             if i == 1
% %                 PARAMS.head.dirlist = PARAMS.head.dirlist(i+1:end,:);
% %             else
% %                 PARAMS.head.dirlist = PARAMS.head.dirlist([1:i-1,i+1:end],:);
% %             end
% %             fprintf('Removing rf %d from directory list\r\n',i);
% %         end
% %         if 512*PARAMS.head.dirlist(i, 1) < hrp_size
% %             ndir = ndir + 1;
% %         else
% %             break
% %         end
% %     end
% %     fprintf('Partial HRP with %d raw files found.\r\n', ndir);
% % else
% %     ndir = PARAMS.head.nextFile;
% % end
% % 1;

% % if we want to process through last file on disk
% if rf_end == 0
%     rf_end = ndir;
%     num_rf = rf_end - rf_start + 1; % +1 b/c inclusive
% if end rf # too big
if rf_end > ndir
    fprintf('Chosen end rf %d out of range. ', rf_end);
    fprintf('Processing through last available rf.\r\n');
    rf_end = ndir;
    num_rf = rf_end - rf_start + 1; 
% valid end rf #
else
    if rf_end == 0
        rf_end = ndir;
    end
    num_rf = rf_end - rf_start + 1;
end

%     
%     
%     % if we want all files set to last rf in partial hrp
%     if rf_end == 0 
%         num_rf = ndir - rf_start + 1; % +1 b/c inclusive
%     else
%         % if our chosen rf_end is out of range of partial hrp
%         if ndir < rf_end
%             num_rf = ndir - rf_start + 1; % +1 b/c inclusive
%             disp(['Partial HRP found. Chosen end rf out of range. ',...
%                 'Processing through last available rf.']);
%         % valid end given
%         else
%             ndir = rf_end;
%             num_rf = rf_end - rf_start + 1;
%         end
%     end
    
% % complete HRP, want all files through end
% elseif rf_end == 0
%     ndir = PARAMS.head.nextFile;
%     num_rf = ndir - rf_start + 1;
%     
% % valid specified end rf
% elseif rf_end < PARAMS.head.nextFile
%     ndir = rf_end;
%     num_rf = ndir - rf_start + 1;
%     
% else
%     fprintf('rf %d is out of range. Processing through last available rf.\r\n',...
%         rf_end);
%     ndir = PARAMS.head.nextFile;
%     num_rf = ndir - rf_start + 1;
% end

% desired filesize for all generated files
filesize = 1.5*1024^3; 

% loop through each decimation type and determine how many raw files can
% fit into each type of xwav
rawFileNums = zeros(1, length(dfs)); % number of rfs/xwav
numXWAVs = zeros(1, length(dfs)); % number of xwavs produced
for i = 1:length(dfs)
    
    % if no decimation, just use 30 raw files/xwav
    if dfs(i) == 1
        rawFileNums(i) = 30;
        
    else
        % figure out how big each output file is going to be
        rawFileNums(i) = ceil((filesize * dfs(i)) ...
                       /(PARAMS.nsampPerSect * PARAMS.bitsPerSamp * ...
                       PARAMS.nsectPerRawFile));
                   
       % number of raw files for xwav exceeds the 
       % number of files on the disk
       if num_rf < rawFileNums(i)
           rawFileNums(i) = num_rf;
       end
    end
    
    % number of xwavs generated for each decimation factor
    numXWAVs(i) = ceil(num_rf/rawFileNums(i));   
end

rf_end = rf_end-1; % for files raw files that are segmented TODO 
end
                    
