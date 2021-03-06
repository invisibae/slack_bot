library(leaflet)
library(leaflet.providers)
library(data.table)
library(packcircles)
library(ggmap)
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
library(slackr)

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

test4 <- nlrb_filing %>%
  left_join(nlrb_doc_link)


test4 %>%
  group_by(region_assigned) %>%
  count(sort = T)





nlrb_filing$date_filed <- ymd(nlrb_filing$date_filed)




test2 <- test %>%
  filter(date_filed > "2022-01-01") %>%
  group_by(name, date_filed, city, state) %>%
  summarise(count = n(),
            allegations = paste(allegation, collapse = ""),
            .groups = "keep")




test3 <- test %>%
  filter(date_filed > "2020-01-01") %>%
  group_by(name, date_filed, city, state, url) %>%
  summarise(count = n(),
            allegations = combine_words(allegation),
            .groups = "keep")

date <- paste("data/allegations", date(), sep =" ") %>%
  paste0(".csv")



test3$date_filed <- test3$date_filed %>%
  ymd()

# construct the post

# adds in a couple of important variables like office handling the allegation

test5 <- test3 %>%
  left_join(nlrb_filing)




latest_date <- test5 %>%
  ungroup() %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  arrange(desc(week)) %>%
  filter(week == max(week)) %>%
  select(week)



latest_date <- latest_date$week %>%
  head(1)



this_week_cases <- test5 %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  filter(week == latest_date) 




allegation_count <- test5 %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  filter(week == latest_date) %>%
  summarise(count = sum(count),
            n = n()
  )


year_ago_date <- test5 %>%
  ungroup() %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  summarise() %>%
  arrange(desc(week)) %>%
  .[53,]

year_ago_allegation_count <- test5 %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  filter(week == year_ago_date) %>%
  summarise(count = sum(count),
            n = n()
  )

year_ago_allegation_type <- test5 %>%
  ungroup() %>%
  group_by(week = floor_date(date_filed, unit="week")) %>%
  filter(week == latest_date) %>%
  count(allegations, sort = T) %>%
  mutate(allegation_short = case_when(str_detect(allegations, "Refusal to Furnish") ~ "Refusal to Furnish Information",
                                      str_detect(allegations, "Concerted") ~ "Retalation",
                                      str_detect(allegations, "Fair Representation") ~ "Duty of Fair Representation",
                                      str_detect(allegations, "Refusal to Bargain") ~ "Refusal to Bargain",
                                      str_detect(allegations, "Discharge") ~ "Discharge (Including Layoff and Refusal to Hire"
  ))


most_common_allegation <- year_ago_allegation_type %>%
  .[1,]

second_most_common_allegation <- year_ago_allegation_type %>%
  .[2,]

third_most_common_allegation <- year_ago_allegation_type %>%
  .[3,]

allegation_1 <- most_common_allegation$allegation_short

allegation_1_n <- most_common_allegation$n


allegation_2 <- second_most_common_allegation$allegation_short

allegation_2_n <- second_most_common_allegation$n

allegation_3 <- third_most_common_allegation$allegation_short

allegation_3_n <- third_most_common_allegation$n





n_firms <- allegation_count$n %>%
  head(1)

n_allegations <- allegation_count$count %>%
  head(1)

year_ago_n_firms <- year_ago_allegation_count$n %>%
  head(1)

year_ago_n_allegations <- year_ago_allegation_count$count %>%
  head(1)


up_or_down <- case_when(
  n_allegations > year_ago_n_allegations ~ print("up"),
  n_allegations < year_ago_n_allegations ~ print("down"),
  n_allegations == year_ago_n_allegations ~ print("equal to"),
  TRUE ~ print("error")
)



latest_date_2 <- format.Date(latest_date, format = "%B %d, %Y")

pct_change <- paste0(round((n_allegations - year_ago_n_allegations) / year_ago_n_allegations * 100), "%")

this_week_cases <- "https://www.nlrb.gov/search/case"

two_lines <- writeLines(c("Read more about this week's cases here:", this_week_cases))

this_week_allegations <-paste("This week, the week of", paste0(latest_date_2, ","), "workers at",
                              n_firms, "firms alleged a total of", n_allegations,
                              "violations of the National Labor Relations Act",
                              "including", paste0(allegation_1),
                              paste0("(",allegation_1_n, " times),"),
                              paste0(allegation_2),
                              paste0("(",allegation_2_n, " times),"),
                              "and", paste0(allegation_3),
                              paste0("(",allegation_3_n, " times)."),
                              "This is", up_or_down, pct_change, "from", year_ago_n_allegations, "a year ago this week.") %>%
  paste("Read more about this week's cases here:", this_week_cases) %>%
  print(two_lines)

