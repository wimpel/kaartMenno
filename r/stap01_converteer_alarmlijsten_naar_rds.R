# laad de bestanden voor conversie
regex.pattern <- paste0("^..", gsub("^20(..)-(..)$", "\\2\\1", analyseperiode), ".*\\.txt$")
bestanden <- list.files(path = locatie_txt_bestanden, pattern = regex.pattern, full.names = TRUE, recursive = TRUE )
#bestanden <- list.files(path = locatie_txt_bestanden, pattern = ".*\\.txt$", full.names = TRUE, recursive = TRUE )
#bestanden <- bestanden[ grepl( "201[8-9]|202[0-9]", bestanden)]

for (bestand in bestanden) {
  vc <- gsub( "(^.*dvm-proxy/)([a-z]+)(/.*$)", "\\2", bestand )
  datum <- paste( gsub( "(^.*storinglijst/)([0-9]+)(/.*$)", "\\2", bestand ),
                  gsub( "(^.*20[0-9]+/)([0-9]+)(/.*$)", "\\2", bestand ),
                  gsub( "(^.*20[0-9]+/[0-9]+/)([0-9]+)(/.*$)", "\\2", bestand ),
                  sep = "-" )
  
  test <- suppressWarnings(
    fread( file = bestand,
                 sep ="|",
                 header = FALSE,
                 na.strings = NULL,
                 skip = 1))
  
  test[, `:=`( V1 = NULL, V2 = NULL, V7 = NULL, V4 = gsub( "^\\d+ ", "", V4))]
  setnames(test, old = c("V3", "V4", "V5", "V6"), new = c("id", "melding", "locatie", "tijdstip"))
  test[, `:=`( weg = stringr::str_extract( locatie, "^[AN]\\d+" ),
               dvk = stringr::str_extract( gsub( "^[AN]\\d+", "", locatie ), "^[a-z]" ),
               rijbaan = stringr::str_extract( gsub( "^[AN]\\d+", "", locatie ), "[RL]"),
               hm = stringr::str_extract( locatie, "\\d+,\\d+" ),
               x1 = "xxx",
               x2 = "xxx")] 
  test[, locatie := NULL]
  setcolorder(test, c("id", "melding", "weg", "dvk", "rijbaan", "hm", "tijdstip", "x1", "x2"))
  # opslaan naar rds bestand  
  saveRDS(test, paste0(locatie_rds_bestanden, datum, " sign-", vc, ".rds" ))
}
rm(test, bestanden, bestand, datum, regex.pattern, vc)

