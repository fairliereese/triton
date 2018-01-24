function writeEffort(rootNode, spreadsheet)
% writeEffort(rootNode, spreadsheet)
% Based on the current effort tree rooted at rootNode,
% write the Effort to a spreadhseet.  Spreadsheet may be
% either a string indicating a filename to be used or 
% a handle to an active X (OLE) spreadsheet.

debug = false;
if debug
    global handles
    handles.Server.visible = true;
end

global TREE
currNode = rootNode.getFirstChild();
tLength = rootNode.getDepth();
if nargout > rootNode.getDepth()
    tLength = nargout-1;
end
struct = cell(1,tLength);
if strcmp(TREE.gran, 'binned')
    granOffset = 2;
    granCell = cell(1,2);%creat a  cell array, will only have two values and set
    granCell{1} = TREE.gran;%to appropiate values. 
    granCell{2} = TREE.binTime;
    binnedTime = true;
else
    granOffset = 1;
    granCell = cell(1,1);
    granCell{1} = TREE.gran;
    binnedTime = false;
end
list = cell(0,tLength);
flag1 = 0;
level = currNode.getLevel();
first = true;

% params will be built into a matrix with default
% parameters, one row for each species.  We double
% the number of columns to accomadate users that
% need to store time with selections.
params = cell(0, 2*size(TREE.frequency,2));

while ~isempty(currNode) || level > 1
    
    previous = currNode;
    level = currNode.getLevel();
    gpValue = currNode.getValue();
    %disp(char(gpValue(2)));
    selected = strcmp(gpValue(1), 'selected');
    if selected
        level = currNode.getLevel();
        % We need to store two values for the second level of the tree
        % Common name and abbreviation
        offset = level >= 2;
        if level == 2
            values{level} = char(currNode.getName());
        end
        values{currNode.getLevel()+offset} = char(gpValue(2));
        traverseChildren = currNode.getAllowsChildren();
        
        if traverseChildren
            % Traverse children
            currNode = currNode.getFirstChild();
        else
            % At a leaf node.  values{1:level} contain the tree info
            list(end+1,1:level+offset) = values(1:level+offset);
            if first
                values{1} = '';  % effort template does not repeat group
            end
        end
    else
        traverseChildren = false;
    end
    
    if ~ traverseChildren
        % Don't go further down the chain
        % We are either at a leaf or we are not interested in this chain
        
        if ~isempty(currNode.getNextSibling())
            % process siblings of the current node
            currNode = currNode.getNextSibling();
        elseif ~isempty(currNode.getParent().getNextSibling())
            % no more siblings, process parent's siblings
            currNode = currNode.getParent().getNextSibling();
        elseif level ~= 1
            % process grandparent's sibling
            % Todo:  Make the whole process more general, perhaps
            %        use a stack and push/pop
            level = currNode.getParent().getParent().getLevel();
            currNode = currNode.getParent().getParent().getNextSibling();
        end
    end
    
    if previous == currNode
        break
    end
end

if ischar(spreadsheet)
    % filename, try to open it
    try
        Excel = actxserver('Excel.Application');
    catch err
        errordlg('Unable to access spreadsheet interface')
        return
    end
    %Excel.Visible = 1;  % for debugging

    try
        Workbook = Excel.workbooks.Open(spreadsheet);  % Open workbook
    catch err
        errordlg(sprintf('Unable to open spreadsheet %s', spreadsheet));
        return
    end
else
    Workbook = spreadsheet;  % Already open, copy handle
end

try
    EffortSheet = Workbook.Sheets.Item('Effort'); % Access the Effort sheet
catch
    errordlg('Master template missing Effort sheet');
end

% erase and rewrite headers with granularity and bintime as columns
colsN = EffortSheet.UsedRange.Columns.Count;
cellRange = sprintf('A1:%s1', excelColumn(colsN));%need proper range format
headerRange = get(EffortSheet, 'Range', cellRange);%get the range of the headers
headerRangeCell = headerRange.value;%convert from range object to cell array




% Traverse rows, removing unselected ones and setting the granularity
% where needed.  
% Replace NaN with '' so regexp doesn't fail
charI = cellfun(@ischar, headerRangeCell);
for idx = find(~charI)
    headerRangeCell{idx} = '';
end
speciesCol= find(strcmp(headerRangeCell, 'Species Code'));
callCol = find(strcmp(headerRangeCell, 'Call'));
granCol = excelColumn(find(strcmp(headerRangeCell, 'Granularity'))-1);
groupCol = excelColumn(find(strcmp(headerRangeCell, 'Group'))-1);

if length(granCell) > 1
    % BinSize required
    granLastCol = excelColumn(find(strcmp(headerRangeCell, 'BinSize_m'))-1);
else
    granLastCol = granCol;
end

% values needed for following loop
whitespace = false;
selectedidx = 1; % indexes 'list'
effortidx = 2; % indexes spreadsheet
comCol = 2;
new_spec = false;

% error messages to display
spec_mis = '';
com_mis = '';
dat_miss = '';
dat_ex = '';
del_lines = {};
temp_idx = 2; % indexes the template

