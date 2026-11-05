# NHIS — National Health Interview Survey

Starter code and documentation for working with the NHIS, 2004–2024.

> **📥 Data download required.** The raw data files are too large for GitHub. Download them from the [shared Dropbox folder](https://www.dropbox.com/scl/fo/oxcdw665ng3q39d11r5yf/ABOW0em1n3G2nsnt4ddrvIY?rlkey=beca6kii18iktke0vweqd83z8&st=txepj9zb&dl=0) and place the year folders in `data/`. See [Step 1](#step-1-obtain-the-data) for details.

## Overview

The National Health Interview Survey (NHIS) is an annual household interview survey conducted by the National Center for Health Statistics (NCHS), part of the CDC. It is one of the primary data sources on the health of the US civilian noninstitutionalized population.

**Key features:**
- **Repeated cross-section** — new sample each year (annual since 1957)
- **Person-level data** from household interviews
- **~30,000–40,000 adults per year** (2019+ design); ~90,000 persons per year (pre-2019)
- **Health insurance**: coverage type, source, gaps
- **Health status**: self-rated health, chronic conditions, functional limitations
- **Health care access/utilization**: usual source of care, ER visits, delayed care
- **Mental health**: PHQ-8 depression screener, GAD-7 anxiety screener (2019+)
- **Demographics**: age, sex, race/ethnicity, education, income, immigration
- **Health behaviors**: smoking, alcohol, physical activity, BMI
- **Complex survey design** with weights, strata, and PSUs

**What the starter scripts produce:**
- `nhis_adult.dta` / `nhis_child.dta` — Combined adult and child files from the Stata loader
- `nhis_adult.rds` / `nhis_child.rds` — Combined adult and child files from the R loader
- `nhis_adult_clean.dta` — Cleaned adult file from the Stata cleaner
- `nhis_adult_clean.rds` — Cleaned adult file from the R cleaner
- Optional R-created Stata exports use `_from_r.dta` suffixes so they do not overwrite Stata outputs

### Data Source

Downloaded from the **NCHS NHIS** data page:
- https://www.cdc.gov/nchs/nhis/data-questionnaires-documentation.htm

---

## The 2019 NHIS Redesign

The NHIS underwent a **major redesign in 2019**. The pre-2019 and post-2019 surveys differ in structure, variable names, and sampling design. Understanding this break is essential for working with NHIS data across time.

**Our approach:** The starter scripts handle this complexity by (1) harmonizing variable **names** to the post-2019 convention in the load/append step, and (2) handling coding **differences** with era-specific logic in the cleaning step, using an `era_post2019` indicator variable.

### Pre-2019 (2004–2018): Hierarchical 5-File Design

Each year has 5 separate data files that must be **merged** to create an analytic dataset:

| File | Level | Merge Keys | Description |
|---|---|---|---|
| `househld` | Household | `hhx, srvy_yr` | Household characteristics |
| `familyxx` | Family | `hhx, fmx, srvy_yr` | Family-level info (income, SNAP) |
| `personsx` | Person | `hhx, fmx, fpx, srvy_yr` | Demographics for ALL household members |
| `samadult` | Person (adult) | `hhx, fmx, fpx, srvy_yr` | Detailed health for 1 random adult per family |
| `samchild` | Person (child) | `hhx, fmx, fpx, srvy_yr` | Detailed health for 1 random child per family |

**Merge order:** `personsx` ← `familyxx` ← `househld`, then join `samadult` or `samchild`.

**Sampling unit:** One sample adult and one sample child per **family** (not household).

**Data format:** Fixed-width ASCII (`.DAT`) files, read into Stata using CDC-provided do-files that use `infix`.

### Post-2019 (2019–2024): Flat 2-File Design

Each year has 2 self-contained data files (no merging needed):

| File | Description |
|---|---|
| `adult` | All data for one sample adult per **household** |
| `child` | All data for one sample child per **household** |

**Everything is in one file:** demographics, family composition, health conditions, insurance, utilization, income — all contained in the adult or child file.

**Sampling unit:** One sample adult and one sample child per **household**.

**Data format:** CSV files in `.zip` archives.

### Key Differences Summary

| Feature | Pre-2019 (2004–2018) | Post-2019 (2019–2024) |
|---|---|---|
| Files per year | 5 (must merge) | 2 (self-contained) |
| Merging required | Yes (up to 4-way) | No |
| Identifiers | `hhx` + `fmx` + `fpx` | `hhx` only |
| Variable suffix | None (e.g., `sex`, `age_p`) | `_a` for adult, `_c` for child |
| Sampling unit | Family | Household |
| Data format | Fixed-width ASCII (`.DAT`) + do-files | CSV (`.csv`) in `.zip` archives |
| Weight variable | `wtfa_sa` (sample adult), `wtfa_sc` (sample child) | `wtfa_a` (adult), `wtfa_c` (child) |
| Strata/PSU | `stratum`/`psu` (2004–05), `strat_p`/`psu_p` (2006–2015), native `pstrat`/`ppsu` (2016–2018) | `pstrat`/`ppsu` |
| PHQ-8 / GAD-7 | Not available | Available |

---

## Directory Structure

```
nhis/
├── README.md                    ← This file
├── code/
│   ├── 01_load_and_append.do    ← Full data build pipeline (Stata)
│   ├── 01_load_and_append.R     ← Same in R
│   ├── 01_load_and_append_optional_low_memory.do ← Optional low-memory Stata entry point
│   ├── 01_load_and_append_optional_low_memory.R  ← Optional low-memory R entry point
│   ├── 02_clean_and_analyze.do  ← Clean variables, descriptive stats (Stata)
│   ├── 02_clean_and_analyze.R   ← Same in R
│   ├── 03_load_income_implicates_optional.R / .do ← Separate completed MI data
│   └── 04_income_mi_example_optional.R / .do     ← Disabled survey + MI example
├── data/
│   ├── NHIS 2004/               ← Pre-2019: .DAT + CDC do-files + .dta
│   ├── NHIS 2005/
│   ├── ...
│   ├── NHIS 2014/               ← Last year with .dta files readily available
│   ├── NHIS 2015/               ← 2015-2018: .zip only (need extraction)
│   ├── ...
│   ├── NHIS 2018/               ← Last pre-redesign year
│   ├── NHIS 2019/               ← First redesigned year
│   ├── ...
│   └── NHIS 2024/               ← Most recent year
├── docs/
│   ├── NHIS_2019_Redesign_sr02-207.pdf
│   ├── NHIS_2024_adult_codebook.pdf
│   ├── NHIS_2024_child_codebook.pdf
│   └── income_variable_matrix.md ← Income definitions, eras, flags and sources
└── output/                      ← Cleaned datasets (created by scripts)
    ├── nhis_adult.dta           ← Combined raw adult file
    ├── nhis_adult.rds           ← Combined raw adult file from R
    ├── nhis_child.dta           ← Combined raw child file
    ├── nhis_child.rds           ← Combined raw child file from R
    ├── nhis_adult_clean.dta     ← Cleaned adult file from Stata
    └── nhis_adult_clean.rds     ← Cleaned adult file from R
```

---

## Quick Start

### Step 1: Obtain the Data

The raw data files are too large for GitHub and must be downloaded separately. Each year's data lives in its own folder under `data/` (e.g., `data/NHIS 2022/`).

**Option A — Dropbox (recommended):**
Download whichever year folders you need from the shared folder:
https://www.dropbox.com/scl/fo/oxcdw665ng3q39d11r5yf/ABOW0em1n3G2nsnt4ddrvIY?rlkey=beca6kii18iktke0vweqd83z8&st=txepj9zb&dl=0

| Year Range | What to Download | Size | Notes |
|---|---|---|---|
| **2019–2024** | `NHIS 2019/` through `NHIS 2024/` | ~200 MB total | **Start here** — simple CSV files, no special setup |
| 2004–2014 | `NHIS 2004/` through `NHIS 2014/` | ~5 GB total | Pre-redesign era — requires CDC do-files to build `.dta` |
| 2015–2018 | `NHIS 2015/` through `NHIS 2018/` | ~1 GB total | Pre-redesign era — scripts extract archives or use CSV fallback when needed |

Place each year folder in `data/`. The starter scripts auto-detect which years are present and process only those.

The ordinary `01`/`02` workflow uses the main annual files. To use the optional income-imputation workflow, also obtain the separate income files for your selected years; see [Income Imputation Files](#income-imputation-files-optional-rstata-workflow).

**Option B — CDC website:**
1. Go to https://www.cdc.gov/nchs/nhis/data-questionnaires-documentation.htm
2. Select the survey year
3. For 2019+: download the CSV data files (adult and child)
4. For pre-2019: download the ASCII data files + Stata programs
5. Place files in `data/NHIS YYYY/` folders

### Step 2: Load and Append (All Years)

**Stata:**
```stata
cd "/path/to/nhis"
do code/01_load_and_append.do
```

**R:**
```r
source("code/01_load_and_append.R")
```

The scripts can be run from `nhis/`, `nhis/code/`, or the repo root. If automatic path detection fails, set the dataset root explicitly:

```stata
global nhis_root "/path/to/nhis"
do "$nhis_root/code/01_load_and_append.do"
```

```r
nhis_root_manual <- "/path/to/nhis"
source(file.path(nhis_root_manual, "code", "01_load_and_append.R"))

# Or before sourcing:
Sys.setenv(NHIS_ROOT = "/path/to/nhis")
```

This script performs the **full data build pipeline.**

**Default (2019–2024 only):** Unzips and imports CSV files — fast and simple, no special setup needed.

**With pre-2019 years enabled:** The Stata loader creates or reuses component `.dta` files, merges the 5-file hierarchical structure (personsx + familyxx + househld + samadult/samchild), and harmonizes variable names. For 2015–2018, it extracts archives and uses CSV fallback when fixed-width ASCII is absent or CDC do-files assume Windows-only paths. To include pre-2019 years, set or edit the `pre2019_years` settings in the script.

The script auto-detects which year folders are present in `data/` and skips any missing years, so you only need to download the years you want to analyze.

**Output:**
- `output/nhis_adult.dta` / `output/nhis_child.dta` — Stata combined files
- `output/nhis_adult.rds` / `output/nhis_child.rds` — R combined files
- `output/nhis_adult_from_r.dta` / `output/nhis_child_from_r.dta` — optional R-created Stata exports if `write_dta_export <- TRUE`

**Note on R:** The R script requires that `.dta` files already exist for pre-2019 years (since CDC do-files are Stata programs). Run the Stata script first to create the `.dta` files, then the R script can load them. For post-2019 years, R works standalone. R writes compact `.rds` files by default; set `write_dta_export <- TRUE` only if you also need R-created Stata files.

### Recommended Lower-Memory Path

For most student projects, use `01_load_and_append_optional_low_memory.*`. Its teaching-friendly default is 2023-2024 with pre-2019 years off. Confirm that default and any project-specific variables before expanding the range.

```stata
do code/01_load_and_append_optional_low_memory.do
```

```r
source("code/01_load_and_append_optional_low_memory.R")
```

The R low-memory loader selects requested columns while reading both post-2019 CSVs and pre-2019 component DTA files. The Stata loader processes one year at a time, but its post-2019 CSV imports read the full annual CSV before dropping columns; pre-2019 component construction can also require a broader annual import.

For scratch runs, set `nhis_output_dir` or `NHIS_OUTPUT_DIR` in R, or global `nhis_output_dir` in Stata. The matching cleaner honors the same output-directory override, so test builds do not have to replace the normal `output/` files.

**Full 2004–2024 build:**

Stata is the all-column full-build path:

```stata
global nhis_pre2019_years "2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018"
global nhis_post2019_years "2019 2020 2021 2022 2023 2024"
do code/01_load_and_append.do
```

For a lower-memory full-span build, explicitly enable all years. The loader keeps the starter variables needed by the cleaner plus any user-requested extras:

```stata
global nhis_pre2019_years "2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018"
global nhis_post2019_years "2019 2020 2021 2022 2023 2024"
do code/01_load_and_append_optional_low_memory.do
```

```r
pre2019_years <- 2004:2018
post2019_years <- 2019:2024
source("code/01_load_and_append_optional_low_memory.R")
```

With the current shared files, both the adult and child files cover 2004–2024 when all years are enabled.

### Step 3: Clean and Analyze

**Stata:**
```stata
do code/02_clean_and_analyze.do
```

**R:**
```r
source("code/02_clean_and_analyze.R")
```

Creates harmonized cleaned variables across all years using era-aware logic and saves the cleaned adult dataset to `output/`. The descriptive tables and example regressions are kept in the scripts as optional teaching blocks but do not run by default. Set `run_examples <- TRUE` in R, or `local run_examples 1` in Stata, to print the examples.

**Output:**
- `output/nhis_adult_clean.dta` — Cleaned adult file from Stata
- `output/nhis_adult_clean.rds` — Cleaned adult file from R
- `output/nhis_adult_clean_from_r.dta` — optional R-created Stata export if `write_dta_export <- TRUE`

### Memory and File-Size Notes

The recommended teaching path is `code/01_load_and_append_optional_low_memory.R` or `.do`, which defaults to 2023-2024 and writes the usual cleaner inputs. These standalone scripts keep the variables needed by the starter cleaner, plus any names listed in `extra_vars` / `nhis_extra_keep_vars`.

The implementations have different peak-memory behavior:

- R inspects each source header and selects only the requested raw columns before reading observations.
- Stata processes and saves one reduced year at a time, but its delimited-text importer reads a complete post-2019 annual CSV before unused columns are dropped.
- The final appended adult and child working files must still fit in memory in either language.

Use `extra_vars` in R for additional variables with stable names after NHIS harmonization:

```r
pre2019_years <- 2004:2018
post2019_years <- 2019:2024
extra_vars <- c("regionbr_a", "plborn_a")
source("code/01_load_and_append_optional_low_memory.R")
```

Use `nhis_extra_keep_vars` in Stata for the same stable-name case:

```stata
global nhis_extra_keep_vars "regionbr_a plborn_a"
do code/01_load_and_append_optional_low_memory.do
```

In Stata, set either year global to `"none"` or `"skip"` if you want to omit that era while testing a smaller build.

Use `extra_var_families` when the same concept appears under different raw names across years. Each named entry keeps all listed aliases during the low-memory load and then coalesces them into one column:

```r
pre2019_years <- 2004:2018
post2019_years <- 2019:2024
extra_var_families <- list(
  health_status_raw = c("phstat_a", "phstat")
)
source("code/01_load_and_append_optional_low_memory.R")
```

```stata
global nhis_extra_var_families ///
    `" "health_status_raw:phstat_a phstat_c phstat" "'
do code/01_load_and_append_optional_low_memory.do
```

Alias families merge columns by name only. If the coding or meaning changes across NHIS eras, harmonize that added variable in `02_clean_and_analyze.R` or in your analysis code.

The large files are the Stata-format outputs. A full 2004–2024 all-column Stata adult file and cleaned adult file are each several GB. The R scripts skip `.dta` export by default and, when requested, write `_from_r.dta` files so R outputs do not collide with Stata outputs. For long pre-2019 builds, start with a small `pre2019_years` list and add years incrementally.

Reference measurements from the reviewed local files are below. They are approximate and machine-specific; they are intended to show the scale of the selected-column route, not guarantee runtime on another computer.

| R low-memory selection | Columns read | Result | Saved RDS size | Reference runtime / R heap high-water |
|---|---|---|---:|---:|
| Default 2023-2024 | Adult: 35 of 647/630 per year; child: 18 of 370/358 | Adult: 62,151 rows x 37 columns; child: 16,052 x 20 | Adult: 1.32 MB; child: 277 KB | About 2.6 seconds / 145 MB |
| Pre-redesign check, 2014 only | Adult components: 33 of 641 person, 9 of 127 family, 4 of 17 household, 19 of 787 sample-adult columns | Adult: 36,697 rows x 40 columns; child: 13,380 x 26 | Adult: 815 KB; child: 244 KB | About 2.6 seconds; heap not recorded |

The R heap figure is the sum of R's recorded high-water cell allocations, not total operating-system process memory. Storage speed, software versions, requested extras, and optional exports can materially change these figures.

---

## How Variable Harmonization Works

The starter scripts use a two-step approach to handle the 2019 redesign:

### Step 1: Name Harmonization (01_load_and_append)

Pre-2019 variable names and post-redesign aliases are renamed to stable starter names. This allows a clean `append` across all years. In particular, the 2021-2024 adult files use `educp_a` rather than the 2019-2020 `educ_a`, and post-2019 citizenship is released as `citznstp_a`; the loaders normalize these to `educ_a` and `citizenp_a`.

| Source name(s) | Harmonized starter name | Description |
|---|---|---|
| `age_p` | `agep_a` | Age |
| `sex` | `sex_a` | Sex (same coding: 1=Male, 2=Female) |
| `origin_i` | `hisp_a` | Hispanic origin |
| `racerpi2` | `raceallp_a` | Race |
| `educ1`; `educp_a` in 2021+ | `educ_a` | Education |
| `notcov` | `notcov_a` | Uninsured |
| `medicaid` | `medicaid_a` | Medicaid |
| `private` | `private_a` | Private insurance |
| `medicare` | `medicare_a` | Medicare |
| `phstat` | `phstat_a` | Self-rated health |
| `wtfa_sa` | `wtfa_a` | Sample adult weight |
| `strat_p` (2006–2015) | `pstrat` | Pseudo-stratum (existing offset); 2016–2018 retain native `pstrat` |
| `psu_p` | `ppsu` | Pseudo-PSU |
| `citizenp`; `citznstp_a` in 2019+ | `citizenp_a` | Citizenship |
| `plborn` | `plborn_a` | Place of birth |
| `rat_cat`, `rat_cat2`, `rat_cat4` | `ratcat_a/c` (copy; natives retained) | Detailed and coarse primary poverty categories |
| `incgrp`, `incgrp2`, `incgrp4` | `incgrp_a/c` (copy; natives retained) | Reported primary income group; eleven bands in 2004–2006, five detailed bands later |
| `ernyr_p` | `ernyr_a` | Personal earnings (adults, pre-2019 only) |

**Within pre-2019 name changes** (some variable names changed during 2004–2018):

| Earlier Name | Later Name | Years Changed |
|---|---|---|
| `othergov` | `othgov` | 2008+ |
| `otherpub` | `othpub` | 2008+ |
| `military` | `milcare` | 2008+ |
| `phospyr` | `phospyr2` | 2006+ |
| `ffdstyn` | `fsnap` | 2011+ |
| `stratum`/`psu` | `strat_p`/`psu_p` | 2006+ |
| `rat_cat` | `rat_cat2` → `rat_cat4` | `rat_cat2` in 2007+, `rat_cat4` in 2014 |
| `incgrp` | `incgrp2` → `incgrp4` | `incgrp2` in 2007+, `incgrp4` in 2014 |

### Step 2: Coding Harmonization (02_clean_and_analyze)

Even after names are harmonized, the **coding** of some variables differs across eras. The cleaning script uses the `era_post2019` indicator (created in Step 1) to apply era-specific recoding.

**Insurance variables (CRITICAL):**
| Code | Pre-2019 Meaning | Post-2019 Meaning |
|---|---|---|
| 1 | Mentioned (= Yes) | Yes |
| 2 | Probed yes (= Yes) | No |
| 3 | No | — |

Pre-2019: codes 1 OR 2 = Yes, code 3 = No. Post-2019: code 1 = Yes, code 2 = No. The `notcov` variable uses the same coding in both eras (1=Not covered, 2=Covered).

**Education:**
| Category | Pre-2019 Codes (`educ1`) | Post-2019 Codes (`educ_a`) |
|---|---|---|
| Less than HS | 0–12 | 0–9 |
| HS/GED | 13–14 | 10 |
| Some college/AA | 15–17 | 11–12 |
| Bachelor's | 18 | 13 |
| Graduate | 19–21 | 14–16 |

**Race (Asian category):**
- Pre-2019 (`racerpi2`): Codes 4–14 represent various Asian/Pacific Islander groups
- Post-2019 (`raceallp_a`): Code 4 = Asian (single collapsed category)
- White (1), Black (2), and AIAN (3) are the same across eras

---

## Key Variables Created

### Demographics

| Variable | Source | Description |
|---|---|---|
| `female` | `sex_a` | Female indicator (1=Female; **Note: sex_a=1 is Male in NHIS**) |
| `age_cat` | `agep_a` | Age category (18-25, 26-34, ..., 75+) |
| `race_eth` | `raceallp_a`, `hisp_a` | Race/ethnicity (White NH, Black NH, Hispanic, Asian NH, Other NH) — era-aware |
| `educ_cat` | `educ_a` | Education (Less than HS, HS/GED, Some college/AA, Bachelor's, Graduate) — era-aware |
| `us_born` | `citizenp_a` | Born in US or territory |
| `citizen` | `citizenp_a` | US citizen (including naturalized) |
| `noncitizen` | `citizenp_a` | Non-citizen |

### Health Insurance

| Variable | Source | Description |
|---|---|---|
| `uninsured` | `notcov_a` | Currently uninsured |
| `has_medicare` | `medicare_a` | Has Medicare — era-aware coding |
| `has_medicaid` | `medicaid_a` | Has Medicaid — era-aware coding |
| `has_private` | `private_a` | Has private insurance — era-aware coding |
| `insur_type` | Multiple | Insurance hierarchy (Medicare > Private > Medicaid > Uninsured > Other) |

### Health Status

| Variable | Source | Description |
|---|---|---|
| `health_status` | `phstat_a` | Self-rated health (1=Excellent to 5=Poor) |
| `fair_poor_health` | `phstat_a` | Fair or poor health (binary) |
| `excellent_vgood` | `phstat_a` | Excellent or very good health (binary) |

### Chronic Conditions

| Variable | Source | Description |
|---|---|---|
| `hypev` | `hypev_a` | Ever had hypertension |
| `chlev` | `chlev_a` | Ever had high cholesterol |
| `dibev` | `dibev_a` | Ever had diabetes |
| `depev` | `depev_a` | Ever had depression |
| `anxev` | `anxev_a` | Ever had anxiety |
| `asev` | `asev_a` | Ever had asthma |
| `copdev` | `copdev_a` | Ever had COPD |
| `arthev` | `arthev_a` | Ever had arthritis |
| `canev` | `canev_a` | Ever had cancer |
| `chdev` | `chdev_a` | Ever had coronary heart disease |
| `miev` | `miev_a` | Ever had heart attack (MI) |
| `strev` | `strev_a` | Ever had stroke |

### Mental Health Screeners (2019+ Only)

| Variable | Source | Description |
|---|---|---|
| `depression_moderate` | `phqcat_a` | Moderate+ depression (PHQ-8 score >= 10) |
| `anxiety_moderate` | `gadcat_a` | Moderate+ anxiety (GAD-7 score >= 10) |

These variables are missing for pre-2019 observations because the PHQ-8 and GAD-7 were introduced in the 2019 redesign.

### Health Care Utilization

| Variable | Source | Description |
|---|---|---|
| `delayed_care` | `pdmed12m_a` | Delayed medical care, past 12 months |
| `foregone_care` | `pnmed12m_a` | Needed but did not get medical care |

### Income / Poverty

NHIS provides family-income dollar bands, poverty measures, and continuous family-income dollars in some years. Income bands describe nominal dollars; poverty measures compare family income with a threshold that reflects family size and composition. Personal earnings are a separate concept and are available in the ordinary starter only before 2019.

**Choose a path before choosing a variable:**

| Your goal | Route | What to expect |
|---|---|---|
| Explore the data or prepare an ordinary adult analysis file | Run one `01` loader, then the matching `02` cleaner | Start with the strict poverty measures and `income_cat3` when grouped income is released, especially for comparisons including 2004–2006. Some responses remain unclassified. From 2019, ordinary income values come from only the first completed imputation; this route omits between-imputation uncertainty. |
| Check whether broad interview brackets change your results | Compare the separate `*_with_coarse` poverty measures from `02` with the strict measures and source flags | Retain a bracket only when it identifies the outcome. These sensitivity measures do not resolve all missing income or replace MI. |
| Account for income-imputation uncertainty in income/poverty estimates or models | Build matching ordinary inputs with `01`, then use optional `03` and an MI analysis | Download the separate income files and analyze all five pre-2019 or all ten post-2019 completed datasets ("implicates"), pooling estimates and variances. `03` supports adults and children. Optional `04` demonstrates single-year survey poverty means and is disabled by default. See the [MI workflow](#income-imputation-files-optional-rstata-workflow) for downloads, settings and commands. |

An implicate is one completed version of the income data, not another respondent sample. The MI outputs stay separate from the ordinary files; the `04` example runs only after you explicitly enable it.

**Check your years next.** Ordinary files provide family-income categories through 2020. Continuous family-income dollars require the separate MI files before 2019 and are also released in the 2019–2020 main and MI files. From 2021, public main and MI files retain poverty measures but withhold both family-income dollars and grouped income; MI does not restore those fields. Choose a measure available in your selected years, using the era table below. Selecting comparable measures does not by itself establish comparability across the 2019 redesign.

All four loaders retain native pre-2019 income constructions, `FMX/FPX`, earnings, post-2019 continuous poverty ratios, dollar income when released, and imputation/top-code flags. Adult/child aliases use `_a`/`_c`. Both existing cleaners are adult-only.

| Cleaned variable | Meaning |
|---|---|
| `pov_cat`, `below_poverty`, `low_income` | Original strict measures using detailed poverty codes 1–14 |
| `pov_cat_with_coarse`, `below_poverty_with_coarse`, `low_income_with_coarse` | Separate sensitivity measures retaining primary reported interview brackets where they identify the outcome |
| `pov_cat_src`, `poverty_binary_src` | 0 unavailable, 1 detailed, 2 interview bracket; primary code 17 identifies binaries but not the four-band category |
| `income_cat` | Five nominal dollar bands; conservative bounds-based mapping of 2004–2006 eleven-band income |
| `income_cat3`, `income_cat3_src` | Under $35,000 / $35,000–74,999 / $75,000+; source 0 unavailable, 1 primary, 2 eligible `INCGRP5` bridge fill in 2014–2018 |
| `earn_cat` | Previous-calendar-year personal earnings for the work-for-pay universe, pre-2019 only; blanks are missing, not zero |
| `income_value_src` | 0 pre-2019 reported construction, 1 post-2019 reported, 2 post-2019 imputed/main implicate 1 |

The [income variable matrix](docs/income_variable_matrix.md) gives code bounds, sentinels, flags, correction provenance, annual availability and official sources. Pre-2019 `RAT_CAT2/3`, `RAT_CAT4/5` and paired `INCGRP` fields are alternative categorical constructions, **not two imputations**. Detailed poverty bounds align across eras, but main-file provenance changes: from 2019 the convenient income variables are **implicate 1 of ten**. Strict category boundaries do not mean reported-only observations. Ordinary-file income examples omit between-imputation uncertainty; use the optional MI workflow for income inference.

`INCGRP` in 2004–2006 has eleven detailed bands. For 2004–2006, `income_cat` is only a partial measure: it has no classified observations in either upper band and omits the straddling $45,000–54,999 band. Its nonmissing distribution is selected by income. Use `income_cat3` for comparisons across these years; do not interpret a five-band tabulation as the full income distribution. The old $45,000–54,999 band crosses the five-band $50,000 cutoff, and $75,000+ cannot identify either upper band. They remain missing in `income_cat` but can enter `income_cat3`. Primary coarse income codes 6–8 in later years cross the starter bands and stay missing. The 2014–2018 bridge fills only an identified three-band category, with a consistency check and source flag. The poverty companions use interview brackets; [2018 documentation](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2018/srvydesc.pdf), pp. 43–44, identifies estimated instrument thresholds for those brackets. Interpret these as separate sensitivity measures rather than exact classifications against final thresholds.

The loaders apply CDC's verified [2007 `RAT_CAT3` correction](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2007_data_release.htm) to loaded copies, retaining `rat_cat3_raw` and `rat_cat3_corrected_2007`. Already-corrected source files are accepted without further changes; source files are not modified by the correction.

| Era | Main poverty | Main grouped/dollar family income | Separate MI |
|---|---|---|---|
| 2004–2006 | `RAT_CAT` | Eleven-band `INCGRP`; no continuous dollars | Five categorical `INCMIMP` plus five continuous `INCIMPS` |
| 2007–2013 | Primary `RAT_CAT2`, alternative `RAT_CAT3` | Five-band/coarse `INCGRP2`, four-band bridge `INCGRP3` | 2007–2008: `INCMIMP` + `INCIMPS`; 2009 onward: five continuous `INCMIMP` |
| 2014–2018 | Primary `RAT_CAT4`, alternative `RAT_CAT5` | Five-band/coarse `INCGRP4`, four-band bridge `INCGRP5` | Five continuous `INCMIMP` |
| 2019–2020 | `RATCAT_A/C`, `POVRATTC_A/C`, main implicate 1 | `INCGRP_A/C`, continuous `FAMINCTC_A/C`, main implicate 1 | Ten `adultinc`/`childinc` implicates including dollars |
| 2021–2024 | `RATCAT_A/C`, `POVRATTC_A/C`, main implicate 1 | **Both grouped income and continuous family dollars absent from main and MI files** | Ten poverty implicates; dollars withheld beginning in 2021 |

Continuous public ratios are disclosure-limited, not exact unrestricted income. Post-2019 ratios have two decimal places and are top-coded at 10 in 2019, 11 from 2020. `INCTCFLG_A/C` concerns family-dollar top-coding, can vary across implicates, and is absent in 2021 but returns in 2022. The dollar fields do not return with that flag.

---

## Weights and Survey Design

**Single-year analysis:**
```stata
svyset ppsu [pweight=wtfa_a], strata(pstrat)
svy: reg outcome demographics
```

**Multi-year pooling:** Divide weights by the number of years:
```stata
gen wtfa_adj = wtfa_a / 6    // for 2019-2024 (6 years)
svyset ppsu [pweight=wtfa_adj], strata(pstrat)
```

The cleaning scripts create `wtfa_adj` automatically based on the number of years in the dataset.

**Stratum offsets for pooling across design periods:**
- 2004–2005: Uses `stratum`/`psu` → renamed to `pstrat`/`ppsu` with `pstrat = 1000 + stratum`
- 2006–2015: Uses `strat_p`/`psu_p` → renamed with `pstrat = 2000 + strat_p`
- 2016–2018: Uses native `pstrat`/`ppsu`, with no added offset
- 2019–2024: Uses `pstrat`/`ppsu` natively (no offset needed)

These existing offsets distinguish some earlier periods; they do not certify pooled inference across all redesigns. Check annual survey-design guidance before pooling. The optional MI examples use one year and annual weights.

---

## Important Notes

### Coding Conventions

In both eras, most binary health variables use:
- `1` = Yes
- `2` = No

Pre-2019 missing codes: values > 2 (typically 7=Refused, 8=Not ascertained, 9=Don't know).
Post-2019 missing codes: `7` = Refused, `8` = Not ascertained, `9` = Don't know.

The cleaning scripts recode to `1`/`0` binary and treat all other values as missing.

**Sex coding differs from other surveys:** In the NHIS, `sex_a = 1` is **Male** and `sex_a = 2` is **Female**. This is opposite to the YRBS (where `sex = 1` is Female).

### Data Availability by Year

| Year Range | File Structure | Raw Format | Status in This Repo |
|---|---|---|---|
| 2004–2014 | 5-file hierarchical | `.DAT` → `.dta` (via CDC do-files) | Ready: `.dta` files available (or auto-created) |
| 2015–2018 | 5-file hierarchical | `.zip` archives / CSV alternatives | Ready for adult builds: Stata extracts archives and uses CSV fallback as needed |
| 2019–2024 | 2-file flat | `.csv` in `.zip` | Ready: scripts auto-unzip |

**Default coverage:** The starter scripts process **2019–2024** by default (post-redesign, simple CSV files). To include pre-2019 adult years, set `pre2019_years <- 2004:2018` in R after running the Stata loader once, or set `global nhis_pre2019_years "2004 ... 2018"` in Stata.

**Special file note:**
- 2017: `familyxx.zip` (fixed-width) is missing; the Stata loader uses `familyxxcsv.zip` as fallback

### Special Years

- **2020:** COVID-disrupted. Data collection was significantly affected. Extra files were created (`adultlong`, `adultpart`). Consider sensitivity analyses excluding 2020.
- **2019:** First year of the redesign. Has both interim (`wtia_a`) and final (`wtfa_a`) weights.
- **2004–2005:** Different stratum/PSU variable names (`stratum`/`psu` vs. `strat_p`/`psu_p`).
- **2004–2010:** No interview month variable; only quarter (`intv_qrt`) and week (`assignwk`).
- **2011–2018:** Has interview month (`intv_mon`).

### Child File

The starter scripts produce a combined child file (`nhis_child.dta`) alongside the adult file. The child file is built the same way — merging personsx + familyxx + househld + samchild for pre-2019, and importing child CSVs for post-2019. With the current shared files, child coverage is 2004–2024 when all years are enabled.

The cleaning script (`02_clean_and_analyze`) focuses on the adult file. To clean the child file, adapt the script using:
- Input: `output/nhis_child.dta` / `.rds`
- Variable suffix: `_c` instead of `_a` (for post-2019 variables)
- Weight: `wtfa_c` instead of `wtfa_a`
- Child-specific health variables from the `samchild` component

The original RDC research scripts provide a template for child health outcomes (access, utilization, school days lost, etc.).

### Income Imputation Files: Optional R/Stata Workflow

The ordinary `01`/`02` path remains one row per selected adult/child. Optional `03_load_income_implicates_optional.*` supports **every year 2004–2024**, defaults to 2024 and both samples, and produces separate completed long files. Optional `04_income_mi_example_optional.*` is disabled by default and demonstrates single-year survey means pooled across **all five** pre-2019 or **all ten** post-2019 implicates. It never overwrites ordinary starter files.

Download the income archives and documentation from the official annual CDC release pages: [2004](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2004_data_release.htm), [2007](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2007_data_release.htm), [2018](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2018_data_release.htm), and [2024 downloads](https://www.cdc.gov/nchs/nhis/documentation/2024-nhis.html). Other years are available through the [NHIS documentation index](https://www.cdc.gov/nchs/nhis/documentation/index.html). These income files are separate downloads from the main adult/child files.

Extract files locally with their original names; do not substitute derived DTA files for raw income ASCII. A supported placement is:

```text
data/NHIS 2004/INCIMPS/incimps1.dat ... incimps5.dat
data/NHIS 2004/INCMIMP/INCMAP1.dat ... INCMAP5.dat
data/NHIS 2005/INCMIMP/INCMIMP1.DAT ... INCMIMP5.DAT
... (2005–2008 also require INCIMPS and categorical INCMIMP)
data/NHIS 2009/INCMIMP/INCMIMP1.DAT ... INCMIMP5.DAT
data/NHIS 2010/INCMIMP/incmimp1.dat ... incmimp5.dat
... (through 2018; filename case variants accepted)
data/NHIS 2024/adultinc24csv/adultinc24.csv
data/NHIS 2024/childinc24csv/childinc24.csv
```

The same income filenames directly in the annual folder are also accepted. A second matching copy is an error. For 2019–2024 use the CSV downloads and extract the ZIPs first. For older self-extracting downloads, extract the data with an archive utility; do not execute legacy Windows programs on macOS. Early `INCIMPS` lacks response flags, so `03` joins its categorical `INCMIMP` companion by person and imputation number. Raw `POVRATI2/3` is scaled once using the annual layout; missing sentinels are removed before scaling.

First run a matching `01` loader with **every requested MI year**, in the same language. Defaults of either ordinary loader include 2024. Then, from `nhis/`:

```r
source("code/03_load_income_implicates_optional.R") # 2024, adults + children
source("code/04_income_mi_example_optional.R")     # disabled by default
# Opt in after reviewing the example:
run_mi_example <- TRUE
mi_example_year <- 2024L
mi_example_sample <- "adult"
source("code/04_income_mi_example_optional.R")
```

```stata
do code/03_load_income_implicates_optional.do      // 2024, adults + children
do code/04_income_mi_example_optional.do          // disabled by default
global nhis_run_mi_example 1
global nhis_mi_example_year 2024
global nhis_mi_example_sample "adult"
do code/04_income_mi_example_optional.do
```

From the repo root, prepend `nhis/` to the script paths; from `nhis/code/`, use the script basename. `NHIS_ROOT` / `nhis_root_manual` in R and global `nhis_root` in Stata also work. `NHIS_OUTPUT_DIR` / `nhis_output_dir` and global `nhis_output_dir` select the ordinary input/output directory. `mi_base_dir` / global `nhis_mi_base_dir` can point to different existing ordinary outputs; `NHIS_MI_OUTPUT_DIR` / `mi_output_dir` and global `nhis_mi_output_dir` set the separate MI output directory.

To request older/nonconsecutive years, set `mi_years <- c(2004, 2018, 2024)` in R or `global nhis_mi_years "2004 2018 2024"` in Stata, and build ordinary inputs containing those years first. Set `mi_samples <- "child"` / `global nhis_mi_samples "child"` for children only. Settings are visible near the top of the scripts. The optional loader repeats a compact set of ordinary design/demographic fields; `mi_base_extra_vars` / global `nhis_mi_base_extra_vars` adds retained ordinary covariates. Income fields cannot be base extras because they must come from the completed files.

Outputs are `nhis_adult_income_mi_long.rds` / `.dta` and `nhis_child_income_mi_long.rds` / `.dta`, containing completed records only, with canonical `implicate`, year-local `mi_person_id`, `mi_M`, `poverty_ratio_mi`, `family_income_mi` when released, `below_poverty_mi`, `low_income_mi`, and native fields/flags. In a mixed-era stack, the family-income column is structurally missing from 2021 onward. For 2004–2008, the binary poverty indicators use official completed `RAT_CATI` categories; rounded ratios can equal 1.00 or 2.00 while these categories place the person below the threshold. From 2009, the indicators use released ratio cutoffs. `poverty_binary_mi_src` records 0 unavailable, 1 official completed category, or 2 released ratio. Separate `below_poverty_from_ratio_mi` and `low_income_from_ratio_mi` retain ratio cutoffs in every year for comparison; `poverty_ratio_mi` is unchanged. The canonical binary construction changes at 2009; use the `*_from_ratio_mi` companions for the same cutoff rule across all years, while accounting for changes in released ratio precision and disclosure limits. R's optional Stata export uses `_from_r.dta` and is off by default. R examples save a separate `_income_mi_example.rds`; Stata saves `_income_mi_example.ster`.

Before 2019 the merge key is `SRVY_YR HHX FMX FPX` plus implicate. From 2019 it is year plus `HHX` plus implicate, **within each separate adult or child sample**. Identifiers retain leading zeros. `03` rejects duplicate keys, incomplete M sets, missing selected persons, invalid design fields and conflicting observed-status values. Nonselected pre-2019 household members are excluded after linking; no adult/child cross-merge occurs. Main-file income overlap is removed before the join.

Install optional R inference dependencies with `install.packages(c("survey", "mitools"))`; scripts do not install packages. R uses one survey design per completed dataset, finite survey degrees of freedom, and Rubin's rules. Stata creates m=0 using exact-report flags plus invariance checks, imports completed data, registers only invariant base fields as regular, and uses `mi estimate: svy: mean`. Varying native imputation-number and top-code fields remain in the flat file. The Stata example compares completed values against a pre-import snapshot through estimation.

Annual sample weights are used in each implicate, **without dividing by M**. Analyze every completed dataset, then pool coefficients and within/between-imputation variances. Never average person-level imputed values into one dataset, count the stacked records as independent people, or present one implicate as complete income inference. Optional age domains use `mi_domain_age_min` / global `nhis_mi_domain_age_min` and survey subpopulation methods. Income-dependent domains require within-implicate membership and their own model/df checks. These first examples are single-year poverty means; earnings MI and cross-era pooled designs need additional review. See the [income matrix](docs/income_variable_matrix.md) and [CDC MI technical guidance](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2024/NHIS2024-imputation-techdoc.pdf).

### Content Changes Over Time

The NHIS questionnaire content changes annually. Key additions in the 2019+ redesign:
- **PHQ-8** (depression screener) and **GAD-7** (anxiety screener) — new in 2019+
- **Exchange/marketplace** insurance questions — new/expanded post-ACA
- **Social determinants of health** — added in later years (2022+)
- **Chronic fatigue, traumatic brain injury, allergies** — added in 2024

Always check the year-specific codebook before assuming a variable exists.

---

## Common Research Applications

The NHIS is widely used in health economics and health services research for:
- **Health insurance coverage** trends and disparities (long time series back to 2004+)
- **ACA evaluation** (comparing pre/post 2010, 2014 implementation)
- **Health disparities** by race/ethnicity, income, education, immigration status
- **Chronic disease** prevalence and trends
- **Health care access** and utilization patterns
- **Mental health** screening and trends (2019+)
- **Immigration and health** (citizenship, nativity, mixed-status families)

---

## Citation

When using NHIS data, cite:

> National Center for Health Statistics. National Health Interview Survey, [year]. Hyattsville, Maryland. Available at: https://www.cdc.gov/nchs/nhis/index.htm

The redesign documentation should also be cited when using 2019+ data:

> National Center for Health Statistics. Redesigned National Health Interview Survey. Series 2, Number 207. June 2024.

Income notes: legacy FPL labels refer to the Census poverty-threshold ratio, not HHS poverty guidelines. In the early MI files, undefined categorical poverty status overrides the continuous ratio bytes. The 2004 supplement has a verified `01E8` undefined marker in 19 records per implicate; `03` preserves raw text and treats it as missing, and `04` reports exclusions. Other unexpected non-numeric income fields stop the loader. Pre-2019 response, category and top-code fields must have documented codes; undefined flags, categories and ratio markers must agree. Required redesigned income values cannot be blank. The pre-2019 ratio limit of 100 is a conservative validation guard, not an official top-code. R mitools and Stata MI use slightly different pooled small-sample degrees-of-freedom formulas, so confidence limits can differ even when pooled estimates and variances agree. Sparse-domain complete-data df can also differ between R subset designs and Stata subpopulation designs; review both conventions before adapting the example.
