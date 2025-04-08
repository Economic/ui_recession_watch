# Raw Data # 

# download eta 539 files with system command
# "wget -N" omites download if data has not been updated "-P" sets the file destination"
system(paste0("wget -N https://oui.doleta.gov/unemploy/csv/ar539.csv  -P suppdata/"))

# Create varibale names and add state codes 
eta.539_var_names <- fread(here("suppdata","eta539_var_names.csv"))
eta.539_old_names <- eta.539_var_names$dol_code
eta.539_new_names <- eta.539_var_names$dol_title
state_codes <- read_csv(here("suppdata", "state_geocodes.csv")) %>% 
  select(state = state_name, state_abb)

#################
# Raw ETA 539 ####
eta.539_raw <- fread(here("suppdata","ar539.csv")) %>%
  # replace variable names to be more readable
  setnames(old = eta.539_old_names, new = eta.539_new_names) %>%
  select(all_of(eta.539_new_names)) %>%
  # format date as class 'Date' 
  mutate(report_date = anytime(report_date),
         report_date = as.Date(report_date),
         reflect_week_ending = anytime(reflect_week_ending),
         relfect_week_ending = as.Date(reflect_week_ending)) %>%
  select(-week_number, -status, -change_date)

#################
# Cleaning Data 

#################
## State Data 
eta.539_state <- eta.539_raw %>%  
  filter(report_date >= cutoff_date)  %>% 
  arrange(state, report_date) %>%
  group_by(state, report_date) %>%
  summarise(
    UCFE_initial = sum(ucfe_no_ui_claims, na.rm = TRUE),
    UCFE_continued = sum(ucfe_no_ut_adjusted_continued_weeks_claimed, na.rm = TRUE),
    ALL_initial = sum(state_ui_initial_claims + stc_workshare_equivalent_initial_claims, na.rm = TRUE),
    ALL_continued = sum(state_ui_adjusted_continued_weeks_claimed + stc_workshare_equivalent_continued_weeks_claimed, na.rm = TRUE),
    .groups = "drop"
  )

# Calculate U.S. totals by report_date
# Step 1: Summarise to national level (no lag yet)
eta.539_us <- eta.539_state %>%
  filter(state != "U.S.") %>%
  group_by(report_date) %>%
  summarise(
    state = "U.S.",
    UCFE_initial = sum(UCFE_initial, na.rm = TRUE),
    UCFE_continued = sum(UCFE_continued, na.rm = TRUE),
    ALL_initial = sum(ALL_initial, na.rm = TRUE),
    ALL_continued = sum(ALL_continued, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(report_date) %>%
  mutate(
    UCFE_yp_initial = lag(UCFE_initial, 52),
    UCFE_yp_continued = lag(UCFE_continued, 52),
    ALL_yp_initial = lag(ALL_initial, 52),
    ALL_yp_continued = lag(ALL_continued, 52)
  )


# Combine state-level and U.S.-level data
eta.539_state <- bind_rows(eta.539_state, eta.539_us) %>%
  group_by(state) %>%
  arrange(report_date) %>%
  mutate(
    UCFE_initial_smooth = slide_dbl(UCFE_initial, mean, .before = 3, .complete = TRUE),
    UCFE_continued_smooth = slide_dbl(UCFE_continued, mean, .before = 3, .complete = TRUE),
    ALL_initial_smooth = slide_dbl(ALL_initial, mean, .before = 3, .complete = TRUE),
    ALL_continued_smooth = slide_dbl(ALL_continued, mean, .before = 3, .complete = TRUE),
    
    YoY_federal_initial = percent(UCFE_initial / lag(UCFE_initial, 52) - 1),
    YoY_federal_continued = percent(UCFE_continued / lag(UCFE_continued, 52) - 1),
    YoY_initial = percent(ALL_initial / lag(ALL_initial, 52) - 1),
    YoY_continued = percent(ALL_continued / lag(ALL_continued, 52) - 1),
    
    YoY_federal_initial_smooth = percent(UCFE_initial_smooth / lag(UCFE_initial_smooth, 52) - 1),
    YoY_federal_continued_smooth = percent(UCFE_continued_smooth / lag(UCFE_continued_smooth, 52) - 1),
    YoY_initial_smooth = percent(ALL_initial_smooth / lag(ALL_initial_smooth, 52) - 1),
    YoY_continued_smooth = percent(ALL_continued_smooth / lag(ALL_continued_smooth, 52) - 1)
  ) %>%
  ungroup() %>%
  filter(report_date >= figure_date)

#################
## National Data 
eta.539_national <- eta.539_state  %>% 
  filter(state=="U.S.")

################
## State Data in Excel format
vars_to_pivot <- c(
  "UCFE_initial", "UCFE_continued", "ALL_initial", "ALL_continued",
  "UCFE_initial_smooth", "UCFE_continued_smooth", "ALL_initial_smooth", "ALL_continued_smooth",
  "YoY_federal_initial", "YoY_federal_continued", "YoY_initial", "YoY_continued",
  "YoY_federal_initial_smooth", "YoY_federal_continued_smooth", "YoY_initial_smooth", "YoY_continued_smooth"
)

# Create a named list of data frames: one for each variable, pivoted wide
state_pivoted_list <- lapply(vars_to_pivot, function(var) {
  eta.539_state %>%
    filter(
      report_date >= "2024-03-11",
      state %in% c("DC", "VA", "MD", "DE", "OH", "ND", "UT", "U.S.")
    ) %>% 
    select(report_date, state, value = all_of(var)) %>%
    pivot_wider(names_from = state, values_from = value)
})

# Name each list element with the corresponding variable name
names(state_pivoted_list) <- vars_to_pivot


