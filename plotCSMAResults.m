function plotCSMAResults(statsCSMA, parTimeList)
%PLOTCSMARESULTS  Plot CSMA/CA throughput and delay for each parTime

    % Throughput figure
    figure; hold on;
    for k = 1:numel(parTimeList)
        p = parTimeList(k);
        entry = statsCSMA(p);
        W     = entry.windowList;    % or whatever your CSMA uses
        sr    = entry.sendRate;
        plot(W, sr, '-s', 'LineWidth',2, ...
             'DisplayName', sprintf('Generation time = %d slots', p));
    end
    xlabel('Contention Window W (slots)');
    ylabel('Throughput (succ. fragments/slot)');
    title('CSMA/CA Throughput vs. Window');
    legend('Location','bestoutside');
    grid on;

    % Delay figure
    figure; hold on;
    for k = 1:numel(parTimeList)
        p = parTimeList(k);
        entry = statsCSMA(p);
        W  = entry.windowList;
        da = entry.delayAve;
        plot(W, da, '-d', 'LineWidth',2, ...
             'DisplayName', sprintf('Generation time = %d slots', p));
    end
    xlabel('Contention Window W (slots)');
    ylabel('Average Delay (slots)');
    title('CSMA/CA Delay vs. Window');
    legend('Location','bestoutside');
    grid on;
end
