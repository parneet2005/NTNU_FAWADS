function plotFAWADSDiversityVsW(results, parTimesToPlot)
% Plot throughput vs W and delay vs W for different diversity orders

    if nargin < 2 || isempty(parTimesToPlot)
        parTimesToPlot = results.parTimeList;
    end

    nPlot = numel(parTimesToPlot);
    figure;
    tiledlayout(nPlot, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    for p = 1:nPlot
        parTime = parTimesToPlot(p);

        % find matching parTime index
        pIdx = find(results.parTimeList == parTime, 1);
        if isempty(pIdx)
            error('generationtime=%g not found in results.parTimeList', parTime);
        end

        % -------- Throughput vs W --------
        nexttile;
        hold on;
        for dIdx = 1:numel(results.diversityList)
            s = results.byDiversity(dIdx).stats(pIdx);
            plot(s.windowList, s.sendRate, 'LineWidth', 1.5, ...
                'DisplayName', sprintf('D = %d', results.diversityList(dIdx)));
        end
        xlabel('W');
        ylabel('Throughput');
        title(sprintf('Throughput vs W (Generation time = %g)', parTime));
        grid on;
        legend('Location','best');
        hold off;

        % -------- Delay vs W --------
        nexttile;
        hold on;
        for dIdx = 1:numel(results.diversityList)
            s = results.byDiversity(dIdx).stats(pIdx);
            plot(s.windowList, s.delayAve, 'LineWidth', 1.5, ...
                'DisplayName', sprintf('D = %d', results.diversityList(dIdx)));
        end
        xlabel('W');
        ylabel('Average delay');
        title(sprintf('Delay vs W (Generation time = %g)', parTime));
        grid on;
        legend('Location','best');
        hold off;
    end
end