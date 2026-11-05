################################################################################
# Optional NHIS income MI loader, 2004-2024. Run a matching 01 loader first.
# Completed long data only: 5 implicates before 2019, 10 from 2019 onward.
# No imputation or inference is performed; ordinary starter files are untouched.
################################################################################
# USER SETTINGS (may also be set before source())
if (!exists("nhis_root_manual")) nhis_root_manual <- NULL
if (!exists("mi_years")) mi_years <- 2024L
if (!exists("mi_samples")) mi_samples <- c("adult", "child")
if (!exists("mi_base_extra_vars")) mi_base_extra_vars <- character()
if (!exists("write_dta_export")) write_dta_export <- FALSE
needed <- c("haven", "dplyr", "readr")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly=TRUE)]
if (length(missing)) stop('Install dependencies: install.packages(c("haven", "dplyr", "readr"))')
# Root detection supports repository root, nhis/, code/, and explicit override.
args <- commandArgs(FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
frames <- vapply(sys.frames(), function(x) if (is.null(x$ofile)) "" else x$ofile, "")
starts <- c(getwd(), dirname(script), dirname(frames[nzchar(frames)]))
ancestors <- function(p) {
  p <- normalizePath(p, mustWork=FALSE); out <- p
  while (dirname(p) != p) { p <- dirname(p); out <- c(out,p) }; out
}
candidates <- unique(c(nhis_root_manual, Sys.getenv("NHIS_ROOT"),
  unlist(lapply(starts, ancestors)), file.path(unlist(lapply(starts, ancestors)),"nhis")))
candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
valid <- candidates[file.exists(file.path(candidates,"code","03_load_income_implicates_optional.R"))]
if (!length(valid)) stop('Set nhis_root_manual or NHIS_ROOT to "/path/to/nhis".')
nhis_root <- normalizePath(valid[1])
if (!exists("nhis_output_dir")) {
  out <- Sys.getenv("NHIS_OUTPUT_DIR")
  nhis_output_dir <- if (nzchar(out)) out else file.path(nhis_root,"output")
}
# Input and output can be separated for verification or a project workflow.
if (!exists("mi_base_dir")) mi_base_dir <- nhis_output_dir
if (!exists("mi_output_dir")) {
  out <- Sys.getenv("NHIS_MI_OUTPUT_DIR")
  mi_output_dir <- if (nzchar(out)) out else nhis_output_dir
}
dir.create(mi_output_dir, recursive=TRUE, showWarnings=FALSE)
if (!length(mi_years) || anyNA(mi_years) || any(!mi_years %in% 2004:2024) || anyDuplicated(mi_years))
  stop("mi_years must contain distinct years from 2004:2024.")
if (!length(mi_samples) || any(!mi_samples %in% c("adult","child")) || anyDuplicated(mi_samples))
  stop('mi_samples must contain "adult" and/or "child", without duplicates.')
mi_years <- sort(mi_years)

unique_keys <- function(d, keys, label) {
  if (!all(keys %in% names(d))) stop(label, ": missing key fields.")
  if (anyNA(d[keys]) || any(vapply(d[keys], function(v) any(trimws(as.character(v))==""), logical(1))) || anyDuplicated(d[keys]))
    stop(label, ": missing or duplicate identifiers.")
}
normalize_keys <- function(d, y) {
  for (v in intersect(if(y<2019)c("hhx","fmx","fpx") else "hhx", names(d))) {
    z <- trimws(as.character(d[[v]]))
    if(anyNA(z) || any(z == "")) stop("Missing raw identifier: ",v)
    if (y < 2019) z <- ifelse(is.na(z),NA_character_, paste0(vapply(nchar(z),function(n) paste(rep("0",max(0,(if(v=="hhx")6 else 2)-n)),collapse=""),""),z))
    d[[v]] <- z
  }; d
}
# Deterministic case-insensitive lookup; ambiguous copies fail.
find_raw <- function(y, folder, filenames) {
  yd <- file.path(nhis_root,"data",paste0("NHIS ",y))
  dirs <- unique(c(file.path(yd,folder),yd))
  paths <- unlist(lapply(dirs, function(p) if(dir.exists(p)) list.files(p,full.names=TRUE) else character()))
  hits <- paths[tolower(basename(paths)) %in% tolower(filenames)]
  if (length(hits)!=1) stop("Need exactly one ",paste(filenames,collapse=" / ")," in ",paste(dirs,collapse=" or "),
    ". Extract the official income archive; do not use derived .dta files.")
  hits
}
read_fixed <- function(path, fields, allow_2004_undefined=FALSE) {
  # All specified positions are from CDC's annual layouts. Read raw ASCII,
  # never CDC-derived DTA files whose programs may have applied decimal scaling.
  lines <- readLines(path, warn=FALSE)
  if (!length(lines) || any(nchar(lines)<max(vapply(fields,`[`,numeric(1),2)))) stop("Truncated/empty fixed-width file: ",path)
  d <- as.data.frame(lapply(fields,function(pos) trimws(substr(lines,pos[1],pos[2]))),stringsAsFactors=FALSE)
  for(v in setdiff(names(d),c("hhx","fmx","fpx"))) {
    txt <- d[[v]]
    known <- allow_2004_undefined && v=="povrati2"
    exception <- if(known) txt=="01E8" else rep(FALSE,length(txt))
    if(any(nzchar(txt) & !grepl("^[0-9]+$",txt) & !exception)) stop("Unexpected non-digit ",v," in ",path)
    if(v %in% c("faminci2","povrati2","povrati3")) d[[paste0(v,"_raw_text")]] <- txt
    txt[exception] <- ""
    d[[v]] <- as.numeric(txt)
  }; d
}
keys_layout <- list(srvy_yr=c(3,6),hhx=c(7,12),fmx=c(13,14),fpx=c(15,16),impnum=c(17,17))
check_income_codes <- function(d, field, allowed) {
  if(anyNA(d[[field]]) || any(!d[[field]] %in% allowed))
    stop("Missing or invalid pre-2019 income code: ",field)
}
read_pre <- function(y) {
  pieces <- lapply(1:5,function(m) {
    if(y <= 2008) {
      d <- read_fixed(find_raw(y,"INCIMPS",paste0("incimps",m,".dat")),c(keys_layout,
        list(faminci2=c(18,23),tcincm_f=c(24,24),povrati2=c(25,28))),allow_2004_undefined=(y==2004))
      catfields <- if(y<=2006) list(incgrp_f=c(18,18),incgrp_i=c(19,20),rat_catf=c(21,21),rat_cati=c(22,23)) else
        list(incgrpf2=c(18,18),incgrpi2=c(19,20),ratcatf2=c(21,21),rat_cati=c(22,23))
      flags <- read_fixed(find_raw(y,"INCMIMP",c(paste0("incmimp",m,".dat"),paste0("incmap",m,".dat"))),c(keys_layout,catfields))
      k <- c("srvy_yr","hhx","fmx","fpx","impnum")
      unique_keys(d,k,"INCIMPS"); unique_keys(flags,k,"INCMIMP")
      if(nrow(d)!=nrow(flags) || nrow(dplyr::anti_join(d,flags,by=k)) || nrow(dplyr::anti_join(flags,d,by=k))) stop("Early companion keys differ.")
      d <- dplyr::left_join(d,flags,by=k)
      check_income_codes(d,if(y<=2006)"incgrp_f" else "incgrpf2",0:2)
      check_income_codes(d,if(y<=2006)"incgrp_i" else "incgrpi2",1:(if(y<=2006)11 else 21))
      check_income_codes(d,if(y<=2006)"rat_catf" else "ratcatf2",if(y<=2006)c(0:3,5) else c(0:2,5))
      check_income_codes(d,"rat_cati",c(1:14,96))
      d$income_response <- d[[if(y<=2006)"rat_catf" else "ratcatf2"]]
      undefined <- d$income_response==5
      anomaly <- d$povrati2_raw_text=="01E8"
      if(any(anomaly & !(d$income_response==5 & d$rat_cati==96))) stop("2004 ratio exception lacks undefined companion flags.")
      if(any(undefined != (d$rat_cati==96))) stop("Undefined poverty flag and category disagree.")
      if(any((d$povrati2_raw_text %in% c("9999","01E8")) != undefined))
        stop("Undefined poverty ratio marker and companion flags disagree.")
      if(any(undefined)) cat(sprintf("[INFO] %d implicate %d: %d source persons have undefined poverty ratios.\n",y,m,sum(undefined)))
    } else {
      rat <- if(y==2009) list(povrati2=c(26,29)) else list(povrati3=c(26,34))
      d <- read_fixed(find_raw(y,"INCMIMP",paste0("incmimp",m,".dat")),c(keys_layout,
        list(famincf2=c(18,18),tcincm_f=c(19,19),faminci2=c(20,25)),rat))
      check_income_codes(d,"famincf2",0:2)
      d$income_response <- d$famincf2
      undefined <- rep(FALSE,nrow(d))
    }
    check_income_codes(d,"tcincm_f",0:1)
    if(any(d$srvy_yr!=y) || any(d$impnum!=m)) stop("Wrong year/imputation number in source.")
    # Sentinel removal precedes implied-decimal conversion.
    d$family_income_mi <- ifelse(d$faminci2==999999,NA_real_,d$faminci2)
    r <- d[[if(y<=2009)"povrati2" else "povrati3"]]
    d$poverty_ratio_mi <- ifelse(undefined | is.na(r) | r==(if(y<=2009)9999 else 999999),NA_real_,r/(if(y<=2009)100 else 1000))
    # 100 is a conservative plausibility guard, not an official top-code.
    # Verified pre-2019 released ratios are below 21. Reject corrupted scales.
    if(any(d$poverty_ratio_mi<0 | d$poverty_ratio_mi>100,na.rm=TRUE)) stop("Implausible pre-2019 poverty ratio; check raw bytes/scale.")
    d$income_observed <- as.integer(d$income_response==0)
    d$implicate <- d$impnum
    d
  }); dplyr::bind_rows(pieces)
}
read_post <- function(y,s) {
  yy <- substr(y,3,4); filename <- paste0(s,"inc",yy,".csv")
  path <- find_raw(y,paste0(s,"inc",yy,"csv"),filename)
  d <- as.data.frame(readr::read_csv(path,col_types=readr::cols(.default="c"),na=character(),show_col_types=FALSE))
  names(d) <- tolower(names(d))
  if(!"srvy_yr" %in% names(d)) d$srvy_yr <- y
  suf <- if(s=="adult") "a" else "c"
  for(v in setdiff(names(d),"hhx")) {
    txt <- trimws(as.character(d[[v]]))
    if(any(nzchar(txt) & !grepl("^-?[0-9]+([.][0-9]+)?$",txt)))
      stop("Unexpected non-numeric ",v," in ",path)
    d[[v]] <- as.numeric(txt)
  }
  mname <- if(y<=2020) "impnum" else paste0("impnum_",suf)
  required <- c("srvy_yr","hhx",mname,paste0(c("povrattc_","ratcat_","impincflg_"),suf))
  if(y<=2020) required <- c(required,paste0(c("faminctc_","incgrp_"),suf))
  if(!all(required %in% names(d))) stop("Missing redesigned income fields: ",path)
  if(anyNA(d[setdiff(required,"hhx")])) stop("Missing required redesigned income values: ",path)
  if(any(!d[[paste0("impincflg_",suf)]] %in% 0:2)) stop("Invalid redesigned income response flag: ",path)
  d$implicate <- d[[mname]]
  d$income_response <- d[[paste0("impincflg_",suf)]]
  d$income_observed <- as.integer(d$income_response==0)
  d$poverty_ratio_mi <- d[[paste0("povrattc_",suf)]]
  if(y<=2020) d$family_income_mi <- d[[paste0("faminctc_",suf)]]
  if(any(d$poverty_ratio_mi<0 | d$poverty_ratio_mi>(if(y==2019)10 else 11),na.rm=TRUE)) stop("Redesigned poverty ratio exceeds its documented bounds.")
  if(any(d$srvy_yr!=y)) stop("Wrong year in income CSV.")
  d
}
for(s in mi_samples) {
  basefile <- file.path(mi_base_dir,paste0("nhis_",s,".rds"))
  if(!file.exists(basefile)) stop("Missing ",basefile,". Run the matching 01 loader with all mi_years first.")
  base <- readRDS(basefile); suf <- if(s=="adult")"a" else "c"
  # Only named base covariates/design are repeated. Main-file income values
  # cannot mask the completed income values in the join.
  basevars <- unique(c("srvy_yr","hhx","fmx","fpx","pstrat","ppsu",paste0(c("wtfa_","agep_","sex_","phstat_","notcov_"),suf),mi_base_extra_vars))
  if(any(grepl("^(rat_?cat|incgrp|famin|family_income|povrat|poverty_|pov_cat|implicate|mi_|impnum|impinc|inctc|income_|below_poverty|low_income|ernyr|tcinc)",mi_base_extra_vars))) stop("Income fields cannot be base extras; use the implicate source fields.")
  base <- base[intersect(basevars,names(base))]
  if(!all(mi_years %in% unique(base$srvy_yr))) stop("Base ",s," file lacks requested mi_years. Re-run 01 with those years.")
  results <- lapply(mi_years,function(y) {
    b <- normalize_keys(base[base$srvy_yr==y,,drop=FALSE],y)
    keys <- c("srvy_yr","hhx",if(y<2019)c("fmx","fpx"))
    design <- c("pstrat","ppsu",paste0("wtfa_",suf))
    if(!all(design %in% names(b)) || anyNA(b[design]) || any(b[[paste0("wtfa_",suf)]]<=0)) stop("Missing/invalid base survey design.")
    unique_keys(b,keys,"Main sample")
    d <- normalize_keys(if(y<2019) read_pre(y) else read_post(y,s),y)
    M <- if(y<2019)5L else 10L
    unique_keys(d,c(keys,"implicate"),"Completed income")
    if(anyNA(d$implicate) || !setequal(unique(d$implicate),seq_len(M))) stop("Unexpected imputation numbers.")
    sizes <- dplyr::count(d,dplyr::across(dplyr::all_of(keys)))
    if(any(sizes$n!=M)) stop("A source person lacks the complete set of implicates.")
    if(nrow(dplyr::anti_join(b,d,by=keys))) stop("Unmatched selected sample persons.")
    if(y>=2019 && nrow(dplyr::anti_join(d,b,by=keys))) stop("Unexpected redesigned income sample persons.")
    z <- dplyr::inner_join(d,b,by=keys)
    if(nrow(z)!=nrow(b)*M) stop("Income merge expanded or lost selected persons.")
    z$mi_person_id <- match(do.call(paste,c(z[keys],sep="|")),sort(unique(do.call(paste,c(z[keys],sep="|")))))
    # Reported-status flags and observed continuous targets must be invariant.
    inv <- dplyr::summarise(dplyr::group_by(z,mi_person_id),
      flag_n=dplyr::n_distinct(income_response),
      ratio_n=if(all(income_observed==1)) dplyr::n_distinct(poverty_ratio_mi) else 1L,
      .groups="drop")
    if(any(inv$flag_n!=1 | inv$ratio_n!=1)) stop("Observed status/ratio varies across implicates.")
    if("family_income_mi" %in% names(z)) {
      a <- z[z$income_observed==1,]; n <- dplyr::summarise(dplyr::group_by(a,mi_person_id),n=dplyr::n_distinct(family_income_mi),.groups="drop")
      if(any(n$n!=1)) stop("Reported dollars vary across implicates.")
    }
    z$below_poverty_from_ratio_mi <- ifelse(is.na(z$poverty_ratio_mi),NA_integer_,as.integer(z$poverty_ratio_mi<1))
    z$low_income_from_ratio_mi <- ifelse(is.na(z$poverty_ratio_mi),NA_integer_,as.integer(z$poverty_ratio_mi<2))
    z$below_poverty_mi <- z$below_poverty_from_ratio_mi
    z$low_income_mi <- z$low_income_from_ratio_mi
    z$poverty_binary_mi_src <- ifelse(is.na(z$poverty_ratio_mi),0L,2L)
    if(y<=2008) {
      # Released two-decimal ratios can round up to 1.00/2.00 while the
      # official completed category remains below the corresponding threshold.
      valid_category <- z$rat_cati %in% 1:14 & z$income_response!=5
      z$below_poverty_mi <- ifelse(valid_category,as.integer(z$rat_cati<=3),NA_integer_)
      z$low_income_mi <- ifelse(valid_category,as.integer(z$rat_cati<=7),NA_integer_)
      z$poverty_binary_mi_src <- ifelse(valid_category,1L,0L)
      if(any((z$poverty_binary_mi_src==1) != !is.na(z$poverty_ratio_mi)))
        stop("Early poverty binary source and continuous availability disagree.")
    }
    observed_binary <- dplyr::summarise(dplyr::group_by(z[z$income_observed==1,],mi_person_id),
      below_n=dplyr::n_distinct(below_poverty_mi),low_n=dplyr::n_distinct(low_income_mi),.groups="drop")
    if(any(observed_binary$below_n!=1 | observed_binary$low_n!=1)) stop("Reported poverty indicators vary across implicates.")
    z$mi_M <- M
    cat(sprintf("[PASS] %d %s: %d selected persons x %d implicates; %d non-sample source persons excluded.\n",y,s,nrow(b),M,nrow(sizes)-nrow(b)))
    z
  })
  z <- dplyr::bind_rows(results)
  # Year-local mi_person_id must always be paired with srvy_yr.
  z <- dplyr::arrange(z,srvy_yr,mi_person_id,implicate)
  outfile <- file.path(mi_output_dir,paste0("nhis_",s,"_income_mi_long.rds"))
  saveRDS(z,outfile); cat("Saved completed MI long data: ",outfile,"\n",sep="")
  if(write_dta_export) haven::write_dta(z,file.path(mi_output_dir,paste0("nhis_",s,"_income_mi_long_from_r.dta")))
}
cat("Use the single-year 04 example for survey + Rubin pooling. Never treat one implicate as a complete income analysis.\n")
