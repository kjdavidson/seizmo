function [data,selected,ax]=selectrecords(data,opt,type,selected,varargin)
%SELECTRECORDS    Select or delete SEIZMO data records graphically
%
%    Usage:    [data,selected,ax]=selectrecords(data)
%              data=selectrecords(data,option)
%              data=selectrecords(data,option,type)
%              data=selectrecords(data,option,type,selected)
%              data=selectrecords(data,option,type,selected,plotoptions)
%
%    Description: [DATA,SELECTED,AX]=SELECTRECORDS(DATA) returns records
%     in SEIZMO data structure DATA that are graphically selected by the
%     user.  By default the plottype is PLOT1 and no records are
%     preselected.  Selection/unselection of records is performed by left-
%     clicking over a record.  Complete dataset selection by middle-
%     clicking over the plot or closing the figure.  Optional additional
%     outputs are the logical array SELECTED which indicates the records
%     that were selected and AX gives the plot handle(s).
%
%     SELECTRECORDS(DATA,OPTION) sets whether selected records from DATA
%     are kept or deleted.  OPTION must be either 'keep' or 'delete'.  When
%     OPTION is 'keep', the background color for selected records is set to
%     a dark green.  For OPTION set to 'delete', the background color is
%     set to a dark red for selected records.  The default is 'keep'.
%
%     SELECTRECORDS(DATA,OPTION,TYPE) sets the plot type to be used in
%     record selection.  TYPE must be one of 'plot0','plot1','p0', or 'p1'.
%     The default is 'plot1'.
%
%     SELECTRECORDS(DATA,OPTION,TYPE,SELECTED) allows preselecting records
%     in DATA using the array SELECTED.  SELECTED must be either true (all
%     selected), false (none selected), a logical array with the same
%     number of elements as DATA, or an array of linear indices.  The
%     default is false.
%
%     SELECTRECORDS(DATA,OPTION,TYPE,SELECTED,PLOTOPTIONS) passes plotting
%     options PLOTOPTIONS (all arguments after SELECTED) to the plotting
%     function chosen with TYPE.
%
%    Notes:
%
%    Header changes: NONE
%
%    Examples:
%     To select which records to delete using plot1:
%       data=selectrecords(data,'delete','plot1')
%
%    See also: PLOT1, PLOT0

%     Version History:
%        Apr. 17, 2008 - initial version (happy bday bro!)
%        Nov. 16, 2008 - update for name changes
%        Nov. 30, 2008 - update for name changes
%        Dec. 13, 2008 - minor bug fixes
%        Mar. 13, 2009 - doc fixes
%        Apr.  3, 2009 - added preselect argument, combine keep/delete code
%                        redundancy
%        Apr. 23, 2009 - fix seizmocheck for octave, move usage up
%        May  30, 2009 - major doc update, major code cleaning
%        June  2, 2009 - fixed history, patches go on bottom now
%        June 25, 2009 - minor doc fixes, allow numeric array for selected
%        Sep. 16, 2009 - fix for getting bgcolor for single record
%        Oct.  6, 2009 - dropped use of LOGICAL function
%        Aug. 26, 2010 - no SEIZMO global, use movekids over uistack for
%                        Octave, update for new plotting routines
%        Jan.  6, 2011 - use key2zoompan
%        Apr.  4, 2011 - fixed logical checking of selected
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Apr.  4, 2011 at 20:50 GMTs

% todo:

% check nargin
if(nargin<1)
    error('seizmo:selectrecords:notEnoughInputs',...
        'Not enough input arguments.');
elseif(nargin>4 && mod(nargin,2))
    error('seizmo:selectrecords:plotOptionMustBePaired',...
        'Plot options must be paired with a value!');
end

% check data structure
versioninfo(data,'dep');

% number of records
nrecs=numel(data);

% valid values for options
valid.OPT={'keep' 'delete'};
valid.TYPE={'plot0' 'plot1' 'p0' 'p1'};

