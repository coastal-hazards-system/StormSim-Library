 
function [indx,dummy3] = date_search(dStruct,dBeg,dEnd,indx)
    % Get Date Ranges
    RangeStart = dStruct.startDate(indx);% Start
    RangeEnd = dStruct.endDate(indx);% End
    % Cut Date Strings
    RangeStart = cellfun(@(x) datenum(x(1:end-4),'yyyy-mm-dd HH:MM:SS'),RangeStart,'UniformOutput',false);
    RangeEnd = cellfun(@(x) datenum(x(1:end-4),'yyyy-mm-dd HH:MM:SS'),RangeEnd,'UniformOutput',false);
    % Check If Query Dates Are Within Product Date Ranges (A<x<B, where x->query dates)
    uBound_chk_dummy = cell2mat(cellfun(@(x) cell2mat(RangeStart)<=x & x<=cell2mat(RangeEnd),{dBeg},'UniformOutput',false));
    lBound_chk_dummy = cell2mat(cellfun(@(x) x>cell2mat(RangeStart) & x<=cell2mat(RangeEnd),{dEnd},'UniformOutput',false));
    % Logical Vector (A<x<B, where x->query dates)
    dummy_indx = uBound_chk_dummy+lBound_chk_dummy>1;
    
    % Query Dates Are Within Range
    if sum(dummy_indx)==2
        % Redefine Product Selection Index
        indx = indx(dummy_indx);
        %
        uBound_chk = uBound_chk_dummy(dummy_indx);
        lBound_chk = lBound_chk_dummy(dummy_indx);
    else
        for kk = 1:length(indx)
            [uBound_chk,lBound_chk] =  date_query_inspecter(uBound_chk_dummy(kk),lBound_chk_dummy(kk),dBeg,dEnd,RangeStart(kk),RangeEnd(kk));
            if uBound_chk==1 && lBound_chk==1
                indx = indx(kk);RangeStart = RangeStart(kk);RangeEnd = RangeEnd(kk);break;
            end
        end
        if uBound_chk==0 && lBound_chk==0
            indx = indx(kk);RangeStart = RangeStart(kk);RangeEnd = RangeEnd(kk);
        end
    end
    
    dummy3 = find(uBound_chk==1 & lBound_chk==1);
end
               