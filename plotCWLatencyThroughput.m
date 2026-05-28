function [figLatency, figThroughput, resultsTbl] = plotCWLatencyThroughput(stats, parTimeList, varargin)
% plotCWLatencyThroughput
%   Plot latency vs contention window and throughput vs contention window.
%
% Inputs
%   stats       : struct array. For each parTime, must contain:
%                 stats(parTime).windowList, stats(parTime).delayAve, stats(parTime).sendRate
%                 (This matches your simulateFAWADSIC output style.)
%   parTimeList : list of parTime values to plot (e.g., [2 3 5 7 10 20])
%
% Name-Value options
%   'ProtocolName'   : string for titles/legends (default: 'Protocol')
%   'SlotDuration_s' : scalar. If provided, converts latency slots->seconds
%   'PayloadBits'    : scalar. If provided with SlotDuration_s, converts throughput to bps
%   'LineSpec'       : e.g. '-o' (default: '-o')
%
% Outputs
%   figLatency    : figure handle (latency vs CW)
%   figThroughput : figure handle (throughput vs CW)
%   resultsTbl    : table with columns [parTime, CW, latency, throughput]

    p = inputParser;
    p.addParameter('ProtocolName', 'Protocol', @(s)ischar(s) || isstring(s));
    p.addParameter('SlotDuration_s', [], @(x) isempty(x) || (isscalar(x) && x > 0));
    p.addParameter('PayloadBits', [], @(x) isempty(x) || (isscalar(x) && x > 0));
    p.addParameter('LineSpec', '-o', @(s)ischar(s) || isstring(s));
    p.parse(varargin{:});

    protoName = string(p.Results.ProtocolName);
    Ts        = p.Results.SlotDuration_s;
    payloadB  = p.Results.PayloadBits;
    lineSpec  = char(p.Results.LineSpec);

    useSeconds = ~isempty(Ts);
    useBps     = ~isempty(Ts) && ~isempty(payloadB);

    % ---------- Build results table ----------
    allPar = [];
    allCW  = [];
    allLat = [];
    allThr = [];

    % ---------- Figure: Latency vs CW ----------
    figLatency = figure('Name', protoName + " Latency vs CW");
    hold on; grid on;
    xlabel('Window (W)');
    if useSeconds
        ylabel('Average latency (s)');
        title(protoName + " Latency vs Window (seconds)");
    else
        ylabel('Average latency (slots)');
        title(protoName + " Latency vs  Window (slots)");
    end

    % ---------- Figure: Throughput vs CW ----------
    figThroughput = figure('Name', protoName + " Throughput vs CW");
    hold on; grid on;
    xlabel('Window (W)');
    if useBps
        ylabel('Throughput (bps)');
        title(protoName + " Throughput vs Window (bps)");
    else
        ylabel('Throughput (successful packets/slot)');
        title(protoName + " Throughput vs Window (normalized)");
    end

    % ---------- Plot loops ----------
    for k = 1:numel(parTimeList)
        parTime = parTimeList(k);
        s = getStatsForParTime(stats, parTime, k);

        W = s.windowList(:);
        lat = s.delayAve(:);
        thr = s.sendRate(:);

        % Convert units if requested
        if useSeconds
            lat = lat .* Ts;
        end
        if useBps
            thr = thr .* (payloadB / Ts);
        end

        % Append to results arrays
        n = numel(W);
        allPar = [allPar; repmat(parTime, n, 1)];
        allCW  = [allCW;  W];
        allLat = [allLat; lat];
        allThr = [allThr; thr];

        % Plot latency
        figure(figLatency);
        plot(W, lat, lineSpec, 'DisplayName', sprintf('Generation time = %g slots', parTime));

        % Plot throughput
        figure(figThroughput);
        plot(W, thr, lineSpec, 'DisplayName', sprintf('Generation time = %g slots', parTime));
    end

    figure(figLatency); legend('Location','best');
    figure(figThroughput); legend('Location','best');

    resultsTbl = table(allPar, allCW, allLat, allThr, ...
        'VariableNames', {'parTime','CW','latency','throughput'});


    % ===== helper: locate stats entry robustly =====
    function s = getStatsForParTime(statsIn, parT, idxFallback)
        % Case A: your current style uses stats(parTime)
        if numel(statsIn) >= parT ...
                && isstruct(statsIn(parT)) ...
                && isfield(statsIn(parT),'windowList') ...
                && ~isempty(statsIn(parT).windowList)
            s = statsIn(parT);
            return;
        end

        % Case B: sequential packing stats(1..numel(parTimeList))
        if numel(statsIn) >= idxFallback ...
                && isfield(statsIn(idxFallback),'windowList') ...
                && ~isempty(statsIn(idxFallback).windowList)
            s = statsIn(idxFallback);
            return;
        end

        error('plotCWLatencyThroughput:MissingStats', ...
            'Could not find stats entry for parTime=%g.', parT);
    end
end
