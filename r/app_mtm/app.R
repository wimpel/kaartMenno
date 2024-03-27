library( data.table )
library( leaflet )
library( leaflet.extras )
library( sf )
library( DT )

storingen <- readRDS( "./data/2018-01-01_tm_2024-02-29-storingen.rds" )
districten <- readRDS( "./data/districten_rws.rds" )

opmaak_tabel <- data.table( ernst_storing = c( 4:1 ),
                            type_storing = c("lang_kruis", "kort_kruis", "lang", "kort"),
                            radius = c(5,3,5,3),
                            weight = c(2,2,2,2),
                            opacity = c(1,1,1,1),
                            color = c("lime", "red", "lime", "blue"),
                            fillOpacity = c(1,1,1,1),
                            fillColor = c("red", "red", "blue", "blue"),
                            stringsAsFactors = FALSE )


# user Interface #####
ui <- ( fluidPage(
  
  titlePanel("Locaties MTM beelden niet conform spec."),
  
  sidebarLayout(
    
    sidebarPanel(
      h2( "Maak een selectie" ),
      h4( "laatste update: 01-03-2024" ),
      h4( "volgende update: 01-04-2024" ),
      
      # __user input -----
      dateInput( 'dateInput',
                 label     = "Datum", 
                 value     = max( storingen$tot ),
                 min       = min( storingen$van ),
                 max       = max( storingen$tot ),
                 format    = "dd-mm-yyyy",
                 startview = "month",
                 weekstart = 1,
                 language  = "nl",
                 autoclose = TRUE ),
      
      selectInput( inputId  = "regioInput", 
                   label    = "Selecteer regio", 
                   choices  = c( "Alle regio's", sort( unique( storingen$RD ) ) ),
                   selected = "Alle regio's",
                   multiple = FALSE ),
      
      conditionalPanel("input.regioInput != 'Alle regio\\'s'",
                       uiOutput("secondSelection") ),
      
      #download de data uit het tabblad "Tabel"
      downloadButton('downloadData', 'Download csv data')
      
    ),
    
    # __mainPanel -----
    mainPanel(
      tabsetPanel(
        tabPanel( "Kaart", leafletOutput( "leafletMap", height = "700px" ) ), 
        tabPanel( "Tabel", dataTableOutput( "dataTabel" ) )
      )
    )
  )
))

# #fake input
# dateInput <- as.Date("31-01-2019", format = "%d-%m-%Y")
# regioInput <- "Alle regio's"

