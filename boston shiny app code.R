library(shiny)
library(mapboxapi)
library(shinyWidgets)
library(plotly)
library(sf)
library(viridis)
library(rsconnect)
library(tidyverse)

# rsconnect::deployApp("E:/Career/Projects/Boston_Shiny_Map/boston_listings_app")

listings <- read_csv("listings_2023.csv")
hospitals <- read_csv("Hospitals.csv")
police <- read_csv("Boston_Police_Stations.csv")
bikes <- read_csv("Blue_Bike_Stations.csv")
meters <- read_csv("Parking_Meters.csv")
hospitals <- read_csv("Hospitals.csv")
ev <- read_csv("Charging_Stations.csv")

Sys.setenv("MAPBOX_TOKEN" = "pk.eyJ1IjoiYm9zdG9uY29ubm9yMTEiLCJhIjoiY2xncXIya2VxMGc1cTNmc2I3NjFoY2NkMyJ9.fcKb-W66WPlzv4oOx6ZC4A")

boston_airbnb <-
  listings %>% 
  filter(price > 0 & price <= 9999) %>% 
  mutate(log_price = log(price, 10)) %>% 
  mutate(min_nights_buckets = cut(minimum_nights,
                                  breaks = c(-Inf, 3, 7, 14, 28, Inf),
                                  labels = c("1-3 nights", "4-7 nights", "8-14 nights", "15-28 nights", "28+ nights")))

boston_airbnb$neighbourhood[boston_airbnb$neighbourhood == 'Longwood Medical Area'] = 'Longwood'

lvls <- 
  boston_airbnb %>% 
  group_by(neighbourhood) %>% 
  summarise(m = median(price)) %>% 
  arrange(m) %>% 
  pull(neighbourhood)

library(tmaptools)
mbta <- read_GPX("mbta.gpx")

stations <-
  mbta$waypoints %>%
  filter(grepl('Red Line|Green Line|Blue Line|Orange Line', type))

T_lines <-
  mbta$tracks %>%
  filter(grepl('Red Line|Green Line|Blue Line|Orange Line', name))


boston_neighborhoods <- sf::st_read("Boston_Neighborhoods.kml")

add_MBTA_line <- function(p, line_color) {
  res <-
    p %>% 
    add_sf(
      data = T_lines %>% filter(grepl(line_color, name, ignore.case = TRUE)),
      color = ~I(line_color),
      text = ~name,
      hoverinfo = "text",
      name = paste0(line_color, " line")
    )
  return(res) }

ui <- fluidPage(
  
  # Application title
  titlePanel("Boston AirBnb Map"),
  
  fluidRow(
    
    #sidebar
    column(
      width = 4,
      sliderInput("price", "Price Range:", min = 0, max = 4500, value = c(min(boston_airbnb$price), max(boston_airbnb$price)), step = 50),
      checkboxGroupInput("min_nights", "Minimum Nights:", choices = c("1-3 nights", "4-7 nights", "8-14 nights", "15-28 nights", "28+ nights"), selected = c("1-3 nights", "4-7 nights", "8-14 nights", "15-28 nights", "28+ nights")), 
      checkboxGroupInput("trainLine", "Subway Line:", choices = c("Red", "Green", "Orange", "Blue"), selected = c("Red", "Green", "Orange", "Blue")),
      checkboxGroupInput("room_type", "Room Type:", choices = c(unique(boston_airbnb$room_type)), selected = c(unique(boston_airbnb$room_type))),
      pickerInput("map_features", "Map Features", choices = c("Hospitals", "Police Stations", "Bluebike Stations", "EV Charging Stations", "Parking Meters"), options = list('actions-box' = TRUE), multiple = TRUE),
      pickerInput("neighborhood", "Neighborhood:", choices = unique(boston_neighborhoods$Name), options = list('actions-box' = TRUE), multiple = TRUE)
    ),
    
    #map
    column(
      width = 8,
      plotlyOutput("map")
    )
  ),
  
  #boxplot
  fluidRow(
    column(width = 4,
           plotlyOutput("boxplot"))
  )
  
)




