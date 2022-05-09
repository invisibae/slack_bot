library(leaflet)
library(leaflet.providers)
devtools::install_github("hrbrmstr/rgeocodio")
library(rgeocodio)
library(data.table)
library(packcircles)
library(ggmap)




election_test <- nlrb_election %>%
  left_join(nlrb_election_result, by = "election_id") %>% 
  left_join(nlrb_tally, by = "election_id")

election_test%>% 
  View()

election_slim <- election_test %>%
  select(election_id, 
         case_number, 
         date, unit_size, 
         total_ballots_counted, 
         votes, void_ballots, 
         challenged_ballots, 
         challenges_are_determinative, 
         union_to_certify, option) %>%
  arrange(desc(election_id))

election_slim %>%
  left_join(nlrb_docket, by = "case_number") %>%
  filter(document == "Tally of Ballots") %>%
  View()

election_slim %>%
  head(1) %>%
  View()


write_csv(test3[1:100,], "data/location_test.csv") 

location_test <- read_csv("data/location_test_geocodio.csv")



# test map with leaflet package 
location_test %>% 
  leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addProviderTiles(providers$CartoDB.Positron) %>%
  addMarkers(lng= ~Longitude, lat= ~Latitude , popup = ~name)


# Giocodio API test (dud, boo, tomato, tomato, tomato, I'm throwing tomatoes)

city_names <- paste0(test3$city[1:100], ", " ,test3$state[1:100])

geo_code_test <- gio_batch_geocode(city_names) 


geo_code_test %>%
  select(geo_code_test$response_results[[1]]$location.lat)

geo_code_test$response_results[[1]] %>%
  select(location.lat, location.lng)





geo_code_test$response_results[[1]] %>%
  select(location.lat, location.lng) %>%
  View()


geo_code_test[1,]$response_results %>%
  as.data.frame() %>%
  select(location.lat, location.lng)

# build union elections df

ballot_test <- election_slim[1:100,] %>%
  group_by(election_id, option) %>%
  summarise(votes, unit_size, void_ballots, challenged_ballots, challenges_are_determinative) %>%
  pivot_wider(names_from = "option", values_from = "votes") 

hopefully_this <- election_slim[1:100,] %>%
  group_by(election_id, option) %>%
  summarise(votes, unit_size, void_ballots, challenged_ballots, challenges_are_determinative, date) %>%
  mutate(be_simple = case_when(option != "No union" ~ "union",
                               TRUE ~ "no union")) %>%
  pivot_wider(names_from = "be_simple", values_from = "votes") %>%
  ungroup() %>%
  group_by(election_id) 




union_elections_final <- setDT(hopefully_this)[, lapply(.SD, na.omit), by = election_id] %>%
  filter(option != "No union")

union_elections_final %>%
  View()


#####

#retry geocoding with ggogle maps api (duh)
  


register_google(key = "AIzaSyCZ_5R9m5ITdW74mWJD9fJDCeMg-fNxPl4")




city_names_test <- test3[1:100,] %>%
  ungroup() %>%
  mutate(city_name = paste0(city, ", " ,state)) 



geocode(location = city_names_test, output = "more", source = "google")


for(i in 1:nrow(city_names_test))
{
  # Print("Working...")
  result <- geocode(city_names_test$city_name[i], output = "latlona", source = "google")
  city_names_test$lon[i] <- as.numeric(result[1])
  city_names_test$lat[i] <- as.numeric(result[2])
  city_names_test$geoAddress[i] <- as.character(result[3])
}

city_names_test

### Success! Lets test out automated mapping with leaflet

city_names_test %>% 
  leaflet() %>%
  addTiles() %>%  # Add default OpenStreetMap map tiles
  addProviderTiles(providers$CartoDB.Positron) %>%
  addMarkers(lng= ~lon, lat= ~lat , popup = ~name)

# Real quick gonna write a way to automate filtering this week's cases so they can be easily mapped and geocoded in the script







