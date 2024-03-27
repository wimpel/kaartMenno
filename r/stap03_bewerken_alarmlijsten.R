library(tidyverse)
library(data.table)
library(lubridate)

#inlezen alarmlijsten
df <- readRDS( "./data/2018-01-01_tm_2024-02-29-mtm-alarmlijst.rds" )
nwb <- readRDS( "./data/nwb201805HmAangevuld.rds") %>% setDT( key = c( "Wegnaam", "rijbaan", "hectometer" ) )

storingsId.v <- c( 1001,1002,1003,1009,1061,1062,2001,3001,4001,4002,4003,4005,
                   4006,4011,4012,4013,4021,5001,5002,6001,6002,6003,6004 )

storingen <- df %>%
  #ID toevoegen
  mutate( os_id = paste0( wegnaam, " " , rijbaan, " ", hectometer) ) %>%
  mutate( id = as.numeric( id ) ) %>%
  #filteren op stiring id
  filter( id %in% storingsId.v ) %>%
  #sorteer op datum
  arrange( datum ) %>%
  #groeperen per os_id en melding
  group_by( vc, id, os_id, melding ) %>%
  #bepaal het datum-verschil met de voorgaande datum,
  #als het datumverschil groter is dan 1, dan is het een nieuwe 'groep' met storingen.
  mutate( diff = c( 0, diff( datum ) ),
          periode = 1 + cumsum( diff > 1 ) ) %>%
  group_by( vc, id, os_id, melding, periode) %>%
  summarise( van = first ( datum),
             tot = last( datum ),
             aantal_dagen = last( datum) - first( datum ) + 1 ) %>%
  #wegkenmerken toevoegen uit os_id
  mutate( wegnaam    = strsplit( os_id, " ")[[1]][[1]], 
          rijbaan    = strsplit( os_id, " ")[[1]][[2]], 
          hectometer = as.numeric( strsplit( os_id, " ")[[1]][[3]] ) ) %>%
  #maak data.table
  setDT( key = c( "wegnaam", "rijbaan", "hectometer" ) )

#left rolling join op wegnummer + rijbaan + hectometer (=rolling to nearest)
storingen.nwb <- nwb[storingen, roll = "nearest", mult = "first", nomatch = 0L]

#betreft het een storing met kruislapmen?
storingen.nwb <- storingen.nwb %>%
  setDF() %>%
  mutate( kruislampfout = case_when(
    id %in% c( 1001:1002 ) & grepl( "X", sub( ".* ", "", melding ) ) ~ "ja",
    id %in% c( 1003, 1009, 2001, 4001:4003, 4005:4006, 5001:5002, 6003 ) ~ "ja",
    id %in% c( 1061:1062, 4011:4013, 6001:6002) & grepl( "X", melding ) ~ "ja",
    TRUE ~ "nee") 
    ) %>%
  setDT()

saveRDS( storingen.nwb, paste0( "./data/", min(df$datum), "_tm_", max(df$datum), "-storingen.rds" ) )
beepr::beep(8)

