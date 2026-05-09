% ==========================================================================
% 01_CN_Pearson_Correlation.m
%
% 목적: 공식 CN (2010년 기준) 값과 지형/임상 인자 간의 피어슨 상관분석
% 출력: 상관계수(r), 유의확률(p-value), 막대그래프 2종 (지형/임상)
%
% 열 구성 가정 (엑셀 기준):
%   - 'F2010' 포함 열 : 공식 CN (2010년)
%   - 15~33번 열      : 지형 인자
%   - 36~49번 열      : 임상 인자
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
% 2. 기준 변수 추출 (공식 CN, 2010년)
% --------------------------------------------------------------------------
idx_CN = find(contains(vars, 'F2010', 'IgnoreCase', true), 1);
if isempty(idx_CN)
    idx_CN = 1;
    warning('F2010 열을 찾지 못해 1번 열을 사용합니다.');
end
CN_raw = data{:, idx_CN};

% --------------------------------------------------------------------------
% 3. 분석 대상 열 범위 설정
% --------------------------------------------------------------------------
max_col   = width(data);
cols_terr = 15:33;  % 지형 인자
cols_fore = 36:49;  % 임상 인자

cols_terr = cols_terr(cols_terr <= max_col);
cols_fore = cols_fore(cols_fore <= max_col);

% --------------------------------------------------------------------------
% 4. 상관분석 수행 (공통 함수)
% --------------------------------------------------------------------------
[r_terr, p_terr, names_terr, sig_terr] = run_correlation(data, vars, CN_raw, cols_terr);
[r_fore, p_fore, names_fore, sig_fore] = run_correlation(data, vars, CN_raw, cols_fore);

% --------------------------------------------------------------------------
% 5. 결과 출력
% --------------------------------------------------------------------------
print_results('지형 인자', names_terr, r_terr, p_terr, sig_terr);
print_results('임상 인자', names_fore, r_fore, p_fore, sig_fore);

% --------------------------------------------------------------------------
% 6. 시각화
% --------------------------------------------------------------------------
plot_correlation(r_terr, names_terr, sig_terr, '공식 CN (2010년) vs 지형 특성 인자', '지형 인자 상관분석');
plot_correlation(r_fore, names_fore, sig_fore, '공식 CN (2010년) vs 임상(숲) 특성 인자', '임상 인자 상관분석');


% ==========================================================================
% 로컬 함수
% ==========================================================================

function [r_out, p_out, names_out, sig_out] = run_correlation(data, vars, y, cols)
% 지정된 열 범위에 대해 y와의 피어슨 상관계수 및 p-value 계산
    n = length(cols);
    r_out    = zeros(1, n);
    p_out    = zeros(1, n);
    names_out = cell(1, n);
    sig_out  = cell(1, n);

    for i = 1:n
        x = data{:, cols(i)};
        names_out{i} = strrep(vars{cols(i)}, 'Sheet1$.', '');

        mask = ~isnan(y) & ~isnan(x);
        if sum(mask) >= 3
            [R, P]   = corrcoef(y(mask), x(mask));
            r_out(i) = R(1,2);
            p_out(i) = P(1,2);
        else
            r_out(i) = 0;
            p_out(i) = 1;
        end

        if p_out(i) < 0.01
            sig_out{i} = '**';
        elseif p_out(i) < 0.05
            sig_out{i} = '*';
        else
            sig_out{i} = 'ns';
        end
    end
end

function print_results(group_name, names, r, p, sig)
% 상관분석 결과를 터미널에 정렬 출력
    fprintf('\n%-60s\n', repmat('=', 1, 60));
    fprintf('  [%s] 상관분석 결과\n', group_name);
    fprintf('%-60s\n', repmat('=', 1, 60));
    fprintf('%-22s | %10s | %10s | %s\n', '변수명', 'r', 'p-value', '유의성');
    fprintf('%-60s\n', repmat('-', 1, 60));
    for i = 1:length(names)
        fprintf('%-22s | %10.3f | %10.4f | %s\n', names{i}, r(i), p(i), sig{i});
    end
    fprintf('%-60s\n', repmat('=', 1, 60));
end

function plot_correlation(r, names, sig, title_str, fig_name)
% 상관계수 막대 그래프 출력
    figure('Name', fig_name, 'Color', 'w', 'Position', [50, 100, 1200, 500]);
    ax = axes();
    b  = bar(r, 'FaceColor', 'flat', 'EdgeColor', 'none', 'BarWidth', 0.6);

    for i = 1:length(r)
        if r(i) >= 0
            b.CData(i,:) = [0.15 0.55 0.45];
        else
            b.CData(i,:) = [0.80 0.25 0.25];
        end

        % 유의한 경우에만 별표 표시
        if strcmp(sig{i}, 'ns')
            label = sprintf('%.2f', r(i));
        else
            label = sprintf('%.2f%s', r(i), sig{i});
        end

        if r(i) >= 0
            text(i, r(i) + 0.03, label, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', 'FontSize', 9, 'FontWeight', 'bold');
        else
            text(i, r(i) - 0.03, label, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end

    set(ax, 'XTick', 1:length(names), 'XTickLabel', names, ...
        'TickLabelInterpreter', 'none', 'FontSize', 10, 'LineWidth', 1.2);
    xtickangle(45);
    ylabel('상관계수 (Pearson r)', 'FontSize', 12, 'FontWeight', 'bold');
    title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
    yline(0, 'k-', 'LineWidth', 1.5);
    r_max = max(abs(r));
    if r_max == 0, r_max = 0.1; end
    ylim([-r_max - 0.15, r_max + 0.15]);
    grid on;
    ax.GridAlpha = 0.3;
end
