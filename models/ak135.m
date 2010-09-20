function [mout]=ak135(varargin)
%AK135    Returns the AK135 Earth model
%
%    Usage:    model=ak135()
%              model=ak135(...,'depths',depths,...)
%              model=ak135(...,'dcbelow',false,...)
%              model=ak135(...,'range',[top bottom],...)
%              model=ak135(...,'crust',true|false,...)
%
%    Description: MODEL=AK135() returns a struct containing the 1D radial
%     Earth model AK135.  The struct has the following fields:
%      MODEL.name      - model name ('AK135')
%           .ocean     - always false here
%           .crust     - true/false
%           .isotropic - always true here
%           .refperiod - always 1sec here
%           .flattened - always false here (see FLATTEN_1DMODEL)
%           .depth     - km depths from 0 to 6371
%           .vp        - isotropic p-wave velocity (km/s)
%           .vs        - isotropic s-wave velocity (km/s)
%           .rho       - density (g/cm^3)
%     Note that the model includes repeated depths at discontinuities.
%
%     MODEL=AK135(...,'DEPTHS',DEPTHS,...) returns the model parameters
%     only at the depths in DEPTHS.  DEPTHS is assumed to be in km.  The
%     model parameters are found by linear interpolation between known
%     values.  DEPTHS at discontinuities return values from the deeper
%     (bottom) side of the discontinuity for the first time and from the
%     top side for the second time.  Depths can not be repeated more than
%     twice and must be monotonically non-decreasing.
%
%     MODEL=AK135(...,'DCBELOW',FALSE,...) returns values from the
%     shallow (top) side of the discontinuity the first time a depth is
%     given at one (using the DEPTHS option) if DCBELOW is FALSE.  The
%     default is TRUE (returns value from bottom-side the first time).  The
%     second time a depth is used, the opposite side is given.
%
%     MODEL=AK135(...,'RANGE',[TOP BOTTOM],...) specifies the range of
%     depths that known model parameters are returned.  [TOP BOTTOM] must
%     be a 2 element array in km.  Note this does not block depths given by
%     the DEPTHS option.
%
%     MODEL=AK135(...,'CRUST',TRUE|FALSE,...) indicates if the crust of
%     AK135 is to be removed or not.  Setting CRUST to FALSE will return a
%     crustless model (the mantle is extended to the surface using linear
%     interpolation).
%
%    Notes:
%     - AK135 reference:
%        Kennett, Engdahl, & Buland 1995, Constraints on seismic velocities
%        in the Earth from traveltimes, Geophys. J. Int. 122, pp. 108-124
%
%    Examples:
%     Plot parameters for the top 400km of the crustless version:
%      model=ak135('r',[0 400],'c',false);
%      figure;
%      plot(model.depth,model.vp,'r',...
%           model.depth,model.vs,'g',...
%           model.depth,model.rho,'b','linewidth',2);
%      title('AK135')
%      legend({'Vp' 'Vs' '\rho'})
%
%    See also: IASP91, PREM

%     Version History:
%        May  19, 2010 - initial version
%        May  20, 2010 - discon on edge handling, quicker
%        May  24, 2010 - added several struct fields for info
%        Aug.  8, 2010 - minor doc touch, dcbelow option
%        Aug. 17, 2010 - added reference
%        Sep. 19, 2010 - doc update, better discontinuity support
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Sep. 19, 2010 at 14:45 GMT

% todo:

% check nargin
if(mod(nargin,2))
    error('seizmo:ak135:badNumInputs',...
        'Unpaired Option/Value!');
end

% option defaults
varargin=[{'d' [] 'b' true 'c' true 'r' [0 6371]} varargin];

% check options
if(~iscellstr(varargin(1:2:end)))
    error('seizmo:ak135:badOption',...
        'All Options must be specified with a string!');
end
for i=1:2:numel(varargin)
    % skip empty
    skip=false;
    if(isempty(varargin{i+1})); skip=true; end

    % check option is available
    switch lower(varargin{i})
        case {'d' 'dep' 'depth' 'depths'}
            if(~isempty(varargin{i+1}))
                if(~isreal(varargin{i+1}) || any(varargin{i+1}<0 ...
                        | varargin{i+1}>6371) || any(isnan(varargin{i+1})))
                    error('seizmo:ak135:badDEPTHS',...
                        ['DEPTHS must be real-valued km depths within ' ...
                        'the range [0 6371] in km!']);
                elseif(any(diff(varargin{i+1})<0))
                    error('seizmo:ak135:badDEPTHS',...
                        'DEPTHS must be monotonically non-increasing!');
                elseif(any(histc(varargin{i+1},...
                        varargin{i+1}([find(diff(varargin{i+1}));end]))>3))
                    error('seizmo:ak135:badDEPTHS',...
                        'DEPTHS has values repeated 3+ times!');
                end
            end
            depths=varargin{i+1}(:);
        case {'dcb' 'dc' 'below' 'b' 'dcbelow'}
            if(skip); continue; end
            if(~islogical(varargin{i+1}) || ~isscalar(varargin{i+1}))
                error('seizmo:ak135:badDCBELOW',...
                    'DCBELOW must be a TRUE or FALSE!');
            end
            dcbelow=varargin{i+1};
        case {'c' 'cru' 'crust'}
            if(skip); continue; end
            if(~islogical(varargin{i+1}) || ~isscalar(varargin{i+1}))
                error('seizmo:ak135:badCRUST',...
                    'CRUST must be a TRUE or FALSE!');
            end
            crust=varargin{i+1};
        case {'r' 'rng' 'range'}
            if(skip); continue; end
            if(~isreal(varargin{i+1}) || numel(varargin{i+1})~=2)
                error('seizmo:ak135:badRANGE',...
                    ['RANGE must be a 2 element vector specifying ' ...
                    '[TOP BOTTOM] in km!']);
            end
            range=sort(varargin{i+1});
        otherwise
            error('seizmo:ak135:badOption',...
                'Unknown Option: %s',varargin{i});
    end
