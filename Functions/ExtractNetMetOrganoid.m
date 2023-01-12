function [NetMet] = ExtractNetMetOrganoid(adjMs,lagval,Info,HomeDir,Params)

% extract network metrics from adjacency matrices for organoid data
% author RCFeord March 2021

% edge threshold for adjM
edge_thresh = 0.0001;

mkdir(char(Info.FN))
cd(char(Info.FN))

for e = 1:length(lagval)
    
    % load adjM
    eval(['adjM = adjMs.adjM' num2str(lagval(e)) 'mslag;']);
    adjM(adjM<0) = 0;
    adjM(isnan(adjM)) = 0;
    
    % create subfolder
    mkdir(strcat(num2str(lagval(e)),'mslag'))
    cd(strcat(num2str(lagval(e)),'mslag'))
    
    %% connectivity measures
    
    % mean and max STTC
    meanSTTC(e) = nanmean(adjM(:));
    maxSTTC(e) = max(adjM(:));
    
    % create list of channel IDs
    ChannelID = 1:size(adjM,1);
    
    %% active nodes
    
    aNtemp = sum(adjM,1);
    iN = find(aNtemp==0);
    aNtemp(aNtemp==0) = [];
    aN = length(aNtemp);
    
    clear aNtemp
    
    adjM(iN,:) = [];
    adjM(:,iN) = [];
    
    %% node degree, edge weight, node strength
    
    [ND,EW] = findNodeDegEdgeWeight(adjM,edge_thresh);
    
    % Node strength
    NS = strengths_und(adjM)';
    
    % plot properties
    plotConnectivityProperties(adjM, e, lagval, maxSTTC, meanSTTC, ND, NS, EW, char(Info.FN),Params)
  
    
    %% if option stipulates binary adjM, binarise the matrix
    
    if strcmp(Params.adjMtype,'binary')
        adjM = weight_conversion(adjM, 'binarize');
    end
    
    %% network metrics - whole experiment
    
    % density
    [Dens, ~, ~] = density_und(adjM);

    % Modularity
    try
        [Ci,Q,~] = mod_consensus_cluster_iterate(adjM,0.4,50);
    catch
        Ci = 0;
        Q = 0;
    end
    nMod = max(Ci);
    
    % global efficiency
    if strcmp(Params.adjMtype,'weighted')
        Eglob = efficiency_wei(adjM);
    elseif strcmp(Params.adjMtype,'binary')
        Eglob = efficiency_bin(adjM);
    end
    
    % Lattice-like model
    if length(adjM)>25
    ITER = 10000;
    Z = pdist(adjM);
    D = squareform(Z);
    [L,Rrp,ind_rp,eff,met] = latmio_und_v2(adjM,ITER,D,'SW');
    
    % Random rewiring model (d)
    ITER = 5000;
    [R, ~,met2] = randmio_und_v2(adjM, ITER,'SW');
    
    plotNullModelIterations(met, met2, lagval, e, char(Info.FN), Params)
    
    %% Calculate network metrics (+normalization).
    
    [SW, SWw, CC, PL] = small_worldness_RL_wu(adjM,R,L);
    
    % local efficiency
    %   For ease of interpretation of the local efficiency it may be
    %   advantageous to rescale all weights to lie between 0 and 1.
    if strcmp(Params.adjMtype,'weighted')
        adjM_nrm = weight_conversion(adjM, 'normalize');
        Eloc = efficiency_wei(adjM_nrm,2);
    elseif strcmp(Params.adjMtype,'binary')
        adjM_nrm = weight_conversion(adjM, 'normalize');
        Eloc = efficiency_bin(adjM_nrm,2);
    end
   
    % betweenness centrality
    %   Note: Betweenness centrality may be normalised to the range [0,1] as
    %   BC/[(N-1)(N-2)], where N is the number of nodes in the network.
    if strcmp(Params.adjMtype,'weighted')
        BC = betweenness_wei(L);
    elseif strcmp(Params.adjMtype,'binary')
        BC = betweenness_bin(adjM);
    end
    BC = BC/((length(adjM)-1)*(length(adjM)-2));
    
     else
     SW = nan;
     SWw = nan;
     CC = nan;
     PL = nan;
     Eloc = nan;
     BC = nan;
    end
    
    % participation coefficient
