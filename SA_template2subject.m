function STL = SA_template2subject(STL,template)

    
    w = waitbar(0,'Computing non-rigid deformations');
    % non-rigid coherent point drift of the template to each pointcloud.
    % Note the pointclouds have undergone centering, scaling, and rigid
    % realignment.
    vertices = template.vertices;
    parfor n=1:length(STL)
        % Define the target coordinates
        target_coords = STL(n).rVertices;

        % Scale template along x, y, and z to match subject
        mins = min(target_coords);
        rngs = range(target_coords);
        tx = mat2gray(vertices(:,1));
        stx = tx.*rngs(1)+mins(1);
        ty = mat2gray(vertices(:,2));
        sty = ty.*rngs(2)+mins(2);
        tz = mat2gray(vertices(:,3));
        stz = tz.*rngs(3)+mins(3);
        svert = [stx sty stz];

        % Do the affine transformation
        % Downsample for speed
        vertices_ds = pcdownsample(pointCloud(svert),'nonuniformGridSample',12);
        vertices_ds = vertices_ds.Location;
        target_coords_ds = pcdownsample(pointCloud(target_coords),'nonuniformGridSample',12);
        target_coords_ds = target_coords_ds.Location;
        pd = pdist2(vertices_ds,target_coords_ds);
        [asg,~] = munkres(pd);
        [ord,~] = find(asg);
        vertices_ds = vertices_ds(ord,:);
        % Define the objective function
        objectiveFunction = @(params) rms(diag(pdist2(transformVertices(vertices_ds,params),target_coords_ds)));
        % Initial guess for the transformation parameters (e.g., translation and rotation)
        initialParams = [0 0 0 1 1 1 0 0 0 0 0 0];
        % Optimize the transformation parameters
        options = optimoptions('fminunc', 'Algorithm', 'quasi-newton','MaxFunctionEvaluations',1000);
        optimalParams = fminunc(objectiveFunction, initialParams, options);
        % Apply the optimized transformation
        tpc = pointCloud(transformVertices(vertices, optimalParams));

        % Now do non-rigid coherent point drift
        [~,moved,rmsecpd] = pcregistercpd(tpc,STL(n).pointcloud, ...
            'SmoothingWeight',0.1,...
            'InteractionSigma',3,...
            'OutlierRatio',0.001,...
            'MaxIterations',20);
        % Assign to structure
        STL(n).template2subject = moved.Location;
        STL(n).template2subject_rmse = rmsecpd;
    end
    close(w)

end