write.table(this_week_allegations, file = "data/this_week_allegations_yday.txt", sep = "\t",
            row.names = TRUE, col.names = NA)



y_day_allegations <- readChar("data/this_week_allegations_yday.txt", 
                              file.info("data/this_week_allegations_yday.txt")$size) %>%
  str_remove_all("\n")







# Post To Slack

if (this_week_allegations == y_day_allegations) {
  slackr_msg(txt = this_week_allegations,
             token = Sys.getenv("SLACK_TOKEN"),
             channel = Sys.getenv("SLACK_CHANNEL"),
             username = Sys.getenv("SLACK_USERNAME"),
             icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
             thread_ts = NULL,
             reply_broadcast = FALSE
  )
} else {
  slackr_msg(txt = "No new labor updates today :cry:",
             token = Sys.getenv("SLACK_TOKEN"),
             channel = Sys.getenv("SLACK_CHANNEL"),
             username = Sys.getenv("SLACK_USERNAME"),
             icon_emoji = Sys.getenv("SLACK_ICON_EMOJI"),
             thread_ts = NULL,
             reply_broadcast = FALSE)
  
}

# save rds

# saveRDS(this_week_allegations, "data/this_week_allegations_text.rds")

## print map and geocode 

# Real quick gonna write a way to automate filtering this week's cases so they can be easily mapped and geocoded in the script

this_week <- test5 %>%
  filter(date_filed >= latest_date) %>% 
  mutate(city_name = paste0(city, ", " ,state)) %>%
  mutate(count2 = count * 1.8)




for(i in 1:nrow(this_week)){
  # Print("Working...")
  result <- geocode(this_week$city_name[i], output = "latlona", source = "google")
  this_week$lon[i] <- as.numeric(result[1])
  this_week$lat[i] <- as.numeric(result[2])
  this_week$geoAddress[i] <- as.character(result[3])
}

this_week$label <- paste0("Name: ", this_week$name,"<br>",
                          "Allegation: ", this_week$allegations,"<br>",
                          "Date Filed:", this_week$date_filed)


this_week_map <- this_week %>% 
  leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addProviderTiles(providers$CartoDB.Positron) %>%
  addMarkers(lng= ~lon, lat= ~lat , popup = ~label,
             clusterOptions = markerClusterOptions())




## Create heatmap 


this_year <- test5 %>%
  filter(date_filed > today() - 365) %>%
  mutate(city_name = paste0(city, ", " ,state)) 

this_year_for_heatmap <- this_year %>%
  group_by(state) %>%
  summarise(month = lubridate::floor_date(date_filed, "month")) %>%
  count(month) %>%
  pivot_wider(names_from = month, values_from = n)

this_year_for_heatmap <- this_year_for_heatmap %>%
  filter(!is.na(state)) %>%
  replace(is.na(.), 0)

this_year %>%
  group_by(state) %>%
  summarise(month = lubridate::floor_date(date_filed, "month")) %>%
  count(month)


heatmap_cols <- this_year_for_heatmap %>% colnames()

heatmap_rows <- this_year_for_heatmap$state



row.names(this_year_for_heatmap) <- heatmap_rows

heatmap_matrix <- data.matrix(this_year_for_heatmap)

# save rds

# saveRDS(heatmap_matrix, "data/heatmap_matrix.rds")

##

row.names(heatmap_matrix) <- heatmap_rows

heatmap_matrix <- heatmap_matrix[,-1]

this_year_heatmap <- heatmap(heatmap_matrix, Rowv=NA, Colv=NA, col = cm.colors(256), scale="none", margins=c(5,10))

heatmap(heatmap_matrix, Rowv=NA, Colv=NA, col = cm.colors(256), scale="none", margins=c(5,10))

#save heatmap RDS

# saveRDS(this_year_heatmap, "data/this_year_heatmap.rds")

## save RDS of map for RMD file 

# saveRDS(this_week_map, file = "data/this_week_map.rds")


#get rid of temp files

unlink(temp_dir, recursive = T)
dir.exists(temp_dir)

dir.create(tempdir())
