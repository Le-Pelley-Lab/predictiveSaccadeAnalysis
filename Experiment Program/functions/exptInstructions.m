
function exptInstructions

global bigMultiplier smallMultiplier medMultiplier
global softTimeoutDuration

instructStr1 = 'The rest of this experiment is similar to the trials you have just completed. On each trial, you should move your eyes to the DIAMOND shape as quickly and directly as possible.';

instructStr2 = ['From now on, you will be able to earn money for correct responses. On each trial you will earn either ', num2str(smallMultiplier), ' points, ', num2str(medMultiplier), ' points, or ', num2str(bigMultiplier), ' points. The amount that you earn will depend on how fast and accurately you move your eyes to the diamond shape.'];

instructStr3 = ['If you take longer than ', num2str(round(softTimeoutDuration * 1000)), ' milliseconds to move your eyes to the diamond, you will receive no points. So you will need to move your eyes quickly!'];
instructStr6 = 'At the end of the session the number of points that you have earned will be used to calculate your total reward payment.\n\nMost participants are able to earn between $7 and $13 in each session of the experiment.';

show_Instructions(1, instructStr1, .1);
show_Instructions(2, instructStr2, .1);
show_Instructions(3, instructStr3, .1);
show_Instructions(6, instructStr6, .1);

end


function show_Instructions(instrTrial, insStr, instrPause)

global MainWindow white

oldTextSize = Screen('TextSize', MainWindow, 46);
oldTextStyle = Screen('TextStyle', MainWindow, 1);

textTop = 150;
characterWrap = 60;
DrawFormattedText(MainWindow, insStr, 120, textTop, white, characterWrap, [], [], 1.2);


Screen('Flip', MainWindow, []);

Screen('TextSize', MainWindow, oldTextSize);
Screen('TextStyle', MainWindow, oldTextStyle);


RestrictKeysForKbCheck(KbName('Space'));   % Only accept spacebar
KbWait([], 2);
RestrictKeysForKbCheck([]); % Re-enable all keys
Screen(MainWindow, 'Flip');

end