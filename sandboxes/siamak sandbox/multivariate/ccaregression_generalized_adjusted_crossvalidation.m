% predicting numerical values using CCA
% large values and small values are corrected

clear all;
format long
disp('===== Linear CCA for Regression ====');
disp('Reading featur vector');

output_mean_mse_array = zeros(7,9);
colinoutput = 0;
for helel_data = [100,200,400,800,1200,1500, 2000,5000,10000]
    colinoutput = colinoutput+1;
    Indices = crossvalind('Kfold',helel_data , 10);%crossvalind('Kfold', 26548, 10);
    figure;
    
    subplot(7,2,1);
    
    for feat = 1:7
        MSEarray =[];
        elapsedarray =[];
        for crossvalidateIter = 1:10
            (fprintf('%d, %.5f',crossvalidateIter, mean(MSEarray)));
            possiblefeaturizations =  {'tfidfbucket','all','logmultinomial', 'logmultinomial2', 'logmultinomial3','bernouli', 'tfidf','multinomial'};
            %featurization = 'bernouli'%'tfidf'%'tfidf'%'multinomial'%'tfidf' %'multinomial'; % 'bernouli', 'tfidf'
            featurization  = possiblefeaturizations{feat};
            featurs = csvread('data\forWeka_featuresonly.csv');
            featurs = featurs(:,2:size(featurs,2));
            
            
            num_data = helel_data%size(featurs,1); %5000;
            
            
            %disp(sprintf('Number of datapoints %d',num_data))
            if strcmp(featurization,'multinomial')
                %just pass
            elseif strcmp(featurization,'bernouli')
                featurs = bernoulli(featurs);
            elseif strcmp(featurization,'tfidf')
                featurs = tfidf(featurs);
            elseif strcmp(featurization,'logmultinomial')
                featurs = log(featurs+1)./log(2);
            elseif strcmp(featurization,'logmultinomial2')
                featurs = round(log(featurs+1)./log(2));
            elseif strcmp(featurization,'logmultinomial3')
                featurs = (log(featurs+1));
            elseif strcmp(featurization,'all')
                featurs = [bernoulli(featurs), tfidf(featurs), (log(featurs+1))] ;
            elseif strcmp(featurization,'tfidfbucket')
                featurs = [log(1000*tfidf(featurs)+1)] ;
                
            end
            
            
            size_training = floor(.9*num_data);
            
            
            trainingset = featurs(Indices~=crossvalidateIter,:);
            testset = featurs(Indices==crossvalidateIter,:);
            
            %disp('Splitting up data into training/test sets');
            [num,txt,raw] = xlsread('data\final104.xls');
            
            % reading the description of each shoe
            descriptions = raw(2:size(raw,1),2);
            style_ratings = num(1:size(num,1),1);
            comfort_ratings = num(1:size(num,1),4);
            overal_ratings = num(1:size(num,1),5);
            
            % only take m data points
            m=num_data;
            descriptions = descriptions(1:m);
            style_ratings = style_ratings(1:m);
            comfort_ratings = comfort_ratings(1:m);
            overal_ratings = overal_ratings(1:m);
            
            responsevals = [style_ratings, comfort_ratings, overal_ratings];
            
            responsevals_training = responsevals(Indices~=crossvalidateIter,:);
            responsevals_test = responsevals(Indices==crossvalidateIter,:);
            
            %disp('Adjusted Linear CCA ');
            % http://www.mathworks.com/help/toolbox/stats/classregtree.html
            
            tic;
            
            %predictions = [];
            %actual = [];
            
            
            [Wx, Wy, r, U, V]  = canoncorr(trainingset,responsevals_training);
            % in [A,B,r,U,V],  U and V are cannonical scores
            % U = (X-repmat(mean(X),N,1))*A
            % V = (Y-repmat(mean(Y),N,1))*B
            
            
            %recheck this part
            N =  size(testset,1);
            predictions = ((testset-repmat(mean(testset),N,1))*Wx*pinv(Wy))+repmat(mean(responsevals_test),N,1);
            actual = responsevals_test;
            predictions( predictions>5)=5;
            predictions( predictions<1)=1;
            MSE = mean(sum(((predictions-actual).^2)'));
            elapsed = toc;
            MSEarray = [MSEarray MSE];
            elapsedarray = [elapsedarray elapsed];
            
        end
        featurization  = possiblefeaturizations{feat}
        fprintf('avergae MSE for adjusted CCA is %0.10f\n', mean(MSEarray));
        subplot(7,2,feat*2-1)
        plot(MSEarray,'-o');
        title(strcat('MSE adjusted CCA (',featurization,') ', sprintf(' avergae MSE = %0.10f\n', mean(MSEarray))));
        xlabel('10 fold cross-validation (iteration no)')
        ylabel('MSE')
        subplot(7,2,feat*2)
        plot(elapsedarray,'-o');
        title(strcat('Elapsed time for adjusted CCA (',featurization, ') ' , sprintf(' avergae elapsed time = %0.10f\n', mean(elapsedarray))));
        xlabel('10 fold cross-validation (iteration no)')
        ylabel('Elapsed Time')
        mtit(sprintf('%d datapoints',helel_data))
        drawnow;
        output_mean_mse_array(feat,colinoutput) = mean(MSEarray);
    end
    
end


