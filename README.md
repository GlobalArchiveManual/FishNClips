# FishNClips
https://marine-ecology.shinyapps.io/FishNClips/

## To add more data to FishNClips
### Part 1. Add Metadata to FishNClips
- Clone the repo to your local machine
- Add a folder in the "data/metadata/" folder, name this folder with the shortened Marine Park name e.g. "South-west Corner" or "Ningaloo" NOT "Ningaloo Marine Park"
- Add this marine park to the UI (in the *leaflet.marine.park* selectInput. The naming needs to be consistent.
- Within the folder created above, create two more folders "stereo-BOSS" and "stereo-BRUV" (Check the folders already created in the metadata folder).
- Add the metadata file to the correct method. 

#### NOTE: Format the metadata correctly
- Follow GlobalArchive conventions for naming the metadata.csv and for the column names.
- Include "fishnclipz" column with "Yes" or "No". TODO Brooke to add this function into the data

### Part 2. Add videos to bucket (Brooke/Nik to add to...)
- Add folder containing the videos, this folder needs to be named with the CampaignID (matching GlobalArchive conventions).



## Styling
Markers are from [flaticon](https://www.flaticon.com/free-icon/maps-and-flags_447031?k=1635227226463).
Colour pallete from [canva colour wheel](https://www.canva.com/colors/color-wheel/)

- #7CF8C1 = green (RGB 124, 248, 193)
- #837CF8 = purple (RGB 131, 124, 248)
- #F87CB3 = pink (RGB 248, 124, 179)
- #F1F87C = yellow (RGB 241, 248, 124)