%     PC = participation_coef(adjM,Ci,0);
    [PC,~,~,~] = participation_coef_norm(adjM,Ci);
    
    % within module degree z-score
    Z = module_degree_zscore(adjM,Ci,0);
    
    %% nodal efficiency
    
    if strcmp(Params.adjMtype,'weighted')
        WCon = weight_conversion(adjM, 'lengths');
        DistM = distance_wei(WCon);
        mDist = mean(DistM,1);
        NE = 1./mDist;
        NE = NE';
    end
    
    %% Hub classification
    
    try
    
    sortND = sort(ND,'descend');
    sortND = sortND(1:round(aN/10));
    hubNDfind = ismember(ND, sortND);
    [hubND, ~] = find(hubNDfind==1);
    
    sortPC = sort(PC,'descend');
    sortPC = sortPC(1:round(aN/10));
    hubPCfind = ismember(PC, sortPC);
    [hubPC, ~] = find(hubPCfind==1);
    
    sortBC = sort(BC,'descend');
    sortBC = sortBC(1:round(aN/10));
    hubBCfind = ismember(BC, sortBC);
    [hubBC, ~] = find(hubBCfind==1);
    
    sortNE = sort(NE,'descend');
    sortNE = sortNE(1:round(aN/10));
    hubNEfind = ismember(NE, sortNE);
    [hubNE, ~] = find(hubNEfind==1);
    
    hubs = [hubND; hubPC; hubBC; hubNE];
    [GC,~] = groupcounts(hubs);
    Hub4 = length(find(GC==4))/aN;
    Hub3 = length(find(GC>=3))/aN;
    
    catch
        
        Hub4 = nan;
        Hub3 = nan;
    end
    
    %% electrode specific half violin plots
    
    try
    electrodeSpecificMetrics(ND, NS, EW, Eloc, BC, PC, Z, lagval, e, char(Info.FN), Params)
    catch
    end
    
    %% node cartography
    
    [NdCartDiv, PopNumNC] = NodeCartography(Z,PC,lagval,e,char(Info.FN),Params); 

    PopNumNCt(e,:) = PopNumNC;
    
    NCpn1 = PopNumNC(1)/aN;
    NCpn2 = PopNumNC(2)/aN;
    NCpn3 = PopNumNC(3)/aN;
    NCpn4 = PopNumNC(4)/aN;
    NCpn5 = PopNumNC(5)/aN;
    NCpn6 = PopNumNC(6)/aN;
    
    %% network plots
    
    [On,adjMord] = reorder_mod(adjM,Ci);
    
    try
        channels = Info.channels;
        channels(iN) = [];
    catch
        fprintf(2,'\n  WARNING: channel order not saved in spike matrix \n used default in line 50 of batch_getHeatMaps_fcn \n \n')
        channels = [47,48,46,45,38,37,28,36,27,17,26,16,35,25,15,14,24,34,13,23,12,22,33,21,32,31,44,43,41,42,52,51,53,54,61,62,71,63,72,82,73,83,64,74,84,85,75,65,86,76,87,77,66,78,67,68,55,56,58,57];
    end
    coords(:,1) = floor(channels/10);
    coords(:,2) = channels - coords(:,1)*10;
    try
    % simple grid network plot
    StandardisedNetworkPlot(adjM, coords, 0.00001, ND, 'MEA', char(Info.FN),'2',Params,lagval,e);
   
    % grid network plot node degree betweeness centrality
    StandardisedNetworkPlotNodeColourMap(adjM, coords, 0.00001, ND, 'Node degree', BC, 'Betweeness centrality', 'MEA', char(Info.FN), '3', Params, lagval,e)
  
    % grid network plot node degree participation coefficient
    StandardisedNetworkPlotNodeColourMap(adjM, coords, 0.00001, ND, 'Node degree', PC, 'Participation coefficient', 'MEA', char(Info.FN), '4', Params, lagval,e)
  
    % grid network plot node strength local efficiency
    StandardisedNetworkPlotNodeColourMap(adjM, coords, 0.00001, NS, 'Node strength', Eloc, 'local connectivity', 'MEA', char(Info.FN), '5', Params, lagval,e)
  
    % simple circular network plot
    NDord = ND(On);
    StandardisedNetworkPlot(adjMord, coords, 0.00001, NDord, 'circular', char(Info.FN),'6',Params,lagval,e);
    
    % node cartography
    NdCartDivOrd = NdCartDiv(On);
    StandardisedNetworkPlotNodeCartography(adjMord, coords, 0.00001, NdCartDivOrd, 'circular', char(Info.FN), '7', Params, lagval, e)
    
   % colour map network plots where nodes are the same size
%     StandardisedNetworkPlotNodeColourMap2(adjM, coords, 0.00001, PC, 'Participation coefficient', 'grid', char(Info.FN), Params)
%     PCord = PC(On);
%     StandardisedNetworkPlotNodeColourMap2(adjMord, coords, 0.00001, PC, 'Participation coefficient', 'circular', char(Info.FN), Params)
%     
     catch
    end
    clear coords
    
    %% reassign to structures
    
    Var = {'ND', 'EW', 'NS', 'aN', 'Dens', 'Ci', 'Q', 'nMod', 'Eglob', 'CC', 'PL' 'SW','SWw' 'Eloc', 'BC', 'PC' , 'Z', 'NCpn1','NCpn2','NCpn3','NCpn4','NCpn5','NCpn6','Hub4','Hub3'};
    
    for i = 1:length(Var)
        VN = cell2mat(Var(i));
        VNs = strcat('NetMet.adjM',num2str(lagval(e)),'mslag.',VN);
        eval([VNs '=' VN ';']);
    end
    
    % clear variables
    clear ND EW NS Dens Ci Q nMod CC PL SW SWw Eloc BC PC Z Var NCpn1 NCpn2 NCpn3 NCpn4 NCpn5 NCpn6 Hub3 Hub4
    

cd(HomeDir); cd(strcat('OutputData',Params.Date)); cd('4_NetworkActivity'); cd('4A_IndividualNetworkAnalysis'); cd(char(Info.Grp)); cd(char(Info.FN))

end

%% node cartography proportions

plotNodeCartographyProportions(NetMet, lagval, char(Info.FN), Params)


%% plot metrics for different lag times

plotNetworkWideMetrics(NetMet, meanSTTC, maxSTTC, lagval, char(Info.FN), Params)

end
