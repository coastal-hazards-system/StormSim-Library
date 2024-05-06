%% StormSim_JPM_Plot.m
%{
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics
    Laboratory (hereinafter “ERDC-CHL”). This material is distributed in
    accordance with DoD Instruction 5230.24. Recipient agrees to abide by
    all notices, and distribution and license markings. The controlling DOD
    office is the U.S. Army Engineer Research and Development Center
    (hereinafter, "ERDC"). This material shall be handled and maintained in
    accordance with For Official Use Only, Export Control, and AR 380-19
    requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and
    derivative works of StormSim and any portions thereof including,
    without limitation, all rights to patent, copyright, trade secret,
    trademark and other proprietary or intellectual property rights.
    Recipient has no rights, by license or otherwise, to use, disclose or
    disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT
    HOLDERS. ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS
    OR IMPLIED WITH RESPECT TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL,
    AND EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, EITHER EXPRESSED OR
    IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF MERCHANTABILITY,
    NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE
    AND RESULTS OF THE USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE
    UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL WARRANTIES AND LIABILITIES
    REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND DISTRIBUTES
    IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST
    ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND
    SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD HARMLESS ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SOFTWARE NAME:
   StormSim-JPM-Plot (Plot Integration)

DESCRIPTION:
   This script plots the response hazard curves developed with the Joint
   Probability Method (JPM) integration script StormSim_JPM.m

INPUT ARGUMENTS:
 - JPM_output: output from StormSimJPM.m . Full hazard curves per virtual gauge;
      as a structure variable with fields:
         sp_ID: savepoint ID number
         x: AEP values
         y: response hazard values
 - sp_id: ID number of the savepoints; specified as a vector of positive
      integers. Example: sp_id = [1 2 3 4 5 10 100 1500];
 - path_out: path to output folder; specified as a character string.
      Leave empty to apply default path in current folder: '.\HC_plots\'
 - yaxis_label: y-axis label for response variable; specified as a character
      vector. Example: 'Still Water Level, SWL (m)'
 - y_ax_Lims: y-axis limits of the plot; specified as a vector. Leave
      empty [] or use this format:
      Col(01): lower limit
      Col(02): upper limit
 - integrate_Method: JPM method to apply; specified as a character vector. Current options
      are 'JPM Standard', 'PCHA ATCS', or 'PCHA Standard'
 - prc: confidence level percentage; specified as a scalar or vector. Leave
      empty [] to apply default values: [2 15 84 98].

OUTPUT ARGUMENTS:
   None. The plot is automatically stored in the output path.

AUTHORS:
   Norberto C. Nadal-Caraballo, PhD (NCNC)
   Efrain Ramos-Santiago (ERS)

CONTRIBUTORS:
   Alexandros A. Taflanidis, PhD (AAT)
   Victor M. Gonzalez, PE (VMG)

HISTORY OF REVISIONS:
20200904-ERS: revised.
20201011-ERS: updated.

***************  ALPHA  VERSION  ***************  FOR TESTING  ************
%}
function [] = StormSim_JPM_Plot(JPM_output,sp_id,path_out,yaxis_label,y_ax_Lims,integrate_Method,prc,ind_aep,a,HC_plt_x,y_log,resp_id)


%% Other parameters
dm_met={'PCHA ATCS','PCHA Standard','JPM Standard'};
str=[dm_met{integrate_Method},' Method'];N=length(JPM_output);cs={'r-.','b--','b--','r-.'};
if length(prc)<4,cs={'r-.','b-.','m-.'};end;prc=round(prc);

% Axes limits
if ind_aep
    XLim=[1e-4 1];XTick=[1e-4 1e-3 1e-2 1e-1 1];
else
    XLim=[1e-4 10];XTick=[1e-4 1e-3 1e-2 1e-1 1 10];
end

% Axes labels
if ind_aep
    XLab = 'Annual Exceedance Probability';
else
    XLab = 'Annual Exceedance Frequency (yr^{-1})';
end

%% Plot hazard curves
if integrate_Method==3 %'JPM Standard'
    for i=1:N
        str2 = int2str(sp_id(i));
        if ~isempty(JPM_output(i).HC_plt_y)
            figure('Color',[1 1 1],'visible','off');
            axes('XScale','log','Yscale',y_log,'XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
            xticks(XTick); xlim(XLim);
            set(gca,'XDir','reverse');
            if ~isempty(y_ax_Lims)
                ylim([min(y_ax_Lims) max(y_ax_Lims)]);
            end
            hold on
            plot(HC_plt_x,JPM_output(i).HC_plt_y,'b','LineWidth',2);
            title({'Coastal Hazards System | StormSim - JPM';...
                str;...
                ['(Virtual Gauge ',str2,')']},'FontSize',12);
            xlabel(XLab,'FontSize',12);
            ylabel({yaxis_label},'FontSize',12);
            hold off
            fname=[path_out,'HC_vg_',resp_id,'.png'];
            switch a
                case 0
                    exportgraphics(gcf,fname,'Resolution',150);
                case 1
                    saveas(gcf,fname,'png');
            end
        end
    end
else %'PCHA ATCS' or 'PCHA Standard'
    for i=1:N
        str2 = int2str(sp_id(i));
        if ~isempty(JPM_output(i).HC_plt_y)
            
            % Take percentiles
            y = JPM_output(i).HC_plt_y(:,1);
            Boot_plt = JPM_output(i).HC_plt_y(:,2:end);
            
            figure('Color',[1 1 1],'visible','off')
            axes('XScale','log','Yscale', y_log, 'XGrid','on','XMinorTick','on','YGrid','on','YMinorTick','on','FontSize',12);
            xticks(XTick); xlim(XLim);
            set(gca,'XDir','reverse');
            if ~isempty(y_ax_Lims)
                ylim([y_ax_Lims(1) y_ax_Lims(2)]);
            end
            hold on;
            
            % Process the percentiles
            pObj=struct('o',[],'n',[],'L','');
            for j=1:length(prc)
                pObj(j).o = plot(HC_plt_x,Boot_plt(:,j),cs{j},'LineWidth',2);
                pObj(j).n = prc(j);
                pObj(j).L = {['CL',int2str(prc(j)),'%']};
            end
            pObj_t = struct2table(pObj);
            pObj_t = sortrows(pObj_t,'n','descend'); % sort the table by 'n'
            
            % Take percentiles
            t1 = pObj_t(pObj_t.n>50,:); t1 = table2struct(t1); %above the mean
            t2 = pObj_t(pObj_t.n<50,:); t2 = table2struct(t2); %below the mean
            
            % Mean
            h1 = plot(HC_plt_x,y,'k','LineWidth',2);
            title({'Coastal Hazards System | StormSim - JPM'; str;...
                ['(Virtual Gauge ',str2,')']},'FontSize',12);
            xlabel(XLab,'FontSize',12);
            ylabel({yaxis_label},'FontSize',12);
            legend([[t1.o],h1,[t2.o]],{t1.L,'Mean',t2.L},'Location','NorthWest','FontSize',12);
            
            hold off;
            fname=[path_out,'HC_vg_',resp_id,'.png'];
            switch a
                case 0
                    exportgraphics(gcf,fname,'Resolution',150);
                case 1
                    saveas(gcf,fname,'png');
            end
        end
    end
end
end