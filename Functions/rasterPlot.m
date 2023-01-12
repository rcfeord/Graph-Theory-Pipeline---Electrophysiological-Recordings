function rasterPlot(File,spikeMatrix,Params,spikeFreqMax)

% creata a raster plot of the recording

%% Downsample spike matrix

% sampling frequency
fs = Params.fs;

% duration of the recording
duration_s = length(spikeMatrix)/fs; % in seconds

spikeMatrix = full(spikeMatrix);

% downsample matrix to 1 frame per second
downSpikeMatrix = downSampleSum(spikeMatrix, duration_s);

%% plot the raster

p = [100 100 1500 600];
set(0, 'DefaultFigurePosition', p)
F1 = figure;
h = imagesc(downSpikeMatrix');
        
xticks((duration_s)/(duration_s/60):(duration_s)/(duration_s/60):duration_s)
xticklabels({'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'})

c = parula;c = c(1:round(length(c)*.85),:);
colormap(c);

aesthetics
ylabel('Electrode')
xlabel('Time (min)')
cb = colorbar;
ylabel(cb, 'Firing Rate (Hz)')
cb.TickDirection = 'out';
set(gca,'TickDir','out');
cb.Location = 'Eastoutside';
cb.Box = 'off';
set(gca, 'FontSize', 14)
ylimit_cbar = spikeFreqMax;
caxis([0,ylimit_cbar])
yticks([1, 10:10:60])
title({strcat(regexprep(File,'_','','emptymatch'),' Raster'),' '});
ax = gca;
ax.TitleFontSizeMultiplier = 0.7;

%% save the figure

fprintf(strcat('\n','\n',File,' saving raster...', '\n','\n'))

if Params.figMat == 1
    saveas(gcf,strcat(File,'_Raster.fig'));
end

if Params.figPng == 1
    saveas(gcf,strcat(File,'_Raster.png'));
end

if Params.figEps == 1
    saveas(gcf,strcat(File,'_Raster.eps'));
end

close(F1); 

  
end
