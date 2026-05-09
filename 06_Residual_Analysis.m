% ==========================================================================
% 06_Residual_Analysis.m
%
% 목적: HEC-HMS 모의 결과에 대한 오차(잔차) 분석
%       - [Part A] 공간적 오차 전파 분석 (노드별 독립/전파 오차 분리)
%       - [Part B] 시계열 표준화 잔차 분석 (수문곡선 기반 모델 평가)
%
% 사용 방법:
%   RUN_PART 변수를 'A', 'B', 또는 'both'로 설정하세요.
% ==========================================================================

close all; clear; clc;

RUN_PART = 'both';  % 'A' | 'B' | 'both'

if strcmp(RUN_PART, 'A') || strcmp(RUN_PART, 'both')
    run_spatial_error_analysis();
end

if strcmp(RUN_PART, 'B') || strcmp(RUN_PART, 'both')
    run_temporal_residual_analysis();
end


% ==========================================================================
% Part A: 공간적 오차 전파 분석
% ==========================================================================
function run_spatial_error_analysis()

fprintf('\n==============================\n');
fprintf('  [Part A] 공간적 오차 전파 분석\n');
fprintf('==============================\n');

% --------------------------------------------------------------------------
% 데이터 입력 (노드 순서: 상류 → 하류)
% --------------------------------------------------------------------------
names = {'Reach-5','Subbasin-1','Reach-4','Subbasin-21','Subbasin-4','Reach-12', ...
         'Subbasin-5','Reach-7','Subbasin-10','Subbasin-31','Reach-16','BreakPoint'};

types = {'R','S','R','S','S','R', ...
         'S','R','S','S','R','B'};

sim = [2529, 1013.2, 3583.7, 529.3, 341.3, 4333.6, ...
       122,  217.9,  137.3,  207.9, 634.2, 4452.6];

obs = [1910.66, 1597.51, 3283.86, 546.23, 340.36, 3784.62, ...
       129.51,  220,     141.36,  202.38, 521.81, 4521.25];

n         = length(names);
tot_err   = obs - sim;        % 총 오차 (양수: 과소예측, 음수: 과대예측)
prop_err  = zeros(1, n);
loc_err   = zeros(1, n);

% --------------------------------------------------------------------------
% 위상학적 오차 전파 (두 권역: 1001 남한강, 1002 평창강)
% --------------------------------------------------------------------------
last_R_1001 = 0;
last_R_1002 = 0;
basin       = 1001;

for i = 1:n
    if strcmp(names{i}, 'Subbasin-5'), basin = 1002; end

    switch types{i}
        case 'S'
            prop_err(i) = 0;
            loc_err(i)  = tot_err(i);

        case 'R'
            up_sum = 0;
            if basin == 1001
                if last_R_1001 > 0
                    up_sum = up_sum + tot_err(last_R_1001);
                end
                for j = (last_R_1001 + 1):(i - 1)
                    if strcmp(types{j}, 'S'), up_sum = up_sum + tot_err(j); end
                end
                last_R_1001 = i;
            else
                start_j = max(last_R_1002 + 1, find(strcmp(names, 'Subbasin-5'), 1));
                if last_R_1002 > 0
                    up_sum = up_sum + tot_err(last_R_1002);
                end
                for j = start_j:(i - 1)
                    if strcmp(types{j}, 'S'), up_sum = up_sum + tot_err(j); end
                end
                last_R_1002 = i;
            end
            prop_err(i) = up_sum;
            loc_err(i)  = tot_err(i) - prop_err(i);

        case 'B'
            prop_err(i) = tot_err(last_R_1001) + tot_err(last_R_1002);
            loc_err(i)  = tot_err(i) - prop_err(i);
    end
end

% --------------------------------------------------------------------------
% 95% 신뢰구간 (독립 오차 기준)
% --------------------------------------------------------------------------
mean_loc = mean(loc_err);
std_loc  = std(loc_err);
ci_upper = mean_loc + 1.96 * std_loc;
ci_lower = mean_loc - 1.96 * std_loc;

% --------------------------------------------------------------------------
% 결과 출력
% --------------------------------------------------------------------------
fprintf('%-15s | %10s | %12s | %10s\n', '노드명', '총 오차', '전파된 오차', '독립 오차');
fprintf('%s\n', repmat('-', 1, 55));
for i = 1:n
    fprintf('%-15s | %10.2f | %12.2f | %10.2f\n', names{i}, tot_err(i), prop_err(i), loc_err(i));
end
fprintf('%s\n', repmat('=', 1, 55));
fprintf('독립 오차 95%% CI : [%.2f, %.2f]  (단위: m³/s)\n', ci_lower, ci_upper);

% --------------------------------------------------------------------------
% 시각화
% --------------------------------------------------------------------------
figure('Name', '공간적 오차 전파 분석', 'Color', 'w', 'Position', [100, 100, 1100, 500]);
hold on; grid on;

b = bar(1:n, [loc_err', prop_err'], 'grouped');
b(1).FaceColor = [0.20 0.60 0.50];
b(2).FaceColor = [0.80 0.40 0.30];

plot(1:n, tot_err, '-ko', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'k');

