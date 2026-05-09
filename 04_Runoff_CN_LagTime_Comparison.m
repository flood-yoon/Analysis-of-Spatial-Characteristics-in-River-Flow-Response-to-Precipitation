% ==========================================================================
% 04_Runoff_CN_LagTime_Comparison.m
%
% 목적: Final_Runoff_C와 CN, LagTime 간의 피어슨 상관분석 및 유의성 시각화
%       - Figure 1: 산점도 + 선형 추세선 (CN, LagTime 각각)
%       - Figure 2: p-value 막대그래프 + 유의수준(0.05) 기준선
%
% 열 이름 자동 매칭 키워드:
%   - Runoff : 'Final'
%   - CN     : 'CN'
%   - LagTime: 'Lag'
%   → 열 이름이 다를 경우 아래 키워드를 수정하세요.
%
% 활용 예시:
%   - CN=99 이상 이상치 제거 전/후 비교 시 파일만 교체해서 재실행
% ==========================================================================

close all; clear; clc;

% --------------------------------------------------------------------------
% 1. 데이터 불러오기
% --------------------------------------------------------------------------
[file, path] = uigetfile({'*.xlsx;*.xls', 'Excel Files'}, '분석할 엑셀 파일을 선택하세요');
if isequal(file, 0)
    error('파일 선택이 취소되었습니다.');
end
filepath = fullfile(path, file);

try
    opts = detectImportOptions(filepath);
    opts.VariableNamingRule = 'preserve';
    data = readtable(filepath, opts);
catch
    error('[오류] 파일을 읽을 수 없습니다. 엑셀이 열려 있다면 닫고 다시 실행하세요.');
end

vars = data.Properties.VariableNames;

% --------------------------------------------------------------------------
% 2. 열 자동 매칭
% --------------------------------------------------------------------------
fCol = @(key) data{:, find(contains(vars, key, 'IgnoreCase', true), 1)};

try
    Runoff = fCol('Final');
    CN     = fCol('CN');
    LT     = fCol('Lag');
catch
    error('열 이름 매칭 실패. Final / CN / Lag 키워드를 포함하는 열이 있는지 확인하세요.');
end

% --------------------------------------------------------------------------
% 3. 결측치 제거
% --------------------------------------------------------------------------
valid  = ~isnan(Runoff) & ~isnan(CN) & ~isnan(LT);
Ro_v   = Runoff(valid);
CN_v   = CN(valid);
LT_v   = LT(valid);
n      = length(Ro_v);

if n < 3
    error('유효 데이터가 3개 미만입니다.');
end

% --------------------------------------------------------------------------
% 4. 피어슨 상관분석
% --------------------------------------------------------------------------
[R1, P1] = corrcoef(Ro_v, CN_v);
r_CN = R1(1,2);  p_CN = P1(1,2);

[R2, P2] = corrcoef(Ro_v, LT_v);
r_LT = R2(1,2);  p_LT = P2(1,2);

sig_CN = get_sig_label(p_CN);
sig_LT = get_sig_label(p_LT);

% --------------------------------------------------------------------------
% 5. 결과 출력
% --------------------------------------------------------------------------
fprintf('\n■ Runoff vs CN / LagTime 상관분석 결과\n');
fprintf('%s\n', repmat('-', 1, 55));
fprintf('유효 데이터 수 (n) : %d\n', n);
fprintf('%s\n', repmat('-', 1, 55));
fprintf('%-20s : r = %6.3f | p = %.4f  %s\n', 'Runoff vs CN',      r_CN, p_CN, sig_CN);
fprintf('%-20s : r = %6.3f | p = %.4f  %s\n', 'Runoff vs LagTime', r_LT, p_LT, sig_LT);
fprintf('%s\n', repmat('=', 1, 55));

% --------------------------------------------------------------------------
% 6. Figure 1: 산점도 + 선형 추세선
% --------------------------------------------------------------------------
figure('Name', '산점도 비교 (CN & LagTime)', 'Color', 'w', 'Position', [100, 100, 1000, 450]);

subplot(1, 2, 1);
plot_scatter(CN_v, Ro_v, [0.20 0.60 0.50], ...
    sprintf('Runoff\\_C vs CN\n(r = %.3f, p = %.3f, n = %d)', r_CN, p_CN, n), ...
    'CN (유출곡선지수)', 'Final\_Runoff\_C');

subplot(1, 2, 2);
plot_scatter(LT_v, Ro_v, [0.80 0.40 0.30], ...
    sprintf('Runoff\\_C vs LagTime\n(r = %.3f, p = %.3f, n = %d)', r_LT, p_LT, n), ...
    'LagTime (지연시간)', 'Final\_Runoff\_C');

% --------------------------------------------------------------------------
% 7. Figure 2: p-value 막대그래프
% --------------------------------------------------------------------------
figure('Name', 'p-value 유의성 검정', 'Color', 'w', 'Position', [150, 150, 600, 450]);

b = bar([p_CN, p_LT], 'FaceColor', [0.30 0.40 0.60], 'EdgeColor', 'k', 'LineWidth', 1.2);
b.FaceAlpha = 0.8;
hold on; grid on;

% 유의수준 기준선 (p = 0.05)
plot([0.5, 2.5], [0.05, 0.05], 'r--', 'LineWidth', 2);
text(0.6, 0.055, '유의수준 p = 0.05', 'Color', 'r', 'FontSize', 11, 'FontWeight', 'bold');

% 막대 위 텍스트
text(1, p_CN + 0.02, sprintf('p = %.4f\n%s', p_CN, sig_CN), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
text(2, p_LT + 0.02, sprintf('p = %.4f\n%s', p_LT, sig_LT), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');

set(gca, 'XTick', 1:2, 'XTickLabel', {'Runoff vs CN', 'Runoff vs LagTime'}, ...
    'FontSize', 11, 'FontWeight', 'bold');
ylabel('p-value', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('매개변수별 통계적 유의성 검정 (n = %d)', n), 'FontSize', 13, 'FontWeight', 'bold');
ylim([0, max([p_CN, p_LT]) + 0.1]);


% ==========================================================================
% 로컬 함수
% ==========================================================================

function plot_scatter(x, y, color, title_str, xlabel_str, ylabel_str)
    scatter(x, y, 65, 'filled', 'MarkerFaceColor', color, 'MarkerEdgeColor', 'k');
    hold on; grid on;
    p_fit = polyfit(x, y, 1);
    x_fit = linspace(min(x), max(x), 200);
    plot(x_fit, polyval(p_fit, x_fit), 'r-', 'LineWidth', 2);
    title(title_str, 'FontSize', 12, 'FontWeight', 'bold');
    xlabel(xlabel_str, 'FontSize', 11);
    ylabel(ylabel_str, 'FontSize', 11);
end

function label = get_sig_label(p)
    if p < 0.01,      label = '** (매우 유의함)';
    elseif p < 0.05,  label = '*  (유의함)';
    else,             label = 'ns (유의하지 않음)';
    end
end
