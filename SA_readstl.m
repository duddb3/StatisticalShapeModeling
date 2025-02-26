function STL = SA_readstl(input)
    % Function to read in STL files
    %   input:
    %       If blank, prompts user to select stl files
    %       If a cell or string list of files, will load all stl files
    %       appearing in the list
    %       If a character array or string of length 1, will treat as
    %       directory and load any stl files in said directory
    %   output:
    %       STL: an N-by-1 structure with fieldnames
    %           "Filename" specifying the full file name of the stl file
    %           "Vertices" containing the points sampled along the surface
    %           "Faces" containing the connectivity list for the points
    %           "Volume" containing the volume bound by the surface
    % 
    % Note, for Volume and SurfaceArea, units are the cubed and squared
    % units that the stl coordinates are in (generally, this will be mm3 
    % and mm2, but that isn't guaranteed and stl does not support
    % specification).
    %
    % Jonathan Dudley, 6/4/2024

    
    % Instantiate output
    STL = struct();
    
    if ~exist('input','var')
        % If no input is given, prompt user to select stl files
        [file,path] = uigetfile('*.stl','Select files for analysis',"MultiSelect","on");
        input = fullfile(path,file);
    end

    if iscell(input)
        % Input is a cell. Check that all elements in cell are stl files.
        % If not, remove non-stl elements and give warning
        input = input(:); % ensure input is a vector
        [~,~,ext] = cellfun(@fileparts,input,'UniformOutput',false);
        isstl = ismember(ext,'.stl');
        if ~any(isstl)
            % No STL files, give error and return
            errordlg('SA_readstl expected STL files in input but found none','Error')
            return
        end
        if ~all(isstl)
            warndlg('Warning: some input files are not recognized as STL files and will be ignored.','Warning');
            input(~isstl) = [];
        end
    elseif isstring(input)
        if length(input)==1
            % Possibly a folder containing STL files
            if isfolder(input)
                d = dir(fullfile(input,'*.stl'));
                if isempty(d)
                    errordlg('SA_readstl expected STL files in input but found none','Error')
                    return
                end
                input = fullfile(input,{d.name}');
            end
        else
            % Possibly a string of file names. Check that all elements
            % in cell are stl files. If not, remove non-stl elements and
            % give warning
            [~,~,ext] = fileparts(input);
            isstl = ismember(ext,'.stl');
            if ~any(isstl)
                % No STL files, give error and return
                errordlg('SA_readstl expected STL files in input but found none','Error')
                return
            end
            if ~all(isstl)
                warndlg('Warning: some input files are not recognized as STL files and will be ignored.','Warning');
                input(~isstl) = [];
            end
        end
    elseif ischar(input)
        % Possibly a folder containing STL files
            if isfolder(input)
                d = dir(fullfile(input,'*.stl'));
                if isempty(d)
                    errordlg('SA_readstl expected STL files in input but found none','Error')
                    return
                end
                input = fullfile(input,{d.name}');
            end
    else
        errordlg('Unexpected input format for SA_readstl','Error')
        return
    end

    w = waitbar(0,'...');
    for n=1:length(input)
        waitbar(n/length(input),w,sprintf('Loading STL files into memory: %i/%i',n,length(input)));
        STL(n).Filename = fullfile(input{n});
        temp = stlread(input{n});
        STL(n).Vertices = temp.Points;
        STL(n).Faces = temp.ConnectivityList;
        % Calculate the volume and surface area (for use in scaling, if applicable)
        [STL(n).Volume,STL(n).SurfaceArea] = SA_vol_sa(temp.Points,temp.ConnectivityList);
    end
    close(w)

end