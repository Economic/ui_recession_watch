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
wp_list[["State Cont Smooth"]] <- state_pivoted_list[["YoY_continued_smooth"]]

# --- Create a workbook to store all sheets ---
wb <- createWorkbook()

# --- Add all national-level sheets to the workbook ---
for (sheet_name in names(wp_list)) {
  addWorksheet(wb, sheet_name)                 # Add worksheet
  writeData(wb, sheet_name, wp_list[[sheet_name]])  # Write data
  freezePane(wb, sheet_name, firstRow = TRUE)  # Freeze the first row
}

# --- Write the workbook to a file ---
saveWorkbook(wb, file = "output/wp_figures.xlsx", overwrite = TRUE)

####################
## State spreadsheet ##

# ----- Outputting a State Master for checking to Excel -----
state_sheet_vars <- list(
  "All cont state"               = c("ALL_continued"),
  "Federal cont state"           = c("UCFE_continued")
)

# --- Build list of state-level data frames for each sheet ---
state_list <- lapply(state_sheet_vars, function(vars) {
  eta.539_state %>%
    select(report_date, state, all_of(vars)) %>% 
    pivot_wider(names_from = state, values_from = all_of(vars))
})

# --- Create a workbook for state sheets ---
wb_state <- createWorkbook()

# --- Add all state-level sheets to the workbook ---
for (sheet_name in names(state_list)) {
  addWorksheet(wb_state, sheet_name)            # Add worksheet
  writeData(wb_state, sheet_name, state_list[[sheet_name]])  # Write data
  freezePane(wb_state, sheet_name, firstRow = TRUE)  # Freeze the first row
}

# --- Write the workbook to a file ---
saveWorkbook(wb_state, file = "output/by_state.xlsx", overwrite = TRUE)



