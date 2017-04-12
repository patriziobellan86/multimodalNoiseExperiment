KbName('UnifyKeyNames');
% clear workspace
clear;
clc;
% avoid errors
PsychPortAudio('Close');
sca;
% suppress all warning
Screen('Preference', 'SuppressAllWarnings', 1);
warning('off','all');

%% EXPERIMENT CONSTANTS AND VARIABLES
presentationTime=0.2;     % stimulus'presentation time
numBlocks = 1;       % numer of blocks 
numStimuli = 40;     % stimuli to present in each block
numNoStimuli = 20;   % stimuli NON present in each block
nimgGrid = 2;        % number images presented in grid-phase
noiseFactors = {0.0 0.05 0.1 0.15};   % noise 
pauseIntratrial = 1; % pause between trials
pauseTrial = 1;      % pause between offset and retrivial phase
% durationAudio = 2.0; % audio data duration
fs = 44100;
% response = 0;        % variable for collecting responses
dataname = 'temporany.tmp'; % filename for save response
current_folder = fileparts(mfilename('fullpath'));  % current folder
%% SCRIPT CONSTANTS AND VARIABLES
sep = PathSep ();    % system separator
screenSize = get( groot, 'Screensize' ); % Display dimension
screenFactor = 0.75;    % 1 = FULL SCREEN
% Screen size
screen_h = floor(screenSize(3)*screenFactor);  % real screen dimension height
screen_v = floor(screenSize(4)*screenFactor);  % real screen dimension vertical

dimimg = floor(screen_h/4);                    % dimension image
strYpos = floor(dimimg/3);                     % y pos for sentences

% computing sceen position 
screenW_x = floor((screenSize(3) - floor(screenSize(3)*screenFactor))/2);
screenW_y = floor((screenSize(4) - floor(screenSize(4)*screenFactor))/2);
screenW_h = screen_h + floor((screenSize(3) - floor(screenSize(3)*screenFactor))/2);
screenW_v = screen_v + floor((screenSize(4) - floor(screenSize(4)*screenFactor))/2);
% grid creation
gridImgSize  = floor(screen_v/4);
% boreder size
border = floor(gridImgSize/4);
gridImgSize = [gridImgSize gridImgSize];
% grid images coords
igrid=1;
for x=border+((screen_h-screen_v)/2):gridImgSize(1)+border:screen_v+border+((screen_h-screen_v)/2)
    for y=border:gridImgSize(1)+border:screen_v
        if x+gridImgSize(1) <= (screen_v+border+((screen_h-screen_v)/2)) & y+gridImgSize(1) <= screen_v
            RectsGrid(igrid,:)=[x y x+gridImgSize(1) y+gridImgSize(1)];
            igrid = igrid+1;
        end
    end
end
fixationTime = 0.5;

%% SCRIPT START

% INIZIALIZATIONS
% audio
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', [], [], [], fs,1);
% video
win=Screen('OpenWindow',0,[255 255 255],[screenW_x screenW_y screenW_h screenW_v]);

% change focus to command window
commandwindow;

str = sprintf('Assignment 2 \n\n Patrizio Bellan \n\n CIMeC');
DrawFormattedText(win, str, 'center','center');
Screen(win,'flip');
pause(3); 

