# library(devtools)
# install_github("UWAMEGFisheries/GlobalArchive") #to check for updates
library(dplyr)
library(stringr)
library(tidyr)
library(rgdal)

data_dir <- here::here("data")

read_metadata <- function(flnm, data_dir = here::here("data")) {
  flnm %>%
    readr::read_csv(col_types = readr::cols(.default = "c")) %>%
    dplyr::mutate(folder.structure = stringr::str_replace_all(flnm, c("C:/GitHub/FishClips/data/metadata/" = "", 
                                                                      "_Metadata.csv" = ""))) %>%
    tidyr::separate(folder.structure, into = c("marine.park", "method", "campaignid"), sep = "/", extra = "drop", fill = "right") %>%
    ga.clean.names()
}

# Bring in metadata ----
metadata <- list.files(path = data_dir, recursive = T, pattern = "_Metadata.csv", full.names = T) %>% 
  purrr::map_df(~ read_metadata(.)) %>%
  dplyr::mutate(campaignid = stringr::str_replace_all(campaignid, c("C:/GitHub/FishClips/data/" = ""))) %>%
  # dplyr::filter(successful.count %in% "Yes") %>%
  filter(!is.na(longitude))

unique(metadata$campaignid)
# Have lost some from using successful.count
# Claude has been using fishnclipz

bruv.videos <- metadata %>%
  dplyr::filter(method %in% "stereo-BRUV") %>%
  dplyr::mutate(sample = as.character(sample))%>% 
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup = paste0('<video width="645" autoplay controls>
  <source src="https://object-store.rc.nectar.org.au/v1/AUTH_00a0b722182f427090a2d462ace79a0a/FishNClips/videos/', campaignid, "/", sample,'.mp4" type="video/mp4">
</video>')) %>%
  dplyr::select(marine.park, method, latitude, longitude, popup, source, sample)

boss.videos <- metadata %>%
  dplyr::filter(method %in% "stereo-BOSS") %>%
  dplyr::mutate(sample = as.character(sample))%>% 
  dplyr::mutate(source = "boss.habitat.highlights") %>%
  dplyr::mutate(popup = paste0('<video width="645" autoplay controls>
  <source src="https://object-store.rc.nectar.org.au/v1/AUTH_00a0b722182f427090a2d462ace79a0a/FishNClips/videos/', campaignid, "/", sample,'.mp4" type="video/mp4">
</video>')) %>%
  dplyr::select(marine.park, method, latitude, longitude, popup, source, sample)

# Load 2021 abrolhos boss metadata ----
# abro.boss.metadata <- read.csv("data/2021-05_Abrolhos_BOSS.csv") %>%
#   ga.clean.names()%>%
#   mutate(sample = as.character(sample))%>%
#   filter(fishnclipz%in%c("Yes"))

# Fish hihglights and 3D model links ----
fish <- read_csv("data/zone-midpoints.csv", col_types = readr::cols(.default = "c")) %>%
  dplyr::filter(!is.na(fish)) %>%
  dplyr::mutate(source = "fish.highlights")%>%
  dplyr::mutate(popup = paste("<center><h4>Fish observed in the ",
                              marine.park,
                              " Marine Park, in the ",
                              zone,
                              " Zone.</h4></center>","<br/>",
                              fish, sep = ""))

models <- read_csv("data/3Dmodels.csv", col_types = readr::cols(.default = "c")) %>% 
  dplyr::mutate(source = "3d.model")

# Merge data together for leaflet map ----
dat <- bind_rows(models, fish, bruv.videos, boss.videos) %>%
  mutate(latitude = as.numeric(latitude)) %>%
  mutate(longitude = as.numeric(longitude))

dat$latitude <- jitter(dat$latitude, factor = 0.01)
dat$longitude <- jitter(dat$longitude, factor = 0.01)

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

# Commonwealth marine parks ----
commonwealth.mp$zone <- as.factor(commonwealth.mp$zone)
commonwealth.mp$zone<-fct_relevel(commonwealth.mp$zone, "Sanctuary (no-take)", "National Park (no-take)", "Recreational Use", "Habitat Protection", "Multiple Use", "Special Purpose")


# SAVE DATA FOR SHINY APP
saveRDS(dat, "data/dat.RDS")
saveRDS(commonwealth.mp, "data/commonwealth.mp.RDS")
saveRDS(state.mp, "data/state.mp.RDS")
saveRDS(ngari.mp, "data/ngari.mp.RDS")
