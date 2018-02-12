function figure_stuff
global REMORA PARAMS


%% load dfs fig
prompt = inputdlg('Enter desired decimation factors (comma separated):',...
    'DF Selection', 1, {'1, 5, 10'});
prompt = strsplit(char(prompt), {',',', '});
REMORA.hrp.dfs = [];
for k = 1:length(prompt)
    df = str2num(prompt{k});
    REMORA.hrp.dfs = [REMORA.hrp.dfs, df];
end

% shorthand dfs alias
dfs = REMORA.hrp.dfs;

%% dfs save locations fig
% color
mycolor = [.8,.8,.8];
r = length(dfs) + 2;
c = 5;
h = 0.02*r; % panel width and height
w = 0.025*c;

bh = 1/r; % button/element width/height
bw = 1/c;

% make x and y locations in plot control window (relative units)
y = zeros(1, r);
for ri = 1:r 
    if ri == 1
        y(ri) = 0;
    else 
        y(ri) = 1/r + y(ri-1);
    end
end

x = zeros(1, r);
for ci = 1:c
    if ci == 1
        x(ci) = 0;
    else
        x(ci) = 1/c + x(ci-1);
    end
end

% dy = y(2)/r-2;
% dx = x(2)/4;

btnPos = [0,0,w,h];

REMORA.fig.hrp = figure('Name', 'Save Disk Selection', 'Units', ...
    'normalized', 'Position', btnPos, 'MenuBar', 'none', 'NumberTitle', 'off');
movegui(gcf, 'center');


% Title
labelStr = 'Select disks to save each DF to:';
btnPos = [x(1),y(end), 5*bw, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized','BackgroundColor', mycolor,...
    'Position', btnPos,'Style','text','String',labelStr);

% list of dfs
for k = 1:length(dfs)
    labelStr = sprintf('%d : ', dfs(k));
    btnPos = [x(1),y(end-k),bw,bh];
    uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'BackgroundColor', mycolor,...
        'Position', btnPos,'Style', 'text', 'String', labelStr);

    labelStr = 'Browse';
    btnPos = [x(4), y(end-k),2*bw,bh];
    REMORA.fig.browsebois{k} = uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'Position', btnPos,...
        'String', labelStr, 'Style', 'pushbutton', 'Callback', sprintf('ctrl_figure_stuff(''get'', %d)', k));
  
    btnPos = [x(2),y(end-k),2*bw,bh];
    REMORA.fig.disk_handles{k} = uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'Position', btnPos,...
        'Style', 'edit', 'BackgroundColor', 'white', 'HorizontalAlignment',...
        'left');
end

% continue
labelStr = 'Continue';
btnPos = [x(2)+.5*x(2), y(1), bw*2, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'Position', btnPos, ...
'String', labelStr, 'Callback', 'ctrl_figure_stuff(''ctn_disk'')');

uiwait;

%% LTSA figure
 
r = length(dfs) + 3;
c = 3;
h = 0.02*r; % panel width and height
w = 0.05*c;

bh = 1/r; % button/element width/height
bw = 1/c;

% make x and y locations in plot control window (relative units)
y = zeros(1, r);
for ri = 1:r 
    if ri == 1
        y(ri) = 0;
    else 
        y(ri) = 1/r + y(ri-1);
    end
end

x = zeros(1, r);
for ci = 1:c
    if ci == 1
        x(ci) = 0;
    else
        x(ci) = 1/c + x(ci-1);
    end
end

btnPos = [0, 0, w, h];

REMORA.fig.hrp = figure('Name', 'LTSA Config', 'Units', 'Normalized',...
    'MenuBar', 'none', 'NumberTitle', 'off', 'Position', btnPos);
movegui(gcf, 'center');

% header info
labelStr = 'Make LTSA for this DF?';
btnPos = [x(1),y(end-1), bw, 2*bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized','BackgroundColor', mycolor,...
    'Position', btnPos,'Style','text','String',labelStr);

labelStr = 'tave';
btnPos = [x(2), y(end), bw, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'BackgroundColor', mycolor,...
    'Position', btnPos, 'Style', 'text', 'String', labelStr);

