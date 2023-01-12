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
    
    p = [10 10 900 600];
    set(0, 'DefaultFigurePosition', p)
    f1 = figure;
    subplot(2,5,1:2)
    imagesc(adjM)
    xlabel('nodes')
    ylabel('nodes')
    c = colorbar;
    c.Label.String = 'correlation coefficient';
    subplot(2,5,4)
    bar(maxSTTC(e))
    ylim([0 1])
    title('max STTC')
    subplot(2,5,5)
    bar(meanSTTC(e))
    ylim([0 1])
    title('mean STTC')
    subplot(2,5,6:10)
    hist(adjM(:))
    xlabel('edge weight')
    ylabel('frequency')
    saveas(f1,strcat('adjM',num2str(lagval(e)),'msConnectivityStats.fig'))
    close(f1)
    
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
     
    f2 = figure();
    subplot(2,1,1)
    plot(met)
    ylabel('small world coeff')
    xlabel('iterations/10')
    title('lattice null model')
    subplot(2,1,2)
    plot(met2)
    title('random null model')
    ylabel('small world coeff')
    xlabel('iterations/10')
    saveas(f2,strcat('adjM',num2str(lagval(e)),'msNullModels.fig'))
    close(f2)
    
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
    PC = participation_coef(adjM,Ci,0);
%     [PC,~,~,~] = participation_coef_norm(adjM,Ci);
    
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
    
    %% node cartography
    
    p = [200 200 600 400];
    set(0, 'DefaultFigurePosition', p)
    f3 = figure();
    [NdCartDiv, PopNumNC] = NodeCartography(Z,PC); 
% [NdCartDiv, PopNumNC] = NodeCartographyTemp(Z,PC);
    saveas(f3,strcat('adjM',num2str(lagval(e)),'msNdCart.fig'))
    close(f3)
    
    PopNumNCt(e,:) = PopNumNC;
    
    NCpn1 = PopNumNC(1)/aN;
    NCpn2 = PopNumNC(2)/aN;
    NCpn3 = PopNumNC(3)/aN;
    NCpn4 = PopNumNC(4)/aN;
    NCpn5 = PopNumNC(5)/aN;
    NCpn6 = PopNumNC(6)/aN;
    
    
    
    %% reassign to structures
    
    Var = {'ND', 'EW', 'NS', 'aN', 'Dens', 'Ci', 'Q', 'nMod', 'Eglob', 'CC', 'PL' 'SW','SWw' 'Eloc', 'BC', 'PC' , 'Z', 'NCpn1','NCpn2','NCpn3','NCpn4','NCpn5','NCpn6','Hub4','Hub3'};
    
    for i = 1:length(Var)
        VN = cell2mat(Var(i));
        VNs = strcat('NetMet.adjM',num2str(lagval(e)),'mslag.',VN);
        eval([VNs '=' VN ';']);
    end
    
    % clear variables
    clear ND EW NS Dens Ci Q nMod CC PL SW SWw Eloc BC PC Z Var NCpn1 NCpn2 NCpn3 NCpn4 NCpn5 NCpn6 Hub3 Hub4
    

cd(HomeDir); cd(strcat('OutputData',Params.Date)); cd('GraphTheory'); cd(char(Info.FN))

end

%% node cartography proportions

c1 = [0.8 0.902 0.310]; % light green
c2 = [0.580 0.706 0.278]; % medium green
c3 = [0.369 0.435 0.122]; % dark green
c4 = [0.2 0.729 0.949]; % light blue
c5 = [0.078 0.424 0.835]; % medium blue
c6 = [0.016 0.235 0.498]; % dark blue

F4 = figure;
x = 1:e;
b = bar(x,PopNumNCt,'stacked');

for t = 1:6
    eval(['b(t).FaceColor = c' num2str(t) ';']);
end
ylim([0 65])
xticks([1 2 3 4 5 6])
xticklabels({'15','25','50','100','150','200'})
xlabel('STTC lag (ms)')

saveas(F4,strcat('NdCartographyProportions.fig'))
close(F4)

%% plot mean and max STTC

p = [50 50 800 300];
set(0, 'DefaultFigurePosition', p)
F5 = figure;

subplot(1,2,1)
plot(meanSTTC)
title('mean STTC')
subplot(1,2,2)
plot(maxSTTC)
title('max STTC')

saveas(F5,strcat('MaxMeanSTTCvsLag.fig'))
close(F5)

%% plot metrics for different lag times

p = [50 50 1100 500];
set(0, 'DefaultFigurePosition', p)
F6 = figure;

Var = {'Dens', 'Q', 'nMod','Eglob', 'CC', 'PL', 'SW','SWw'};

for i = 1:length(Var)
    for e = 1:length(lagval)
        VN = cell2mat(Var(i));
        VNs = strcat('NetMet.adjM',num2str(lagval(e)),'mslag.',VN);
        eval(['TempDat(e) =' VNs ';']);
    end
    subplot(2,4,i)
    plot(TempDat)
    title(VN)
    clear TempDat
end

saveas(F6,strcat('NetMetvsLag.fig'))
close(F6)

%% network plots

end
