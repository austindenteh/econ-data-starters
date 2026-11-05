********************************************************************************
* Optional completed income MI loader, 2004-2024. Run a matching 01 loader first.
* Five implicates before 2019, ten from 2019 onward; no estimation or imputation.
* USER SETTINGS: set globals before do, or edit defaults below.
* global nhis_root "/path/to/nhis"
* global nhis_output_dir "/path/to/ordinary/output"
* global nhis_mi_output_dir "/path/to/mi/output"
* global nhis_mi_years "2004 2018 2024"
* global nhis_mi_samples "adult child"
* global nhis_mi_base_extra_vars "educ_a"
********************************************************************************
clear all
set more off
local cwd "`c(pwd)'"
if "$nhis_root" != "" & fileexists("$nhis_root/code/03_load_income_implicates_optional.do") {
    global nhis_root "$nhis_root"
}
else if fileexists("code/03_load_income_implicates_optional.do") & fileexists("README.md") {
    global nhis_root "`cwd'"
}
else if fileexists("03_load_income_implicates_optional.do") & fileexists("../README.md") {
    global nhis_root "`cwd'/.."
}
else if fileexists("nhis/code/03_load_income_implicates_optional.do") & fileexists("nhis/README.md") {
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
local years "2024"
if "$nhis_mi_years" != "" local years "$nhis_mi_years"
local samples "adult child"
if "$nhis_mi_samples" != "" local samples "$nhis_mi_samples"
local unique_years : list uniq years
if "`years'" != "`unique_years'" {
    display as error "Choose distinct MI years from 2004 through 2024."
    error 198
}
foreach y of local years {
    if missing(real("`y'")) | !inrange(real("`y'"),2004,2024) | real("`y'") != floor(real("`y'")) {
        display as error "MI years must be integers from 2004 through 2024."
        error 198
    }
}
local unique_samples : list uniq samples
if "`samples'" != "`unique_samples'" {
    display as error "Choose adult and/or child without duplicate samples."
    error 198
}
foreach s of local samples {
    if !inlist("`s'","adult","child") {
        display as error "MI samples must be adult and/or child."
        error 198
    }
}
foreach v in $nhis_mi_base_extra_vars {
    if regexm("`v'","^(rat_?cat|incgrp|famin|family_income|povrat|poverty_|pov_cat|implicate|mi_|impnum|impinc|inctc|income_|below_poverty|low_income|ernyr|tcinc)") {
        display as error "Income fields cannot be base extras; use implicate source fields."
        error 198
    }
}
capture program drop nhis_mi_find
program define nhis_mi_find, rclass
    syntax, Year(integer) Folder(string) Names(string)
    local hits 0
    local path ""
    foreach dir in "data/NHIS `year'/`folder'" "data/NHIS `year'" {
        local actual ""
        capture local actual : dir "`dir'" files "*"
        foreach f of local actual {
            local matched 0
            foreach name of local names {
                if lower("`f'") == lower("`name'") local matched 1
            }
            if `matched' {
                local hits = `hits'+1
                local path "`dir'/`f'"
            }
        }
    }

    if `hits' != 1 {
        display as error "Need exactly one of `names' under data/NHIS `year'/`folder' or its year folder."
        display as error "Extract the official archive first; do not use derived income DTA files."
        error 601
    }
    return local path "`path'"
end
capture program drop nhis_mi_keys
program define nhis_mi_keys
    syntax, Year(integer)
    foreach v in hhx fmx fpx {
        if `year' >= 2019 & "`v'" != "hhx" continue
        capture confirm variable `v'
        if _rc == 0 {
            capture confirm numeric variable `v'
            if _rc == 0 {
                if "`v'" == "hhx" tostring `v', replace format(%06.0f)
                else tostring `v', replace format(%02.0f)
            }
            replace `v' = trim(`v')
            assert !missing(`v') & `v' != "."
            if `year' < 2019 {
                if "`v'" == "hhx" replace `v' = substr("000000"+`v',-6,6)
                else replace `v' = substr("00"+`v',-2,2)
            }
        }
    }
