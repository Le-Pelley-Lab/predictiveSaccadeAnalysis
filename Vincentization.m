function Vincentization

clear all

global quantiles


quantiles = 3;
%load('SaccadeLatencyData_Session2.mat')
maxSubs = 40;
subNums = zeros(maxSubs,1);
predictivePropDist = zeros(maxSubs,quantiles);
predictiveProp2Dist = zeros(maxSubs,quantiles);
predictivePropTarget = zeros(maxSubs,quantiles);
predictiveNum = zeros(maxSubs,quantiles);
nonPredictivePropDist = zeros(maxSubs,quantiles);
nonPredictiveProp2Dist = zeros(maxSubs,quantiles);
nonPredictivePropTarget = zeros(maxSubs,quantiles);
nonPredictiveNum = zeros(maxSubs,quantiles);
doublePropDist = zeros(maxSubs,quantiles);
doubleProp2Dist = zeros(maxSubs,quantiles);
doublePropTarget = zeros(maxSubs,quantiles);
doubleNum = zeros(maxSubs,quantiles);

wd = cd;
maxPhases = [2,1]; % Session 1 = 2 phases; Session 2 = 1 phase

minSub = input('Lowest participant number (if empty = 1) --> ');
if isempty(minSub)
    minSub = 1;
end
maxSub = input('Highest participant number (if empty = 100) --> ');
if isempty(maxSub)
    maxSub = 100;
end

s = 0;

for sub = minSub : maxSub
    
    testFilename = [wd '\SummarySaccadeDataP' num2str(sub) '.mat'];
    
    if exist(testFilename, 'file') == 2
        
        s = s + 1;
        
        saccadeFilename = [wd '\SummarySaccadeDataP' num2str(sub) '.mat'];
        
        load(saccadeFilename);
        
        discardedTrials(s) = 0;
        anticipatorySaccades(s) = 0;
        outsideFixation(s) = 0;
        noSaccades(s) = 0;
        noValidData(s) = 0;
        
        subNums(s) = saccadeSessionData(1).saccadePhaseData(1).summarySaccadeData(1,1);
        
        for session = 1:2
            
            behavFilename = [wd '\Data\BehavData\VMC_MvNP_noOmi_dataP' num2str(sub) '_S', num2str(session) '.mat'];
            
            load(behavFilename);
            
            for phase = 1:maxPhases(session)
                
                saccadeData  = [saccadeSessionData(session).saccadePhaseData(phase).summarySaccadeData DATA.trialInfo(phase+1).trialData(:,[20 6:8]) ];
                
                discardedTrials(s) = discardedTrials(s) + sum(saccadeData(:,11));
                anticipatorySaccades(s) = anticipatorySaccades(s) + sum(saccadeData(:,12));
                outsideFixation(s) = outsideFixation(s) + sum(saccadeData(:,13));
                noSaccades(s) = noSaccades(s) + sum(saccadeData(:,14));
                noValidData(s) = noValidData(s) + sum(saccadeData(:,15));
                
                saccadeData(saccadeData(:,11)==1,:) = []; %remove discarded trials
                
                sessionProps(session).phaseProps(phase).predictiveProps = saccadeData(saccadeData(:,16) == 1 | saccadeData(:,16) == 2,:);
                sessionProps(session).phaseProps(phase).nonPredictiveProps = saccadeData(saccadeData(:,16) == 3 | saccadeData(:,16) == 4,:);
                sessionProps(session).phaseProps(phase).doubleProps = saccadeData(saccadeData(:,16) == 5 | saccadeData(:,16) == 6,:);
                
            end
        end
        
        combinedProps.predictiveProps = [sessionProps(1).phaseProps(1).predictiveProps; sessionProps(1).phaseProps(2).predictiveProps; sessionProps(2).phaseProps(1).predictiveProps];
        combinedProps.nonPredictiveProps = [sessionProps(1).phaseProps(1).nonPredictiveProps; sessionProps(1).phaseProps(2).nonPredictiveProps; sessionProps(2).phaseProps(1).nonPredictiveProps];
        combinedProps.doubleProps = [sessionProps(1).phaseProps(1).doubleProps; sessionProps(1).phaseProps(2).doubleProps; sessionProps(2).phaseProps(1).doubleProps];
        
        latencyDeciles.predictive(s,1:quantiles) = quantile(combinedProps.predictiveProps(:,3),quantiles);
        latencyDeciles.nonPredictive(s,1:quantiles) = quantile(combinedProps.nonPredictiveProps(:,3), quantiles);
        latencyDeciles.double(s,1:quantiles) = quantile(combinedProps.doubleProps(:,3), quantiles);
        
        for d = 1:quantiles
            
            if d == 1
                startDecPredictive = 0;
                startDecNonPredictive = 0;
                startDecDouble = 0;
            else
                startDecPredictive = latencyDeciles.predictive(s,d-1);
                startDecNonPredictive = latencyDeciles.nonPredictive(s,d-1);
                startDecDouble = latencyDeciles.double(s,d-1);
            end
            
            tempPredictiveData = combinedProps.predictiveProps(combinedProps.predictiveProps(:,3)<latencyDeciles.predictive(s,d) & combinedProps.predictiveProps(:,3) > startDecPredictive,:);
            tempNonPredictiveData = combinedProps.nonPredictiveProps(combinedProps.nonPredictiveProps(:,3)<latencyDeciles.nonPredictive(s,d) & combinedProps.nonPredictiveProps(:,3) > startDecNonPredictive,:);
            tempDoubleData = combinedProps.doubleProps(combinedProps.doubleProps(:,3)<latencyDeciles.double(s,d) & combinedProps.doubleProps(:,3) > startDecDouble,:);
            
            
            for t = 1:size(tempPredictiveData,1)
                saccDir = find(tempPredictiveData(t,4:10)==1);
                if saccDir == tempPredictiveData(t,17) %saccade to target
                    predictivePropTarget(s,d) = predictivePropTarget(s,d) + 1;
                elseif saccDir == tempPredictiveData(t,18) %saccade to main distractor
                    predictivePropDist(s,d) = predictivePropDist(s,d) + 1;
                elseif saccDir == tempPredictiveData(t,19) %saccade to sec distractor
                    predictiveProp2Dist(s,d) = predictiveProp2Dist(s,d) + 1;
                end
            end
            predictiveNum(s,d) = size(tempPredictiveData,1);
            
            for t = 1:size(tempNonPredictiveData,1)
                saccDir = find(tempNonPredictiveData(t,4:10)==1);
                if saccDir == tempNonPredictiveData(t,17) %saccade to target
                    nonPredictivePropTarget(s,d) = nonPredictivePropTarget(s,d) + 1;
                elseif saccDir == tempNonPredictiveData(t,18) %saccade to main distractor
                    nonPredictivePropDist(s,d) = nonPredictivePropDist(s,d) + 1;
                elseif saccDir == tempNonPredictiveData(t,19) %saccade to sec distractor
                    nonPredictiveProp2Dist(s,d) = nonPredictiveProp2Dist(s,d) + 1;
                end
            end
            nonPredictiveNum(s,d) = size(tempNonPredictiveData,1);
            
            for t = 1:size(tempDoubleData,1)
                saccDir = find(tempDoubleData(t,4:10)==1);
                if saccDir == tempDoubleData(t,17) %saccade to target
                    doublePropTarget(s,d) = doublePropTarget(s,d) + 1;
                elseif saccDir == tempDoubleData(t,18) %saccade to main distractor
                    doublePropDist(s,d) = doublePropDist(s,d) + 1;
                elseif saccDir == tempDoubleData(t,19) %saccade to sec distractor
                    doubleProp2Dist(s,d) = doubleProp2Dist(s,d) + 1;
                end
            end
            doubleNum(s,d) = size(tempDoubleData,1);
        end
        
        
        predictivePropDist(s,:) = predictivePropDist(s,:)./predictiveNum(s,:);
        predictivePropTarget(s,:) = predictivePropTarget(s,:)./predictiveNum(s,:);
        predictiveProp2Dist(s,:) = predictiveProp2Dist(s,:)./predictiveNum(s,:);
        
        nonPredictivePropDist(s,:) = nonPredictivePropDist(s,:)./nonPredictiveNum(s,:);
        nonPredictivePropTarget(s,:) = nonPredictivePropTarget(s,:)./nonPredictiveNum(s,:);
        nonPredictiveProp2Dist(s,:) = nonPredictiveProp2Dist(s,:)./nonPredictiveNum(s,:);
        
        doublePropDist(s,:) = doublePropDist(s,:)./doubleNum(s,:);
        doubleProp2Dist(s,:) = doubleProp2Dist(s,:)./doubleNum(s,:);
        doublePropTarget(s,:) = doublePropTarget(s,:)./doubleNum(s,:);
        
        
    else
        disp(['DATA FOR PARTICIPANT ', num2str(sub), ' NOT FOUND']);
    end
