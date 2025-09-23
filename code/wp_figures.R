## WP figures ##

# --- Define variable groupings for national-level sheets ---
sheet_vars <- list(
  "All Initial"               = c("ALL_initial", "ALL_yp_initial"),
  "All Continued"             = c("ALL_continued", "ALL_yp_continued"),
  "Federal Initial"           = c("UCFE_initial", "UCFE_yp_initial"),
  "Federal Continued"         = c("UCFE_continued", "UCFE_yp_continued")
)

# --- Build list of national-level data frames for each sheet ---
wp_list <- lapply(sheet_vars, function(vars) {
  df <- eta_539_national %>%
    filter(date >= figure_date) %>%
    select(date, all_of(vars))
  
  # Identify rows where any column is 0 or NA
  numeric_cols <- df %>% select(all_of(vars))
  keep_rows <- rowSums(is.na(numeric_cols) | numeric_cols == 0) == 0
  
  df[keep_rows, ]
})


# --- Add multiple state-level data sheets, filtering zeros/NAs ---
wp_list[["State Cont Smooth"]] <- state_pivoted_list[["YoY_continued_smooth"]] |>
  select(date, DC, US) |> 
  filter(date >= cutoff_date & date < (current_date - 7))

 

wp_list[["State Fed Cont Smooth"]] <- state_pivoted_list[["YoY_federal_continued_smooth"]] |>
  select(date, DC, MD, VA, US) |> 
   filter(date >= cutoff_date & date < (current_date - 14))


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
  "Federal cont state" = c("UCFE_continued"), 
  "All cont state smooth"     = c("ALL_continued_smooth"),
  "Federal cont state smooth" = c("UCFE_continued_smooth"), 
  "YoY All cont state smooth"     = c("YoY_continued_smooth"),
  "YoY Federal cont state smooth " = c("YoY_federal_continued_smooth")
  
)

# --- Build list of state-level data frames ---
state_list <- lapply(state_sheet_vars, function(vars) {
  eta_539_state %>%
    filter(date >= figure_date) |> 
    select(date, state, all_of(vars)) %>% 
     group_by(date, state) %>%
    summarise(across(all_of(vars), sum, na.rm = TRUE), .groups = "drop") %>%
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



