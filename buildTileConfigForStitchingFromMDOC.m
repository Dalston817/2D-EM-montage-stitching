% David C Alston 3-10-2025 david.alston@louisville.edu
% Build a tile configuration text file based on PieceCoordinates as read
% from an mdoc file.
% For use with FIJI grid stitching plugin
% PROTOTYPE VERSION
clc
close all
clear
%% Select mdoc or idoc file
%DEV TODO - Just find automatically in folder with tifs
[file, path] = uigetfile('*.idoc;*.mdoc');
if path == 0; return; end % User cancelled selection
mdocFullpath = fullfile(path, file);
%% Load mdoc file
fileID = fopen(mdocFullpath, 'r');
rawChars = fscanf(fileID, '%c');
fclose(fileID);
posSplit = split(rawChars, 'PieceCoordinates');
%% Parse mdoc file to get just per tile XY tile position in pixels as numbers (PieceCoordinates)
posSplit(1) = []; % Has pixel spacing etc,
zSplit = split(posSplit, 'StageZ');
zSplit(:, 2) = []; % First column all that is needed
finalSplit = split(zSplit, ' ');
XYAsNum = str2double(finalSplit(:, 3:4));% Ignoring Z in this case (always 0 for these montages)
clearvars posSplit zSplit finalSplit % Cleanup workspace
%% Select folder containing individual tiles as .tif files
%{
% Assumes these images are names '0000.tif' out to however many tiles
% there are (out to '0099.tif' if 10x10 for example)
%
% Also assumes this folder only has these tiles (no other TileConfig or
% other files)
%}
[outPath] = uigetdir('', 'Select path containing individual tif tiles');
allTifs = dir(fullfile(outPath, '*.tif'));
allTifs([allTifs.isdir].') = []; % Remove folders
fprintf('INFO::Found %i tif tiles in folder\n', numel(allTifs));
%% Build tile configuration file
outString = "dim = 2";  % Always first line
outString = vertcat(outString, " ");  %Always second line
for N = 1:numel(allTifs)
    cTifName = allTifs(N).name;
    xyToAdd = XYAsNum(N, :);
    xyAsStr = string(['(', num2str(xyToAdd(1)), ', ', num2str(xyToAdd(2)), ')']);
    newLine = strcat(cTifName, "; ; ", xyAsStr);
    outString = vertcat(outString, newLine); %#ok<AGROW>
end
newTileConfigFullpath = fullfile(outPath, 'customTileConfig.txt');
outFID = fopen(newTileConfigFullpath, 'w');
fprintf(outFID, '%s\n', outString);
fclose(outFID);
%%
fprintf('INFO::Wrote tile configuration successfully\n');