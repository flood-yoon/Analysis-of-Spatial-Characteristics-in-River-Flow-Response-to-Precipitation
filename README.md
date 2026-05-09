# Hydrological CN \& LagTime Statistical Analysis

MATLAB scripts for Pearson correlation analysis and residual diagnostics in watershed hydrology research.  
Developed as part of a graduate thesis at the University of Seoul.

\---

## File Overview

|File|Description|
|-|-|
|`01\_CN\_Pearson\_Correlation.m`|Pearson correlation between official CN (2010) and terrain / forest stand factors|
|`02\_Factor\_Impact\_Evaluation.m`|Impact evaluation of terrain, forest, soil, and slope factors on CN and LagTime|
|`03\_CN\_Runoff\_Validation.m`|Validation scatter plot of official CN vs final runoff coefficient|
|`04\_Runoff\_CN\_LagTime\_Comparison.m`|Runoff vs CN \& LagTime comparison with p-value bar chart|
|`05\_CN\_LagTime\_CrossCorrelation.m`|Cross-correlation between CN and LagTime|
|`06\_Residual\_Analysis.m`|Spatial error propagation analysis + time-series standardized residual analysis|

\---

## Usage

1. Open any `.m` file in MATLAB and run it.
2. A file dialog will appear — select the Excel (`.xlsx` / `.xls`) file you want to analyze.
3. Results are printed to the Command Window (text) and displayed as Figure windows (plots).

> \*\*Note:\*\* Column name keywords and column index settings are documented in the comment header of each script. Adjust only those lines if your Excel structure differs.

\---

## Methods

* **Pearson correlation (r)**: Linear correlation coefficient and two-tailed p-value via `corrcoef()`
* **Significance levels**: p < 0.01 (`\*\*`), p < 0.05 (`\*`), otherwise (`ns`)
* **Area ratio conversion**: Forest stand, soil type, and slope interval areas are divided by watershed area before analysis
* **Error propagation**: Topological separation of local vs. propagated error in HEC-HMS simulation results
* **Model performance metrics**: RMSE, NSE (Nash-Sutcliffe Efficiency), R²

\---

## Requirements

* MATLAB R2019b or later (required for local functions)
* No additional toolboxes needed

\---

## Glossary

|Term|Definition|
|-|-|
|CN|Curve Number — index of rainfall-runoff response|
|LagTime|Watershed lag time (hr)|
|Runoff\_C|Final runoff coefficient|
|NSE|Nash-Sutcliffe Efficiency — model performance index|
|RMSE|Root Mean Square Error|