ans = AskForString(win, 'Would you like run the experiment? (y: yes, n: no): ');
if strcmp(ans,'y')
    str = sprintf('Choose experiment s folder');
    DrawFormattedText(win, str, 'center','center');
    Screen(win,'flip');
    pause(2);

    % selecting experiment folder
    while true
        folder_name = uigetdir(current_folder, 'Selecting the folder of the experiment');
        if folder_name
            break;
        end
    end
    
    DrawFormattedText(win,'loading data experiment', 'center','center');
    Screen(win,'flip');
    
    % load data
    stimuli=LoadData(current_folder, dimimg);
    
    % ask partecipant name
    partecipantName = AskForString(win, 'Partecipant Name: ');
    % coding Name for save file
    dataname = strcat('subject_', partecipantName(randi(length(partecipantName))), ...
                partecipantName(randi(length(partecipantName))));
            
    %% EXPERIMENT

    indresponse = 1;    %'index Response'

    for iblock = 1: numBlocks
        % block msg
        str = ['block  ', num2str(iblock), '\', num2str(numBlocks)];
        DrawFormattedText(win, str, 'center','center');
        Screen(win,'flip');
        pause(2);

        % stimuli selection
        % 50% congruent - 50% incongruent audio vs words or img
        stimuli = Shuffle(stimuli);
        presStim = stimuli(1:40);
        noPresStim = stimuli(41:end);

        for i = 1:length(presStim)
            subblockStimuli(i).trialString =  presStim(i).string;
            % congruent incongruent condiction choosen randomly
            if mod(randi(2)-1,2)
                % incongruent condiction
                subblockStimuli(i).congruent = 0;
                % random choise - avoid errors
                j = randi(length(presStim));
                while j == i
                    j = randi(length(presStim));
                end
                subblockStimuli(i).string = presStim(j).string;
                subblockStimuli(i).img = presStim(j).img;
            else
                % congruent condiction
                subblockStimuli(i).congruent = 1;
                subblockStimuli(i).string = presStim(i).string;
                subblockStimuli(i).img =  presStim(i).img;
            end
            % introducing noise in stimulus
            noiseLevel = noiseFactors{mod(i,4)+1};
            subblockStimuli(i).nioseLevel = noiseLevel;
            subblockStimuli(i).wav = noiseSample (presStim(i).wav, noiseLevel);
        end

        % shuffling stimoli
        subblockStimuli = Shuffle(subblockStimuli);


        %% Fase 1
        DrawFormattedText(win, 'first part','center', 'center'); 
        Screen('Flip', win);
        pause(1);
        DrawFormattedText(win, 'press "x" if the image is the word that you have heard, "n" instead','center',strYpos); 
        Screen('Flip', win);
        pause(3);            
        for i = 1:numStimuli
            % Presentation fase
            DrawFormattedText(win, 'listen carefully','center', 'center'); 
            Screen('Flip', win);
            pause(1);
            Screen('Flip', win);
            %play audio 
            PsychPortAudio('FillBuffer', pahandle, subblockStimuli(i).wav');
            startTime = PsychPortAudio('Start', pahandle);
            while true
                s = PsychPortAudio('GetStatus', pahandle); % query current playback status
                if ~s.Active
                    break
                end
            end
%             ShowFixationCross (win, pauseIntratrial);
            % retrival fase
            % show img          
            DrawFormattedText(win, 'press "x" if the image is the word that you have heard, "n" instead','center',strYpos); 
            tex = Screen('MakeTexture',win,subblockStimuli(i).img);
            Screen('DrawTexture', win, tex);
            sRT = Screen('Flip', win);
            % defined 'x' and 'n' as True false for the experiment
            [eRT keyCode] = KbWait;

            response(indresponse).exp = 1;
            response(indresponse).congruent = subblockStimuli(i).congruent;
            response(indresponse).noiseLevel = subblockStimuli(i).nioseLevel;
            if KbName(keyCode) == 'x'
                if subblockStimuli(i).congruent
                    % correct answer
                    response(indresponse).correct = 1;
                else
                    % incorrect answer
                    response(indresponse).correct = 0;
                end
            else
                if subblockStimuli(i).congruent
                    % incorrect answer
                    response(indresponse).correct = 0;
                else
                    % correct answer
                    response(indresponse).correct = 1;
                end 
            end
            response(indresponse).RT = eRT - sRT;        
            indresponse = indresponse+1;        
            pause(pauseTrial);
        end
        pause (pauseIntratrial);

        % shuffling stimoli
        subblockStimuli = Shuffle(subblockStimuli);

        
        %% Fase 2
        DrawFormattedText(win, 'second part','center', 'center'); %,'center', 'center');
        Screen('Flip', win);
        pause(1);
        DrawFormattedText(win, 'press "x" if the word is the same word that you heard, "n" instead', 'center', strYpos);
        Screen('Flip', win);
        pause(3);
        for i = 1:numStimuli
            % Presentation fase
            DrawFormattedText(win, 'listen carefully','center', 'center'); %,'center', 'center');
            Screen('Flip', win);
            pause(1);
            Screen('Flip', win);
            %play audio
            PsychPortAudio('FillBuffer', pahandle, subblockStimuli(i).wav');
            startTime = PsychPortAudio('Start', pahandle);
            while true
                s = PsychPortAudio('GetStatus', pahandle); % query current playback status
                if ~s.Active
                    break;
                end
            end
%             ShowFixationCross (win, pauseIntratrial);

            % retrival fase
            % show img       
            DrawFormattedText(win, 'press x if the word is the same word that you heard, any key instead', 'center', strYpos);
            DrawFormattedText(win, subblockStimuli(i).string,'center', 'center');
            sRT = Screen('Flip', win);
            % defined 'x' and 'n' as True false for the experiment
            [eRT keyCode] = KbWait;

            response(indresponse).exp = 2;
            response(indresponse).congruent = subblockStimuli(i).congruent;
            response(indresponse).noiseLevel = subblockStimuli(i).nioseLevel;
            if KbName(keyCode) == 'x'
                if subblockStimuli(i).congruent
                    % correct answer
                    response(indresponse).correct = 1;
                else
                    % incorrect answer
                    response(indresponse).correct = 0;
                end
            else
                if subblockStimuli(i).congruent
                    % incorrect answer
                    response(indresponse).correct = 0;
                else
                    % correct answer
                    response(indresponse).correct = 1;
                end 
            end
            response(indresponse).RT = eRT - sRT;        
            indresponse = indresponse+1;
            pause(pauseTrial);
        end
        pause (pauseIntratrial);


        % shuffling stimoli
        subblockStimuli = Shuffle(subblockStimuli);

        %% Fase 3
        DrawFormattedText(win, 'third part','center', 'center'); 
        Screen('Flip', win);
        pause(1);
        DrawFormattedText(win,'write the word that you have heard : ');
        Screen('Flip', win);
        pause(3);
        % listen 
        % retrieval write
        for i = 1:numStimuli
            % only congruent stimuli
            if ~subblockStimuli(i).congruent
                continue;
            end 
            % Presentation fase
            DrawFormattedText(win, 'listen carefully','center', 'center'); 
            Screen('Flip', win);
            pause(1);
            Screen('Flip', win);
            %play audio
            PsychPortAudio('FillBuffer', pahandle, subblockStimuli(i).wav');
            startTime = PsychPortAudio('Start', pahandle);
            while true
                s = PsychPortAudio('GetStatus', pahandle); % query current playback status
                if ~s.Active
                    break;
                end
            end
%             ShowFixationCross (win, pauseIntratrial);
            
            % retrival fase
            [string RT]= AskForString(win, 'write the word that you have heard : ');

            response(indresponse).exp = 3;
            response(indresponse).congruent = subblockStimuli(i).congruent;
            response(indresponse).noiseLevel = subblockStimuli(i).nioseLevel;
            if strcmp(string, subblockStimuli(i).string)
                % correct answer
                response(indresponse).correct = 1;
            else
                % incorrect answer
                response(indresponse).correct = 0;
            end
            response(indresponse).RT = RT;
            indresponse = indresponse+1;
            pause(pauseTrial);
        end
        pause (pauseIntratrial);
        


        %% Fase 4
        DrawFormattedText(win, 'fourth part','center', 'center'); %,'center', 'center');
        Screen('Flip', win);
        pause(1);
        DrawFormattedText(win, 'select ONLY the images corresponding to the words that you have heard before','center','center');
        pause (3);
        Screen('Flip',win);
            
        % only matching seen img 
        % 20 trials.
        for i = 1:numNoStimuli
            % choose 2 images presented and 7 never presented
            % the goal is to find the 2 images

            % shuffling stimoli
            presStim = Shuffle(presStim);
            noPresStim = Shuffle(noPresStim);

            for j = 1:nimgGrid
                stimuliGrid(j).tex = Screen('MakeTexture', win,presStim(j).img);
                stimuliGrid(j).presented = 1;
            end
            for j = nimgGrid+1:9
                stimuliGrid(j).tex = Screen('MakeTexture', win,noPresStim(j).img);
                stimuliGrid(j).presented = 0;
            end
            stimuliGrid = Shuffle(stimuliGrid);

            for j=1:9
                stimuliGrid(j).coords = RectsGrid(j,:);
            end

            correct = 0;    % correct answers
            attempts = 0;   % number of attempts

            % start experimental phase
             % grid drawing
            ShowFixationCross (win, fixationTime);
             
            for row=1:length(stimuliGrid)
                Screen('DrawTexture',win, stimuliGrid(row).tex, [], [stimuliGrid(row).coords]);
            end
            sRT = Screen(win,'flip');
            while (attempts < 9) & (correct < nimgGrid)
                
                [mouseX, mouseY, buttons]=GetMouse(win);
                if buttons(1)
                    % check if is in the coord of one rect
                    for row=1:length(stimuliGrid)
                        if mouseX >=  stimuliGrid(row).coords(1) &  mouseX <= stimuliGrid(row).coords(3) & ...
                                mouseY >=  stimuliGrid(row).coords(2) &  mouseY <= stimuliGrid(row).coords(4)
                            attempts = attempts + 1;
                            if stimuliGrid(row).presented 
                                correct = correct+1;
                                if correct == nimgGrid
                                    eRT = Screen('Flip',win);
                                    break
                                end
                            end
                            % image deletion
                            stimuliGrid(row) = [];
                            
                            % redrawing the grid
                            Screen(win,'flip');
                            for row=1:length(stimuliGrid)
                                Screen('DrawTexture',win, stimuliGrid(row).tex, [], [stimuliGrid(row).coords]);
                            end
                            Screen(win,'flip');
                            break;
                        end
                    end
                    if correct == nimgGrid
                        break;
                    end
                end
            end
            response(indresponse).exp = 4;
            response(indresponse).noiseLevel = 0; %this is not used in this experiment subblockStimuli(i).nioseLevel;
            response(indresponse).correct = correct/attempts;
            response(indresponse).congruent = 2;
            response(indresponse).RT = eRT - sRT;
            
            indresponse = indresponse+1;       
            pause (pauseIntratrial);
        end
        pause (3);
    end

    DrawFormattedText(win, 'Select file to save', 'center','center');
    Screen(win,'flip');
    pause(2);

    % save data
    while true
        [FileName,PathName] = uiputfile({'*.xlsx','*.xlsx excel file'; '*.csv','*.csv CSV'} ,'Save data',strcat(current_folder,dataname));
        if FileName
            break;
        end
    end
    FileName=fullfile(PathName,sep,FileName);
    try
        data=struct2table (response);
        writetable(data,FileName);

        DrawFormattedText(win, 'data saved', 'center','center');
        Screen(win,'flip');
        pause(2);
    catch
        DrawFormattedText(win, 'save failed due to errors', 'center','center');
        Screen(win,'flip');
        pause(2);
    end

    % close PortAudio
    PsychPortAudio('Close');    
end

DrawFormattedText(win, 'End of the experiment', 'center','center');
Screen(win,'flip');
pause(3);

DrawFormattedText(win, 'in order to avoid error (due to matlab exclusive access)', 'center','center');
Screen(win,'flip');
pause(1);
DrawFormattedText(win, 'it is better close matlab before do analysis', 'center','center');
Screen(win,'flip');
pause(1);
% % close screen
% Screen('CloseAll');
% sca;
% 
% % initialize video
% win=Screen('OpenWindow',0,[255 255 255],[screenW_x screenW_y screenW_h screenW_v]);

ans = AskForString(win, 'Would you like analyzing data? (y: yes, n: no)  :');
if strcmp(ans,'y')
    %% Analyzing data
    DrawFormattedText(win, 'Select multiple files for multiple subject analysis', 'center','center');
    Screen(win,'flip');
    pause(2);
    Screen(win,'flip');
    % open data files (a file for each subject)
    FileName = 'none.file';
    while true
        [FileName,PathName] = uigetfile({'*.xlsx','*.xlsx excel file'; '*.csv','*.csv CSV'},'Open files for analysis' ,dataname,'MultiSelect','on')
        if isa(FileName,'cell') & length(FileName) > 0
            break;
        elseif isa(FileName, 'char') & FileName ~= 0
            break;
        elseif FileName == 0;
            return;
        end
    end
    
    analysData = [];
    if isa(FileName, 'char')
        FileName={FileName};
    end    
    
    % load data and add sbj culomn
    for i = 1:length(FileName)
        data=readtable(strcat(PathName,FileName{i}));
        data = table2struct(data);
        
        % adding subjectName (only last 2 letters because the first are not the subject's name coded!)
        %             sbjName = FileName{i};
        [f,n,e]=fileparts(FileName{i})
        sbjName = n(end-1:end);
        for j = 1:length(data)
            data(j).subject = sbjName;
        end
        analysData = [analysData; data];
    end
     
    % first 2 experiment
    tbl=struct2table(analysData);
   
    for iexp = 1:2
        f = figure;
        indsubplot = 1;  
        for inoiseLevel = 1:length(noiseFactors)   % {0.0 0.05 0.1 0.15}
            for icongr = 0:1
               if icongr
                  strcng = ' congruent' ;
               else
                  strcng = ' incongruent';
               end
               titlegraph=['exp ', num2str(iexp), 'perc. noise ',num2str(noiseFactors{inoiseLevel}), strcng];
                             
               % extract indexes
               indCorr = find([analysData.exp]==iexp & ...
                   [analysData.noiseLevel]==noiseFactors{inoiseLevel} & ...
                   [analysData.congruent]==icongr & [analysData.correct]==1)';
               
               indNoCorr = find([analysData.exp]==iexp & ...
                   [analysData.noiseLevel]==noiseFactors{inoiseLevel} & ...
                   [analysData.congruent]==icongr & [analysData.correct]==0)';
               
               % avoid inf and Nan
               if (length(indCorr) > 0 & length(indNoCorr) > 0)
                    percCorr = length(indCorr)/(length(indCorr)+length(indNoCorr))*100;
               elseif (length(indCorr) > 0)
                   percCorr = 100.0;
               else
                   percCorr = 0.0;
               end
               percIncorr = 100 -percCorr;
%                if (length(indNoCorr) > 0 & length(indNoCorr) > 0)
%                     percIncorr = length(indNoCorr)/(length(indNoCorr)+length(indNoCorr))*100;
%                else
%                    percIncorr = 0.0
%                end
               % data extraction
               corr=tbl(indCorr,:);
               % data selection
               corr=corr(:,5)  % RT correct
               % to array
               corr=table2array(corr);
               if isempty(corr)
                   corr=0;
               end
               meanCorr = mean(corr);
               stdCorr = std(corr);
               
               % data extraction
               incorr=tbl(indNoCorr,:);
               % data selection
               incorr=incorr(:,5);  % RT incorrect
               % to array
               incorr=table2array(incorr);
               if isempty(incorr)
                   incorr=0;
               end
               meanIncorr = mean(incorr);
               stdIncorr = std(incorr);
               
               % plotting data
               
               subplot (2,4,indsubplot);
               
               bar([meanCorr, meanIncorr]);
               hold on;
               %plotting error bar
               plot([1 1],[meanCorr+stdCorr meanCorr-stdCorr]);
               plot([2 2],[meanIncorr+stdIncorr meanIncorr-stdIncorr]);
               % change aspect ration of the bars
               set(gca, 'PlotBoxAspectRatio', [1 2 1]);
               % change backgound color
               set(gcf, 'Color', [1 1 1]);
%                % change font size of the axis
%                set(gca, 'FontSize', 15)
               % throw out the box around the graph
               box off;
               % add y label
               ylabel('Reaction time [ms]');
               % change tck lenghht (2 times of the current length)
               set(gca, 'ticklength', 2*get(gca, 'ticklength'));
               % set tick outside (instead of default setting, inside) the graph
               set(gca, 'Tickdir', 'out');
               % set x tick labels
               percCorrstr =sprintf('correct %2.2f%%',round(percCorr,2));
               percIncorrstr=sprintf('incorrect %2.2f%%', round(percIncorr,2));
               
%                xticklabels({'correct', 'incorrect'});
               xticklabels({percCorrstr, percIncorrstr});
               
               % rotating the xticklabels (45°)
               set(gca, 'XTickLabelRotation', 45);
               % handling gca
               ax = gca;
               % obtain the children list of object handled by gca
               ax.Children
               % modify the bar width (borders around bars)
               set(ax.Children(3), 'LineWidth', 1.5);
               % modify bars color
               set(ax.Children(3), 'FaceColor', [0.5 0.5 0.5]);
               % modify error bar's color
               % modify bars color
               set(ax.Children(1), 'Color', 'k');
               set(ax.Children(1), 'Linewidth', 1.5);
               
               set(ax.Children(2), 'Color', 'k');
               set(ax.Children(2), 'Linewidth', 1.5);
               
               hold on;
               
               plot([0.8 1.2], [meanCorr+stdCorr meanCorr+stdCorr], 'LineWidth', 1.5, 'Color', 'k' );
               plot([0.8 1.2], [meanCorr-stdCorr meanCorr-stdCorr], 'LineWidth', 1.5, 'Color', 'k' );
               
               plot([1.8 2.2], [meanIncorr+stdIncorr meanIncorr+stdIncorr], 'LineWidth', 1.5, 'Color', 'k' );
               plot([1.8 2.2], [meanIncorr-stdIncorr meanIncorr-stdIncorr], 'LineWidth', 1.5, 'Color', 'k' );
                
               title(titlegraph);
               
               indsubplot = indsubplot +1;
           end
        end
        hold off;
    end
    
    
   %% third grph
   
   
   iexp = 3
   f = figure;
   indsubplot = 1;
   for inoiseLevel = 1:length(noiseFactors)   % {0.0 0.05 0.1 0.15}
       
       titlegraph=['exp ', num2str(iexp), 'perc. noise ',num2str(noiseFactors{inoiseLevel})];
       
       % extract indexes
       indCorr = find([analysData.exp]==iexp & ...
           [analysData.noiseLevel]==noiseFactors{inoiseLevel} & ...
           [analysData.congruent]==1 & [analysData.correct]==1)';
       
       indNoCorr = find([analysData.exp]==iexp & ...
           [analysData.noiseLevel]==noiseFactors{inoiseLevel} & ...
           [analysData.congruent]==1 & [analysData.correct]==0)';
       
       % avoid inf and Nan
       if (length(indCorr) > 0 & length(indNoCorr) > 0)
           percCorr = length(indCorr)/(length(indCorr)+length(indNoCorr))*100;
       elseif (length(indCorr) > 0)
           percCorr = 100.0;
       else
           percCorr = 0.0;
       end
       percIncorr = 100 -percCorr;
       % data extraction
       corr=tbl(indCorr,:);
       % data selection
       corr=corr(:,5)  % RT correct
       % to array
       corr=table2array(corr);
       if isempty(corr)
           corr=0;
       end
       meanCorr = mean(corr);
       stdCorr = std(corr);
       
       % data extraction
       incorr=tbl(indNoCorr,:);
       % data selection
       incorr=incorr(:,5);  % RT incorrect
       % to array
       incorr=table2array(incorr);
       if isempty(incorr)
           incorr=0;
       end
       meanIncorr = mean(incorr);
       stdIncorr = std(incorr);
       
       % plotting data
       
       subplot (2,2,indsubplot);
       
       bar([meanCorr, meanIncorr]);
       hold on;
       %plotting error bar
       plot([1 1],[meanCorr+stdCorr meanCorr-stdCorr]);
       plot([2 2],[meanIncorr+stdIncorr meanIncorr-stdIncorr]);
       % change aspect ration of the bars
       set(gca, 'PlotBoxAspectRatio', [1 2 1]);
       % change backgound color
       set(gcf, 'Color', [1 1 1]);
       %                % change font size of the axis
       %                set(gca, 'FontSize', 15)
       % throw out the box around the graph
       box off;
       % add y label
       ylabel('Reaction time [ms]');
       % change tck lenghht (2 times of the current length)
       set(gca, 'ticklength', 2*get(gca, 'ticklength'));
       % set tick outside (instead of default setting, inside) the graph
       set(gca, 'Tickdir', 'out');
       % set x tick labels
       percCorrstr =sprintf('correct %2.2f%%',round(percCorr,2));
       percIncorrstr=sprintf('incorrect %2.2f%%', round(percIncorr,2));
       
       %                xticklabels({'correct', 'incorrect'});
       xticklabels({percCorrstr, percIncorrstr});
       
       % rotating the xticklabels (45°)
       set(gca, 'XTickLabelRotation', 45);
       % handling gca
       ax = gca;
       % obtain the children list of object handled by gca
       ax.Children
       % modify the bar width (borders around bars)
       set(ax.Children(3), 'LineWidth', 1.5);
       % modify bars color
       set(ax.Children(3), 'FaceColor', [0.5 0.5 0.5]);
       % modify error bar's color
       % modify bars color
       set(ax.Children(1), 'Color', 'k');
       set(ax.Children(1), 'Linewidth', 1.5);
       
       set(ax.Children(2), 'Color', 'k');
       set(ax.Children(2), 'Linewidth', 1.5);
       
       hold on
       
       plot([0.8 1.2], [meanCorr+stdCorr meanCorr+stdCorr], 'LineWidth', 1.5, 'Color', 'k' );
       plot([0.8 1.2], [meanCorr-stdCorr meanCorr-stdCorr], 'LineWidth', 1.5, 'Color', 'k' );
       
       plot([1.8 2.2], [meanIncorr+stdIncorr meanIncorr+stdIncorr], 'LineWidth', 1.5, 'Color', 'k' );
       plot([1.8 2.2], [meanIncorr-stdIncorr meanIncorr-stdIncorr], 'LineWidth', 1.5, 'Color', 'k' );
       
       title(titlegraph);
       
       indsubplot = indsubplot +1;
   end
   hold off;
   
   %% fourth graph
   inds = find([analysData.exp]==4)';
   % data extraction
   inds=tbl(inds,:);
   % data selection
   RTs=inds(:,5);  % RT 
   % to array
   RTs=table2array(RTs);
   
   meanRTs = mean(RTs);
   stdRTs = std(RTs);
      % data selection
   accs=inds(:,4);  % accuracy 
   % to array
   accs=table2array(accs);
   accs= accs*100;
   meanaccs = mean(accs);
   stdaccs = std(accs);
   
   scatter(accs,RTs)
   ylabel('Reaction time [ms]');  
   xlabel('accuracy');   
   title('Experiment 4');
    
   
end

DrawFormattedText(win, 'Thanks', 'center','center');
Screen(win,'flip');
pause(3);

% close screen
Screen('CloseAll');
sca

%% END EXPERIMENT SCRIPT

%% SCRIPT FUNCTIONS

function stimuli = LoadData (current_folder, dimimg)
    sep = PathSep();

    current_folder_audio = [current_folder sep 'sounds' sep ];
    current_folder_image = [current_folder sep 'images' sep ];

    fileslistSounds = dir (current_folder_audio);
    fileslistSounds = {fileslistSounds.name};
    fileslistSounds = setdiff(fileslistSounds,'.');
    fileslistSounds = setdiff(fileslistSounds,'..');

    fileslistImgs = dir (current_folder_image);
    fileslistImgs = {fileslistImgs.name};
    fileslistImgs = setdiff(fileslistImgs,'.');
    fileslistImgs = setdiff(fileslistImgs,'..');
    fileslistImgs = fileslistImgs';
    stimulus='';

    fpointer = fopen ( 'elenco_stimoli' , 'r');
    for i=1:100
        dato = fscanf ( fpointer , '%s\n',1 );
        if isempty(dato); break; end
        stimulus(i).string = dato;
        img = imread(strcat(current_folder_image, fileslistImgs{i}));
        img = imresize(img,[dimimg dimimg], 'Antialiasing', false);
        stimulus(i).img=img;
        [y,fs] = psychwavread(strcat(current_folder_audio, fileslistSounds{i}));
        stimulus(i).wav = y;
    end
    fclose (fpointer);
    clear fileslistSounds fileslistImgs
    stimuli = stimulus;
end

%% 
function [str RT]= AskForString(win, stringToPresent)
    sRT = Screen(win,'flip');
    [string] = GetEchoString(win, stringToPresent, 50, 50);%, [100 100 100], [250 250 250]);
    eRT = Screen(win,'flip');
    str = string;
    RT = eRT - sRT;
end 

%%
function RealTime = ShowFixationCross (win, fixationTime)
    % fixation frame
    DrawFormattedText(win, 'look at the fixation point','center', 'center');
    Screen(win,'flip');
    WaitSecs(.5);
    % fixation point
     DrawFormattedText(win, '+', 'center', 'center');
    startTime = Screen(win,'flip');
    while GetSecs < startTime + fixationTime; end
    removeTime = Screen(win,'flip');
    RealTime = removeTime; %startTime - removeTime;
end    

 %% NOIZE GENERATOR
function Y = noiseSample (Ydata, noizeFactor)
    noise=rand(size(Ydata));
    % random noise indexes
    indexes=randperm(length(Ydata),round(noizeFactor*length(Ydata)));
    % getting noise into sample
    length(indexes)
    for i=1:length(indexes)
        Ydata(indexes(i)) = noise(i);
    end
    Y = Ydata;
end

function sep = PathSep (void)
    if ispc()
        sep = '\';
    elseif ismac() || IsLinux() 
        sep ='/';
    end
end