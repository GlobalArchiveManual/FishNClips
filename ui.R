tagList(
  useShinyjs(),
  dashboardPage(
    # dbHeader,
    dashboardHeader(title = "Fish & Clips",
                    tags$li(a(href = 'https://marineecology.io/',
                              img(src = 'https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/MEG-white.png?raw=true',
                                  title = "Marine Ecology Group", height = "50px"),
                              style = "padding-top:10px; padding-bottom:10px;"),
                            class = "dropdown"),
                    tags$li(a(href = 'https://www.nespmarine.edu.au/',
                              img(src = 'https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/mbh-logo-white-cropped.png?raw=true',
                                  title = "Marine Biodiversity Hub", height = "50px"),
                              style = "padding-top:10px; padding-bottom:10px;"),
                            class = "dropdown")),
    # dashboardHeader(title = "habitatMAPPer"),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Interactive imagery", tabName = "imagery", icon = icon("map")),
        menuItem("Acknowledgements", tabName = "acknowledgements", icon = icon("hands-helping", lib="font-awesome"))
      )
    ),
    dashboardBody(
      tags$head(tags$link(rel = "shortcut icon", href = "favicon.ico")),
      tags$head(tags$style('.selectize-dropdown {z-index: 10000}')),
      tabItems(
        # Upload data ----
        tabItem(tabName = "imagery",
                #tags$head(
                #  includeCSS("styles.css") # Include custom CSS
                #),
                fluidRow(box(width = 12, title = "Select an area to explore", status = "primary", solidHeader = TRUE, 
                             add_busy_spinner(spin = "fading-circle"),
                             
                             selectInput("leaflet.marine.park", "", c("Geographe Marine Park" = "Geographe Bay", # first part is bit user sees
                                                                     "Ningaloo Marine Park" = "Ningaloo",
                                                                     "South-west Corner Marine Park" = "South-west Corner",
                                                                     "Abrolhos Marine Park" = "Abrolhos",
                                                                     "Montebello Islands Marine Park" = 'Montebello'))),
                         
                         # box(width = 3, title = "Map display options", status = "primary", solidHeader = TRUE,
                             # checkboxInput("leaflet.cluster", "Cluster fish highlights", TRUE)), # ,checkboxInput("leaflet.zoom", "Animated zoom", TRUE)
                         
                         box(width = 12, leafletOutput("imagery.leaflet", height = 625))
                )
                ), # End tab item
        
        
        tabItem(tabName = "acknowledgements",
                fluidRow(box(width = 4, status = "primary", height = 800,
                             "     ",HTML('<center><img src="logos-stacked.png" width="100%"></center>')
                
                ),
                box(width = 8, status = "primary", height = 800, title = "Acknowledgements",
                    "The Marine Biodiversity Hub is funded by the Australian Government's National Environmental Science Program.", br(), br(),
                    "Ningaloo Marine Park video footage from the benchmark survey of deepwater fish in the Ningaloo Marine Park, Commonwealth waters. Funded by the Marine Biodiversity Hub, Parks Australia, the CSIRO and the University of Western Australia.", br(),br(),
                    "Geographe Bay Marine Park video footage from the benchmark survey funded by the National Environmental Research Programme, the University of Western Australia and Curtin University.",br(),br(),
                    "South-west Corner video footage is from the benchmark survey funded by by Parks Australia, the University of Western Australia and the Australian Government's National Environmental Science Program's Marine Biodiversity Hub. ",br(),br(),
                    "These surveys are contributing to our understanding of deeper water fishes and habitats, helping Parks Australia manage Australia's marine environment.",br(),br(),
                    "Icons made by", a("Smashicons", href = "www.flaticon.com/authors/smashicons"), "from", a("Flaticon", href = "www.flaticon.com"))
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

