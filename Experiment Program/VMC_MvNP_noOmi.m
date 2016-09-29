
clear all

sca;

clc;

functionFoldername = fullfile(pwd, 'functions');    % Generate file path for "functions" folder in current working directory
addpath(genpath(functionFoldername));       % Then add path to this folder and all subfolders


global MainWindow screenNum
global scr_centre DATA datafilename p_number
global centOrCents
global screenRes
global distract_col colourName
global white black gray yellow
global bigMultiplier smallMultiplier medMultiplier
global calibrationNum
global exptSession
global awareInstrPause
global stim_size
global EGdataFilenameBase
global sessionPoints

global realVersion
global eyeVersion

eyeVersion = true;
realVersion = true;


commandwindow;

if realVersion
    screenNum = 0;
    Screen('Preference', 'SkipSyncTests', 0);      % Enables the Psychtoolbox calibrations
    awareInstrPause = 18;
else
    screenNum = 0;
    Screen('Preference', 'SkipSyncTests', 2);      % Skips the Psychtoolbox calibrations
    fprintf('\n\nEXPERIMENT IS BEING RUN IN DEBUGGING MODE!!! IF YOU ARE RUNNING A ''REAL'' EXPT, QUIT AND CHANGE realVersion TO true\n\n');
    awareInstrPause = 1;

end




bigMultiplier = 100;    % Points multiplier for trials with high-value distractor
smallMultiplier = 0;   % Points multiplier for trials with low-value distractor
medMultiplier = 50;   % Points multiplier for trials with med-value distractor


if smallMultiplier == 1
    centOrCents = 'point';
else
    centOrCents = 'points';
end

stim_size = 92;     % 92 Size of stimuli


starting_total = 0;

calibrationNum = 0;


if eyeVersion
    
    disp('Initializing tetio...');
    tetio_init();
    
    disp('Browsing for trackers...');
    trackerinfo = tetio_getTrackers();
    trackerId = trackerinfo(1).ProductId;
    
    fprintf('Connecting to tracker "%s"...\n', trackerId);
    tetio_connectTracker(trackerId)
    
    currentFrameRate = tetio_getFrameRate;
    fprintf('Connected!  Sample rate: %d Hz.\n', currentFrameRate);
    
    DATA.trackerID = trackerId;
    
end

if exist('Data', 'dir') == 0
    mkdir('Data');
end

if exist('Data\BehavData', 'dir') == 0
    mkdir('Data\BehavData');
end
if exist('Data\CalibrationData', 'dir') == 0
    mkdir('Data\CalibrationData');
end
if exist('Data\EyeData', 'dir') == 0
    mkdir('Data\EyeData');
end

if realVersion
    
    inputError = 1;
    
    while inputError == 1
        inputError = 0;
        
        p_number = input('Participant number  ---> ');
        exptSession = input('Session number  ---> ');
        
        datafilename = ['Data\BehavData\VMC_MvNP_noOmi_dataP', num2str(p_number), '_S'];
        
        if exist([datafilename, num2str(exptSession), '.mat'], 'file') == 2
            disp(['Session ', num2str(exptSession), ' data for participant ', num2str(p_number),' already exist'])
            inputError = 1;
        end
        
        if exptSession > 1
            if exist([datafilename, num2str(exptSession - 1), '.mat'], 'file') == 0
                disp(['No session ', num2str(exptSession - 1), ' data for participant ', num2str(p_number)])
                inputError = 1;
            end
            if exist([datafilename, num2str(1), '.mat'], 'file') == 0
                disp(['No session ', num2str(1), ' data for participant ', num2str(p_number)])
                inputError = 1;
            end
        end
        
    end
    
    
    
    if exptSession == 1
        colBalance = 0;
        while colBalance < 1 || colBalance > 2
            colBalance = input('Counterbalance (1-2)---> ');
            if isempty(colBalance); colBalance = 0; end
        end
        
        p_age = input('Participant age ---> ');
        p_sex = 'a';
        while p_sex ~= 'm' && p_sex ~= 'f' && p_sex ~= 'M' && p_sex ~= 'F'
            p_sex = input('Participant gender (M/F) ---> ', 's');
            if isempty(p_sex); p_sex = 'a'; end
        end
        
        p_hand = 'a';
        while p_hand ~= 'r' && p_hand ~= 'l' && p_hand ~= 'R' && p_hand ~= 'L'
            p_hand = input('Participant hand (R/L) ---> ','s');
            if isempty(p_hand); p_hand = 'a'; end
        end
        
    else
        
        load([datafilename, num2str(exptSession - 1), '.mat'])
        colBalance = DATA.counterbal;
        p_age = DATA.age;
        p_sex = DATA.sex;
        p_hand = DATA.hand;
        if isfield(DATA, 'totalBonus')
            starting_total = DATA.totalBonus;
        else
            starting_total = 0;
        end
        
        disp (['Age:  ', num2str(p_age)])
        disp (['Sex:  ', p_sex])
        disp (['Hand:  ', p_hand])
        disp (['Counterbalance:  ', num2str(colBalance)])
        
        y_to_continue = 'a';
        while y_to_continue ~= 'y' && y_to_continue ~= 'Y'
            y_to_continue = input('Is this OK? (y = continue, n = quit) --> ','s');
            if y_to_continue == 'n'
                Screen('CloseAll');
                clear all;
                error('Quitting program');
            end
            
            if isempty(y_to_continue); y_to_continue = 'a'; end
            
        end
        
    end
    
