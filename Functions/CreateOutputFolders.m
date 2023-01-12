function [] = CreateOutputFolders(HomeDir,Date)

% this function creates the following output folder structure:
%
%   OutputData+Date
%       ExperimentMatFiles
%       SpikeDetection
%       EphysProperties
%       FunctionalConnectivity
%       GraphTheory
%       AgeGroupComparisons

%% make sure we start in the home directory
cd(HomeDir)

%% does an output folder already exist for that date?

if exist(strcat('OutputData',Date),'dir')
    % if so, choose a suffix to rename previous analysis folder
    NewFNsuffix = inputdlg({'An output data folder already exists for the date today, enter a suffix for the old folder to differentiate (i.e. v1)'});
    NewFN = strcat('OutputData',Date,char(NewFNsuffix));
    % rename the old folder
    movefile(strcat('OutputData',Date),NewFN)
end

%% now we can create the output folders

mkdir(strcat('OutputData',Date))
cd(strcat('OutputData',Date))
mkdir('ExperimentMatFiles')
mkdir('SpikeDetection')
mkdir('EphysProperties')
cd('EphysProperties')
mkdir('NotBoxPlotsGroups')
mkdir('NotBoxPlotsDiv')
mkdir('HalfViolinPlotsGroups')
mkdir('HalfViolinPlotsDiv')
mkdir('HalfViolinPlotsGroupsElecSpecific')
mkdir('HalfViolinPlotsDivElecSpecific')
cd(HomeDir)
cd(strcat('OutputData',Date))
mkdir('FunctionalConnectivity')
mkdir('GraphTheory')
mkdir('AgeGroupComparisons')
cd('AgeGroupComparisons')
mkdir('LagGroupDivPlots')
mkdir('NotBoxPlotsGroups')
mkdir('NotBoxPlotsDiv')
mkdir('HalfViolinPlotsGroups')
mkdir('HalfViolinPlotsDiv')
mkdir('HalfViolinPlotsGroupsElecSpecific')
mkdir('HalfViolinPlotsDivElecSpecific')
mkdir('NodeCartography')
cd(HomeDir)
addpath(genpath(strcat('OutputData',Date)))

end