yline(ci_upper, '--b', '95% CI (Upper)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
yline(ci_lower, '--b', '95% CI (Lower)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
yline(0, 'k-', 'LineWidth', 1);

xticks(1:n); xticklabels(names); xtickangle(45);
title('하천 네트워크 오차 전파 분석 (1001 남한강 & 1002 평창강)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('오차 잔차 (Obs - Sim,  m³/s)', 'FontSize', 11);
legend({'독립 오차 (Local)', '전파 오차 (Propagated)', '총 오차 (Total)'}, 'Location', 'northwest');
hold off;

end


% ==========================================================================
% Part B: 시계열 표준화 잔차 분석
% ==========================================================================
function run_temporal_residual_analysis()

fprintf('\n==============================\n');
fprintf('  [Part B] 시계열 잔차 분석\n');
fprintf('==============================\n');

% --------------------------------------------------------------------------
% 시간 벡터 (2020-09-03 04:00 ~ 09-04 02:00, 1시간 간격, 총 23스텝)
% --------------------------------------------------------------------------
time_arr = datetime(2020, 9, 3, 4, 0, 0) + hours(0:22)';

% --------------------------------------------------------------------------
% 모의/관측 유량 데이터 (단위: m³/s)
% --------------------------------------------------------------------------
sim_Q = [534.5; 636.8; 750.7; 889.3; 1071.1; 1310.7; 1598.5; 1934.4; 2351.3; ...
         2874.1; 3478.8; 4041.3; 4333.6; 4186.6; 3638.7; 2888.6; 2142.9; 1526.7; ...
         1072.1; 750.9; 524.2; 365.2; 254.5];

obs_Q = [58.27; 60.12; 59.88; 67.55; 79.5; 131.54; 159.52; 534.67; 1042.05; ...
         3116.52; 3771.21; 3569.93; 3784.62; 3037.58; 2766.93; 2457.05; 2107.77; ...
         1921.0; 1651.3; 1450.4; 1327.95; 1208.77; 1056.69];

n         = length(obs_Q);
residuals = obs_Q - sim_Q;

% --------------------------------------------------------------------------
% 모델 평가지표
% --------------------------------------------------------------------------
RMSE      = sqrt(mean(residuals.^2));
NSE       = 1 - sum(residuals.^2) / sum((obs_Q - mean(obs_Q)).^2);
R_mat     = corrcoef(obs_Q, sim_Q);
R_squared = R_mat(1,2)^2;

% --------------------------------------------------------------------------
% 표준화 잔차 계산 (leverage 기반)
% --------------------------------------------------------------------------
RSE          = sqrt(sum(residuals.^2) / (n - 2));
mean_sim     = mean(sim_Q);
SS_xx        = sum((sim_Q - mean_sim).^2);
hii          = (1/n) + (sim_Q - mean_sim).^2 / SS_xx;
std_residuals = residuals ./ (RSE .* sqrt(max(1 - hii, 0)));  % 음수 방지

% --------------------------------------------------------------------------
% 결과 출력
% --------------------------------------------------------------------------
fprintf('RMSE (평균 제곱근 오차) : %.2f m³/s\n', RMSE);
fprintf('NSE  (모형 효율 계수)   : %.3f\n', NSE);
fprintf('R²   (결정계수)         : %.3f\n', R_squared);
fprintf('%s\n', repmat('-', 1, 75));
fprintf('%-12s | %12s | %12s | %15s | %10s\n', '시간', '관측치(Obs)', '예측치(Sim)', '잔차', '표준화잔차');
fprintf('%s\n', repmat('-', 1, 75));
for i = 1:n
    fprintf('%s | %12.2f | %12.2f | %15.2f | %10.2f\n', ...
        datestr(time_arr(i), 'mm/dd HH:MM'), obs_Q(i), sim_Q(i), residuals(i), std_residuals(i));
end
fprintf('%s\n', repmat('=', 1, 75));

% --------------------------------------------------------------------------
% 시각화
% --------------------------------------------------------------------------
figure('Name', '수문곡선 및 표준화 잔차', 'Color', 'w', 'Position', [100, 100, 1200, 500]);

% 수문곡선 비교
subplot(1, 2, 1);
plot(time_arr, obs_Q, '-ko', 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', 'k', 'DisplayName', '관측 (Observed)');
hold on; grid on;
plot(time_arr, sim_Q, '-ro', 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', 'r', 'DisplayName', '모의 (Simulated)');
title(sprintf('수문곡선 비교\n(NSE=%.3f, R²=%.3f, RMSE=%.1f m³/s)', NSE, R_squared, RMSE), ...
    'FontSize', 11, 'FontWeight', 'bold');
xlabel('시간', 'FontSize', 11); ylabel('유량 (m³/s)', 'FontSize', 11);
legend('Location', 'northwest'); xtickformat('MM/dd HH:mm');

% 표준화 잔차
subplot(1, 2, 2);
stem(time_arr, std_residuals, 'k', 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
hold on; grid on;
yline(0,  'k-',  'LineWidth', 1);
yline( 3, 'r--', '이상치 기준 (+3)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
yline(-3, 'r--', '이상치 기준 (-3)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
title('시간별 표준화 잔차 (Standardized Residuals)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('시간', 'FontSize', 11); ylabel('표준화 잔차', 'FontSize', 11);
xtickformat('HH:mm'); ylim([-4, 4]);

end
