function [eyelinkTrial, eyelinkBlock] = read_eyelink(FILENAME, varargin)

% This function takes as input the name of an eyelink file and outputs the
% data trial by trial in eyelinkTrial, and as single continuous vectors in
% eyelinkBlock.
%
% If coded eyelink events are available, they should be provided as a
% structure in second argument. The structure should have a "key" field,
% containing the event names, and a "value" field, containing the corresponding event
% codes.
%
% It is based on the COSYgraphics toolbox and assumes that the same toolbox was used to run the experiment.
%
% A. Z?non, Decembre 9, 2016

if length(varargin)==0
elseif length(varargin)==1
    eventList=varargin{1};
    if isstruct(eventList)
        if isfield(eventList,'key') && isfield(eventList,'value')
            for ii = 1:length(eventList)
                eval([eventList(ii).key '=' num2str(eventList(ii).value) ';']);
            end
        end
    else
        error('Second argument should be a structure containing the events key-value pairs');
    end
else
    error('Incorrect number of arguments');
end

PRE_START_RECORD = 0;
BLINK_MARGIN = 0;% determines by how much blink time is appended before and after each Eyelink-detected blink.

if strcmp(FILENAME(end-3:end),'.mat') && exist([FILENAME(1:end-4) '_events.asc']) && exist([FILENAME(1:end-4) '_samples.asc'])
    FILENAME = FILENAME(1:end-4);% removes the .mat at the end of filename
end

if ~exist([FILENAME '_events.asc']) || ~exist([FILENAME '_samples.asc'])
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkTrial.saccades = NaN;
    eyelinkTrial.eyeTime = NaN;
    eyelinkBlock = NaN;
    disp('Non existent Eyelink file');
    return
end
try
    [eyelinkEvents, header] = getEyelinkAscEvents([FILENAME '_events.asc']);
catch
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkTrial.saccades = NaN;
    eyelinkTrial.eyeTime = NaN;
    eyelinkBlock = NaN;
    disp('Impossible to run getEyelinkAscEvents');
    return
end
disp(' Reading eyelink file');
fid = fopen([FILENAME '_samples.asc']);
content = fscanf(fid,'%c');
fclose(fid);
content = strrep(content,char([9 46 46 46 10]),char(10));
content = strrep(content,char([32 32 32 46]),'');
firstline = content(1:findstr(content,char(10)));
columns = findstr(firstline,char(9));
numColumns = length(columns)+1;
N = strread(content,'','delimiter',char(9),'emptyvalue',NaN);

%[N,T] = stdtextread([FILENAME '_samples.asc'], 25, 0, '', '-skip','E', '-skip','S', '-skip','MSG', '-nan','   .');
%[N,T] = stdtextread([FILENAME(1:end-4) '_samples.asc'], 25, 0, '%n%n%n%n%s%n%n%s', '-skip','E', '-skip','S', '-skip','MSG', '-nan','   .');
%[N,T] = stdtextread([FILENAME(1:end-4) '_samples.asc'], 25, 0, '%n%n%n%n%n%s', '-skip','E', '-skip','S', '-skip','MSG', '-nan','   .');

disp(' Extracting start/stop trials and event codes');
eyelinkMSG = eyelinkEvents(4).evLine;
startTrialIndex=0;
for ii = 1:length(eyelinkMSG)
    msg = eyelinkMSG{ii};
    firstTab = find(double(msg)==9,1);
    spaces = find(double(msg)==32);
    timeStamp = str2num(msg(firstTab+1:spaces(1)-1));
    col = findstr(msg,':');
    if ~isempty(col) && length(spaces)>=2
        endOfType = min(spaces(2),col(1));
    elseif length(spaces)>=2
        endOfType = spaces(2);
    elseif ~isempty(col)
        endOfType = col(1);
    end
    type = msg(spaces(1)+1:endOfType-1);
    switch type
        case 'SUBJECT'
            Subject = msg(col+1:end);
        case 'STARTTRIAL'
            pawn = findstr(msg,'#');
            %startTrialIndex = str2num(msg(pawn+1:col-1));
            startTrialIndex = startTrialIndex+1;
            eyelinkTrial(startTrialIndex).approximateStartTime = timeStamp;
        case 'SYNC'
            syncTime = msg(col+1:end-1);
            eyelinkTrial(startTrialIndex).syncTime = syncTime;
        case 'TRIALSYNCTIME'
            if startTrialIndex>0
                eyelinkTrial(startTrialIndex).startTime = timeStamp;
            else
                startTrialIndex = 1;
                eyelinkTrial(startTrialIndex).startTime = timeStamp;
                warning('TRIALSYNCTIME happens bebore first trial onset');
            end
        case 'USEREVENT'
            quotes = union(strfind(msg,'"'),strfind(msg,char(39)));
            if isempty(quotes)
                warning('No quotes, taking string after last space')
                quotes = [spaces(2) length(msg)+1];
            end
            eventName = msg(quotes(1)+1:quotes(2)-1);
            if length(quotes)>=4
                eventType = msg(quotes(3)+1:quotes(4)-1);
                event = [eventName '_' eventType];
            else
                eventType = '';
                event = eventName;
            end
            
            if exist('startTrialIndex') && exist('eyelinkTrial')
                if ~isfield(eyelinkTrial,'events') || isempty(eyelinkTrial(startTrialIndex).events)
                    eyelinkTrial(startTrialIndex).events(1).time = timeStamp;%-st+PRE_START_RECORD+1;
                    eyelinkTrial(startTrialIndex).events(1).name = event;
                else
                    n = length(eyelinkTrial(startTrialIndex).events);
                    eyelinkTrial(startTrialIndex).events(n+1).time = timeStamp;%-st+PRE_START_RECORD+1;
                    eyelinkTrial(startTrialIndex).events(n+1).name = event;
                end
            end
            
            
            
        case 'STOPTTRIAL'
            pawn = findstr(msg,'#');
            stopTrialIndex = str2num(msg(pawn+1:col-1));
            stopTrialIndex = startTrialIndex;
