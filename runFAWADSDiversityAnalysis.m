function results = runFAWADSDiversityAnalysis(N, dataLength, simTime, positions, params, Dlist)
%RUNFAWADSDIVERSITYANALYSIS
% Sweep diversity order and compare throughput/delay with and without SIC.
%
% INPUTS:
%   N, dataLength, simTime, positions, params
%       Same inputs used by simulateFAWADSIC(...)
%
%   Dlist
%       Vector of diversity orders to test, e.g. 1:5
%
% OUTPUT:
%   results
%       Struct containing raw stats, best throughput, best delay, and plots.
%
% NOTES:
%   1) This function assumes simulateFAWADSIC stores results as stats(parTime)
%      rather than stats(idx).
%   2) Best throughput is taken as max(sendRate) over contention window W.
%   3) Best delay is taken as min(delayAve) over contention window W.

    if nargin < 6 || isempty(Dlist)
        Dlist = 1:min(5, params.numChannel);
    end

    parList = params.parTimeList(:).';   % row vector
    numD    = numel(Dlist);
    numP    = numel(parList);

    % Preallocate result containers
    results = struct();
    results.Dlist   = Dlist;
    results.parList = parList;

    results.noSIC  = initModeStruct(numP, numD);
    results.withSIC = initModeStruct(numP, numD);

    % ---------------------------
    % Run sweeps: without SIC
    % ---------------------------
    for d = 1:numD
        paramsTmp = params;
        paramsTmp.numDiversity = Dlist(d);
        paramsTmp.enableSIC    = false;

        stats = simulateFAWADSIC(N, dataLength, simTime, positions, paramsTmp);
        results.noSIC.rawStats{d} = stats;

        for p = 1:numP
            pt = parList(p);   % IMPORTANT: stats indexed by actual parTime value

            sr = stats(pt).sendRate(:);
            da = stats(pt).delayAve(:);
            wl = stats(pt).windowList(:);

            % Best throughput over W
            [bestThr, idxThr] = max(sr);
            delayAtBestThr = da(idxThr);
            W_atBestThr    = wl(idxThr);

            % Best delay over W
            finiteMask = isfinite(da);
            if any(finiteMask)
                finiteIdx = find(finiteMask);
                [bestDly, localIdx] = min(da(finiteMask));
                idxDly = finiteIdx(localIdx);

                thrAtBestDly = sr(idxDly);
                W_atBestDly  = wl(idxDly);
            else
                bestDly      = inf;
                thrAtBestDly = NaN;
                W_atBestDly  = NaN;
            end

            results.noSIC.bestThroughput(p,d)    = bestThr;
            results.noSIC.delayAtBestThroughput(p,d) = delayAtBestThr;
            results.noSIC.bestDelay(p,d)         = bestDly;
            results.noSIC.throughputAtBestDelay(p,d) = thrAtBestDly;
            results.noSIC.bestW_for_Throughput(p,d)  = W_atBestThr;
            results.noSIC.bestW_for_Delay(p,d)       = W_atBestDly;
        end
    end

    % ---------------------------
    % Run sweeps: with SIC
    % ---------------------------
    for d = 1:numD
        paramsTmp = params;
        paramsTmp.numDiversity = Dlist(d);
        paramsTmp.enableSIC    = true;

        stats = simulateFAWADSIC(N, dataLength, simTime, positions, paramsTmp);
        results.withSIC.rawStats{d} = stats;

        for p = 1:numP
            pt = parList(p);   % IMPORTANT: stats indexed by actual parTime value

            sr = stats(pt).sendRate(:);
            da = stats(pt).delayAve(:);
            wl = stats(pt).windowList(:);

            % Best throughput over W
            [bestThr, idxThr] = max(sr);
            delayAtBestThr = da(idxThr);
            W_atBestThr    = wl(idxThr);

            % Best delay over W
            finiteMask = isfinite(da);
            if any(finiteMask)
                finiteIdx = find(finiteMask);
                [bestDly, localIdx] = min(da(finiteMask));
                idxDly = finiteIdx(localIdx);

                thrAtBestDly = sr(idxDly);
                W_atBestDly  = wl(idxDly);
            else
                bestDly      = inf;
                thrAtBestDly = NaN;
                W_atBestDly  = NaN;
            end

            results.withSIC.bestThroughput(p,d)    = bestThr;
            results.withSIC.delayAtBestThroughput(p,d) = delayAtBestThr;
            results.withSIC.bestDelay(p,d)         = bestDly;
            results.withSIC.throughputAtBestDelay(p,d) = thrAtBestDly;
            results.withSIC.bestW_for_Throughput(p,d)  = W_atBestThr;
            results.withSIC.bestW_for_Delay(p,d)       = W_atBestDly;
        end
    end

    % Aggregate averages across parTime values
    results.noSIC.avgBestThroughput   = mean(results.noSIC.bestThroughput, 1, 'omitnan');
    results.withSIC.avgBestThroughput = mean(results.withSIC.bestThroughput, 1, 'omitnan');

    results.noSIC.avgBestDelay   = colFiniteMean(results.noSIC.bestDelay);
    results.withSIC.avgBestDelay = colFiniteMean(results.withSIC.bestDelay);

    % Create plots
    makePlots(results);

    % Print a summary table to command window
    printSummary(results);