end
foreach s of local samples {
    local suffix "a"
    if "`s'" == "child" local suffix "c"
    local basefile "`base_dir'/nhis_`s'.dta"
    confirm file "`basefile'"
    use "`basefile'", clear
    local vars "srvy_yr hhx fmx fpx pstrat ppsu wtfa_`suffix' agep_`suffix' sex_`suffix' phstat_`suffix' notcov_`suffix' $nhis_mi_base_extra_vars"
    local present ""
    foreach v of local vars {
        capture confirm variable `v'
        if _rc == 0 local present "`present' `v'"
    }
    keep `present'
    tempfile base combined
    save `base'
    local firstyear 1
    foreach y of local years {
        use `base', clear
        keep if srvy_yr == `y'
        if _N == 0 {
            display as error "Base `s' file lacks `y'; re-run 01 with requested years."
            error 2000
        }
        nhis_mi_keys, year(`y')
        local keys "srvy_yr hhx"
        if `y' < 2019 local keys "`keys' fmx fpx"
        isid `keys'
        assert !missing(pstrat,ppsu,wtfa_`suffix') & wtfa_`suffix' > 0
        local persons = _N
        tempfile yearbase incs
        save `yearbase'
        local M 5
        if `y' >= 2019 local M 10
        if `y' < 2019 {
            forvalues m=1/5 {
                if `y' <= 2008 {
                    nhis_mi_find, year(`y') folder("INCIMPS") names("incimps`m'.dat INCIMPS`m'.DAT")
                    infix srvy_yr 3-6 str hhx 7-12 str fmx 13-14 str fpx 15-16 ///
                        impnum 17 str6 faminci2_raw_text 18-23 str1 tcincm_f 24 str4 povrati2_raw_text 25-28 using "`r(path)'", clear
                    tempfile continuous
                    save `continuous'
                    nhis_mi_find, year(`y') folder("INCMIMP") names("incmimp`m'.dat INCMIMP`m'.DAT INCMAP`m'.dat INCMAP`m'.DAT")
                    local path "`r(path)'"
                    if `y' <= 2006 {
                        infix srvy_yr 3-6 str hhx 7-12 str fmx 13-14 str fpx 15-16 ///
                            impnum 17 str1 incgrp_f 18 str2 incgrp_i 19-20 str1 rat_catf 21 str2 rat_cati 22-23 using "`path'", clear
                    }
                    else {
                        infix srvy_yr 3-6 str hhx 7-12 str fmx 13-14 str fpx 15-16 ///
                            impnum 17 str1 incgrpf2 18 str2 incgrpi2 19-20 str1 ratcatf2 21 str2 rat_cati 22-23 using "`path'", clear
                    }
                    isid `keys' impnum
                    merge 1:1 `keys' impnum using `continuous', assert(match) nogen
                }
                else {
                    nhis_mi_find, year(`y') folder("INCMIMP") names("incmimp`m'.dat INCMIMP`m'.DAT")
                    local path "`r(path)'"
                    if `y' == 2009 {
                        infix srvy_yr 3-6 str hhx 7-12 str fmx 13-14 str fpx 15-16 ///
                            impnum 17 str1 famincf2 18 str1 tcincm_f 19 str6 faminci2_raw_text 20-25 str4 povrati2_raw_text 26-29 using "`path'", clear
                    }
                    else {
                        infix srvy_yr 3-6 str hhx 7-12 str fmx 13-14 str fpx 15-16 ///
                            impnum 17 str1 famincf2 18 str1 tcincm_f 19 str6 faminci2_raw_text 20-25 str9 povrati3_raw_text 26-34 using "`path'", clear
                    }
                }
                * Validate raw flag/category bytes before numeric conversion.
                local codefields "tcincm_f famincf2"
                if `y' <= 2006 local codefields "tcincm_f incgrp_f incgrp_i rat_catf rat_cati"
                else if `y' <= 2008 local codefields "tcincm_f incgrpf2 incgrpi2 ratcatf2 rat_cati"
                foreach v of local codefields {
                    assert regexm(trim(`v'),"^[0-9]+$")
                    destring `v', replace
                }
                assert inlist(tcincm_f,0,1)
                if `y' <= 2006 {
                    assert inlist(incgrp_f,0,1,2) & inrange(incgrp_i,1,11)
                    assert inlist(rat_catf,0,1,2,3,5)
                    gen byte income_response = rat_catf
                }
                else if `y' <= 2008 {
                    assert inlist(incgrpf2,0,1,2) & inrange(incgrpi2,1,21)
                    assert inlist(ratcatf2,0,1,2,5)
                    gen byte income_response = ratcatf2
                }
                else {
                    assert inlist(famincf2,0,1,2)
                    gen byte income_response = famincf2
                }
                if `y' <= 2008 {
                    assert inrange(rat_cati,1,14) | rat_cati==96
                    assert (income_response==5) == (rat_cati==96)
                }
                assert srvy_yr == `y' & impnum == `m'
                assert regexm(trim(faminci2_raw_text),"^[0-9]+$") | trim(faminci2_raw_text)==""
                gen double faminci2 = real(faminci2_raw_text)
                if `y' <= 2009 {
                    assert regexm(trim(povrati2_raw_text),"^[0-9]+$") | trim(povrati2_raw_text)=="" | (`y'==2004 & povrati2_raw_text=="01E8")
                    gen double povrati2 = real(povrati2_raw_text)
                    if `y' <= 2008 {
                        assert income_response==5 & rat_cati==96 if povrati2_raw_text=="01E8"
                        assert inlist(povrati2_raw_text,"9999","01E8") == (income_response==5)
                        * Keep numeric 9999 in the native field, as R does.
                        replace povrati2 = . if povrati2_raw_text=="01E8"
                        quietly count if income_response==5
                        display as text "[INFO] `y' implicate `m': " r(N) " source persons have undefined poverty ratios."
                    }
                }
                else {
                    assert regexm(trim(povrati3_raw_text),"^[0-9]+$") | trim(povrati3_raw_text)==""
                    gen double povrati3 = real(povrati3_raw_text)
                }
                gen double family_income_mi = faminci2 if faminci2 != 999999
                if `y' <= 2009 gen double poverty_ratio_mi = povrati2/100 if povrati2 != 9999
                else gen double poverty_ratio_mi = povrati3/1000 if povrati3 != 999999
                * Conservative plausibility guard (not an official top-code).
                assert inrange(poverty_ratio_mi,0,100) | missing(poverty_ratio_mi)
                gen byte income_observed = (income_response == 0)
                clonevar implicate = impnum
                if `m' > 1 append using `incs'
                save `incs', replace
            }
        }
        else {
            local yy = substr("`y'",3,2)
            nhis_mi_find, year(`y') folder("`s'inc`yy'csv") names("`s'inc`yy'.csv")
            import delimited using "`r(path)'", clear varnames(1) case(lower) stringcols(_all)
            capture confirm variable srvy_yr
            if _rc != 0 gen srvy_yr = `y'
            foreach v of varlist _all {
                if "`v'" != "hhx" {
                    capture confirm string variable `v'
                    if _rc == 0 assert trim(`v') == "" | regexm(trim(`v'),"^-?[0-9]+([.][0-9]+)?$")
                    destring `v', replace
                }
            }
            local mvar "impnum"
            if `y' >= 2021 local mvar "impnum_`suffix'"
            clonevar implicate = `mvar'
            clonevar income_response = impincflg_`suffix'
            assert !missing(srvy_yr,implicate,income_response,povrattc_`suffix',ratcat_`suffix')
            assert inlist(income_response,0,1,2)
            if `y' <= 2020 assert !missing(faminctc_`suffix',incgrp_`suffix')
            gen byte income_observed = (income_response == 0)
            gen double poverty_ratio_mi = povrattc_`suffix'
            if `y' <= 2020 gen double family_income_mi = faminctc_`suffix'
            assert inrange(poverty_ratio_mi,0,cond(`y'==2019,10,11))
            assert srvy_yr == `y'
        }
        nhis_mi_keys, year(`y')
        isid `keys' implicate
        assert inrange(implicate,1,`M') & implicate == floor(implicate)
        bysort `keys': assert _N == `M'
        egen byte first = tag(`keys')
        quietly count if first
        local sourcepersons = r(N)
        drop first
        * MI is master. Base contains NO overlapping income values.
        merge m:1 `keys' using `yearbase', gen(link)
        assert link != 2
        if `y' >= 2019 assert link == 3
        keep if link == 3
        drop link
        assert _N == `persons'*`M'
        local idkeys "hhx"
        if `y' < 2019 local idkeys "hhx fmx fpx"
        egen long mi_person_id = group(`idkeys')
        bysort mi_person_id (implicate): assert income_response == income_response[1]
        by mi_person_id: assert poverty_ratio_mi == poverty_ratio_mi[1] if income_observed == 1
        capture confirm variable family_income_mi
        if _rc == 0 {
            by mi_person_id: assert family_income_mi == family_income_mi[1] if income_observed == 1
        }
        gen byte below_poverty_from_ratio_mi = (poverty_ratio_mi < 1) if !missing(poverty_ratio_mi)
        gen byte low_income_from_ratio_mi = (poverty_ratio_mi < 2) if !missing(poverty_ratio_mi)
        gen byte below_poverty_mi = below_poverty_from_ratio_mi
        gen byte low_income_mi = low_income_from_ratio_mi
        gen byte poverty_binary_mi_src = cond(missing(poverty_ratio_mi),0,2)
        if `y' <= 2008 {
            // Rounded ratios can reach 1.00/2.00 while RAT_CATI remains below.
            replace below_poverty_mi = (rat_cati <= 3) if inrange(rat_cati,1,14) & income_response != 5
            replace low_income_mi = (rat_cati <= 7) if inrange(rat_cati,1,14) & income_response != 5
            replace below_poverty_mi = . if !inrange(rat_cati,1,14) | income_response == 5
            replace low_income_mi = . if !inrange(rat_cati,1,14) | income_response == 5
            replace poverty_binary_mi_src = cond(inrange(rat_cati,1,14) & income_response != 5,1,0)
            assert (poverty_binary_mi_src==1) == !missing(poverty_ratio_mi)
        }
        by mi_person_id: assert below_poverty_mi == below_poverty_mi[1] if income_observed == 1
        by mi_person_id: assert low_income_mi == low_income_mi[1] if income_observed == 1
        gen byte mi_M = `M'
        display as text "[PASS] `y' `s': `persons' persons x `M' implicates; " `sourcepersons'-`persons' " non-sample persons excluded."
        if `firstyear' == 0 append using `combined'
        save `combined', replace
        local firstyear 0
    }
    sort srvy_yr mi_person_id implicate
    compress
    save "`mi_output_dir'/nhis_`s'_income_mi_long.dta", replace
    display as text "Saved: `mi_output_dir'/nhis_`s'_income_mi_long.dta"
}
display as text "Use 04 for single-year survey + Rubin pooling. One implicate is not complete income inference."