server <- ( function( input, output, session ) {
  
  output$secondSelection <- renderUI({
    selectInput( inputId  = "districtInput", 
                 label    = "Selecteer district:", 
                 choices  = c( "Alle districten", sort( unique( storingen$District[which(storingen$RD == input$regioInput)] ) ) ),
                 selected = "Alle districten",
                 multiple = FALSE )
  })
  
  #filter weer te geven districten
  filteredDistricten <- reactive({
    #alle regio's
    if (input$regioInput == "Alle regio's" ) {
      districten
      #alle districten
    } else if (input$districtInput == "Alle districten" ) {
      districten[ grepl( paste0( "^", sub( "RWS ", "", input$regioInput )), districten$DISTRICTCO, perl = TRUE ), ]
    } else {
      districten[ districten$DISTRICTCO == input$districtInput, ]
    }
  })
  
  mtmdata <- reactive ({
    if ( input$regioInput == "Alle regio's" ) {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput, ]
    } else if (input$districtInput == "Alle districten" ) {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput & RD %in% input$regioInput, ]
    } else {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput & District %in% input$districtInput, ]
    }
    temp[, storingsduur_peildatum := input$dateInput - van + 1 ]
    temp[ os_id %in% temp[ storingsduur_peildatum > 30, os_id ] , dertig_dagen := "ja" ]
    temp[ is.na( dertig_dagen ), dertig_dagen := "nee" ]
    temp[ dertig_dagen == "ja" & kruislampfout == "nee", type_storing := "lang"]
    temp[ dertig_dagen == "nee" & kruislampfout == "nee", type_storing := "kort"]
    temp[ dertig_dagen == "ja" & kruislampfout == "ja", type_storing := "lang_kruis"]
    temp[ dertig_dagen == "nee" & kruislampfout == "ja", type_storing := "kort_kruis"]
    #verzamel alle tekst per OS
    #eerst de tekst per melding vastleggen
    temp[, labeltekst := paste0( melding, " - ", storingsduur_peildatum, " dag(en)" )]
    #daarna alle meldingen per od_id samenvoegen, gescheiden door <br>
    temp[, labeltekst := paste0( labeltekst, collapse = "<br>"), by = os_id ]
    #join
    temp[opmaak_tabel, (names(opmaak_tabel)) := list( i.ernst_storing,i.type_storing,i.radius,i.weight,i.opacity,i.color,i.fillOpacity,i.fillColor), on = "type_storing"]
    #neem per OS de rij met het meest ernstige storing
    temp <- temp[ temp[, .I[ which.max( ernst_storing ) ], by = os_id ]$V1]
    #opmaken uiteindelijke label-tekst
    temp[, labeltekst := paste0( "<p><b>", os_id, "</b></p><p>", labeltekst, "</p>" )]
    return( temp )
  })
  
  ### 2019-04-23 ###
  mtmdata.tabel <- reactive ({
    if ( input$regioInput == "Alle regio's" ) {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput, ]
    } else if (input$districtInput == "Alle districten" ) {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput & RD %in% input$regioInput, ]
    } else {
      temp <- storingen[ van <= input$dateInput & tot >= input$dateInput & District %in% input$districtInput, ]
    }
    temp[, storingsduur_peildatum := input$dateInput - van + 1 ]
    temp[ os_id %in% temp[ storingsduur_peildatum > 30, os_id ] , dertig_dagen := "ja" ]
    temp[ is.na( dertig_dagen ), dertig_dagen := "nee" ]
    temp[ dertig_dagen == "ja" & kruislampfout == "nee", type_storing := "lang"]
    temp[ dertig_dagen == "nee" & kruislampfout == "nee", type_storing := "kort"]
    temp[ dertig_dagen == "ja" & kruislampfout == "ja", type_storing := "lang_kruis"]
    temp[ dertig_dagen == "nee" & kruislampfout == "ja", type_storing := "kort_kruis"]
    return( temp )
  })
  ### /2019-04-23 ###
  
  addLegendCustom <- function(group, map, colors, labels, sizes, borderWidth, borderColors, opacity = 1, position = "topright" ){
    colorAdditions <- paste0(colors, "; width:", sizes, "px; height:", sizes, "px; border: ", borderWidth, "px solid ", borderColors)
    labelAdditions <- paste0("<div style='display: inline-block;height: ", sizes, "px;margin-top: 4px;line-height: ", sizes, "px;'>", labels, "</div>")
    return(addLegend(map, colors = colorAdditions, labels = labelAdditions, opacity = opacity, position = position, group = group)) 
  }
  
  #output$leafletMap-----
  #maak een leaflet aan, maar voeg nog geen layers toe
  output$leafletMap <- renderLeaflet({
    leaflet() %>% 
      addTiles( group = "OSM (default)") %>% 
      # addWMSTiles( "https://geodata.nationaalgeoregister.nl/luchtfoto/rgb/wms?",
      #              layers = "Actueel_ortho25",
      #              options=WMSTileOptions(format="image/jpeg",
      #                                     transparent=TRUE ) ,
      #              group = "PDOK luchtfoto"
      addWMSTiles( "https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0?",
                   layers = "Actueel_ortho25",
                   options=WMSTileOptions(format="image/jpeg",
                                          transparent=TRUE ) ,
                   group = "PDOK luchtfoto"
      ) %>%
      #setView( 4.213, 51.876, zoom = 7 ) %>% #statische view op basis van heel NL
      #pas viewprt aan op basis van st_bbox
      fitBounds(st_bbox(filteredDistricten())[[1]], st_bbox(filteredDistricten())[[2]], 
                st_bbox(filteredDistricten())[[3]], st_bbox(filteredDistricten())[[4]]) %>%
      addScaleBar( position = "bottomleft" )
  })
  
  observe({
    leafletProxy("leafletMap" ) %>%
      clearMarkers() %>%
      clearShapes() %>%
      addPolygons( data = filteredDistricten(),
                   group = "RWS district",
                   color = "black",
                   weight = 2,
                   fillColor = ~color,
                   opacity = 0.5,
                   popup = ~DISTRICTCO,
                   highlightOptions = highlightOptions( color = "yellow",
                                                        weight = 5,
                                                        bringToFront = FALSE ) ) %>%
      addCircleMarkers( data = mtmdata(),
                        group = "MTM storingen",
                        lat = ~latitude,
                        lng = ~longutide,
                        radius = ~radius,
                        weight = ~weight,
                        opacity = ~opacity,
                        color = ~color,
                        fillOpacity = ~fillOpacity,
                        fillColor = ~fillColor,
                        popup = ~labeltekst ) %>%
      #opnieuw opbouwen legenda
      clearControls() %>%
      addLayersControl( 
        baseGroups = c( "OSM (default)", "PDOK luchtfoto" ),
        overlayGroups = c( "MTM storingen" ), 
        options = layersControlOptions( collapsed = FALSE ) ) %>%
      addLegendCustom(group = "MTM storingen", 
                      colors = c("blue", "blue", "red", "red"), 
                      labels = c("storing", "storing >30", "kruis-storing", " kruis-storing >30"), 
                      sizes = c(10, 10, 10, 10),
                      borderColors = c("white", "lime", "white", "lime" ),
                      borderWidth = c(2, 2, 2, 2 ) 
                      )
    })
  
  #tabel met waarnemingen weergeven
  tabelData <- reactive({
    req( mtmdata.tabel() )
    cols <- c( "RD", "District", "vc", "os_id", "melding", "aantal_dagen", "van", "tot", "storingsduur_peildatum", "kruislampfout" )
    mtmdata.tabel()[, ..cols]
  })
  
  output$dataTabel <- DT::renderDataTable( tabelData() )
  
  output$downloadData <- downloadHandler(
    filename = "storingen.csv", 
    content = function(file) {
      write.table( tabelData(), 
                   file, 
                   sep = ";", 
                   na = "", 
                   dec = ",", 
                   row.names = FALSE)
    }
  )
  
})

shinyApp(ui = ui, server = server)