labelStr = 'dfreq';
btnPos = [x(3), y(end), bw, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'BackgroundColor', mycolor,...
    'Position', btnPos, 'Style', 'text', 'String', labelStr);

for k = 1:length(dfs)
    % list of dfs
    labelStr = sprintf('%d  ', dfs(k));
    btnPos = [x(1),y(end-k-1),bw,bh];
    REMORA.fig.radio{k} = uicontrol(REMORA.fig.hrp, 'Units', 'normalized',...
        'Position', btnPos,'Style', 'radio', 'String', labelStr);
    
    btnPos = [x(2), y(end-k-1), bw, bh];
    REMORA.fig.tave_fig{k} = uicontrol(REMORA.fig.hrp, 'Units', 'normalized',...
        'Position', btnPos, 'Style', 'edit', 'String', '5');
    
    btnPos = [x(3), y(end-k-1), bw, bh];
    REMORA.fig.dfreq_fig{k} = uicontrol(REMORA.fig.hrp, 'Units', 'normalized',...
        'Position', btnPos, 'Style', 'edit', 'String', '100');   
end

% continue
labelStr = 'Continue';
btnPos = [x(2), y(1), bw, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized', 'Position', btnPos, ...
'String', labelStr, 'Callback', 'ctrl_figure_stuff(''ctn_ltsa'')');

uiwait;

%% channel selection
prompt = inputdlg('Which channels should be processed (comma separated):',...
    'LTSA Channel', 1, {'1'});
prompt = strsplit(char(prompt), {',',', '});
valid = [1 2 3 4]; 
REMORA.hrp.ch = [];
for k = 1:length(prompt)
    ch = str2num(prompt{k});
    
    % make sure channel is valid, right now only 4 ch data possible
    if ismember(ch, valid)
        REMORA.hrp.ch = [REMORA.hrp.ch, ch];
    else
        fprintf('Invalid channel number %s\n', ch);
    end
end

%% Start/end rf  
c = 4;
r = 6;
 
h = 0.02*r; % panel width and height
w = 0.04*c;

bh = 1/r; % button/element width/height
bw = 1/c;

% make x and y locations in plot control window (relative units)
y = zeros(1, r);
for ri = 1:r 
    if ri == 1
        y(ri) = 0;
    else 
        y(ri) = 1/r + y(ri-1);
    end
end

x = zeros(1, r);
for ci = 1:c
    if ci == 1
        x(ci) = 0;
    else
        x(ci) = 1/c + x(ci-1);
    end
end

btnPos = [0,0,w,h];
REMORA.fig.hrp = figure('Name', 'RF nums', 'Units', 'Normalized',...
    'MenuBar', 'none', 'NumberTitle', 'off', 'Position', btnPos);
movegui(gcf,'center');


% label info
labelStr = 'Choose a start and end rf';
btnPos = [x(1), y(end), 1, bh];
uicontrol(REMORA.fig.hrp, 'Units', 'normalized','BackgroundColor',mycolor,...
    'Position',btnPos,'Style','text','String',labelStr,'HorizontalAlign',...
    'left');

% start and end rf uicontrol objects
btnPos = [x(1), y(end-1),1.5*bw,bh]; 
REMORA.fig.start = uicontrol(REMORA.fig.hrp, 'Units','normalized',...
    'Position',btnPos,'Style','edit','HorizontalAlign','left');

btnPos = [x(2)+.5*x(2),y(end-1),bw,bh];
labelStr = '    Start';
uicontrol(REMORA.fig.hrp,'Units','normalized','Position',btnPos,...
    'Style','text','String',labelStr,'BackgroundColor',mycolor,...
    'HorizontalAlign','left');

btnPos = [x(1),y(end-2),1.5*bw,bh];
REMORA.fig.end = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'POsition',btnPos,'Style','edit','HorizontalAlign','left');

btnPos = [x(2)+.5*x(2),y(end-2),bw,bh];
labelStr = '    End';
uicontrol(REMORA.fig.hrp,'Units','normalized','Position',btnPos,...
    'Style','text','String',labelStr,'BackgroundColor',mycolor,...
    'HorizontalAlign','left');

