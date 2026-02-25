function [Hm0, Depth_Limited_Waves] = apply_depth_limitation(Hm0, Tp, h, g)
%% VECTORIZE INPUTS
data_dims = size(Hm0);
Hm0 = Hm0(:);
Tp = Tp(:);
h = h(:);
%% Depth limitation wave transformation
%     disp('      Checking for depth limited waves...')
% Empirical Breaker Index Coefficient
K_b =  1; % max(0.01,normrnd(1,0.3,size(h)));
% Compute Wave Number
[km,~,~]=cellfun(@(x,y) wavnum1_VG(x,y,g),{Tp},{h},'UniformOutput',false);
km = cell2mat(km);
% Compute Depth Limited Waves
Depth_Limited_Waves=K_b*0.1.*(2*pi./km(:,1)).*tanh(km(:,1).*h);
Depth_Limited_Waves(Depth_Limited_Waves<=0)=Hm0(Depth_Limited_Waves<=0); %negative h was making these waves negative (not realistic)
% Ratio Check
Ratio_Check = Depth_Limited_Waves./h;
% Replace Hm0 With Depth Limited Value If Hm0>Hm0_DL
Hm0(Hm0>Depth_Limited_Waves) = Depth_Limited_Waves(Hm0>Depth_Limited_Waves);
% Reshape
Hm0 = reshape(Hm0,data_dims);
Depth_Limited_Waves = reshape(Depth_Limited_Waves,data_dims);

end