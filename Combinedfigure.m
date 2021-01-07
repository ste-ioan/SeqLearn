%% figure for seq learn
[RT_TOTALS, ~] = step_reactiontimestotals_extraction;
Millisec = RT_TOTALS*1000;

functions = {'power1', 'exp1'};
idx = listdlg('ListString', functions);
law = functions{idx};
% average learning curve
ft = fittype(law);
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
x = [1:45]';

            y =  mean(Millisec(:,4:48,1))';
            [fitresultg1a1] = fit( x, y, ft, opts);

            y =  mean(Millisec(:,52:96,1))';
            [fitresultg1a2] = fit( x, y, ft, opts);

            
            y =  mean(Millisec(:,4:48,2))';
            [fitresultg2a1] = fit( x, y, ft, opts);

            
            y =  mean(Millisec(:,52:96,2))';
            [fitresultg2a2] = fit( x, y, ft, opts);

x = x';   

coefs1 = coeffvalues(fitresultg1a1);
coefs2 = coeffvalues(fitresultg1a2);
coefs3 = coeffvalues(fitresultg2a1);
coefs4 = coeffvalues(fitresultg2a2);

ci1 = confint(fitresultg1a1);
ci2 = confint(fitresultg1a2);
ci3 = confint(fitresultg2a1);
ci4 = confint(fitresultg2a2);
%% exponential    a*(exp(b*x))
if strcmp(law, 'exp1')
            yhat_g1a1 = coefs1(1)*(exp(coefs1(2) * x));
            g1a1_lowbound = ci1(1,1) * (exp(ci1(1,2) * x));
            g1a1_highbound = ci1(2,1) * (exp(ci1(2,2) * x));
            
           yhat_g1a2 =  coefs2(1)*(exp(coefs2(2) * x));
            g1a2_lowbound =  ci2(1,1) * (exp(ci2(1,2) * x));
            g1a2_highbound = ci2(2,1) * (exp(ci2(2,2) * x));
 
           yhat_g2a1 = coefs3(1)*(exp(coefs3(2) * x));
            g2a1_lowbound =  ci3(1,1) * (exp(ci3(1,2) * x));
            g2a1_highbound = ci3(2,1) * (exp(ci3(2,2) * x));
        
           
           yhat_g2a2 =coefs4(1)*(exp(coefs4(2) * x));
            g2a2_lowbound =  ci4(1,1) * (exp(ci4(1,2) * x));
            g2a2_highbound = ci4(2,1) * (exp(ci4(2,2) * x));

elseif strcmp(law, 'power1')
%% power a*x^b
            yhat_g1a1 = coefs1(1)*(x .^ coefs1(2));
            g1a1_lowbound = ci1(1,1)*(x .^ ci1(1,2));
            g1a1_highbound = ci1(2,1)*(x .^ ci1(2,2));
            
           yhat_g1a2 =  coefs2(1)*(x .^ coefs2(2));
            g1a2_lowbound =  ci2(1,1)*(x .^ ci2(1,2));
            g1a2_highbound = ci2(2,1)*(x .^ ci2(2,2));
 
           yhat_g2a1 = coefs3(1)*(x .^ coefs3(2));
            g2a1_lowbound =  ci3(1,1)*(x .^ ci3(1,2));
            g2a1_highbound = ci3(2,1)*(x .^ ci3(2,2));
           
           yhat_g2a2 = coefs4(1)*(x .^ coefs4(2)); 
            g2a2_lowbound =  ci4(1,1)*(x .^ ci4(1,2));
            g2a2_highbound = ci4(2,1)*(x .^ ci4(2,2));        
 
end
 
 plot(1:99, mean(Millisec(:,:,1)), 'ko')
 hold on
 shadedErrorBar(4:48, yhat_g1a1, [(g1a1_highbound-yhat_g1a1);(yhat_g1a1 - g1a1_lowbound)]/1.96)
 hold on
 shadedErrorBar(52:96, yhat_g1a2, [(g1a2_highbound - yhat_g1a2);(yhat_g1a2-g1a2_lowbound)]/1.96)  
 hold on

 plot(1:99, mean(Millisec(:,:,2)), 'ro')
 hold on
 shadedErrorBar(4:48, yhat_g2a1, [(g2a1_highbound-yhat_g2a1);(yhat_g2a1 - g2a1_lowbound)]/1.96, 'r')
 hold on
 shadedErrorBar(52:96, yhat_g2a2, [(g2a2_highbound - yhat_g2a2);(yhat_g2a2-g2a2_lowbound)]/1.96, 'r')
 