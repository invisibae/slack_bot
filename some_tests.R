library(tidyverse)
library(rvest)
library(janitor)
library(dplyr)
library(furrr)
library(rjson)
library(curl)
library(DBI)
library(RSQLite)
library(RCurl)
library(data.table)
library(lubridate)
library(knitr)

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

heres_the_file


# Let's try to get labor data from the db file

#db will be where we can get each individual table from the SQLite DB
db <- dbConnect(dbDriver("SQLite"), dbname = heres_the_file)

#This is our list of tables as outlined on github
dbListTables(db)

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

nlrb_alleg <- nlrb_filing %>%
  left_join(nlrb_allegation, by = "case_number") %>%
  filter(!is.na(allegation))


nlrb_alleg$date_filed <- nlrb_alleg$date_filed %>% ymd()

test$date_filed %>% typeof()

nlrb_alleg2 <- nlrb_alleg %>%
  filter(date_filed > "2022-01-01") %>%
  group_by(name, date_filed, city, state) %>%
  summarise(count = n(),
            allegations = paste(allegation, collapse = ""),
            .groups = "keep") 


  
  
nlrb_alleg3 <- nlrb_alleg %>%
  filter(date_filed > "2022-01-01") %>%
  group_by(name, date_filed, city, state, url) %>%
  summarise(count = n(),
            allegations = combine_words(allegation),
            .groups = "keep")

write_csv(nlrb_alleg3, "data/allegations_test.csv")


#get rid of the temp file 
unlink("temp_dir")





######## having some fun 
hotel_workers_pandemic <- nlrb_filing %>%
  mutate(date_filed = ymd(date_filed)) %>%
  mutate(name = toupper(name)) %>%
  filter(str_detect(toupper(name), "UNITE HERE")) %>%
  filter(date_filed >= "2020-01-01")
  

test <- hotel_workers_pandemic %>%
  inner_join(nlrb_allegation, by = "case_number") %>%
  select(name, allegation, city, state, date_filed, date_closed, reason_closed, url)

document_links <- nlrb_doc_link %>%
  select(case_number, url)

nlrb_allegations_w_docs <- nlrb_doc_link %>%
  left_join(nlrb_filing, by ="case_number") %>%
  left_join(nlrb_allegation, by = "case_number") %>%
  filter(!is.na(name) & !is.na(allegation)) 

nlrb_allegations_w_docs$created_a <- nlrb_allegations_w_docs$created_at %>%
  as.Date("%Y-%m-%d") 

nlrb_allegations_w_docs %>% 
  View()




#############

URL <- "https://beta.bls.gov/dataViewer/view/timeseries/APU000074714"

cpi_gas_table <- URL %>%
  read_html() %>%
  html_table()

cpi_gas_table<- cpi_gas_table[[4]]

