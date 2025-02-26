function STL = SA_smooth(STL)


    parfor n=1:length(STL)
        % get the faces and vertices
        F = STL(n).Faces;
        V = STL(n).Vertices;

        % laplacian smoothing
        STL(n).Vertices = SA_smooth_vertices(V,F,'laplacian',1/16,20);

        STL(n).Vertices = SA_smooth_vertices(STL(n).Vertices,F,'mean',round(0.005*length(V)),1);

        STL(n).Smoothed = true;

    end
    

end