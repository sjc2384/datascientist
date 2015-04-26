library(jsonlite)
library(plyr)

# this functions loads the CSV version of the imdb archive file
# and converts it to a data frame
# (this file is not a live data but an archive, saved on February 21, 2015)
loadTextData <- function() {

  movies <- read.csv("raw_imdb_data_top250.csv", header=F)
  
  pattern <- "(.*) \\((.*)\\)$"
  
  # archive contains title and year in a single variable, ie. The Matrix (1999)
  # we'll parse it with the regex and save it as two separate variable
  movies <- data.frame(Rating = as.numeric(movies$V2), 
                 Year = as.integer(substr(gsub(pattern, "\\2", movies$V3), 1, 4)), 
                 Title = gsub(pattern, "\\1", movies$V3), 
                 Votes = as.integer(gsub(",", "", movies$V1))) # remove delimiter comma
  
  return(movies)
}

# this function will load, the actual, "live" data based on the archive data above
# it uses the OMD API http://www.omdbapi.com/
loadFromJSON <- function(movieInRaw) {
  # in the archive file, movies are listed with original title, replace the non-english ones
  # as english title is needed for API search
  title <- translateTitle(movieInRaw[3])
  # replace whitespace with "+"
  title <- gsub("[[:space:]]", "+", title)
  # get the data by title and year (title by itself might not be enough)
  json_file <- sprintf("http://www.omdbapi.com/?t=%s&y=%s&plot=short&r=json&tomatoes=true", title, movieInRaw[2])
  data <- fromJSON(txt=json_file)
  
  if(data$Response == "False") {
    print(sprintf("Error! Cannot load %s from OMDB API", title))
    return(NULL)
  } else {
    return(as.data.frame(data))
  }
}

# using the functions above, this function gets the "live" data of the top250 and returns it as a data frame
getMoviesDataFrame <- function() {
  rawData <- loadTextData()
  data <- apply(rawData, 1, loadFromJSON)
  # at this point, the data is a list of data.frames, convert it to a real data.frame
  data <- ldply(data, data.frame)
  return(data)
}

# using the functions above, this function gets the "live" data of the top250 and returns it as a JSON
# also saves the JSON file to the disk
getMoviesJSON <- function() {
  data <- getMoviesDataFrame()
  jsondata <- toJSON(data)
  write(jsondata, "movies.json")
  return(jsondata)
}

# a hardcoded list of the foreign -> english translations for the movies in the archive
# TODO: replace with a more robust method
translateTitle <- function(title) {
  switch(title,
         "Il buono, il brutto, il cattivo." = return("The Good the Bad and the Ugly"),
         "Shichinin no samurai" = return("Seven Samurai"),
         "Cidade de Deus" = return("City of God"),
         "C'era una volta il West" = return("Once Upon a Time in the West"),
         "Léon" = return("Leon The Professional"),
         "El secreto de sus ojos" = return("The Secret in Their Eyes"),
         "La vita č bella" = return("Life Is Beautiful"),
         "Sen to Chihiro no Kamikakushi" = return("Spirited Away"),
         "Das Leben der Anderen" = return("The Lives of Others"),
         "Nuovo Cinema Paradiso" = return("Cinema Paradiso"),
         "Le fabuleux destin d'Amélie Poulain" = return("Am%C3%A9lie"),
         "M" = return("M "),
         "Hotaru no haka" = return("Grave of the Fireflies"),
         "Oldeuboi" = return("Oldboy"),
         "Mononoke-hime" = return("Princess Mononoke"),
         "Ladri di biciclette" = return("Bicycle Thieves"),
         "Rashômon" = return("Rashomon"),
         "Per qualche dollaro in piů" = return("For a Few Dollars More"),
         "Jodaeiye Nader az Simin" = return("A Separation"),
         "Yôjinbô" = return("Yojimbo"),
         "Taare Zameen Par" = return("Like Stars on Earth"),
         "Jagten" = return("The Hunt"),
         "El laberinto del fauno" = return("Pan's Labyrinth"),
         "Tonari no Totoro" = return("My Neighbor Totoro"),
         "Det sjunde inseglet" = return("The Seventh Seal"),
         "Eskiya" = return("The Bandit"),
         "Smultronstället" = return("Wild Strawberries"),
         "Hauru no ugoku shiro" = return("Howl's Moving Castle"),
         "Le salaire de la peur" = return("The Wages of Fear"),
         "Les diaboliques" = return("Diabolique"),
         "Les quatre cents coups" = return("The 400 Blows"),
         "Kaze no tani no Naushika" = return("Nausicaa of the Valley of the Wind"),
         "Mou gaan dou" = return("Infernal Affairs"),
         "Fanny och Alexander" = return("Fanny and Alexander"),
         "Yip Man" = return("Ip Man"),
         "La battaglia di Algeri" = return("The Battle of Algiers"),
         "Salinui chueok" = return("Memories of Murder"),
         "Per un pugno di dollari" = return("A Fistful of Dollars"),
         "La strada" = return("The Road"),
         "Tenkű no shiro Rapyuta" = return("Castle in the Sky"),
         "Le samouraď" = return("Le Samourai"),
         "Fa yeung nin wa" = return("In the Mood for Love"),
         "8˝" = return("8%C2%BD"),
         "Der Untergang" = return("Downfall"),
         return(title))
}

