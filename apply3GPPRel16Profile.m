function params = apply3GPPRel16Profile(params, profileName)
%APPLY3GPPREL16PROFILE Map a 3GPP Release 16 NR-V2X profile to this simulator.
%
% This project is a lightweight MAC/PHY simulator, not a full NR sidelink
% implementation. The profile below keeps explicit 3GPP-inspired metadata in
% params.nr and maps the pieces this code can actually simulate onto the
% existing channel, PHY, contention-window, diversity, and SIC knobs.

    if nargin < 2 || isempty(profileName)
        profileName = 'NR-V2X-FR1-SL-30kHz';
    end
    if ~isfield(params,'fa') || ~isstruct(params.fa), params.fa = struct(); end
    if ~isfield(params,'aloha') || ~isstruct(params.aloha), params.aloha = struct(); end
    if ~isfield(params,'csma') || ~isstruct(params.csma), params.csma = struct(); end
    if ~isfield(params,'cw') || ~isstruct(params.cw), params.cw = struct(); end
    if ~isfield(params,'phy') || ~isstruct(params.phy), params.phy = struct(); end

    switch upper(string(profileName))
        case "NR-V2X-FR1-SL-30KHZ"
            params.standard.name    = '3GPP NR-V2X sidelink';
            params.standard.release = 16;
            params.standard.profile = char(profileName);

            % Release-16 NR sidelink concepts represented as metadata.
            params.nr.interface          = 'PC5 sidelink';
            params.nr.mode               = 'Mode 2 autonomous resource selection';
            params.nr.frequencyRange     = 'FR1';
            params.nr.carrierFrequencyHz = 5.9e9;
            params.nr.bandwidthHz        = 20e6;
            params.nr.subcarrierSpacingHz= 30e3;
            params.nr.slotDuration_s     = 0.5e-3;
            params.nr.subframeDuration_s = 1e-3;
            params.nr.frameDuration_s    = 10e-3;
            params.nr.waveform           = 'CP-OFDM';
            params.nr.modulation         = {'QPSK','16QAM','64QAM','256QAM'};
            params.nr.sidelinkChannels   = {'PSCCH','PSSCH','PSFCH','PSBCH'};
            params.nr.harqFeedback       = true;
            params.nr.csiFeedback        = true;

            % Simulation mapping. These are deliberately conservative for a
            % 1 ms mobility trace: one simulator step remains one trace sample.
            params.numChannel     = 2;       % abstract NR sidelink subchannels
            params.rangeThreshold = 500;      % let link budget, not 1000 m range, dominate

            params.fa.CWmin       = 16;
            params.fa.CWmax       = 1024;
            params.aloha.CWmin    = 16;
            params.aloha.CWmax    = 1024;
            params.csma.CWmin     = 16;
            params.csma.CWmax     = 1024;
            params.cw.CWmin_base  = 16;
            params.cw.CWmax_cap   = 1024;

            params.numDiversity   = 3;
            params.enableSIC      = true;

            params.phy.d0         = 1;
            params.phy.f0         = params.nr.carrierFrequencyHz;
            params.phy.c          = 3e8;
            params.phy.PL0        = 20*log10(4*pi*params.phy.d0*params.phy.f0/params.phy.c);
            params.phy.n          = 2.2;
            params.phy.sigma      = 3;
            params.phy.Pt_dBm     = 23;
            params.phy.PtLP_dBm   = 23;
            params.phy.PtHP_dBm   = 30;
            params.phy.RxSens_dBm = -95;

        otherwise
            error('Unknown 3GPP Release 16 profile: %s', profileName);
    end
end
