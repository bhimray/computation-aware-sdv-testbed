function mergedTable = joinTable(tablePath1, tablePath2, outputPath)
%JOINRESULTTABLES Join two result tables with the same structure.
%
%   mergedTable = joinResultTables(tablePath1, tablePath2, outputPath)
%
% Inputs
%   tablePath1 : path to first .mat file containing a table
%   tablePath2 : path to second .mat file containing a table
%   outputPath : full path of output .mat file
%
% Example
%   mergedTable = joinResultTables( ...
%       "phase1/random_delay/urban_results.mat", ...
%       "phase1/random_delay/other_scenarios_results.mat", ...
%       "analysis/phase1_random_delay_all_scenarios.mat");
%
% The function:
%   1. Loads both files
%   2. Finds the table inside each file
%   3. Checks that both tables have the same columns
%   4. Reorders columns if needed
%   5. Vertically joins them
%   6. Saves the merged table

%% Load files
data1 = load(tablePath1);
data2 = load(tablePath2);

%% Find table in first file
table1 = getTableFromLoadedFile(data1, tablePath1);

%% Find table in second file
table2 = getTableFromLoadedFile(data2, tablePath2);

%% Check table variable names
vars1 = table1.Properties.VariableNames;
vars2 = table2.Properties.VariableNames;

% Check that both contain exactly the same variables
if ~isequal(sort(vars1), sort(vars2))
    error("Tables do not have the same variables.");
end

%% Reorder second table to match first table
table2 = table2(:, vars1);

%% Join vertically
mergedTable = [table1; table2];

%% Create output folder if it does not exist
outputFolder = fileparts(outputPath);

if ~isempty(outputFolder) && ~exist(outputFolder, "dir")
    mkdir(outputFolder);
end

%% Save
save(outputPath, "mergedTable");

fprintf("\nTables joined successfully.\n");
fprintf("Table 1 rows : %d\n", height(table1));
fprintf("Table 2 rows : %d\n", height(table2));
fprintf("Total rows   : %d\n", height(mergedTable));
fprintf("Saved to     : %s\n\n", outputPath);

end


%% ------------------------------------------------------------------------
function T = getTableFromLoadedFile(dataStruct, filePath)
% Find the table variable inside a loaded MAT file.

fieldNames = fieldnames(dataStruct);

tableFound = false;

for k = 1:numel(fieldNames)

    currentVariable = dataStruct.(fieldNames{k});

    if istable(currentVariable)

        if tableFound
            error( ...
                "More than one table exists in file: %s", ...
                filePath);
        end

        T = currentVariable;
        tableFound = true;
    end
end

if ~tableFound
    error("No table found in file: %s", filePath);
end

end