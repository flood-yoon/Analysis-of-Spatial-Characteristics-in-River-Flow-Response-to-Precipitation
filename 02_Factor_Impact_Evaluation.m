% ==========================================================================
% 02_Factor_Impact_Evaluation.m
%
% 목적: CN(유출곡선지수) 및 LagTime(지연시간)에 대한 지형/임상/토양/경사 인자의
%       피어슨 상관분석 및 영향도 평가
%
% 분석 항목:
%   [Part A] CN     vs 지형/임상 인자 (임상 면적은 유역면적 비율로 변환)
%   [Part B] LagTime vs 지형/임상 인자 (동일 방식)
%   [Part C] CN     vs 토양/경사/하천 인자
%   [Part D] LagTime vs 토양/경사/하천 인자
%
% 열 이름 규칙 (엑셀 파일에 맞게 수정):
%   - CN 열      : 'asdf.CN'
%   - LagTime 열 : 'asdf.LagTime'
%   - 유역면적 열 : '통합.csv.유역면적' 또는 '표준유역.csv.유역면적(Km^2)'
% ==========================================================================

close all; clear; clc;

% --------------------------------------------------------------------------
% 1. 데이터 불러오기
% --------------------------------------------------------------------------
[file, path] = uigetfile({'*.xls;*.xlsx', 'Excel Files'}, '분석할 통합 엑셀 파일을 선택하세요');
if isequal(file, 0)
    error('파일 선택이 취소되었습니다.');
end
filepath = fullfile(path, file);

opts = detectImportOptions(filepath);
opts.VariableNamingRule = 'preserve';
data = readtable(filepath, opts);
vars = data.Properties.VariableNames;

% 열 이름으로 데이터 유연하게 추출
getCol = @(key) data{:, find(contains(vars, key, 'IgnoreCase', true), 1, 'last')};

% --------------------------------------------------------------------------
% 2. 종속 변수 및 유역면적 추출
% --------------------------------------------------------------------------
CN      = getCol('CN');
LagTime = getCol('LagTime');
Area    = getCol('유역면적');

% --------------------------------------------------------------------------
% 3. [Part A & B] 지형/임상 인자 상관분석
%    - 절대값 인자: 평균표고, 평균경사, 최고표고
%    - 임상 인자: 유역면적 비율(%)로 변환
% --------------------------------------------------------------------------
forest_factors = {'1영급', '2영급', '3영급', '4영급', '5영급', '6영급', ...
                  'NoData', '치수', '소경목', '중경목', '대경목', ...
                  '소밀도(소)', '중밀도(중)', '소밀도(밀)'};

X_abs = [getCol('유역평균표고'), getCol('유역평균경사'), getCol('유역내 최고표고')];

n_f = length(forest_factors);
X_ratio = zeros(height(data), n_f);
for i = 1:n_f
    X_ratio(:, i) = getCol(forest_factors{i}) ./ Area;
end

X_AB = [X_abs, X_ratio];
varNames_AB = [{'평균표고', '평균경사', '최고표고'}, ...
               strcat(forest_factors, '_비율')];

fprintf('\n[Part A] CN vs 지형/임상 인자\n');
r_A = compute_and_print(X_AB, CN, varNames_AB);
plot_bar(r_A, varNames_AB, 'CN(유출지수) vs 지형/임상 인자 상관계수', 'CN_지형임상');

fprintf('\n[Part B] LagTime vs 지형/임상 인자\n');
r_B = compute_and_print(X_AB, LagTime, varNames_AB);
plot_bar(r_B, varNames_AB, 'LagTime(지연시간) vs 지형/임상 인자 상관계수', 'LagTime_지형임상');

% --------------------------------------------------------------------------
% 4. [Part C & D] 토양/경사/하천 인자 상관분석
%    - 하천총길이, 유로연장: 절대값 사용
%    - 토양, 경사 구간: 유역면적 비율(%)로 변환
% --------------------------------------------------------------------------
StreamLen   = getCol('하천총길이');
ChannelLen  = getCol('유로연장');

Soil_SandyLoam = getCol('사양토') ./ Area;
Soil_Loam      = getCol('양토')   ./ Area;
Soil_SiltLoam  = getCol('미사질양토') ./ Area;

slope_cols = {'0to10','10to20','20to30','30to40','40to50', ...
              '50to60','60to70','70to80','80to90','90to100', ...
              '0to30','30to60','60to100'};

n_s = length(slope_cols);
X_slope = zeros(height(data), n_s);
for i = 1:n_s
    X_slope(:, i) = getCol(slope_cols{i}) ./ Area;
end

X_CD = [Area, StreamLen, ChannelLen, Soil_SandyLoam, Soil_Loam, Soil_SiltLoam, X_slope];
varNames_CD = [{'유역면적', '하천총길이', '유로연장', '사양토%', '양토%', '미사질양토%'}, ...
               strcat('경사_', slope_cols, '%')];

fprintf('\n[Part C] CN vs 토양/경사/하천 인자\n');
r_C = compute_and_print(X_CD, CN, varNames_CD);
plot_bar(r_C, varNames_CD, 'CN(유출지수) vs 토양/경사/하천 인자 상관계수', 'CN_토양경사');

fprintf('\n[Part D] LagTime vs 토양/경사/하천 인자\n');
r_D = compute_and_print(X_CD, LagTime, varNames_CD);
plot_bar(r_D, varNames_CD, 'LagTime(지연시간) vs 토양/경사/하천 인자 상관계수', 'LagTime_토양경사');


% ==========================================================================
% 로컬 함수
% ==========================================================================

function r_vals = compute_and_print(X, y, varNames)
% 각 인자와 y 간의 피어슨 상관계수 계산 및 출력
    valid = ~isnan(y) & ~any(isnan(X), 2);
    y_v   = y(valid);
    X_v   = X(valid, :);
    n_var = size(X_v, 2);
    r_vals = zeros(n_var, 1);

    fprintf('%-22s | %10s | %s\n', '항목명', 'r', '관계 특성');
    fprintf('%s\n', repmat('-', 1, 50));

    for i = 1:n_var
        R = corrcoef(X_v(:, i), y_v);
        r_vals(i) = R(1,2);

        if r_vals(i) > 0.3,      rel = '강한 정비례(+)';
        elseif r_vals(i) > 0,    rel = '약한 정비례(+)';
        elseif r_vals(i) < -0.3, rel = '강한 반비례(-)';
        else,                     rel = '약한 반비례(-)';
        end

        fprintf('%-22s | %10.3f | %s\n', varNames{i}, r_vals(i), rel);
    end
    fprintf('%s\n', repmat('=', 1, 50));
end

function plot_bar(r_vals, varNames, title_str, fig_name)
% 상관계수 막대그래프 출력 (양수: 청록, 음수: 적색)
    figure('Name', fig_name, 'Color', 'w', 'Position', [50, 100, 1400, 500]);
    b = bar(r_vals, 'FaceColor', 'flat', 'EdgeColor', 'none');

    for i = 1:length(r_vals)
        if r_vals(i) >= 0
            b.CData(i,:) = [0.20 0.60 0.50];
        else
            b.CData(i,:) = [0.80 0.30 0.30];
        end
    end

    xticks(1:length(varNames));
    xticklabels(varNames);
    xtickangle(45);
    ylabel('상관계수 (Pearson r)', 'FontSize', 11);
    title(title_str, 'FontSize', 13, 'FontWeight', 'bold');
    yline(0, 'k-', 'LineWidth', 1.5);
    grid on;
end
