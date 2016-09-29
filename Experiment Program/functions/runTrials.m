
function trial = runTrials(exptPhase)

global MainWindow
global scr_centre DATA datafilename
global distract_col
global black gray yellow
global yellowIndex greyIndex
global bigMultiplier smallMultiplier medMultiplier
global stim_size stimLocs
global stimCentre aoiRadius
global fix_aoi_radius
global exptSession
global softTimeoutDuration
global sessionPoints
global EGdataFilenameBase

global realVersion
global eyeVersion

gamma = 0.2;    % Controls smoothing of displayed gaze location. Lower values give more smoothing


if realVersion

    softTimeoutDuration = 1.2;

    timeoutDuration = [4, 2, 2];     % [4, 2, 2] timeout duration
    fixationTimeoutDuration = 4;    % 4 fixation timeout duration

    itiDuration = 1.4;            % 1.4
    
    feedbackDuration = [0.7, 1.4, 1.4];       %  [0.7, 1.4, 1.4]  FB duration: Practice, first block of expt phase, later in expt phase

    yellowFixationDuration = 0.3;     % Duration for which fixation cross turns yellow to indicate trial about to start
    postFixationPause = 0.15;        % 0.15 Blank screen after fixation disappears (sampled randomly)

    initialPause = 2;   % 2
    breakDuration = 15;  % 15

    requiredFixationTime = 0.1;     % Time that target must be fixated for trial to be successful

    fixationFixationTime = 0.5;       % Time that fixation cross must be fixated for trial to begin
    
    pracTrials = 8;    % 8
    numExptBlocksSess1 = [1, 5, 8];     % [1, 5, 8]
    numExptBlocksSess2 = [1, 13];       % [1, 13]
    
    blocksPerBreak = 2;

    preTrainSinglePerBlock = 9;
    
    mixedSinglePerBlock = 7;
    mixedDoublePerBlock = 4;
    
else
    
    softTimeoutDuration = 2;

    timeoutDuration = [4, 2, 2];     % [4, 2, 2] timeout duration
    fixationTimeoutDuration = 4;    % 4 fixation timeout duration

    itiDuration = 0.01;            % 0.7
    feedbackDuration = [0.001, 0.2, 0.2];       %[0.001, 0.001, 0.001]    [0.7, 2.5, 1.5]  FB duration: Practice, first block of expt phase, later in expt phase

    yellowFixationDuration = 0.005;     % Duration for which fixation cross turns yellow to indicate trial about to start
    postFixationPause = 0.005;        % 0.15 Blank screen after fixation disappears (sampled randomly)

    initialPause = 0.005;   % 2 ***
    breakDuration = 2;  % 15 ***

    requiredFixationTime = 0.005;     % Time that target must be fixated for trial to be successful

    fixationFixationTime = 0.005;       % Time that fixation cross must be fixated for trial to begin
    
    pracTrials = 2;    % 8
    numExptBlocksSess1 = [1, 1, 1];
    numExptBlocksSess2 = [1, 1];

    blocksPerBreak = 1;

    preTrainSinglePerBlock = 1;
    
    mixedSinglePerBlock = 1;
    mixedDoublePerBlock = 1;
    
end    

savingGazeData = false;
    
if exptPhase == 1
    numTrials = pracTrials;

    distractorTypes = [yellowIndex, greyIndex];   % Yellow and grey
    
    exptTrialsPerBlock = pracTrials;
    
    trialTypeArray = ones(exptTrialsPerBlock, 1);
    
    winMultiplier = 0;
    

