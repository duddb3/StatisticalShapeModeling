function STL = SA_center(STL)


    for n=1:length(STL)
        STL(n).Translation = mean(STL(n).Vertices);
        STL(n).Vertices = STL(n).Vertices-STL(n).Translation;
        STL(n).Centered = true;
    end
    

end