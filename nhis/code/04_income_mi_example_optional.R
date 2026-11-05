################################################################################
# Disabled-by-default, SINGLE-YEAR survey + MI example. Run 01 then 03 first.
# Uses all 5 (2004-18) or all 10 (2019-24) implicates with Rubin pooling.
# USER SETTINGS (can be supplied before source())
################################################################################
if (!exists("run_mi_example")) run_mi_example <- FALSE
if (!exists("mi_example_year")) mi_example_year <- 2024L
if (!exists("mi_example_sample")) mi_example_sample <- "adult"
if (!exists("mi_domain_age_min")) mi_domain_age_min <- NULL
if (!exists("nhis_root_manual")) nhis_root_manual <- NULL
if (!run_mi_example) {
  cat("MI example disabled. Set run_mi_example <- TRUE after running 01 and 03.\n")
} else {
needed <- c("survey","mitools")
missing <- needed[!vapply(needed,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Install dependencies: install.packages(c("survey", "mitools"))')
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
valid <- candidates[file.exists(file.path(candidates,"code","04_income_mi_example_optional.R"))]
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
if(length(mi_example_year)!=1 || !mi_example_year %in% 2004:2024 ||
   length(mi_example_sample)!=1 || !mi_example_sample %in% c("adult","child")) stop("Choose one supported year and sample.")
p <- file.path(mi_output_dir,paste0("nhis_",mi_example_sample,"_income_mi_long.rds"))
if(!file.exists(p)) stop("Missing ",p,"; run 03 first.")
z <- readRDS(p); z <- z[z$srvy_yr==mi_example_year,]
M <- if(mi_example_year<2019)5L else 10L
if(!nrow(z) || anyDuplicated(z[c("mi_person_id","implicate")]) || !setequal(unique(z$implicate),1:M) || any(table(z$mi_person_id)!=M)) stop("Incomplete/duplicate implicates.")
suf <- if(mi_example_sample=="adult")"a" else "c"
weight <- paste0("wtfa_",suf); age <- paste0("agep_",suf)
if(!is.null(mi_domain_age_min) && (!age %in% names(z) || length(mi_domain_age_min)!=1)) stop("Domain requires a single minimum age and the sample age field.")
completed <- lapply(1:M,function(m) z[z$implicate==m,])
# Survey weights are annual weights, never divided by M. Use per-implicate
# domains; evaluate membership inside each design rather than pooling persons.
designs <- lapply(completed,function(d) survey::svydesign(ids=~ppsu,strata=~pstrat,
  weights=stats::as.formula(paste0("~",weight)),data=d,nest=TRUE))
if(!is.null(mi_domain_age_min)) designs <- lapply(designs,function(d) {
  membership <- !is.na(d$variables[[age]]) & d$variables[[age]]>=mi_domain_age_min
  d[membership,]
})
dfs <- vapply(designs,survey::degf,numeric(1))
if(any(dfs<=0) || length(unique(dfs))!=1) stop("Complete-data survey df must be positive and common across implicates; review domain/design.")
# Undefined targets are excluded explicitly and must identify the same people
# in every completed analysis sample; this example has an invariant age domain.
eligible_ids <- lapply(designs,function(d) {
  valid <- stats::complete.cases(d$variables[c("poverty_ratio_mi","low_income_mi")])
  cat("[INFO] Completed sample: ",sum(valid)," eligible; ",sum(!valid)," undefined targets excluded.\n",sep="")
  d$variables$mi_person_id[valid]
})
if(any(!vapply(eligible_ids,function(ids) setequal(ids,eligible_ids[[1]]),logical(1))))
  stop("Analysis eligibility changes across implicates; review missing targets/domain.")
estimates <- lapply(designs,function(d) survey::svymean(~poverty_ratio_mi+low_income_mi,d,na.rm=TRUE))
pooled <- mitools::MIcombine(estimates,df.complete=dfs[1])
print(summary(pooled))
cat("Complete-data survey df: ",dfs[1],"; implicates: ",M,".\n",sep="")
# Save estimates and within-implicate variances for independent Rubin checks.
result <- list(year=mi_example_year,sample=mi_example_sample,M=M,df_complete=dfs[1],
  domain_age_min=mi_domain_age_min,Q=lapply(estimates,stats::coef),
  U=lapply(estimates,stats::vcov),pooled=pooled)
path <- file.path(mi_output_dir,paste0("nhis_",mi_example_sample,"_income_mi_example.rds"))
saveRDS(result,path); cat("Saved: ",path,"\n",sep="")
# Cross-era pooling and income-dependent regression/domain specifications need
# their own design, df, and substantive review. Earnings are outside this example.
}
