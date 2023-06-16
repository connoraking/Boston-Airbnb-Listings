# Boston Airbnb Listings

The objective of this project was to create an interactive application that provides users with various information about AirBnB listings in the Boston area. The app allows users to filter listings by price range and room type, and choose different features they want to visualize on the map such as hospitals, police stations, bike stations, EV charging stations, and parking meters. In addition, the application provides an option to select and highlight different neighborhoods and public transit lines, allowing users to explore the city's infrastructure in relation to the AirBnB listings. The project was coded using R within Rstudio.

- **EDA**: Exploratory data analysis with visualizations can be found here: [EDA](2023 eda.Rmd)
- **Report**: A more detailed report of the maps can be found here: [Report](./2023_maps.Rmd)

## Shiny App

The [Shiny app](https://connoraking.shinyapps.io/boston_listings_app/) was hosted on shinyapps.io

## Table of Contents

## Introduction

### Project Overview

This project serves as a demonstration of my proficiency in R programming, data analysis, and geospatial visualization. I have designed and developed an interactive tool using R and the Mapbox API that showcases various employment sectors and demographic trends across different geographical locations. The interactive map produced is particularly useful in visualizing and understanding the spatial distribution of these attributes, providing meaningful insights for urban planning, policy-making, and resource allocation decisions.

### Tools and Libaries used

In the course of this project, I've applied extensive use of various R libraries:

- **Data Manipulation**: `tidyverse`
- **Geospatial Analysis**: `sf`, `tmaptools`
- **Data Visualization**: `plotly`, `ggplot2`, `viridis`
- **Shiny App Development**: `shiny`, `shinyWidgets`
- **Map Rendering**: `mapboxapi`

### Data Acquisition

- Listings (March 19th 2023): [Inside Airbnb](http://insideairbnb.com/get-the-data/)
- MBTA data: [Erik Demaine](http://erikdemaine.org/maps/mbta/)
- Neighborhood Lines: [Boston Maps](https://data.boston.gov/dataset/boston-neighborhoods) 
- Hospitals: [Boston Maps](https://data.boston.gov/dataset/hospitals)
- Police Stations: [Boston Maps](https://data.boston.gov/dataset/boston-police-stations) 
- Bluebike Stations: [Boston Maps](https://data.boston.gov/dataset/blue-bike-stations)
- EV Charging Stations: [Boston Maps](https://data.boston.gov/dataset/charging-stations)
- Parking Meters: [Boston Maps](https://data.boston.gov/dataset/parking-meters)
- Recreational Spaces: [Boston Maps](https://data.boston.gov/dataset/open-space)

## Data Cleaning and Pre-processing

- Listings valued at $0 or outliers deemed to be errors were removed. 
- The `grepl` package was used to parse MBTA stations and subway lines.
- The `meters` data set was wrangled from a single `str` column named `PAY_POLICY` into columns `pay_time`, `pay_days`, `pay_rate`, and `pay_duration`. These new columns were then used in the tooltip for the associated markers.

## Maps and Geospatial Analysis

Since GitHub's Markdown rendering does not support intreactive content directly, I cannot embed the the interactive maps into the document. Instead I will embedd png files for the maps. As a limitation, you won't be able to see the tooltips for each marker. Please check out the [Shiny app](https://connoraking.shinyapps.io/boston_listings_app/) I created which includes all features and interactivity.

### Map with Listings
![](map_pics/p_listings)<!-- -->




