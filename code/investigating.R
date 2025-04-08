## Visualizations ## 

#National Visualizations

### News release figure
ggplot(eta.539_national, aes(x = report_date)) +
  geom_line(aes(y = UCFE_initial, color = "Year Prior", linetype = "Dotted"), size = 1) +
  geom_line(aes(y = UCFE_yp_initial , color = "Lastest 52 Weeks", linetype = "Solid"), size = 1) +
  scale_linetype_manual(values = c("Dotted" = "dotted", "Solid" = "solid")) +
  scale_y_continuous(limits = c(0, 2000)) +  # Set y-axis scale
  labs(
    title = "FEDERAL",
    x = "Date",
    y = "Sum of UCFE Initial Claims",
    color = "Legend"
  ) +
  theme_minimal()

ggplot(eta.539_national, aes(x = report_date)) +
  geom_line(aes(y = ALL_initial, color = "Year Prior", linetype = "Dotted"), size = 1) +
  geom_line(aes(y = ALL_yp_initial, color = "Lastest 52 Weeks", linetype = "Solid"), size = 1) +
  scale_linetype_manual(values = c("Dotted" = "dotted", "Solid" = "solid")) +
  scale_y_continuous(limits = c(0, 500000)) +  # Set y-axis scale
  labs(
    title = "ALL",
    x = "Date",
    y = "Sum of Initial Claims",
    color = "Legend"
  ) +
  theme_minimal()

### YOY plots
ggplot(eta.539_national, aes(x = report_date)) +
  geom_line(aes(y = YoY_federal_initial), size = 1) + # Set y-axis scale
  labs(
    title = "FEDERAL",
    x = "Date",
    y = "YoY % UCFE Initial Claims",
    color = "Legend"
  ) +
  theme_minimal()

ggplot(eta.539_national, aes(x = report_date)) +
  geom_line(aes(y = YoY_initial), size = 1) +
  scale_y_continuous(limits = c(-1, 1)) +
  labs(
    title = "ALL",
    x = "Date",
    y = "YoY % Initial Claims",
    color = "Legend"
  ) +
  theme_minimal()


# State Visualizatios
eta.539_vis <- eta.539_state %>%
  filter(
    report_date >= "2024-03-11",
    state %in% c("DC", "VA", "MD", "DE", "OH", "ND", "UT", "U.S.")
  )

## Fed Initial Claims 
ggplot(eta.539_vis, aes(x = report_date, y = YoY_federal_initial, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "FEDERAL initial ",
    x = "Date",
    y = "YoY % UCFE Initial Claims",
    color = "State"
  ) +
  theme_minimal()

## Fed Initial Claims Smooth
ggplot(eta.539_vis, aes(x = report_date, y = YoY_federal_initial_smooth, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "FEDERAL initial smooth",
    x = "Date",
    y = "YoY % UCFE Initial Claims",
    color = "State"
  ) +
  theme_minimal()


# All Initial 
ggplot(eta.539_vis, aes(x = report_date, y = YoY_initial, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "ALL initial",
    x = "Date",
    y = "YoY % Initial Claims",
    color = "State"
  ) +
  theme_minimal()

# All initial smooth
ggplot(eta.539_vis, aes(x = report_date, y = YoY_initial_smooth, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "ALL initial smooth",
    x = "Date",
    y = "YoY % Initial Claims",
    color = "State"
  ) +
  theme_minimal()


## Fed Cont Claims 
ggplot(eta.539_vis, aes(x = report_date, y = YoY_federal_continued, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "FEDERAL continued ",
    x = "Date",
    y = "YoY % UCFE Continued Claims",
    color = "State"
  ) +
  theme_minimal()

## Fed Cont Claims Smooth
ggplot(eta.539_vis, aes(x = report_date, y = YoY_federal_continued_smooth, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "FEDERAL continued smooth",
    x = "Date",
    y = "YoY % UCFE Continued Claims",
    color = "State"
  ) +
  theme_minimal()

# All continued 
ggplot(eta.539_vis, aes(x = report_date, y = YoY_continued, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "ALL continued",
    x = "Date",
    y = "YoY % Continued Claims",
    color = "State"
  ) +
  theme_minimal()

# All cont smooth
ggplot(eta.539_vis, aes(x = report_date, y = YoY_continued_smooth, color = state)) +
  geom_line(size = 1) +
  labs(
    title = "ALL continued smooth",
    x = "Date",
    y = "YoY % Continued Claims",
    color = "State"
  ) +
  theme_minimal()
