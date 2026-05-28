%% ————————————————————————————————————————————————
%% load your RoadRunner scenario output
load("simulationData_50_1ms.mat","time","positions");
[~, N, ~] = size(positions);
fprintf('There are %d vehicles in this RoadRunner scenario.\n', N);
% timeVec and number of slots
timeVec = time(:);
simTime = numel(timeVec);

% number of vehicles
N = size(positions,2);

% protocol parameters
dataLength   = 1;               
parTimeList  = [2, 3, 5, 7, 10, 20];
rangeThreshold = 300;    % communication range in meters
recvId         = 1;    % the “base‐station” or receiver ID
numChannel     = 16;   % # of orthogonal channels


% build the params struct for any protocol that needs it
params = struct( ...
  'parTimeList',   parTimeList, ...
  'numChannel',    numChannel, ...
  'rangeThreshold',rangeThreshold, ...
  'recvId',        recvId ...
);

% 3. Log‑distance PHY parameters
params.phy.d0        = 1;                      % reference distance (m)
params.phy.f0        = 5.9e9;                  % carrier freq (Hz)
params.phy.c         = 3e8;                    % speed of light (m/s)
params.phy.PL0       = 20*log10(4*pi*params.phy.d0*params.phy.f0/params.phy.c);
params.phy.n         = 3;                      % path‑loss exponent
params.phy.sigma     = 6;                      % shadowing std‑dev [dB]
params.phy.Pt_dBm    = 20;                     % TX power (dBm)
params.phy.RxSens_dBm= -85;                    % RX sensitivity (dBm)

%% call the FAWADS simulator
statsFAWADS = simulateFAWAD(N, dataLength, simTime, positions, params );
statsCSMA = simulateCSMACA(N, simTime, positions, params);
statsALOHA = simulateSlottedALOHA(N, simTime, positions, params);


%% now hand off to the plotting routine
% make sure plotFAWADSResults.m is on your path
plotFAWADSResults(statsFAWADS, parTimeList);

% Plot CSMA & comparisons
% plotCSMAResults(statsCSMA, parTimeList)

% plotCSMAandCompare(stats, statsCSMA, parTimeList);

plotProtocolComparison(statsFAWADS, statsCSMA, statsALOHA, parTimeList)
