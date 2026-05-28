function plotFAWADSResults(statsFAWADS, parTimeList)
%PLOTFAWADSRESULTS  Plot FAWADS throughput and delay for each parTime
%   Inputs:
%     statsFAWADS : struct array from implementFAWADfunct
%     parTimeList : vector of parTime values
%
%   Generates two figures:
%     1) Throughput vs. contention window for each parTime
%     2) Average delay vs. contention window for each parTime

    % Throughput figure
    figure;
    hold on;
    for pIdx = 1:length(parTimeList)
        p = parTimeList(pIdx);
        entry = statsFAWADS(p);
        W = entry.windowList;
        sr = entry.sendRate;
        plot(W, sr, '-o', 'LineWidth', 2, ...
             'DisplayName', sprintf('Generation time = %d slots', p));
    end
    xlabel('Contention Window W (slots)', 'FontSize', 14);
    ylabel('Throughput (succ. fragments/slot)', 'FontSize', 14);
    title('FAWADS Throughput vs. Contention Window', 'FontSize', 16);
    legend('Location', 'bestoutside');
    grid on;

    % Delay figure
    figure;
    hold on;
    for pIdx = 1:length(parTimeList)
        p = parTimeList(pIdx);
        entry = statsFAWADS(p);
        W = entry.windowList;
        da = entry.delayAve;
        plot(W, da, '-s', 'LineWidth', 2, ...
             'DisplayName', sprintf('Generation time = %d slots', p));
    end
    xlabel('Contention Window W (slots)', 'FontSize', 14);
    ylabel('Average Delay (slots)', 'FontSize', 14);
    title('FAWADS Delay vs. Contention Window', 'FontSize', 16);
    legend('Location', 'bestoutside');
    grid on;
end
