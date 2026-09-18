% loadall.m
% Automatically discovers and loads all XML signal (sdef) and parameter (pdef)
% definition files from the Modules folder into the MATLAB base workspace
%
% Naming convention:
%   sdef_*.xml  ->  loaded as Simulink.Signal objects
%   pdef_*.xml  ->  loaded as Simulink.Parameter objects
%
% Location: C:\Users\sakee\OneDrive\Desktop\STM32_Projects\Motor_Control\Build
% Scans:    C:\Users\sakee\OneDrive\Desktop\STM32_Projects\Motor_Control\Modules

function loadall()

    % Define the Modules folder relative to Build folder
    buildDir   = fileparts(mfilename('fullpath'));
    modulesDir = fullfile(buildDir, '..', 'Modules');
    modulesDir = char(java.io.File(modulesDir).getCanonicalPath()); % resolve '..'

    % Check Modules folder exists
    if ~isfolder(modulesDir)
        error('Modules folder not found at: %s', modulesDir);
    end

    % Find all XML files in Modules folder
    xmlFiles = dir(fullfile(modulesDir, '*.xml'));

    if isempty(xmlFiles)
        fprintf('No XML files found in: %s\n', modulesDir);
        return;
    end

    fprintf('===========================================\n');
    fprintf('Scanning: %s\n', modulesDir);
    fprintf('Found %d XML file(s)\n', length(xmlFiles));
    fprintf('===========================================\n');

    totalSignals    = 0;
    totalParameters = 0;

    % Loop through each XML file and route to correct loader
    for f = 1 : length(xmlFiles)

        fname   = xmlFiles(f).name;
        xmlPath = fullfile(modulesDir, fname);

        fprintf('\nLoading: %s\n', fname);

        try
            if strncmp(fname, 'sdef_', 5)
                % Signal definition file
                count        = loadSignalsFromXML(xmlPath);
                totalSignals = totalSignals + count;

            elseif strncmp(fname, 'pdef_', 5)
                % Parameter definition file
                count           = loadParametersFromXML(xmlPath);
                totalParameters = totalParameters + count;

            else
                fprintf('  SKIPPED: filename does not start with sdef_ or pdef_\n');
            end

        catch e
            fprintf('  WARNING: Failed to load %s\n', fname);
            fprintf('  Reason: %s\n', e.message);
        end

    end

    fprintf('\n===========================================\n');
    fprintf('Signals loaded:    %d\n', totalSignals);
    fprintf('Parameters loaded: %d\n', totalParameters);
    fprintf('===========================================\n');

    % Hide storage class labels on all loaded models (skip locked libraries)
    loadedModels = bdroot;
    if ischar(loadedModels)
        loadedModels = {loadedModels};
    end
    for m = 1 : length(loadedModels)
        modelName = loadedModels{m};
        % Skip locked or library models
        if strcmp(get_param(modelName, 'BlockDiagramType'), 'model') && ...
           ~strcmp(get_param(modelName, 'Lock'), 'on')
            set_param(modelName, 'ShowStorageClass', 'off');
            fprintf('Hidden storage class labels for: %s\n', modelName);
        end
    end

end


% -----------------------------------------------------------------------
% Load Simulink.Signal objects from sdef XML
% -----------------------------------------------------------------------
function count = loadSignalsFromXML(xmlPath)

    tree    = xmlread(xmlPath);
    signals = tree.getElementsByTagName('Signal');
    count   = signals.getLength;

    for i = 0 : count - 1

        node = signals.item(i);

        % Get signal name attribute
        name = char(node.getAttribute('Name'));

        if isempty(name)
            fprintf('  SKIPPED: Signal with no name found\n');
            continue;
        end

        % Read fields
        dataType    = getXMLValue(node, 'DataType');
        initVal     = getXMLValue(node, 'InitialValue');
        minVal      = getXMLValue(node, 'Min');
        maxVal      = getXMLValue(node, 'Max');
        description = getXMLValue(node, 'Description');

        % Create Simulink.Signal object
        sig              = Simulink.Signal;
        sig.DataType     = dataType;
        sig.InitialValue = initVal;
        sig.StorageClass = 'Model default';
        sig.StorageClass = 'Auto';  % Simulink manages memory internally
        sig.Complexity   = 'real';  % Fixes Complexity 'auto' error
        sig.Description  = description;

        if ~isempty(minVal)
            sig.Min = str2double(minVal);
        end
        if ~isempty(maxVal)
            sig.Max = str2double(maxVal);
        end

        assignin('base', name, sig);
        fprintf('  [SIG] %s  (Type: %-10s  Init: %s)\n', name, dataType, initVal);

    end

end


% -----------------------------------------------------------------------
% Load Simulink.Parameter objects from pdef XML
% -----------------------------------------------------------------------
function count = loadParametersFromXML(xmlPath)

    tree       = xmlread(xmlPath);
    parameters = tree.getElementsByTagName('Parameter');
    count      = parameters.getLength;

    for i = 0 : count - 1

        node = parameters.item(i);

        % Get parameter name attribute
        name = char(node.getAttribute('Name'));

        if isempty(name)
            fprintf('  SKIPPED: Parameter with no name found\n');
            continue;
        end

        % Read fields
        dataType    = getXMLValue(node, 'DataType');
        value       = getXMLValue(node, 'Value');
        minVal      = getXMLValue(node, 'Min');
        maxVal      = getXMLValue(node, 'Max');
        unit        = getXMLValue(node, 'Unit');
        description = getXMLValue(node, 'Description');

        % Create Simulink.Parameter object
        param              = Simulink.Parameter;
        param.Value        = castValue(value, dataType);  % set value FIRST
        param.DataType     = dataType;                    % then set datatype
        param.StorageClass = 'Auto';
        param.Description  = description;

        if ~isempty(minVal)
            param.Min = str2double(minVal);
        end
        if ~isempty(maxVal)
            param.Max = str2double(maxVal);
        end

        assignin('base', name, param);
        fprintf('  [PAR] %s  (Type: %-10s  Value: %s  Unit: %s)\n', name, dataType, value, unit);

    end

end


% -----------------------------------------------------------------------
% Helper: cast string value to correct MATLAB numeric type
% -----------------------------------------------------------------------
function out = castValue(valStr, dataType)
    numVal = str2double(valStr);
    switch lower(dataType)
        case 'uint8',   out = uint8(numVal);
        case 'uint16',  out = uint16(numVal);
        case 'uint32',  out = uint32(numVal);
        case 'int8',    out = int8(numVal);
        case 'int16',   out = int16(numVal);
        case 'int32',   out = int32(numVal);
        case 'single',  out = single(numVal);
        case 'double',  out = double(numVal);
        case 'boolean', out = logical(numVal);
        otherwise,      out = numVal;
    end
end


% -----------------------------------------------------------------------
% Helper: extract text value from XML node by tag name
% -----------------------------------------------------------------------
function value = getXMLValue(node, tagName)
    elements = node.getElementsByTagName(tagName);
    if elements.getLength > 0
        value = strtrim(char(elements.item(0).getTextContent));
    else
        value = '';
    end
end