else
    
    if eyeVersion
        savingGazeData = true;
        trialEGarray = zeros(timeoutDuration(exptPhase) * 2 * 300, 27);    % Preallocate memory for eyetracking data. Tracker samples at 300Hz, so multiplying timeout duration by 2*300 means there will be plenty of slots
   end
    
    numSingleDistractType = 4;        % Two types of distractor present trial (P, NP) with two reward types each
    numDoubleDistractType = 2;

    numTrialTypes = numSingleDistractType + numDoubleDistractType;
    
    distractorTypes = zeros(numTrialTypes,2);
    distractorTypes(1,:) = [1, greyIndex];
    distractorTypes(3,:) = [2, greyIndex];
    distractorTypes(5,:) = [1, 2];
    
    for ii = 1 : 2 : (numTrialTypes - 1)
        distractorTypes(ii + 1, :) = distractorTypes(ii,:);
    end
    
    winMultiplier = zeros(numTrialTypes,1);     % winMultiplier is a bad name now; it's actually the amount that they win
    winMultiplier(1) = medMultiplier;         % Single P
    winMultiplier(2) = medMultiplier;
    winMultiplier(3) = bigMultiplier;         % Single NP
    winMultiplier(4) = smallMultiplier;
    winMultiplier(5) = medMultiplier;     % Double
    winMultiplier(6) = medMultiplier;     % Double
    
    if exptSession == 1
        if exptPhase == 2
            numSingleDistractPerBlock = preTrainSinglePerBlock;     % 6
            numDoubleDistractPerBlock = 0;     % 0
        else
            numSingleDistractPerBlock = mixedSinglePerBlock;     % 5
            numDoubleDistractPerBlock = mixedDoublePerBlock;     % 1
        end
        
        numExptBlocks = numExptBlocksSess1(exptPhase);
       
    elseif exptSession == 2
        
        numSingleDistractPerBlock = mixedSinglePerBlock;     % 5
        numDoubleDistractPerBlock = mixedDoublePerBlock;     % 1
        
        numExptBlocks = numExptBlocksSess2(exptPhase);
        
    end
    
    exptTrialsPerBlock = numSingleDistractType * numSingleDistractPerBlock + numDoubleDistractType * numDoubleDistractPerBlock;    % Gives 34
    
    trialTypeArray = zeros(exptTrialsPerBlock, 1);
    
    loopCounter = 0;
    for ii = 1 : numSingleDistractType
        for jj = 1 : numSingleDistractPerBlock
            loopCounter = loopCounter + 1;
            trialTypeArray(loopCounter) = ii;
        end
    end
    
    for ii = numSingleDistractType + 1 : numSingleDistractType + numDoubleDistractType
        for jj = 1 : numDoubleDistractPerBlock
            loopCounter = loopCounter + 1;
            trialTypeArray(loopCounter) = ii;
        end
    end
    
    numTrials = numExptBlocks * exptTrialsPerBlock;    % 14 * exptTrialsPerBlock = 476


end

shTrialTypeArray = shuffleTrialorder(trialTypeArray);   % Calls a function to shuffle trials

exptTrialsBeforeBreak = exptTrialsPerBlock * blocksPerBreak;     % 2 * exptTrialsPerBlock = 72



if ~eyeVersion
    ShowCursor('Arrow');
end



fixationPollingInterval = 0.03;    % Duration between successive polls of the eyetracker for gaze contingent stuff; during fixation display
trialPollingInterval = 0.01;      % Duration between successive polls of the eyetracker for gaze contingent stuff; during stimulus display

junkFixationPeriod = 0.1;   % Period to throw away at start of fixation before gaze location is calculated
junkGazeCycles = junkFixationPeriod / trialPollingInterval;



stimLocs = 6;       % Number of stimulus locations
perfectDiam = stim_size + 10;   % Used in FillOval to increase drawing speed

circ_diam = 200;    % Diameter of imaginary circle on which stimuli are positioned

fix_size = 20;      % This is the side length of the fixation cross
fix_aoi_radius = fix_size * 3;

gazePointRadius = 10;


% Create a rect for the fixation cross
fixRect = [scr_centre(1) - fix_size/2    scr_centre(2) - fix_size/2   scr_centre(1) + fix_size/2   scr_centre(2) + fix_size/2];


% Create a rect for the circular fixation AOI
fixAOIrect = [scr_centre(1) - fix_aoi_radius    scr_centre(2) - fix_aoi_radius   scr_centre(1) + fix_aoi_radius   scr_centre(2) + fix_aoi_radius];


[diamondTex, fixationTex, colouredFixationTex, fixationAOIsprite, colouredFixationAOIsprite, gazePointSprite, stimWindow] = setupStimuli(fix_size, gazePointRadius);


% Create a matrix containing the six stimulus locations, equally spaced
% around an imaginary circle of diameter circ_diam
stimRect = zeros(stimLocs,4);

