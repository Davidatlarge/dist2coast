## calculate distance between geo points and coastline
## distance is in m
## transforming to UTM32 and also cropping does not seem to have a measurable performance benefit with moderate numbers of points (100) and spatial extend (North Sea scale)
## the output = "distmat" option might be quite useless if the linestrings of the coastline are not also output
## the coastline = "mapdata" uses map('world') because high res maps are too slow

dist2coast <- function(lons,
                       lats,
                       coastline_crop = NULL, #  numeric vector with xmin, ymin, xmax and ymax for cropping the coastline to a bounding box, e.g. c(xmin = -1, ymin = 50, xmax = 11, ymax = 60), elements do not have to be named but must be in the correct order
                       coastline = "ne", # coastline source; "ne" for Natural Earth (www.naturalearthdata.com) (faster), "mapdata" for using map('world') (more precise)
                       as_utm32 = FALSE, # transform both points and coast to UTM32, i.e. a planar projection, for more speed
                       output = "mindist", # "mindist" for distance to nearest coastline, "distmat" for matrix of distances between points (in rows) and every line (in cols)
                       plot = FALSE
                       
) {
  suppressWarnings( suppressPackageStartupMessages(library(dplyr, quietly = TRUE)) )
  suppressWarnings( suppressPackageStartupMessages(library(mapdata, quietly = TRUE)) ) 
  suppressWarnings( suppressPackageStartupMessages(library(sf, quietly = TRUE)) )
  
  # make sf features for points and coastline
  points <- data.frame(lons, lats) %>%
    st_as_sf(coords = c("lons", "lats")) %>%
    st_set_crs(4326)
  
  switch(coastline,
         "ne" = coast <- rnaturalearth::ne_coastline(scale = 110, returnclass = "sf") %>% st_set_crs(4326),
         "mapdata" = coast <- st_as_sf(map('world', plot = FALSE, fill = TRUE)) %>% st_set_crs(4326)
  )
  
  # crop coastline
  if(!is.null(coastline_crop)) {
    if(is.null(names(coastline_crop))) {names(coastline_crop) <- c("xmin", "ymin", "xmax", "ymax")}
    suppressMessages(suppressWarnings(
      coast <- st_crop(coast, coastline_crop)
    ))
  }
  
  # transform to UTM 32
  if(as_utm32) {
    points <- points %>% st_transform(25832)
    coast <- coast %>% st_transform(25832)
  }
  
  # calculate distances
  distmat <- st_distance(points, coast)
  mindist <- apply(distmat, 1, min)
  
  switch (output,
          "mindist" = out <- mindist,
          "distmat" = out <- distmat)
  
  if(plot) {
    suppressWarnings(library(ggplot2, quietly = TRUE))
    p1 <- ggplot() +
      geom_sf(data = coast, fill = "grey70") +
      geom_point(aes(lons, lats, col = mindist/1000)) +
      scale_x_continuous(expand = c(0,0)) +
      scale_y_continuous(expand = c(0,0)) +
      scale_color_gradientn(name = "distance to\nshore [km]", colours = c("blue", "red")) +
      theme_bw()
    print(p1)
  }
  
  return(out)
}
