# Load libraries ----
library(dplyr)
library(DT)
library(forcats)
library(ggplot2)
library(GlobalArchive)
library(leaflet)
library(readr)
library(shiny)
library(shinybusy)
library(shinydashboard)
library(shinyjs)
library(stringr)
library(tidyr)

# These files are made in the "create.data.R" script, open and edit there to change the contents of the files
dat <- readRDS("data/dat.RDS")
commonwealth.mp <- readRDS("data/commonwealth.mp.RDS")
state.mp <- readRDS("data/state.mp.RDS")
ngari.mp <- readRDS("data/ngari.mp.RDS")

# Colours
#7CF8C1 = green (124, 248, 193)
#837CF8 = purple (131, 124, 248)
#F87CB3 = pink (248, 124, 179)
#F1F87C = yellow (241, 248, 124)

state.pal <- colorFactor(c("#bfaf02", # conservation
                           "#7bbc63", # sanctuary = National Park
                           "#fdb930", # recreation
                           "#b9e6fb", # general use
                           '#ccc1d6' # special purpose
), state.mp$zone)

commonwealth.pal <- colorFactor(c("#f6c1d9", # Sanctuary
                                  "#7bbc63", # National Park
                                  "#fdb930", # Recreational Use
                                  "#fff7a3", # Habitat Protection
                                  '#b9e6fb', # Multiple Use
                                  '#ccc1d6'# Special Purpose
), commonwealth.mp$zone)


# Make icon for images and videos----
# html_legend <- "<div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>
# <div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>
# <div style='width: auto; height: 45px'> <div style='position: relative; display: inline-block; width: 36px; height: 45px' <img src='images/marker_red.png'> </div> <p style='position: relative; top: 15px; display: inline-block; ' > BRUV </p> </div>"

html_legend <- "<div style='padding: 10px; padding-bottom: 10px;'><h4 style='padding-top:0; padding-bottom:10px; margin: 0;'> Marker Legend </h4><br/>

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_yellow.png?raw=true'
style='width:30px;height:30px;'> Fish highlights <br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_green.png?raw=true'
style='width:30px;height:30px;'> Habitat imagery (stereo-BRUV)<br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_pink.png?raw=true'
style='width:30px;height:30px;'> Habitat imagery (BOSS)<br/> 

<img src='https://github.com/UWAMEGFisheries/UWAMEGFisheries.github.io/blob/master/images/markers/marker_purple.png?raw=true'  
style='width:30px;height:30px;'> 3D models"
