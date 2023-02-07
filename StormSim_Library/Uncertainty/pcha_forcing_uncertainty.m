function iVar_w_u = pcha_forcing_uncertainty(iVar, u_a, u_r, normU)
a = u_a+iVar; r = u_r.*iVar;
u_iVar = 1./sqrt(1./(a).^2 + 1./(r).^2);
u_iVar = u_iVar .* (a./abs(a));
iVar_w_u = iVar + u_iVar.*normU;
end