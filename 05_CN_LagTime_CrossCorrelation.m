% ==========================================================================
% 05_CN_LagTime_CrossCorrelation.m
%
% 목적: CN(유출곡선지수)과 LagTime(지연시간) 간의 직접적인 상관관계 분석
%       - 산점도 + 선형 추세선
%
% 열 이름 키워드:
%   - CN      : 'CN'
%   - LagTime : 'LagTime'
% ==========================================================================

close all; clear; clc;

% --------------------------------------------------------------------------
% 1. 데이터 불러오기
% --------------------------------------------------------------------------
[file, path] = uigetfile({'*.xls;*.xlsx', 'Excel Files'}, '통합 엑셀 파일을 선택하세요');
if isequal(file, 0)
    error('파일 선택이 취소되었습니다.');
end
filepath = fullfile(path, file);

opts = detectImportOptions(filepath);
opts.VariableNamingRule = 'preserve';
data = readtable(filepath, opts);
vars = data.Properties.VariableNames;

% --------------------------------------------------------------------------
% 2. 변수 추출 및 결측치 제거
% --------------------------------------------------------------------------
idx_CN = find(contains(vars, 'CN',      'IgnoreCase', true), 1);
idx_LT = find(contains(vars, 'LagTime', 'IgnoreCase', true), 1);

if isempty(idx_CN) || isempty(idx_LT)
    error('CN 또는 LagTime 열을 찾지 못했습니다. 열 이름을 확인하세요.');
end

CN      = data{:, idx_CN};
LagTime = data{:, idx_LT};

valid = ~isnan(CN) & ~isnan(LagTime);
CN_v  = CN(valid);
LT_v  = LagTime(valid);
n     = length(CN_v);

if n < 3
    error('유효 데이터가 3개 미만입니다.');
end

% --------------------------------------------------------------------------
% 3. 피어슨 상관분석
% --------------------------------------------------------------------------
[R, ~] = corrcoef(CN_v, LT_v);
r_val  = R(1,2);

if r_val > 0
    rel_str = '정비례: CN이 클수록 지연시간도 길어지는 경향';
else
    rel_str = '반비례: CN이 클수록 지연시간이 짧아지는 경향';
end

% --------------------------------------------------------------------------
% 4. 결과 출력
% --------------------------------------------------------------------------
fprintf('\n■ CN vs LagTime 교차 상관분석 결과\n');
fprintf('%s\n', repmat('-', 1, 50));
fprintf('유효 데이터 수 (n) : %d\n', n);
fprintf('상관계수 (r)       : %.3f\n', r_val);
fprintf('관계 특성          : %s\n', rel_str);
fprintf('%s\n', repmat('=', 1, 50));

% --------------------------------------------------------------------------
% 5. 시각화
% --------------------------------------------------------------------------
figure('Name', 'CN vs LagTime', 'Color', 'w', 'Position', [100, 100, 700, 500]);

scatter(CN_v, LT_v, 60, 'filled', ...
    'MarkerFaceColor', [0.20 0.60 0.50], 'MarkerEdgeColor', 'k', 'LineWidth', 1);
hold on; grid on;

p_fit  = polyfit(CN_v, LT_v, 1);
x_fit  = linspace(min(CN_v), max(CN_v), 200);
plot(x_fit, polyval(p_fit, x_fit), 'r-', 'LineWidth', 2);

xlabel('CN (유출곡선지수)',     'FontSize', 12, 'FontWeight', 'bold');
ylabel('LagTime (지연시간)',    'FontSize', 12, 'FontWeight', 'bold');
title('CN(유출곡선지수) vs LagTime(지연시간) 상관관계', 'FontSize', 14, 'FontWeight', 'bold');
legend({'유역별 데이터', sprintf('선형 추세선  (r = %.3f)', r_val)}, ...
    'Location', 'northwest', 'FontSize', 11);

hold off;