else
    
    p_number = 1;
    exptSession = 2;
    colBalance = 1;
    p_sex = 'm';
    p_age = 123;
    p_hand = 'r';
    datafilename = ['Data\BehavData\VMC_MvNP_noOmi_dataP', num2str(p_number), '_S', num2str(exptSession)];
    
end


DATA.subject = p_number;
DATA.session = exptSession;
DATA.counterbal = colBalance;
DATA.age = p_age;
DATA.sex = p_sex;
DATA.hand = p_hand;
DATA.start_time = datestr(now,0);


DATA.session_Bonus = 0;
DATA.session_Points = 0;
DATA.actualBonusSession = 0;
DATA.totalBonus = 0;


datafilename = [datafilename, num2str(exptSession),'.mat'];

if eyeVersion
    EGfolderName = 'Data\EyeData';
    EGsubfolderNameString = ['P', num2str(p_number), 'S', num2str(exptSession)];
    mkdir(EGfolderName, EGsubfolderNameString);
    EGdataFilenameBase = [EGfolderName, '\', EGsubfolderNameString, '\GazeData', EGsubfolderNameString];
end

% *******************************************************


KbName('UnifyKeyNames');    % Important for some reason to standardise keyboard input across platforms / OSs.

Screen('Preference', 'DefaultFontName', 'Courier New');

% generate a random seed using the clock, then use it to seed the random
% number generator
rng('shuffle');
randSeed = randi(30000);
DATA.rSeed = randSeed;
rng(randSeed);

% Get screen resolution, and find location of centre of screen
[scrWidth, scrHeight] = Screen('WindowSize',screenNum);
screenRes = [scrWidth scrHeight];
scr_centre = screenRes / 2;

% now set colors
white = [255,255,255];
black = [0,0,0];
gray = [70 70 70];   %[100 100 100]

orange = [193 95 30];
green = [54 145 65];
blue = [37 141 165]; %[87 87 255];
pink = [193 87 135];

yellow = [255 255 0];

global bgdColour
bgdColour = black;

MainWindow = Screen(screenNum, 'OpenWindow', bgdColour);
Screen('TextFont', MainWindow, 'Courier New');
Screen('TextSize', MainWindow, 46);
Screen('TextStyle', MainWindow, 1);


DATA.frameRate = round(Screen(MainWindow, 'FrameRate'));


HideCursor;

numColourTypes = 4;

global yellowIndex greyIndex
yellowIndex = numColourTypes;
greyIndex = numColourTypes - 1;

distract_col = zeros(numColourTypes,3);

distract_col(yellowIndex,:) = yellow;       % Practice colour
switch colBalance
    case 1
        distract_col(1,:) = orange;      % Predictive
        distract_col(2,:) = blue;      % Non-predictive
    case 2
        distract_col(1,:) = blue;
        distract_col(2,:) = orange;
end

distract_col(greyIndex,:) = gray;

colourName = cell(numColourTypes,1);

for ii = 1 : length(colourName)
    if distract_col(ii,:) == orange
        colourName(ii) = {'ORANGE'};
    elseif distract_col(ii,:) == green
        colourName(ii) = {'GREEN'};
    elseif distract_col(ii,:) == blue
        colourName(ii) = {'BLUE'};
    elseif distract_col(ii,:) == pink
        colourName(ii) = {'PINK'};
    elseif distract_col(ii,:) == yellow
        colourName(ii) = {'YELLOW'};
    elseif distract_col(ii,:) == gray
        colourName(ii) = {'GREY'};
    end
end

sessionPoints = 0;

phaseLength = zeros(3, 1);





initialInstructions;

if eyeVersion
    runPTBcalibration;
end

pressSpaceToBegin;

phaseLength(1) = runTrials(1);     % Practice phase

save(datafilename, 'DATA');

exptInstructions;

if exptSession > 1
    Screen('TextSize', MainWindow, 40);
    Screen('TextStyle', MainWindow, 1);
    totalStr = ['In the previous session, you earned $', num2str(starting_total, '%0.2f'), '.\n\nThis will be added to whatever you earn in this session.'];
    DrawFormattedText(MainWindow, totalStr, 'center', 'center', yellow, [], [], [], 1.2);
    Screen(MainWindow, 'Flip');
    RestrictKeysForKbCheck(KbName('Space'));   % Only accept spacebar
    KbWait([], 2);
    RestrictKeysForKbCheck([]); % Re-enable all keys
    Screen(MainWindow, 'Flip');
end

Screen('TextSize', MainWindow, 38);
Screen('TextStyle', MainWindow, 1);

DrawFormattedText(MainWindow, 'Please tell the experimenter when you are ready to begin', 'center', 'center' , white);
DrawFormattedText(MainWindow, 'EXPERIMENTER: Press C to recalibrate, T to continue with test', 'center', 850, white);
Screen(MainWindow, 'Flip');

RestrictKeysForKbCheck([KbName('c'), KbName('t')]);   % Only accept keypresses from keys C and t
KbWait([], 2);
[~, ~, keyCode] = KbCheck;      % This stores which key is pressed (keyCode)
keyCodePressed = find(keyCode, 1, 'first');     % If participant presses more than one key, KbCheck will create a keyCode array. Take the first element of this array as the response
keyPressed = KbName(keyCodePressed);    % Get name of key that was pressed
RestrictKeysForKbCheck([]); % Re-enable all keys

if eyeVersion
    if keyPressed == 'c'
        runPTBcalibration;
    end
end

pressSpaceToBegin;


sessionPoints = 0;

if exptSession == 1
    phaseLength(2) = runTrials(2);
    phaseLength(3) = runTrials(3);
else
    phaseLength(2) = runTrials(2);
    awareInstructions;
    awareTest;
end


sessionBonus = 7 + (sessionPoints-14040) * 6 / 9360;   % convert points into cents at rate of 7200 points = $1

sessionBonus = ceil(sessionBonus*10) / 10;        % ... round this value UP to nearest 10 cents

if sessionBonus < 7        %check to see if participant earned less than $7.10; if so, adjust payment upwards
    actual_bonus_payment = 7;
elseif sessionBonus > 13
    actual_bonus_payment = 13;
    else
    actual_bonus_payment = sessionBonus;
end

DATA.session_Bonus = sessionBonus;
DATA.session_Points = sessionPoints;
DATA.actualBonusSession = actual_bonus_payment;
DATA.totalBonus = actual_bonus_payment + starting_total;
DATA.end_time = datestr(now,0);

save(datafilename, 'DATA');


[~, ny, ~] = DrawFormattedText(MainWindow, ['SESSION COMPLETE\n\nPoints in this session = ', separatethousands(sessionPoints, ','), '\n\nCash bonus in this session = $', num2str(actual_bonus_payment, '%0.2f')], 'center', 'center' , white);

if exptSession > 1
    [~, ny, ~] = DrawFormattedText(MainWindow, ['\n\n\nTOTAL CASH BONUS = $', num2str(actual_bonus_payment + starting_total , '%0.2f')], 'center', ny, yellow);
    
    fid1 = fopen('Data\BehavData\_TotalBonus_summary.csv', 'a');
    fprintf(fid1,'%d,%f\n', p_number, actual_bonus_payment + starting_total);
    fclose(fid1);
end




DrawFormattedText(MainWindow, '\n\nPlease fetch the experimenter', 'center', ny , white, [], [], [], 1.5);

Screen('Flip', MainWindow);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now condense all the EG data files for individual trials into a single
% file for each participant, and delete the originals
if eyeVersion
    overallEGdataFilename = [EGfolderName, '\GazeData', EGsubfolderNameString, '.mat'];
    
    if exptSession == 1
        minPhase = 2;
        maxPhase = 3;
    else
        minPhase = 2;
        maxPhase = 2;
    end        
    
    for exptPhase = minPhase : maxPhase
        
        for trial = 1 : phaseLength(exptPhase)
            inputFilename = [EGdataFilenameBase, 'Ph', num2str(exptPhase), 'T', num2str(trial), '.mat'];
            load(inputFilename);
            ALLGAZEDATA.EGdataPhase(exptPhase).EGdataTrial(trial).data = GAZEDATA;
            clear GAZEDATA;
        end
        
    end
    
    save(overallEGdataFilename, 'ALLGAZEDATA');
    rmdir([EGfolderName, '\', EGsubfolderNameString], 's');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


RestrictKeysForKbCheck(KbName('ESCAPE'));   % Only accept ESC key to quit
KbWait([], 2);




rmpath(genpath(functionFoldername));       % Then add path to this folder and all subfolders
Snd('Close');

Screen('Preference', 'SkipSyncTests',0);

sca;

clear all
