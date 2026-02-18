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

# Make the SA seires

SA_claims <- eta_539_national |>  
  left_join(seasonal_adjustment, by = "date") |>  
  mutate( 
    initial_sa = round(ALL_initial/as.numeric(IC_adjust)),
    continued_sa = round(ALL_continued/as.numeric(IU_adjust)),
    smooth_ic_sa = slide_dbl(initial_sa, mean, .before = 3, .complete = TRUE), 
    smooth_cc_sa = slide_dbl(continued_sa, mean, .before = 3, .complete = TRUE)
  ) |> 
  filter( 
    date >= "2020-1-4") |> 
    select(date, initial_sa, continued_sa, smooth_ic_sa, smooth_cc_sa)


  write_csv(SA_claims, "output/SA_claims.csv")
