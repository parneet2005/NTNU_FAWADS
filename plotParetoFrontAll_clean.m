function fig = plotParetoFrontAll_clean(details, varargin)

p = inputParser;
p.addParameter('ProtocolName',"Protocol", @(s)ischar(s)||isstring(s));
p.addParameter('AnnotateEvery', 3, @(x)isscalar(x)&&x>=1);
p.parse(varargin{:});
opt = p.Results;

fig = figure('Name', string(opt.ProtocolName) + " Pareto (smoothed, clean)");
hold on; grid on;
xlabel('Latency (smoothed)'); ylabel('Throughput (smoothed)');
title(string(opt.ProtocolName) + " Pareto front (maximize throughput, minimize latency)");

for k = 1:numel(details)
    W  = details(k).W(:);
    Ts = details(k).T_smooth(:);
    Ls = details(k).L_smooth(:);
    pIdx = details(k).paretoIdx(:);

    % sort Pareto points by latency for a clean polyline
    [Lp, ord] = sort(Ls(pIdx));
    pIdx = pIdx(ord);
    Tp = Ts(pIdx);

    label = sprintf('Packet generation time = %g', details(k).parTime);

    % plot Pareto front only
    plot(Lp, Tp, '-o', 'LineWidth', 1.5, 'DisplayName', label);

    % annotate CW values on the Pareto front (sparse)
    step = opt.AnnotateEvery;
    for ii = 1:step:numel(pIdx)
        i = pIdx(ii);
        text(Ls(i), Ts(i), sprintf('  W=%g', W(i)), 'FontSize', 8);
    end

    % highlight chosen Wtrade
    Wtrade = details(k).Wtrade;
    iTrade = find(W == Wtrade, 1);
    if ~isempty(iTrade)
        plot(Ls(iTrade), Ts(iTrade), 'p', 'MarkerSize', 12, 'LineWidth', 2, ...
             'HandleVisibility','off');
    end
end

legend('Location','best');
end
