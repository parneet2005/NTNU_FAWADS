function h = fadingCoeff(type)
% Small-scale fading
%   type = 'rayleigh' or 'rician'
    switch lower(type)
      case 'rayleigh'
        h = (randn+1i*randn)/sqrt(2);
      case 'rician'
        K = 6;  % Rician K-factor
        s = sqrt(K/(K+1));
        sigma = sqrt(1/(2*(K+1)));
        h = (s + sigma*(randn+1i*randn));
      otherwise
        error('Unknown fading type');
    end
end
