# library(devtools)
# install_github("UWAMEGFisheries/GlobalArchive") #to check for updates
library(GlobalArchive)
library(dplyr)
library(stringr)
library(tidyr)
library(rgdal)
library(forcats)
library(readr)

data_dir <- here::here("data")

read_metadata <- function(flnm, data_dir = here::here("data")) {
  flnm %>%
    readr::read_csv(col_types = readr::cols(.default = "c")) %>%
    dplyr::mutate(folder.structure = stringr::str_replace_all(flnm, c("G:/FishNClips/data/metadata/" = "",
                                                                      "_Metadata.csv" = "",
                                                                      "_metadata.csv" = ""))) %>%
    tidyr::separate(folder.structure, into = c("marine.park", "method", "campaignid"), sep = "/", extra = "drop", fill = "right") %>%
    ga.clean.names()
}

clips <- read.delim("data/download.txt", header = FALSE) %>%
  separate(V1, c("file", "campaignid", "sample"), "/") %>%
  dplyr::mutate(sample = str_replace_all(.$sample, ".mp4", ""))

unique(clips$sample)
unique(clips$campaignid) %>% sort()

glimpse(clips)


# Bring in old metadata ----
metadata_old <- list.files(path = data_dir, recursive = T, pattern = "_Metadata.csv", full.names = T) %>% 
  purrr::map_df(~ read_metadata(.)) %>%
  dplyr::mutate(sample = str_replace_all(.$sample, c("FHC01" = "FHCO1", "FHC02" = "FHCO2", "FHC03" = "FHCO3"))) %>%
  # dplyr::filter(successful.count %in% "Yes") %>%
  filter(!is.na(longitude)) %>%
  dplyr::rename(latitude_dd = latitude, longitude_dd = longitude) %>%
  dplyr::mutate(sample = case_when(
    campaignid %in% "2020-06_south-west_stereo-BRUVs" ~ str_pad(sample, side = "left", pad = "0", width = 2),
    .default = sample
  )) %>%
  # dplyr::filter(!is.na(sample)) %>%
  glimpse()

metadata_new <- list.files(path = data_dir, recursive = T, pattern = "_metadata.csv", full.names = T) %>% 
  purrr::map_df(~ read_metadata(.)) %>%
  # dplyr::filter(successful.count %in% "Yes") %>%
  filter(!is.na(longitude_dd)) %>%
  dplyr::mutate(sample = case_when(
    is.na(sample) & is.na(period) ~ opcode,
    is.na(sample) & is.na(opcode) ~ period, 
    .default = sample
  )) %>%
  glimpse()

unique(metadata_old$campaignid)%>% sort()
unique(metadata_new$campaignid)%>% sort()

metadata <- bind_rows(metadata_old, metadata_new) %>%
  dplyr::select(campaignid, sample, latitude_dd, longitude_dd, marine.park, method) %>%
  glimpse()

# Clips missing metadata
missing.metadata <- anti_join(clips, metadata) %>%
  filter(!sample %in% "pre-converted")


# metadata missing clips
missing.clips <- anti_join(metadata, clips)

# remove points that are missing clips
# TODO will need to update the clips download to keep all the ones that are uploaded
metadata <- anti_join(metadata, missing.clips)

unique(metadata$campaignid)%>% sort()

