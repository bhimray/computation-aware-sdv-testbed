function exportFigure(figureHandle, folder, baseName)
%EXPORTFIGURE Save one figure in PNG and editable MATLAB formats.

arguments
    figureHandle
    folder (1,1) string
    baseName (1,1) string
end

assert(isgraphics(figureHandle, "figure"), ...
    "The supplied handle is not a MATLAB figure.");

if ~isfolder(folder)
    mkdir(folder);
end

print( ...
    figureHandle, ...
    fullfile(folder, baseName + ".png"), ...
    "-dpng", ...
    "-r200");

savefig( ...
    figureHandle, ...
    fullfile(folder, baseName + ".fig"));

end