for i = 0 : stimLocs - 1    % Define rects for stimuli and line segments
    stimRect(i+1,:) = [scr_centre(1) - circ_diam * sin(i*2*pi/stimLocs) - stim_size / 2   scr_centre(2) - circ_diam * cos(i*2*pi/stimLocs) - stim_size / 2   scr_centre(1) - circ_diam * sin(i*2*pi/stimLocs) + stim_size / 2   scr_centre(2) - circ_diam * cos(i*2*pi/stimLocs) + stim_size / 2];
end

stimCentre = zeros(stimLocs, 2);
for i = 1 : stimLocs
    stimCentre(i,:) = [stimRect(i,1) + stim_size / 2,  stimRect(i,2) + stim_size / 2];
end
distractorAOIradius = 2 * (circ_diam / 2) * sin(pi / stimLocs);       % This gives circular AOIs that are tangent to each other
targetAOIradius = round(stim_size * 0.75);        % This gives a smaller AOI that will be used to determine target fixations on each trial

aoiRadius = zeros(stimLocs);


distract1LocArray = [-2, -1, 1, 2];   % Positions away from target for distractor 1 location.

trialCounter = 0;
block = 1;
trials_since_break = 0;

DATA.fixationTimeouts(exptPhase) = 0;
DATA.trialTimeouts(exptPhase) = 0;

if eyeVersion
    tetio_startTracking; % start recording
end

WaitSecs(initialPause);

Screen('Flip', MainWindow);     % Clear screen


