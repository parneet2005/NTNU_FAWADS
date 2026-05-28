function [CWmin, CWmax] = densityAwareCW(density, params)
% Map (scalar) density -> CWmin; cap CWmax. Linear, simple, tunable.

CWmin = round(params.cw.CWmin_base * (1 + params.cw.alpha_linear * density));
CWmin = max(params.cw.CWmin_base, CWmin);
CWmax = min(params.cw.CWmax_cap, CWmin * 32);
end
