function STL = SA_pointcloud(STL)
    % This function takes the surface defined by the vertices and faces in 
    % STL.Vertices and STL.Faces, resamples the surface to ~4,096 vertices,
    % saves the resamples faces and vertices in STL.rFaces and
    % STL.rVertices, and creates a pointCloud object from the resampled
    % vertices in STL.pointcloud;

    for n=1:length(STL)
        V = STL(n).Vertices;
        F = STL(n).Faces;
        [STL(n).rFaces,STL(n).rVertices] = SA_mesh_resample(F,V);
        STL(n).pointcloud = pointCloud(STL(n).rVertices);
    end

end