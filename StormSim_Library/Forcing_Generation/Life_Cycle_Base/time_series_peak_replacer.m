%{
LICENSING:
    This code is part of StormSim software suite developed by the U.S. Army
    Engineer Research and Development Center Coastal and Hydraulics Laboratory
    (hereinafter “ERDC-CHL”). This material is distributed in accordance with DoD
    Instruction 5230.24. Recipient agrees to abide by all notices, and distribution
    and license markings. The controlling DOD office is the U.S. Army Engineer
    Research and Development Center (hereinafter, "ERDC"). This material shall be
    handled and maintained in accordance with For Official Use Only, Export Control,
    and AR 380-19 requirements. ERDC-CHL retains all right, title and interest in
    StormSim and any portion thereof and in all copies, modifications and derivative
    works of StormSim and any portions thereof including, without limitation, all
    rights to patent, copyright, trade secret, trademark and other proprietary or
    intellectual property rights. Recipient has no rights, by license or otherwise, to
    use, disclose or disseminate StormSim, in whole or in part.

DISCLAIMER:
    STORMSIM IS PROVIDED “AS IS” BY ERDC-CHL AND THE RESPECTIVE COPYRIGHT HOLDERS.
    ERDC-CHL MAKES NO OTHER WARRANTIES WHATSOEVER EITHER EXPRESS OR IMPLIED WITH RESPECT
    TO STORMSIM OR ANYTHING PROVIDED BY ERDC-CHL, AND EXPRESSLY DISCLAIMS ALL WARRANTIES
    OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING WITHOUT LIMITATION, WARRANTIES OF
    MERCHANTABILITY, NON-INFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE, FREEDOM FROM BUGS,
    CORRECTNESS, ACCURACY, RELIABILITY, AND RESULTS, AND REGARDING THE USE AND RESULTS OF THE
    USE, AND THAT THE ASSOCIATED SOFTWARE’S USE WILL BE UNINTERRUPTED. ERDC-CHL DISCLAIMS ALL
    WARRANTIES AND LIABILITIES REGARDING THIRD PARTY SOFTWARE, IF PRESENT IN STORMSIM, AND
    DISTRIBUTES IT “AS IS.” RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS AGAINST ERDC-CHL, THE
    UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS, AND SHALL INDEMNIFY AND HOLD
    HARMLESS ERDC-CHL, THE UNITED STATES GOVERNMENT AND ITS CONTRACTORS AND SUBCONTRACTORS FOR ANY
    LIABILITIES, DEMANDS, DAMAGES.

SCRIPT NAME:
    time_series_peak_replacer.m.

CALLED BY:
    DLL_Master.m

PURPOSE:
    This script replaces the peak water level value for each storm time
    series with the one reported in the ADCIRC peaks files.

INPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    | LC_SimOUT_hyd |  Structure  |  Time series life cyle structure used in |
    |               |             |  damage progression analysis (timeseries)|
    |---------------|-------------|------------------------------------------|
    |   MCSimOUT    |   Matrix    |  Contains peak water level and wave      |
    |               |             |  height values of sampled storms.        |
    |---------------|-------------|------------------------------------------|
    |    MC_indx    |  Structure  |  Contains storm indexes of sampled       |
    |               |             |  storms. Used to build LC_SimOUT_hyd     |
    |---------------|-------------|------------------------------------------|

OUTPUTS:
    |   Vars Name   |  Vars Type  |               Description                |
    |---------------|-------------|------------------------------------------|
    | LC_SimOUT_hyd |  Structure  |  Time series life cyle structure used in |
    |               |             |  damage progression analysis (timeseries)|
    |---------------|-------------|------------------------------------------|

AUTHOR:
Fabian Garcia-Moreno
%}
function [LC_SimOUT_hyd] = time_series_peak_replacer(LC_SimOUT_hyd,LC_MCSimOUT,MC_indx)

% Loop Through ALl Life Cycles
for jj = 1:length(LC_SimOUT_hyd)
    % Extract Current Time Series LC
    tsData = LC_SimOUT_hyd(jj).LCNUM;
    % Extract Current Peaks LC
    pData = LC_MCSimOUT(jj).LCNUM;
    % Extract Current MC Index LC
    mData = MC_indx(jj).LCNUM;
    % Loop Through All Storms In LC
    for ii = 1:length(pData)
        if mData(ii,2)==1
            % Extract Row Indexes Of Storm From Time Series LC Forcing Structure
            tsIndx = find(tsData(:,1)==pData(ii,8));
            % Find Where The Maximum WL Is Located
            [~,mIndx] = max(tsData(tsIndx,5));
            % Replace Storm Time Series Peak WL With Peak Found On Peaks File
            LC_SimOUT_hyd(jj).LCNUM(tsIndx(mIndx),5) = pData(ii,4);
        end
    end
end
end