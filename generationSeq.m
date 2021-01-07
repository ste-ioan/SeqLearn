function [RecallTable] = generationSeq

RecallTable = cell(30,2);
RecallTable(1:15,2) = {'Control'};
RecallTable(16:30,2) = {'Awareness'};

% locate folders
FilesHub = '~/Documents/SeQ Learn Backup/SeqLearn/data';
cd(FilesHub);

groupfolders = dir;
groupfolders = groupfolders (3:4);

for fldindx = 1:2

cd([FilesHub,'/', groupfolders(fldindx).name])
if fldindx == 1
    adder = 0;
else
    adder = 15;
end
for subj = 1:15
cd(num2str(subj))
cd('Session2')

rememberedTrial = nan(3,1);
for b=1:3
fid=fopen(['Groupe',num2str(fldindx),'Session2_Sujet',num2str(subj),'_B',num2str(b),'_FB.txt']);
FB = fscanf(fid,'%f');
fclose(fid);
rememberedTrial(b) = sum(FB);

if rememberedTrial(b) == 12
    disp(['subject', num2str(subj),'of group', num2str(fldindx), 'recalled all elements in trial', num2str(b)])
end
end

RecallTable{subj+adder, 1} = mean(rememberedTrial);
cd ..
cd ..
end
end

cd('~/Documents/SeQ Learn Backup/SeqLearn/results/')
RecallTable = cell2table(RecallTable);
RecallTable.Properties.VariableNames = {'AvgRecall', 'Groupe'};
writetable(RecallTable)
