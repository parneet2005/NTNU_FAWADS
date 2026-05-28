function plotCSMAandCompare(statsFAWADS, statsCSMA, parTimeList)
%PLOTCSMAANDCOMPARE  Plot CSMA results and compare with FAWADS
%   Inputs:
%     statsFAWADS : struct array from implementFAWADfunct
%     statsCSMA   : struct array from simulateCSMACA
%     parTimeList : vector of parTime values

    % === Plot CSMA/CA results ===
    % Extract throughput and delay for CSMA
    srCSMA = arrayfun(@(p) statsCSMA(p).sendRate, parTimeList);
    daCSMA = arrayfun(@(p) statsCSMA(p).delayAve, parTimeList);

    % Throughput vs generation time
    figure;
    plot(parTimeList, srCSMA, '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Throughput (succ. fragments/slot)', 'FontSize', 14);
    title('CSMA/CA Throughput vs Generation Time', 'FontSize', 16);
    grid on;

    % Delay vs generation time
    figure;
    plot(parTimeList, daCSMA, '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Average Delay (slots)', 'FontSize', 14);
    title('CSMA/CA Delay vs Generation Time', 'FontSize', 16);
    grid on;

    % === Compare FAWADS & CSMA ===
    % For FAWADS, take peak throughput and corresponding best delay per parTime
    bfawads = arrayfun(@(p) max(statsFAWADS(p).sendRate), parTimeList);
    dfawads = arrayfun(@(p) statsFAWADS(p).minDelay, parTimeList);

    % Combined throughput comparison
    figure;
    hold on;
    plot(parTimeList, bfawads, '-o', 'LineWidth', 2, 'DisplayName', 'FAWADS (best)');
    plot(parTimeList, srCSMA, '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Throughput (succ. fragments/slot)', 'FontSize', 14);
    title('FAWADS vs CSMA/CA Throughput', 'FontSize', 16);
    legend('Location','bestoutside');
    grid on;

    % Combined delay comparison
    figure;
    hold on;
    plot(parTimeList, dfawads, '-o', 'LineWidth', 2, 'DisplayName', 'FAWADS (best delay)');
    plot(parTimeList, daCSMA, '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Average Delay (slots)', 'FontSize', 14);
    title('FAWADS vs CSMA/CA Delay', 'FontSize', 16);
    legend('Location','bestoutside');
    grid on;
end