for trial = 1 : numTrials
    
    trialCounter = trialCounter + 1;    % This is used to set distractor type below; it can cycle independently of trial
    trials_since_break = trials_since_break + 1;
    

    if exptPhase == 1
        FB_duration = feedbackDuration(1);
    else
        if block == 1 && exptSession == 1
            FB_duration = feedbackDuration(2);
        else
            FB_duration = feedbackDuration(3);
        end
    end
    
    targetLoc = randi(stimLocs);
    
    distract1LocOffset = Sample(distract1LocArray);
    distract2LocOffset = -distract1LocOffset;
    
    trialType = shTrialTypeArray(trialCounter);

    trialRewardAvailable = winMultiplier(trialType);
    
    distract1Colour = distractorTypes(trialType, 1);
    distract2Colour = distractorTypes(trialType, 2);
    
    distract1Loc = mod(targetLoc + distract1LocOffset, stimLocs);
    distract2Loc = mod(targetLoc + distract2LocOffset, stimLocs);
    
    if distract1Loc == 0
        distract1Loc = 6;
    end
    if distract2Loc == 0
        distract2Loc = 6;
    end
    
    Screen('FillRect', stimWindow, black);  % Clear the screen from the previous trial by drawing a black rectangle over the whole thing
    
    for i = 1 : stimLocs
        Screen('FillOval', stimWindow, gray, stimRect(i,:), perfectDiam);       % Draw stimulus circles
        aoiRadius(i) = distractorAOIradius;     % Set large AOIs around all locations (we'll change the AOI around the target location in a minute)
    end
    
    Screen('FillOval', stimWindow, distract_col(distract1Colour,:), stimRect(distract1Loc,:), perfectDiam);      % Draw coloured circle in distractor location
    Screen('FillOval', stimWindow, distract_col(distract2Colour,:), stimRect(distract2Loc,:), perfectDiam);      % Draw coloured circle in distractor location

    Screen('DrawTexture', stimWindow, diamondTex, [], stimRect(targetLoc,:));       % Draw diamond in target location
    aoiRadius(targetLoc) = targetAOIradius;     % Set a special (small) AOI around the target
    
    %     for i = 1 : stimLocs          % Draw AOI circles (remove this from final version)
    %         Screen('FrameOval', stimWindow, white, [stimCentre(i,1) - aoiRadius(i), stimCentre(i,2) - aoiRadius(i), stimCentre(i,1) + aoiRadius(i), stimCentre(i,2) + aoiRadius(i)], 1, 1);
    %     end
    
    
    Screen('DrawTexture', MainWindow, fixationAOIsprite, [], fixAOIrect);
    Screen('DrawTexture', MainWindow, fixationTex, [], fixRect);
    
    timeOnFixation = zeros(2);    % a slot for each stimulus location, and one for "everywhere else"
    stimSelected = 2;   % 1 = fixation cross, 2 = everywhere else
    continueFixation = true;
    fixationBadSamples = 0;
    fixationTimeout = 0;
    gazeCycle = 0;
    
    startFixationTime = Screen('Flip', MainWindow, [], 1);     % Present fixation cross
    
    if eyeVersion
        
        [~, ~, ts, ~] = tetio_readGazeData; % Empty eye tracker buffer
        startEyePeriod = double(ts(end));  % Take the timestamp of the last element in the buffer as the start of the trial. Need to convert to double so can divide by 10^6 later to change to seconds
        startFixationTimeoutPeriod = startEyePeriod;
        
        currentGazePoint = zeros(1,2);
        
        while continueFixation
            Screen('DrawTexture', MainWindow, fixationAOIsprite, [], fixAOIrect);   % Redraw fixation cross and AOI, and draw gaze point on top of that
            Screen('DrawTexture', MainWindow, fixationTex, [], fixRect);
            
            WaitSecs(fixationPollingInterval);      % Pause between updates of eye position
            [lefteye, righteye, ts, ~] = tetio_readGazeData;    % Get eye-tracker data since previous call
            
            if isempty(ts) == 0
                
                [eyeX, eyeY, validPoints] = findMeanGazeLocation(lefteye, righteye, length(ts));    % Find mean gaze location during the previous polling interval
                
                gazeCycle = gazeCycle + 1;
                
                if validPoints > 0
                    if gazeCycle <= junkGazeCycles
                        currentGazePoint = [eyeX, eyeY];        % If in junk period at start of trial, keep track of gaze location; this will determine starting point of gaze when the junk period ends
                    else
                        currentGazePoint = (1 - gamma) * currentGazePoint + gamma * [eyeX, eyeY];       % Calculate smoothed gaze location using weighted moving average of current and previous locations
                        
                        Screen('DrawTexture', MainWindow, gazePointSprite, [], [currentGazePoint(1) - gazePointRadius, currentGazePoint(2) - gazePointRadius, currentGazePoint(1) + gazePointRadius, currentGazePoint(2) + gazePointRadius]);
                        Screen('DrawingFinished', MainWindow);
                        
                        stimSelected = checkEyesOnFixation(eyeX, eyeY);     % If some gaze has been detected, check whether this is on the fixation cross, or "everywhere else"
                        
                    end
                    
                else
                    stimSelected = 2;   % If no gaze detected, record gaze as "everywhere else"
                    fixationBadSamples = fixationBadSamples + 1;
                end
                
                endEyePeriod = double(ts(end));     % Last entry in timestamp data gives end time of polling period
                timeOnFixation(stimSelected) = timeOnFixation(stimSelected) + (endEyePeriod - startEyePeriod) / 10^6;   % Divided by 10^6 because eyetracker gives time in microseconds
                startEyePeriod = endEyePeriod;      % Start of next polling period is end of the last one
                
            end
            
            if timeOnFixation(1) >= fixationFixationTime         % If fixated on target
                continueFixation = false;
            elseif (endEyePeriod - startFixationTimeoutPeriod)/ 10^6 >= fixationTimeoutDuration        % If time since start of fixation period > fixation timeout limit
                continueFixation = false;
                fixationTimeout = 1;
            end
            
            Screen('Flip', MainWindow);     % Update display with gaze point
            
        end
        
        
    else    % If not eyeVersion use mouse tracking
    
        while continueFixation
            WaitSecs(fixationPollingInterval);
            [mouseX, mouseY] = GetMouse;
            
            stimSelected = checkEyesOnFixation(mouseX, mouseY);
                
            timeOnFixation(stimSelected) = 1;
            
            if timeOnFixation(1) == 1
                continueFixation = false;
            elseif GetSecs - startFixationTime >= fixationTimeoutDuration
                continueFixation = false;
                fixationTimeout = 1;
            end
            
        end
    
    
    end

    
    fixationTime = GetSecs - startFixationTime;      % Length of fixation period in ms
    fixationPropGoodSamples = 1 - double(fixationBadSamples) / double(gazeCycle);
    
    Screen('DrawTexture', MainWindow, colouredFixationAOIsprite, [], fixAOIrect);
    Screen('DrawTexture', MainWindow, colouredFixationTex, [], fixRect);
    Screen('Flip', MainWindow);     % Present coloured fixation cross
    
    WaitSecs(yellowFixationDuration);
    
    Screen('Flip', MainWindow);     % Show fixation cross without circle
    
    WaitSecs(postFixationPause);
    
    searchOutcome = 0;
    timeOnLoc = zeros(1, stimLocs + 1);    % a slot for each stimulus location, and one for "everywhere else"
    stimSelected = stimLocs + 1; %#ok<NASGU>
    trialBadSamples = 0;
    gazeCycle = 0;
    arrayRowCounter = 2;    % Used to write EG data to the correct rows of an array. Starts at 2 because we write the first row in separately below (line marked ***)
   
    if savingGazeData
        trialEGarray(:,:) = 0;
    end
    
    Screen('DrawTexture', MainWindow, stimWindow);      % Copy stimuli to main window
    
    startTrialTime = Screen('Flip', MainWindow);      % Present stimuli, and record start time (st) when they are presented.
    
    
    if eyeVersion
    
        [lefteye, righteye, ts, ~] = tetio_readGazeData; % Empty eye tracker buffer
        
        startEyePeriod = double(ts(end));  % Take the timestamp of the last element in the buffer as the start of the first eye tracking period
        startEyeTrial = startEyePeriod;     % This will be used to judge timeouts below
        
        if savingGazeData
            trialEGarray(1,:) = [double(ts(length(ts))), lefteye(length(ts),:), righteye(length(ts),:)];       % *** First row of saved EG array gives start time
        end
        
        while searchOutcome == 0
            WaitSecs(trialPollingInterval);      % Pause between updates of eye position
            [lefteye, righteye, ts, ~] = tetio_readGazeData;    % Get eye-tracker data since previous call
            
            if isempty(ts) == 0
                
                [eyeX, eyeY, validPoints] = findMeanGazeLocation(lefteye, righteye, length(ts));    % Find mean gaze location during the previous polling interval
                
                endPoint = arrayRowCounter + length(ts) - 1;
                
                if savingGazeData
                    trialEGarray(arrayRowCounter:endPoint,:) = [double(ts), lefteye, righteye];
                end
                
                arrayRowCounter = endPoint + 1;
                
                gazeCycle = gazeCycle + 1;
                
                if validPoints > 0
                    stimSelected = checkEyesOnStim(eyeX, eyeY);     % If some gaze has been detected, check whether this is in an AOI, or "everywhere else"
                else
                    trialBadSamples = trialBadSamples + 1;
                    stimSelected = stimLocs + 1;   % If no gaze detected, record gaze as "everywhere else"
                end
                
                endEyePeriod = double(ts(end));     % Last entry in timestamp data gives end time of polling period
                timeOnLoc(stimSelected) = timeOnLoc(stimSelected) + (endEyePeriod - startEyePeriod) / 10^6;   % Divided by 10^6 because eyetracker gives time in microseconds
                startEyePeriod = endEyePeriod;      % Start of next polling period is end of the last one
                
            end
            
            if timeOnLoc(targetLoc) >= requiredFixationTime         % If fixated on target
                searchOutcome = 1;
            elseif (endEyePeriod - startEyeTrial)/ 10^6 >= timeoutDuration(exptPhase)        % If time since start of trial > timeout limit for this phase
                searchOutcome = 2;
            end
            
        end
    
    else     % If not eyeVersion, use mouse tracking

        while searchOutcome == 0
            WaitSecs(trialPollingInterval);
            [mouseX, mouseY] = GetMouse;
            
            stimSelected = checkEyesOnStim(mouseX, mouseY);
                
            timeOnLoc(stimSelected) = 1;
            
            if timeOnLoc(targetLoc) == 1
                searchOutcome = 1;
            elseif GetSecs - startTrialTime >= timeoutDuration(exptPhase)
                searchOutcome = 2;
            end
            
        end
        
    end
    
    rt = GetSecs - startTrialTime;      % Response time
    
    Screen('Flip', MainWindow);
    
    
    trialPropGoodSamples = 1 - double(trialBadSamples) / double(gazeCycle);
    
    searchTimeout = 0;
    softTimeoutTrial = 0;
    omission1Trial = 0;
    omission2Trial = 0;
    trialPay = 0;
    
    if exptPhase == 1
        
        fbStr = 'correct';
        if searchOutcome == 2
            searchTimeout = 1;
            fbStr = 'TOO SLOW\n\nPlease try to look at the diamond more quickly';
        end
        
    else
        
        fbTimeout = ['TOO SLOW\n\n+0 points\n\nYou could have won ', num2str(trialRewardAvailable), ' points'];
        
        if searchOutcome == 2
            searchTimeout = 1;
            fbStr = fbTimeout;
            trialPay = 0;
        else
            
            if timeOnLoc(distract1Loc) > 0          % If people have looked at the distractor location (includes trials with no distractor actually presented)
                omission1Trial = 1;
            end
            if timeOnLoc(distract2Loc) > 0          % If people have looked at the distractor location (includes trials with no distractor actually presented)
                omission2Trial = 1;
            end
            
            if rt > softTimeoutDuration      % If RT is greater than the "soft" timeout limit, don't get reward (but also don't get explicit timeout feedback)
                softTimeoutTrial = 1;
                fbStr = fbTimeout;
                trialPay = 0;
            else
                trialPay = trialRewardAvailable;
                sessionPoints = sessionPoints + trialRewardAvailable;
                fbStr = ['+', num2str(trialPay), ' points'];
            end
            
        end
        
    end
    
    Screen('TextSize', MainWindow, 54);
    DrawFormattedText(MainWindow, fbStr, 'center', 'center', yellow, [], [], [], 1.3);
    
    Screen('Flip', MainWindow);
    
    WaitSecs(FB_duration);

    
    
    trialData = [exptSession, block, trial, trialCounter, trials_since_break, targetLoc, distract1Loc, distract2Loc, fixationTime, fixationPropGoodSamples, fixationTimeout, trialPropGoodSamples, searchTimeout, softTimeoutTrial, omission1Trial, omission2Trial, rt, trialPay, sessionPoints, trialType, distract1Colour, distract2Colour, timeOnLoc(1,:)];

    if trial == 1
        DATA.trialInfo(exptPhase).trialData = zeros(numTrials, size(trialData, 2));
    end
    DATA.trialInfo(exptPhase).trialData(trial, :) = trialData(:);

    DATA.fixationTimeouts(exptPhase) = DATA.fixationTimeouts(exptPhase) + fixationTimeout;
    DATA.trialTimeouts(exptPhase) = DATA.trialTimeouts(exptPhase) + searchTimeout;
    DATA.sessionPoints = sessionPoints;

    save(datafilename, 'DATA');

    if savingGazeData
        EGdataFilename = [EGdataFilenameBase, 'Ph', num2str(exptPhase), 'T', num2str(trial), '.mat'];
        
        GAZEDATA = trialEGarray(1:arrayRowCounter-1, :);
        save(EGdataFilename, 'GAZEDATA');
        
    end
    
            
    RestrictKeysForKbCheck(KbName('c'));   % Only accept C key to begin calibration
    startITItime = Screen('Flip', MainWindow);

    [~, keyCode, ~] = KbWait([], 2, startITItime + itiDuration);    % Wait for ITI duration while monitoring keyboard
    
    RestrictKeysForKbCheck([]);   % Re-enable all keys
    
    % If pressed C during ITI period, run an extraordinary calibration, otherwise
    % carry on with the experiment    
    if sum(keyCode) > 0
        if eyeVersion
            try
                tetio_stopTracking;
            catch ME
                a = 1;
            end
            runPTBcalibration;
            tetio_startTracking;
            WaitSecs(initialPause);
        end
    end

    
    if mod(trial, exptTrialsPerBlock) == 0
        shTrialTypeArray = shuffleTrialorder(trialTypeArray);   % Calls a function to shuffle trials
        trialCounter = 0;
        block = block + 1;
    end
        
    if mod(trial, exptTrialsBeforeBreak) == 0
        if trial ~= numTrials || (exptSession == 1 && exptPhase == 2)
            take_a_break(breakDuration, initialPause, sessionPoints);
            [diamondTex, fixationTex, colouredFixationTex, fixationAOIsprite, colouredFixationAOIsprite, gazePointSprite, stimWindow] = setupStimuli(fix_size, gazePointRadius);
            trials_since_break = 0;
        end
    end
        

