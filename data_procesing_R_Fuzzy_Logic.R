#----Loading libraries-------#
library(sets)
library(RMySQL)
library(DBI)


#------------Building our water prediction system based on fuzzy system-----------#
variables <- set(
  Temperature = fuzzy_partition(varnames = c(Cold = 15, Medium = 30, Hot = 45), sd = 7.5,
                                universe = seq( from = 0, to= 100, by = 0.1 )),
  Humidity = fuzzy_partition(varnames = c(Dry = 0, Medium = 40, Wet = 80), sd = 17.5,
                             universe = seq( from = 0, to= 100, by = 0.1 )),
  Luminosity = fuzzy_partition(varnames = c(Dark = 0, Medium = 7500, Light = 15000), sd = 5000,
                               universe = seq( from = 0, to= 15000, by = 1 )),
  Duration = fuzzy_partition(varnames =c(Zero = 0, VShort= 8, Short = 16, Long = 24, VLong = 32), sd = 3,
                             universe = seq( from = 0, to= 50, by = 0.1 ))
)

rules <-set(
  #-------------------------------------------------------------------------------------------------------------#
  fuzzy_rule(Humidity %is% Wet ,Duration %is% Zero),
  #-------------------------------------------------------------------------------------------------------------#
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Cold, Duration %is% Short),
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Medium && Luminosity %is% Light || Luminosity %is% Medium, Duration %is% VShort),
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Medium && Luminosity %is% Dark, Duration %is% Short),
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Hot && Luminosity %is% Light, Duration %is% Zero),
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Hot && Luminosity %is% Medium, Duration %is% VShort),
  fuzzy_rule(Humidity %is% Medium && Temperature %is% Hot && Luminosity %is% Dark, Duration %is% Long),
  #-------------------------------------------------------------------------------------------------------------#
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Cold, Duration %is% VLong),
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Medium && Luminosity %is% Light, Duration %is% Short),
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Medium && Luminosity %is% Medium || Luminosity %is% Dark, Duration %is% Long),
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Hot && Luminosity %is% Light, Duration %is% Zero),
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Hot && Luminosity %is% Medium, Duration %is% VShort),
  fuzzy_rule(Humidity %is% Dry && Temperature %is% Hot && Luminosity %is% Dark, Duration %is% VLong)
)

Water_System <- fuzzy_system(variables, rules)
print(Water_System)
plot(Water_System)

#------------------Simple test---------------#
debit = 0.67
f1 <- fuzzy_inference(Water_System, list( Temperature= 30, Humidity= 65 , Luminosity= 6200))
duration1 <- gset_defuzzify(f1, "centroid")
print(duration1)
volume1 = duration1 * debit
print(volume1)


#----DataBase (Sensor_Data) variables retrieve -------#
mySqlCreds <- list(dbhostname ="ec2-108-128-15-84.eu-west-1.compute.amazonaws.com",
                   dbname ='PISTE10',
                   username='piste10',
                   pass = 'piste10',
                   port = 3306
)

count <- 1
while (TRUE) {
  con<- dbConnect(
    dbDriver("MySQL"),
    host = mySqlCreds$dbhostname,
    dbname = mySqlCreds$dbname,
    user =mySqlCreds$username,
    password = mySqlCreds$pass,
    port=mySqlCreds$port
  )
  RowQuery <- "SELECT COUNT(*) FROM Agro_Environmental_Parameters "
  rowscount <- dbGetQuery(con, RowQuery)
  
  while (count <= rowscount) {
    myQuery <- paste("SELECT * from Agro_Environmental_Parameters where Row_ID = '",count,"';",sep="")
    data.frame <- dbGetQuery(con, myQuery)
    
    #----Fuzzy Logic : Duration prediction-------#
    options(digits=3)
    v1 <-  as.double(data.frame$Temperature)
    v2 <- as.double(data.frame$Humidity)
    v3 <- as.double(data.frame$Luminosity)
    f1 <- fuzzy_inference(Water_System, list( Temperature= v1, Humidity= v2 , Luminosity=  v3  ))
    duration <- gset_defuzzify(f1, "centroid")
    if (duration < 14) 
      decision <- 0
    else
      decision <- 1
    #-----Seeing results---#
    print(duration)
    print(decision)
    
    
    #----DataBase (resultat) Writing -------#
    values <- data.frame(
      Row_ID= data.frame$Row_ID ,
      Node_ID= data.frame$Node_ID ,
      Luminosity = data.frame$Luminosity ,
      Humidity = data.frame$Humidity , 
      Temperature = data.frame$Temperature  , 
      Time = data.frame$Time , 
      Date =  data.frame$Date , 
      Duration = duration ,
      Decision = decision 
    )
    
    dbWriteTable(con,"resultats",values, overwrite=FALSE,append=TRUE, row.names = FALSE)
    count <- count +1
  }
  #----Disconnect -------#
  dbDisconnect(con)
  Sys.sleep(20)
  print('Data stored successfully : Sleep Time before Relaunch!')
}

#lapply(dbListConnections(MySQL()), dbDisconnect)