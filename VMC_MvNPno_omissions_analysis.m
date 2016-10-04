function VMC_MvNPno_omissions_analysis()

clear all
clc

commandwindow;

global numBlocks distractTypes fid1 exptSessions exptPhases
global screenRes

RemoveInitial_N_trials = 2;
Remove_N_trialsAfterBreak = 2;
% anticipationLimit = 150;
% slowResponseLimit = 9999;

requiredTrialPropGoodSamples = 0.25;    % Sets lower limit of proportion of good gaze samples required for trial to be analysed (0.25 in previous papers)


defaultMinSubNumber = 1;
defaultMaxSubNumber = 40;

minSubNumber = input(['Lowest participant number (default = ', num2str(defaultMinSubNumber), ')  ---> ']);
maxSubNumber = input(['Highest participant number (default = ', num2str(defaultMaxSubNumber), ') ---> ']);

if isempty(minSubNumber)
    minSubNumber = defaultMinSubNumber;
end
if isempty(maxSubNumber)
    maxSubNumber = defaultMaxSubNumber;
end

distractTypes = 3;
exptSessions = 2;
exptPhases = 2;
awareTestTrials = 2;

numBlocks = zeros(exptSessions, exptPhases);
numBlocks(1,1) = 5;
numBlocks(1,2) = 8;
numBlocks(2,1) = 0;
numBlocks(2,2) = 13;

maxBlocks = max(numBlocks(:));      % Take column representation of numBlocks and find largest entry


% Create lots of matrices for storing different bits of data
omissionStoreBlock = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks, 2);    % The 2 in each of these is for 2 'distractors' on each trial (one of which may be grey)
omissionStoreSession = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, 2);
omissionStoreAll = zeros(maxSubNumber, distractTypes, exptPhases, 2);

omissionStoreBlock_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks, 2);
omissionStoreSession_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, 2);
omissionStoreAll_num = zeros(maxSubNumber, distractTypes, exptPhases, 2);

rtStoreBlock = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks);
rtStoreSession = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases);
rtStoreAll = zeros(maxSubNumber, distractTypes, exptPhases);

rtStoreBlock_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks);
rtStoreSession_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases);
rtStoreAll_num = zeros(maxSubNumber, distractTypes, exptPhases);


EGtimeOnDistractorBlock = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks, 2);
EGtimeOnDistractorSession = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, 2);
EGtimeOnDistractorAll = zeros(maxSubNumber, distractTypes, exptPhases, 2);

EGtimeOnDistractorBlock_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, maxBlocks, 2);
EGtimeOnDistractorSession_num = zeros(maxSubNumber, distractTypes, exptSessions, exptPhases, 2);
EGtimeOnDistractorAll_num = zeros(maxSubNumber, distractTypes, exptPhases, 2);


subNumSummary = zeros(maxSubNumber, 1);
missingTrials = zeros(maxSubNumber, exptSessions);
ageSummary = zeros(maxSubNumber, 1);
sexSummary = zeros(maxSubNumber, 1);
counterbalSummary = zeros(maxSubNumber, 1);
awareButtonSummary = zeros(maxSubNumber, awareTestTrials);
awareConfSummary = zeros(maxSubNumber, awareTestTrials);
sessionPayment = zeros(maxSubNumber, exptSessions);
fixationTimeouts = zeros(maxSubNumber, exptSessions);
trialTimeouts = zeros(maxSubNumber, exptSessions);
trialSoftTimeouts = zeros(maxSubNumber, exptSessions, exptPhases);
trialsSummary = zeros(maxSubNumber, exptSessions, exptPhases);
meanFixPropGood = zeros(maxSubNumber, exptSessions);
meanTrialPropGood = zeros(maxSubNumber, exptSessions);
meanPropGoodNum = zeros(maxSubNumber, exptSessions);
badSampleTrials = zeros(maxSubNumber, exptSessions);
trackerIDsummary = zeros(maxSubNumber, exptSessions);
startTimeSummary = cell(maxSubNumber, exptSessions);


% Define on-screen locations of stimuli (used for calculating distractor
% dwell time)
stimCentre = zeros(6, 2);
stimCentre(1,:) = [960, 340];
stimCentre(2,:) = [786.795, 440];
stimCentre(3,:) = [786.795, 640];
stimCentre(4,:) = [960, 740];
stimCentre(5,:) = [1133.205, 640];
stimCentre(6,:) = [1133.205, 440];