end

if eyeVersion
    try
        tetio_stopTracking;
    catch ME
        a = 1;
    end
end


Screen('Close', diamondTex);
Screen('Close', fixationTex);
Screen('Close', colouredFixationTex);
Screen('Close', fixationAOIsprite);
Screen('Close', colouredFixationAOIsprite);
Screen('Close', gazePointSprite);
Screen('Close', stimWindow);


end









function [eyeXpos, eyeYpos, sum_validities] = findMeanGazeLocation(lefteyeData, righteyeData, samples)
global screenRes

lefteyeValidity = zeros(samples,1);
righteyeValidity = zeros(samples,1);

for ii = 1 : samples
    if lefteyeData(ii,13) == 4 && righteyeData(ii,13) == 4
        lefteyeValidity(ii) = 0; righteyeValidity(ii) = 0;
    elseif lefteyeData(ii,13) == righteyeData(ii,13)
        lefteyeValidity(ii) = 0.5; righteyeValidity(ii) = 0.5;
    elseif lefteyeData(ii,13) < righteyeData(ii,13)
        lefteyeValidity(ii) = 1; righteyeValidity(ii) = 0;
    elseif lefteyeData(ii,13) > righteyeData(ii,13)
        lefteyeValidity(ii) = 0; righteyeValidity(ii) = 1;
    end
