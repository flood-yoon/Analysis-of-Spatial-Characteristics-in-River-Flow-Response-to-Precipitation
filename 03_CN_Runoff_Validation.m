% ==========================================================================
% 03_CN_Runoff_Validation.m
%
% 목적: 공식 CN (2010년) 값과 최종 유출계수(Final_Runoff_C) 간의
%       상관관계 검증 (산점도 + 선형 추세선)
%
% 열 구성 가정 (엑셀 기준, xlsread 사용):
%   - 1번 열 : 공식 CN (F2010)
%   - 7번 열 : Final_Runoff_C
%   → 실제 파일에 맞게 아래 CN_COL, RUNOFF_COL 상수를 수정하세요.
% ==========================================================================

close all; clear; clc;

% --------------------------------------------------------------------------
% 사용자 설정값 (파일 열 번호)
% --------------------------------------------------------------------------
CN_COL     = 1;   % 공식 CN 열 번호
RUNOFF_COL = 7;   % Final_Runoff_C 열 번호

% --------------------------------------------------------------------------
% 1. 데이터 불러오기
% --------------------------------------------------------------------------
[file, path] = uigetfile({'*.xlsx;*.xls', 'Excel Files'}, '공식CN_Runoff 엑셀 파일을 선택하세요');
if isequal(file, 0)
    error('파일 선택이 취소되었습니다.');
end
filepath = fullfile(path, file);

try
    [num_data, ~, ~] = xlsread(filepath);
catch
    error('[오류] 파일을 읽을 수 없습니다. 엑셀이 열려 있다면 닫고 다시 실행하세요.');
end

% --------------------------------------------------------------------------
% 2. 데이터 추출 및 결측치 제거
% --------------------------------------------------------------------------
CN_raw     = num_data(:, CN_COL);
Runoff_raw = num_data(:, RUNOFF_COL);

valid = ~isnan(CN_raw) & ~isnan(Runoff_raw);
CN_v  = CN_raw(valid);
Ro_v  = Runoff_raw(valid);
n     = length(CN_v);

if n < 3
    error('유효 데이터가 3개 미만입니다. 열 번호(CN_COL, RUNOFF_COL)를 확인하세요.');
end

% --------------------------------------------------------------------------
% 3. 피어슨 상관분석
% --------------------------------------------------------------------------
[R_mat, P_mat] = corrcoef(CN_v, Ro_v);
r_val = R_mat(1,2);
p_val = P_mat(1,2);
sig   = get_sig_label(p_val);

% --------------------------------------------------------------------------
% 4. 결과 출력
% --------------------------------------------------------------------------
fprintf('\n■ Runoff vs 공식 CN (2010년) 상관분석 결과\n');
fprintf('%s\n', repmat('-', 1, 50));
fprintf('유효 데이터 수 (n) : %d\n', n);
fprintf('상관계수 (r)       : %.3f\n', r_val);
fprintf('유의확률 (p-value) : %.4f  %s\n', p_val, sig);
fprintf('%s\n', repmat('=', 1, 50));

% --------------------------------------------------------------------------
% 5. 시각화
% --------------------------------------------------------------------------
figure('Name', 'CN vs Runoff', 'Color', 'w', 'Position', [200, 200, 650, 500]);

scatter(CN_v, Ro_v, 80, 'filled', ...
    'MarkerFaceColor', [0.20 0.50 0.70], 'MarkerEdgeColor', 'k', 'LineWidth', 1);
hold on; grid on;

p_fit  = polyfit(CN_v, Ro_v, 1);
x_line = linspace(min(CN_v), max(CN_v), 200);
plot(x_line, polyval(p_fit, x_line), 'r-', 'LineWidth', 2.5);

xlabel('공식 산정 CN (2010년 기준)', 'FontSize', 13, 'FontWeight', 'bold');
ylabel('Final\_Runoff\_C (최종 유출계수)', 'FontSize', 13, 'FontWeight', 'bold');
title(sprintf('Final\\_Runoff\\_C vs 공식 CN (2010년)  (n = %d)', n), ...
    'FontSize', 14, 'FontWeight', 'bold');

annotation('textbox', [0.55, 0.15, 0.36, 0.14], ...
    'String', sprintf('r = %.3f\np = %.4f\n%s', r_val, p_val, sig), ...
    'FitBoxToText', 'on', 'BackgroundColor', 'w', 'EdgeColor', 'k', ...
    'FontSize', 12, 'FontWeight', 'bold');


% ==========================================================================
% 로컬 함수
% ==========================================================================

function label = get_sig_label(p)
    if p < 0.01,      label = '** (매우 유의함)';
    elseif p < 0.05,  label = '*  (유의함)';
    else,             label = 'ns (유의하지 않음)';
    end
end
