function plotWindowLatencyAndRate(statsFAWADS, parTimesToShow)
% Puts success rate (left y) and average latency (right y) vs. window W.
% parTimesToShow: e.g., [3 10] to reproduce the two panels in your example.

    if nargin < 2 || isempty(parTimesToShow)
        parTimesToShow = [3 10];
    end

    % Precompute axis ranges so subplots share scales
    srMax = 0; latMax = 0;
    for p = parTimesToShow
        s = statsFAWADS(p);
        srMax  = max(srMax,  max(s.sendRate));
        latMax = max(latMax, max(s.delayAve));
    end
    srMax  = srMax * 1.1;      % headroom
    latMax = latMax * 1.1;

    f = figure('Color','w');
    tl = tiledlayout(1, numel(parTimesToShow), 'TileSpacing','compact','Padding','compact');
    title(tl, 'Fig.1 Relationships of Window with Latency and Data rate', ...
          'FontSize',16,'FontWeight','bold');

    for k = 1:numel(parTimesToShow)
        p = parTimesToShow(k);
        s = statsFAWADS(p);
        W = s.windowList;
        SR = s.sendRate;    % Success rate [times/slot]
        LAT = s.delayAve;   % Average latency [slot]

        ax = nexttile; grid(ax,'on'); hold(ax,'on');

        yyaxis(ax,'left');
        h1 = plot(W, SR, 'o--', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                  'DisplayName', 'Success Rate');
        ylabel('Success Rate [times/slot]');
        ylim([0, max(1,srMax)]);

        yyaxis(ax,'right');
        h2 = plot(W, LAT, 'd--', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                  'DisplayName', 'Average Latency');
        ylabel('Average Latency [slot]');
        ylim([0, max(1,latMax)]);

        xlabel('Window Number');
        legend([h1 h2],'Location','best');

        % Panel caption (Japanese style used in your sample)
        txt = sprintf('データ生起間隔の最大値：%d slots', p);
        text(0.5, -0.18, txt, 'Units','normalized', ...
             'HorizontalAlignment','center','FontSize',11);
    end
end
