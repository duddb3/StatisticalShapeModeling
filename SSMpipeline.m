function [STL,T,template] = SSMpipeline(InputTable)
    % Function to read in an excel/csv file. The file must have one column
    % labeled "STL" where each row is the full file name for a *.stl file
    % containing the shape information for a given observation. This file
    % will be read into a table variable T. Then the function will
    % construct a structure variable STL where the ith index corresponds
    % the ith row of table T. This function also produces a structure
    % variable template that is the average shape of all surfaces provided
    % in InputTable.
    % 
    % Note: The table may have any other number of columns containing 
    % participant ID, demographic information, etc. That may be useful for
    % running PLS-regression based statistical shape models like below:
    %
    %   [STL,T,template] = SSMpipeline('MyListOfSTLs.xlsx');
    %   SSM = SA_SSM(STL,'PLS',T.age);
    %
    % The above two lines of code would load in all shapes listed in the
    % file "MyListOfSTLs.xlsx", do all the requisite preprocessing, and
    % perform PLS-regression based statistical shape modeling to generate
    % shape modes that explain the variance in your age variable.



    % Read in the table in variable InputTable
    T = readtable(InputTable);

    % Read in the vertices and faces from the STL files
    STL = SA_readstl(vertcat(T.STL));
    % Center vertices
    STL = SA_center(STL);
    % Scale all shapes to average volume
    STL = SA_scale(STL);
    % Apply smoothing to surface (reduce "stairstep" effect from
    % anisotropic voxel sizes)
    STL = SA_smooth(STL);
    % Create a pointcloud object from vertices
    STL = SA_pointcloud(STL);

    % Do group-level preprocessing
    [STL,initial_template] = SA_preproc_group(STL);
    
    % initial template-to-subject non-rigid registration
    STL = SA_template2subject(STL,initial_template);
    % Perform PCA-based statistical shape model to get template
    SSM_pca = SA_SSM(STL,'PCA');
    % Create the template structure variable
    template.vertices = SSM_pca.average_shape;
    template.faces = initial_template.faces;
    template.pointcloud = pointCloud(SSM_pca.average_shape);
    % final template-to-subject non-rigid registration
    STL = SA_template2subject(STL,template);


end