end

save('VincentizerCheck_Predictiveness.mat');

global fid1

fid1 = fopen('Vincentized_MvNP_noOmi_2.csv', 'w');

outputHeaders;

for ii = 1 : s
    fprintf(fid1,'%d,', subNums(ii));
    fprintf(fid1,',');
    fprintf(fid1,'%d,', discardedTrials(ii));
    fprintf(fid1,'%d,', anticipatorySaccades(ii));
    fprintf(fid1,'%d,', outsideFixation(ii));
    fprintf(fid1,'%d,', noSaccades(ii));
    fprintf(fid1,'%d,', noValidData(ii));
    fprintf(fid1,',');
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,', latencyDeciles.predictive(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',predictivePropTarget(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',predictivePropDist(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',predictiveProp2Dist(ii,d));
    end
    fprintf(fid1,',');
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,', latencyDeciles.nonPredictive(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',nonPredictivePropTarget(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',nonPredictivePropDist(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',nonPredictiveProp2Dist(ii,d));
    end
    fprintf(fid1,',');
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,', latencyDeciles.double(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',doublePropTarget(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',doublePropDist(ii,d));
    end
    fprintf(fid1,',');
    for d = 1:quantiles
        fprintf(fid1,'%8.6f,',doubleProp2Dist(ii,d));
    end
    fprintf(fid1,'\n');
end

fclose(fid1);


end

function outputHeaders

global fid1 quantiles

trialTypes = 3;
valTypes = 4;
TTnames = {'predictive', 'nonPredictive', 'double'};
valNames = {'latency', 'TargetProp', 'DistProp', '2DistProp'};


fprintf(fid1, 'SubNum,');
fprintf(fid1,',');
fprintf(fid1,'discardedTrials,');
fprintf(fid1,'anticipatorySaccades,');
fprintf(fid1,'outsideFixations,');
fprintf(fid1,'noSaccades,');
fprintf(fid1,'noValidData,');



for tt = 1:trialTypes
    fprintf(fid1,',');
    for vv = 1:valTypes
        fprintf(fid1,',');
        for d = 1:quantiles
            fprintf(fid1, [TTnames{tt}, '_', valNames{vv}, '_d', num2str(d),',']);
        end
    end
end

fprintf(fid1,'\n');

end

