# Weather data web scraping tool for collecting data from Wunderground.com
# Adam Brooker 16th October 2018



library(RSelenium)
library(seleniumPipes)
library(XML)
library(wdman)
library(stringr)
library(tidyverse)


setwd('G:/Data/WeatherData/Data tables/Rahoy') 



# code to start web session

rD <- selenium(port = 4567L) # start local Selenium server

remDr <- remoteDriver(port = 4567L, browser = 'firefox') # link to Selenium server
remDr$open() # open remote controlled web browser
remDr$maxWindowSize(winHand = 'current')

remDr$closeServer # close selenium server


# ballachulish start link
startlink <- 'https://www.wunderground.com/personal-weather-station/dashboard?ID=IHIGHLAN46&cm_ven=localwx_pwsdash#history/tgraphs/s20171016/e20171016/mdaily'

# Corran start link
startlink <- 'https://www.wunderground.com/personal-weather-station/dashboard?ID=IUNITEDK518&cm_ven=localwx_pwsdash#history/s20160601/e20160601/mdaily'

# Rahoy start link
startlink <- 'https://www.wunderground.com/personal-weather-station/dashboard?ID=IHIGHLAN16&cm_ven=localwx_pwsdash#history/tdata/s20180528/e20180528/mdaily'


nodays <- 32

remDr$navigate(startlink) # nagivate to start url
#Sys.sleep(signif(runif(1,2,3), 2))

# MANUALLY ENTER START DATE FOR DATA COLLECTION

# click table view tab
remDr$findElement(using="css selector", value=".active+ .tab-item a")$clickElement()

wdata <- data.frame()

for(i in 1:nodays){

# get date for current table
elems <- remDr$findElements(using="css selector", value=".current-date")
date <- unlist(lapply(elems, function(x){x$getElementText()}))[[1]]

# Scrape data from each column
elems <- remDr$findElements(using="css selector", value=".heading-cell")
obtime <- data.frame('time' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
obtime <- data.frame('time' = as.character(unlist(lapply(obtime$time, function(x) paste0(date, ' ', obtime[x,1]))))) # add date to time
obtime <- as.data.frame(sort(as.POSIXct(strptime(obtime$time, tz = 'UTC', format = '%B %d, %Y %I:%M %p')))) # convert character string to date/time format
colnames(obtime) <- 'time'
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(2)")
temp <- data.frame('temperature' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(3)")
dew <- data.frame('dewpoint' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(4)")
hum <- data.frame('humidity' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(5)")
windDir <- data.frame('wind direction' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(6)")
windSpeed <- data.frame('wind speed' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(7)")
windGust <- data.frame('wind gust' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(8)")
pressure <- data.frame('pressure' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(9)")
precipRate <- data.frame('precip. rate' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(10)")
precipAccum <- data.frame('precip. accum.' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(11)")
uv <- data.frame('uv' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))
elems <- remDr$findElements(using="css selector", value=".data-cell:nth-child(12)")
solar <- data.frame('solar' = as.character(unlist(lapply(elems, function(x){x$getElementText()}))))

# combine each column into data frame
day <- data.frame('time' = obtime, 'temperature' = temp, 'dewpoint' = dew, 'humidity' = hum, 'wind direction' = windDir, 
                    'wind speed' = windSpeed, 'wind gust' = windGust, 'pressure' = pressure, 'precip. rate' = precipRate,
                    'precip accum' = precipAccum, 'uv' = uv, 'solar' = solar)

wdata <- rbind(wdata, day)

remDr$findElement(using="css selector", value="#next-timeframe")$clickElement()
Sys.sleep(signif(runif(1,5,7), 2))

} # end of weather scraping loop


colnames(wdata) <- c('time', 'temp_C', 'dewpoint_C', 'humidity_percent', 'windDir_deg', 'windSpeed_kph', 'windGust_kph', 
                     'pressure_hPa', 'precipRate_mm', 'precipAccum_mm', 'uvIndex', 'solarIrradiance_wperm2')

wdata <- as.tibble(wdata)

# remove units and convert character strings to numeric
wdata$temp_C <- as.numeric(str_sub(wdata$temp_C, 1, str_length(wdata$temp_C)-3))
wdata$dewpoint_C <- as.numeric(str_sub(wdata$dewpoint_C, 1, str_length(wdata$dewpoint_C)-3))
wdata$humidity_percent <- as.numeric(str_sub(wdata$humidity_percent, 1, str_length(wdata$humidity_percent)-2))
wdata$windDir_deg <- ifelse(as.character(wdata$windDir_deg == 'North'), 0,
                        ifelse(as.character(wdata$windDir_deg == 'NNE'), 22.5, 
                          ifelse(as.character(wdata$windDir_deg == 'NE'), 45, 
                              ifelse(as.character(wdata$windDir_deg == 'ENE'), 67.5, 
                                  ifelse(as.character(wdata$windDir_deg == 'East'), 90,
                                      ifelse(as.character(wdata$windDir_deg == 'ESE'), 112.5,
                                          ifelse(as.character(wdata$windDir_deg == 'SE'), 135,
                                              ifelse(as.character(wdata$windDir_deg == 'SSE'), 157.5,
                                                  ifelse(as.character(wdata$windDir_deg == 'South'), 180,
                                                     ifelse(as.character(wdata$windDir_deg == 'SSW'), 202.5,
                                                        ifelse(as.character(wdata$windDir_deg == 'SW'), 225,
                                                           ifelse(as.character(wdata$windDir_deg == 'WSW'), 247.5,
                                                               ifelse(as.character(wdata$windDir_deg == 'West'), 270,
                                                                  ifelse(as.character(wdata$windDir_deg == 'WNW'), 292.5,
                                                                     ifelse(as.character(wdata$windDir_deg == 'NW'), 315, 337.5)))))))))))))))
wdata$windSpeed_kph <- as.numeric(str_sub(wdata$windSpeed_kph, 1, str_length(wdata$windSpeed_kph)-4))
wdata$windGust_kph <- as.numeric(str_sub(wdata$windGust_kph, 1, str_length(wdata$windGust_kph)-4))
wdata$pressure_hPa <- as.numeric(str_sub(wdata$pressure_hPa, 1, str_length(wdata$pressure_hPa)-4))
wdata$precipRate_mm <- as.numeric(str_sub(wdata$precipRate_mm, 1, str_length(wdata$precipRate_mm)-3))
wdata$precipAccum_mm <- as.numeric(str_sub(wdata$precipAccum_mm, 1, str_length(wdata$precipAccum_mm)-3))
wdata$uvIndex <- as.numeric(wdata$uvIndex)
wdata$solarIrradiance_wperm2 <- as.numeric(str_sub(wdata$solarIrradiance_wperm2, 1, str_length(wdata$solarIrradiance_wperm2)-5))

write.csv(wdata, 'Rahoy_56_636N_5_841W_Weather_Jun-Aug2018.csv')

rm(day, dew, hum, obtime, precipAccum, precipRate, pressure, solar, temp, uv, windDir, windGust, windSpeed, date, elems)





