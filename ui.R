tagList(
  useShinyjs(),
  dashboardPage(
    dbHeader,
    # dashboardHeader(title = "habitatMAPPer"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Interactive imagery", tabName = "imagery", icon = icon("map")),
        menuItem("Acknowledgements", tabName = "acknowledgements", icon = icon("hands-helping", lib="font-awesome"))
      )
    ),
    dashboardBody(
      tags$head(tags$link(rel = "shortcut icon", href = "favicon.ico")),
      tabItems(
        # Upload data ----
        tabItem(tabName = "imagery",
                #tags$head(
                #  includeCSS("styles.css") # Include custom CSS
                #),
                fluidRow(box(width = 12, title = "Select an area to explore", status = "primary", solidHeader = TRUE, 
                             add_busy_spinner(spin = "fading-circle"),
                             
                             selectInput("leaflet.marine.park", "", c("Geographe Marine Park" = "Geographe Bay",
                                                                     "Ningaloo Marine Park" = "Ningaloo",
                                                                     "South-west Corner Marine Park" = "South-west Corner"))),
                         
                         # box(width = 3, title = "Map display options", status = "primary", solidHeader = TRUE,
                             # checkboxInput("leaflet.cluster", "Cluster fish highlights", TRUE)), # ,checkboxInput("leaflet.zoom", "Animated zoom", TRUE)
                         
                         box(width = 12, leafletOutput("imagery.leaflet", height = 625))
                )
                ), # End tab item
        
        
        tabItem(tabName = "acknowledgements",
                fluidRow(box(width = 8, status = "primary", height = 800, title = "Acknowledgments",
                             "The Marine Biodiversity Hub is funded by the Australian Government's National Environmental Science Program", br(), br(),
                             "Ningaloo video footage from the baseline survey of deepwater fish in the Ningaloo Marine Park, Commonwealth waters. Funded by the Marine Biodiversity Hub and Parks Australia.", br(),br(),
                             "Geographe Bay video footage from the National Envrionmental Research Programme, UWA and Curtin",br(),br(),
                             "South-west corner video footage from the baseline survey of deeperwater fish and habitats in the South-west Corner Marine Park, Commonwealth waters. Funded by the Marine Biodiversity Hub, Parks Australia and the University of Western Australia.
",br(),br(),"Icons made by <a href='https://www.flaticon.com/authors/smashicons' title='Smashicons'>Smashicons</a> from <a href='https://www.flaticon.com/' title='Flaticon'> www.flaticon.com</a>"),
                         box(width = 4, status = "primary", height = 800,
                             imageOutput("logos")
                
                )
                )
        )
        
      )
    )
  ),
  tags$footer("Developed by Brooke Gibbons and Tim Langlois, 2020", align = "center"#, style = "
              # position:absolute;
              # bottom:0;
              # width:100%;
              # height:30px;   /* Height of the footer */
              # color: white;
              # padding: 10px;
              # background-color: black;
              # z-index: 1000;"
              )
  
)#end tagList
# )

