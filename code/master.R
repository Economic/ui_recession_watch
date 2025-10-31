library(tidyverse)
library(data.table)
library(lubridate)
library(here)
library(anytime)
library(formattable)
library(janitor)
library(readr)
library(openxlsx)
library(slider)
library(dplyr)
library(zoo)
library(pdftools)

## Set relevant dates
current_date <- ymd("2025-10-30")
cutoff_date <- current_date %m-% years(1) - weeks(5)
figure_date <- current_date %m-% years(2) - weeks(5)


# extract key pdf data that is not found in raw extracts at time of release
source("code/pdf_extract.R", echo = TRUE)

# download raw DOL ETA data and clean
source("code/clean_539_data.R", echo = TRUE)

# create excel for wp figures
source("code/wp_figures.R", echo = TRUE)