%             if stopTrialIndex~=startTrialIndex
%                 warning('Inconsistencies in trial indices in eyelink .asc file');
%             end
            eyelinkTrial(startTrialIndex).stopTime = timeStamp;
        case 'STOPTRIAL'
            pawn = findstr(msg,'#');
            stopTrialIndex = str2num(msg(pawn+1:col-1));
            stopTrialIndex = startTrialIndex;
%             if stopTrialIndex~=startTrialIndex
%                 warning('Inconsistencies in trial indices in eyelink .asc file');
%             end
            eyelinkTrial(startTrialIndex).stopTime = timeStamp;
        case 'TASK'
            Task = msg(col+1:end-1);
    end
end
if ~exist('eyelinkTrial')
    eyelinkTrial.startTime = NaN;
    eyelinkTrial.stopTime = NaN;
    eyelinkTrial.syncTime = NaN;
    eyelinkTrial.events = NaN;
    eyelinkTrial.blinks = NaN;
    eyelinkTrial.saccades = NaN;
    eyelinkTrial.eyeTime = NaN;
    disp('No start/stop message.');
else
    if ~isfield(eyelinkTrial,'startTime')
        for ii = 1:length(eyelinkTrial)
            eyelinkTrial(ii).startTime=eyelinkTrial(ii).approximateStartTime;
        end
        rmfield(eyelinkTrial,'approximateStartTime');
    else
        rmfield(eyelinkTrial,'approximateStartTime');
    end
end

%%%%%% eye position data %%%%%%
allPupilVector = N(:,4);
allEyeXVector = N(:,2);
allEyeYVector = N(:,3);
allEyeTimeVector = N(:,1);
z=diff(N(1:10,1));
if z(1)==~z(2) && ~z(2)==z(3) && z(3)==~z(4) && ~z(4)==z(5) 
    if all(unique(diff(N(:,1)))==[0; 1])
        warning('Sampling rate is probably 2000 Hz -> downsampling to 1000 Hz');
        allEyeTimeVector=(N(1:end-1,1)+N(2:end,1))/2;
        allEyeTimeVector(end+1) = allEyeTimeVector(end)+0.5;
        allEyeTimeVector = downsampleVector(allEyeTimeVector,2000,1000);
        allPupilVector = downsampleVector(allPupilVector,2000,1000);
        allEyeXVector = downsampleVector(allEyeXVector,2000,1000);
        allEyeYVector = downsampleVector(allEyeYVector,2000,1000);
    end
end

disp(' Processing saccades');
allSaccVector = allPupilVector*0;
if length(eyelinkEvents)>=6
    eyelinkSSACC = eyelinkEvents(6).evLine;
    eyelinkESACC = eyelinkEvents(2).evLine;
    for ii = 1:length(eyelinkSSACC)
        msg = eyelinkESACC{ii};
        tabs = find(double(msg)==9);
        spaces = find(double(msg)==32);
        begTimeStamp = str2num(msg(spaces(2)+1:tabs(1)-1));
        endTimeStamp = str2num(msg(tabs(1)+1:tabs(2)-1));
        [z,begInd]=min(abs(allEyeTimeVector-begTimeStamp));
        [z,endInd]=min(abs(allEyeTimeVector-endTimeStamp));
        vectorIndices = [begInd:endInd];
        allSaccVector(vectorIndices) = 1;
        
        if exist('eyelinkTrial') && isfield(eyelinkTrial,'startTime') && isfield(eyelinkTrial,'stopTime')