% Define distractor AOI (used for calculating distractor dwell time)
AOIradius = 100;

% Screen resolution and screen centre
screenRes(1) = 1920;
screenRes(2) = 1080;

screenCentre(1) = screenRes(1)/2;
screenCentre(2) = screenRes(2)/2;


timeOnLoc = zeros(6, 1);

fileCounter = 0;

exptName = 'VMC_MvNP_noOmi';

for subNum = minSubNumber : maxSubNumber
    
    behavFilenameBase = ['Data\BehavData\', exptName, '_dataP', num2str(subNum), '_'];
    
    session1Filename = [behavFilenameBase, 'S1.mat'];   % Start processing only if there's a session 1 and session 2 file for this participant
    session2Filename = [behavFilenameBase, 'S2.mat'];
    
    if exist(session1Filename, 'file') == 2 && exist(session2Filename, 'file') == 2
        
        
        fileCounter = fileCounter + 1;
        
        for sessionNum = 1 : exptSessions
            
            behavFilename = [behavFilenameBase, 'S', num2str(sessionNum), '.mat'];
            
            
            if exist(behavFilename, 'file') == 2
                
                disp(['Processing file ', behavFilename]);
                
                load(behavFilename);
                
                
                %                 % Create a few more matrices for storing data
                %                 storeLeftFixationTime = zeros(dim1,1);
                %                 storeLeftFixationRow = zeros(dim1,1);
                %                 storeSaccLat = zeros(dim1,1);
                %                 timeOnDistractor = zeros(dim1,1);
                
                % Copy some details about the participant and summary data
                subNumSummary(fileCounter) = DATA.subject;
                ageSummary(fileCounter) = DATA.age;
                counterbalSummary(fileCounter) = DATA.counterbal;
                
                if sessionNum == 1
                    fixationTimeouts(fileCounter, sessionNum) = DATA.fixationTimeouts(2) + DATA.fixationTimeouts(3);
                    trialTimeouts(fileCounter, sessionNum) = DATA.trialTimeouts(2) + DATA.trialTimeouts(3);
                else
                    fixationTimeouts(fileCounter, sessionNum) = DATA.fixationTimeouts(2);
                    trialTimeouts(fileCounter, sessionNum) = DATA.trialTimeouts(2);
                end
                
                trackerIDsummary(fileCounter, sessionNum) = sscanf(DATA.trackerID,'TX300-%f');
                
                if DATA.sex == 'f' || DATA.sex == 'F'
                    sexSummary(fileCounter) = 1;
                else
                    sexSummary(fileCounter) = 0;
                end
                
                startTimeSummary(fileCounter, sessionNum) = {DATA.start_time};
                
                if isfield(DATA, 'session_Bonus')
                    sessionPayment(fileCounter, sessionNum) = DATA.session_Bonus;
                end
                
                
                if sessionNum == exptSessions
                    
                    if isfield(DATA, 'awareTestInfo')
                        for ii = 1 : awareTestTrials
                            awareButtonSummary(fileCounter, DATA.awareTestInfo(ii, 2)) = DATA.awareTestInfo(ii, 3);
                            awareConfSummary(fileCounter, DATA.awareTestInfo(ii, 2)) = DATA.awareTestInfo(ii, 4);
                        end
                    end
                    
                end
                
                
                for exptPhase = 1 : exptPhases
                    
                    validPhase = true;
                    
                    if sessionNum == 1
                        if exptPhase == 1
                            datafilePhase = 2;      % Phase with no compound trials in session 1 is called phase 2 in data files
                        else
                            datafilePhase = 3;      % Phase with compound trials in session 1 is called phase 3 in data files
                        end
                        
                    elseif sessionNum == 2
                        if exptPhase == 1
                            datafilePhase = 0;      % session 2 has no phase with no compound trials
                            validPhase = false;
                        else
                            datafilePhase = 2;      % Phase in session 2 with compound trials is called phase 2 in data files
                        end
                    end
                    
                    if validPhase
                        
                        trialsPhase = size(DATA.trialInfo(datafilePhase).trialData, 1);
                        
                        trialsSummary(fileCounter, sessionNum, exptPhase) = trialsPhase;
                        
                        for trial = 1 : trialsPhase
                            
                            exptSession_data = DATA.trialInfo(datafilePhase).trialData(trial, 1);
                            block_data = DATA.trialInfo(datafilePhase).trialData(trial, 2);
                            trial_data = DATA.trialInfo(datafilePhase).trialData(trial, 3);
                            trialCounter_data = DATA.trialInfo(datafilePhase).trialData(trial, 4);
                            trials_since_break_data = DATA.trialInfo(datafilePhase).trialData(trial, 5);
                            targetLoc_data = DATA.trialInfo(datafilePhase).trialData(trial, 6);
                            distract1Loc_data = DATA.trialInfo(datafilePhase).trialData(trial, 7);
                            distract2Loc_data = DATA.trialInfo(datafilePhase).trialData(trial, 8);
                            fixationTime_data = DATA.trialInfo(datafilePhase).trialData(trial, 9);
                            fixationPropGoodSamples_data = DATA.trialInfo(datafilePhase).trialData(trial, 10);
                            fixationTimeout_data = DATA.trialInfo(datafilePhase).trialData(trial, 11);
                            trialPropGoodSamples_data = DATA.trialInfo(datafilePhase).trialData(trial, 12);
                            searchTimeout_data = DATA.trialInfo(datafilePhase).trialData(trial, 13);
                            softTimeoutTrial_data = DATA.trialInfo(datafilePhase).trialData(trial, 14);
                            omission1Trial_data = DATA.trialInfo(datafilePhase).trialData(trial, 15);
                            omission2Trial_data = DATA.trialInfo(datafilePhase).trialData(trial, 16);
                            rt_data = DATA.trialInfo(datafilePhase).trialData(trial, 17);
                            trialPay_data = DATA.trialInfo(datafilePhase).trialData(trial, 18);
                            sessionPoints_data = DATA.trialInfo(datafilePhase).trialData(trial, 19);
                            trialType_data = DATA.trialInfo(datafilePhase).trialData(trial, 20);
                            distract1Colour_data = DATA.trialInfo(datafilePhase).trialData(trial, 21);
                            distract2Colour_data = DATA.trialInfo(datafilePhase).trialData(trial, 22);
                            
                            for ii = 1 : 6
                                timeOnLoc(ii) = DATA.trialInfo(datafilePhase).trialData(trial, 22 + ii);
                            end
                            
                            if block_data == 0
                                
                                missingTrials(fileCounter, sessionNum) = missingTrials(fileCounter, sessionNum) + 1;
                                
                            else
                                
                                
                                if trial_data > RemoveInitial_N_trials && trials_since_break_data > Remove_N_trialsAfterBreak
                                    
                                    
                                    if searchTimeout_data ~= 1       % If not a timeout
                                        
                                        
                                        if trialPropGoodSamples_data >= requiredTrialPropGoodSamples      % If enough good samples to qualify for analysis
                                            
                                            % Store some data
                                            meanFixPropGood(fileCounter, sessionNum) = meanFixPropGood(fileCounter, sessionNum) + fixationPropGoodSamples_data;
                                            meanTrialPropGood(fileCounter, sessionNum) = meanTrialPropGood(fileCounter, sessionNum) + trialPropGoodSamples_data;
                                            meanPropGoodNum(fileCounter, sessionNum) = meanPropGoodNum(fileCounter, sessionNum) + 1;
                                            
                                            trialSoftTimeouts(fileCounter, sessionNum, exptPhase) = trialSoftTimeouts(fileCounter, sessionNum, exptPhase) + softTimeoutTrial_data;
                                            
                                            % trialType_data is crucial. 1 &
                                            % 2 = predictive (medium), 3 =
                                            % NP (high trials), 4 = NP (low
                                            % trials), 5 = P & NP
                                            if trialType_data == 1 || trialType_data == 2
                                                distractType = 1;
                                            elseif trialType_data == 3 || trialType_data == 4
                                                distractType = 2;
                                            elseif trialType_data == 5 || trialType_data == 6
                                                distractType = 3;
                                            end
                                            
                                            omissionData = [omission1Trial_data, omission2Trial_data];
                                            
                                            timeOnDistractData = [timeOnLoc(distract1Loc_data), timeOnLoc(distract2Loc_data)];
                                            
                                            % Store data regarding whether this is an
                                            % omission trial
                                            for ii = 1 : 2
                                                omissionStoreBlock(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) = omissionStoreBlock(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) + omissionData(ii);
                                                omissionStoreSession(fileCounter, distractType, sessionNum, exptPhase, ii) = omissionStoreSession(fileCounter, distractType, sessionNum, exptPhase, ii) + omissionData(ii);
                                                omissionStoreAll(fileCounter, distractType, exptPhase, ii) = omissionStoreAll(fileCounter, distractType, exptPhase, ii) + omissionData(ii);
                                                
                                                omissionStoreBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) = omissionStoreBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) + 1;
                                                omissionStoreSession_num(fileCounter, distractType, sessionNum, exptPhase, ii) = omissionStoreSession_num(fileCounter, distractType, sessionNum, exptPhase, ii) + 1;
                                                omissionStoreAll_num(fileCounter, distractType, exptPhase, ii) = omissionStoreAll_num(fileCounter, distractType, exptPhase, ii) + 1;
                                                
                                                if omissionData(ii) == 1
                                                    EGtimeOnDistractorBlock(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) = EGtimeOnDistractorBlock(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) + timeOnDistractData(ii);
                                                    EGtimeOnDistractorSession(fileCounter, distractType, sessionNum, exptPhase, ii) = EGtimeOnDistractorSession(fileCounter, distractType, sessionNum, exptPhase, ii) + timeOnDistractData(ii);
                                                    EGtimeOnDistractorAll(fileCounter, distractType, exptPhase, ii) = EGtimeOnDistractorAll(fileCounter, distractType, exptPhase, ii) + timeOnDistractData(ii);

                                                    EGtimeOnDistractorBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) = EGtimeOnDistractorBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data, ii) + 1;
                                                    EGtimeOnDistractorSession_num(fileCounter, distractType, sessionNum, exptPhase, ii) = EGtimeOnDistractorSession_num(fileCounter, distractType, sessionNum, exptPhase, ii) + 1;
                                                    EGtimeOnDistractorAll_num(fileCounter, distractType, exptPhase, ii) = EGtimeOnDistractorAll_num(fileCounter, distractType, exptPhase, ii) + 1;
                                                end
                                                
                                                
                                            end
                                            
                                            % And store RT data
                                            
                                            rtStoreBlock(fileCounter, distractType, sessionNum, exptPhase, block_data) = rtStoreBlock(fileCounter, distractType, sessionNum, exptPhase, block_data) + rt_data;
                                            rtStoreSession(fileCounter, distractType, sessionNum, exptPhase) = rtStoreSession(fileCounter, distractType, sessionNum, exptPhase) + rt_data;
                                            rtStoreAll(fileCounter, distractType, exptPhase) = rtStoreAll(fileCounter, distractType, exptPhase) + rt_data;
                                            
                                            rtStoreBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data) = rtStoreBlock_num(fileCounter, distractType, sessionNum, exptPhase, block_data) + 1;
                                            rtStoreSession_num(fileCounter, distractType, sessionNum, exptPhase) = rtStoreSession_num(fileCounter, distractType, sessionNum, exptPhase) + 1;
                                            rtStoreAll_num(fileCounter, distractType, exptPhase) = rtStoreAll_num(fileCounter, distractType, exptPhase) + 1;
                                            
                                            
                                        else
                                            
                                            badSampleTrials(fileCounter, sessionNum) = badSampleTrials(fileCounter, sessionNum) + 1;
                                            
                                        end    % If trial has high enough proportion of good samples
                                        
                                    end       % If a timeout
                                    
                                    
                                end   % If an excluded trial at start of expt / after pause
                                
                            end   % If data missing
                            
                            
                        end   % For loop for trials
                        
                    end   % if not a valid phase
                    
                end   % for loop for phases
                
                clear DATA
                
            else
                
                disp(['File ', dataFilename, ' not found']);
                
            end     % If current session file exists
            
            
        end    % For loop over sessions
        
        
        meanFixPropGood(fileCounter, :) = meanFixPropGood(fileCounter, :) ./ meanPropGoodNum(fileCounter, :);
        meanTrialPropGood(fileCounter, :) = meanTrialPropGood(fileCounter, :) ./ meanPropGoodNum(fileCounter, :);
        
        omissionStoreBlock(fileCounter, :, :, :, :, :) = omissionStoreBlock(fileCounter, :, :, :, :, :) ./ omissionStoreBlock_num(fileCounter, :, :, :, :, :);
        omissionStoreSession(fileCounter, :, :, :, :) = omissionStoreSession(fileCounter, :, :, :, :) ./ omissionStoreSession_num(fileCounter, :, :, :, :);
        omissionStoreAll(fileCounter, :, :, :) = omissionStoreAll(fileCounter, :, :, :) ./ omissionStoreAll_num(fileCounter, :, :, :);
        
        rtStoreBlock(fileCounter, :, :, :, :) = rtStoreBlock(fileCounter, :, :, :, :) ./ rtStoreBlock_num(fileCounter, :, :, :, :);
        rtStoreSession(fileCounter, :, :, :) = rtStoreSession(fileCounter, :, :, :) ./ rtStoreSession_num(fileCounter, :, :, :);
        rtStoreAll(fileCounter, :, :) = rtStoreAll(fileCounter, :, :) ./ rtStoreAll_num(fileCounter, :, :);
        
        EGtimeOnDistractorBlock(fileCounter, :, :, :, :, :) = EGtimeOnDistractorBlock(fileCounter, :, :, :, :, :) ./ EGtimeOnDistractorBlock_num(fileCounter, :, :, :, :, :);
        EGtimeOnDistractorSession(fileCounter, :, :, :, :) = EGtimeOnDistractorSession(fileCounter, :, :, :, :) ./ EGtimeOnDistractorSession_num(fileCounter, :, :, :, :);
        EGtimeOnDistractorAll(fileCounter, :, :, :) = EGtimeOnDistractorAll(fileCounter, :, :, :) ./ EGtimeOnDistractorAll_num(fileCounter, :, :, :);
        
        
    else
        disp(['File ', session1Filename, ' not found']);
        
    end    % If session 1 file exists
    