#-------------server-------------
server <- function(input, output) {
  
  #reactive data
  filtered_data <- reactive({
    data <- boston_airbnb
    
    #reactive price
    data <- data[data$price >= input$price[1] & data$price <= input$price[2], ]
    
    #reactive min nights
    if(!is.null(input$min_nights)) {
      data <- data %>% 
        filter(min_nights_buckets %in% input$min_nights)
    }
    
    #reactive room type
    if(!is.null(input$room_type)){
      data <- data %>% 
        filter(room_type %in% input$room_type)
    }
    
    #reactive neighborhood
    if (!is.null(input$neighborhood)) {
      data <- data %>% filter(neighbourhood %in% input$neighborhood)
      selected_neighborhoods <- boston_neighborhoods[boston_neighborhoods$Name %in% input$neighborhood, ]
    }
    
    data 
    
  })
  
  output$map <- renderPlotly({
    p <- plot_mapbox(filtered_data(), width = 1250, height = 850) %>%
      add_markers(
        x = ~longitude,
        y = ~latitude,
        color = ~log(price, 10),
        name = "Log (base 10) of price",
        text = 
          ~paste(
            name, 
            "\nRoom type:", room_type,
            "\nPrice: ", price,
            "\nMinimum nights: ", minimum_nights
          ),
        hoverinfo = "text"
      ) %>%
      layout(
        mapbox =
          list(
            center = list(lat = 42.32, lon = -71.1),
            zoom = 10.5,
            style = "dark"
          )
      ) 
    
    
    
    #red line
    if ("Red" %in% input$trainLine){
      mbta_red <- stations %>% filter(grepl("red", type, ignore.case = TRUE))
      p <- add_MBTA_line(p, "red") %>% 
        add_sf(
          data = mbta_red,
          name = "MBTA T stations",
          text = ~paste(name, " (", type, ")"),
          hoverinfo = "text",
          color = I("pink"),
          size = I(30)
        )
    }
    
    #green line
    if ("Green" %in% input$trainLine){
      mbta_green <- stations %>% filter(grepl("green", type, ignore.case = TRUE))
      p <- add_MBTA_line(p, "green") %>% 
        add_sf(
          data = mbta_green,
          name = "MBTA T stations",
          text = ~paste(name, " (", type, ")"),
          hoverinfo = "text",
          color = I("pink"),
          size = I(30)
        )
    }
    
    #orange line
    if ("Orange" %in% input$trainLine){
      mbta_orange <- stations %>% filter(grepl("orange", type, ignore.case = TRUE))
      p <- add_MBTA_line(p, "orange") %>% 
        add_sf(
          data = mbta_orange,
          name = "MBTA T stations",
          text = ~paste(name, " (", type, ")"),
          hoverinfo = "text",
          color = I("pink"),
          size = I(30)
        )
    }
    
    #blue line
    if ("Blue" %in% input$trainLine){
      mbta_blue <- stations %>% filter(grepl("blue", type, ignore.case = TRUE))
      p <- add_MBTA_line(p, "blue") %>% 
        add_sf(
          data = mbta_blue,
          name = "MBTA T stations",
          text = ~paste(name, " (", type, ")"),
          hoverinfo = "text",
          color = I("pink"),
          size = I(30)
        )
    }
    
    
    #neighborhoods
    if (!is.null(input$neighborhood)){
      p <- p %>% add_sf(
        inherit = FALSE,
        data = boston_neighborhoods[boston_neighborhoods$Name %in% input$neighborhood, ],
        fill = "",
        name = "Neighborhoods Boundaries",
        text = ~Name,
        hoverinfo = "text",
        color = I("azure4"),
        opacity = 0.7
      ) 
      
    }
    
    #map features
    if ("Hospitals" %in% input$map_features){
      p <- p %>% add_trace(
        data = hospitals,
        x = ~Longitude,
        y = ~Latitude,
        mode = 'markers',
        name = "Hospitals",
        text = ~paste(Name,
                      "\nAddress: ", Address),
        hoverinfo = "text",
        marker = list(
          color = 'magenta', size = 7)
      )
    }
    
    if ("Bluebike Stations" %in% input$map_features){
      p <- p %>% add_trace(
        data = bikes,
        x = ~Longitude,
        y = ~Latitude,
        opacity = 0.5,
        mode = 'markers',
        name = "Bike Stations",
        text = ~paste("Station Number: ", Number,
                      "\nAddress: ", Name,
                      "\nTotal Docks: ", Total_docks),
        hoverinfo = "text",
        marker = list(color = 'navy', size = 5)
      )
    }
    
    if ("Police Stations" %in% input$map_features){
      p <- p %>% add_trace(
        data = police,
        x = ~CENTROIDX,
        y = ~CENTROIDY,
        mode = 'markers',
        name = "Police Stations",
        text = ~paste("Address: ", ADDRESS),
        hoverinfo = "text",
        marker = list(color = 'red', size = 10)
      )
    }
    
    if ("EV Charging Stations" %in% input$map_features){
      p <- p %>% add_trace(
        data = ev,
        x = ~Longitude,
        y = ~Latitude,
        mode = 'markers',
        name = 'EV Charging Stations',
        text = ~paste(
          Station_Name,
          "\nAddress: ", Street_Address,
          "\nNetwork ", ifelse(is.na(EV_Network), "Not Available", EV_Network),
          "\nConnector: ", EV_Connector_Types
        ),
        hoverinfo = "text",
        marker = list(color = "orange", size = 7)
      )
    }
    
    if ("Parking Meters" %in% input$map_features){
      p <- p %>% add_trace(
        data = meters,
        x = ~LONGITUDE,
        y = ~LATITUDE,
        opacity = 0.5,
        mode = 'markers',
        name = 'Parking Meters',
        text = ~paste(
          "Payment Days: ", pay_days,
          "\nPayment Times: ", pay_time,
          "\nRate (per hour): ", pay_rate,
          "\nDuration (hours): ", pay_duration
        ),
        hoverinfo = "text",
        marker = list(color = "#8c564b", size = 5)
      )
    }
    
    if ("Recreational/Open Spaces" %in% input$map_features){
      p <- p %>% add_sf(
        inherit = FALSE,
        data = open_spaces,
        name = "Open Spcae",
        text = ~Name,
        hoverinfo = "text",
        color = I("darkgreen")
      )
    }
    
    p
    
  })
  
  #boxplot
  output$boxplot <- renderPlotly({
    p_box <-
      plot_ly(
        filtered_data(),
        x = ~factor(neighbourhood, lvls),
        y = ~price,
        type = "box",
        showlegend = FALSE,
        name = "") %>%
      layout(
        yaxis = list(type = "log", title = "log(price)"),
        xaxis = list(title = "", tickangle = -35)
      )
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
