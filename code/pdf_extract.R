pdf_url <- "https://www.dol.gov/ui/data.pdf"
pdf_text <- pdf_text(pdf_url)

page4 <- pdf_text[4]
page5 <- pdf_text[5] 

## Extract the National continued and inital claims 
page4_numbers <- str_extract_all(page4, "([0-9,]+)")[[1]]

initial_claims_all <- as.numeric(gsub(",", "", page4_numbers[10]))
continued_claims_all <- as.numeric(gsub(",", "", page4_numbers[30]))

# Extract the state level initial and continued claims 
page5_numbers <- str_extract_all(page5, "([0-9,]+)")[[1]]

DC_continued <- as.numeric(gsub(",", "", page5_numbers[54]))
MD_continued <- as.numeric(gsub(",", "", page5_numbers[126]))
VA_continued <- as.numeric(gsub(",", "", page5_numbers[294]))