bruv.videos <- metadata %>%
  dplyr::filter(method %in% "stereo-BRUV") %>%
  dplyr::mutate(sample = as.character(sample))%>% 
  dplyr::mutate(source = "bruv.habitat.highlights") %>%
  dplyr::mutate(popup = paste0('<video width="645" autoplay controls>
  <source src="https://object-store.rc.nectar.org.au/v1/AUTH_00a0b722182f427090a2d462ace79a0a/FishNClips/videos/', campaignid, "/", sample,'.mp4" type="video/mp4">
</video>')) %>%
  dplyr::select(marine.park, method, latitude_dd, longitude_dd, popup, source, sample)

boss.videos <- metadata %>%
  dplyr::filter(method %in% "stereo-BOSS") %>%
  dplyr::mutate(sample = as.character(sample))%>% 
  dplyr::mutate(source = "boss.habitat.highlights") %>%
  dplyr::mutate(popup = paste0('<video width="645" autoplay controls>
  <source src="https://object-store.rc.nectar.org.au/v1/AUTH_00a0b722182f427090a2d462ace79a0a/FishNClips/videos/', campaignid, "/", sample,'.mp4" type="video/mp4">
</video>')) %>%
  dplyr::select(marine.park, method, latitude_dd, longitude_dd, popup, source, sample)

# Fish hihglights and 3D model links ----
fish <- read_csv("data/zone-midpoints.csv", col_types = readr::cols(.default = "c")) %>%
  dplyr::filter(!is.na(fish)) %>%
  dplyr::mutate(source = "fish.highlights")%>%
  dplyr::mutate(popup = paste("<center><h4>Fish observed in the ",
                              marine.park,
                              " Marine Park, in the ",
                              zone,
                              " Zone.</h4></center>","<br/>",
                              fish, sep = "")) %>%
  filter(!marine.park %in% "South-west Corner")

models <- read_csv("data/3Dmodels.csv", col_types = readr::cols(.default = "c")) %>% 
  dplyr::mutate(source = "3d.model")

# Merge data together for leaflet map ----
dat <- bind_rows(models, fish, bruv.videos, boss.videos) %>%
  mutate(latitude_dd = as.numeric(latitude_dd)) %>%
  mutate(longitude_dd = as.numeric(longitude_dd))

dat$latitude_dd <- jitter(dat$latitude_dd, factor = 0.01)
dat$longitude_dd <- jitter(dat$longitude_dd, factor = 0.01)

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

data_for_seamap <- metadata %>%
  dplyr::mutate(url = paste0("https://object-store.rc.nectar.org.au/v1/AUTH_00a0b722182f427090a2d462ace79a0a/FishNClips/videos/", campaignid, "/", sample, ".mp4")) %>%
  dplyr::mutate(funding = case_when(
    campaignid %in% c("2014-12_Geographe.Bay_stereo-BRUVs") ~ "NERP",
    campaignid %in% c("2014-10_Montebello.sanctuaries_stereo-BRUVs",
                      "2015-01_Montebello.transect_stereo-BRUVs") ~ "WA Government & NCB & PMCP",
    campaignid %in% c("2019-08_Ningaloo-Deep_stereo-BRUVs",
                      "2020-06_south-west_stereo-BRUVs",
                      "2020-10_south-west_stereo-BOSS",
                      "2020-10_south-west_stereo-BRUVs",
                      "2021-03_West-Coast_stereo-BOSS") ~ "NESP D3",
    campaignid %in% c("2021-05_Abrolhos_stereo-BOSS",
                      "2021-05_Abrolhos_stereo-BRUVs") ~ "Parks Australia",
    campaignid %in% c("2021-05_Point Cloates_stereo-BRUVs",
                      "2021-08_Point Cloates_stereo-BRUVs",
                      "2022-05_Point Cloates_Naked-BOSS",
                      "2022-05_Point Cloates_Squid-BOSS",
                      "2022-05_Point Cloates_stereo-BRUVs") ~ "Parks Australia & OMP Ningaloo",
    campaignid %in% c("2022-03_Dongara_BOSS") ~ "FRDC",
    campaignid %in% c("2022-11_Investigator_stereo-BRUVs",
                      "2022-11_Salisbury_stereo-BRUVs",
                      "2022-11_Termination_stereo-BOSS",
                      "2022-11_Termination_stereo-BRUVs") ~ "Parks Australia & OMP Wudjari",
    campaignid %in% c("2023-03_SwC_BOSS",
                      "2023-03_SwC_stereo-BRUVs") ~ "Parks Australia",
    campaignid %in% c("2023-09_Dampier_stereo-BRUVs") ~ "Parks Australia & OMP Murujuga"
  )) %>%
  dplyr::filter(!campaignid %in% "2020-03_south-west_stereo-BOSS")

test <- data_for_seamap %>%
  distinct(campaignid, funding)

write_csv(data_for_seamap, "coordinates-and-videos-for-seamap.csv")
