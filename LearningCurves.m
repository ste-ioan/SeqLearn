[RT_TOTALS, ~] = step_reactiontimestotals_extraction;
RT_TOTALS = RT_TOTALS * 1000;

% Set up fittype and options.
functions = {'power1', 'exp1'};
idx = listdlg('ListString', functions);
law = functions{idx};

ft = fittype(law);
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
x1 = [1:45]';
x2 = [1:45]';

for group = 1:2
    for n = 1:15        
        if group == 2
            y =  RT_TOTALS(n,4:48,group)';
            [fitresult, gof(n+15,1)] = fit( x1, y, ft, opts);
            Intercepts(n+15,1) = fitresult.a;
            Slopes(n+15,1) = fitresult.b;
            
            y =  RT_TOTALS(n,52:96,group)';
            [fitresult, gof(n+15,2)] = fit( x2, y, ft, opts);
            Intercepts(n+15,2) = fitresult.a;
            Slopes(n+15,2) = fitresult.b;

        else
            y =  RT_TOTALS(n,4:48,group)';
            [fitresult, gof(n,1)] = fit( x1, y, ft, opts);
            Intercepts(n,1) = fitresult.a;
            Slopes(n,1) = fitresult.b;
 
         if n == 10 % this subj replied to less than half steps in these trials
        x3 =  [1:43]';
        x3(end-1) = [];
        y = RT_TOTALS(n,52:96,group)';
        y = y(1:end-2);
        y(end-1) = [];
            [fitresult, gof(n,2)] = fit( x3, y, ft, opts);
            Intercepts(n,2) = fitresult.a;
            Slopes(n,2) = fitresult.b;
         else     
            
            y =  RT_TOTALS(n,52:96,group)';
            [fitresult, gof(n,2)] = fit( x2, y, ft, opts);
            Intercepts(n,2) = fitresult.a;
            Slopes(n,2) = fitresult.b;
         end
        end
    end
end

% %Ranova table for sequence A
% RanovaPowerTable = array2table(Slopes, 'VariableNames', {'acqui1', 'acqui2'});
% RanovaPowerTable(:,end+1) = cell2table([repmat({'Cntrl'},15,1); repmat({'Aware'},15,1)]);
% writetable(RanovaPowerTable)
% 
% % % sequence B
% Btable = array2table([mean([RT_TOTALS(:,1:3,1);RT_TOTALS(:,1:3,2)],2),...
%     mean([RT_TOTALS(:,49:51,1);RT_TOTALS(:,49:51,2)],2), mean([RT_TOTALS(:,97:99,1);RT_TOTALS(:,97:99,2)],2)]); 
% 
% Btable(1:15,end+1) = cell2table({'Cntrl'}); 
% Btable(16:end,end) = cell2table({'Aware'});
% Btable.Properties.VariableNames = {'B1', 'B2', 'B3', 'Group'};
% writetable(Btable)

% average goodness of fit
mean([gof.rsquare])