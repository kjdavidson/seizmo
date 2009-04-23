function [times]=getarrival(data,phase)
%GETARRIVAL    Returns stored phase arrival time from SEIZMO data header
%
%    Usage:    times=getarrival(data,phase)
%
%    Description: GETARRIVAL(DATA,PHASE) searches 'kt(n)' header fields in
%     the SEIZMO structure DATA for the specified phase PHASE.  If found,
%     the matching 't(n)' value is returned.  If not, NaN is returned.
%     In case of multiple entries for the same phase, only the first
%     match found for each record is returned - lower has preference.
%     
%    Notes:
%     - NAME OF PHASE IS CASE SENSITIVE!
%
%    Tested on: Matlab r2007b
%
%    Examples:
%     Ptimes=getarrival(data,'P');
%     sSKStimes=getarrival(data,'sSKS')
%
%    See also: quicksnr, getheader

%     Version History:
%        Jan. 28, 2008 - initial version
%        Feb. 29, 2008 - uses SEISCHK now
%        Mar.  4, 2008 - minor doc update
%        Oct.  8, 2008 - doc update, add history
%        Nov. 16, 2008 - doc update, history fix, rename from PULLARR to
%                        GETARRIVAL, minor code clean
%        Nov. 24, 2008 - minor code cleaning
%        Apr. 23, 2009 - fix nargchk for octave, move usage up
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Apr. 23, 2009 at 20:10 GMT

% todo:

% check nargin
msg=nargchk(2,2,nargin);
if(~isempty(msg)); error(msg); end
    
% grab header values
[kt,t]=getheader(data,'kt','t');

% remove spaces from kt
kt=strtrim(kt);

% number of records
nrecs=numel(data);

% do operations individually
times=nan(nrecs,1);
for i=1:nrecs
    % find first match
    pos=find(strcmp(phase,kt(i,:)),1);
    
    % check for failure
    if(isempty(pos))
        warning('seizmo:getarrival:noPhase',...
            'Could not find phase %s for record %d !',phase,i);
        continue;
    end
    
    % add time
    times(i)=t(i,pos);
end

end