%             strT = [eyelinkTrial.startTime];
%             stpT = [eyelinkTrial.stopTime];
%             if length(strT)<length(stpT)
%                 strT = [eyelinkTrial(1).approstrT];
            if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
                trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
            elseif ~isempty(begTimeStamp)
                trialIndex = find(([eyelinkTrial.startTime]<begTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
            elseif ~isempty(endTimeStamp)
                trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>endTimeStamp));
            end
            if ~isempty(trialIndex) && length(trialIndex)<2
                if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
                    saccTime = [begTimeStamp:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
                elseif ~isempty(begTimeStamp)
                    saccTime = [begTimeStamp:eyelinkTrial(trialIndex).stopTime]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
                elseif ~isempty(endTimeStamp)
                    saccTime = [eyelinkTrial(trialIndex).startTime:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
                end
                saccTime(saccTime<=0) = [];
                eyelinkTrial(trialIndex).saccades(saccTime) = 1;
            end
        end
    end
end
if exist('eyelinkTrial') && ~isfield(eyelinkTrial,'saccades')
    for ii = 1:length(eyelinkTrial)
        eyelinkTrial(ii).saccades =NaN;
    end
end

disp(' Processing blink data');
eyelinkEBLINK = eyelinkEvents(1).evLine;
allBlinkVector = allPupilVector*0;
for ii = 1:length(eyelinkEBLINK)
    msg = eyelinkEBLINK{ii};
    tabs = find(double(msg)==9);
    spaces = find(double(msg)==32);
    begTimeStamp = str2num(msg(spaces(2)+1:tabs(1)-1))-BLINK_MARGIN;
    endTimeStamp = str2num(msg(tabs(1)+1:tabs(2)-1))+BLINK_MARGIN;
    [z,begInd]=min(abs(allEyeTimeVector-begTimeStamp));
    [z,endInd]=min(abs(allEyeTimeVector-endTimeStamp));
    vectorIndices = [begInd:endInd];
    
    allBlinkVector(vectorIndices) = 1;
    if exist('eyelinkTrial') && isfield(eyelinkTrial,'startTime') && isfield(eyelinkTrial,'stopTime')
        if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
        elseif ~isempty(begTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<begTimeStamp)&([eyelinkTrial.stopTime]>begTimeStamp));
        elseif ~isempty(endTimeStamp)
            trialIndex = find(([eyelinkTrial.startTime]<endTimeStamp)&([eyelinkTrial.stopTime]>endTimeStamp));
        end
        if ~isempty(trialIndex) && length(trialIndex)<2
            if ~isempty(begTimeStamp) & ~isempty(endTimeStamp)
                blinkTime = [begTimeStamp:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            elseif ~isempty(begTimeStamp)
                blinkTime = [begTimeStamp:eyelinkTrial(trialIndex).stopTime]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            elseif ~isempty(endTimeStamp)
                blinkTime = [eyelinkTrial(trialIndex).startTime:endTimeStamp]-eyelinkTrial(trialIndex).startTime+PRE_START_RECORD+1;
            end
            blinkTime(blinkTime<=0) = [];
            eyelinkTrial(trialIndex).blinks(blinkTime) = 1;
        end
    end
end
if exist('eyelinkTrial') && ~isfield(eyelinkTrial,'blinks')
    for ii = 1:length(eyelinkTrial)
        eyelinkTrial(ii).blinks =NaN;
    end
end

allBlinkVector=logical(allBlinkVector);
allSaccVector=logical(allSaccVector);
allPupilVector=allPupilVector/2000;
eyelinkBlock.pupilSize=allPupilVector;
eyelinkBlock.blinks=allBlinkVector;
eyelinkBlock.saccades=allSaccVector;
eyelinkBlock.eyeX=allEyeXVector;
eyelinkBlock.eyeY=allEyeYVector;
eyelinkBlock.time=allEyeTimeVector;

disp(' Reformating in trials');
if exist('eyelinkTrial') && isfield(eyelinkTrial,'startTime')
    for ii = 1:length(eyelinkTrial)
        start = eyelinkTrial(ii).startTime;
        if ii <length(eyelinkTrial)
            stop = eyelinkTrial(ii+1).startTime;
        else
            stop = allEyeTimeVector(end)+1;
        end
        
        if ~isempty(stop)
            ix = find((allEyeTimeVector>=start) & (allEyeTimeVector<stop));
            eyelinkTrial(ii).eyeX = allEyeXVector(ix);
            eyelinkTrial(ii).eyeY = allEyeYVector(ix);
            eyelinkTrial(ii).pupilSize = allPupilVector(ix);
            eyelinkTrial(ii).eyeTime = allEyeTimeVector(ix);
        else
            eyelinkTrial(ii) = [];
        end
    end
else
    eyelinkTrial=NaN;
end