% default inputs
if(nargin<2 || isempty(opt)); opt='keep'; end
if(nargin<3 || isempty(type)); type='plot1'; end
if(nargin<4 || isempty(selected)); selected=false; end

% check inputs
if(~ischar(opt) || size(opt,1)~=1 || ndims(opt)~=2 ...
        || isempty(strmatch(lower(opt),valid.OPT)))
    error('seizmo:selectrecords:badInput',...
        ['OPT must be one of the following strings:\n' ...
        sprintf('''%s'' ',valid.OPT{:})]);
elseif(~ischar(type) || size(type,1)~=1 || ndims(type)~=2 ...
        || ~any(strcmpi(type,valid.TYPE)))
    error('seizmo:selectrecords:badInput',...
        ['TYPE must be one of the following strings:\n' ...
        sprintf('''%s'' ',valid.TYPE{:})]);
elseif((isnumeric(selected) && (any(selected~=fix(selected)) ...
        || any(selected<1 | selected>nrecs))) || (islogical(selected) ...
        && all(numel(selected)~=[1 nrecs])))
    error('seizmo:selectrecords:badInput',...
        'SELECTED must be TRUE, FALSE, logical array or linear indices!');
end

% fix selected
if(islogical(selected) && isscalar(selected))
    selected(1:nrecs,1)=selected;
elseif(isnumeric(selected))
    lidx=selected;
    selected=false(nrecs,1);
    selected(lidx)=true;
end

% set color
keep=~isempty(strmatch(opt,'keep'));
if(keep)
    color=[0 .3 0];
else % delete
    color=[.3 0 0];
end

% proceed by plot type
button=0; handles=ones(nrecs,1)*-1;
switch lower(type)
    case {'plot0' 'p0'}
        ax=plot0(data,varargin{:});
        
        % patch under all
        xlims=xlim(ax);
        for i=1:nrecs
            handles(i)=patch([xlims(ones(1,2)) xlims(2*ones(1,2))],...
                [i+0.5 i-0.5 i-0.5 i+0.5],color,'parent',ax);
        end
        movekids(handles,'back');
        set(handles(~selected),'visible','off')
        
        while(button~=2)
            % get mouse button pressed
            try
                [x,y,button]=ginput(1);
            catch
                ax=-1;
                break;
            end
            if(button==1)
                % figure out which record from y position
                clicked=round(y);
                
                % check range
                if(clicked<1 || clicked>nrecs); continue; end
                
                % remove from selected if already selected, turn off patch
                if(selected(clicked))
                    selected(clicked)=false;
                    set(handles(clicked),'visible','off');
                % otherwise add to selected, turn on patch
                else
                    selected(clicked)=true;
                    set(handles(clicked),'visible','on');
                end
            else
                key2zoompan(button,ax);
            end
        end
    case {'plot1' 'p1'}
        % plot type 1
        ax=plot1(data,varargin{:});
        
        % color preselected
        bgcolors=get(ax,'color');
        if(iscell(bgcolors))
            bgcolors=cell2mat(bgcolors);
        end
        set(ax(selected),'color',color);
        
        while(button~=2)
            % get mouse button pressed
            try
                [x,y,button]=ginput(1);
            catch
                ax=-1;
                break;
            end
            
            % grab axis handle
            handle=gca;
            
            % figure out which record
            clicked=find(handle==ax,1);
            if(isempty(clicked)); continue; end
            
            % act based on button
            if(button==1)
                % remove from list if in list and change color
                if(selected(clicked))
                    selected(clicked)=false;
                    set(handle,'color',bgcolors(clicked,:));
                % otherwise add to list and change color
                else
                    selected(clicked)=true;
                    set(handle,'color',color);
                end
            else
                key2zoompan(button,handle);
            end
        end
end

% handle data
if(keep)
    data=data(selected);
else % delete
    data(selected)=[];
end

end
