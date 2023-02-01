function(input, output, session) {
  
  # showModal(modalDialog(
  #   title = "REDIRECTING"
  # ))
  
  # # ONLY TURN THIS ON WHEN REDIRECTING (e.g. ON GLOBALARCHIVE ACCOUNT)
  # session$sendCustomMessage("mymessage", "mymessage")
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query[['park']])) {
      
      print(query[['park']])
      
      updateSelectInput(session,
                        "park",

                        choices = c("Geographe Marine Park" = "Geographe Bay", # first part is bit user sees
                                    "Ningaloo Marine Park" = "Ningaloo",
                                    "South-west Corner Marine Park" = "South-west Corner",
                                    "Abrolhos Marine Park" = "Abrolhos",
                                    "Montebello Islands Marine Park" = 'Montebello'),

                        selected = query[['park']])
    }
  })
  

  
# Filter data to selected marine park (should make plotting faster) ----
  map.dat <- reactive({
    req(input$park)

    dat %>%
      dplyr::filter(marine.park %in% input$park) %>%
      glimpse()
    
  })

# Create leaflet explore map ----
  output$imagery.leaflet <- renderLeaflet({

    map.dat <- map.dat() # call in filtered data

    boss.habitat.highlights.popups <- filter(map.dat, source %in% c("boss.habitat.highlights"))
    bruv.habitat.highlights.popups <- filter(map.dat, source %in% c("bruv.habitat.highlights"))
    fish.highlights.popups <- filter(map.dat, source %in% c("fish.highlights"))
    threed.model.popups <- filter(map.dat, source %in% c("3d.model"))
    image.popups <- filter(map.dat, source %in% c('image'))

    # Having this in the global.R script breaks now - make icons on server side
    icon.bruv.habitat <- iconList(blue = makeIcon("images/marker_green.png", iconWidth = 40, iconHeight =40))
    icon.boss.habitat <- iconList(blue = makeIcon("images/marker_pink.png", iconWidth = 40, iconHeight =40))
    icon.fish <- iconList(blue = makeIcon("images/marker_yellow.png", iconWidth = 40, iconHeight =40))
    icon.models <- iconList(blue = makeIcon("images/marker_purple.png", iconWidth = 40, iconHeight =40))

    lng1 <- min(map.dat$longitude)
    lat1 <- min(map.dat$latitude)
    lng2 <- max(map.dat$longitude)
    lat2 <- max(map.dat$latitude)

    leaflet <- leaflet() %>%
      addProviderTiles('Esri.WorldImagery', group = "World Imagery") %>%
      addTiles(group = "Open Street Map")%>%
      addControl(html = html_legend, position = "bottomleft") %>%
      # flyToBounds(lng1, lat1, lng2, lat2)%>%
      fitBounds(lng1, lat1, lng2, lat2)%>%

      # stereo-BRUV habitat videos
      addMarkers(data=bruv.habitat.highlights.popups,
                        icon = icon.bruv.habitat,
                        popup = bruv.habitat.highlights.popups$popup,
                        #label = bruv.habitat.highlights.popups$sample,
                        clusterOptions = markerClusterOptions(iconCreateFunction =
                                                                JS("
                                          function(cluster) {
                                             return new L.DivIcon({
                                               html: '<div style=\"background-color:rgba(124, 248, 193, 0.9)\"><span>' + cluster.getChildCount() + '</div><span>',
                                               className: 'marker-cluster'
                                             });
                                           }")),
                        group="BRUV Habitat imagery",
                        popupOptions=c(closeButton = TRUE,minWidth = 0,maxWidth = 700))%>%

      # BOSS habitat videos
      addMarkers(data=boss.habitat.highlights.popups,
                 icon = icon.boss.habitat,
                 popup = boss.habitat.highlights.popups$popup,
                 #label = boss.habitat.highlights.popups$sample,
                 clusterOptions = markerClusterOptions(iconCreateFunction =
                                                         JS("
                                          function(cluster) {
                                             return new L.DivIcon({
                                               html: '<div style=\"background-color:rgba(248, 124, 179, 0.9)\"><span>' + cluster.getChildCount() + '</div><span>',
                                               className: 'marker-cluster'
                                             });
                                           }")),
                 group="BOSS Habitat imagery",
                 popupOptions=c(closeButton = TRUE,minWidth = 0,maxWidth = 700))%>%

      # stereo-BRUV fish videos
      addMarkers(data=fish.highlights.popups,
                        icon = icon.fish,
                        popup = fish.highlights.popups$popup,
                        clusterOptions = markerClusterOptions(iconCreateFunction =
                                                                JS("
                                          function(cluster) {
                                             return new L.DivIcon({
                                               html: '<div style=\"background-color:rgba(241, 248, 124,0.9)\"><span>' + cluster.getChildCount() + '</div><span>',
                                               className: 'marker-cluster'
                                             });
                                           }")),
                        group="Fish highlights",
                        popupOptions=c(closeButton = TRUE,minWidth = 0,maxWidth = 700))%>%

      # 3D models
      addMarkers(data=threed.model.popups,
                        icon = icon.models,
                        popup = threed.model.popups$popup,
                        clusterOptions = markerClusterOptions(iconCreateFunction =
                                                                JS("
                                          function(cluster) {
                                             return new L.DivIcon({
                                               html: '<div style=\"background-color:rgba(131, 124, 248,0.9)\"><span>' + cluster.getChildCount() + '</div><span>',
                                               className: 'marker-cluster'
                                             });
                                           }")),
                        group="3D models",
                        popupOptions=c(closeButton = TRUE, minWidth = 0,maxWidth = 700)
                        )%>%


      # Ngari Capes Marine Parks
      addPolygons(data = ngari.mp, weight = 1, color = "black",
                  fillOpacity = 0.8, fillColor = "#7bbc63",
                  group = "State Marine Parks", label=ngari.mp$Name)%>%

      # State Marine Parks
      addPolygons(data = state.mp, weight = 1, color = "black",
                  fillOpacity = 0.8, fillColor = ~state.pal(zone),
                  group = "State Marine Parks", label=state.mp$COMMENTS)%>%

      # Add a legend
      addLegend(pal = state.pal, values = state.mp$zone, opacity = 1,
                title="State Zones",
                position = "bottomright", group = "State Marine Parks")%>%

      # Commonwealth Marine Parks
      addPolygons(data = commonwealth.mp, weight = 1, color = "black",
                  fillOpacity = 0.8, fillColor = ~commonwealth.pal(zone),
                  group = "Australian Marine Parks", label=commonwealth.mp$ZoneName)%>%

      # Add a legend
      addLegend(pal = commonwealth.pal, values = commonwealth.mp$zone, opacity = 1,
                title="Australian Marine Park Zones",
                position = "bottomright", group = "Australian Marine Parks")%>%

      addLayersControl(
        baseGroups = c("World Imagery","Open Street Map"),
        overlayGroups = c("Fish highlights",
                          "BRUV Habitat imagery","BOSS Habitat imagery",
                          "3D models",
                          "State Marine Parks",
                          "Australian Marine Parks"), options = layersControlOptions(collapsed = FALSE))%>%
      hideGroup("State Marine Parks")%>%
      hideGroup("Australian Marine Parks")

    return(leaflet)

  })

  # logos
  output$logos <- renderImage({
      return(list(
        src = "images/logos-stacked.png",
        width = "100%", #400
        height = 600,
        contentType = "image/png",
        alt = "Face"
      ))

  }, deleteFile = FALSE)

  
}
