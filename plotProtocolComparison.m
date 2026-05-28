function plotProtocolComparison(statsFAWADS, statsCSMA, statsALOHA, parTimeList)
% Compare FAWADS, CSMA/CA, and Slotted ALOHA performance

    bfawads = zeros(1, numel(parTimeList));
    bcsma   = zeros(1, numel(parTimeList));
    baloha  = zeros(1, numel(parTimeList));

    dfawads = zeros(1, numel(parTimeList));
    dcsma   = zeros(1, numel(parTimeList));
    daloha  = zeros(1, numel(parTimeList));

    for k = 1:numel(parTimeList)
        pt = parTimeList(k);

        sF = getStatByParTime(statsFAWADS, pt);
        sC = getStatByParTime(statsCSMA,   pt);
        sA = getStatByParTime(statsALOHA,  pt);

        bfawads(k) = max(sF.sendRate);
        bcsma(k)   = max(sC.sendRate);
        baloha(k)  = sA.sendRate;

        dfawads(k) = sF.minDelay;
        dcsma(k)   = sC.delayAve;
        daloha(k)  = sA.delayAve;
    end

    % Throughput figure
    figure; hold on;
    plot(parTimeList, bfawads, '-o', 'LineWidth', 2, 'DisplayName', 'FAWADS (best)');
    plot(parTimeList, bcsma,   '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    plot(parTimeList, baloha,  '-d', 'LineWidth', 2, 'DisplayName', 'Slotted ALOHA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Throughput (succ. fragments/slot)', 'FontSize', 14);
    title('Protocol Throughput Comparison', 'FontSize', 16);
    legend('Location', 'bestoutside');
    grid on;

    % Delay figure
    figure; hold on;
    plot(parTimeList, dfawads, '-o', 'LineWidth', 2, 'DisplayName', 'FAWADS (best delay)');
    plot(parTimeList, dcsma,   '-s', 'LineWidth', 2, 'DisplayName', 'CSMA/CA');
    plot(parTimeList, daloha,  '-d', 'LineWidth', 2, 'DisplayName', 'Slotted ALOHA');
    xlabel('Generation time [slots]', 'FontSize', 14);
    ylabel('Average Delay (slots)', 'FontSize', 14);
    title('Protocol Delay Comparison', 'FontSize', 16);
    legend('Location', 'bestoutside');
    grid on;
end

function s = getStatByParTime(stats, parTime)
% Works with both:
% 1) new style: stats(i).parTime exists
% 2) old style: stats(parTime)

    if isempty(stats)
        error('The stats input is empty.');
    end

    if isfield(stats, 'parTime') && ~isempty([stats.parTime])
        idx = find([stats.parTime] == parTime, 1, 'first');
        if isempty(idx)
            error('Could not find parTime = %g in stats.', parTime);
        end
    else
        idx = parTime;
        if idx > numel(stats)
            error('parTime = %g exceeds stats length = %d.', parTime, numel(stats));
        end
    end

    s = stats(idx);
end