end

sum_validities = sum(lefteyeValidity) + sum(righteyeValidity);
if sum_validities > 0
    eyeXpos = screenRes(1) * (lefteyeData(:,7)' * lefteyeValidity + righteyeData(:,7)' * righteyeValidity) / sum_validities;
    eyeYpos = screenRes(2) * (lefteyeData(:,8)' * lefteyeValidity + righteyeData(:,8)' * righteyeValidity) / sum_validities;

    if eyeXpos > screenRes(1)       % This guards against the possible bug that Tom identified where gaze can be registered off-screen
        eyeXpos = screenRes(1);
    end
    if eyeYpos > screenRes(2)
        eyeYpos = screenRes(2);
    end

else
    eyeXpos = 0;
    eyeYpos = 0;
end

end




function detected = checkEyesOnStim(x, y)
global stimCentre aoiRadius stimLocs

detected = stimLocs + 1;
for s = 1 : stimLocs
    if (x - stimCentre(s,1))^2 + (y - stimCentre(s,2))^2 <= aoiRadius(s)^2
        detected = s;
        return
    end
end

end


function detected = checkEyesOnFixation(x, y)
global scr_centre fix_aoi_radius

detected = 2;
if (x - scr_centre(1))^2 + (y - scr_centre(2))^2 <= fix_aoi_radius^2
    detected = 1;
    return
