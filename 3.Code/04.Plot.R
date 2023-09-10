ggplot() + 
  geom_sf(data = reloc_cities, aes(geometry = geometry),
          color = "grey") +
  geom_sf(data = gov_samples, aes(geometry = geometry), 
          color = "blue") +
  geom_sf(data = old_gov, aes(geometry = geometry), 
          color = "green") +
  geom_sf(data = old_comms, aes(geometry = geometry), 
          color = "green") +
  geom_sf(data = new_gov, aes(geometry = geometry), 
          color = "red") +
  geom_sf(data = new_comms, aes(geometry = geometry), 
          color = "red") +
  geom_sf(data = ctrl_govs_valid, aes(geometry = geometry),
          color = "purple") +
  geom_sf(data = ctrl_comms_valid, aes(geometry = geometry),
          color = "purple") 
# +
#   geom_sf_label(data = reloc_cities, aes(label = 市),
#                 size = 3, color = "gray40")


st_write(all_comms, "../1.Input/comms.geojson", delete_dsn = TRUE)

all_comms <- as.data.frame(all_comms) %>% 
  st_as_sf() %>% 
  st_transform(crs=4326)

all_govs <- st_as_sf(all_govs) %>% 
  st_transform(crs=4326)

new_old_distance_4326 <- st_distance(st_transform(new_gov, crs = 4326), 
                                     st_transform(old_gov, crs = 4326)
                                     , by_element = TRUE) %>%
  as.numeric()

distance_leaflet <- 1500

leaflet(all_comms) %>%
  geoqmap(attribution = "Government Relocation") %>%
  # addPolygons(data = all_comms %>% 
  #               filter(ctrl_dis == distance_leaflet),
  #             color = ~label
  #             
  #             
  #             ) %>%
  addMeasure(primaryLengthUnit = "meters") %>%
  # gdmap(type = "normal", attribution = "Alan Huang") %>%
  # addProviderTiles(
  #   "OpenStreetMap",
  #   # give the layer a name
  #   group = "OpenStreetMap"
  # ) %>%
  # addTiles(group = "OSM(default)") %>% 
  # addProviderTiles("Esri.WorldImagery", group = "ESRI") %>% 
  # addProviderTiles("Stamen.Toner", group = "Stamen") %>% 
  # addLayersControl(baseGroup = c("OSM(default", "ESRI", "Stamen")) %>% 
  # addTiles(urlTemplate = "https://mts1.google.com/vt/lyrs=s&hl=en&src=app&x={x}&y={y}&z={z}&s=G", 
  #          attribution = 'Google') %>% 
  addCircles(data = old_gov,
             ~before_long, ~before_lat, 
             # popup = ~as.character(市), 
             # label = ~as.character(市),
             radius = new_old_distance_4326, color = "blue") %>%
  # addMarkers(data = ctrl_govs) %>%
  addMarkers(data = new_gov,
             ~after_long, ~after_lat, 
             popup = ~as.character(市), 
             label = "treatment groups, new govs") %>%
  addCircles(data = new_gov,
             ~after_long, ~after_lat, 
             popup = ~as.character(市), 
             label = "treatment groups, new govs",
             radius = distance_leaflet, color = "red") %>%
  addMarkers(data = old_gov,
             ~before_long, ~before_lat, 
             # popup = ~as.character(市), 
             label = "old govs") %>%
  addCircles(data = old_gov,
             ~before_long, ~before_lat, 
             # popup = ~as.character(市), 
             label = "old govs",
             radius = distance_leaflet, color = "green") %>%
  addMarkers(data = all_govs %>% 
               filter(ctrl_dis == distance_leaflet),
             # popup = ~as.character(市),
             label = "control groups") %>%
  addCircles(data = all_govs %>% 
               filter(ctrl_dis == distance_leaflet),
             label = "control groups",
             radius = distance_leaflet, color = "purple")

sessionInfo()
