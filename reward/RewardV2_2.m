%% Reward Paradigm (Ponz et al 2010) adapted for EEG

% Version 2 
% Includes a constant indication of the total points in lower right corner
% Includes a user prompt for participant ID and number of trials
% Saves name as "RT_Results_ParticipantID.mat"

% Version 2.1
% Automatic breaks at trials 50, 100, and 150
% Now with German feedback

% Version 2.2
% Now measures and records actual reaction time
%
% 28.01.11
% Save name is not the participant ID + _RT

clear all
clc

myRand = RandStream('mt19937ar','Seed',sum(100*clock));
RandStream.setDefaultStream(myRand);

%% Configure Parallel Port

dio=digitalio('parallel', 'lpt1'); %creates the object
addline(dio,0:7,0,'out');   %adds the lines... only needed once  

%% User Prompt for participant ID and number of trials

prompt      = {'Participant ID', 'Number of Trials?'};
dlg_title   = 'Reward Task';
def         = {'AA0101', '200'};
Info        = inputdlg(prompt, dlg_title,1,def);

%% Parameter Preprocessing

SaveName    = strcat(Info{1}, '_RT'); %
no_trials   = str2double(Info{2});         % numbers of pictures to present

load Reward_Stimulus.mat;

TW          = 0.2;
bgCol       = [255 255 255];
fgCol       = [0 0 0];

[window, rect] = Screen('OpenWindow',0, bgCol);
[ FRate ] =Screen('GetFlipInterval', window);
HideCursor

wWidth      = rect(3);
wHeight     = rect(4);
            
scx         = wWidth/2;
scy         = wHeight/2;

fixa = [scx-50, scx-10; scy-10, scy-50;...
        scx+50, scx+10; scy+10, scy+50]; % Two overlapping rectangles

%% Get Priority levels and change ours to the maximum

priorityLevel   = MaxPriority(window);
Priority(priorityLevel);

%% Welcome Screen

Screen(window,'TextSize',35);
Screen(window,'TextFont',['Times New Roman']);

[newX, newY]= Screen('DrawText', window, 'Drücken Sie eine beliebige Taste, um den Versuch zu starten', 0, 0, bgCol);
[SucX, SucY]= Screen('DrawText', window, 'Bravo!', 0, 0, bgCol);
[TotX, TotY]= Screen('DrawText', window, 'Sie haben jetzt XX Punkte', 0, 0, bgCol);
% Screen('Flip', window, [0], [0]); %Essentially just clears the screen for the next object...

Screen('DrawText', window, 'Drücken Sie eine beliebige Taste, um den Versuch zu starten', wWidth/2-(newX/2) , wHeight/2, fgCol);
Screen('Flip', window, [0], [0]); %Present the prepared DrawText
KbWait;

Screen(window,'TextSize',50);

%% Resampling the Cues and Targets

cue_mix = randsample(8, no_trials,true);
tar_mix = randsample(12,no_trials,true);

Delay   = (FRate * 30)+(FRate/2); %Multiples of the screen refresh rate
NewTotal = 0;
Reaction_Time = 0;

%% Experimental Loop

for i = 1:no_trials

if (i == 51) ||  (i == 101) || (i == 151)
    
    Screen(window,'TextSize',35);
    
    Screen('DrawText', window, 'Zeit für eine kleine Pause', wWidth/2-(newX/2) , wHeight/2-70, fgCol);
    Screen('DrawText', window, 'Drücken Sie eine beliebige Taste, um den Versuch zu starten', wWidth/2-(newX/2) , wHeight/2, fgCol);
    Screen('Flip', window, [0], [0]); %Present the prepared DrawText
    
    Screen(window,'TextSize',50);
    
    KbWait;
    
end

Response = 0;    
c       = cue_mix(i);
t       = tar_mix(i);
Jitter  = rand(1)*1.5+.5;
    
curr_cue    = (Stim.Cues{1,c});
curr_tar    = (Stim.Targets{1,t});

cue_tex     = Screen('MakeTexture', window, curr_cue);
tar_tex     = Screen('MakeTexture', window, curr_tar);

Screen('DrawText', window, sprintf('%i', NewTotal), wWidth*.95, wHeight*.9, fgCol);   
Screen('DrawTexture', window, cue_tex);
CueOn       = Screen('Flip', window);


