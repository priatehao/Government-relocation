rm(list = ls()) 
set.seed(1234)
library(tidyverse)
library(sf)
library(leaflet)
library(leafem)
# library(rstatatools)
library(tidyverse)
library(fs)
library(parallel)
setwd(here::here("0.DataCleaning/1.Input"))

# 4326, WG84, longlat
# 3415, UTM, meters
read_sf("2019行政区划/市.shp") %>%
  st_transform(crs=4326) -> all_cities
st_is_longlat(all_cities)
st_crs(all_cities)
info <- read.csv("RelocationCities.csv") 
reloc_cities <- all_cities %>%
  left_join(info, by = c("市" = "city")) %>%
  filter(! before_long==0 )  %>%
  mutate(cityindex = row_number())

old_gov <- as.data.frame(reloc_cities) %>%
  st_as_sf(coords = c("before_long", "before_lat"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("old"))


new_gov <- as.data.frame(reloc_cities) %>%
  st_as_sf(coords = c("after_long", "after_lat"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("new"))


new_old_distance_3415 <- st_distance(st_transform(new_gov, crs = 3415), 
                                     st_transform(old_gov, crs = 3415), 
                                     by_element = TRUE) %>%
  as.numeric()



# gov_samples <- old_gov %>%
#   st_transform(crs = 3415) %>%
#   st_buffer(dist = new_old_distance_3415) %>%
#   st_cast("LINESTRING") %>%
#   st_transform(crs = 4326)

remove_invalid <- function(ctrl_comms) {
  data <- list()
  for (i in 1:nrow(reloc_cities) ) {
    # print(i)
    criteria1 <- st_intersects(ctrl_comms %>% 
                                 dplyr::filter(cityindex == i)
                               , new_comms %>% 
                                 dplyr::filter(cityindex == i)
                               , sparse = FALSE) %>% 
      apply(1, any)
    criteria2 <- st_within(ctrl_comms %>% 
                             dplyr::filter(cityindex == i)
                           , reloc_cities %>% 
                             dplyr::filter(cityindex == i)
                           , sparse = FALSE) %>% 
      apply(1, any)
    # print(criteria)
    data[[i]] <- ctrl_comms %>% 
      dplyr::filter(cityindex == i) %>% 
      # dplyr::filter((!criteria1) & (criteria2))
      mutate(valid =
      case_when(
        (!criteria1) & (criteria2) ~ 1,
        TRUE ~ 0
      ))
  }
  do.call(rbind, data)
}

# ctrl_comms_valid <- remove_invalid(ctrl_comms) 
# ctrl_govs_valid <- remove_invalid(ctrl_govs)  




# Random Communities within circles
sp <- 10
ctrl_per <- rep(sp, nrow(old_gov))
distance_l <- list(1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000)
# distance_l <- list(1000, 1500, 2000, 2500, 3000)
comms <- list()
govs <- list()
for (i in 1:length(distance_l)) {
  dist <- distance_l[[i]]
  print(dist)
  
  new_comms <- new_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>% 
    mutate(ctrl_dis = c(dist))
  
  old_comms <- old_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>%
    mutate(ctrl_dis = c(dist))
  
  ctrl_govs <- old_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = new_old_distance_3415) %>%
    st_cast("LINESTRING") %>% 
    st_sample(ctrl_per) %>%
    st_cast("POINT") %>%
    st_as_sf() %>%
    st_transform(crs = 4326) %>%
    rename(geometry = x) %>% 
    mutate(cityindex = ceiling(row_number()/sp)) %>% 
    full_join(st_drop_geometry(reloc_cities), by = "cityindex" ) %>% 
    mutate(ctrl_dis = c(dist),
           cityindex = as.integer(cityindex),
           label = c('control')
    )
  ctrl_govs_valid <- remove_invalid(ctrl_govs)
  ctrl_comms <- ctrl_govs %>% 
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    # st_cast("LINESTRING") %>%
    st_transform(crs = 4326)
  ctrl_comms_valid <- remove_invalid(ctrl_comms)
  coms <- list(ctrl_comms_valid, new_comms, old_comms) #
  gos <- list(ctrl_govs_valid, new_gov, old_gov) #
  comms[[i]] <- data.table::rbindlist(coms, fill=TRUE) %>% 
    arrange(cityindex)
  govs[[i]] <- data.table::rbindlist(gos, fill=TRUE) %>% 
    arrange(cityindex)
}
all_comms <- data.table::rbindlist(comms, fill=TRUE)
all_govs <- data.table::rbindlist(govs, fill=TRUE)

st_write(all_comms, "../1.Input/comms1.geojson", delete_dsn = TRUE)

# # Rings within the circles
# sp <- 10
# ctrl_per <- rep(sp, nrow(old_gov))
# distance_l <- list(1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000)
# # distance_l <- list(1000, 1500, 2000, 2500, 3000)
# comms <- list()
# govs <- list()
# for (i in 1:length(distance_l)) {
#   dist <- distance_l[[i]]
#   print(dist)
#   
#   new_comms <- new_gov %>%
#     st_transform(crs = 3415) %>%
#     st_buffer(dist = dist) %>%
#     st_transform(crs = 4326) %>% 
#     mutate(ctrl_dis = c(dist))
#   
#   new_comms_minus <- new_gov %>%
#     st_transform(crs = 3415) %>%
#     st_buffer(dist = dist-500) %>%
#     st_transform(crs = 4326) %>% 
#     mutate(ctrl_dis = c(dist))
#   
#   xx <- new_comms %>% 
#     st_difference(new_comms_minus)
# }  
#   # old_comms <- old_gov %>%
#   #   st_transform(crs = 3415) %>%
#   #   st_buffer(dist = dist) %>%
#   #   st_transform(crs = 4326) %>%
#   #   mutate(ctrl_dis = c(dist))
#   
#   ctrl_govs <- old_gov %>%
#     st_transform(crs = 3415) %>%
#     st_buffer(dist = new_old_distance_3415) %>%
#     st_cast("LINESTRING") %>% 
#     st_sample(ctrl_per) %>%
#     st_cast("POINT") %>%
#     st_as_sf() %>%
#     st_transform(crs = 4326) %>%
#     rename(geometry = x) %>% 
#     mutate(cityindex = ceiling(row_number()/sp)) %>% 
#     full_join(st_drop_geometry(reloc_cities), by = "cityindex" ) %>% 
#     mutate(ctrl_dis = c(dist),
#            cityindex = as.integer(cityindex),
#            label = c('control')
#     )
#   ctrl_govs_valid <- remove_invalid(ctrl_govs)
#   ctrl_comms <- ctrl_govs %>% 
#     st_transform(crs = 3415) %>%
#     st_buffer(dist = dist) %>%
#     # st_cast("LINESTRING") %>%
#     st_transform(crs = 4326)
#   ctrl_comms_valid <- remove_invalid(ctrl_comms)
#   coms <- list(ctrl_comms_valid, new_comms, old_comms) #
#   gos <- list(ctrl_govs_valid, new_gov, old_gov) #
#   comms[[i]] <- data.table::rbindlist(coms, fill=TRUE) %>% 
#     arrange(cityindex)
#   govs[[i]] <- data.table::rbindlist(gos, fill=TRUE) %>% 
#     arrange(cityindex)
# }
# all_comms <- data.table::rbindlist(comms, fill=TRUE)
# all_govs <- data.table::rbindlist(govs, fill=TRUE)
# 
# st_write(all_comms, "../1.Input/comms1.geojson", delete_dsn = TRUE)
# 
# st_multiringbuffer<-function(x,n,d, overlap=F){
#   buf<-function(dist){st_buffer(x,dist) %>% mutate(dist=dist)}
#   out<-purrr::map_df(seq(1:n)*d, buf) %>% arrange(desc(dist))
#   if (overlap==F) { 
#     out<-out %>% st_intersection() %>% dplyr::select(dist) %>%
#       mutate(dist=row_number()*d)
#   }
# }
# 
# xx <- st_multiringbuffer(new_gov, 5, 1000)
# 
# buf<-function(dist){st_buffer(new_gov,dist) %>% mutate(dist=dist)}
# out<-purrr::map_dfr(seq(1:5)*1000, buf) %>% arrange(desc(dist)) %>% mutate(group=1:n())
# if (overlap==F) { 
#   xx<-out %>% 
#     st_intersection() 
#   
#   %>% 
#     dplyr::select(dist) %>%
#     mutate(dist=row_number()*d)
# }
# 
# 
# out<-out %>% st_intersection()



# For Mechanism: FinancialInstitution.csv, InsuranceInstitution.csv
fin_inst_df <- read_csv('FinancialInstitution.csv', show_col_types = FALSE)
fin_inst <- as.data.frame(fin_inst_df) %>%
  st_as_sf(coords = c("经度", "纬度"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("fin_inst")) 

ins_inst_df <- read_csv('InsuranceInstitution.csv', show_col_types = FALSE)
ins_inst <- as.data.frame(ins_inst_df) %>%
  st_as_sf(coords = c("经度", "纬度"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("ins_inst")) 

enterprise_df <- read_csv('IndustryInfo.csv', show_col_types = FALSE)
enterprise <- as.data.frame(enterprise_df) %>%
  filter((!is.na(经度)) & (!is.na(纬度))) %>% 
  st_as_sf(coords = c("经度", "纬度"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("enterprise")) 

enterprise %>% 
  select(geometry, 年份) -> enterprise_compress

realestate_df <- read_csv('RealEstateInfo.csv', show_col_types = FALSE)
realestate <- as.data.frame(realestate_df) %>%
  filter((!is.na(经度)) & (!is.na(纬度)) & (!is.na(竣工时间)) ) %>% 
  mutate(finish_date = as.Date(竣工时间),
         finish_year = year(finish_date)) %>% 
  st_as_sf(coords = c("经度", "纬度"), 
           crs = 4326, remove = FALSE) %>%
  mutate(label = c("realestate")) 

realestate %>% 
  select(geometry, finish_year) -> realestate_compress

realestateprice <- realestate %>% 
  mutate(price = parse_number(价格)) %>% 
  filter((!is.na(price)) & (!price<500) ) %>% 
  mutate(priceid = 1:n())

realestateprice %>% 
  select(geometry, finish_year, price, priceid) -> realestateprice_compress

realestatehousehold <- realestate %>% 
  mutate(householdn = parse_number(当期户数)) %>% 
  filter((!is.na(householdn)) & (!householdn<10) ) %>% 
  mutate(householdid = 1:n())

realestatehousehold %>% 
  select(geometry, finish_year, householdn, householdid) -> realestatehousehold_compress


all_comms_fin_inst_list = list()
all_comms_ins_inst_list = list()
all_comms_ent_inst_list = list()
all_comms_rea_inst_list = list()
all_comms_pri_inst_list = list()
all_comms_hou_inst_list = list()
for (i in seq(2000, 2021, by=1)) {
  fin_inst_i <- fin_inst %>%
    filter(year <= i)
  ins_inst_i <- ins_inst %>%
    filter(year <= i)
  enterprise_compress_i <- enterprise_compress %>%
    filter(年份 <= i)
  realestate_compress_i <- realestate_compress %>% 
    filter(finish_year <= i)
  realestateprice_compress_i <- realestateprice_compress %>% 
    filter(finish_year <= i)
  realestatehousehold_compress_i <- realestatehousehold_compress %>% 
    filter(finish_year <= i)
  
  all_comms %>%
    mutate(fin_inst_count = lengths(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), fin_inst_i)),
           year = i,
           group=1:n()) %>%
    select(year, fin_inst_count, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp1

  all_comms %>%
    mutate(ins_inst_count = lengths(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), ins_inst_i)),
           year = i,
           group=1:n()) %>%
    select(year, ins_inst_count, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp2

  # all_comms %>%
  #   mutate(enterprise_count = lengths(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), enterprise_compress_i)),
  #          year = i,
  #          group=1:n()) %>%
  #   select(year, enterprise_count, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp3

  all_comms %>% 
    mutate(realestate_count = lengths(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), realestate_compress_i)),
           year = i,
           group=1:n()) %>% 
    select(year, realestate_count, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp4
  
  
  nn <- tibble::enframe(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), realestateprice_compress_i) , name = 'group', value = 'priceid') %>% 
    tidyr::unnest(priceid) %>% 
    left_join(realestateprice, by=c('priceid'='priceid')) %>% 
    group_by(group) %>% 
    summarise(realestate_avgprice = mean(price))

  all_comms %>% 
    mutate(group=1:n() ) %>% 
    left_join(nn, by=c('group'='group')) %>% 
    mutate(realestate_avgprice = replace_na(realestate_avgprice, 0),
           log_realestate_avgprice = log(realestate_avgprice+1),
           year = i) %>%
    select(year, realestate_avgprice, log_realestate_avgprice, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp5

  
  mm <- tibble::enframe(st_intersects(st_as_sf(all_comms, crs = 4326, remove = FALSE), realestatehousehold_compress_i) , name = 'group', value = 'householdid') %>% 
    tidyr::unnest(householdid) %>% 
    left_join(realestatehousehold, by=c('householdid'='householdid')) %>% 
    group_by(group) %>% 
    summarise(realestate_totalhh = sum(householdn))
  
  all_comms %>% 
    mutate(group=1:n() ) %>% 
    left_join(mm, by=c('group'='group')) %>% 
    mutate(realestate_totalhh = replace_na(realestate_totalhh, 0),
           year = i) %>%
    select(year, realestate_totalhh, label, cityindex, ctrl_dis, group, 实际迁移时间) -> temp6
  
  
  all_comms_fin_inst_list[[i-1999]] = temp1
  all_comms_ins_inst_list[[i-1999]] = temp2
  # all_comms_ent_inst_list[[i-1999]] = temp3
  all_comms_rea_inst_list[[i-1999]] = temp4
  all_comms_pri_inst_list[[i-1999]] = temp5
  all_comms_hou_inst_list[[i-1999]] = temp6
}