end

% the ak135 model
model=[
     0.000      5.8000      3.4600      2.7200
    20.000      5.8000      3.4600      2.7200
    20.000      6.5000      3.8500      2.9200
    35.000      6.5000      3.8500      2.9200
    35.000      8.0400      4.4800      3.3198
    77.500      8.0450      4.4900      3.3455
   120.000      8.0500      4.5000      3.3713
   165.000      8.1750      4.5090      3.3985
   210.000      8.3000      4.5180      3.4258
   210.000      8.3000      4.5230      3.4258
   260.000      8.4825      4.6090      3.4561
   310.000      8.6650      4.6960      3.4864
   360.000      8.8475      4.7830      3.5167
   410.000      9.0300      4.8700      3.5470
   410.000      9.3600      5.0800      3.7557
   460.000      9.5280      5.1860      3.8175
   510.000      9.6960      5.2920      3.8793
   560.000      9.8640      5.3980      3.9410
   610.000     10.0320      5.5040      4.0028
   660.000     10.2000      5.6100      4.0646
   660.000     10.7900      5.9600      4.3714
   710.000     10.9229      6.0897      4.4010
   760.000     11.0558      6.2095      4.4305
   809.500     11.1353      6.2426      4.4596
   859.000     11.2221      6.2798      4.4885
   908.500     11.3068      6.3160      4.5173
   958.000     11.3896      6.3512      4.5459
  1007.500     11.4705      6.3854      4.5744
  1057.000     11.5495      6.4187      4.6028
  1106.500     11.6269      6.4510      4.6310
  1156.000     11.7026      6.4828      4.6591
  1205.500     11.7766      6.5138      4.6870
  1255.000     11.8491      6.5439      4.7148
  1304.500     11.9200      6.5727      4.7424
  1354.000     11.9895      6.6008      4.7699
  1403.500     12.0577      6.6285      4.7973
  1453.000     12.1245      6.6555      4.8245
  1502.500     12.1912      6.6815      4.8515
  1552.000     12.2550      6.7073      4.8785
  1601.500     12.3185      6.7326      4.9052
  1651.000     12.3819      6.7573      4.9319
  1700.500     12.4426      6.7815      4.9584
  1750.000     12.5031      6.8052      4.9847
  1799.500     12.5631      6.8286      5.0109
  1849.000     12.6221      6.8515      5.0370
  1898.500     12.6804      6.8742      5.0629
  1948.000     12.7382      6.8972      5.0887
  1997.500     12.7956      6.9194      5.1143
  2047.000     12.8526      6.9418      5.1398
  2096.500     12.9096      6.9627      5.1652
  2146.000     12.9668      6.9855      5.1904
  2195.500     13.0222      7.0063      5.2154
  2245.000     13.0783      7.0281      5.2403
  2294.500     13.1336      7.0500      5.2651
  2344.000     13.1894      7.0720      5.2898
  2393.500     13.2465      7.0931      5.3142
  2443.000     13.3018      7.1144      5.3386
  2492.500     13.3585      7.1369      5.3628
  2542.000     13.4156      7.1586      5.3869
  2591.500     13.4741      7.1807      5.4108
  2640.000     13.5312      7.2031      5.4345
  2690.000     13.5900      7.2258      5.4582
  2740.000     13.6494      7.2490      5.4817
  2740.000     13.6494      7.2490      5.4817
  2789.670     13.6530      7.2597      5.5051
  2839.330     13.6566      7.2704      5.5284
  2891.500     13.6602      7.2811      5.5515
  2891.500      8.0000      0.0000      9.9145
  2939.330      8.0382      0.0000      9.9942
  2989.660      8.1283      0.0000     10.0722
  3039.990      8.2213      0.0000     10.1485
  3090.320      8.3122      0.0000     10.2233
  3140.660      8.4001      0.0000     10.2964
  3190.990      8.4861      0.0000     10.3679
  3241.320      8.5692      0.0000     10.4378
  3291.650      8.6496      0.0000     10.5062
  3341.980      8.7283      0.0000     10.5731
  3392.310      8.8036      0.0000     10.6385
  3442.640      8.8761      0.0000     10.7023
  3492.970      8.9461      0.0000     10.7647
  3543.300      9.0138      0.0000     10.8257
  3593.640      9.0792      0.0000     10.8852
  3643.970      9.1426      0.0000     10.9434
  3694.300      9.2042      0.0000     11.0001
  3744.630      9.2634      0.0000     11.0555
  3794.960      9.3205      0.0000     11.1095
  3845.290      9.3760      0.0000     11.1623
  3895.620      9.4297      0.0000     11.2137
  3945.950      9.4814      0.0000     11.2639
  3996.280      9.5306      0.0000     11.3127
  4046.620      9.5777      0.0000     11.3604
  4096.950      9.6232      0.0000     11.4069
  4147.280      9.6673      0.0000     11.4521
  4197.610      9.7100      0.0000     11.4962
  4247.940      9.7513      0.0000     11.5391
  4298.270      9.7914      0.0000     11.5809
  4348.600      9.8304      0.0000     11.6216
  4398.930      9.8682      0.0000     11.6612
  4449.260      9.9051      0.0000     11.6998
  4499.600      9.9410      0.0000     11.7373
  4549.930      9.9761      0.0000     11.7737
  4600.260     10.0103      0.0000     11.8092
  4650.590     10.0439      0.0000     11.8437
  4700.920     10.0768      0.0000     11.8772
  4801.580     10.1415      0.0000     11.9414
  4851.910     10.1739      0.0000     11.9722
  4902.240     10.2049      0.0000     12.0001
  4952.580     10.2329      0.0000     12.0311
  5002.910     10.2565      0.0000     12.0593
  5053.240     10.2745      0.0000     12.0867
  5103.570     10.2854      0.0000     12.1133
  5153.500     10.2890      0.0000     12.1391
  5153.500     11.0427      3.5043     12.7037
  5204.610     11.0585      3.5187     12.7289
  5255.320     11.0718      3.5314     12.7530
  5306.040     11.0850      3.5435     12.7760
  5356.750     11.0983      3.5551     12.7980
  5407.460     11.1166      3.5661     12.8188
  5458.170     11.1316      3.5765     12.8387
  5508.890     11.1457      3.5864     12.8574
  5559.600     11.1590      3.5957     12.8751
  5610.310     11.1715      3.6044     12.8917
  5661.020     11.1832      3.6126     12.9072
  5711.740     11.1941      3.6202     12.9217
  5813.160     11.2134      3.6337     12.9474
  5863.870     11.2219      3.6396     12.9586
  5914.590     11.2295      3.6450     12.9688
  5965.300     11.2364      3.6498     12.9779
  6016.010     11.2424      3.6540     12.9859
  6066.720     11.2477      3.6577     12.9929
  6117.440     11.2521      3.6608     12.9988
  6168.150     11.2557      3.6633     13.0036
  6218.860     11.2586      3.6653     13.0074
  6269.570     11.2606      3.6667     13.0100
  6320.290     11.2618      3.6675     13.0117
  6371.000     11.2622      3.6678     13.0122];

