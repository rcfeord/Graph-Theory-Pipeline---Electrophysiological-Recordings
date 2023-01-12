function electrodeHeatMaps(FN,spikeMatrix,Params)

%% create channels variable if it doesn't exist
if ~exist('channels')
       channels = [47,48,46,45,38,37,28,36,27,17,26,16,35,25,15,14,24,34,13,23,12,22,33,21,32,31,44,43,41,42,52,51,53,54,61,62,71,63,72,82,73,83,64,74,84,85,75,65,86,76,87,77,66,78,67,68,55,56,58,57];
end

% remove spikes from reference electrode
spikeMatrix(:,find(channels == 15)) = nan;

%% plot figure

F1 = figure;
makeHeatMap(spikeMatrix,'rate',channels)  % choose 'rate' or 'count' or 'logc'

% set title
title({strcat(regexprep(FN,'_','','emptymatch'),' ElectrodeHeatmap'),' '});

fprintf(strcat('\n','\n',FN,' saving heatmap...', '\n','\n'))
% save figure
if Params.figMat == 1
    saveas(gcf,strcat(FN,'_heatmap.fig'));
end
if Params.figPng == 1
    saveas(gcf,strcat(FN,'_heatmap.png'));
end
if Params.figEps == 1
    saveas(gcf,strcat(FN,'_heatmap.eps'));
end

close all;

end