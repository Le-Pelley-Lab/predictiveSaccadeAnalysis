function ProcessSaccades(subjectlist, ROIs, varargin)
% ProcessSaccades: I-VT Algorithm for determining saccade direction and
% latency from Tobii eyetracker data
%
% ProcessSaccades(subjectlist, ROIs, [fixationCoords], [discardAnticipatorySaccades], [discardOutsideFixationSaccades], [graphVersion])
% subjectlist is a vector of participant numbers, e.g., [1:5 8 9:15].
%
% ROIs is a list of the coordinates of stimuli of interest (in PTB pixel
% format), e.g., [0 0 500 500; 500 500 1000 1000]. If ROIs is set to 1, assumes saccades will be separated according to
% whether they are directed left or right relative to the fixation point.
% If ROIs set to 2, assumes saccades will be separated according to whether
% they are directed up or down relative to the fixation point.
%
% fixationCoords is an optional variable that codes for the participant's
% starting fixation point on each trial. If left out, algorith assumes the
% centre of the screen.
%
% discardAnticipatorySaccades is optional. If set to 0, anticipatory saccades will not be
% discarded. Default value is to discard anticipatory saccades.
%
% discardOutsideFixationSaccades is optional. If set to 0, trials with no
% valid gaze samples recorded within 100 px of the fixation point in first
% 80 ms will not be discarded. Default value is to discard.

% Screen details
res = [1920 1080];

if nargin<1
    error('missing inputs')
elseif nargin > 6
    error('too many inputs')
end

nVarargs = length(varargin);
if nVarargs < 3
    varargin{3} = [];
end
if isempty(varargin{1})
    varargin{1} = [res(1)/2 res(2)/2];
end
if isempty(varargin{2})
    varargin{2} = 1;
end
if isempty(varargin{3})
    varargin{3} = 1;
end
if isempty(varargin{4})
	varargin{4} = false;
end
fixationCoords = varargin{1};
discardAnticipatory = varargin{2};
discardOutsideFixation = varargin{3};
graphVersion = varargin{4};

% if we do not include ROIs, then assume default of predictiveness experimental program
if isempty(ROIs)
    scr_centre = res./2;
    stimLocs = 6;
    circ_diam = 200;
    stim_size = 92;
    for i = 0 : stimLocs - 1    % Define rects for stimuli and line segments
        ROIs(i+1,:) = [scr_centre(1) - circ_diam * sin(i*2*pi/stimLocs) - stim_size / 2   scr_centre(2) - circ_diam * cos(i*2*pi/stimLocs) - stim_size / 2   scr_centre(1) - circ_diam * sin(i*2*pi/stimLocs) + stim_size / 2   scr_centre(2) - circ_diam * cos(i*2*pi/stimLocs) + stim_size / 2];
    end
end

% Algorithm parameters
WindowLength = 20;
vThreshold = 40;
fixGapDurThresh = 10;
fixGapAngleThresh = 0.5;
medianFilterWindowLength = 5;
if discardAnticipatory == 1
    anticipationThreshold = 80;
else
    anticipationThreshold = 0;
end


% determine number subjects
maxSub = length(subjectlist);
maxPhases = [2,1]; % Session 1 = 2 phases; Session 2 = 1 phase
maxTrials = [180, 288; 468, 0]; % Sess 1 Ph 1 = 180 trials, Sess 1 Ph 2 = 288 trials. Sess 2 Ph 1 = 468 trials

if graphVersion
	trialsToCheck = []; % input a list of trials here for graphs to be generated
