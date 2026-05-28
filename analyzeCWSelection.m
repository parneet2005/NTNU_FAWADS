function [summaryTbl, details, fig] = analyzeCWSelection(stats, parTimeList, varargin)
% analyzeCWSelection
% For each packet generation time (parTime), smooth curves, compute WT95, WLtol,
% Pareto front, and a trade-off CW (knee or constraint-based).
%
% Plotting:
%   - ONLY plots smoothed curves
%   - ONE combined figure for ALL packet generation times
%
% Inputs
%   stats       : struct array with fields per parTime:
%                .windowList (CW vector), .sendRate (throughput), .delayAve (latency)
%   parTimeList : packet generation times to analyze (e.g., [2 3 5 7 10 20])
%
% Name-Value options
%   'ThroughputFrac' : 0.95 default (WT95 = smallest CW achieving 95% of max throughput)
%   'LatencyTol'     : 0.02 default (WLtol = smallest CW within 2% of min latency)
%   'SmoothMethod'   : 'movmean' (default) or 'sgolay'
%   'SmoothSpan'     : integer span in points (default 3)
%   'KneeMethod'     : 'line' (default) or 'ideal'
%   'LatencyMax'     : [] or scalar constraint (same units as delayAve)
%   'ThroughputMin'  : [] or scalar constraint (same units as sendRate)
%   'Plot'           : true/false (default true)
%   'ProtocolName'   : string for plot titles (default "Protocol")
%
% Outputs
%   summaryTbl : one row per packet generation time with CW selections
%   details    : struct array with per-parTime data/indices
%   fig        : combined figure handle (empty if Plot=false)

    p = inputParser;
    p.addParameter('ThroughputFrac', 0.95, @(x)isscalar(x) && x>0 && x<=1);
    p.addParameter('LatencyTol', 0.02, @(x)isscalar(x) && x>=0 && x<=0.2);
    p.addParameter('SmoothMethod', 'movmean', @(s)ischar(s) || isstring(s));
    p.addParameter('SmoothSpan', 3, @(x)isscalar(x) && x>=1);
    p.addParameter('KneeMethod', 'line', @(s)any(strcmpi(string(s),["line","ideal"])));
    p.addParameter('LatencyMax', [], @(x) isempty(x) || (isscalar(x) && isfinite(x)));
    p.addParameter('ThroughputMin', [], @(x) isempty(x) || (isscalar(x) && isfinite(x)));
    p.addParameter('Plot', true, @(x)islogical(x) && isscalar(x));
    p.addParameter('ProtocolName', "Protocol", @(s)ischar(s) || isstring(s));
    p.parse(varargin{:});
    opt = p.Results;

    if ~isempty(opt.LatencyMax) && ~isempty(opt.ThroughputMin)
        error('Use only one constraint: LatencyMax OR ThroughputMin (not both).');
    end

    nP = numel(parTimeList);
    summary = cell(nP, 1);
    details = struct('parTime',[],'W',[],'T_raw',[],'L_raw',[], ...
                     'T_smooth',[],'L_smooth',[],'paretoIdx',[], ...
                     'WT95',[],'WLtol',[],'Wtrade',[],'choiceRule',[]);

    % ----- Combined plot (all packet generation times) -----
    fig = [];
    if opt.Plot
        proto = string(opt.ProtocolName);
        fig = figure('Name', proto + " CW selection (smoothed, all packet generation times)");
        tiledlayout(1,2,'Padding','compact','TileSpacing','compact');

        axL = nexttile; hold(axL,'on'); grid(axL,'on');
        xlabel(axL,'Window (W)');
        ylabel(axL,'Latency (smoothed)');
        title(axL, proto + " Latency vs W (smoothed)");

        axT = nexttile; hold(axT,'on'); grid(axT,'on');
        xlabel(axT,'Window (W)');
        ylabel(axT,'Throughput (smoothed)');
        title(axT, proto + " Throughput vs W (smoothed)");
    end

    for k = 1:nP
        parTime = parTimeList(k);
        s = getStatsForParTime(stats, parTime, k);

        W = s.windowList(:);
        T = s.sendRate(:);
        L = s.delayAve(:);

        % Clean + sort
        good = isfinite(W) & isfinite(T) & isfinite(L);
        W = W(good); T = T(good); L = L(good);
        [W, ord] = sort(W);
        T = T(ord); L = L(ord);

        % ---- Smoothing ----
        Ts = smoothdata(T, opt.SmoothMethod, opt.SmoothSpan);
        Ls = smoothdata(L, opt.SmoothMethod, opt.SmoothSpan);

        % ---- WT95% ----
        Tmax = max(Ts);
        thrTarget = opt.ThroughputFrac * Tmax;
        idxWT = find(Ts >= thrTarget, 1, 'first');
        WT95 = W(idxWT);

        % ---- WLtol ----
        Lmin = min(Ls);
        latTarget = (1 + opt.LatencyTol) * Lmin;
        idxWL = find(Ls <= latTarget, 1, 'first');
        WLtol = W(idxWL);

        % ---- Pareto front (maximize Ts, minimize Ls) ----
        paretoMask = paretoFrontMaxTMinL(Ts, Ls);
        paretoIdx  = find(paretoMask);

        % ---- Choose Wtrade ----
        if ~isempty(opt.LatencyMax)
            feas = (Ls <= opt.LatencyMax);
            if any(feas)
                feasIdx = find(feas);
                [~, bestLocal] = max(Ts(feas));
                idxChoice = feasIdx(bestLocal);
                choiceRule = sprintf("Max T subject to L<=%.4g", opt.LatencyMax);
            else
                idxChoice = pickKnee(W, Ts, Ls, paretoIdx, opt.KneeMethod);
                choiceRule = "Knee (fallback; no feasible L constraint)";
            end
        elseif ~isempty(opt.ThroughputMin)
            feas = (Ts >= opt.ThroughputMin);
            if any(feas)
                feasIdx = find(feas);
                [~, bestLocal] = min(Ls(feas));
                idxChoice = feasIdx(bestLocal);
                choiceRule = sprintf("Min L subject to T>=%.4g", opt.ThroughputMin);
            else
                idxChoice = pickKnee(W, Ts, Ls, paretoIdx, opt.KneeMethod);
                choiceRule = "Knee (fallback; no feasible T constraint)";
            end
        else
            idxChoice = pickKnee(W, Ts, Ls, paretoIdx, opt.KneeMethod);
            choiceRule = "Knee on Pareto";
        end

        Wtrade = W(idxChoice);

        % ---- Build summary row (use smoothed values for reporting consistency) ----
        row = table( ...
            parTime, ...
            WT95,   Ts(W==WT95), ...
            WLtol,  Ls(W==WLtol), ...
            Wtrade, Ts(idxChoice), Ls(idxChoice), ...
            string(choiceRule), ...
            'VariableNames', { ...
                'packetGenTime', ...
                'WT95','T_smooth_at_WT95', ...
                'WLtol','L_smooth_at_WLtol', ...
                'Wtrade','T_smooth_at_Wtrade','L_smooth_at_Wtrade', ...
                'Rule' ...
            });

        summary{k} = row;

        % ---- Save details ----
        details(k).parTime   = parTime;
        details(k).W         = W;
        details(k).T_raw     = T;
        details(k).L_raw     = L;
        details(k).T_smooth  = Ts;
        details(k).L_smooth  = Ls;
        details(k).paretoIdx = paretoIdx;
        details(k).WT95      = WT95;
        details(k).WLtol     = WLtol;
        details(k).Wtrade    = Wtrade;
        details(k).choiceRule= choiceRule;

        % ---- Plot ONLY smoothed curves, combined figure ----
        if opt.Plot
            label = sprintf('Packet generation time = %g', parTime);

            plot(axL, W, Ls, '-o', 'DisplayName', label);
            plot(axT, W, Ts, '-o', 'DisplayName', label);
        end
    end

    summaryTbl = vertcat(summary{:});

    if opt.Plot
        legend(axL,'Location','best');
        legend(axT,'Location','best');
    end
