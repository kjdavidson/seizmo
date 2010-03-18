function [CONF,data,T,cv,lv,pv,align]=relarr(conf_file_path)
% RELATIVE PHASE/GROUP ARRIVAL AND AMPLITUDE DETERMINATION

% DEFAULT CONFIGURATION
CONF=defaultrelarrconf;

% GET CONFIGURATION FROM FILE
if(nargin==1 && ~isempty(conf_file_path)); CONF=rconf(conf_file_path,CONF); end

% RUNTIME DETERMINED CONFIGURATION (FILTER INDEPENDENT)
periods=findstr('.',CONF.DATEDIR);
CONF.DATESTR=CONF.DATEDIR; CONF.DATESTR(periods)=[];
CONF.OUTPUTBASENAME=[strtrim(CONF.OUTPUTDIR) filesep ...
    strtrim(CONF.PHASE) '.event' CONF.DATESTR '.run' num2str(CONF.RUNTIME)];

% READ IN DATA HEADERS
disp('READING IN DATA HEADERS')
CONF.INPUTDIR=strcat(CONF.DATEDIRPATH,filesep,CONF.DATEDIR,filesep);
files=dir(CONF.INPUTDIR);
path2files=strcat(CONF.INPUTDIR,{files.name}.');
warning('off','all')
data=rh(path2files);
warning('on','all')

% LIMIT READ IN FILES TO TIMESERIES FILES ONLY
data(~strcmp(genumdesc(data,'iftype'),'Time Series File'))=[];

% LIMIT FILES BY DISTANCE/AZIMUTHAL
disp('LIMITING DATA BY EARTHQUAKE-STATION GEOMETRY')
data(gh(data,'gcarc')<CONF.GCCUT1)=[];
data(gh(data,'gcarc')>CONF.GCCUT2)=[];
data(gh(data,'dist')<CONF.KMCUT1)=[];
data(gh(data,'dist')>CONF.KMCUT2)=[];
data(gh(data,'az')<CONF.AZICUT1)=[];
data(gh(data,'az')>CONF.AZICUT2)=[];
data(gh(data,'baz')<CONF.BAZICUT1)=[];
data(gh(data,'baz')>CONF.BAZICUT2)=[];

% GET PHASE ARRIVAL TIMES
disp('GETTING PREDICTED ARRIVALS')
if(CONF.PULLARR==1)
    data=ch(data,CONF.TTFIELD,pullarr(data,CONF.PHASE));
else 
    % USE TTBOX TO GET ARRIVAL TIMES (NOT IMPLEMENTED YET)
    % DOESN'T WORK FOR DIFFRACTED PHASES (THE REASON WHY ITS NOT IMPLEMENTED)
    % READ IN MODEL
    % GET TRAVELTIMES (HAVE TO FIX THE TRIPLICATION ISSUE FIRST...)
end

% PRE-FILTER DATA PROCESSING
disp('PERFORMING PRE-FILTER PROCESSING')
[data,CONF]=filter_preprep(data,CONF);

% INITIAL FILTER SECTION
[names,summary]=relarr_filterwrapper(data,CONF);
    
% THROW OUT DATA NOT PASSING INITIAL FILTER


% INJECT NEW ARRIVAL TIMES


% FILTER BANK SELECT
disp('SELECTING FILTER BANK (USER MENU)')

% FILTER LOOP

    % FILTER DEPENDENT CONFIGURATION
    
    % FILTER DATA
    disp('')
    
    % POST-FILTER DATA PROCESSING
    disp('PERFORMING POST-FILTER PROCESSING')
    
    % QUICK SNR
    
    % TRIAL LOOP
    
        % WINDOW
        
        % TAPER
        
        % CORRELATE
        
        % CLUSTER
        
        % ALIGN
        
        % PREEN
        
        % NEXT TRIAL/USE THESE TIMES FOR NEXT TRIAL?
        
    % NEXT FILTER/USE THESE TIMES FOR NEXT FILTER
    
    

    
    
    
    
    
% PREPARE DATA (SEPARATE ROUTINE SINCE IT IS LONG)
disp('PREPING DATA FOR ANALYSIS')
data=align_prep(data,CONF);



% QUICK SNR
if(CONF.QCKSNR)
    disp('CALCULATING SNR')
    % GET SNR FOR THE PHASE AND PUT IT IN THE HEADER
    data=ch(data,CONF.SNRFIELD,qcksnr(data,gh(data,CONF.TTFIELD),CONF.NOISWIN,CONF.SIGWIN));
    
    % DEFAULTS
    nrecs=length(data);
    snrcut=[]; nsnrcut=0; 
    snrcutmark=ones(nrecs,1)*32; % ' '
    
    % SNR CUT
    if(CONF.QCKSNRCUT)
        % FIND CUT
        snrcut=(gh(data,CONF.SNRFIELD)<CONF.QCKSNRCUT);
        nsnrcut=nnz(snrcut);
        snrcutmark(snrcut)=88; % 'X'
    end
    
    % WRITE SNRCUT INFO
    if(exist([CONF.OUTPUTBASENAME '.qcksnr'],'file'))
        delete([CONF.OUTPUTBASENAME '.qcksnr']);
    end
    dlmwrite([CONF.OUTPUTBASENAME '.qcksnr'],...
        ['snr cut = ' num2str(CONF.QCKSNRCUT)],'');
    dlmwrite([CONF.OUTPUTBASENAME '.qcksnr'],...
        ['number cut = ' num2str(nsnrcut)],'-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.qcksnr'],' ','-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.window'],...
        'FILENAME     SNR','-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.qcksnr'],...
        [char({data.name}') ones(nrecs,5)*32 ...
        num2str(gh(data,CONF.SNRFIELD)) ones(nrecs,5)*32 ...
        char(snrcutmark)],'-append','delimiter','');
    
    % CUT
    data(snrcut)=[];
