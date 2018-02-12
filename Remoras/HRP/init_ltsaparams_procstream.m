function init_file_ltsaparams

% will initialize parameters for ltsa creation that are specific to the
% ltsa file that is being made

global PARAMS

PARAMS.ltsa.nBits = PARAMS.nBits;
PARAMS.ltsa.nch = PARAMS.nch;

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

% loop through directory list of raw HRP file to get timing info
PARAMS.ltsahead.year = zeros(length(PARAMS.head.dirlist)); % TODO depending on what raw files go into this ltsa, index dirlist accordingly!
for i = 1:length(PARAMS.head.dirlist) % TODO depending on what raw files go into this ltsa, index dirlist accordingly!
    PARAMS.ltsahd.year(i)
end

end
