%{
% build2DTileConfigForStitchingFromDOC.m
%
% PURPOSE: Build a 2D tile configuration text file based on PieceCoordinates as read
%   from an mdoc or idoc file. For use with FIJI grid stitching plugin.
%
% INPUTS: A folder containing the tifs to stitch plus one .mdoc or .idoc
%      file. Assumes these are named just as numbers (0001.tif, 0002.tif, etc).
%
% OUTPUTS: A custom tile config text file for use with the FIJI grid
%   stitching plugin.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% 	on earlier versions). Tested on Windows 11.
%
% AUTHOR: David C Alston (david.alston@louisville.edu) June 2025.
%
% NOTES:
%   - More info on the FIJI grid stitching plugin:
%       -- https://github.com/fiji/Stitching
%       -- https://imagej.net/plugins/grid-collection-stitching
%}
clc
close all
clear
%% Select folder with tifs and and one .mdoc or .idoc file
[inputPath] = uigetdir('', 'Select path containing tifs plus idoc/mdoc');
docFiles = [dir(strcat(inputPath, '/*.idoc'));dir(strcat(inputPath, '/*.mdoc'))];
if numel(docFiles) > 1
    beep;
    fprintf("ERROR::More than 1 idoc/mdoc file found in folder. Check input folder");
    return
end
if numel(docFiles) == 0
    beep;
    fprintf("ERROR::No idoc/mdoc files found in folder. Check input folder");
end
docFullpath = fullfile(docFiles(1).folder, docFiles(1).name);
%% Search input folder for tifs (assuming at least 2)
allTifs = dir(fullfile(inputPath, '*.tif'));
allTifs([allTifs.isdir].') = []; % Remove folders
if numel(allTifs) < 2
    beep;
    fprintf("ERROR::Less than two tif files found. Cannot build tile configuration. Check input folder");
    return
end
fprintf('INFO::Found %i tif tiles in folder. Check these are in order below:\n', numel(allTifs));
disp({allTifs(:).name}');
%% Load and parse mdoc/idoc file
% To get just per tile XY tile position in pixels as numbers (PieceCoordinates)
fileID = fopen(docFullpath, 'r');
rawChars = fscanf(fileID, '%c');
fclose(fileID);
pcSplit = split(rawChars, 'PieceCoordinates');
pcSplit(1) = []; % Has pixel spacing etc
zSplit = split(pcSplit, 'StageZ');
zSplit(:, 2) = []; % First column all that is needed
finalSplit = split(zSplit, ' ');
XYAsNum = str2double(finalSplit(:, 3:4));% Ignoring Z in this case (always 0 for these montages)
clearvars pcSplit zSplit finalSplit % Cleanup workspace
%% Build 2D tile configuration file
outString = "dim = 2";  % Always first line
outString = vertcat(outString, " ");  % Always second line
for N = 1:numel(allTifs)
    cTifName = allTifs(N).name;
    xyToAdd = XYAsNum(N, :);
    xyAsStr = string(['(', num2str(xyToAdd(1)), ', ', num2str(xyToAdd(2)), ')']);
    newLine = strcat(cTifName, "; ; ", xyAsStr);
    outString = vertcat(outString, newLine); %#ok<AGROW>
end
newTileConfigFullpath = fullfile(inputPath, 'customTileConfig.txt');
outFID = fopen(newTileConfigFullpath, 'w');
fprintf(outFID, '%s\n', outString);
fclose(outFID);
%% Wrote succesfully, write info
fprintf('INFO::Wrote tile configuration successfully:\n');
disp(outString);