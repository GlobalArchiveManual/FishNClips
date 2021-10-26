# Load libraries ----
# install.packages("shinybusy")
# profvis(runApp())
library(dplyr)
library(DT)
library(forcats)
library(fst)
library(ggplot2)
library(devtools)
# install_github("UWAMEGFisheries/GlobalArchive") #to check for updates
library(GlobalArchive)
library(grid)
library(htmlwidgets)
library(leaflet)
library(leaflet.minicharts)
library(leafpop)
library(mapview)
library(profvis)
library(raster)
library(readr)
library(rgdal)
library(rgeos)
library(rmapshaper)
library(shiny)
library(shinyBS)
library(shinybusy)
library(shinydashboard)
# library(shinydashboardPlus)
library(shinythemes)
library(shinyjs)
library(sf)
library(stringr)
library(tidyr)

# Colours
#7CF8C1 = green (124, 248, 193)
#837CF8 = purple (131, 124, 248)
#F87CB3 = pink (248, 124, 179)
#F1F87C = yellow (241, 248, 124)

# Bring in data ----
# Load 2019 ningaloo metadata ----
ning.bruv.metadata <- read.csv("data/2019-08_Ningaloo_metadata.csv") %>%
  mutate(sample = as.character(sample))

# Load 2014 geographe bay metadata ----
gb.bruv.metadata <- read.csv("data/2014-12_Geographe.Bay_stereoBRUVs_Metadata.csv")

# Load 2020 south west metadata ----
sw.bruv.metadata <- read.csv("data/2020_south-west_stereo-BRUVs.checked.metadata.csv")%>%
  filter(successful.count%in%c("Yes"))

# Load 2021 abrolhos boss metadata ----
abro.boss.metadata <- read.csv("data/2021-05_Abrolhos_BOSS.csv") %>%
  ga.clean.names()%>%
  mutate(sample = as.character(sample))

# Load 2021 abrolhos bruv metadata ----
abro.bruv.metadata <- read.csv("data/2021-05_Abrolhos_stereo-BRUVs.csv") %>%
  ga.clean.names()%>%
  mutate(sample = as.character(sample))%>%
  filter(!is.na(longitude))