% remove crust if desired
if(~crust)
    % linear extrapolation to the surface
    model(1,:)=[0 8.0359 4.4718 3.2986];
    model(2:4,:)=[];
end

% interpolate depths if desired
if(~isempty(depths))
    %depths=depths(depths>=range(1) & depths<=range(2));
    [bot,top]=interpdc1(model(:,1),model(:,2:end),depths);
    if(dcbelow)
        [tidx,tidx]=unique(depths);
        top(tidx,:)=bot(tidx,:);
        model=[depths top];
    else
        [tidx,tidx]=unique(depths,'first');
        bot(tidx,:)=top(tidx,:);
        model=[depths bot];
    end
else
    % get index range (assumes depths are always non-decreasing in model)
    idx1=find(model(:,1)>range(1),1);
    idx2=find(model(:,1)<range(2),1,'last');
    
    % are range points amongst the knots?
    tf=ismember(range,model(:,1));
    
    % if they are, just use the knot, otherwise interpolate
    if(tf(1))
        idx1=idx1-1;
    else
        vtop=interp1q(model(idx1-1:idx1,1),model(idx1-1:idx1,2:end),range(1));
    end
    if(tf(2))
        idx2=idx2+1;
    else
        vbot=interp1q(model(idx2:idx2+1,1),model(idx2:idx2+1,2:end),range(2));
    end
    
    % clip model
    model=model(idx1:idx2,:);
    
    % pad range knots if not there
    if(~tf(1)); model=[range(1) vtop; model]; end
    if(~tf(2)); model=[model; range(2) vbot]; end
end

% array to struct
mout.name='AK135';
mout.ocean=false;
mout.crust=crust;
mout.isotropic=true;
mout.refperiod=1;
mout.flattened=false;
mout.depth=model(:,1);
mout.vp=model(:,2);
mout.vs=model(:,3);
mout.rho=model(:,4);

end