end



% WINDOW
if(CONF.WINDOW)
    disp('WINDOWING DATA')
    
    % USER REFINED WINDOW
    if(CONF.USERWIN)
        % INITIAL WINDOW (ALIGNS AND FOCUSES ON PHASE) 
        data=cutim(data,CONF.TTFIELD,CONF.INTWIN(1),CONF.TTFIELD,CONF.INTWIN(2),CONF.FILL,CONF.FILLER);
        
        % ADJUST TIMING TO BE RELATIVE TO PHASE
        [b,e,tt]=gh(data,'b','e',CONF.TTFIELD);
        data=ch(data,'b',b-tt,'e',e-tt);
        
        % REMOVE MEAN
        data=rmean(data);
        
        % USER WINDOW
        [data,CONF.SIGWIN]=userwindow(data,1);
        
        % UPDATE CONFIG
        if(isempty(CONF.SIGWIN)); CONF.SIGWIN=CONF.INTWIN; end % CHECK FOR NO WINDOW
    % AUTO WINDOW (FOR THE BRAVE)
    else
        data=cutim(data,CONF.TTFIELD,CONF.SIGWIN(1),CONF.TTFIELD,CONF.SIGWIN(2),CONF.FILL,CONF.FILLER);
        
        % ADJUST TIMING TO BE RELATIVE TO PHASE
        [b,e,tt]=gh(data,'b','e',CONF.TTFIELD);
        data=ch(data,'b',b-tt,'e',e-tt);
    end
    
    % WRITE WINDOW INFO
    if(exist([CONF.OUTPUTBASENAME '.window'],'file'))
        delete([CONF.OUTPUTBASENAME '.window']);
    end
    dlmwrite([CONF.OUTPUTBASENAME '.window'],...
        ['interactive = ' num2str(CONF.USERWIN)],'');
    dlmwrite([CONF.OUTPUTBASENAME '.window'],...
        ['length = ' num2str(CONF.SIGWIN(2)-CONF.SIGWIN(1))],...
        '-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.window'],' ','-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.window'],...
        'FILENAME     BEGIN     END    DELTA     NPTS',...
        '-append','delimiter','');
    nrecs=length(data); pad=ones(nrecs,5)*32;
    dlmwrite([CONF.OUTPUTBASENAME '.window'],...
        [char({data.name}') pad ...
        num2str(gh(data,'b')+tt) pad ...
        num2str(gh(data,'e')+tt) pad ...
        num2str(gh(data,'delta')) pad ...
        num2str(gh(data,'npts'))],'-append','delimiter','');
end



% REMOVE DEAD
data=rdead(data);



% TAPER
if(CONF.TAPER)
    disp('TAPERING DATA')
    
    % USER REFINED TAPER
    if(CONF.USERTAPER)
        [data,CONF.TAPERTYPE,CONF.TAPERHW,CONF.TAPEROPT]=usertaper(data);
    % AUTO TAPER (FOR THE BRAVE)
    else
        data=taper(data,CONF.TAPERHW,CONF.TAPERTYPE,CONF.TAPEROPT);
    end
    
    % WRITE TAPER INFO
    if(exist([CONF.OUTPUTBASENAME '.taper'],'file'))
        delete([CONF.OUTPUTBASENAME '.taper']);
    end
    dlmwrite([CONF.OUTPUTBASENAME '.taper'],...
        ['interactive = ' num2str(CONF.USERTAPER)],'');
    dlmwrite([CONF.OUTPUTBASENAME '.taper'],...
        ['taper type = ' num2str(CONF.TAPERTYPE)],...
        '-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.taper'],...
        ['taper halfwidths = ' num2str(CONF.TAPERHW)],...
        '-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.taper'],...
        ['taper option = ' num2str(CONF.TAPEROPT)],...
        '-append','delimiter','');
