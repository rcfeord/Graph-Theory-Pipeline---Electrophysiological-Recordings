function [NdCartDiv,PopNumNC] = NodeCartography(Z,PC)
    
% node cartography 
% see Guimera and Amaral, 2005
% 'Functional cartography of complex metabolic networks'

% author RCFeord 2020

%% define colour scheme

c1 = [0.8 0.902 0.310]; % light green
c2 = [0.580 0.706 0.278]; % medium green
c3 = [0.369 0.435 0.122]; % dark green
c4 = [0.2 0.729 0.949]; % light blue
c5 = [0.078 0.424 0.835]; % medium blue
c6 = [0.016 0.235 0.498]; % dark blue

%% create cartography boundaries

plot([0 1],[2.5 2.5],'--k')
hold on
plot([0.625 0.625],[-5 2.5],'--k')
plot([0.8 0.8],[-5 2.5],'--k')
plot([0.3 0.3],[2.5 4],'--k')
plot([0.75 0.75],[2.5 4],'--k')
xlim([0 1])
ylim([-2 4])
% ylim([min(Z)-min(Z)*0.1 max(Z)+max(Z)*0.1])

%% Find node identities

NdCartDiv = zeros(length(PC),1);
PCdivNonHub = [0 0.625 0.8 1];
PCdivHub = [0 0.3 0.75 1];
PCp1 = [];
PCp2 = [];
PCp3 = [];
PCc1 = [];
PCc2 = [];
PCc3 = [];
Zp1 = [];
Zp2 = [];
Zp3 = [];
Zc1 = [];
Zc2 = [];
Zc3 = [];
for j = 1:length(PC)
    if (Z(j)<2.5)&&(PC(j)<0.625)
        NdCartDiv(j) = 1;
        PCp1 = [PCp1 PC(j)];
        Zp1 = [Zp1 Z(j)];
    elseif (Z(j)<2.5)&&(PC(j)>=0.625)&&(PC(j)<0.8)
        NdCartDiv(j) = 2;
        PCp2 = [PCp2 PC(j)];
        Zp2 = [Zp2 Z(j)];
    elseif (Z(j)<2.5)&&(PC(j)>=0.8)
        NdCartDiv(j) = 3;
        PCp3 = [PCp3 PC(j)];
        Zp3 = [Zp3 Z(j)];
    elseif (Z(j)>=2.5)&&(PC(j)<0.3)
        NdCartDiv(j) = 4;
        PCc1 = [PCc1 PC(j)];
        Zc1 = [Zc1 Z(j)];
    elseif (Z(j)>=2.5)&&(PC(j)>=0.3)&&(PC(j)<0.75)
        NdCartDiv(j) = 5;
        PCc2 = [PCc2 PC(j)];
        Zc2 = [Zc2 Z(j)];
    elseif (Z(j)>2.5)&&(PC(j)>=0.75)
        NdCartDiv(j) = 6;
        PCc3 = [PCc3 PC(j)];
        Zc3 = [Zc3 Z(j)];
    end
end

PopNumNC(1) = length(PCp1);
PopNumNC(2) = length(PCp2);
PopNumNC(3) = length(PCp3);
PopNumNC(4) = length(PCc1);
PopNumNC(5) = length(PCc2);
PopNumNC(6) = length(PCc3);

%% plot nodes

scatter(PCp1,Zp1,18,'MarkerEdgeColor',c1,'MarkerFaceColor',c1)
scatter(PCp2,Zp2,18,'MarkerEdgeColor',c2,'MarkerFaceColor',c2)
scatter(PCp3,Zp3,18,'MarkerEdgeColor',c3,'MarkerFaceColor',c3)
scatter(PCc1,Zc1,18,'MarkerEdgeColor',c4,'MarkerFaceColor',c4)
scatter(PCc2,Zc2,18,'MarkerEdgeColor',c5,'MarkerFaceColor',c5)
scatter(PCc3,Zc3,18,'MarkerEdgeColor',c6,'MarkerFaceColor',c6)

title('node cartography')
xlabel('participation coefficient')
ylabel('within-module degree z-score')

end