% skip rfs?
btnPos = [x(1), y(end-3),1.5*bw,bh];
REMORA.fig.skip = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'Style','edit','HorizontalAlign','left');

btnPos = [x(2)+.5*x(2),y(end-3),2.5*bw,bh];
labelStr = '   RF #s to skip; comma separated';
uicontrol(REMORA.fig.hrp,'Units','normalized','Position',btnPos,...
    'String',labelStr,'Style','text','BackgroundColor',mycolor,...
    'HorizontalAlign','left');

btnPos = [x(1),y(end-4),1,bh];
labelStr = 'Process whole disk';
REMORA.fig.wholeradio = uicontrol(REMORA.fig.hrp,'String',labelStr,...
   'Style','radio','BackgroundColor',mycolor,'Units','normalized',...
   'Position',btnPos,'Callback','ctrl_figure_stuff(''rad_rf'')');

% continue button
btnPos = [x(2),y(1),bw,bh];
labelStr = 'Continue';
uicontrol(REMORA.fig.hrp,'String',labelStr,...
    'Style','push','Units','normalized','Position',btnPos,...
    'Callback','ctrl_figure_stuff(''ctn_rf'')');

uiwait;

%% Boolean options
c = 4;
r = 9;
 
h = 0.02*r; % panel width and height
w = 0.04*c;

bh = 1/r; % button/element width/height
bw = 1/c;

% make x and y locations in plot control window (relative units)
y = zeros(1, r);
for ri = 1:r 
    if ri == 1
        y(ri) = 0;
    else 
        y(ri) = 1/r + y(ri-1);
    end
end

x = zeros(1, r);
for ci = 1:c
    if ci == 1
        x(ci) = 0;
    else
        x(ci) = 1/c + x(ci-1);
    end
end

btnPos = [0,0,w,h];
REMORA.fig.hrp = figure('Name', 'Other', 'Units', 'Normalized',...
    'MenuBar', 'none', 'NumberTitle', 'off', 'Position', btnPos);
movegui(gcf,'center');

% label info
btnPos = [x(1),y(end),1,bh];
labelStr = '   Other options';
uicontrol(REMORA.fig.hrp,'Units','normalized','BackgroundColor',mycolor,...
    'Position',btnPos,'Style','text','String',labelStr,'HorizontalAlign',...
    'left');

% radio buttons

% fix directory times
btnPos = [x(1),y(end-1),1,bh];
labelStr = '   Fix directory list times';
REMORA.fig.fix_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor,'Callback','ctrl_figure_stuff(''enb'')');

btnPos = [.5*x(2),y(end-2),3/c,bh];
labelStr = 'Use modified dirlist time files';
REMORA.fig.fix_files_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor,'Enable','off');

% rmfifo
btnPos = [x(1),y(end-3),1,bh];
labelStr = '   Remove FIFO noise';
REMORA.fig.rmfifo_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor);

% resume processing
btnPos = [x(1),y(end-4),1,bh];
labelStr = '   Resume processing';
REMORA.fig.resume_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor);

% display output to command window
btnPos = [x(1),y(end-5),1,bh];
labelStr = '   Display output to command window';
REMORA.fig.disp_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor);

% create diary log of output
btnPos = [x(1), y(end-6),1,bh];
labelStr = '   Create diary log of output';
REMORA.fig.diary_rad = uicontrol(REMORA.fig.hrp,'Units','normalized',...
    'Position',btnPos,'String',labelStr,'Style','radio',...
    'BackgroundColor',mycolor);

% save parameters
btnPos = [x(1)+.25*x(2),y(1),1.5*bw,1.5*bh];
labelStr = 'Save params';
uicontrol(REMORA.fig.hrp,'Units','normalized','Position',btnPos,...
    'String',labelStr,'Style','push','Callback','ctrl_figure_stuff(''save'')');

% go! (Start processing!)
btnPos = [x(4)-.75*x(2),y(1),1.5*bw,1.5*bh];
labelStr = 'Go';
uicontrol(REMORA.fig.hrp,'Units','normalized','Position',btnPos,...
    'String',labelStr,'Style','push','Callback','ctrl_figure_stuff(''go'')');

uiwait;

end