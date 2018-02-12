function load_modhdrs(modfile)

global PARAMS

modhdrs = load(modfile);
modhdrs = modhdrs.modhdrs;

% loop through each of the messed up entries
for i = 1:size(modhdrs, 1)
    modI = modhdrs(i, 2);
    if modI 
        PARAMS.head.dirlist(modI, :) = [PARAMS.head.dirlist(modI, 1),...
            modhdrs(i, 10:16), PARAMS.head.dirlist(modI, 9:11)];
    end
end
end