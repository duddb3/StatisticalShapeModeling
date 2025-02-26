function STL = SA_scale(STL)
    % This function scales the vertices such that volume of all loaded
    % objects is equal

    % In this manner, the ultimate shape modes will not contain information
    % about how the size/volume varied across participants (usually, that
    % is not of interest since you can directly and more easily measure and
    % analyze the volume/surface area if you want)

    target_volume = mean(vertcat(STL.Volume));
    for n=1:length(STL)
        scale = (target_volume/STL(n).Volume)^(1/3);
        STL(n).Vertices = scale.*STL(n).Vertices;
        STL(n).Scaled = true;
    end
    

end