end

% ===================== Helpers =====================

function s = getStatsForParTime(statsIn, parT, idxFallback)
    % Supports either stats(parTime) indexing or sequential stats(k)
    if numel(statsIn) >= parT ...
            && isstruct(statsIn(parT)) ...
            && isfield(statsIn(parT),'windowList') && ~isempty(statsIn(parT).windowList)
        s = statsIn(parT);
        return;
    end
    if numel(statsIn) >= idxFallback ...
            && isfield(statsIn(idxFallback),'windowList') && ~isempty(statsIn(idxFallback).windowList)
        s = statsIn(idxFallback);
        return;
    end
    error('Missing stats entry for packet generation time (parTime)=%g', parT);
end

function mask = paretoFrontMaxTMinL(T, L)
    % Non-dominated set for objectives: maximize T, minimize L
    n = numel(T);
    mask = true(n,1);
    for i = 1:n
        if ~mask(i), continue; end
        dom = (T >= T(i) & L <= L(i)) & (T > T(i) | L < L(i));
        dom(i) = false;
        if any(dom), mask(i) = false; end
    end
end

function idxChoice = pickKnee(W, T, L, paretoIdx, kneeMethod)
    if isempty(paretoIdx), paretoIdx = 1:numel(W); end

    Tp = T(paretoIdx);
    Lp = L(paretoIdx);

    % Normalize
    Tn = (Tp - min(Tp)) / max(eps, (max(Tp)-min(Tp)));   % higher better
    Ln = (Lp - min(Lp)) / max(eps, (max(Lp)-min(Lp)));   % lower better

    switch lower(string(kneeMethod))
        case "ideal"
            d = hypot(1 - Tn, Ln);          % ideal (1,0)
            [~, ii] = min(d);

        case "line"
            [~, a] = max(Tn);
            [~, b] = min(Ln);
            A = [Tn(a), Ln(a)];
            B = [Tn(b), Ln(b)];

            if norm(B - A) < 1e-9
                d = hypot(1 - Tn, Ln);
                [~, ii] = min(d);
            else
                P = [Tn(:), Ln(:)];
                AB = (B - A);
                num = abs( (P(:,1)-A(1))*AB(2) - (P(:,2)-A(2))*AB(1) );
                den = norm(AB);
                dist = num / den;
                [~, ii] = max(dist);
            end

        otherwise
            error('Unknown KneeMethod.');
    end

    idxChoice = paretoIdx(ii);
end
