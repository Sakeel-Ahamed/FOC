% compare_model.m
% Compares a model in Motor_Control\Modules against last committed version
% Temp files are created in Motor_Control\Build (same folder as this script)
% Automatically cleans up temp files when diff window is closed
%
% Usage:
%   compare_model()                         - compares motor_control.slx
%   compare_model('my_model.slx')           - compares specific model
%   compare_model('my_model.slx', 'HEAD~2') - compares against specific commit

function compare_model(modelName, commitRef)

    % Defaults
    if nargin < 1 || isempty(modelName)
        modelName = 'motor_control.slx';
    end
    if nargin < 2 || isempty(commitRef)
        commitRef = 'HEAD';
    end

    % Derive key folders relative to this script's location (Build folder)
    buildDir   = fileparts(mfilename('fullpath'));
    modulesDir = fullfile(buildDir, '..', 'Modules');
    modulesDir = char(java.io.File(modulesDir).getCanonicalPath()); % resolve '..'

    % Full path to the current model in Modules
    modelName = strrep(modelName, '/', filesep);
    modelName = strrep(modelName, '\', filesep);
    modelPath = fullfile(modulesDir, modelName);

    if ~isfile(modelPath)
        error('Model not found: %s\nMake sure the model is in the Modules folder.', modelPath);
    end

    [~, baseName, ext] = fileparts(modelName);
    tempFile = fullfile(buildDir, ['prev_' baseName ext]);

    % Get git root to build relative path for git show
    [gitRoot, status] = getGitRoot();
    if status ~= 0
        error('Not a git repository or git not found.');
    end

    % Build relative path for git show (forward slashes)
    relPath = strrep(modelPath, [gitRoot filesep], '');
    relPath = strrep(relPath, '\', '/');

    % Extract committed version into Build folder
    gitCmd = sprintf('cd "%s" && git show %s:"%s" > "%s"', gitRoot, commitRef, relPath, tempFile);
    [status, result] = system(gitCmd);

    if status ~= 0
        error('git show failed. Is this file committed?\nGit error: %s', result);
    end

    fprintf('===========================================\n');
    fprintf('Model:     %s\n', modelPath);
    fprintf('Against:   %s\n', commitRef);
    fprintf('Temp file: %s\n', tempFile);
    fprintf('Close the diff window to auto-delete temp file...\n');
    fprintf('===========================================\n');

    % Open visdiff
    visdiff(tempFile, modelPath);

    % Wait for diff window to close then clean up
    waitfor(findDiffFigure(modelName));

    % Delete temp file
    if isfile(tempFile)
        delete(tempFile);
        fprintf('Cleaned up: %s\n', tempFile);
    end

end


% -----------------------------------------------------------------------
% Get git root directory
% -----------------------------------------------------------------------
function [gitRoot, status] = getGitRoot()
    [status, gitRoot] = system('git rev-parse --show-toplevel');
    gitRoot = strtrim(gitRoot);
    gitRoot = strrep(gitRoot, '/', filesep); % normalise to OS separators
end


% -----------------------------------------------------------------------
% Find the visdiff figure window to waitfor
% -----------------------------------------------------------------------
function h = findDiffFigure(modelName)
    h = [];
    timeout = 10;  % max seconds to wait for visdiff to open
    
    for t = 1 : timeout
        pause(1);
        figures = findall(0, 'Type', 'figure');
        for i = 1 : length(figures)
            name = get(figures(i), 'Name');
            if contains(name, 'Comparison') || contains(name, modelName)
                h = figures(i);
                return;  % found it, stop waiting immediately
            end
        end
    end
    % If not found after 30s, cleanup will still run
end