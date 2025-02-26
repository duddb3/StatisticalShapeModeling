function [volume,surface_area] = SA_vol_sa(V,F)
    % Instantiate metrics
    volume = 0;
    surface_area = 0;

    % Loop over each face
    for i=1:size(F,1)
        % Get the vertices of the face
        v1 = V(F(i,1),:);
        v2 = V(F(i,2),:);
        v3 = V(F(i,3),:);
        
        % Calculate the absolute value of the determinant to get the
        % component volume
        vol = det([[v1;v2;v3;0 0 0] [0 0 0 1]'])/6;
    
        % Add to total volume
        volume = volume + vol;

        % Calculate the distance between each pair of vertices (i.e.,
        % the triangle sides a, b, and c
        abc = pdist([v1;v2;v3]);
        % get the "semi-perimeter" (just the sum of the triangle sides
        % divided by two
        sp = sum(abc)/2;
        % Area of the triangle given by
        ar = sqrt(prod([sp (sp-abc)]));
        % Add area of face to total area
        surface_area = surface_area + ar;
    end
    volume = abs(volume);
end