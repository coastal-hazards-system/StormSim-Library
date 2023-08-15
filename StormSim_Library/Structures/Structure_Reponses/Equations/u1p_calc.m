
function u1p = u1p_calc(wdth,Rc,z1p,Tmm1,H,Sslp,grav)
    % Spectral Mean Wave Length
    Lmm1=grav*Tmm1.^2./2./pi;
    % Spectral Mean Wave Slope
    som = H./Lmm1;
    % Surf Similarity Parameter
    SSPm=1./Sslp./sqrt(som);
    % Friction Factor
    gamf = zeros(size(Tmm1));
    gamf(SSPm<=2) = 0.55;
    gamf(SSPm>2 & SSPm<10) = 0.05625.*(SSPm(SSPm>2 & SSPm<10)-2)+0.55;
        gamf(SSPm>=10) = 1;
    % friction factor for crest
    gam_crest =gamf;
    % Compute u1%
    u1pNum=sqrt((z1p-Rc)./gamf./H); % What To Do When z1p-Rc
    u1pDenom=1+0.1.*wdth./H;
    u1p=sqrt(grav.*H).*1.7.*sqrt(gam_crest).*u1pNum./u1pDenom;
    u1p((z1p-Rc)<0) = 0;
end