end



% CORRELATE
[records]=combo(data);
if(CONF.UCORR)
    % CUBE RECORDS?
    if(2-menu('CUBE RECORDS?','YES','NO')); records=records.^3; end
    
    % PICK PEAKS AND TROUGHS?
    CONF.ABSXC=logical(2-menu('PICK PEAKS AND TROUGHS?','YES','NO'));
    
    % CHOOSE NUMBER OF PEAKS
    CONF.NPEAKS=2*menu('CORRELEGRAM MAXES TO PICK?','1','3','5','7')-1;
end
disp('CORRELATING (CAN TAKE A MINUTE...)')
[cv,lv,pv]=mcxc(records,[],CONF.NPEAKS,[],CONF.SPACING,[],CONF.NORMXC,CONF.ABSXC,[],CONF.POW2PAD);



% CLUSTER
if(CONF.CLUSTER)
    if(CONF.USERCLUSTER)
        % HEIRARCHIAL LINKAGE
        Z=linkage(1-cv(:,1,1).',CONF.CMETHOD);
        
        % GRAPHICAL SELECTION
        [CONF.GLOBALDIST,color,perm]=usercluster(Z,data,CONF.GLOBALDIST,...
            'xlabel',['Times relative to predicted ' CONF.PHASE ' (sec)']);
        
        % CLUSTER
        T=cluster(Z,'cutoff',CONF.GLOBALDIST,'criterion','distance');
        
        % GET GROUP COLORING
        nrecs=size(records,2);
        ng=max(T);
        iperm=zeros(1,nrecs);
        iperm(perm)=1:nrecs;
        color=color(iperm,:);
        GCOLOR=zeros(ng,3);
        for i=1:ng
            GCOLOR(i,:)=color(find(i==T,1),:);
        end
        clear color perm iperm
    else
        % AUTO CLUSTER (FOR THE BRAVE)
        Z=linkage(1-cv(:,1).',CONF.CMETHOD);
        T=cluster(Z,'cutoff',CONF.GLOBALDIST,'criterion','distance');
        
        % GET GROUP COLORING
        P=pconf;
        cmapfunc=str2func(P.TREECOLORMAP);
        GCOLOR=cmapfunc(max(T));
    end
    
    % WRITE OUT CLUSTER INFO
    if(exist([CONF.OUTPUTBASENAME '.cluster'],'file'))
        delete([CONF.OUTPUTBASENAME '.cluster']);
    end
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],...
        ['clustering option = ' num2str(CONF.CLUSTER)],'');
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],...
        ['interactive = ' num2str(CONF.USERCLUSTER)],...
        '-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],...
        ['clustering distance = ' num2str(CONF.GLOBALDIST)],...
        '-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],' ','-append','delimiter','');
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],...
        'FILENAME     CLUSTER_ID',...
        '-append','delimiter','');
    nrecs=length(data); pad=ones(nrecs,5)*32;
    dlmwrite([CONF.OUTPUTBASENAME '.cluster'],...
        [char({data.name}') pad num2str(T)],'-append','delimiter','');
    if(exist([CONF.OUTPUTBASENAME '.linkage'],'file'))
        delete([CONF.OUTPUTBASENAME '.linkage']);
    end
    dlmwrite([CONF.OUTPUTBASENAME '.linkage'],num2str(Z),'');
end



% SOLVER
[align]=groupeval(T,cv,lv,pv,CONF);




% SELECT




return
end