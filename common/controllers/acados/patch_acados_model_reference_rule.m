function patch_acados_model_reference_rule( ...
    generatedDirectory, solverSourceName)
%PATCH_ACADOS_MODEL_REFERENCE_RULE Patch one generated S-function source.

arguments
    generatedDirectory {mustBeTextScalar}
    solverSourceName {mustBeTextScalar}
end

sourceFile = fullfile( ...
    string(generatedDirectory), ...
    string(solverSourceName));

sourceText = fileread(sourceFile);

inheritanceRule = ...
    "ssSetModelReferenceSampleTimeInheritanceRule(" + ...
    "S, USE_DEFAULT_FOR_DISCRETE_INHERITANCE);";

if contains(sourceText, inheritanceRule)
    return;
end

pattern = ...
    "(static void mdlInitializeSizes\s*" + ...
    "\(SimStruct \*S\)\s*\{)";

replacement = ...
    "$1" + newline + ...
    "    " + inheritanceRule;

patchedText = regexprep( ...
    sourceText, pattern, replacement, "once");

assert( ...
    ~isequal(patchedText, sourceText), ...
    "Could not locate mdlInitializeSizes in generated S-function.");

fileID = fopen(sourceFile, "w");
assert(fileID ~= -1, ...
    "Could not open generated S-function source for writing.");

fileCleanup = onCleanup(@() fclose(fileID));
fprintf(fileID, "%s", patchedText);

disp("Added the model-reference sample-time inheritance rule.");

end
