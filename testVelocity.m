velFig = figure(1);
posFig = figure(2);
maxPhase = [2,1];
for session = 1:2
    for phase = 1:maxPhase(session)
        %for t = 1:length(velSessionData(session).velPhaseData(phase).velTrialData)
            figure(1)
        plot([1:length(velSessionData(session).velPhaseData(phase).xTrialData{t})]', velSessionData(session).velPhaseData(phase).xTrialData{t}, [1:length(velSessionData(session).velPhaseData(phase).yTrialData{t})]', velSessionData(session).velPhaseData(phase).yTrialData{t});
        figure(2)
        plot([1:length(velSessionData(session).velPhaseData(phase).velTrialData{t})], velSessionData(session).velPhaseData(phase).velTrialData{t})
        hold on
        plot([1:length(velSessionData(session).velPhaseData(phase).velTrialData{t})], repmat(40,1,length(velSessionData(session).velPhaseData(phase).velTrialData{t})))
        hold off
        figure(3)
        plot([1:length(velSessionData(session).velPhaseData(phase).xRawTrialData{t})]', velSessionData(session).velPhaseData(phase).xRawTrialData{t}, [1:length(velSessionData(session).velPhaseData(phase).xRawTrialData{t})]', velSessionData(session).velPhaseData(phase).yRawTrialData{t})
        pause
        
        %end
    end
end 