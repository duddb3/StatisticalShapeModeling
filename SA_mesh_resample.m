function [rFaces,rVertices] = SA_mesh_resample(F,V,target_density)

    if ~exist('target_density','var')
        % default to ~4,096 vertices in output
        target_density = 4096;
    end
    nvert = size(V,1);


    while target_density>nvert
        % If the number of vertices in the original file is less than
        % the target number, we need to upsample first
        numF = size(F,1);
        numV = size(V,1);
        nV = cat(1,V,zeros(numF,3));
        nF = zeros(3*numF,3);
        for i=1:numF
            j = i+numV;
            vi = F(i,:);
            nV(j,:) = mean(V(vi,:));
            nfi = 3*(i-1)+1;
            nF(nfi:nfi+2,:) = [vi([1 2; 2 3; 3 1]) repmat(j,3,1)];
        
        end
        V = nV;
        F = nF;
        nvert = size(V,1);
    end
    % Downsample the mesh to the target density
    fv.faces = F;
    fv.vertices = V;
    scale = target_density/nvert;
    nfv = reducepatch(fv,scale);
    rFaces = nfv.faces;
    rVertices = nfv.vertices;

end