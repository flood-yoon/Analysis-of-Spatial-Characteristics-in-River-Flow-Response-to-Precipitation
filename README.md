# Hydrological CN & LagTime Statistical Analysis

MATLAB scripts for Pearson correlation analysis and residual diagnostics in watershed hydrology research.  
Developed as part of a graduate thesis (서울시립대학교).

---

## File Overview

| 파일명 | 분석 내용 |
|---|---|
| `01_CN_Pearson_Correlation.m` | 공식 CN(2010년) vs 지형/임상 인자 다중 상관분석 |
| `02_Factor_Impact_Evaluation.m` | CN·LagTime vs 지형/임상/토양/경사 인자 영향도 평가 |
| `03_CN_Runoff_Validation.m` | 공식 CN vs 최종 유출계수(Runoff) 검증 |
| `04_Runoff_CN_LagTime_Comparison.m` | Runoff vs CN·LagTime 비교 및 p-value 시각화 |
| `05_CN_LagTime_CrossCorrelation.m` | CN과 LagTime 간 교차 상관관계 |
| `06_Residual_Analysis.m` | 공간적 오차 전파 분석 + 시계열 표준화 잔차 분석 |

---

## 사용 방법

1. MATLAB에서 해당 `.m` 파일을 실행합니다.
2. 파일 선택 팝업이 나타나면 분석할 엑셀(`.xlsx` / `.xls`) 파일을 선택합니다.
3. 결과는 MATLAB 커맨드 창(텍스트)과 Figure 창(그래프)으로 출력됩니다.

> **참고:** 각 스크립트 상단의 주석에 열 이름 키워드 및 열 번호 설정 방법이 안내되어 있습니다.  
> 엑셀 구조가 다를 경우 해당 부분만 수정하면 됩니다.

---

## 주요 분석 방법

- **피어슨 상관분석 (Pearson r)**: 선형 상관계수 및 p-value 산출
- **유의수준**: p < 0.01 (`**`), p < 0.05 (`*`), 그 외 (`ns`)
- **면적 비율 변환**: 임상·토양·경사 면적 인자는 유역면적으로 나누어 비율(%)로 변환 후 분석
- **오차 전파 분석**: 위상 순서 기반 독립 오차 vs 전파 오차 분리 (HEC-HMS 결과 대상)
- **모델 평가지표**: RMSE, NSE(Nash-Sutcliffe Efficiency), R²

---

## 요구 사항

- MATLAB R2019b 이상 (로컬 함수 지원)
- 추가 Toolbox 불필요

---

## 변수명 약어 정리

| 약어 | 설명 |
|---|---|
| CN | Curve Number (유출곡선지수) |
| LagTime | 유역 지연시간 (hr) |
| Runoff_C | 최종 유출계수 |
| NSE | Nash-Sutcliffe Efficiency (모형 효율 계수) |
| RMSE | Root Mean Square Error |
