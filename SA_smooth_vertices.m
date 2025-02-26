function smoothed_vertices = SA_smooth_vertices(V,F,filter_type,filter_factor,n_iter)


    if ismatrix(V) && size(V,2)==3
        vpc = pointCloud(V);
    else
        fprintf(2,'input to SA_smooth must be an N-by-3 matrix of coordinates')
        return
    end


    if ~exist('filter_type','var')
        filter_type = 'mean';
    else
        filter_type = lower(filter_type);
    end

    % Set default factor if not specified
    if ~exist('filter_factor','var')
        switch filter_type
            case 'mean'
                % number of nearest neighbors with which to average
                filter_factor = round(0.005*size(V,1));
            case 'laplacian'
                filter_factor = 1/16;
            case 'taubin'
                filter_factor = [1/16 -1/15];
        end
    end

    % Set default number of iterations if not specified
    if ~exist('n_iter','var')
        switch filter_type
            case 'mean'
                n_iter = 1;
            case 'laplacian'
                n_iter = 20;
            case 'taubin'
                n_iter = 20;
        end
    end


    switch filter_type
        case 'mean'
            % get starting volume
            starting_vol = SA_vol_sa(V,F);

            smoothed_vertices = zeros(size(V));
            for i=1:n_iter
                if i>1
                    vpc = pointCloud(smoothed_vertices);
                end
                for n=1:length(V)
                    j = findNearestNeighbors(vpc,vpc.Location(n,:),filter_factor);
                    smoothed_vertices(n,:) = mean(vpc.Location(j,:),1);
                end
            end

            % now rescale as the above method will shrink meshes
            new_vol = SA_vol_sa(smoothed_vertices,F);
            scale = (starting_vol/new_vol)^(1/3);
            smoothed_vertices = scale.*smoothed_vertices;

        case 'laplacian'
            % get starting volume
            starting_vol = SA_vol_sa(V,F);

            % compute the adjacency matrix
            A = sparse([F(:,1); F(:,1); F(:,2); F(:,2); F(:,3); F(:,3)], ...
                [F(:,2); F(:,3); F(:,1); F(:,3); F(:,1); F(:,2)], 1);
            A = double(A>0);
            % compute the graph laplacian
            N = size(A,1);
            GL = speye(N,N) + (A - spdiags(sum(A,2),0,N,N))*filter_factor;
            
            smoothed_vertices = V;
            for i=1:n_iter
                smoothed_vertices = GL*smoothed_vertices;
            end

            % now rescale as the above method will shrink meshes
            new_vol = SA_vol_sa(smoothed_vertices,F);
            scale = (starting_vol/new_vol)^(1/3);
            smoothed_vertices = scale.*smoothed_vertices;
        case 'taubin'
            % need to implement
        otherwise
            fprintf(2,'Input filter_type must be mean, laplacian, or taubin. No smoothing has been performed\n');
            smoothed_vertices = V;
    end

end