end

end



function shuffArray = shuffleTrialorder(inArray)

acceptShuffle = 0;

while acceptShuffle == 0
    shuffArray = Shuffle(inArray);     % Shuffle order of distractors
    acceptShuffle = 1;   % Shuffle always OK in practice phase
    if shuffArray(1) > 6 || shuffArray(2) > 6
        acceptShuffle = 0;   % Reshuffle if either of the first two trials (which may well be discarded) are rare types
    end
end

end




function take_a_break(breakDur, pauseDur, totalPointsSoFar)

global MainWindow white yellow
global eyeVersion

if eyeVersion
    try
        tetio_stopTracking;
    catch ME
        a = 1;
    end
end

oldFont = Screen('TextFont', MainWindow, 'Segoe UI');
oldSize = Screen('TextSize', MainWindow, 46);
oldStyle = Screen('TextStyle', MainWindow, 0);

    
[~, ny, ~] = DrawFormattedText(MainWindow, ['Time for a break\n\nSit back, relax for a moment! You will be able to carry on in ', num2str(breakDur),' seconds.\n\nREMEMBER: You should try to move your eyes to the diamond as quickly and as accurately as possible!'], 'center', 200, white, 75, [], [], 1.2);

Screen('TextStyle', MainWindow, 1);
DrawFormattedText(MainWindow, ['\n\n\nTotal so far = ', separatethousands(totalPointsSoFar, ','), ' points'], 'center', ny, yellow);