end
%Initiate data array
%trialMovements = struct(cell(maxSub,maxTrials);


%Calculate the centre point of each ROI
if numel(ROIs) > 1
    stimCentre = [(ROIs(:,3)+ROIs(:,1))/2 (ROIs(:,4)+ROIs(:,2))/2];
    withinAngle = 30; % max degrees of polar angle from stimulus for saccade to be classified as towards the stim.
elseif ROIs == 1
    stimCentre(1,:) = [1 res(2)/2]; %left location
    stimCentre(2,:) = [res(1) res(2)/2]; %right location
    withinAngle = 89; %set to whatever is appropriate, but be wary of 90 degs as classifier currently checks for >= this number
else
    stimCentre(1,:) = [res(1)/2 0]; %top location
    stimCentre(2,:) = [res(1)/2 res(2)]; %bottom location
    withinAngle = 89; %set to whatever is appropriate, but be wary of 90 degs as classifier currently checks for >= this number
end

%create vectors from the fixation point to the centre of the ROIs
stimVector = stimCentre - repmat(fixationCoords,size(stimCentre,1),1);

subStep = 0;
for sub = subjectlist
    
    subStep = subStep+1;
    
    for session = 1:2
        
        GazeFileName = ['Data\EyeData\GazeDataP', num2str(sub), 'S', num2str(session), '.mat']; %CHANGE THIS FOR EACH ANALYSIS
        load(GazeFileName, 'ALLGAZEDATA');
        
        for phase = 1:maxPhases(session)
            
            saccadeSessionData(session).saccadePhaseData(phase).summarySaccadeData = zeros(maxTrials(session, phase),size(stimVector,1)+9); %initiate summary data array
            
            clc; disp(['Processing Subject ',num2str(sub), ' Session ', num2str(session), ' Phase ', num2str(phase)])
            
            
            
            for t = 1:maxTrials(session, phase)
                
                clc; disp(['Sub ', num2str(sub), ' Session ', num2str(session), ' Phase ', num2str(phase), ' Trial ', num2str(t)]);
                
                %load data file for current trial
                savedEGdata = ALLGAZEDATA.EGdataPhase(phase+1).EGdataTrial(t).data;
                
                sampleInterval = ((savedEGdata(end,1)-savedEGdata(1,1))/1000)/size(savedEGdata,1); % determine the average interval between each successive eyetracker sample
                sampleWindowLength = round((WindowLength/2)/sampleInterval); %determine how many samples for half of the saccade detection Window
                
                GazeData = savedEGdata;
                
                % prepare essential EG data
                EGerr = [mean(GazeData(:,14)==4) mean(GazeData(: ,27)==4)]; % calc error on each eye
                if EGerr(1) < EGerr(2)
                    GazeData = GazeData(:,[1 2 3 4 10 11 12 14 8 9]); % use Left eye - timestamp EyePos XYZ, GazePos XYZ, Validity, GazePos XY 2d coordinates
                else
                    GazeData = GazeData(:,[1 15 16 17 23 24 25 27 21 22]); % use Right eye - timestamp EyePos XYZ, GazePos XYZ, Validity, GazePos XY 2d coordinates
                end
                
                % rescale 2d coordinates from proportion to pixels
                GazeData(:,9) = bsxfun(@times,GazeData(:,9),res(1));
                GazeData(:,10) = bsxfun(@times,GazeData(:,10),res(2));
                
                velSessionData(session).velPhaseData(phase).xRawTrialData{t} = GazeData(:,9);
                velSessionData(session).velPhaseData(phase).yRawTrialData{t} = GazeData(:,10);
                
                % Interpolate Gaps
                GapsBeforeFill = sum(GazeData(:,8)==4)/size(GazeData,1);
                if GapsBeforeFill < 1 && GapsBeforeFill > 0 % valid data exists
                    GazeData = fillMissing(GazeData, 75, sampleInterval); %interpolate gaps in data
                end
                GapsAfterFill = sum(GazeData(:,8)==4)/size(GazeData,1);
                
                % apply moving average filter to smooth out noise in the gaze
                % position samples
                newX = zeros(size(GazeData(:,5)));
                newY = zeros(size(GazeData(:,6)));
                newZ = zeros(size(GazeData(:,7)));
                
                for ss = 1:size(GazeData,1)
                    windowStep = 2;
                    windowCheck = 1;
                    while windowCheck == 1
                        windowStart = ss-windowStep;
                        windowEnd = ss+windowStep;
                        if windowStart < 1 || windowEnd > size(GazeData,1)
                            windowStep = windowStep-1;
                        elseif sum(GazeData(windowStart:windowEnd,8)==4) > 1
                            windowStep = windowStep-1;
                        else
                            windowCheck = 0;
                        end
                    end
                    
                    if windowStep > -1
                        newX(ss) = mean(GazeData(windowStart:windowEnd,5));
                        newY(ss) = mean(GazeData(windowStart:windowEnd,6));
                        newZ(ss) = mean(GazeData(windowStart:windowEnd,7));
                    else
                        newX(ss) = 0;
                        newY(ss) = 0;
                        newZ(ss) = 0;
                    end
                end
                
                % Fix this so that we can store the raw unfiltered coords as
                % well
                GazeData(:,5) = newX;
                GazeData(:,6) = newY;
                GazeData(:,7) = newZ;
                
                % Start of I-VT classifier
                velocity = zeros(1, size(GazeData,1)-sampleWindowLength); % set up velocity array
                angle = zeros(1, size(GazeData,1)-sampleWindowLength); % set up angle array
                movType = zeros(1, size(GazeData,1)-sampleWindowLength); % set up movement type array
                
                % check if gaze is within 100 px of scr centre for any sample in first 80ms (if discard set to on)
                withinCentre = 1;
                if discardOutsideFixation == 1
                    withinCentre = 0;
                    if size(GazeData,1) > 80/sampleInterval
                        for ss = 1 : round(80/sampleInterval)
                            if sqrt((GazeData(ss,9)-fixationCoords(1))^2+(GazeData(ss,10)-fixationCoords(2))^2) < 100 %pythagoras
                                withinCentre = 1;
                                break
                            end
                        end
                    end
                end
                aa = 1;
                bb = 0; %used later on to keep track of different movements in trial
                movList = {};
                for s = sampleWindowLength+1:size(GazeData,1)-sampleWindowLength % step through trial data with a moving window of ~20ms (8 samples)
                    
                    if sum(GazeData(s-sampleWindowLength:s+sampleWindowLength,8)==4)>0
                        velocity(s) = -1;  %if there is any missing data in the velocity window, velocity = -1 and move on
                    else
                        eyePoint = repmat(GazeData(s,2:4),2,1);
                        gazePoint = GazeData([s-sampleWindowLength s+sampleWindowLength],5:7);
                        gazeVector = eyePoint-gazePoint; % calculate vector from beginning and end gaze point to eye position in centre of time window
                        angle(s) = acosd(dot(gazeVector(1,:),gazeVector(2,:))/(norm(gazeVector(1,:))*norm(gazeVector(2,:)))); %does fancy stuff to determine angle between vectors
                        time = (GazeData(s+sampleWindowLength,1)-savedEGdata(s-sampleWindowLength,1))/1000000; %find time taken from beginning to end of time window in seconds
                        velocity(s) = angle(s)/time; % determine angular velocity in degrees of visual angle/sec
                    end
                    
                    %%%DEMO%%%
                    %              time = [1:length(GazeData(:,1))];
                    %              plot(time, GazeData(:,9)', time, GazeData(:,10)', time, [velocity 0 0 0], time, repmat(30,1,length(time)))
                    %%%%%%%%%%
                    
                    velSessionData(session).velPhaseData(phase).velTrialData{t} = velocity;
                    velSessionData(session).velPhaseData(phase).xTrialData{t} = GazeData(:,5);
                    velSessionData(session).velPhaseData(phase).yTrialData{t} = GazeData(:,6);
                    
                    
                    %I-VT classifier
                    if velocity(s) > vThreshold
                        movType(s) = 2; %mark as saccade
                    elseif velocity(s) > -1
                        movType(s) = 1; %mark as fixation
                    else
                        movType(s) = 0; %mark as gap
                    end
                    
                    if movType(s) ~= movType(s-1) || s == size(GazeData,1)-sampleWindowLength % if detected movement is not the same as that on the previous sample, or we are at the end of the trial
                        bb = bb + 1;
                        if bb > 1 %add the previous eye movement to a higher level list
                            endTime = (currentMov(end,1)+GazeData(s,1))/2;
                            movList(bb-1,:) = {movType(s-1) startTime endTime (endTime-startTime)/1000 latency currentMov currentMov(end,9:10)}; %[movement type, start time, end time, length of movement, movement details, x/y coords of last sample in movement]
                            if movType(s-1) == 1   %if a fixation
                                movList(bb-1,7) = {mean(currentMov(:,9:10),1)}; %calculate mean fixation point over entire fixation
                            end
                        end
                        % collect info for new movement
                        startTime = (GazeData(s,1)+GazeData(s-1,1))/2;
                        latency = (startTime-GazeData(1,1))/1000;
                        currentMov = [];
                        currentMov(1,:) = GazeData(s,:);
                        aa = 2;
                    else %otherwise, add current sample info to current movement.
                        currentMov(aa,:) = GazeData(s,:);
                        aa = aa + 1;
                    end
                end


                %% This is here so that you can view the filtered X and Y coordinates across time for each trial. Useful for debugging
                    if graphVersion
                        
                        if ismember(t, trialsToCheck)
                    
                        distractorOnPoint = find(timeStamps>DistractorOn, 1);
                        targetOnPoint = find(timeStamps > TargetOn, 1);
                        msTime = (GazeData(:,1)-GazeData(1))/1000;
                        acceleration = diff(velocity)/.0033;


                        %scrsz = get(groot,'ScreenSize');

                        posFig = figure(1);
                        subplot(2,2,1)
                        plot(msTime, GazeData(:,9), 'k')
                        hold on
                        plot(msTime, GazeData(:,10), 'b')                   

                        plot(repmat(msTime(distractorOnPoint), [1,1920]), 1:1920, 'r')
                        plot(repmat(msTime(targetOnPoint), [1,1920]), 1:1920, 'g')
                        hold off
                        axis([0, msTime(end), 0, 1920])
                        title('X and Y Coordinates Across Time')
                        xlabel('Time (ms)');
                        ylabel('Pixel');
                        legend('X Coordinates', 'Y Coordinates', 'Distractor On', 'Target On');

                        subplot(2,2,3)
                        plot(GazeData(1:distractorOnPoint-1,9), GazeData(1:distractorOnPoint-1,10), 'k')
                        hold on
                        plot(GazeData(distractorOnPoint:targetOnPoint-1,9), GazeData(distractorOnPoint:targetOnPoint-1,10), 'r')
                        plot(GazeData(targetOnPoint:end,9), GazeData(targetOnPoint:end,10), 'g')
                        hold off
                        axis([0, 1920, 0, 1080])
                        title('X and Y Coordinates')
                        xlabel('X Coords')
                        ylabel('Y Coords')
                        legend('Pre-Distractor', 'Distractor On', 'Target On');

                        subplot(2,2,2)
                        plot(msTime(1:length(velocity)), velocity)
                        hold on
                        plot(msTime(1:length(velocity)), repmat(vThreshold, [length(velocity), 1]), '--k')
                        plot(repmat(msTime(distractorOnPoint), [1,1920]), 1:1920, 'r')
                        plot(repmat(msTime(targetOnPoint), [1,1920]), 1:1920, 'g')
                        hold off
                        axis([0, msTime(end), 0, 100])
                        title('Velocity Across Time')
                        xlabel('Time (ms)')
                        ylabel('Velocity (dva/s)')
                        legend('Velocity', 'Velocity Threshold', 'Distractor On', 'Target On');
                        
%                         subplot(2,2,4)
%                         plot(GazeData(1:distractorOnPoint-1,5), GazeData(1:distractorOnPoint-1,6), 'k')
%                         hold on
%                         plot(GazeData(distractorOnPoint:targetOnPoint-1,5), GazeData(distractorOnPoint:targetOnPoint-1,6), 'r')
%                         plot(GazeData(targetOnPoint:end,5), GazeData(targetOnPoint:end,6), 'g')
%                         hold off
%                         %axis([0, 1920, 0, 1080])
%                         title('X and Y Coordinates')
%                         xlabel('X Coords')
%                         ylabel('Y Coords')
%                         legend('Pre-Distractor', 'Distractor On', 'Target On');


                        subplot(2,2,4)
                        plot(msTime(1:length(acceleration)), acceleration)
                        hold on
                        plot(repmat(msTime(distractorOnPoint), [1,15000]), 1:15000, 'r')
                        plot(repmat(msTime(targetOnPoint), [1,15000]), 1:15000, 'g')
                        hold off
                        axis([0, msTime(end), 0, 15000])
                        title('Approximated Acceleration Across Time')
                        xlabel('Time (ms)')
                        ylabel('Acceleration (dva/s^2)')
                        legend('Acceleration', 'Distractor On', 'Target On');
                        pause;
                        
                        end
                    
                    end

                
%                 %merge adjacent fixations
                if isempty(movList) == 0
%                     fixationIndex = find(cell2mat(movList(:,1))==1); %find index of all fixations in previous trial
%                     
%                     if numelements(fixationIndex) > 1 %if there is more than one fixation
%                         for f = 2:size(fixationIndex,1)
%                             %check time between start and end of fixations
%                             fixGap = (movList{fixationIndex(f),2}-movList{fixationIndex(f-1),3})/1000;
%                             %check angle between fixation points
%                             fixGapEyePos = repmat((movList{fixationIndex(f),6}(1,2:4) + movList{fixationIndex(f-1),6}(end,2:4))/2,2,1); %calculate average eye position across both fixations
%                             fixGapGazePos = [movList{fixationIndex(f),6}(1,5:7); movList{fixationIndex(f-1),6}(end,5:7)];
%                             fixGapGazeVector = fixGapEyePos-fixGapGazePos; % create vectors
%                             fixGapAngle = acosd(dot(fixGapGazeVector(1,:),fixGapGazeVector(2,:))/(norm(fixGapGazeVector(1,:))*norm(fixGapGazeVector(2,:)))); %angle between two vectors
%                             
%                             if fixGap < fixGapDurThresh %&& fixGapAngle < fixGapAngleThresh %if fixations are close enough in time and space, merge
%                                 movList{fixationIndex(f-1),4} = sum(sum([movList{fixationIndex(f-1):fixationIndex(f),4}])); %sum all the durations together
%                                 movList{fixationIndex(f-1),3} = movList{fixationIndex(f),3};   %change end time to final sample
%                                 for gg = fixationIndex(f-1)+1:fixationIndex(f) %combines all of the data points across both fixations and anything in between
%                                     movList{fixationIndex(f-1),6} = [cell2mat(movList(fixationIndex(f-1),6)); cell2mat(movList(gg,6))];
%                                 end
%                                 movList(fixationIndex(f-1)+1:fixationIndex(f),1) = {-1}; %delete old movements
%                                 movList(fixationIndex(f-1),7) = {mean(movList{fixationIndex(f-1),6}(:,9:10))}; %determine new fixation point average
%                             end
%                         end
%                     end
%                     index = find([movList{:,1}]==-1); %remove old fixations from list
%                     movList(index,:) = [];
                    subMovements(subStep).sessionMovements(session).phaseMovements(phase).trialMovements(t) = {movList};
                else
                    subMovements(subStep).sessionMovements(session).phaseMovements(phase).trialMovements(t) = {0};
                end
                
                
                discardTrial = 0;
                anticipatorySaccade = 0;
                outsideFixation = 0;
                noSaccades = 0;
                noValidData = 0;
                
                %find first saccade
                if isempty(movList) == 0
                    saccList = cell2mat(movList(:,1));
                    saccIdx = find(saccList(:,1)==2);
                    
                    %idx = find(saccList(:,1)==2,1,'first'); %find the index of the first saccade
                    foundSaccade = 0;
                    if isempty(saccIdx) == 0
                        aa = 1;
                        idx = saccIdx(aa);
                        while foundSaccade == 0 && aa <= sum(saccList(:,1)==2)
                            idx = saccIdx(aa);
                            foundSaccade = 1;
                            saccadeLength = movList{idx,4};
                            if saccadeLength < fixGapDurThresh;
                                foundSaccade = 0;
                                aa = aa + 1;
                            elseif saccadeLength > fixGapDurThresh && aa > 1
                                qq = 1;
                            end
                            
                        end
                        fixIdx = find(saccList(:,1)==1); %indexes of fixations
                        nextFix = fixIdx(fixIdx>idx); %find next fixation after first saccade
                        saccadeLatency = movList{idx,5}; %find latency of first saccade
                        
                        if saccadeLatency < anticipationThreshold %if anticipatory saccade, or no samples near fixation within first 80ms, mark to be discarded
                            discardTrial = 1;
                            anticipatorySaccade = 1; %mark as anticipatory
                        elseif withinCentre == 0
                            discardTrial = 1;
                            outsideFixation = 1;
                        end
                        
                        
                        endCoords = movList{idx,7}; %find end point of first saccade
                        
                        saccadeVector = [endCoords(1) - fixationCoords(1) endCoords(2) - fixationCoords(2)]; %calculate a vector from fixation point to saccade endpoint
                        
                        % determine the direction of the saccade
                        direction = zeros(1,size(stimVector,1)+1);
                        for aa = 1:size(stimVector,1);
                            saccadeAngle = acosd(dot(saccadeVector,stimVector(aa,:))/(norm(saccadeVector)*norm(stimVector(aa,:)))); %calculate angle between fixation-stimulus vector and fixation-saccade endpoint vector
                            if saccadeAngle <= withinAngle %if within a threshold angle
                                direction(aa) = 1; %mark as going towards that stimulus
                            end
                        end
                        
                        if sum(direction) == 0 %if saccade is not within angle threshold of any ROI
                            direction(end) = 1; % code as going "somewhere else"
                        end
                        
                    end
                    
                    if foundSaccade == 0 %if no saccades detected in trial
                        
                        saccadeLatency = NaN;
                        direction = ones(1,size(stimVector,1)+1)*99;
                        discardTrial = 1;
                        noSaccades = 1;
                        
                    end
                    
                else %if no valid eye data detected in trial
                    saccadeLatency = NaN;
                    direction = ones(1,size(stimVector,1)+1)*99;
                    discardTrial = 1;
                    noValidData = 1;
                end
                
                saccadeSessionData(session).saccadePhaseData(phase).summarySaccadeData(t,:) = [sub, t, saccadeLatency, direction, discardTrial, anticipatorySaccade, outsideFixation, noSaccades, noValidData];
                
                movList = {};
            end
        end
    end
    
    
    save(['SummarySaccadeDataP',num2str(sub),'.mat'],'saccadeSessionData');
    save(['RawVelocityDataP', num2str(sub),'.mat'], 'velSessionData');
    
end

save('AllEyeMovements.mat', 'subMovements');

end


function dataOut = fillMissing(dataIn, GapThresh, freqMS)
% dataIn = eyeGaze data to process (x,y,validity)
% GapThresh = time window in ms for acceptable gaps
% freqMS = ms value of each timestamp


% Interpolation of gaps
while dataIn(1,8) == 4 % remove gaps at start
    dataIn(1,:) = [];
end
while dataIn(end,8) == 4 % remove gaps at end
    dataIn(end,:) = [];
end

% this section works out what positions needs to be filled and provides
% start and end points for each fill, stored in iFills
iFills = zeros(size(dataIn,1),2);
intCnt = 0;
checkPos = 2;
while checkPos < size(dataIn,1) % check each position in turn
    endPos = checkPos; % set end to current check
    if dataIn(checkPos,8)==4 % if missing (otherwise increase check position)
        while dataIn(endPos,8)==4 % step through until valid data is found
            endPos = endPos + 1; % increase end position
        end
        if endPos-checkPos < (GapThresh/freqMS) % if that gap is smalle enough
            intCnt = intCnt + 1; % this is a new fill
            iFills(intCnt,:) = [checkPos-1 endPos]; % add details of fill to the array
        end
        checkPos = endPos + 1; % go to next check position beyond the end
    else
        checkPos = checkPos + 1;
    end
end
iFills(intCnt+1:end,:) = []; % remove empty rows of array

% use values to interpolate
for r = 1:size(iFills,1)
    intSteps = 0:1/(iFills(r,2)-iFills(r,1)):1; % calculate appropriate distribution across fill range
    
    EyePosX = dataIn(iFills(r,1),2) + (dataIn(iFills(r,2),2)-dataIn(iFills(r,1),2))*intSteps; % interpolation of x
    EyePosY = dataIn(iFills(r,1),3) + (dataIn(iFills(r,2),3)-dataIn(iFills(r,1),3))*intSteps; % interpolation of y
    EyePosZ = dataIn(iFills(r,1),4) + (dataIn(iFills(r,2),4)-dataIn(iFills(r,1),4))*intSteps; % interpolation of z\
    GazePosX = dataIn(iFills(r,1),5) + (dataIn(iFills(r,2),5)-dataIn(iFills(r,1),5))*intSteps;
    GazePosY = dataIn(iFills(r,1),6) + (dataIn(iFills(r,2),6)-dataIn(iFills(r,1),6))*intSteps;
    GazePosZ = dataIn(iFills(r,1),7) + (dataIn(iFills(r,2),7)-dataIn(iFills(r,1),7))*intSteps;
    GazePos2dX = dataIn(iFills(r,1),9) + (dataIn(iFills(r,2),9)-dataIn(iFills(r,1),9))*intSteps;
    GazePos2dY = dataIn(iFills(r,1),10) + (dataIn(iFills(r,2),10)-dataIn(iFills(r,1),10))*intSteps;
    dataIn(iFills(r,1):iFills(r,2),2:10) = [round(EyePosX)' round(EyePosY)' round(EyePosZ)' round(GazePosX)' round(GazePosY)' round(GazePosZ)' zeros(size(EyePosX,2),1) round(GazePos2dX)' round(GazePos2dY)']; % update array
end

dataOut = dataIn;

end