% loop through entries in the spreadsheet and entries in list of effort
while selectedidx <= length(list)

    Range = EffortSheet.Range(sprintf('%d:%d', effortidx, effortidx));
    values = Range.value;
    
    if selectedidx == 1
        specname = list{selectedidx, comCol};
        
    % new species
    elseif ~strcmp(specname, list{selectedidx, comCol})
            specname = list{selectedidx, comCol};
            new_spec = true;   
    else
        new_spec = false;
    end
    
    % new group? 
    if ~isempty(list{selectedidx, 1})
        group_l = list{selectedidx, 1};
    end
    if ~isempty(values{1}) & ~isnan(values{1})
        group_v = values{1};
    end

    % call type and group matching
    if ischar(values{callCol}) && strcmp(values{callCol}, list{selectedidx, callCol})...
            && strcmp(group_v, group_l)

        % missing data in columns that carry over from previous row?
        if ~ischar(values{comCol}) && ~ischar(values{speciesCol}) && ...
                whitespace == false
            
            % warn about missing entries
            dat_miss = horzcat(dat_miss, num2str(effortidx), ', ');
            
            % Matches, add granularity
            GranRange = EffortSheet.Range(...
                sprintf('%s%d:%s%d', granCol, effortidx, granLastCol, effortidx));
            set(GranRange, 'Value', granCell);
            
            if ~isempty(list{selectedidx, 1})
                % first item in group, set group name
                GrpRange = EffortSheet.Range(...
                    sprintf('%s%d:%s%d', groupCol, effortidx, groupCol, effortidx));
                set(GrpRange, 'Value', list{selectedidx, 1});
            end
            selectedidx = selectedidx + 1;
            effortidx = effortidx + 1;
            whitespace = false;
         
        % one mismatch?
        elseif strcmp(values{comCol}, list{selectedidx, comCol}) || ...
                strcmp(values{speciesCol}, list{selectedidx, speciesCol})

            % Matches, add granularity
            GranRange = EffortSheet.Range(...
                sprintf('%s%d:%s%d', granCol, effortidx, granLastCol, effortidx));
            set(GranRange, 'Value', granCell);
            
            if ~isempty(list{selectedidx, 1})
                % first item in group, set group name
                GrpRange = EffortSheet.Range(...
                    sprintf('%s%d:%s%d', groupCol, effortidx, groupCol, effortidx));
                set(GrpRange, 'Value', list{selectedidx, 1});
            end
            
            if ~strcmp(values{comCol}, list{selectedidx, comCol})
                % warn about mismatching common names
                com_mis = horzcat(com_mis, num2str(effortidx), ', ');
            elseif ~strcmp(values{speciesCol}, list{selectedidx, speciesCol})
                % warn about mismatching species codes
                spec_mis = horzcat(spec_mis, num2str(effortidx), ', ');
            end
            
            selectedidx = selectedidx + 1;
            effortidx = effortidx + 1;
            whitespace = false;
        
        % extra data with missing columns
        elseif ~ischar(values{comCol}) && ~ischar(values{speciesCol}) && ...
                whitespace == true
            has_data = sum(cellfun(@ischar, values));        
            if has_data
                del_lines = vertcat(del_lines, values(2:4));
            end  
            dat_ex = horzcat(dat_ex, num2str(selectedidx), ', ');
            selectedidx = selectedidx + 1;
        else
            has_data = sum(cellfun(@ischar, values));        
            if has_data
                del_lines = vertcat(del_lines, values(2:4));
            end  
            Range.Delete()
        end
 
    % if we're entering a new species, keep the whitespace row 
    elseif new_spec == true
        new_spec = false;
        effortidx = effortidx + 1;
        
        % if we don't need this entry 
    else 
        % The first empty row after retaining an entry is retained.
        % All others are removed.
        has_data = sum(cellfun(@ischar, values));        
        if has_data || whitespace
            if has_data
                del_lines = vertcat(del_lines, values(2:4));
            end
            Range.Delete();
        end
        if ~ has_data
            whitespace = true;
        end
    end
    temp_idx = temp_idx + 1;
end  

% remove everything after effort we care about
RowsN = EffortSheet.UsedRange.Rows.Count; 
for i = effortidx:RowsN
    Range = EffortSheet.Range(sprintf('%d:%d', effortidx, effortidx));
    values = Range.value;
    has_data = sum(cellfun(@ischar, values));        
    if has_data
        del_lines = vertcat(del_lines, values(2:4));
    end    
    Range.Delete();
end

% error messages for template issues and for debugging purposes
e1 = '';
e2 = '';
e3 = '';
mssg = {};
i = 1;
if ~strcmp(spec_mis, '')
    e1 = horzcat('Mismatch(es) in species code(s). Line(s) ', spec_mis(1:length(spec_mis)-2));
    mssg{i} = e1;
    i = i+1;
end
if ~strcmp(com_mis, '')
    e2 = horzcat('Mismatch(es) in common name(s). Line(s) ', com_mis(1:length(com_mis)-2));
    mssg{i} = e2;
    i = i+1;
end
if ~strcmp(dat_miss, '')
    e3 = horzcat('Missing data in line(s) ', dat_miss(1:length(dat_miss)-2));
    mssg{i} = e3;
    i = i+1;
end
if ~strcmp(dat_ex, '')
    e4 = horzcat('Unexpected entries on line(s) ', dat_ex(1:length(dat_ex)-2));
    mssg{i} = e4;
end

if debug == true
    lim = size(del_lines);
    lim = lim(1);
    for i = 1:lim
        m = sprintf('Deleted line: %s %s %s', del_lines{i,1}, del_lines{i,2}, del_lines{i,3});
        disp_msg(m);
    end
end
for i = 1:length(mssg)
    if ~strcmp(mssg{i}, '')
        disp_msg(mssg{i});
    end
end    



if ischar(spreadsheet)
    % save and close, user wanted file operation
    Workbook.Save();  % Save changes
    Workbook.Close(false);  % Close program
    Excel.Quit;  % Exit server
end