gb.bruv.video <- gb.bruv.metadata %>%
  ga.clean.names() %>%
  # dplyr::mutate(sample=as.numeric(sample))%>% # for testing only
  # dplyr::filter(sample<61)%>% # for testing only
  dplyr::mutate(sample=as.character(sample))%>% 
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup=paste0('<video width="645" autoplay controls>
  <source src="https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/',sample,'.mp4?raw=true" type="video/mp4">
</video>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>%
  dplyr::mutate(marine.park = "Geographe Bay")

# https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/Compilations/test-video-2.mp4?raw=true # this link works

# Create dataframe for 2019 Ningaloo BRUV images for plotting ----
ning.bruv.image <- ning.bruv.metadata %>%
  dplyr::mutate(image=paste0("https://marineecology.io/images/habitatmapp/ningaloo/",sample,".jpg",sep="")) %>%
  ga.clean.names() %>%
  dplyr::mutate(source = "image") %>%
  mutate(height='"365"')%>%mutate(width='"645"')%>%
  mutate(popup=paste0('<iframe src=',image,' height=',height,' width=',width,'></iframe>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>% # ,bruv.video,auv.video,source
  dplyr::mutate(marine.park = "Ningaloo")

ning.bruv.video <- ning.bruv.metadata %>%
  ga.clean.names() %>%
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup=paste0('<video width="645" autoplay controls>
  <source src="https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/ningaloo/',sample,'.mp4?raw=true" type="video/mp4">
</video>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>% # ,bruv.video,auv.video,source
  dplyr::mutate(marine.park = "Ningaloo")

abro.boss.video <- abro.boss.metadata %>%
  ga.clean.names() %>%
  dplyr::mutate(source = "boss.habitat.highlights") %>%
  dplyr::mutate(popup=paste0('<video width="645" autoplay controls>
  <source src="https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/abrolhos/BOSS/',sample,'.mp4?raw=true" type="video/mp4">
</video>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>% # ,bruv.video,auv.video,source
  dplyr::mutate(marine.park = "Abrolhos")

abro.bruv.video <- abro.bruv.metadata %>%
  ga.clean.names() %>%
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup=paste0('<video width="645" autoplay controls>
  <source src="https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/abrolhos/BRUV/',sample,'.mp4?raw=true" type="video/mp4">
</video>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>% # ,bruv.video,auv.video,source
  dplyr::mutate(marine.park = "Abrolhos")

# 
# # Create dataframe for 2019 Ningaloo BRUV images for plotting ----
sw.bruv.image <- sw.bruv.metadata %>%
  ga.clean.names() %>%
  dplyr::mutate(image=paste0("01",sample,"",sep="")) %>% # NEED TO UPDATE THIS
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup=paste0('<video width="645" autoplay controls>
  <source src="https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/videos/south-west/',sample,'.mp4?raw=true" type="video/mp4">
</video>')) %>%
  dplyr::select(latitude, longitude, popup, source) %>% # ,bruv.video,auv.video,source
  dplyr::mutate(marine.park = "South-west Corner")

# Fish hihglights and 3D model links ----
fish <- read.csv("data/zone-midpoints.csv", na.strings=c("NA","NaN", " ","")) %>%
  dplyr::filter(!is.na(fish)) %>%
  dplyr::mutate(source = "fish.highlights")%>%
  dplyr::mutate(popup = paste("<center><h4>Fish observed in the ",
                              marine.park,
                              " Marine Park, in the ",
                              zone,
                              " Zone.</h4></center>","<br/>",
                              fish, sep = ""))

models <- read.csv("data/3Dmodels.csv", na.strings=c("NA","NaN", " ","")) %>% 
  dplyr::mutate(source = "3d.model")

# Merge data together for leaflet map ----
dat <- bind_rows(models, gb.bruv.video, sw.bruv.image, fish, ning.bruv.video,abro.boss.video, abro.bruv.video) #fish, gb.bruv.image, ning.bruv.image, sw.bruv.image

# Spatial files ----
# State marine parks ----
ngari.mp <- readOGR("data/spatial/test1.shp") 
state.mp <- readOGR("data/spatial/WA_MPA_2018.shp")

# filter out unassigned and unclassified
state.mp <- state.mp[!state.mp$ZONE_TYPE %in% c("Unassigned (IUCN IA)","Unassigned (IUCN II)","Unassigned (IUCN III)","Unassigned (IUCN IV)","Unassigned (IUCN VI)","MMA (Unclassified) (IUCN VI)","MP (Unclassified) (IUCN VI)"), ]

# remove all alphanumeric to rename zone type
state.mp$zone<-str_replace_all(state.mp$ZONE_TYPE, c("[^[:alnum:]]"=" "))
state.mp$zone<-str_replace_all(state.mp$zone, c("Conservation Area  IUCN IA "="Conservation (no-take)",
                                                "General Use  IUCN II "="General Use",
                                                "General Use Area  IUCN VI "="General Use",
                                                "General Use Zone  IUCN II "="General Use",
                                                "Recreation Area  IUCN II "="Recreation",
                                                "Recreation Zone  IUCN II "="Recreation",
                                                "Sanctuary Area  IUCN VI "="Sanctuary (no-take)",
                                                "Sanctuary Zone  IUCN IA "="Sanctuary (no-take)",
                                                "Special Purpose Zone  Aquaculture   IUCN VI " ="Special Purpose",
                                                "Special Purpose Zone  Benthic Protection   IUCN IV "="Special Purpose",
                                                "Special Purpose Zone  Dugong Protection   IUCN IV "="Special Purpose", 
                                                "Special Purpose Zone  Habitat Protection   IUCN IV " ="Special Purpose",
                                                "Special Purpose Zone  Pearling   IUCN VI "  ="Special Purpose",    
                                                "Special Purpose Zone  Puerulus   IUCN IA "  ="Special Purpose", 
                                                "Special Purpose Zone  Scientific Reference   IUCN II "="Special Purpose",
                                                "Special Purpose Zone  Scientific Reference   IUCN VI "="Special Purpose",
                                                "Special Purpose Zone  Seagrass Protection   IUCN IV "="Special Purpose", 
                                                "Special Purpose Zone  Shore Based Activities   IUCN II "="Special Purpose",
                                                "Special Purpose Zone  Wildlife Conservation   IUCN VI "="Special Purpose",
                                                "Special Purpose Zone  Wildlife Viewing and Protection   IUCN IV "="Special Purpose",
                                                "Special Purpose Zone 1  Shore based Activities   IUCN II "="Special Purpose",       
                                                "Special Purpose Zone 2  Shore based Activities   IUCN II "="Special Purpose",       
                                                "Special Purpose Zone 3  Shore based Activities   IUCN II " ="Special Purpose",      
                                                "Special Purpose Zone 3  Shore based Activities   IUCN VI " ="Special Purpose",      
                                                "Special Purpose Zone 4  Shore based Activities   IUCN II "="Special Purpose"))

# unique(state.mp$zone)


# Commonwealth marine parks ----
commonwealth.mp <- readOGR("data/spatial/AustraliaNetworkMarineParks.shp")
commonwealth.mp$zone<-str_replace_all(commonwealth.mp$ZoneName, c("[^[:alnum:]]"=" "))
commonwealth.mp$zone<-str_replace_all(commonwealth.mp$zone, c(" Zone"="",
                                                              "Habitat Protection  Lord Howe " = "Habitat Protection",
                                                              "Habitat Protection  Reefs " = "Habitat Protection",
                                                              "Marine National Park" = "National Park",
                                                              "National Park" = "National Park (no-take)",
                                                              "Special Purpose  Mining Exclusion " = "Special Purpose",
                                                              "Special Purpose  Norfolk " = "Special Purpose",
                                                              "Special Purpose  Trawl " = "Special Purpose",
                                                              "Sanctuary" = "Sanctuary (no-take)"))
unique(commonwealth.mp$zone)


# Create factors for legends and plotting ----
# State marine parks ----
state.mp$zone <- as.factor(state.mp$zone)
state.mp$zone<-fct_relevel(state.mp$zone, "Conservation (no-take)", "Sanctuary (no-take)", "Recreation", "General Use", "Special Purpose")

state.pal <- colorFactor(c("#bfaf02", # conservation
                           "#7bbc63", # sanctuary = National Park
                           "#fdb930", # recreation
                           "#b9e6fb", # general use
                           '#ccc1d6' # special purpose
), state.mp$zone)

# Commonwealth marine parks ----
commonwealth.mp$zone <- as.factor(commonwealth.mp$zone)
commonwealth.mp$zone<-fct_relevel(commonwealth.mp$zone, "Sanctuary (no-take)", "National Park (no-take)", "Recreational Use", "Habitat Protection", "Multiple Use", "Special Purpose")

commonwealth.pal <- colorFactor(c("#f6c1d9", # Sanctuary
                                  "#7bbc63", # National Park
                                  "#fdb930", # Recreational Use
                                  "#fff7a3", # Habitat Protection
                                  '#b9e6fb', # Multiple Use
                                  '#ccc1d6'# Special Purpose
), commonwealth.mp$zone)

# Fish data for plots ----
master<-read_csv("data/fish/australia.life.history_200824.csv")%>%
  ga.clean.names()%>%
  dplyr::select(family,genus,species,australian.common.name)

family.common.names<-read_csv("data/fish/family.common.names.csv")%>%
  ga.clean.names()%>%
  distinct()%>%
  dplyr::mutate(family.common.name=paste("An unknown",australian.family.common.name,sep=" "))%>%
  dplyr::select(family,family.common.name)

lumped.common.names<-read_csv("data/fish/lumped.common.names.csv")%>%
  ga.clean.names()%>%
  distinct()

maxn <- read_csv("data/fish/2014-12_Geographe.Bay_stereoBRUVs.complete.maxn.csv",col_types = cols(.default = "c"))%>%
  dplyr::mutate(maxn=as.numeric(maxn))%>%
  dplyr::select(-c(latitude,longitude,status))%>%
  left_join(master)%>%
  left_join(family.common.names)%>%
  left_join(lumped.common.names)%>%
  dplyr::mutate(common.name=if_else(is.na(australian.common.name),family.common.name,australian.common.name))%>%
  dplyr::mutate(common.name=if_else(!is.na(lumped.common.name),lumped.common.name,common.name))%>%
  dplyr::mutate(scientific=paste(genus," ",species," (",common.name,")",sep=""))

metadata.regions<-read_csv("data/fish/metadata.regions.csv",col_types = cols(.default = "c"))%>%
  mutate(zone=str_replace_all(.$zone,c("Sanctuary"="Sanctuary (no-take)","Fished"="Outside Marine Park")))%>%
  mutate(zone=as.factor(zone))%>%
  mutate(zone=fct_relevel(zone, "Sanctuary (no-take)", "National Park (no-take)","Habitat Protection","Multiple Use","Special Purpose"))%>%
  mutate(status=fct_relevel(status, "No-take", "Fished"))

length <- read_csv("data/fish/2014-12_Geographe.Bay_stereoBRUVs.complete.length.csv",col_types = cols(.default = "c"))%>%
  dplyr::mutate(number=as.numeric(number),length=as.numeric(length))%>%
  dplyr::select(-c(latitude,longitude,status))%>%
  left_join(master)%>%
  left_join(family.common.names)%>%
  left_join(lumped.common.names)%>%
  dplyr::mutate(common.name=if_else(is.na(australian.common.name),family.common.name,australian.common.name))%>%
  dplyr::mutate(common.name=if_else(!is.na(lumped.common.name),lumped.common.name,common.name))%>%
  dplyr::mutate(scientific=paste(genus," ",species," (",common.name,")",sep=""))

mass <- read_csv("data/fish/2014-12_Geographe.Bay_stereoBRUVs.complete.mass.csv",col_types = cols(.default = "c"))%>%
  dplyr::mutate(number=as.numeric(number),mass.g=as.numeric(mass.g))%>%
  dplyr::select(-c(latitude,longitude,status))%>%
  left_join(master)%>%
  left_join(family.common.names)%>%
  left_join(lumped.common.names)%>%
  dplyr::mutate(common.name=if_else(is.na(australian.common.name),family.common.name,australian.common.name))%>%
  dplyr::mutate(common.name=if_else(!is.na(lumped.common.name),lumped.common.name,common.name))%>%
  dplyr::mutate(scientific=paste(genus," ",species," (",common.name,")",sep=""))

# Make icon for images and videos----
icon.habitat <- makeAwesomeIcon(icon = "image", library = "fa")
icon.fish <- makeAwesomeIcon(icon = "video", library = "fa", markerColor = "lightred", iconColor = "black")
icon.models <- makeAwesomeIcon(icon = "laptop", library = "fa", markerColor = "orange", iconColor = "black")

IconSet <- awesomeIconList(
  "Fish highlights"   = makeAwesomeIcon(icon = "video", library = "fa", markerColor = "lightred"),
  "Habitat imagery" = makeAwesomeIcon(icon = "image", library = "fa"),
  "3D models" = makeAwesomeIcon(icon = "laptop", library = "fa", markerColor = "orange")
)

testIcons <- iconList(blue = makeIcon("images/marker_red.png", iconWidth = 24, iconHeight =32),
                       green = makeIcon("images/marker_green.png", iconWidth = 24, iconHeight =32),
                       orange = makeIcon("images/marker_blue.png", iconWidth = 24, iconHeight =32))

# icon.bruv.habitat <- iconList(blue = makeIcon("images/marker_green.png", iconWidth = 40, iconHeight =40))
# icon.boss.habitat <- iconList(blue = makeIcon("images/marker_pink.png", iconWidth = 40, iconHeight =40))
# icon.fish <- iconList(blue = makeIcon("images/marker_yellow.png", iconWidth = 40, iconHeight =40))
# icon.models <- iconList(blue = makeIcon("images/marker_purple.png", iconWidth = 40, iconHeight =40))

html_legend <- "<div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>
<div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>
<div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>"

html_legend <- "<div style='padding: 10px; padding-bottom: 10px;'><h4 style='padding-top:0; padding-bottom:10px; margin: 0;'> Marker Legend </h4><br/>

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_yellow.png?raw=true'
style='width:30px;height:30px;'> Fish highlights <br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_green.png?raw=true'
style='width:30px;height:30px;'> Habitat imagery (stereo-BRUV)<br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_pink.png?raw=true'
style='width:30px;height:30px;'> Habitat imagery (BOSS)<br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_purple.png?raw=true'  
style='width:30px;height:30px;'> 3D models"

# Legend function ----
markerLegendHTML <- function(IconSet) {
  # container div:
  legendHtml <- "<div style='padding: 10px; padding-bottom: 10px;'><h4 style='padding-top:0; padding-bottom:10px; margin: 0;'> Marker Legend </h4>"
  
  n <- 1
  # add each icon for font-awesome icons icons:
  for (Icon in IconSet) {
    # if (Icon[["library"]] == "fa") {
      legendHtml<- paste0(legendHtml, "<div style='width: auto; height: 45px'>",
                          "<div style='position: relative; display: inline-block; width: 36px; height: 45px' class='awesome-marker-icon-",Icon[["markerColor"]]," awesome-marker'>",
                          "<i style='margin-left: 3px; margin-top: 11px; 'class= 'fa fa-",Icon[["icon"]]," fa-inverse'></i>",
                          "</div>",
                          "<p style='position: relative; top: 15px; display: inline-block; ' >", names(IconSet)[n] ,"</p>",
                          "</div>")    
    # }
    n<- n + 1
  }
  paste0(legendHtml, "</div>")
}


dbHeader <- dashboardHeader()
dbHeader$children[[2]]$children <-  tags$a(href='http://mycompanyishere.com',
                                           tags$img(src='https://www.nespmarine.edu.au/sites/default/themes/nespmarine/logo.png',height='60',width='200'))

dbHeader <- dashboardHeader(title = "Fish & Clips",
                            tags$li(a(href = 'https://marineecology.io/',
                                      img(src = 'https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/MEG-white.png?raw=true',
                                          title = "Marine Ecology Group", height = "50px"),
                                      style = "padding-top:10px; padding-bottom:10px;"),
                                    class = "dropdown"),
                            tags$li(a(href = 'https://www.nespmarine.edu.au/',
                                      img(src = 'https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/mbh-logo-white-cropped.png?raw=true',
                                          title = "Marine Biodiversity Hub", height = "50px"),
                                      style = "padding-top:10px; padding-bottom:10px;"),
                                    class = "dropdown"))


# Theme for plotting ----
Theme1 <-    theme_bw()+
  theme( # use theme_get() to see available options
    panel.grid = element_blank(), 
    panel.border = element_blank(), 
    axis.line = element_line(colour = "black"),
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    legend.background = element_blank(),
    legend.key = element_blank(), # switch off the rectangle around symbols in the legend
    legend.text = element_text(size=12),
    legend.title = element_blank(),
    #legend.position = "top",
    text=element_text(size=12),
    strip.text.y = element_text(size = 12,angle = 0),
    axis.title.x=element_text(vjust=0.3, size=12),
    axis.title.y=element_text(vjust=0.6, angle=90, size=12),
    axis.text.y=element_text(size=12),
    axis.text.x=element_text(size=12),
    axis.line.x=element_line(colour="black", size=0.5,linetype='solid'),
    axis.line.y=element_line(colour="black", size=0.5,linetype='solid'),
    strip.background = element_blank(),
    plot.title = element_text(color="black", size=12, face="bold.italic"))

theme_collapse<-theme(      ## the commented values are from theme_grey
  panel.grid.major=element_line(colour = "white"), ## element_line(colour = "white")
  panel.grid.minor=element_line(colour = "white", size = 0.25), 
  plot.margin= grid::unit(c(0, 0, 0, 0), "in"))

# functions for summarising data on plots ----
se <- function(x) sd(x) / sqrt(length(x))
se.min <- function(x) (mean(x)) - se(x)
se.max <- function(x) (mean(x)) + se(x)

addLegendCustom <- function(map, colors, labels, sizes, opacity = 0.5){
  colorAdditions <- paste0(colors, "; border-radius: 50%; width:", sizes, "px; height:", sizes, "px")
  labelAdditions <- paste0("<div style='display: inline-block;height: ", sizes, "px;margin-top: 4px;line-height: ", sizes, "px;'>", labels, "</div>")
  
  return(addLegend(map, colors = colorAdditions, labels = labelAdditions, opacity = opacity))
}

