workplace_deaths <- read_csv("data/workplace_deaths_test.csv")

workplace_deaths

workplace_deaths <- workplace_deaths %>%
  rename(industry_name = `Industry Sector`)

union_by_industry <- read_csv("data/union_by_industry_test.csv")

industry_names <- workplace_deaths$`Industry Sector` %>%
  str_to_upper()

workplace_deaths %>%
  filter(`Industry Sector` == industry_names) %>% 
  select(`Industry Sector`,`2020`)

union_by_industry  <- union_by_industry %>% 
  rename("industry_name" = "...1")

union_by_industry$industry_name

union_test <- union_by_industry %>% 
  mutate(industry_name = str_to_upper(industry_name)) %>% 
  rename(pct_union_repped = `Percent of employed Union Represented`) %>%
  filter(industry_name %in% industry_names) 


workplace_deaths_2020 <- workplace_deaths %>%
  mutate(industry_name = str_to_upper(industry_name)) %>%
  select(industry_name, `2020`)
  
death_graph <- workplace_deaths_2020 %>% 
  rename(death_rate_2020 = `2020`
         ) %>% 
  left_join(union_test) %>% 
  select(industry_name, death_rate_2020, pct_union_repped, `Total Employed (in thousands)`)


death_graph %>%
  filter(!is.na(pct_union_repped | !is.na(`Total Employed (in thousands)`))) %>%
  ggplot() +
  geom_point(aes(x = pct_union_repped, y = death_rate_2020, size = `Total Employed (in thousands)`, color = industry_name)) +
  geom_smooth(aes(x = pct_union_repped, y = death_rate_2020))


death_graph %>%
  filter(is.na(pct_union_repped))

union_by_industry %>%
  select(industry_name) %>%
  View()

death_graph




