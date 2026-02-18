# Raw Data # 

# download eta 539 files with system command
# "wget -N" omites download if data has not been updated "-P" sets the file destination"
system(paste0("wget -N https://oui.doleta.gov/unemploy/csv/ar539.csv  -P suppdata/"))

# Create varibale names and add state codes 
eta.539_var_names <- fread(here("suppdata","eta539_var_names.csv"))
eta.539_old_names <- eta.539_var_names$dol_code
eta.539_new_names <- eta.539_var_names$dol_title
state_codes <- read_csv(here("suppdata", "state_geocodes.csv")) |> 
  select(state = state_name, state_abb)

# Read in the seasonal adjustment files
GET("https://www.bls.gov/lau/current-factors.xlsx", 
    add_headers(`User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"),
    write_disk("suppdata/current-factors.xlsx", overwrite = TRUE))

seasonal_adjustment <- read.xlsx("suppdata/current-factors.xlsx") |> 
  slice(-1) |>                                        # delete first row
  mutate(date = seq(as.Date("2020-01-04"), 
                    by = "7 days", 
                    length.out = n()),
         date = as.Date(date)) |> 
  relocate(date, .before = 1) |> 
  select(date, IC_adjust = X2, IU_adjust = X3)


##############
# Raw ETA 539 
eta.539_raw <- fread(here("suppdata","ar539.csv")) |>
  # replace variable names to be more readable
  setnames(old = eta.539_old_names, new = eta.539_new_names) |>
  select(all_of(eta.539_new_names)) |>
  # format date as class 'Date' 
  mutate(
    report_date = as.Date(anytime(report_date)),
    reflect_week_ending = as.Date(anytime(reflect_week_ending))
  )


##########################################################
# Cleaning Data and Adding in the numbers extracted by pdf 

# Initial claims summarized by state and report_date
initial_claims <- eta.539_raw |>
  mutate(
    UCFE_initial = ucfe_no_ui_claims,
    ALL_initial = (state_ui_initial_claims + stc_workshare_equivalent_initial_claims) / 1000) |> 
  rename(date = report_date)

# Adding the extrcated value 
new_row <- tibble(
  date            = max(initial_claims$date) + 7,  
  UCFE_initial    = NA_real_,
  ALL_initial     = initial_claims_all/1000,
  state             = "US"
)

initial_claims <- bind_rows(initial_claims, new_row)

# Continued claims summarized by state and reflect_week_ending
continued_claims <- eta.539_raw |>
  mutate(
    UCFE_continued = ucfe_no_ut_adjusted_continued_weeks_claimed,
    ALL_continued = (state_ui_adjusted_continued_weeks_claimed + stc_workshare_equivalent_continued_weeks_claimed) / 1000) |>
  rename(date = reflect_week_ending)

## Adding the extrcated value 
new_rows <- tibble(
  date            = max(continued_claims$date) + c(7,7,7),  # or whatever your next date should be
  UCFE_continued    = NA_real_,
  ALL_continued     = c(DC_continued/1000, MD_continued/1000, VA_continued/1000),
  state             = c("DC", "MD", "VA")
)

continued_claims <- bind_rows(continued_claims, new_rows)

# Join them back together and add the PDF extracts 
eta.539 <- initial_claims |>
  left_join(continued_claims, by = c("state", "date")) |>  
  mutate(date = as.Date(date)) |> 
  select(date, state, UCFE_initial, ALL_initial, UCFE_continued, ALL_continued)
  
##################
# National dataset 
eta_539_national <- eta.539 |> 
  arrange(date) |>
  summarise(
    UCFE_initial = sum(UCFE_initial, na.rm = TRUE),
    UCFE_continued = sum(UCFE_continued, na.rm = TRUE),
    ALL_initial = sum(ALL_initial, na.rm = TRUE),
    ALL_continued = sum(ALL_continued, na.rm = TRUE), 
    .by = (date)) |> 
  mutate(
    UCFE_yp_initial = lag(UCFE_initial, 52,),
    UCFE_yp_continued = lag(UCFE_continued, 52),
    ALL_yp_initial = lag(ALL_initial, 52),
    ALL_yp_continued = lag(ALL_continued, 52), 
    state = "US"
  ) 

eta_539_national$ALL_continued[nrow(eta_539_national) - 1] <- continued_claims_all/1000

###############
# State dataset 
eta_539_state <- eta.539 |> 
  bind_rows(eta_539_national |> select(date, state, UCFE_initial, ALL_initial, UCFE_continued, ALL_continued)) |>
   mutate(
    UCFE_initial_smooth = slide_dbl(UCFE_initial, mean, .before = 3, .complete = TRUE),
    UCFE_continued_smooth = slide_dbl(UCFE_continued, mean, .before = 3, .complete = TRUE),
    ALL_initial_smooth = slide_dbl(ALL_initial, mean, .before = 3, .complete = TRUE),
    ALL_continued_smooth = slide_dbl(ALL_continued, mean, .before = 3, .complete = TRUE),
    
    YoY_federal_initial_smooth = UCFE_initial_smooth / lag(UCFE_initial_smooth, 52) - 1,
    YoY_federal_continued_smooth = UCFE_continued_smooth / lag(UCFE_continued_smooth, 52) - 1,
    YoY_initial_smooth = ALL_initial_smooth / lag(ALL_initial_smooth, 52) - 1,
    YoY_continued_smooth = ALL_continued_smooth / lag(ALL_continued_smooth, 52) - 1
  )


################
## State Data in Excel format
vars_to_pivot <- c(
  "UCFE_continued",  "ALL_continued",
   "UCFE_continued_smooth",  "ALL_continued_smooth",
   "YoY_federal_continued_smooth", "YoY_continued_smooth"
)

# Create a named list of data frames: one for each variable, pivoted wide
state_pivoted_list <- lapply(vars_to_pivot, function(var) {
  eta_539_state %>%
    group_by(date, state) %>%               # ensure uniqueness
    summarise(value = sum(.data[[var]], na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = state, values_from = value)
})


# Name each list element with the corresponding variable name
names(state_pivoted_list) <- vars_to_pivot