reduce(all_comms_fin_inst_list, bind_rows) -> all_comms_fin_inst
reduce(all_comms_ins_inst_list, bind_rows) -> all_comms_ins_inst
reduce(all_comms_ent_inst_list, bind_rows) -> all_comms_ent_inst
reduce(all_comms_rea_inst_list, bind_rows) -> all_comms_rea_inst
reduce(all_comms_pri_inst_list, bind_rows) -> all_comms_pri_inst
reduce(all_comms_hou_inst_list, bind_rows) -> all_comms_hou_inst
write_csv(all_comms_fin_inst, "fin_inst.csv")
write_csv(all_comms_ins_inst, "ins_inst.csv")
write_csv(all_comms_ent_inst, "enterprise.csv")
write_csv(all_comms_rea_inst, "realestate.csv")
write_csv(all_comms_pri_inst, "realestateprice.csv")
write_csv(all_comms_hou_inst, "realestatehh.csv")







# Random Communities within cities
sp <- 10
ctrl_per <- rep(sp, nrow(old_gov))
distance_l <- list(1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000)
# distance_l <- list(1000, 1500, 2000, 2500, 3000)
comms <- list()
govs <- list()
for (i in 1:length(distance_l)) {
  dist <- distance_l[[i]]
  print(dist)
  
  new_comms <- new_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>% 
    mutate(ctrl_dis = c(dist))
  
  old_comms <- old_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>%
    mutate(ctrl_dis = c(dist))
  
  ctrl_govs <- reloc_cities %>% 
    st_sample(ctrl_per) %>%
    st_cast("POINT") %>%
    st_as_sf() %>%
    st_transform(crs = 4326) %>%
    rename(geometry = x) %>% 
    mutate(cityindex = ceiling(row_number()/sp)) %>% 
    full_join(st_drop_geometry(reloc_cities), by = "cityindex" ) %>% 
    mutate(ctrl_dis = c(dist),
           cityindex = as.integer(cityindex),
           label = c('control')
    )
  ctrl_govs_valid <- remove_invalid(ctrl_govs)
  ctrl_comms <- ctrl_govs %>% 
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    # st_cast("LINESTRING") %>%
    st_transform(crs = 4326)
  ctrl_comms_valid <- remove_invalid(ctrl_comms)
  coms <- list(ctrl_comms_valid, new_comms, old_comms) #
  gos <- list(ctrl_govs_valid, new_gov, old_gov) #
  comms[[i]] <- data.table::rbindlist(coms, fill=TRUE) %>% 
    arrange(cityindex)
  govs[[i]] <- data.table::rbindlist(gos, fill=TRUE) %>% 
    arrange(cityindex)
}
all_comms <- data.table::rbindlist(comms, fill=TRUE)
all_govs <- data.table::rbindlist(govs, fill=TRUE)
st_write(all_comms, "../1.Input/comms2.geojson", delete_dsn = TRUE)


