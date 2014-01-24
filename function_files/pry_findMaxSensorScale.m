function [stimLMS, stimRGB] = pry_findMaxSensorScale(dpy,stimLMS,backRGB,sensors,expt)%% function [stimLMS, stimRGB] = pry_findMaxSensorScale(display,stimLMS,backRGB,sensors)%%AUTHOR: Wandell, Baseler, Press, Wade% Based on findMaxConeScale - for multispectral stimulation%DATE:   09.08.98%PURPOSE:%%   Calculate the maximum scale factor for the stimLMS given the%   background and display properties. %   %   When stimLMS.dir is in a cone isolating direction, the maximum%   scale factor is also to the max cone contrast available for that cone%   class. %   %   When stimLMS is not in a cone isolating direction, you are on%   your own.  That's why we call it scale.%  % ARGUMENTS%%  display:  .spectra is  a 361x3 display primaries%             %  stimLMS:  The field%             .dir     defines the color direction. By convention,%                X.dir is a n-vector with a maximum value of 1.0%             .scale   a vector of scale factors%             %  backRGB:  .dir    defines the color direciton. By convention,%                X.dir is a n-vector with a maximum value of 1.0%             .scale  a single scale factor%			  (optional, [0.5 0.5 0.5] default)%  sensors:  361x3 matrix of sensor wavelength sensitivities%             (optional, - use Baylor nomogram as default).%% RETURNS%            % stimLMS:  %           .maxScale is the highest scale factor.  This is the%           .maximum contrast when stimLMS.dir is cone isolating.%             % stimRGB: %          .dir is set to display primary direction corresponding to this%           lms direction. %% 10.29.98:	Swapped order of parameters.% 11.17.98: RFD & WAP: added scaling for lmsBack.%	NOTE: as of now, the RGB values returned are scaled by the%	background LMS so that they accurately reflect the requested%	LMS values in stimLMS.  (i.e., now you will get your requested%	LMS contrasts no matter what the background color direction.)% 04.13.13 ARW: Now accepts multispectral display and LMS% Set up input defaults%if ~isfield(dpy,'backRGB')    error    disp('Cone2RGB: Using default background of [0.5 0.5 0.5]')  dpy.backRGB.dir = [1 1 1]';  dpy.backRGB.scale = 0.5;endbackRGB.dir=dpy.backRGB.dir(:);backRGB.scale=dpy.backRGB.scale;if ~exist('sensors','var')    error    wavelengths=400:2:700;    disp('Assuming normal trichromat sensors');    conepeaks=[564 534 437]; %% N.B. additional cone peaks can be added here e.g. for additional cones/melanopsin        coneSpectra=BaylorNomogram(wavelengths(:),conepeaks(:));    sensors=coneSpectra'; % nWaves x mSensorsendif isfield(dpy,'spectra')==0  error('The display structure requires a spectra field');else  rgb2lms = sensors'*dpy.spectra;  lms2rgb = pinv(rgb2lms); % pinv is here in case we have nsensors ~= nprimariesend% Check whether the background RGB values are within the unit cube% meanRGB = backRGB.dir(:) * backRGB.scale; % err = checkRange(meanRGB,[0 0 0]',[1 1 1]');% if err ~= 0%   error('meanRGB out of range')% end%  Determine the background LMS direction %lmsBack = rgb2lms * meanRGB;%  Scale stimulus LMS by the background LMSstimLMS.dir=expt.stim.chrom.stimLMS.dir()';scaledStimLMS = stimLMS.dir(:) .* lmsBack;%  Determine the stimulus RGB direction  stimRGB.dir = lms2rgb*scaledStimLMS;%stimRGB.dir = rgb2lms\scaledStimLMS;stimRGB.dir = stimRGB.dir/max(abs(stimRGB.dir));% We want to find the largest scale factor such that the% background plus stimulus fall on the edges of the unit cube.% We begin with the zero sides of the unit cube, % %      zsFactor*(stimRGB.dir) + meanRGB = 0% % Solving this equation for zsFactor, we obtain%sFactor = -(meanRGB) ./ stimRGB.dir;%  The smallest scale factor that bumps into this side is% zsFactor = min(abs(sFactor));% Now find the sFactor that limits us on the 1 side of the unit RGB cube.% %       usFactor*stimRGB.dir + meanRGB = 1%   sFactor = (1 - meanRGB) ./ stimRGB.dir;usFactor = min(abs(sFactor));%  Return the smaller of these two factors%  stimRGB.maxScale = min(zsFactor,usFactor)% Next, convert these values into LMS contrast terms.% % General discussion:% %  For each scale factor applied to the stimulus, there is a%  corresponding contrast.  But, this must be computed using both%  the stimLMS and the backLMS.  So, contrast and stimLMS.scale%  are not uniquely linked, but they depend on the background.% %  When stimRGB.scale is less than stimRGB.maxScale, we are sure that we%  are within the unit cube on this background.  What is the%  highest scale level we can obtain for the various cone classes%  at this edge? % % Compute the LMS coordinates of the [stimulus plus background] and% the background alone.  Use these to compute the max scale% factor we can use in the LMS direction.  This is the maximum% contrast when we are in a cone isolating direction.%  lmsStimPlusBack = rgb2lms*(stimRGB.maxScale*stimRGB.dir + backRGB.dir*backRGB.scale)stimLMS.maxScale = max(abs((lmsStimPlusBack  - lmsBack) ./ lmsBack))backLMS.dir = lmsBack;backLMS.scale = 1;return