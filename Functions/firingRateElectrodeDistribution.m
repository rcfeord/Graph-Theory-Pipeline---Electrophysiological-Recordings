function firingRateElectrodeDistribution(File,Ephys,Params)

% creata a half violin plot of the firing rate for individual electrodes

p = [100 100 500 600];
set(0, 'DefaultFigurePosition', p)
F1 = figure;

HalfViolinPlot(Ephys.FR,1,[0.5 0.5 0.5],0.3)

xlim([0.5 1.5])
        
xticks([])
aesthetics
ylabel('firing rate (Hz)')
title({strcat(regexprep(File,'_','','emptymatch'),' FiringRatePerElectrode'),' '});
ax = gca;
ax.TitleFontSizeMultiplier = 0.7;

%% save the figure

fprintf(strcat('\n','\n',File,' saving figure...', '\n','\n'))
if Params.figMat == 1
    saveas(gcf,strcat(File,'_FiringRatePerElectrode.fig'));
end
if Params.figPng == 1
    saveas(gcf,strcat(File,'_FiringRatePerElectrode.png'));
end
if Params.figEps == 1
    saveas(gcf,strcat(File,'_FiringRatePerElectrode.eps'));
end

close(F1); 

  
end