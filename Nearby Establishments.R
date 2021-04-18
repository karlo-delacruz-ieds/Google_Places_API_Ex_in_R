rm(list = ls())
gc()

# load library and setup google places api key
library(ggmap)
library(dplyr)
library(tidyr)

register_google(key = "your_google_api_key") # must work/ google cloud enabled

# collect location data
location_data <- read.csv("location_data_tbl.csv")

location_data <- location_data[,c("location_name", "latitude", "longitude")]


# pause function to prevent being blocked as spam
pause <- function(x){
  p1 <- proc.time()
  Sys.sleep(x)
  proc.time() - p1 # The cpu usage should be negligible
}


# Google Places API execution to get nearby establishments using R
# 2 next page token for free trial version (student) per coordinate
library(googleway)
for (i in 1:nrow(location_data)) {
        # get nearby places first time
        res1 <- google_places(
                    location = c(lat = location_data$latitude[i], lon = location_data$longitude[i]), 
                    radius = 100,
                    key = "your_google_api_key")
        token2 = res1$next_page_token
        pause(3)
        # get nearby places 2nd time, use next page token
        res2 <- google_places(
                    location = c(lat = location_data$latitude[i], lon = location_data$longitude[i]),
                    radius = 100, page_token = token2, 
                    key = "your_google_api_key")
        token3 = res2$next_page_token
        pause(3)
        # get nearby places 3rd time, use next page token
        res3 <- google_places(
                    location = c(lat = location_data$latitude[i], lon = location_data$longitude[i]),
                    radius = 100, page_token = token3, 
                    key = "your_google_api_key")
        pause(3)
        # combine nearby places results
        df1 <- res1$results[c('name','types')]
        df2 <- res2$results[c('name','types')]
        df3 <- res3$results[c('name','types')]
        temp_data <- rbind(df1, df2, df3)
        # add location_data information
        temp_data$location_name <- location_data$location_name[i]
        temp_data$latitude <- location_data$latitude[i]
        temp_data$longitude <- location_data$longitude[i]
        # reorder by column name
        temp_data  <- temp_data[c("location_name", "latitude", "longitude", "name", "types")]
        temp_data <- unnest(temp_data, types)
        # create dataframe using location data  with list of nearby establishments and it type
        if (i == 1){
          full_data <- temp_data
        } else {
          full_data <- rbind(full_data, temp_data)
        }
        rm(res1, res2, res3, token2, token3, df1, df2, df3, temp_data)
}        


write.csv(full_data, "nearby_estab_100mrad.csv", row.names = FALSE)


