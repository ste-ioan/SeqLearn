%%Script for the analysis of pupil data from SeQ_Learn%%
% clear
% clc

%this guy makes you select file folder and cd's to there
FilesHub = '~/Documents/SeQ Learn Backup/SeqLearn/data';
cd(FilesHub);
%find eyefile and extract data
folders = dir;

for fldindx = 1:2
    
    for subj = 1:15
        cd([FilesHub,'/', num2str(fldindx)])
    
        cd(num2str(subj))
        cd('Session1')
        
        EyeFile = dir('eyeData*');
        
        if EyeFile(1).name(end) == 'f'
            filename = EyeFile(1).name(1:end-4);
        else
            lastletter= EyeFile(1).name(end-5);
            
            switch lastletter
                case 't'
                    filename=EyeFile(1).name(1:end-11);
                case 'e'
                    filename=EyeFile(1).name(1:end-12);
                otherwise
                    warning('there is some issue with the filename extraction');
            end
        end
        
        t=find(EyeFile(1).name=='t');
        undrscrs=find(EyeFile(1).name=='_');
        point=find(EyeFile(1).name=='.');
        if length(undrscrs)<=2
            sn=EyeFile(1).name(t(2)+1:point-1);
        else
            sn=EyeFile(1).name(t(2)+1:undrscrs(3)-1);
        end
        e=find(EyeFile(1).name=='e');
        g=EyeFile(1).name(e(3)+1);
        
        %get the data thx to read_eyelink
        [trialData,blockData]=read_eyelink(filename);
        
        %reorganize data so that it can be filtered & downsampled
        data.pupilData.block = blockData;
        data.pupilData.trials = trialData;

        % clean data
        data.pupilData = processBlinks(data.pupilData,1000);%set fourth arg to true to see blink removal
        data = downsampleEyedata(data, 10, 1000);
        data = filterPupil(data, .05, 10);
        alldata(fldindx).subj(subj) = data;

        tr = length(data.pupilData.trials);
        y = data.pupilData.block.filteredPupilSize;
        ynf = data.pupilData.block.pupilSize;
        t = data.pupilData.block.time;
        e = y*0;
        ee = e;
        for b=1:tr
            fid=fopen(['Groupe',g,'Session1_Sujet',sn,'_B',num2str(b),'_RT.txt']);
            try
                RT=fscanf(fid,'%f');
                RTs(:,b,subj,fldindx) = RT;
                RT=RT(end);
                fclose(fid);
            catch
                RT = 0;
            end
           
            e1 = data.pupilData.trials(b).events(2).time;
            e2 = data.pupilData.trials(b).events(13).time+(RT*1000)+2000;%adds RT and 2 seconds for pupil to set back to baseline
            e3 = [data.pupilData.trials(b).events(2:13).time];
            [~,f] = min(abs(t-e1));
            e(f) = 1;
            [~,f] = min(abs(t-e2));
            e(f) = 2;
            for k = 1:length(e3)
            [~,f] = min(abs(t-e3(k)));
            ee(f) = b;  
            end
        end
        
        A(:,:,subj,fldindx) = event_align(y(:),e(:),1,1:100,2);
        Anf(:,:,subj,fldindx) = event_align(ynf(:),e(:),1,1:100,2);
        
        ok = ~isnan(y);
        y = y(:);
        ynf = ynf(:);
        e = e(:);
        e2 = e*0;
        f = find(e==1);
        f2 = find(e==2);
        for ii = 1:length(f)
            e2(f(ii):f2(ii)) = 1;
        end
        e2 = e2(:);
        bl = data.pupilData.block.blinks;
        bl = bl(:);
        bloff = [0; diff(bl)==-1];
        ee = ee(:);
        
        % change this for n of trials in model
        U = [double((ee(ok)>0) & (ee(ok)<4)), double((ee(ok)>3) & (ee(ok)<49)), double((ee(ok)>48) & (ee(ok)<52)), double((ee(ok)>51) & (ee(ok)<97)), double(ee(ok)>96)];

        
        opt = ssestOptions('Focus','simulation');
        opt.Regularization.Lambda = 1; % you can increase here to limit outliers

% here we look for best resolution (inputdelay) for the model, based on fit (evaluation)       
l = 0;
for a = .001:.01:.9
l = l+1;
mockmodel(subj,fldindx).m = ssest(iddata(ynf(ok)-nanmean(ynf),U,1/10),2,'InputDelay',repmat(a,1,5),opt);

for chunk = 1:5
evaluation(l,chunk) = mockmodel(subj,fldindx).m(1,chunk).Report.Fit.FitPercent;
end
end

% if fldindx == 1
% fitStorage(subj) = (max(evaluation(:,1)));
% else
% fitStorage(subj+15) = (max(evaluation(:,1)));
% end

[~,x] = max(evaluation(:,1));
a = .001:.01:.9;
     
        model(subj,fldindx).m = ssest(iddata(ynf(ok)-nanmean(ynf),U,1/10),2,'InputDelay',repmat(a(x),1,5),opt);
        clear U evaluation mockmodel
     end
end

II = nan(100000,5,15,2);
for ii = 1:15
for jj = 1:2
I=impulse(model(ii,jj).m);
MM(:,ii,jj) = squeeze(max(I));% max of impulse responses: 5 values per subject corresponding to B1 A1 B2 A2 B3
II(1:size(I,1),:,ii,jj) = squeeze(I);% all impulse responses
end
end
% % plots average impulse responses for B1 A1 B2 A2 B3
% figure;
% t = {'B1','A1','A2','A3','A4','A5','A6','A7','A8','A9',...
%     'A10', 'A11', 'A12', 'A13', 'A14', 'A15', 'B2', 'A16', 'A17', 'A18', 'A19', 'A20', ...
%     'A21', 'A22', 'A23', 'A24', 'A25', 'A26', 'A27', 'A28', 'A29', 'A30','B3'};
% for ii = 1:5
%     subplot(1,5,ii);
%     plot(squeeze(nanmean(II(1:100,ii,:,:),3)))
%     legend('group 1','group 2')
%     title(t{ii});
% end

% make table for Jamovi
JamoviPupiltab = [];
for jj = 1:2
for ii = 1:15
temp = [repmat(ii, 5, 1), MM(:,ii,jj)];   
JamoviPupiltab = [JamoviPupiltab;temp];
end
end

JamoviPupiltab = array2table(JamoviPupiltab, 'VariableNames', {'subnum', 'Pupil'});
% i'll add group and sequence on jamovi
writetable(JamoviPupiltab)