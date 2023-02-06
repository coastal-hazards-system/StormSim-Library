function Hm0 = apply_depth_limitation(Hm0,Tp,h)    
%% Depth limitation wave transformation
%     disp('      Checking for depth limited waves...')
    % Empirical Breaker Index Coefficient
    K_b =  max(0.01,normrnd(1,0.3,size(h)));
    % Compute Wave Number
    g = 9.81*ones(size(h));
    [km,~,~]=arrayfun(@wavnum1_VG,Tp,h,g);
    % Compute Depth Limited Waves
    Depth_Limited_Waves=K_b*0.1.*(2*pi./km(:,1)).*tanh(km(:,1).*h);
    Depth_Limited_Waves(Depth_Limited_Waves<=0)=Hm0(Depth_Limited_Waves<=0); %negative h was making these waves negative (not realistic)
    % Ratio Check
    Ratio_Check = Depth_Limited_Waves./h;
    % Replace Hm0 With Depth Limited Value If Hm0>Hm0_DL
    Hm0(Hm0>Depth_Limited_Waves) = Depth_Limited_Waves(Hm0>Depth_Limited_Waves);
    end