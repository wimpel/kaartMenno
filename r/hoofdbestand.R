# initialisatie
analyseperiode <- "2024-03"  # formaat jjjj-mm
# locatie van de alarmlijsten van de dvm proxy
locatie_txt_bestanden <- "I:/brondata/mtm-alarm/dvm-proxy" 
# locatie van de naar omgezette alarmlijsten van de dvm proxy
localie_excel_bestanden <- "I:/brondata/mtm-alarm/dvm-proxy/rds/" 

# stap 0: laad de benodigde libraries
library(data.table)
library(openxlsx)
# stap 1: zet de txt bestanden om naar excel-bestanden (nodig wegens legacy)
source("./r/stap01_converteer_alarmlijsten_naar_excel.R")
# stap 2: lees de omgezette excel bestanden in naar een lijst met storingen
source("./r/stap01_converteer_alarmlijsten_naar_excel.R")
