function setTune(paramInput, newValue)
%SETTUNE Change a tunable Simulink.Parameter and update Monitor & Tune.
%
% Both of these forms work:
%
%   setTune(BEnableLedBlink, false)
%   setTune('BEnableLedBlink', false)
%
% Examples:
%   setTune('BEnableLedBlink', true)
%   setTune('BEnableLedBlink', 'False')
%   setTune('Kp', 2.5)
%   setTune('Ki', 100)
%   setTune('SpeedRef', '1500')

    %% --------------------------------------------------------
    % Get parameter
    % ---------------------------------------------------------

    if ischar(paramInput) || isstring(paramInput)

        % Parameter name was supplied as text
        paramName = char(paramInput);

        % Read parameter from base workspace
        try
            param = evalin('base', paramName);
        catch
            error('Parameter "%s" does not exist in the base workspace.', ...
                  paramName);
        end

    elseif isa(paramInput, 'Simulink.Parameter')

        % Parameter object supplied directly
        param = paramInput;
        paramName = inputname(1);

        if isempty(paramName)
            error('Could not determine the parameter name.');
        end

    else
        error(['First argument must be either a Simulink.Parameter ' ...
               'or its name as a string.']);
    end


    %% --------------------------------------------------------
    % Verify parameter type
    % ---------------------------------------------------------

    if ~isa(param, 'Simulink.Parameter')
        error('"%s" is not a Simulink.Parameter.', paramName);
    end


    %% --------------------------------------------------------
    % Convert string inputs
    % ---------------------------------------------------------

    if ischar(newValue) || isstring(newValue)

        valueString = strtrim(string(newValue));

        if strcmpi(valueString, "true")
            newValue = true;

        elseif strcmpi(valueString, "false")
            newValue = false;

        else
            numericValue = str2double(valueString);

            if isnan(numericValue)
                error('"%s" is not a valid numeric or Boolean value.', ...
                      valueString);
            end

            newValue = numericValue;
        end
    end


    %% --------------------------------------------------------
    % Preserve parameter datatype
    % ---------------------------------------------------------

    currentValue = param.Value;

    if islogical(currentValue)

        newValue = logical(newValue);

    elseif isnumeric(currentValue)

        newValue = cast(newValue, class(currentValue));

    else

        error('Unsupported parameter type: %s', class(currentValue));

    end


    %% --------------------------------------------------------
    % Change parameter
    % ---------------------------------------------------------

    param.Value = newValue;

    % Write it back into the base workspace
    assignin('base', paramName, param);


    %% --------------------------------------------------------
    % Update model / send value to target
    % ---------------------------------------------------------

    model = bdroot(gcs);

    if isempty(model)
        error('No Simulink model is currently active.');
    end

    set_param(model, 'SimulationCommand', 'update');


    %% --------------------------------------------------------
    % Confirmation
    % ---------------------------------------------------------

    fprintf('%s = %s\n', paramName, string(newValue));

end