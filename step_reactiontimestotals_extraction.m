function [RT_TOTALS, RemovedPercentageofSteps] = step_reactiontimestotals_extraction
% there is a discrepancy between my Rt_totals matrix and the Rts i get
% looking through eyefiles, also i had done it trial wise while i've been
% asked to do it stepwise, so here i am
if ismac
cd( '~/Documents/SeQ Learn Backup/SeqLearn/results/Pupil')
else
cd( 'C:\Users\MococoEEG\Documents\SeQ Learn Backup\SeqLearn\results\Pupil') 
end
load('allpupildata.mat')

RT_TOTALS = nan(12,99,2);
removedSteps = 0;
% locate folders
if ismac
FilesHub = '~/Documents/SeQ Learn Backup/SeqLearn/data';
else
% FilesHub = 'C:\Users\MococoEEG\ownCloud\MATLAB\Data\SeqLearn\';
FilesHub =  'C:\Users\MococoEEG\Documents\SeQ Learn Backup\SeqLearn\data';    

end
cd(FilesHub);
folders = dir;

folders = folders (4:5);    

for fldindx = 1:2
    cd([FilesHub,'/', folders(fldindx).name])
    
    for subj = 1:15
        cd(num2str(subj))
        cd('Session1')
        
        % open txt files, get RTs, remove outliers
        for b=1:99
            
            try
                fid=fopen(['Groupe',num2str(fldindx),'Session1_Sujet',num2str(subj),'_B',num2str(b),'_RT.txt']);
                
                RT = fscanf(fid,'%f');
                fclose(fid);
                
                fid=fopen(['Groupe',num2str(fldindx),'Session1_Sujet',num2str(subj),'_B',num2str(b),'_FB.txt']);
                FB = fscanf(fid,'%f');
                fclose(fid);
                
            catch
                % in case an RT is file is missing (lookin at you trial 13 of subj 9
                % group 1), extract it from eyelink file. you'll need the
                % variable 'alldata' from PupilAnalysis2 to do this
                RT = diff([[alldata(fldindx).subj(subj).pupilData.trials(b).events.time],...
                    alldata(fldindx).subj(subj).pupilData.trials(b).stopTime]);
                RT(1) = [];
            end
            if sum(FB) < 6
                disp([num2str(subj),' group',num2str(fldindx), ' trial ', num2str(b), ' has less than half correct'])
            end
            RT = RT(logical(FB)); % remove wrong answers
            removedSteps = removedSteps + abs((length(RT) - 12));
            
            upperbound = round(mean(RT) + 2*(std(RT)),2);
            lowerbound = round(mean(RT) - 2*(std(RT)),2);
            
            lowOutlier = find(RT <= lowerbound);
            if ~isempty(lowOutlier)
                RT(lowOutlier) = [];
                removedSteps = removedSteps+1;
            end
            
            bigOutlier = find(RT >= upperbound);
            if ~isempty(bigOutlier)
                RT(bigOutlier) = [];
                removedSteps = removedSteps+1;
            end                    

            Errors_Totals(subj,b,fldindx) = sum(FB==0);
            RT_TOTALS(subj,b,fldindx) = mean(RT);
        end
        cd ..
        cd ..
    end
end

% divide removedSteps by totalSteps(12 steps, 99 trials, 30 subjects)
% to calculate the percentage of steps removed from total.
totalRemoved = removedSteps/(12*99*30);
RemovedPercentageofSteps = totalRemoved*100;

% if you want to test error rates between subjects
g1 = sum(Errors_Totals(:,:,1));
g2 = sum(Errors_Totals(:,:,2));
errdiff = ranksum(g1,g2);
return
