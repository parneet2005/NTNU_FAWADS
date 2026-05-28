function figs = plotV2XPaperFigures(statsFAWADS, N, dataLength, simTime, positions, params, varargin)
%PLOTV2XPAPERFIGURES Create V2X paper-style figures from FAWADS results.
%   figs = plotV2XPaperFigures(statsFAWADS, N, dataLength, simTime, positions, params)
%   generates:
%     1) DSR vs W for CAM/DENM/BG
%     2) PDR vs W for CAM/DENM/BG
%     3) Delay vs W for CAM/DENM/BG
%     4) Collision rate vs W
%     5) DENM DSR vs background load
%
% Name-value options:
%   'OverloadLoads' : vector of BG probabilities to sweep
%   'PlotOverload'  : true/false, defaults to true only when DENM and BG are enabled
%   'Visible'       : 'on' or 'off' for figures

    p = inputParser;
    p.addParameter('OverloadLoads', [0.01 0.03 0.05 0.10], @(x)isnumeric(x) && isvector(x) && ~isempty(x));
    p.addParameter('PlotOverload', [], @(x)islogical(x) || isnumeric(x));
    p.addParameter('Visible', 'on', @(x)ischar(x) || isstring(x));
    p.parse(varargin{:});
    opt = p.Results;

    plotOverload = opt.PlotOverload;
    if isempty(plotOverload)
        plotOverload = params.v2x.DENM.enable && params.v2x.BG.enable;
    end

    nCases = numel(statsFAWADS);
    [nRows, nCols] = bestTileShape(nCases);
    scenarioLabel = getTrafficScenarioLabel(params);

    figs = struct();
    figs.deadline = figure('Name','V2X Deadline Survival vs Window Size', ...
        'Color','w', 'Visible', char(opt.Visible));
    tl = tiledlayout(figs.deadline, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');
    title(tl, 'Deadline Survival Ratio vs Window Size');
    for caseIdx = 1:nCases
        s = getStatsEntry(statsFAWADS, caseIdx);
        ax = nexttile;
        plotTrafficMetric(ax, s.windowList, s.v2x, 'DSR_CAM', 'DSR_DENM', 'DSR_BG');
        xlabel(ax, 'W');
        ylabel(ax, 'DSR');
        title(ax, scenarioLabel);
        legend(ax, 'CAM', 'DENM', 'BG', 'Location', 'best');
        ylim(ax, [0 1]);
        grid(ax, 'on');
    end

    figs.pdr = figure('Name','V2X PDR vs Window Size', ...
        'Color','w', 'Visible', char(opt.Visible));
    tl = tiledlayout(figs.pdr, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');
    title(tl, 'Packet Delivery Ratio vs Window Size');
    for caseIdx = 1:nCases
        s = getStatsEntry(statsFAWADS, caseIdx);
        ax = nexttile;
        plotTrafficMetric(ax, s.windowList, s.v2x, 'PDR_CAM', 'PDR_DENM', 'PDR_BG');
        xlabel(ax, 'W');
        ylabel(ax, 'PDR');
        title(ax, scenarioLabel);
        legend(ax, 'CAM', 'DENM', 'BG', 'Location', 'best');
        ylim(ax, [0 1]);
        grid(ax, 'on');
    end

    figs.delay = figure('Name','V2X Delay vs Window Size', ...
        'Color','w', 'Visible', char(opt.Visible));
    tl = tiledlayout(figs.delay, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');
    title(tl, 'Average Delay vs Window Size');
    for caseIdx = 1:nCases
        s = getStatsEntry(statsFAWADS, caseIdx);
        ax = nexttile;
        plotTrafficMetric(ax, s.windowList, s.v2x, ...
            'delay_CAM_avg', 'delay_DENM_avg', 'delay_BG_avg');
        xlabel(ax, 'W');
        ylabel(ax, 'Average Delay (slots)');
        title(ax, scenarioLabel);
        legend(ax, 'CAM', 'DENM', 'BG', 'Location', 'best');
        grid(ax, 'on');
    end

    figs.collision = figure('Name','V2X Collision Rate vs Window Size', ...
        'Color','w', 'Visible', char(opt.Visible));
    tl = tiledlayout(figs.collision, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');
    title(tl, 'Collision Rate vs Window Size');
    for caseIdx = 1:nCases
        s = getStatsEntry(statsFAWADS, caseIdx);
        ax = nexttile;
        plot(ax, s.windowList, extractMetricArray(s.v2x, 'collisionRate'), '-o', 'LineWidth', 1.5);
        xlabel(ax, 'W');
        ylabel(ax, 'Collision Rate');
        title(ax, scenarioLabel);
        ylim(ax, [0 1]);
        grid(ax, 'on');
    end

    if plotOverload
        overloadLoads = opt.OverloadLoads(:).';
        denmDsrVsLoad = nan(numel(overloadLoads), nCases);
        for loadIdx = 1:numel(overloadLoads)
            paramsLoad = params;
            paramsLoad.v2x.BG.enable = true;
            paramsLoad.v2x.BG.probPerSlot = overloadLoads(loadIdx);
            statsLoad = simulateFAWADSIC_V2XTraffic(N, dataLength, simTime, positions, paramsLoad);

            for caseIdx = 1:nCases
                s = getStatsEntry(statsLoad, caseIdx);
                denmByW = extractMetricArray(s.v2x, 'DSR_DENM');
                denmDsrVsLoad(loadIdx, caseIdx) = max(denmByW, [], 'omitnan');
            end
        end

        figs.overload = figure('Name','V2X Overload Behavior', ...
            'Color','w', 'Visible', char(opt.Visible));
        ax = axes(figs.overload);
        hold(ax, 'on');
        colors = lines(nCases);
        for caseIdx = 1:nCases
            plot(ax, overloadLoads, denmDsrVsLoad(:,caseIdx), '-o', ...
                'LineWidth', 1.5, 'Color', colors(caseIdx,:), ...
                'DisplayName', scenarioLabel);
        end
        xlabel(ax, 'Background Load Probability per Slot');
        ylabel(ax, 'DENM Deadline Survival Ratio');
        title(ax, 'Overload Behavior (best DENM DSR across W)');
        ylim(ax, [0 1]);
        grid(ax, 'on');
        legend(ax, 'Location', 'best');
    else
        figs.overload = [];
    end
end

function plotTrafficMetric(ax, W, metricsByWindow, fieldCAM, fieldDENM, fieldBG)
    hold(ax, 'on');
    plot(ax, W, extractMetricArray(metricsByWindow, fieldCAM), '-o', 'LineWidth', 1.5);
    plot(ax, W, extractMetricArray(metricsByWindow, fieldDENM), '-s', 'LineWidth', 1.5);
    plot(ax, W, extractMetricArray(metricsByWindow, fieldBG), '-d', 'LineWidth', 1.5);
end

function vals = extractMetricArray(metricsByWindow, fieldName)
    vals = nan(1, numel(metricsByWindow));
    for idx = 1:numel(metricsByWindow)
        if isfield(metricsByWindow(idx), fieldName)
            vals(idx) = metricsByWindow(idx).(fieldName);
        end
    end
end

function s = getStatsEntry(statsIn, idx)
    if numel(statsIn) >= idx && isfield(statsIn(idx), 'windowList') && ~isempty(statsIn(idx).windowList)
        s = statsIn(idx);
        return;
    end
    error('Missing stats entry for V2X traffic configuration %d.', idx);
end

function label = getTrafficScenarioLabel(params)
    parts = {};
    if params.v2x.CAM.enable
        parts{end+1} = sprintf('CAM %.3g s', params.v2x.CAM.period_s);
    end
    if params.v2x.DENM.enable
        parts{end+1} = sprintf('DENM %.3g s mean', params.v2x.DENM.meanInterArrival_s);
    end
    if params.v2x.BG.enable
        parts{end+1} = sprintf('BG %.3g prob/slot', params.v2x.BG.probPerSlot);
    end
    if isempty(parts)
        label = 'No V2X traffic enabled';
    else
        label = strjoin(parts, ', ');
    end
end

function [nRows, nCols] = bestTileShape(nTiles)
    nCols = ceil(sqrt(nTiles));
    nRows = ceil(nTiles / nCols);
end
