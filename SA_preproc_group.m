function [STL,template] = SA_preproc_group(STL)
    % This function
    %    1. Finds the shape in STL that minimizes rigid registration error
    %    when serving as the fixed/reference shape
    %    2. Rigidly coregisters all shapes to that shape
    %    3. Creates a template shape based on the concatenation of all
    %    coregistered pointclouds
    %    4. Rigidly coregisters all shapes to that template
    %    5. Computes non-linear deformations of the template to the subject


    % instantiate variables
    rmse = NaN(length(STL));
    tforms = cell(0);
    
    % Step 1.
    % For each shape, rigidly coregister the pointcloud to each other shape
    % and record the rmse of resultant inlier points.
    w = waitbar(0,'...');
    for x=1:length(STL)
        waitbar(x/length(STL),w,sprintf('Finding optimal target shape: %i/%i',x,length(STL)));
        % get the pointcloud
        V1 = STL(x).pointcloud;
        % downsample
        V1 = pcdownsample(V1,'nonuniformGridSample',6);

        % for ICP, transform of A->B ~= transform B->A and rmse(x,y) ~=
        % rmse(y,x), so loop over all shapes
        parfor y=1:length(STL)
            % get the pointcloud
            V2 = STL(y).pointcloud;
            % downsample
            V2 = pcdownsample(V2,'nonuniformGridSample',6);

            % calculate rigid registration
            [tforms{x,y},~,rmse(x,y)] = pcregistericp(V1,V2);
        end
    end
    close(w);

    % Step 2.
    w = waitbar(0,'Applying rigid registration');
    % Find surface that provides best target for rigid registration
    [~,i] = min(mean(rmse,'omitnan'));
    % and apply the corresponding transform to all other surfaces to bring
    % the point clouds into rough alignment with one another
    parfor n=1:length(STL)
        if n==i
            STL(n).middleshape = true;
        else
            STL(n).middleshape = false;
        end
        STL(n).pointcloud = pctransform(STL(n).pointcloud,tforms{n,i});
        STL(n).rVertices = STL(n).pointcloud.Location;
        STL(n).pointcloud_realigned = true;
    end
    close(w);


    % Step 3. Create the initial template
    w = waitbar(0,'Creating template shape');
    % concatenate pointclouds
    pcall = pccat(vertcat(STL.pointcloud));
    % denoise
    pcall = pcdenoise(pcall,'NumNeighbors',round(0.005*length(pcall.Location)));
    verts = pcall.Location;
    verts = verts-mean(verts);
    % create the volumetric image
    % Set resolution
    res = 1;
    rverts = verts*(1/res);
    rverts = round(rverts);
    % convert coordinates to indices
    mncoords = min(rverts);
    rverts = rverts - mncoords;
    % provide a buffer
    rverts = rverts+10*res;
    mx = max(rverts);
    V = zeros(mx+10*res);
    for n=1:size(rverts,1)
        V(rverts(n,1),rverts(n,2),rverts(n,3)) = V(rverts(n,1),rverts(n,2),rverts(n,3))+1;
    end
    k = round(8/res);
    if rem(k,2)==0
        k = k+1;
    end
    V = smooth3(V,'gaussian',k,2);
    V = V>median(V(V~=0));
    V = imfill(V,'holes');
    [template.faces,template.vertices] = isosurface(permute(V,[2 1 3]));
    template.vertices = template.vertices*res;
    % Smooth
    template.vertices = SA_smooth_vertices(template.vertices,template.faces,'laplacian');
    % Resample to desired number of vertices
    [template.faces,template.vertices] = SA_mesh_resample(template.faces,template.vertices);
    % Center to 0,0,0
    template.vertices = template.vertices - mean(template.vertices);
    % Scale to target volume
    target_volume = mean(vertcat(STL.Volume));
    template_volume = SA_vol_sa(template.vertices,template.faces);
    scale = (target_volume/template_volume)^(1/3);
    template.vertices = scale.*template.vertices;
    % Create pointcloud object
    template.pointcloud = pointCloud(template.vertices);
    close(w);

    % Step 4. Rigidly register each subject to the new template shape
    tpc = template.pointcloud;
    parfor x=1:length(STL)
        % get the pointclouds
        V1 = STL(x).pointcloud;
        V2 = tpc;
        % calculate rigid registration
        [~,STL(x).pointcloud] = pcregistericp(V1,V2);
        STL(x).rVertices = STL(x).pointcloud.Location;
    end


end