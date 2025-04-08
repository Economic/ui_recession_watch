## WP figures ## 

# --- Define variable groupings for national-level sheets ---
sheet_vars <- list(
  "All Initial"               = c("ALL_initial", "ALL_yp_initial"),
  "Federal Initial"           = c("UCFE_initial", "UCFE_yp_initial"),
  "All Continued"             = c("ALL_continued", "ALL_yp_continued"),
  "Federal Continued"         = c("UCFE_continued", "UCFE_yp_continued"),
  "YoY All Initial"           = c("YoY_initial"),
  "YoY Federal Initial"       = c("YoY_federal_initial"),
  "YoY Federal Continued"     = c("YoY_federal_continued"),
  "YoY All Continued"         = c("YoY_continued")
)

# --- Build list of state-level data frames for each sheet ---
wp_list <- lapply(sheet_vars, function(vars) {
  eta.539_national %>%
    select(report_date, all_of(vars))
})

# --- Add multiple state-level data sheets ---
wp_list[["State Fed Cont Smooth"]] <- state_pivoted_list[["YoY_federal_continued_smooth"]]

# --- Write everything to Excel ---
write.xlsx(wp_list, file = "output/wp_figures.xlsx")