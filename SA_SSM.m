function SSM = SA_SSM(STL,modeltype,Y)
    % This function fits a statistical shape model to the shapes defined in
    % the "templat2subject" field of the STL structure variable. If a PLS
    % model type is specified, shape modes will be constructed that take 
    % into consideration the variance of the input array Y of size
    % n-by-v where n is equal to the length of the STL structure variable
    % and v is any integer.

    if ~exist('modeltype','var')
        % Default to PCA based model
        modeltype = 'PCA';
    end

    switch modeltype
        case 'PCA'
            % perform PCA based model
            % First reshape the data into an S-by-N matrix X where S is the
            % number of shapes in the dataset and N is 3 times the number
            % of coordinates
            N = numel(STL(1).template2subject);
            SSM.included = vertcat(STL.template2subject_rmse)<2;
            errs = find(SSM.included);
            S = length(errs);
            for s=1:S
                X(s,:) = STL(errs(s)).template2subject(:);
            end
            if any(isnan(X(:)))
                [coeff,SSM.scores,SSM.latent,~,~,SSM.average_shape] = pca(X,"Algorithm","als");
            else
                [coeff,SSM.scores,SSM.latent,~,~,SSM.average_shape] = pca(X,"Algorithm","svd");
            end
            SSM.average_shape = reshape(SSM.average_shape,[],3);

        
            for n=1:size(coeff,2)
                SSM.shape_mode_loadings(:,:,n) = reshape(coeff(:,n),[],3);
            end
            SSM.variance_explained = SSM.latent./sum(SSM.latent);
            SSM.cumulative_variance_explained = cumsum(SSM.variance_explained);


        case 'PLS'
            % Partial least-squares regression based model
            N = numel(STL(1).template2subject);
            bad_reg = vertcat(STL.template2subject_rmse)>=2;
            missing_Y = any(isnan(Y),2);
            SSM.included = ~bad_reg & ~missing_Y;
            errs = find(SSM.included);
            S = length(errs);
            for s=1:S
                X(s,:) = STL(errs(s)).template2subject(:);
            end
            SSM.Y = Y(SSM.included,:);
            [xl,SSM.y_loadings,SSM.x_scores,SSM.y_scores,beta,pctvar] = plsregress(zscore(X),zscore(SSM.Y));
            for n=1:size(xl,2)
                SSM.shape_mode_loadings(:,:,n) = reshape(xl(:,n),[],3);
                
            end
            SSM.intercepts = beta(1,:);
            SSM.betas = reshape(beta(2:end,:),[],3,size(Y,2));
            SSM.variance_explained = pctvar;
            SSM.cumulative_variance_explained = cumsum(SSM.variance_explained,2);

            % Permutation testing to ascertain significance of components
            perms = 5000;
            parfor p=1:perms
                ord = randperm(size(SSM.Y,1),size(SSM.Y,1));
                Yperm = SSM.Y(ord,:);
                [xl_perm(:,:,p),yl_perm(:,:,p),~,~,beta_perm(:,:,p),pctvarp(:,:,p)] = plsregress(zscore(X),zscore(Yperm));
            end
            SSM.varpval = (sum(pctvarp>pctvar,3)+1)/(perms+1);
            SSM.ylp = (sum(abs(yl_perm)>abs(SSM.y_loadings),3)+1)/(perms+1);

            
    end


end