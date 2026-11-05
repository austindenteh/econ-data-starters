# NHIS public income variables, 2004–2024

This note distinguishes reported categories in the older main files from completed income values in separate multiple-imputation (MI) files. From 2019, the convenient main-file income values are **implicate 1 of ten**, including both reported and imputed responses. A complete income analysis uses every released implicate and pools estimates and variances. The ordinary starter does not perform MI inference.

## Availability by era

| Era | Main-file poverty variables | Main-file family income | Personal earnings | Separate completed income files |
|---|---|---|---|---|
| 2004–2006 | `RAT_CAT`: detailed categories 1–14; 96 undefined, 99 unknown | `INCGRP`: eleven detailed bands; coarse 12/13; 97/98/99 nonresponse. No continuous dollars | `ERNYR_P`: eleven bands | Five categorical `INCMIMP` files plus five continuous `INCIMPS` files; early continuous files lack imputation-status flags |
| 2007–2013 | `RAT_CAT2` detailed/primary and `RAT_CAT3` alternative; both include coarse codes | `INCGRP2`: five detailed bands and coarse 6–8; `INCGRP3`: four-band bridge | `ERNYR_P` | 2007–2008: five categorical `INCMIMP` plus continuous `INCIMPS`; 2009–2013: five continuous `INCMIMP` |
| 2014–2018 | `RAT_CAT4` detailed/primary and `RAT_CAT5` alternative; coarse codes | `INCGRP4`: five detailed bands and coarse 6/7; `INCGRP5`: four-band bridge with some additional classified responses | `ERNYR_P` | Five continuous `INCMIMP` files |
| 2019–2020 | `RATCAT_A/C` and continuous `POVRATTC_A/C`; main values are implicate 1 | `INCGRP_A/C` five bands and `FAMINCTC_A/C` top-coded continuous dollars; main values are implicate 1 | Not released | Separate `adultinc`/`childinc` CSVs, ten rows per sample person; dollars and poverty measures |
| 2021–2024 | `RATCAT_A/C` and `POVRATTC_A/C`; main values are implicate 1 | **Neither grouped income nor continuous family dollars is released**, in either main or MI files | Not released | Ten poverty implicates per sample person in `adultinc`/`childinc`; no public dollar-income field |