end   % For loop for subjects





for outputType = 1 : 3
    
    if outputType == 1
        
        outDataBlock = omissionStoreBlock;
        outDataSession = omissionStoreSession;
        outDataAll = omissionStoreAll;
        
        numVariants = 2;
        
        outString = 'om';
        
    elseif outputType == 2
        
        outDataBlock = EGtimeOnDistractorBlock;
        outDataSession = EGtimeOnDistractorSession;
        outDataAll = EGtimeOnDistractorAll;
        
        numVariants = 2;
        
        outString = 'dw';
        
    elseif outputType == 3
        
        outDataBlock = rtStoreBlock;
        outDataSession = rtStoreSession;
        outDataAll = rtStoreAll;
        
        numVariants = 1;
        
        outString = 'rt';
        
    end
    
    fid1 = fopen([exptName, '_', outString, '.csv'], 'w');
    
    for outRow = 0 : fileCounter
        
        headerRow = false;
        if outRow == 0
            headerRow = true;
        end
        
        
        if headerRow
            fprintf(fid1,'subNum,');
            fprintf(fid1,'age,');
            fprintf(fid1,'sex,');
            fprintf(fid1,'counterbal,');
            fprintf(fid1,'bonus1,bonus2,');
            fprintf(fid1,'trackerID1,trackerID2,');
            fprintf(fid1,'time1,time2,');
            fprintf(fid1,'missing1,missing2,');
            fprintf(fid1,'badSampleTrials1,badSampleTrials2,');
            fprintf(fid1,'fixTimeouts1,fixTimeouts2,');
            fprintf(fid1,'trialTimeouts1,trialTimeouts2,');
            fprintf(fid1,'fixPropGood1,fixPropGood2,');
            fprintf(fid1,'trialPropGood1,trialPropGood2,');
            
            
        else        % Not header row
            
            fprintf(fid1,'%d,', subNumSummary(outRow));
            fprintf(fid1,'%d,', ageSummary(outRow));
            fprintf(fid1,'%d,', sexSummary(outRow));
            fprintf(fid1,'%d,', counterbalSummary(outRow));
            fprintf(fid1,'%f,', sessionPayment(outRow,:));
            fprintf(fid1,'%15.0d,', trackerIDsummary(outRow,:));
            fprintf(fid1, [char(startTimeSummary(outRow,1)), ',', char(startTimeSummary(outRow,2)), ',']);
            fprintf(fid1,'%d,', missingTrials(outRow,:));
            fprintf(fid1,'%d,', badSampleTrials(outRow,:));
            fprintf(fid1,'%d,', fixationTimeouts(outRow,:));
            fprintf(fid1,'%d,', trialTimeouts(outRow,:));
            fprintf(fid1,'%f,', meanFixPropGood(outRow,:));
            fprintf(fid1,'%f,', meanTrialPropGood(outRow,:));
            
        end
        
        for exptSession = 1 : exptSessions
            for exptPhase = 1 : exptPhases
                if headerRow
                    fprintf(fid1, ['trials_S', num2str(exptSession), 'Ph', num2str(exptPhase), ',']);
                else
                    fprintf(fid1,'%d,', trialsSummary(outRow, exptSession, exptPhase));
                end
            end
        end
        
        for exptSession = 1 : exptSessions
            for exptPhase = 1 : exptPhases
                if headerRow
                    fprintf(fid1, ['softTO_S', num2str(exptSession), 'Ph', num2str(exptPhase), ',']);
                else
                    fprintf(fid1,'%d,', trialSoftTimeouts(outRow, exptSession, exptPhase));
                end
            end
        end
        
        fprintf(fid1,',');
        for ii = 1 : awareTestTrials
            if headerRow
                fprintf(fid1, ['awareButtonD', num2str(ii), ',']);
                fprintf(fid1, ['awareConfD', num2str(ii), ',']);
            else
                fprintf(fid1,'%d,', awareButtonSummary(outRow, ii));
                fprintf(fid1,'%d,', awareConfSummary(outRow, ii));
            end
        end
        
        
        
        fprintf(fid1,',');
        for exptPhase = 1 : exptPhases
            for distractType = 1 : distractTypes
                for variant = 1 : numVariants
                    
                    if headerRow
                        fprintf(fid1, ['ALL_', outString, '_Ph', num2str(exptPhase), 'D', num2str(distractType), 'V', num2str(variant), ',']);
                    else
                        fprintf(fid1,'%8.6f,', outDataAll(outRow, distractType, exptPhase, variant));
                    end
                    
                end
            end
            fprintf(fid1,',');
        end
        
        
        fprintf(fid1,',');
        for exptPhase = 1 : exptPhases
            for exptSession = 1 : exptSessions
                for distractType = 1 : distractTypes
                    for variant = 1 : numVariants
                        
                        if headerRow
                            fprintf(fid1, ['SES_', outString, '_Ph', num2str(exptPhase), '_S', num2str(exptSession), 'D', num2str(distractType), 'V', num2str(variant), ',']);
                        else
                            fprintf(fid1,'%8.6f,', outDataSession(outRow, distractType, exptSession, exptPhase, variant));
                        end
                        
                    end
                end
            end
            fprintf(fid1,',');
        end
        
        fprintf(fid1,',');
        for exptPhase = 1 : exptPhases
            for exptSession = 1 : exptSessions
                for distractType = 1 : distractTypes
                    for variant = 1 : numVariants
                        for block = 1 : numBlocks(exptSession, exptPhase)
                            
                            if headerRow
                                fprintf(fid1, ['SES_', outString, '_Ph', num2str(exptPhase), '_S', num2str(exptSession), 'D', num2str(distractType), 'V', num2str(variant), 'B', num2str(block), ',']);
                            else
                                fprintf(fid1,'%8.6f,', outDataBlock(outRow, distractType, exptSession, exptPhase, block, variant));
                            end
                            
                        end
                        fprintf(fid1,',');
                    end
                end
            end
        end
        
        fprintf(fid1,'\n');
        
    end
    
    fprintf(fid1,'\n');
    fprintf(fid1,'Distract 1 = Predictive (M)');
    fprintf(fid1,'Distract 2 = Nonpredictive (H/L)');
    
    fprintf(fid1,'RemoveInitial_N_trials,%d\n', RemoveInitial_N_trials);
    fprintf(fid1,'Remove_N_trialsAfterBreak,%d\n', Remove_N_trialsAfterBreak);
    fprintf(fid1,'requiredTrialPropGoodSamples,%f\n', requiredTrialPropGoodSamples);
    
    fclose(fid1);
end

clear all

end