putvalue(dio.line(1),1) %send high pulse (1) to line 'l' (S1)
putvalue(dio.line(1),0) %resets line 'l' to low (0)



Screen('DrawText', window, sprintf('%i', NewTotal), wWidth*.95, wHeight*.9, fgCol);   
Screen('FillRect', window, fgCol, fixa);
FixOn       = Screen('Flip', window, CueOn+1);

Screen('DrawText', window, sprintf('%i', NewTotal), wWidth*.95, wHeight*.9, fgCol);   
Screen('DrawTexture', window, tar_tex);
TarOn       = Screen('Flip', window, FixOn + Jitter);



putvalue(dio.line(2),1) %send high pulse (1) to line '2' (S2)
putvalue(dio.line(2),0) %resets line 'l' to low (0)



%% Look for keyboard responses while the target is presented
while GetSecs-TarOn < Delay
     [keyIsDown, secs] = KbCheck;
    if keyIsDown
        Response = 1;
        Reaction_Time = secs - TarOn;
    end
    %while KbCheck; end
end

Screen('DrawText', window, sprintf('%i', NewTotal), wWidth*.95, wHeight*.9, fgCol); 
BlankOn     = Screen('Flip', window, TarOn + Delay);



%% Process Cues and Responses in order to produce the correct feedback

    if (c == 1) || (c == 3) 
        if Response == 1
            Screen('DrawText', window, 'Bravo!!!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
        else
            NewTotal = NewTotal - 1;
            Screen('DrawText', window, 'Zu spät!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
        end

    elseif (c == 2) || (c == 4)
         if Response == 1
            Screen('DrawText', window, 'Bravo!!!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
        else
            NewTotal = NewTotal - 5;
            Screen('DrawText', window, 'Zu spät!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
         end

    elseif (c == 5) || (c == 7)
         if Response == 1
            NewTotal = NewTotal + 1; 
            Screen('DrawText', window, 'Bravo!!!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
         else
            Screen('DrawText', window, 'Zu spät!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
         end

    elseif (c == 6) || (c == 8)
        if Response == 1
            NewTotal = NewTotal + 5; 
            Screen('DrawText', window, 'Bravo!!!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
        else
            Screen('DrawText', window, 'Zu spät!', wWidth/2-(SucX/2) , wHeight/2-50, fgCol);
        end

    end

Screen('DrawText', window, sprintf('%i', NewTotal), wWidth*.95, wHeight*.9, fgCol);    
Screen('DrawText', window, sprintf('Sie haben jetzt %i Punkte', NewTotal), wWidth/2-(TotX/2), wHeight/2+50, fgCol);

FeedbackOn  = Screen('Flip', window, TarOn + 2.5); % Displays feedback 2.5s after target (regardless of Delay)
putvalue(dio.line(3),1) %send high pulse (1) to line '2' (S4)
putvalue(dio.line(3),0) %resets line 'l' to low (0)

%% Results Processing

Results.Delay(i)   = Delay;    % Records the Participant's Delay for that Trial
Results.Correct(i) = Response; % Records the Participant's Response for that Trial
Results.Cue(i)     = c; % Records the Preseneted Cue
Results.Time(i)    = Reaction_Time; % Records response time
Results.Totals(i)  = NewTotal;

    if Response == 1
       Delay = Delay-(FRate*2); % Decrease the delay by ~33ms
    else
       Delay = Delay+(FRate*2); % Increase the delay by ~33ms
    end

WaitSecs(1);

Screen('Close', cue_tex);
Screen('Close', tar_tex);

end

%% Text for end of the experiment

[newX, newY]= Screen('DrawText', window, 'Ende des Experiments, vielen Dank', 0, 0, bgCol);
Screen('Flip', window, [0], [0]); %Essentially just clears the screen for the next object...

Screen('DrawText', window, 'Ende des Experiments, vielen Dank', wWidth/2-(newX/2) , wHeight/2, fgCol);
Screen('Flip', window, [0], [0]); %Present the prepared DrawText
KbWait;
WaitSecs(0.5);

Screen('CloseAll');

%% End of Experiment
Screen('CloseAll');

save(SaveName, 'Results');

%y=cell2mat(struct2cell(Results))'; %use to copy to excel