The pre-2019 paired names identify **alternative detailed/bridge categorical constructions**, not multiple-imputation implicates. Actual implicates have their own records/files and an imputation-number field. See the [2007 family layout](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2007/familyxx_layout.pdf), [2018 family layout](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2018/familyxx_layout.pdf), and [2018 income release description](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2018_data_release.htm). The withholding of dollars begins in 2021, as documented in the [2021 survey description](https://stacks.cdc.gov/view/cdc/148808/cdc_148808_DS1.pdf), printed pp. 113–114.

## Main-file code meanings and starter recodes

The detailed poverty codes are the same intervals across eras:

| Code | Ratio | Code | Ratio |
|---|---|---|---|
| 1 | <0.50 | 8 | 2.00–2.49 |
| 2 | 0.50–0.74 | 9 | 2.50–2.99 |
| 3 | 0.75–0.99 | 10 | 3.00–3.49 |
| 4 | 1.00–1.24 | 11 | 3.50–3.99 |
| 5 | 1.25–1.49 | 12 | 4.00–4.49 |
| 6 | 1.50–1.74 | 13 | 4.50–4.99 |
| 7 | 1.75–1.99 | 14 | ≥5.00 |

`RAT_CAT` in 2004–2006 has no coarse codes 15–18. In 2007–2018, primary `RAT_CAT2/4` codes 15, 16, 17 mean <1, 1–1.99, ≥2 with no further detail. Alternative `RAT_CAT3/5` codes 15, 16, 17, 18 mean <1, 1–1.99, 2–3.99, ≥4. An unsplittable primary code 17 can become unknown/undefined in the alternative. Unknown is 99; undefined is 96 where defined in the annual layout. Post-2019 `RATCAT_A/C` contains substantive codes 1–14, not a released 98 nonresponse category.

Legacy FPL labels mean a Census poverty-threshold ratio here, not HHS poverty guidelines. The original `pov_cat`, `below_poverty`, and `low_income` use only detailed codes 1–14. Separate `*_with_coarse` companions conservatively include primary code 15 as below poverty and 16 as 100–199%; code 17 identifies both binary outcomes as zero but cannot distinguish 200–399% from ≥400%. `pov_cat_src` and `poverty_binary_src` are 0 unavailable, 1 detailed, 2 interview bracket. Alternative `RAT_CAT3/5` does not fill these companions.

These bracket companions carry an interpretive limit: the [2018 survey description](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2018/srvydesc.pdf), printed pp. 43–44 and Table 9, distinguishes estimated thresholds used in the interview instrument from final Census thresholds used for detailed recodes. The companions are sensitivity measures based on reported interview brackets; they are not guaranteed classifications against final thresholds. This precise threshold-construction evidence is for 2018; consult each earlier year's documentation.

### Family income categories

| Field | Detailed codes | Coarse or non-substantive codes |
|---|---|---|
| `INCGRP`, 2004–2006 | 1: $0–4,999; 2: $5,000–9,999; 3: $10,000–14,999; 4: $15,000–19,999; 5: $20,000–24,999; 6: $25,000–34,999; 7: $35,000–44,999; 8: $45,000–54,999; 9: $55,000–64,999; 10: $65,000–74,999; 11: ≥$75,000 | 12: ≥$20,000 without detail; 13: <$20,000 without detail; 97 refused, 98 not ascertained, 99 unknown |
| `INCGRP2`, 2007–2013 | 1: <$35,000; 2: $35,000–49,999; 3: $50,000–74,999; 4: $75,000–99,999; 5: ≥$100,000 | 6: <$50,000; 7: ≥$50,000; 8: $50,000–99,999; 99 unknown |
| `INCGRP4`, 2014–2018 | Same five detailed bands | 6: <$50,000; 7: $50,000–99,999; 96 undefined, 99 unknown |
| `INCGRP3/5` bridge | 1: <$35,000; 2: $35,000–74,999; 3: $75,000–99,999; 4: ≥$100,000 | 96 undefined, 99 unknown |
| `INCGRP_A/C`, 2019–2020 | Same five detailed bands as `INCGRP2/4`, completed implicate 1 in the main file | Absent from 2021 onward |

The starter's five-band `income_cat` uses conservative bounds in 2004–2006: codes 1–6 and 13 → first band, 7 → second, 9–10 → third. Code 8 crosses the $50,000 cutoff; code 11 cannot distinguish the two upper bands; code 12 crosses several bands. They remain missing in the five-band measure. The new `income_cat3` uses <$35,000 / $35,000–74,999 / ≥$75,000, so old code 8 and 11 can be classified. Later detailed five-band codes collapse to these three bands. In 2014–2018 only, an eligible missing three-band value is filled from `INCGRP5`, after a consistency assertion. `income_cat3_src` is 0 unavailable, 1 primary, 2 bridge. No raw-code coalescing occurs. Coarse `INCGRP2` 6–8 and `INCGRP4` 6–7 do not identify any of these complete bands and remain missing. All dollar bands are nominal. The five-band measure is **partial and selected by income in 2004–2006**: neither upper band can be identified, and the $45,000–54,999 band is omitted. Use `income_cat3` for cross-era distributions rather than presenting the partial five-band distribution as representative.

For the original categories, consult the [2004 release documentation](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2004_data_release.htm) and the annual family layouts, rather than assuming the later five-band scheme applies to all years.

### 2007 correction and earnings

The [2007 CDC correction](https://archive.cdc.gov/www_cdc_gov/nchs/nhis/nhis_2007_data_release.htm) replaces `RAT_CAT3=17` with 99 when `FM_SIZE<=2` and `INCGRP2=2`. The loaders apply the verified rule to the loaded copy only, save its incoming value as `rat_cat3_raw`, and mark changed observations in `rat_cat3_corrected_2007`. Already-corrected inputs produce no additional changes. The [correction archive](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2007/ratcat07.zip) is the official reference. The rule is not applied to other years. Unresolved behavior in later alternative constructions is another reason those alternatives do not enter default poverty companions.

`ERNYR_P` is personal work earnings during the previous calendar year for people in the work-for-pay universe (`WRKLYR1=1`). Its eleven bands begin at $1–4,999, then $5,000–9,999, $10,000–14,999, $15,000–19,999, $20,000–24,999, $25,000–34,999, $35,000–44,999, $45,000–54,999, $55,000–64,999, $65,000–74,999, ≥$75,000. Refused/not ascertained/unknown and blank out-of-universe values stay missing, not zero. `earn_cat` keeps the original broad five-band collapse; the optional MI examples concern family income/poverty, not employment or earnings with changing imputed universes.

## Imputation-number and status fields

| Field | Meaning and location |
|---|---|
| `IMPNUM` | 1–5 in pre-2019 MI; 1–10 in 2019–2020 `adultinc`/`childinc`. Not a main-file imputation-number field in 2019–2020 |
| `IMPNUM_A/C` | From 2021: 1–10 in MI files, 1 in main adult/child files |
| `IMPINCFLG_A/C` | 0 reported, 1 imputed with no income information, 2 imputed using reported brackets; response-status flag, invariant across implicates |
| `INCTCFLG_A/C` | Family dollar-income top-coding flag; 2019–2020, absent 2021, returns 2022–2024 even though dollars are withheld. Can vary across implicates; it is not an imputation number or a poverty-ratio top-coding flag |
| `INCGRP_F`, `RAT_CATF` | Early categorical income-group and poverty-category flags; their observed-status meanings differ. `INCGRP_F=0` can include bracket-only reporting and does not establish observed continuous dollars |
| `INCGRPF2`, `RATCATF2` | 2007–2008 categorical companion flags; 0 exact report, 1 imputed/no information, 2 imputed/bracket information, 5 undefined where documented |
| `FAMINCF2` | 2009–2018 continuous family-income response status: 0 reported, 1 imputed/no information, 2 imputed using reported categories |
| `TCINCM_F` | Pre-2019 family-income/poverty top-coding flag; can vary across completed files |

See the [2004 categorical layout](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/datdoc04.pdf), [2007 categorical layout](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/datdoc07.pdf), [2024 main adult codebook](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2024/Adult-codebook.pdf), and [2024 income summary](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2024/Adultinc-summary.pdf).

`income_value_src` in ordinary outputs is 0 pre-2019 reported construction, 1 post-2019 reported, 2 post-2019 imputed/main implicate 1. It describes response provenance, not availability of every derived category. Reported-only subsetting changes the analysis population and does not replace MI inference.

## Continuous measures and scaling

The optional loader reads **raw ASCII**, preserving the raw ratio field alongside `poverty_ratio_mi`. `INCIMPS` in 2004–2008 and `INCMIMP` in 2009 use `POVRATI2` with two implied decimals; 2010–2018 use `POVRATI3` with three. Remove 9999 / 999999 sentinels before dividing by 100 / 1000. Remove the continuous income sentinel 999999. In the verified [official 2004 supplement](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NHIS/2004_imputed_income/incimps.zip), 19 records per implicate contain `01E8` rather than the layout's 9999 undefined marker; their companion `RAT_CATF=5` and `RAT_CATI=96` establish undefined poverty status. The loader preserves original field text, overrides undefined ratios to missing from these flags, and rejects other unexpected non-digit numeric fields. Pre-2019 response, category and top-code fields require documented codes; undefined flags, categories and ratio markers must agree. A pre-2019 ratio bound of 100 is a conservative corruption/scale guard, not an official top-code. Some CDC setup programs already scale or rename fields, so derived local DTA files are unsuitable inputs for this adapter. Early continuous files require the categorical companion to identify observed response status. `INCGRPI2` in 2007–2008 MI has **21 bands**, unlike the main-file five-band `INCGRP2`.

From 2019, CSV `POVRATTC_A/C` already has decimal places and is rounded to two decimals, top-coded at 10 in 2019 and 11 from 2020. Required redesigned income values cannot be missing; unexpected non-numeric CSV fields and invalid response flags stop the optional loaders. It remains disclosure-limited continuous data; it does not permit recovering public family dollars in 2021–2024. See the [2004 supplement layout](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/SUP3PU04.pdf), [2018 MI layout](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/datdoc18.pdf), and [2024 imputation technical document](https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/NHIS/2024/NHIS2024-imputation-techdoc.pdf).

## Estimation boundary

`03_*` produces completed long files, retaining native income/status fields. Each person is identified by year plus `HHX/FMX/FPX` before 2019, and year plus `HHX` within each separate adult/child sample afterward. `implicate` is the canonical completed-data number; `mi_person_id` is year-local and must be paired with year. `mi_M` is 5 or 10. `income_response` copies `RAT_CATF` (2004–2006), `RATCATF2` (2007–2008), `FAMINCF2` (2009–2018), or `IMPINCFLG_A/C` (2019 onward); nonzero codes retain their era-specific meanings. `income_observed` identifies the conservative exact-report criterion used for continuous targets. Base fields repeat across implicates and income overlap is excluded before merging.

For 2004–2008, `below_poverty_mi` and `low_income_mi` use the official completed `RAT_CATI`: substantive codes 1–3 are below poverty; 1–7 are below twice the poverty threshold. Undefined status stays missing. The released two-decimal ratios can round up to exactly 1.00 or 2.00 while the official category remains below that threshold. Thus cutting the rounded ratios understates these binary shares slightly in the verified early files. From 2009, these indicators use the released ratio cutoffs `<1` and `<2`. `poverty_binary_mi_src` is 0 unavailable, 1 official completed category (2004–2008), or 2 released continuous ratio (2009–2024). `below_poverty_from_ratio_mi` and `low_income_from_ratio_mi` retain ratio-derived indicators in every year for comparison. `poverty_ratio_mi` itself is unchanged. The canonical binary construction changes at 2009; the `*_from_ratio_mi` companions apply the same cutoff rule across years, with era-specific precision and disclosure limits. See the [2004 imputation documentation](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/datdoc04.pdf) and [2007 imputation documentation](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/datdoc07.pdf) for category bounds, and the [2004 continuous supplement](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/SUP3PU04.pdf) and [2007 continuous supplement](https://archive.cdc.gov/www_cdc_gov/nchs/data/nhis/SUP3PU07.pdf) for ratio precision.

The disabled `04_*` examples use one year, annual adult/child weights, `PSTRAT/PPSU`, and every implicate. R analyzes every survey design and applies `MIcombine` with finite complete-data survey degrees of freedom. Stata constructs m=0 only from documented exact-report status and invariant completed continuous values, imports completed data, registers variables safely, and uses `mi estimate: svy: mean`. Completed values are compared to a snapshot made before import through estimation. Both examples print undefined-target exclusions and reject changing eligibility. R `mitools::MIcombine` and Stata MI use slightly different pooled small-sample df formulas; pooled estimates/variances can agree while confidence limits differ. Sparse age domains can also give different complete-data df in R subset designs and Stata survey subpopulation designs. Check estimates/variances separately from both df conventions. Native varying imputation-number and top-code fields stay in the flat output rather than being incorrectly registered regular.

Age-domain membership is evaluated in each R design; Stata uses survey subpopulation estimation. Income-dependent domains should likewise be defined within each completed dataset and need their own analysis/df review. This release does not supply a pooled cross-era MI model, an earnings MI model, new imputations, or a Stata m=0 adapter for additional categorical targets beyond the supplied binary poverty indicators. Observed status must be target-specific: in 2004–2006 `INCGRP_F=0` establishes an observed income group, whereas `RAT_CATF=0` is the conservative criterion for observed poverty category and continuous income/ratio. The supplied binary indicators are checked for invariance among these exact-report records. Do not reuse one universal flag for other categorical targets.

References: [R survey MI analysis](https://r-survey.r-forge.r-project.org/pkgdown/docs/reference/with.svyimputationList.html), [mitools pooling and df](https://search.r-project.org/CRAN/refmans/mitools/html/MIcombine.html), [Stata MI import](https://www.stata.com/manuals/mimiimportflong.pdf), [Stata MI estimation](https://www.stata.com/manuals/miestimation.pdf). Pool estimates and variances, not the individual income values. Do not analyze a single implicate as a complete income analysis, average the implicate values into one dataset, treat the stack as independent people, or divide survey weights by the number of imputations.
