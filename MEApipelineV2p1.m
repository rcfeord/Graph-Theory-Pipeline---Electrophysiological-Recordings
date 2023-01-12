% Process data from MEA recordings of 2D and 3D cultures
% author: RCFeord, May 2021


%% Set parameters

% set analysis folder to home directory
HomeDir = '';

% data input from excel spreadheet, column 1: name of recording, column 2:
% DIV/age of sample, column 3: group/cell line
xlsfilename = 'OldVsNew_mismatched.xlsx'; % name of excel spreadsheet
sheet = 1; % specify excel sheet
xlRange = 'A2:C25'; % specify range on the sheet

% get date
formatOut = 'ddmmmyyyy'; Params.Date = datestr(now,formatOut); clear formatOut

% run spike detection?
detectSpikes = 0; % 1 = yes, 0 = no
% if spike detection is already output, specify the folder 
spikeDetectedData = '';

% set cost parameter for wavelet spike detection 
Params.SpikesCostParam = 0.34;

% set spike method to be used in downstream analysis
Params.SpikesMethod = 'thr4p5'; % 'thr3p0','mea','merged'

% set parameters for functional connectivity inference
Params.FuncConLagval = [15]; % set the different lag values (in ms)
Params.TruncRec = 0; % truncate recording? 1 = yes, 0 = no
Params.TruncLength = 120; % length of truncated recordings (in seconds)

% set parameters for connectivity matrix thresholding
Params.ProbThreshRepNum = 400; % probabilistic thresholding number of repeats 
Params.ProbThreshTail = 0.10; % probabilistic thresholding percentile threshold
Params.ProbThreshPlotChecks = 1; % randomly sample recordings to plot probabilistic thresholding check, 1 = yes, 0 = no
Params.ProbThreshPlotChecksN = 3; % number of random checks to plot

% set parameters for graph theory
Params.adjMtype = 'weighted'; % 'weighted' or 'binary'

% figure formats
Params.figMat = 1; % figures saved as .mat format, 1 = yes, 0 = no
Params.figPng = 1; % figures saved as .png format, 1 = yes, 0 = no
Params.figEps = 1; % figures saved as .eps format, 1 = yes, 0 = no

%% Additional setup

% create output data folder if doesn't exist
CreateOutputFolders(HomeDir,Params.Date)

% export parameters to csv file
cd(strcat('OutputData',Params.Date))
writetable(struct2table(Params), strcat('Parameters_',Params.Date,'.csv'))
cd(HomeDir)

%% Import metadata from spreadsheet

[num,txt,~] = xlsread(xlsfilename,sheet,xlRange);
ExpName = txt(:,1); % name of recording
ExpGrp = txt(:,3); % name of experimental group
ExpDIV = num(:,1); % DIV number

[~,Params.GrpNm] = findgroups(ExpGrp);
[~,Params.DivNm] = findgroups(ExpDIV);

% save metadata 
for ExN = 1:length(ExpName) 
    
    Info.FN = ExpName(ExN);
    Info.DIV = num2cell(ExpDIV(ExN));
    Info.Grp = ExpGrp(ExN);
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    save(strcat(char(Info.FN),'_',Params.Date,'.mat'),'Info')
    cd(HomeDir)
    
end

%% if spreadsheet doesnt exist...

% still needs work....
% [GrpInfo, GrpNames] = GroupingInfo(spikeDetectedData);

%% Create a random sample for checking the probabilistic thresholding

if Params.ProbThreshPlotChecks == 1
    Params.randRepCheckExN = randi([1 length(ExpName)],1,Params.ProbThreshPlotChecksN);
    Params.randRepCheckLag = Params.FuncConLagval(randi([1 length(Params.FuncConLagval)],1,Params.ProbThreshPlotChecksN));
    Params.randRepCheckP = [Params.randRepCheckExN;Params.randRepCheckLag];
end

%% Format spike data

for  ExN = 1:length(ExpName) 
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    load(strcat(char(ExpName(ExN)),'_',Params.Date,'.mat'),'Info')
    cd(HomeDir)
    
    % extract spike matrix, spikes times and associated info
    disp(char(Info.FN))
    cd(spikeDetectedData)
    [spikeMatrix,spikeTimes,Params,Info] = formatSpikeTimes(char(Info.FN),Params,Info);
    cd(HomeDir)
    
    % initial run-through to establish max values for scaling
    spikeFreqMax(ExN) = prctile((downSampleSum(full(spikeMatrix), Info.duration_s)),95,'all');
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    save(strcat(char(Info.FN),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','spikeMatrix')
    cd(HomeDir)
    
    clear spikeTimes
end

%% Ephys properties

disp('Electrophysiological properties')

spikeFreqMax = max(spikeFreqMax);

for  ExN = 1:length(ExpName)
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    load(strcat(char(ExpName(ExN)),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','spikeMatrix')
    cd(HomeDir)
    
    % get firing rates and burst characterisation
    Ephys = firingRatesBursts(spikeMatrix,Params,Info);
    
    cd(strcat('OutputData',Params.Date)); cd('EphysProperties')
    mkdir(char(Info.FN))
    cd(char(Info.FN))

    % generate and save raster plot
    rasterPlot(char(Info.FN),spikeMatrix,Params,spikeFreqMax)
    % electrode heat maps
    electrodeHeatMaps(char(Info.FN),spikeMatrix,Params)
    % spike rate half violin plots
    firingRateElectrodeDistribution(char(Info.FN),Ephys,Params)
    
    cd(HomeDir)
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    save(strcat(char(Info.FN),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','Ephys')
    cd(HomeDir)
    
    clear spikeTimes spikeMatrix
    
end

% create combined plots across groups/ages
PlotEphysStats(ExpName,Params,HomeDir)
cd(HomeDir)

%% Functional connectivity - generate adjM

disp('generating adjacency matrices')

for  ExN = 1:length(ExpName) 
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    load(strcat(char(ExpName(ExN)),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','Ephys')
    cd(HomeDir)
    
    disp(char(Info.FN))
    
    cd(strcat('OutputData',Params.Date))
    adjMs = generateAdjMs(spikeTimes,ExN,Params,Info);
    cd(HomeDir)
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    save(strcat(char(Info.FN),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','Ephys','adjMs')
    cd(HomeDir)
    
end

%% Apply graph theory

for  ExN = 1:length(ExpName) 
    
    cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    load(strcat(char(ExpName(ExN)),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','Ephys','adjMs')
    cd(HomeDir)
    
    disp(char(Info.FN))

    cd(strcat('OutputData',Params.Date)); cd('GraphTheory')
    NetMet = ExtractNetMetOrganoid(adjMs,Params.FuncConLagval,Info,HomeDir,Params);
    
    cd(HomeDir); cd(strcat('OutputData',Params.Date)); cd('ExperimentMatFiles')
    save(strcat(char(Info.FN),'_',Params.Date,'.mat'),'Info','Params','spikeTimes','Ephys','adjMs','NetMet')
    cd(HomeDir)
    
    clear adjMs 
    
end

% create combined plots
PlotNetMet(ExpName,Params,HomeDir)
cd(HomeDir)