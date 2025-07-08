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
  mutate(
    report_date = as.Date(anytime(report_date)),
    reflect_week_ending = as.Date(anytime(reflect_week_ending))
  )%>%
  select(-week_number, -status, -change_date)

#################
# Cleaning Data 

#################
## State Data 

# Initial claims summarized by state and report_date
initial_claims <- eta.539_raw %>%
  filter(report_date >= cutoff_date) %>%
  summarise(
    UCFE_initial = sum(ucfe_no_ui_claims, na.rm = TRUE),
    ALL_initial = sum(state_ui_initial_claims + stc_workshare_equivalent_initial_claims, na.rm = TRUE) / 1000,
    .by = c(state, report_date)
  ) %>% 
  rename(date = report_date)

# Continued claims summarized by state and reflect_week_ending
continued_claims <- eta.539_raw %>%
  filter(report_date >= cutoff_date) %>%
  summarise(
    UCFE_continued = sum(ucfe_no_ut_adjusted_continued_weeks_claimed, na.rm = TRUE),
    ALL_continued = sum(state_ui_adjusted_continued_weeks_claimed + stc_workshare_equivalent_continued_weeks_claimed, na.rm = TRUE) / 1000,
    .by = c(state, reflect_week_ending)
  ) %>%
  rename(date = reflect_week_ending)

# Join them back together
eta.539_state <- initial_claims %>%
  left_join(continued_claims, by = c("state", "date")) %>%  
  mutate(date = as.Date(date))
  
   

# Calculate U.S. totals by report_date
eta.539_us <- eta.539_state %>%
  filter(state != "U.S.") %>%
  summarise(
    state = "U.S.",
    UCFE_initial = if (any(is.na(UCFE_initial))) NA_real_ else sum(UCFE_initial),
    UCFE_continued = if (any(is.na(UCFE_continued))) NA_real_ else sum(UCFE_continued),
    ALL_initial = if (any(is.na(ALL_initial))) NA_real_ else sum(ALL_initial),
    ALL_continued = if (any(is.na(ALL_continued))) NA_real_ else sum(ALL_continued),
    .by = c(date)
  ) %>%
  arrange(date) %>%
  mutate(
    UCFE_yp_initial = lag(UCFE_initial, 52,),
    UCFE_yp_continued = lag(UCFE_continued, 52),
    ALL_yp_initial = lag(ALL_initial, 52),
    ALL_yp_continued = lag(ALL_continued, 52)
  )

# Combine state-level and U.S.-level data
eta.539_final <- bind_rows(eta.539_state, eta.539_us) %>%
  group_by(state) %>%
  arrange(date) %>%
  mutate(
    UCFE_initial_smooth = slide_dbl(UCFE_initial, mean, .before = 3, .complete = TRUE),
    UCFE_continued_smooth = slide_dbl(UCFE_continued, mean, .before = 3, .complete = TRUE),
    ALL_initial_smooth = slide_dbl(ALL_initial, mean, .before = 3, .complete = TRUE),
    ALL_continued_smooth = slide_dbl(ALL_continued, mean, .before = 3, .complete = TRUE),
    
    YoY_federal_initial = UCFE_initial / lag(UCFE_initial, 52) - 1,
    YoY_federal_continued = UCFE_continued / lag(UCFE_continued, 52) - 1,
    YoY_initial = ALL_initial / lag(ALL_initial, 52) - 1,
    YoY_continued = ALL_continued / lag(ALL_continued, 52) - 1,
    
    YoY_federal_initial_smooth = UCFE_initial_smooth / lag(UCFE_initial_smooth, 52) - 1,
    YoY_federal_continued_smooth = UCFE_continued_smooth / lag(UCFE_continued_smooth, 52) - 1,
    YoY_initial_smooth = ALL_initial_smooth / lag(ALL_initial_smooth, 52) - 1,
    YoY_continued_smooth = ALL_continued_smooth / lag(ALL_continued_smooth, 52) - 1
  ) %>%
  ungroup() %>%
  filter(date >= figure_date)

#################
## National Data 
eta.539_national <- eta.539_final  %>% 
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
  eta.539_final %>%
    filter(
      state %in% c("DC", "VA", "MD", "U.S.")
    ) %>% 
    select(date, state, value = all_of(var)) %>%
    pivot_wider(names_from = state, values_from = value)
})

# Name each list element with the corresponding variable name
names(state_pivoted_list) <- vars_to_pivot




