suppressPackageStartupMessages(library(data.table))
q <- PROJ
d <- fread(file.path(q, "data_private", "cohort_raw.csv"))

cat(sprintf("COHORT: %s stays, %d hospitals\n",
            format(nrow(d), big.mark = ","), uniqueN(d$hospitalid)))
cat(sprintf("  any delirium assessment : %5.1f%%\n", 100*mean(d$any_delirium_assess)))
cat(sprintf("  any sedation assessment : %5.1f%%\n", 100*mean(d$any_sedation_assess)))
cat(sprintf("  any pain assessment     : %5.1f%%\n", 100*mean(d$any_pain_assess)))

v <- d[ventilated == 1]
cat(sprintf("\nVENTILATED subgroup (n=%s), guideline strongest here:\n",
            format(nrow(v), big.mark = ",")))
cat(sprintf("  any delirium assessment : %5.1f%%\n", 100*mean(v$any_delirium_assess)))
cat(sprintf("  any sedation assessment : %5.1f%%\n", 100*mean(v$any_sedation_assess)))

hp <- d[, .(n = .N, pct = 100*mean(any_delirium_assess)), by = hospitalid][n >= 25]
cat(sprintf("\nHOSPITAL VARIATION (%d hospitals with >= 25 stays)\n", nrow(hp)))
cat(sprintf("  %% screened: median %.1f, IQR %.1f-%.1f, range %.1f-%.1f\n",
            median(hp$pct), quantile(hp$pct, .25), quantile(hp$pct, .75),
            min(hp$pct), max(hp$pct)))
cat(sprintf("  hospitals screening <10%%: %d    >90%%: %d\n",
            sum(hp$pct < 10), sum(hp$pct > 90)))
