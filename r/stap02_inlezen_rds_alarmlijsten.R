# lijst met bestanden die ingelezen dienen te worden
in.te.lezen.bestanden <- list.files( path = locatie_rds_bestanden,
                                  pattern = ".*\\.rds$",
                                  full.names = TRUE,
                                  recursive = TRUE)
# lookup tabel voor vertalen nama verkeerscentrale naar regio
lookup <- data.table(vc_oud = c("mn", "non", "nwn", "zn", "zwn"),
                     vc_nieuw = c("UT", "ON", "NWN", "ZN", "ZH"))
# inlezen en bewerken bestanden
L <- lapply(in.te.lezen.bestanden, readRDS)
names(L) <- basename(in.te.lezen.bestanden)
# voeg data samen
DT <- data.table::rbindlist(L, id = "bestandsnaam")
# datum en vc 
DT[, datum := as.Date(gsub("(^....-..-..).*", "\\1", bestandsnaam), format = "%Y-%m-%d")]
DT[, vc := gsub(".*-([a-z]+)\\.rds$", "\\1", bestandsnaam)]
DT[lookup, vc := i.vc_nieuw, on = .(vc = vc_oud)]
#onnodige zaken weer wissen
DT[, `:=`(bestandsnaam = NULL, tijdstip = NULL, x1 = NULL, x2 = NULL)]
# rijbaan
DT[!is.na(dvk), rijbaan2 := dvk]
DT[rijbaan == "R", rijbaan2 := "Re"]
DT[rijbaan == "L", rijbaan2 := "Li"]
DT[, rijbaan := rijbaan2]
DT[, rijbaan2 := NULL]
# geen rijbaan, dan wegfilteren
DT <- DT[!is.na(rijbaan), ]
# hectometer numeriek maken
DT[, hectometer := as.numeric(gsub( ",", ".", hm, fixed = TRUE))]
# allesn van voor 2018 wegmikken
DT <- DT[datum >= as.Date("2018-01-01"), ]
# opruimen
DT[, `:=`(dvk = NULL, hm = NULL)]
# wegschrijven
saveRDS(DT, paste0( "./data/", min(DT$datum), "_tm_", max(DT$datum), "-mtm-alarmlijst.rds" ) )
#opruimen
rm(lookup, DT, L, in.te.lezen.bestanden)