Screen('Flip', MainWindow, [], 1);
WaitSecs(breakDur);

Screen('TextSize', MainWindow, 34);
Screen('TextStyle', MainWindow, 0);
DrawFormattedText(MainWindow, 'Press any key to continue', 'center', 900, [0,255,255]);
Screen(MainWindow, 'Flip');

RestrictKeysForKbCheck([]); % Enable all keys
KbWait([], 2);

Screen('TextSize', MainWindow, 46);
DrawFormattedText(MainWindow, 'Please put your chin back in the chinrest,\nand press space when you are ready to continue', 'center', 'center' , white, [], [], [], 1.2);
Screen('Flip', MainWindow);

RestrictKeysForKbCheck(KbName('Space'));   % Only accept spacebar
KbWait([], 2);
Screen('Flip', MainWindow);

Screen('TextFont', MainWindow, oldFont);
Screen('TextSize', MainWindow, oldSize);
Screen('TextStyle', MainWindow, oldStyle);


if eyeVersion
    try
        tetio_startTracking;
    catch ME
        a = 1;
    end
end

WaitSecs(pauseDur);

end


function [diamondTex, fixationTex, colouredFixationTex, fixationAOIsprite, colouredFixationAOIsprite, gazePointSprite, stimWindow] = setupStimuli(fs, gpr)

global MainWindow
global fix_aoi_radius
global white black gray yellow
global stim_size

perfectDiam = stim_size + 10;   % Used in FillOval to increase drawing speed

% This plots the points of a large diamond, that will be filled with colour
d_pts = [stim_size/2, 0;
    stim_size, stim_size/2;
    stim_size/2, stim_size;
    0, stim_size/2];


% Create an offscreen window, and draw the two diamonds onto it to create a diamond-shaped frame.
diamondTex = Screen('OpenOffscreenWindow', MainWindow, black, [0 0 stim_size stim_size]);
Screen('FillPoly', diamondTex, gray, d_pts);

% Create an offscreen window, and draw the fixation cross in it.
fixationTex = Screen('OpenOffscreenWindow', MainWindow, black, [0 0 fs fs]);
Screen('DrawLine', fixationTex, white, 0, fs/2, fs, fs/2, 2);
Screen('DrawLine', fixationTex, white, fs/2, 0, fs/2, fs, 2);


colouredFixationTex = Screen('OpenOffscreenWindow', MainWindow, black, [0 0 fs fs]);
Screen('DrawLine', colouredFixationTex, yellow, 0, fs/2, fs, fs/2, 4);
Screen('DrawLine', colouredFixationTex, yellow, fs/2, 0, fs/2, fs, 4);

% Create a sprite for the circular AOI around the fixation cross
fixationAOIsprite = Screen('OpenOffscreenWindow', MainWindow, black, [0 0  fix_aoi_radius*2  fix_aoi_radius*2]);
Screen('FrameOval', fixationAOIsprite, white, [], 1, 1);   % Draw fixation aoi circle

colouredFixationAOIsprite = Screen('OpenOffscreenWindow', MainWindow, black, [0 0  fix_aoi_radius*2  fix_aoi_radius*2]);
Screen('FrameOval', colouredFixationAOIsprite, yellow, [], 2, 2);   % Draw fixation aoi circle


% Create a marker for eye gaze
gazePointSprite = Screen('OpenOffscreenWindow', MainWindow, black, [0 0 gpr*2 gpr*2]);
Screen('FillOval', gazePointSprite, yellow, [0 0 gpr*2 gpr*2], perfectDiam);       % Draw stimulus circles

% Create a full-size offscreen window that will be used for drawing all
% stimuli and targets (and fixation cross) into
stimWindow = Screen('OpenOffscreenWindow', MainWindow, black);
end
