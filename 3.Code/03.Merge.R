rm(list = ls()) 
set.seed(1234)
library(tidyverse)
library(sf)
library(leaflet)
library(leafem)
library(rstatatools)
library(tidyverse)
library(fs)
library(parallel)
library(geojsonsf)
library(ggspatial)
setwd(here::here("0.DataCleaning/2.Output"))

for (f in c(1, 2, 3)) {
  comms <- geojson_sf(paste0("../1.Input/comms", f, ".geojson")) %>% 
    st_make_valid() %>% 
    st_transform(crs=4326) %>% 
    mutate(group=1:n()) %>% 
    st_drop_geometry()
  
  print(paste0('*light_', f, '.csv'))
  file.list <- list.files(pattern=paste0('*light_', f, '.csv'))
  list_data <- lapply(file.list, read_csv, show_col_types = FALSE)
  # list_data <- mapply(read_csv, file.list, show_col_types = FALSE)
  
  reduce(list_data, bind_rows) -> df
  df <- df %>%
    mutate(year = str_sub(file, - 4, - 1),
           group = group)
  
  DF <- df %>% 
    full_join(comms, by=c("group"))
  
  write_csv(DF, paste0("DF", f, ".csv"))
}

file.list <- list.files(pattern=paste0('*light_city.csv'))
list_data <- lapply(file.list, read_csv, show_col_types = FALSE)
reduce(list_data, bind_rows) -> df
df <- df %>%
  mutate(year = str_sub(file, - 4, - 1))
write_csv(df, paste0("DF_city.csv"))
