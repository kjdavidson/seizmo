function [isleap]=isleapyear(year)
%ISLEAPYEAR    True if year is a leap year
%
%    Usage:    leapyears=isleapyear(years)
%
%    Description: ISLEAPYEAR(YEARS) returns a logical array equal in size
%     to YEARS with values set to true for the corresponding elements in
%     YEARS that are leap years.
%
%    Notes:
%     - Gregorian calendar only!
%     - Only valid for 1+ AD unless corrections are made to BC years
%       (1 BC == 0, 2 BC == -1, ...)
%
%    Tested on: Matlab r2007b
%
%    Examples:
%     Takes into account the century rule and the exception so that
%     isleapyear([1900 1904 2000 2004]) returns [0 1 1 1].
%
%    See also: julday, calday, leapseconds

%     Version History:
%        Oct. 28, 2008 - initial version
%        Apr. 23, 2009 - move usage up
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Apr. 23, 2009 at 21:30 GMT

% todo:

% require numeric years
if(~isnumeric(year))
    error('seizmo:isleapyear:badYear','YEARS must be numeric!');
end

% force years to be integer
year=floor(year);

% every 4 years unless it falls on a century except every 400 years
isleap=(~mod(year,4) & (mod(year,100) | ~mod(year,400)));

end
