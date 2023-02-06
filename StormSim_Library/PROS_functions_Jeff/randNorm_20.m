%%

%% Number of Discrete Values

n=20;

%% CL = 0.000

pd = makedist('Normal','mu',0,'sigma',1);
%t = truncate(pd,-3,3);
t=pd;
r = random(t,[1e6 n]);
temp = sort(r,2);
temp = nanmean(temp,1);
temp = nanmean([abs(temp(1,1:n/2));fliplr(temp(1,n/2+1:n))]);
temp = [-1*temp,fliplr(temp)];
temp = round(temp,4);
randNorm0_20 = temp;
m0 = mean(temp);
s0 = std(temp);
max(temp)
save randNorm0_20.mat randNorm0_20
norm_20=randNorm0_20';
save discrete_norm_20.mat norm_20

%% CL = 1.000

pd = makedist('Normal','mu',1,'sigma',0.67);
%t = truncate(pd,-3,3);
t=pd;
r = random(t,[1e6 n]);
temp = sort(r,2);
temp = nanmean(temp,1);
% temp = nanmean([abs(temp(1,1:n/2));fliplr(temp(1,n/2+1:n))]);
% temp = [-1*temp,fliplr(temp)];
temp = round(temp,4);
randNorm1_20 = temp;
m1 = mean(temp);
s1 = std(temp);
max(temp)
save randNorm1_20.mat randNorm1_20

%% CL = 1.282

pd = makedist('Normal','mu',1.282,'sigma',0.58);
%t = truncate(pd,-3,3);
t=pd;
r = random(t,[1e6 n]);
temp = sort(r,2);
temp = nanmean(temp,1);
% temp = nanmean([abs(temp(1,1:n/2));fliplr(temp(1,n/2+1:n))]);
% temp = [-1*temp,fliplr(temp)];
temp = round(temp,4);
randNorm2_20 = temp;
m2 = mean(temp);
s2 = std(temp);
max(temp)
save randNorm2_20.mat randNorm2_20

%% CL = 1.644

pd = makedist('Normal','mu',1.644,'sigma',0.46);
%t = truncate(pd,-3,3);
t=pd;
r = random(t,[1e6 n]);
temp = sort(r,2);
temp = nanmean(temp,1);
% temp = nanmean([abs(temp(1,1:n/2));fliplr(temp(1,n/2+1:n))]);
% temp = [-1*temp,fliplr(temp)];
temp = round(temp,4);
randNorm3_20 = temp;
m3 = mean(temp);
s3 = std(temp);
max(temp)
save randNorm3_20.mat randNorm3_20

%% CL = 2.000

pd = makedist('Normal','mu',2,'sigma',0.34);
%t = truncate(pd,-3,3);
t=pd;
r = random(t,[1e6 n]);
temp = sort(r,2);
temp = nanmean(temp,1);
% temp = nanmean([abs(temp(1,1:n/2));fliplr(temp(1,n/2+1:n))]);
% temp = [-1*temp,fliplr(temp)];
temp = round(temp,4);
randNorm4_20 = temp;
m4 = mean(temp);
s4 = std(temp);
max(temp)
save randNorm4_20.mat randNorm4_20