# Random Communities on the line
sp <- 10
ctrl_per <- rep(sp, nrow(old_gov))
distance_l <- list(1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000)
# distance_l <- list(1000)
comms <- list()
govs <- list()
for (i in 1:length(distance_l)) {
  dist <- distance_l[[i]]
  print(dist)
  
  new_comms <- new_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>% 
    mutate(ctrl_dis = c(dist))
  
  old_comms <- old_gov %>%
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    st_transform(crs = 4326) %>%
    mutate(ctrl_dis = c(dist))
  
  ctrl_govs <- as.data.frame(st_sfc(mapply(function(a,b){st_cast(st_union(a,b),"LINESTRING")}, old_gov$geometry, new_gov$geometry, SIMPLIFY=FALSE))) %>% 
    st_as_sf(crs = 4326) %>%  
    st_transform(crs = 3415) %>%
    st_cast("LINESTRING") %>% 
    st_sample(ctrl_per) %>%
    st_cast("POINT") %>%
    st_as_sf() %>%
    st_transform(crs = 4326) %>%
    rename(geometry = x) %>% 
    mutate(cityindex = ceiling(row_number()/sp)) %>% 
    full_join(st_drop_geometry(reloc_cities), by = "cityindex" ) %>% 
    mutate(ctrl_dis = c(dist),
           cityindex = as.integer(cityindex),
           label = c('control')
    )
  ctrl_govs_valid <- remove_invalid(ctrl_govs)
  ctrl_comms <- ctrl_govs %>% 
    st_transform(crs = 3415) %>%
    st_buffer(dist = dist) %>%
    # st_cast("LINESTRING") %>%
    st_transform(crs = 4326)
  ctrl_comms_valid <- remove_invalid(ctrl_comms)
  coms <- list(ctrl_comms_valid, new_comms, old_comms) #
  gos <- list(ctrl_govs_valid, new_gov, old_gov) #
  comms[[i]] <- data.table::rbindlist(coms, fill=TRUE) %>% 
    arrange(cityindex)
  govs[[i]] <- data.table::rbindlist(gos, fill=TRUE) %>% 
    arrange(cityindex)
}
all_comms <- data.table::rbindlist(comms, fill=TRUE)
all_govs <- data.table::rbindlist(govs, fill=TRUE)

st_write(all_comms, "../1.Input/comms3.geojson", delete_dsn = TRUE)
