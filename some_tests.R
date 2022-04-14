library(tidyverse)
library(rvest)
library(janitor)
library(dplyr)
library(DBI)
library(RSQLite)
library(data.table)
library(lubridate)
library(knitr)
library(remotes)





#first let's try to download the linked sql db file

url <- "https://github.com/labordata/nlrb-data"

labor_html <- read_html(url)

# we'll get the download link here
nlrb_download_url <- labor_html %>%
  html_nodes("#readme ul li:nth-child(1) a") %>%
  html_attr("href")



#make a temp file to store the zip
temp<- tempfile()

temp_dir <- tempdir()

#download zip to temporary file
download.file(nlrb_download_url, temp)


#and unzip
unzip(temp, exdir = temp_dir)


#append directory name, base name, and file name to get a consistent file path
temp_dir_name <- dirname(temp_dir)
temp_base_name <- basename(temp_dir)

heres_the_file <- paste0(temp_dir_name, "//",temp_base_name, "/nlrb.db")



# Let's try to get labor data from the db file

#db will be where we can get each individual table from the SQLite DB
db <- dbConnect(dbDriver("SQLite"), dbname = heres_the_file)

#This is our list of tables as outlined on github


#grabs the table for filings
nlrb_filing <- dbReadTable(db, "filing")
nlrb_docket <- dbReadTable(db, "docket")
nlrb_doc_link <- dbReadTable(db, "document")
nlrb_election <- dbReadTable(db, "election")
nlrb_election_mode <- dbReadTable(db, "election_mode")
nlrb_election_result <- dbReadTable(db, "election_result")
nlrb_allegation <- dbReadTable(db, "allegation")
nlrb_participant <- dbReadTable(db, "participant")
nlrb_sought_unit <- dbReadTable(db, "sought_unit")
nlrb_tally<- dbReadTable(db, "tally")
nlrb_voting_unit <- dbReadTable(db, "voting_unit")

test <- nlrb_filing %>%
  left_join(nlrb_allegation, by = "case_number") %>%
  filter(!is.na(allegation))



test$date_filed %>% typeof()

test2 <- test %>%
  filter(date_filed > "2022-01-01") %>%
  group_by(name, date_filed, city, state) %>%
  summarise(count = n(),
            allegations = paste(allegation, collapse = ""),
            .groups = "keep")




test3 <- test %>%
  filter(date_filed > "2022-01-01") %>%
  group_by(name, date_filed, city, state, url) %>%
  summarise(count = n(),
            allegations = combine_words(allegation),
            .groups = "keep")

date <- paste("data/allegations", date(), sep =" ") %>% 
  paste0(".csv")

write_csv(test3, date)


#get rid of temp files

unlink(temp_dir, recursive = T)
dir.exists(temp_dir)