end

% ============================================================
% Helper: initialize struct
% ============================================================
function S = initModeStruct(numP, numD)
    S = struct();
    S.rawStats = cell(1, numD);

    S.bestThroughput        = NaN(numP, numD);
    S.delayAtBestThroughput = NaN(numP, numD);

    S.bestDelay             = Inf(numP, numD);
    S.throughputAtBestDelay = NaN(numP, numD);

    S.bestW_for_Throughput  = NaN(numP, numD);
    S.bestW_for_Delay       = NaN(numP, numD);

    S.avgBestThroughput     = NaN(1, numD);
    S.avgBestDelay          = NaN(1, numD);
end

% ============================================================
% Helper: finite mean by column
% ============================================================
function y = colFiniteMean(X)
    [nr, nc] = size(X);
    y = NaN(1, nc);
    for c = 1:nc
        vals = X(:,c);
        vals = vals(isfinite(vals));
        if ~isempty(vals)
            y(c) = mean(vals);
        end
    end
end

% ============================================================
% Helper: plotting
% ============================================================
function makePlots(results)

    Dlist   = results.Dlist;
    parList = results.parList;

    % 1) Average best throughput vs diversity order
    figure;
    plot(Dlist, results.noSIC.avgBestThroughput, '-o', 'LineWidth', 1.6); hold on;
    plot(Dlist, results.withSIC.avgBestThroughput, '-s', 'LineWidth', 1.6);
    grid on;
    xlabel('Diversity Order');
    ylabel('Average Best Throughput');
    title('Average Best Throughput vs Diversity Order');
    legend('No SIC', 'With SIC', 'Location', 'best');

    % 2) Average best delay vs diversity order
    figure;
    plot(Dlist, results.noSIC.avgBestDelay, '-o', 'LineWidth', 1.6); hold on;
    plot(Dlist, results.withSIC.avgBestDelay, '-s', 'LineWidth', 1.6);
    grid on;
    xlabel('Diversity Order');
    ylabel('Average Best Delay');
    title('Average Best Delay vs Diversity Order');
    legend('No SIC', 'With SIC', 'Location', 'best');

    % 3) Best throughput vs diversity order for each offered load (no SIC)
    figure; hold on;
    for p = 1:numel(parList)
        plot(Dlist, results.noSIC.bestThroughput(p,:), '-o', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('Generation time = %g slots', parList(p)));
    end
    grid on;
    xlabel('Diversity Order');
    ylabel('Best Throughput');
    title('Best Throughput vs Diversity Order (No SIC)');
    legend('Location', 'best');

    % 4) Best throughput vs diversity order for each offered load (with SIC)
    figure; hold on;
    for p = 1:numel(parList)
        plot(Dlist, results.withSIC.bestThroughput(p,:), '-s', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('Generation time = %g slots', parList(p)));
    end
    grid on;
    xlabel('Diversity Order');
    ylabel('Best Throughput');
    title('Best Throughput vs Diversity Order (With SIC)');
    legend('Location', 'best');

    % 5) Best delay vs diversity order for each offered load (no SIC)
    figure; hold on;
    for p = 1:numel(parList)
        plot(Dlist, results.noSIC.bestDelay(p,:), '-o', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('Generation time = %g slots', parList(p)));
    end
    grid on;
    xlabel('Diversity Order');
    ylabel('Best Delay');
    title('Best Delay vs Diversity Order (No SIC)');
    legend('Location', 'best');

    % 6) Best delay vs diversity order for each offered load (with SIC)
    figure; hold on;
    for p = 1:numel(parList)
        plot(Dlist, results.withSIC.bestDelay(p,:), '-s', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('Generation time = %g slots', parList(p)));
    end
    grid on;
    xlabel('Diversity Order');
    ylabel('Best Delay');
    title('Best Delay vs Diversity Order (With SIC)');
    legend('Location', 'best');
end

% ============================================================
% Helper: print summary
% ============================================================
function printSummary(results)

    Dlist = results.Dlist(:);

    T = table( ...
        Dlist, ...
        results.noSIC.avgBestThroughput(:), ...
        results.withSIC.avgBestThroughput(:), ...
        results.noSIC.avgBestDelay(:), ...
        results.withSIC.avgBestDelay(:), ...
        'VariableNames', { ...
            'DiversityOrder', ...
            'AvgBestThr_NoSIC', ...
            'AvgBestThr_WithSIC', ...
            'AvgBestDelay_NoSIC', ...
            'AvgBestDelay_WithSIC' ...
        });

    disp('==============================================================');
    disp('DIVERSITY ANALYSIS SUMMARY');
    disp(T);
    disp('==============================================================');
end
