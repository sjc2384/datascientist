library(jsonlite)
library(googleVis)
library(shiny)

movies <- fromJSON(txt="movies.json")

# year
movies[,2] <- as.numeric(movies[,2])
# metascore
movies[,15] <- as.numeric(movies[,15])
# imdb rating
movies[,16] <- as.numeric(movies[,16])
# imdb votes
movies[,17] <- as.numeric(gsub(",", "", movies[,17]))
# tomatometer
movies[,20] <- as.numeric(movies[,20])
# tomato rating
movies[,22] <- as.numeric(movies[,22])
# tomato user rating
movies[,28] <- as.numeric(movies[,28])
# number of tomato user rating
movies[,29] <- as.numeric(gsub(",", "", movies[,29]))
# insert 0 instead of NA
movies[is.na(movies[,29]),29] <- 0
# decade
movies[,35] <- movies$Year - movies$Year %% 10
# add a name to the decade variable too
colnames(movies)[35] = "decade"

# second data frame only for the movies that contain Box Office data
movieswithBO <- movies[-which(movies$BoxOffice == "N/A"),]

# a function to convert earning to actual numbers
# i.e.: "$3.1M --> 3100000
convertDollarToNumeric <- function(item) {
  # first, remove dollar sign
  item <- sub('\\$','',item) 
  # check the last character
  if(substr(item, nchar(item), nchar(item)) == "M") {
    # then millions
    item <- as.numeric(substr(item, 1, nchar(item)-1)) * 1000000
  } else {
    # else thousands
    item <- as.numeric(substr(item, 1, nchar(item)-1)) * 1000
  }
  return(item)
}

# save the earnings into a separate variable and name them correctly
movieswithBO[,35] <- as.numeric(sapply(movieswithBO$BoxOffice, convertDollarToNumeric))
colnames(movieswithBO)[35] = "Earnings"
# this variable will duplicate the title variable but is needed for the google scatter plot
# (tooltip variable name must contain ".html.tooltip")
movieswithBO$Earnings.html.tooltip <- movieswithBO$Title

shinyServer(function(input, output) {
  
  number <- reactive({
    input$movienumber
  })
  
  xaxis <- reactive({
    switch(input$xaxis,
           "IMDB rating" = "imdbRating", 
           "Rotten Tomatoes user rating" = "tomatoUserRating", 
           "Rotten Tomatoes rating" = "tomatoRating", 
           "Tomatometer" = "tomatoMeter", 
           "Year released" = "Year")
  })
  
  yaxis <- reactive({
    switch(input$yaxis,
           "IMDB rating" = "imdbRating", 
           "Rotten Tomatoes user rating" = "tomatoUserRating", 
           "Rotten Tomatoes rating" = "tomatoRating", 
           "Tomatometer" = "tomatoMeter", 
           "Year released" = "Year")
  })
  
  bubblesize <- reactive({
    switch(input$bubblesize,
           "No. of IMDB votes" = "imdbVotes",
           "No. of Rotten Tomatoes ratings" = "tomatoUserReviews",
           "Metascore" = "Metascore")
  })
  
  colorv <- reactive({
    switch(input$colorv,
           "MPAA rating" = "Rated",
           "Year released" = "Year",
           "Decade released" = "decade"
    )
  })
  
  # we'll need this as a numeric for easier subsetting
  boxxaxis <- reactive({
    switch(input$boxxaxis,
           "IMDB rating" = 16, 
           "Rotten Tomatoes user rating" = 28, 
           "Rotten Tomatoes rating" = 22, 
           "Tomatometer" = 20, 
           "Year released" = 2)
  })
  
  trendchecked <- reactive({ 
    input$trendcheckbox 
  })
  
  # chart on the default page, using GoogleVis bubble chart
  # all parameters of the chart is set up via user actions (dropdown menus)
  # except the ID (idvar), which is the title of the movie all times
  output$view <- renderGvis({
    # only the selected amount of movies
    data <- movies[1:number(),]

    gvisBubbleChart(data,
                    idvar="Title",
                    xvar=xaxis(),
                    yvar=yaxis(),
                    sizevar=bubblesize(),
                    colorvar=colorv(),
                    options=list(height=950,
                                 fontSize=10))
  })
  
  # the second, simpler chart
  # X axis is the box office earnings, Y axis can be selected by the user
  # a linear trendline can be added with a checkbox
  # checking this also opens up a very simple prediction model
  # where the earnings of a move given selected parameter is predicted
  output$boxofficeview <- renderGvis({
    ops <- list()
    if(trendchecked()) {
      ops <- list(height=950, fontSize=10, trendlines="0")
    } else {
      ops <- list(height=950, fontSize=10)
    }
      
    gvisScatterChart(movieswithBO[,c(boxxaxis(), 35, 36)], 
                     options=ops)
    
  })
  
  # a very simple linear prediction model
  predict <- function() {
    
    prediction.frame <- data.frame(Variable=movieswithBO[,boxxaxis()], Value=movieswithBO$Earnings)
    lma = lm(prediction.frame$Value~prediction.frame$Variable)
    
    prediction.frame <- data.frame(Variable=input$uservalue, Value=0)
    calculated <- as.numeric(predict.lm(lma, prediction.frame))
    
    return(calculated)
  }
  
  # update the text field with the prediction
  output$calculatedvalue <- renderPrint({ predict() })
  
  output$table <- renderDataTable({
    data <- movies[-c(10, 14, 26, 34)]
    data
  })
  
  output$downloadData <- downloadHandler(
    filename = function() { 
      return("movies.csv") 
    },
    content = function(file) {
      write.csv(movies, file)
    }
  )
})
