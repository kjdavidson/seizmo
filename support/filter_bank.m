function [bank]=filter_bank(range,option,width,offset)
%FILTER_BANK    Makes a set of narrow-band bandpass filters
%
%    Usage: [bank]=filter_bank(range,option,width,offset)
%
%    Description:  FILTER_BANK(RANGE,OPTION,WIDTH,OFFSET) returns a bank of
%     bandpass filters.  Each row in the bank corresponds to a separate
%     filter, with the first column giving the center frequency and the 2nd
%     and 3rd columns giving the passband corner frequencies for that 
%     filter.  RANGE is a two element vector giving the frequency range for
%     the filter bank.  OPTION is either 'constant' or 'variable' and 
%     indicates whether the width and offset for filters in the bank are 
%     constant over the frequency range (WIDTH and OFFSET are taken in mHz)
%     or if the width and offset varies (WIDTH and OFFSET are assumed to be
%     given as a fraction of the center frequency).
%
%    Examples:
%      Build a filter bank over the range 0.01 to 0.1 Hz with filter widths
%      equal to 20% the center frequency and adjacent filters separated by 
%      10% of the larger center frequency:
%        bank=filter_bank([0.01 0.1],'variable',0.2,0.1)
%
%      Build a filter bank over the range 0.01 to 0.1 Hz with filter widths
%      of constant 10 mHz and offset by 5 mHz:
%        bank=filter_bank([0.01 0.1],'constant',0.010,0.005)
%
%    See also: iirfilter

% check number of arguments
msg=nargchk(4,4,nargin);
if(~isempty(msg)); error(msg); end;

% check arguments
if(numel(range)>2 || ~isnumeric(range) || any(range<0))
    error('SAClab:filter_bank:badInput',...
        'RANGE must be an array of 2 positive frequencies (Hz)')
end
if(~isscalar(width) || ~isnumeric(width) || width<0)
    error('SAClab:filter_bank:badInput','Filter width must be >0')
end
if(~isscalar(offset) || ~isnumeric(offset) || offset<0)
    error('SAClab:filter_bank:badInput','Filter offset must be >0')
end

% fix range
range=sort(range(:));

% decide how to make bank based on option
if(isequal(option,'constant'))
    bank(:,1)=range(1):offset:range(2);
    bank(:,2)=bank(:,1)-width/2;
    bank(:,3)=bank(:,1)+width/3;
elseif(isequal(option,'variable'))
    bank(1,1)=range(1);
    width1=1-width/2;
    width2=1+width/2;
    offset=1+offset;
    count=1;
    while(1)
        bank(count,2)=bank(count,1)*width1;
        bank(count,3)=bank(count,1)*width2;
        count=count+1;
        bank(count,1)=bank(count-1,1)*offset;
        if(bank(count,1)>range(2))
            bank(count,:)=[];
            break;
        end
    end
else
    error('SAClab:filter_bank:badInput','Unknown option: %s',option)
end

end
