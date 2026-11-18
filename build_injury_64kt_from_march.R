## Build the injury storm-aligned file under the first-E-code definition at all three thresholds.
##
## The March 2026 injury extract (first E code; matches the weekly injury baseline exactly) has
## >=34 and >=55 kt rows only. The provider's files are tabulated for every storm against all
## counties, so a storm's rows depend only on its impact date, not on the threshold. For each storm
## that qualifies at >=64 kt (from the all-cause file) the >=64 kt rows are therefore the storm's
## >=55 kt rows, provided the impact dates agree. This is checked below on the two files that do
## have real >=64 kt rows (all-cause and the July injury extract) before it is applied.
##
## Output: Ed_county_weekly_confidential/ED_Injuries_FirstEcode.csv (originals are not changed).
suppressPackageStartupMessages(library(data.table))
proj <- here::here()   # project root (the folder that holds ED_county_weekly_TC_phases.Rmd)
conf <- file.path(proj, "Ed_county_weekly_confidential")
read_sa <- function(f) {
  d <- fread(f, colClasses = list(character = c("SID", "County", "Window")))
  d[, `:=`(impact_date = as.IDate(impact_date), window_start = as.IDate(window_start), window_end = as.IDate(window_end))]
  d
}
march <- read_sa(file.path(proj, "ED_Cyclones_Injuries_by_County_34kt55kt_Threat4_Threat7_PostWeekly_2yr.csv"))
ac    <- read_sa(file.path(conf, "ED_AllCause.csv"))
july  <- read_sa(file.path(conf, "ED_Injuries.csv"))
key   <- c("SID", "County", "Window", "PostWeek", "event_day_start", "event_day_end", "window_start", "window_end", "impact_date")

## storms at >=64 kt and their impact dates (all-cause file covers all three thresholds)
s64 <- unique(ac[threshold_knots == 64, .(SID, impact_date)])
s55 <- unique(ac[threshold_knots == 55, .(SID, impact_date_55 = impact_date)])
s64 <- s55[s64, on = "SID"][, same_date := impact_date == impact_date_55]
cat("Storms at >=64 kt:", nrow(s64), " with the same impact date at >=55 kt:", s64[same_date == TRUE, .N], "\n")

## ---- 1. validate the construction on files that have real 64 kt rows -------------------------
copy_55_to_64 <- function(d, sids) d[threshold_knots == 55 & SID %in% sids][, threshold_knots := 64L]
validate <- function(d, label) {
  sids <- intersect(s64[same_date == TRUE, SID], d[threshold_knots == 64, unique(SID)])
  built <- copy_55_to_64(d, sids)
  real  <- d[threshold_knots == 64 & SID %in% sids]
  j <- merge(built[, c(key, "Visits"), with = FALSE], real[, c(key, "Visits"), with = FALSE],
             by = key, all = TRUE, suffixes = c("_built", "_real"))
  cat(sprintf("VALIDATION %-12s storms %d | rows built %d real %d | only built %d | only real %d | Visits differ %d\n",
              label, length(sids), nrow(built), nrow(real), sum(is.na(j$Visits_real)), sum(is.na(j$Visits_built)),
              sum(j$Visits_built != j$Visits_real, na.rm = TRUE)))
  nrow(j) == nrow(real) && nrow(built) == nrow(real) && all(j$Visits_built == j$Visits_real)
}
ok1 <- validate(ac, "all-cause"); ok2 <- validate(july, "July injury")
stopifnot(ok1, ok2)

## ---- 2. build the 64 kt rows from the March >=55 kt rows ----------------------------------------
use <- s64[same_date == TRUE & SID %in% march[threshold_knots == 55, unique(SID)], SID]
missing <- setdiff(s64$SID, use)
cat("\n64 kt storms built from March >=55 kt rows:", length(use), "\n")
cat("64 kt storms NOT available (not in March at >=55 kt, or different date):", length(missing), "\n")
print(unique(ac[SID %in% missing, .(SID, impact_date)]))
new64 <- copy_55_to_64(march, use)
out <- rbindlist(list(march, new64), use.names = TRUE)
setorderv(out, c("SID", "threshold_knots", "County", "event_day_start"))
stopifnot(identical(names(out), names(march)), out[, .N, by = .(SID, threshold_knots, County, Window)][, all(N == 1)])
cat("\nRows by threshold:\n"); print(out[, .(rows = .N, storms = uniqueN(SID), counties = uniqueN(County)), by = threshold_knots])

## the 34 and 55 kt rows must be exactly the March file
chk <- merge(out[threshold_knots %in% c(34, 55)], march, by = c(key, "threshold_knots"), all = TRUE, suffixes = c("_out", "_m"))
cat("34/55 kt rows identical to the March file:", nrow(chk) == nrow(march) && all(chk$Visits_out == chk$Visits_m), "\n")

## which windows the July 64 kt rows have that the built rows do not (Threat_1d is not in the March extract)
j64 <- merge(new64[, c(key, "Visits"), with = FALSE], july[threshold_knots == 64 & SID %in% use, c(key, "Visits"), with = FALSE],
             by = key, all = TRUE, suffixes = c("_firstE", "_july"))
cat("\nRows present in July 64 kt but not in the built file, by window type:\n")
print(j64[is.na(Visits_firstE), .N, by = .(type = fifelse(Window == "Threat_1d", "Threat_1d (not in March extract)",
                                                         "other (count below 6 under first-E-code)"))])
cat("Rows in the built file but not in July 64 kt:", j64[is.na(Visits_july), .N], "\n")
cat("Where both exist, July / first-E-code ratio of total visits:",
    round(j64[!is.na(Visits_firstE) & !is.na(Visits_july), sum(Visits_july) / sum(Visits_firstE)], 3), "\n")

fwrite(out, file.path(conf, "ED_Injuries_FirstEcode.csv"))
cat("\nWritten:", file.path(conf, "ED_Injuries_FirstEcode.csv"), " rows:", nrow(out), "\n")
