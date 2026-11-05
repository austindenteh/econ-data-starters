********************************************************************************
* Disabled-by-default SINGLE-YEAR example: all 5/10 completed income implicates.
* USER SETTINGS: set globals before do, or edit defaults below.
* global nhis_run_mi_example 1
* global nhis_mi_example_year 2024
* global nhis_mi_example_sample "adult"
* global nhis_mi_domain_age_min 65  // optional age domain
* global nhis_root "/path/to/nhis"
* global nhis_output_dir "/path/to/output"
* global nhis_mi_output_dir "/path/to/mi/output"
********************************************************************************
clear all
set more off
local run_mi_example 0
if "$nhis_run_mi_example" == "1" local run_mi_example 1
if `run_mi_example' == 0 {
    display as text "MI example disabled. Set global nhis_run_mi_example 1 after 01 and 03."
    exit
}
local cwd "`c(pwd)'"
if "$nhis_root" != "" & fileexists("$nhis_root/code/04_income_mi_example_optional.do") {
    global nhis_root "$nhis_root"
}
else if fileexists("code/04_income_mi_example_optional.do") & fileexists("README.md") {
    global nhis_root "`cwd'"
}
else if fileexists("04_income_mi_example_optional.do") & fileexists("../README.md") {
    global nhis_root "`cwd'/.."
}
else if fileexists("nhis/code/04_income_mi_example_optional.do") & fileexists("nhis/README.md") {
    global nhis_root "`cwd'/nhis"
}
else {
    display as error "Could not locate the nhis/ directory."
    display as error "Run from nhis/, nhis/code/, from the repo root, or set global nhis_root."
    display as error `"Manual override: global nhis_root "/path/to/nhis""'
    error 601
}

cd "$nhis_root"
local output_dir "output"
if "$nhis_output_dir" != "" {
    local output_dir "$nhis_output_dir"
}
capture mkdir "`output_dir'"

local base_dir "`output_dir'"
if "$nhis_mi_base_dir" != "" local base_dir "$nhis_mi_base_dir"
local mi_output_dir "`output_dir'"
if "$nhis_mi_output_dir" != "" local mi_output_dir "$nhis_mi_output_dir"
capture mkdir "`mi_output_dir'"
local year 2024
if "$nhis_mi_example_year" != "" local year = real("$nhis_mi_example_year")
local sample "adult"
if "$nhis_mi_example_sample" != "" local sample "$nhis_mi_example_sample"
if !inrange(`year',2004,2024) | `year' != floor(`year') | !inlist("`sample'","adult","child") {
    display as error "Choose one integer year from 2004 through 2024 and sample adult or child."
    error 198
}
local suffix "a"
if "`sample'" == "child" local suffix "c"
local M 5
if `year' >= 2019 local M 10
use "`mi_output_dir'/nhis_`sample'_income_mi_long.dta", clear
keep if srvy_yr == `year'
isid mi_person_id implicate
assert inrange(implicate,1,`M') & implicate == floor(implicate)
bysort mi_person_id (implicate): assert _N == `M'
by mi_person_id: assert income_observed == income_observed[1]
foreach v in poverty_ratio_mi below_poverty_mi low_income_mi {
    by mi_person_id: assert `v' == `v'[1] if income_observed == 1
}
gen byte mi_unavailable = missing(poverty_ratio_mi,low_income_mi)
by mi_person_id: assert mi_unavailable == mi_unavailable[1]
quietly count if implicate == 1 & mi_unavailable == 1
display as text "[INFO] Selected sample: " r(N) " persons have undefined targets and are excluded from these means."
local regular "srvy_yr hhx pstrat ppsu wtfa_`suffix' income_observed mi_unavailable"
capture confirm variable agep_`suffix'
if _rc == 0 local regular "`regular' agep_`suffix'"
foreach v of local regular {
    by mi_person_id: assert `v' == `v'[1]
}
* Narrow estimation container. Varying native imputation-number/top-code fields
* remain in the flat 03 output and cannot be registered regular here.
keep mi_person_id implicate `regular' poverty_ratio_mi below_poverty_mi low_income_mi
sort mi_person_id implicate
tempfile completed original
save `completed'
* m=0: continuous targets observed only when the documented response flag says
* exact income reported, with invariance already checked above. A reported
* early category does not establish an observed continuous dollar amount.
keep if implicate == 1
replace implicate = 0
foreach v in poverty_ratio_mi below_poverty_mi low_income_mi {
    replace `v' = . if income_observed != 1
}
append using `completed'
mi import flong, m(implicate) id(mi_person_id) ///
    imputed(poverty_ratio_mi below_poverty_mi low_income_mi) clear
drop implicate
mi register regular mi_person_id `regular'
mi update
* Compare m>0 against the snapshot made BEFORE import/registration/update.
* cf works on matching row order and values; temporary native MI identifiers
* do not enter the comparison. Repeat after estimation below.
capture program drop nhis_check_completed
program define nhis_check_completed
    syntax, Snapshot(string) Vars(string) M(integer)
    preserve
        keep if _mi_m > 0
        rename _mi_m implicate
        sort mi_person_id implicate
        cf `vars' using "`snapshot'", all
    restore
end
local checkvars "mi_person_id implicate `regular' poverty_ratio_mi below_poverty_mi low_income_mi"
nhis_check_completed, snapshot("`completed'") vars("`checkvars'") m(`M')
mi varying
mi svyset ppsu [pweight=wtfa_`suffix'], strata(pstrat)
if "$nhis_mi_domain_age_min" != "" {
    confirm variable agep_`suffix'
    local minage = real("$nhis_mi_domain_age_min")
    if missing(`minage') error 198
    gen byte mi_domain = !missing(agep_`suffix') & agep_`suffix' >= `minage'
    mi register regular mi_domain
    mi estimate, post: svy, subpop(mi_domain): mean poverty_ratio_mi low_income_mi
}
else {
    mi estimate, post: svy: mean poverty_ratio_mi low_income_mi
}
estimates save "`mi_output_dir'/nhis_`sample'_income_mi_example.ster", replace
matrix list e(b)
matrix list e(V)
nhis_check_completed, snapshot("`completed'") vars("`checkvars'") m(`M')
display as text "[PASS] All completed values unchanged from before MI import through estimation."
* Uses annual weights and Rubin pooling. No weights/M and no single-implicate
* inference. Cross-era pooling/earnings require separate design/universe review.
