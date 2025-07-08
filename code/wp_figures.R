## WP figures ##

# --- Define variable groupings for national-level sheets ---
sheet_vars <- list(
  "All Initial"               = c("ALL_initial", "ALL_yp_initial"),
  "Federal Initial"           = c("UCFE_initial", "UCFE_yp_initial"),
  "All Continued"             = c("ALL_continued", "ALL_yp_continued"),
  "Federal Continued"         = c("UCFE_continued", "UCFE_yp_continued")
)

# --- Build list of national-level data frames for each sheet ---
wp_list <- lapply(sheet_vars, function(vars) {
  eta.539_national %>%
    select(date, all_of(vars))
})

# --- Add multiple state-level data sheets ---
wp_list[["State Fed Cont Smooth"]] <- state_pivoted_list[["YoY_federal_continued_smooth"]]
wp_list[["State Cont Smooth"]]     <- state_pivoted_list[["YoY_continued_smooth"]]

# --- Create a workbook to store all sheets ---
wb <- createWorkbook()
date_style <- createStyle(numFmt = "yyyy-mm-dd")  # Excel display format

# --- Add all national-level sheets to the workbook ---
for (sheet_name in names(wp_list)) {
  df <- wp_list[[sheet_name]]
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet_name, df)
  freezePane(wb, sheet_name, firstRow = TRUE)
  
  # Format date column (assumed to be the first column)
  if ("date" %in% names(df)) {
    addStyle(wb, sheet = sheet_name, style = date_style,
             rows = 2:(nrow(df) + 1), cols = which(names(df) == "date"),
             gridExpand = TRUE)
  }
}

# --- Write the workbook to a file ---
saveWorkbook(wb, file = "output/wp_figures.xlsx", overwrite = TRUE)

####################
## State spreadsheet ##

# --- Define state sheet variables ---
state_sheet_vars <- list(
  "All cont state"     = c("ALL_continued"),
  "Federal cont state" = c("UCFE_continued")
)

# --- Build list of state-level data frames ---
state_list <- lapply(state_sheet_vars, function(vars) {
  eta.539_final %>%
    select(date, state, all_of(vars)) %>% 
    pivot_wider(names_from = state, values_from = all_of(vars))
})

# --- Create a workbook for state-level sheets ---
wb_state <- createWorkbook()

# --- Add state-level sheets with formatted dates ---
for (sheet_name in names(state_list)) {
  df <- state_list[[sheet_name]]
  addWorksheet(wb_state, sheet_name)
  writeData(wb_state, sheet_name, df)
  freezePane(wb_state, sheet_name, firstRow = TRUE)
  
  if ("date" %in% names(df)) {
    addStyle(wb_state, sheet = sheet_name, style = date_style,
             rows = 2:(nrow(df) + 1), cols = which(names(df) == "date"),
             gridExpand = TRUE)
  }
}

# --- Write the workbook to a file ---
saveWorkbook(wb_state, file = "output/by_state.xlsx", overwrite = TRUE)



