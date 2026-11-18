# Tropical cyclone phases and emergency department encounters in Florida

Analysis code for:

> Hsu D, Melix B, Elsner JB, Powell E, Harville EW, Wu Z, Uejio CK. *Association Between Tropical Cyclone Phases and Cause-Specific Emergency Department Demand in Florida, United States, 2005–2023.* Manuscript submitted to the Journal of Exposure Science & Environmental Epidemiology.

The code estimates changes in county-weekly emergency department (ED) encounters across three tropical cyclone (TC) phases: Threat (the 7 days before impact), Impact (the impact day), and Cleanup (the 7 days after impact). It does this for all-cause encounters, ten cause-specific categories, and four age groups, at three wind intensity thresholds (≥34, ≥55, and ≥64 kt). The model is a fixed-effects Poisson regression with county and year-month fixed effects, a log window-length offset, and standard errors clustered by county and year-month. A timing permutation falsification test is also included.

## Data are not included

The ED encounter data are confidential. They were provided under a data use agreement with the Florida Department of Health and the Florida Agency for Health Care Administration (AHCA), and they cannot be shared by the authors. They may be requested from these agencies. **No ED data, and no outputs derived from them at the county level, are included in this repository.**

The public inputs are:

| Input | Source | How it is obtained |
|---|---|---|
| Storm tracks | IBTrACS North Atlantic v04r01 (NOAA NCEI) | Downloaded by the script if missing |
| Florida county boundaries | U.S. Census Bureau 2020 cartographic boundary files | Downloaded by the `tigris` package |
| Rural-Urban Continuum Codes 2023 | USDA Economic Research Service | Place `Ruralurbancontinuumcodes2023.csv` in `Ed_county_weekly_public/` |

## Files

| File | Purpose |
|---|---|
| `ED_county_weekly_TC_phases.Rmd` | Main analysis: storm swaths, exposed counties, phase models, figures, attributable fractions, falsification tests, and the results tables |
| `build_injury_64kt_from_march.R` | Builds the injury input file (`ED_Injuries_FirstEcode.csv`) at all three thresholds from the provider's injury extract; run once before the main analysis |

## Folder layout expected by the code

The code finds the project root with `here::here()`, so run it from a clone of this repository (or an RStudio project in the same folder).

```
ED-TC-phases-Florida/
├── ED_county_weekly_TC_phases.Rmd
├── build_injury_64kt_from_march.R
├── Ed_county_weekly_confidential/        # AHCA files (not public)
│   ├── ED_AllCause.csv                   # storm-aligned all-cause windows
│   ├── ER_AllCause_County_by_Day_05_24.csv
│   ├── ED_<Category>.csv                 # storm-aligned windows, one file per category
│   ├── ED_Injuries_FirstEcode.csv        # written by build_injury_64kt_from_march.R
│   ├── ED_Age_Cats.csv
│   ├── Combined_ER_Weekly_By_County_DiseaseCategories.csv
│   └── ER_AllCause_AgeGroups_County_Weekly.csv
└── Ed_county_weekly_public/              # IBTrACS tracks and USDA codes
```

The script creates `figs/` and `outputs/results_tables/`.

## Running the analysis

1. Run `build_injury_64kt_from_march.R` once to create the injury input file.
2. Knit or run `ED_county_weekly_TC_phases.Rmd` from top to bottom. An input consistency check near the top stops the run if the storm-aligned and baseline extracts do not count encounters the same way.

The timing permutation tests (200 iterations per outcome and threshold) take the longest. Random seeds are set in the code. The study period is 2005–2023; storm tracks are read for 2004–2024 only so that phase windows near the ends of the period are complete.

R packages: `sf`, `dplyr`, `lubridate`, `tidyr`, `readr`, `ggplot2`, `fixest`, `tigris`, `purrr`, `stringr`, `broom`, `here`, `tibble`, `rlang`, `scales`, and `data.table` (helper script only). Developed with R 4.3.3.

## Script outputs and the manuscript

The figure files keep the names used during development. They map to the manuscript as follows.

| Script output | Manuscript |
|---|---|
| `Figure2_allcause_phases_by_threshold` | Figure 1 |
| `Figure5_county_phase_vs_expected` | Figure 2 |
| `Figure3_cause_specific_by_threshold` | Figure 3 |
| `Figure4_age_groups_by_threshold` | Figure 4 |
| `Figure1_exposure_*` | Figure S1 |
| `FigureS1_ED_volume` | Figure S2 |
| `FigureS2a_TC_counts_34kt`, `FigureS2b_TC_counts_55_64kt` | Figure S3 |
| `T4b_attributable_fraction_number_64kt.csv` | Table 1 |
| `T1_study_inventory.csv` | Table S2 and Methods |
| `T8_falsification_allcause.csv`, `T9_falsification_categories.csv`, `T10_falsification_extended.csv` | Table S3 |
| `T3_allcause_phase_effects.csv`, `T5_cause_specific_effects.csv`, `T6_age_group_effects.csv` | Table S4 |
| `T4_attributable_fraction_number.csv` | Table S5 |
| `T2_panel_composition.csv` | Methods |
| `T7_threat_without_swath.csv` | Discussion |

## License

MIT (see `LICENSE`).
