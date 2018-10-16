# Weather data web scraping tool for collecting data from Wunderground.com
# Adam Brooker 16th October 2018



library(RSelenium)
library(seleniumPipes)
library(XML)
library(wdman)


setwd('G:/Data/WeatherData/Data tables/Ballachulish') 



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

nodays <- 5

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
obtime <- data.frame('time' = as.character(unlist(lapply(obtime$time, function(x) paste0(date, ' ', obtime[x,1])))))
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


}

write.csv(wdata, 'CorranWeather_Jun-Nov2016.csv')
