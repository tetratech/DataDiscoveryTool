library(DT)
library(httr)
library(stringr)
library(leaflet)
library(data.table)
library(rCharts)
library(scales)
library(jsonlite)
options(scipen=30)
#~~~~~~~~~~~~~~~~~~~~~~~~~~
## Tt Mod, Add Library ####
library(XLConnect)
source("external/dataQAQC.R", local=TRUE)
# Special version of DT needed to enable editable tables
#devtools::install_github('rstudio/DT@feature/editor')
# Increase file size limit for uploads (need for large datasets)
options(shiny.maxRequestSize=30*1024^2)
#~~~~~~~~~~~~~~~~~~~~~~~~~~
#Load helper functions
source("external/buildurl.R", local=TRUE)
source("external/readWQPdata_app.R", local=TRUE)
source("external/whatWQPsites_app.R", local=TRUE)
source("external/getData.R", local=TRUE)
#Global variables
display = c("Station", "Name", "ActivityStartDate",  "Characteristic", "Result",
            "Unit", "ResultSampleFractionText", 
            "Method", "Method_ID", "ActivityMediaSubdivisionName", "OrganizationFormalName", "ActivityTypeCode")

display_Map = c("Station", "Name", "Organization",  "Characteristic", "Result", "Unit",
                "Method", "ActivityStartDate")
compute_data <- function(updateProgress = NULL) {
  # Create 0-row data frame which will be used to store data
  dat <- data.frame(x = numeric(0), y = numeric(0))
  
  for (i in 1:60) {
    Sys.sleep(0.5)
    
    # Compute new row of data
    new_row <- data.frame(x = rnorm(1), y = rnorm(1))
    
    # If we were passed a progress update function, call it
    if (is.function(updateProgress)) {
      if (round(new_row$x) %% 2 == 0){
        text<-"Please be patient"
      }
      if (round(new_row$x) %% 2 != 0){
        text<-"still working"
      }
      full_text <- paste0("A message will display when the download is complete  ", text)
      updateProgress(detail = full_text)
    }
    
    # Add the new row of data
    dat <- rbind(dat, new_row)
  }  
  dat
}

shinyServer(
  function(input, output, session) {    
    # for Desktop bat file
    session$onSessionEnded(function() {
      stopApp()
    })
    # Take the labels and get the FIPS for State and county
    state_FIPS<-reactive({
      if (is.null(input$state)){
        return (" ")
      } else (as.character(states[states$desc %in% input$state, "FIPS"]))
    })
    county_FIPS<-reactive({
        if (is.null(input$county)){
          return (" ")
        } else (as.character(counties[counties$desc %in% input$county, "value"]))
    })   
    huc8s<-reactive({
      if(is.null(input$huc_ID)){
        return(" ")
      } else (input$huc_ID)
    })
    sample_media<-reactive({
      if(is.null(input$media)|| is.na(input$media)){
        return(" ")
      } else (input$media)
    })
    char_group<-reactive({
      if(is.null(input$group)|| is.na(input$group)){
        return(" ")
      } else (input$group)
    })
    char<-reactive({
      if(is.null(input$chars)|| is.na(input$chars)){
        return(" ")
      } else (input$chars)
    })
    type<-reactive({
      if(is.null(input$site_type)|| is.na(input$site_type)){
        return(" ")
      } else (input$site_type)
    })
    org<-reactive({
      if(is.null(input$org_id)|| is.na(input$org_id)){
        return(" ")
      } else (input$org_id)
    })
    site<-reactive({
      if(is.null(input$site_id)){
        return(" ")
      } else (input$site_id)
    })
    
    ## County selection filter
    output$county <- renderUI({
      countiesdt <- data.table(counties)
      #   countystate <- countiesdt[grepl(input$state, desc, ignore.case = TRUE)]
      if(is.null(input$state)){
        selectizeInput("county", label=p("Choose a County"), selected = NULL,
                       choices = as.character(countiesdt$desc) , multiple = TRUE)
      } else {
        selectizeInput("county", label=p("Choose a County"), selected = NULL,
                       choices = countydt[state %in% input$state ,as.character(unique(desc))] , 
                       multiple = TRUE)
      }
      
    })
    
    # Generate the url for the header pull
    url<-reactive({ 
      url<-buildurl(bBox = c(input$West, input$South, input$East, input$North), lat = input$LAT, long = input$LONG, within = input$distance,
               statecode = state_FIPS(), countycode = county_FIPS(), siteType = type(), organization = org(), 
               siteid = site(), huc = huc8s(), sampleMedia = sample_media(), characteristicType = char_group(), characteristicName = char(),
               startDateLo = as.Date(input$date_Lo, format = '%m-%d-%Y'), startDateHi = as.Date(input$date_Hi, format = '%m-%d-%Y'))
    })
    output$URL<-renderText({
      url()
    })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Tt Mod, QueryData, Save/Load Buttons ####
    ## Save Query
    output$SaveQuery2 <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_Query_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")}
      ,content = function(file) {
        # Create List
        lst_query_save <- list(input$state
                              ,input$county
                              ,input$huc_ID
                              ,input$LAT
                              ,input$LONG
                              ,input$distance
                              ,input$North
                              ,input$South
                              ,input$East
                              ,input$West
                              ,input$date_Lo
                              ,input$date_Hi
                              ,input$media
                              ,input$group
                              ,input$chars
                              ,input$site_type
                              ,input$org_id
                              ,input$site_id)
        # Set List Names
        names(lst_query_save) <- c("state"
                                  ,"county"
                                  ,"huc_ID"
                                  ,"LAT"
                                  ,"LONG"
                                  ,"distance"
                                  ,"North"
                                  ,"South"
                                  ,"East"
                                  ,"West"
                                  ,"date_Lo"
                                  ,"date_Hi"
                                  ,"media"
                                  ,"group"
                                  ,"chars"
                                  ,"site_type"
                                  ,"org_id"
                                  ,"site_id")
        # Save List
        #strFile <- paste0("DDT_Query_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
        saveRDS(lst_query_save, file)  
      }
    )
    
    # Update Query based on User File
    observeEvent(input$UpdateQuery, {
      # Get Query File specs
      q <- input$LoadQueryFile
      # Error check
      if(is.null(q)) return(NULL)
      # Error checking
      if (exists("lst_query_load")==TRUE){##IF.exists.START
        rm(lst_query_load)
      }##IF.exists.END
      # define list
      lst_query_load <- readRDS(q$datapath)
      # # Update Query Info onscreen (to user selections)
      #

      # In some cases (for Counties) required the "update" button to be clicked more than once.
      # So iterate the process
      for (i in 1:3) {##FOR.i.START
        # clear selections
        clearQuerySelection(session)
        ## Location
        updateSelectizeInput(session, "state"
                             , choices=as.character(states$desc)
                             , selected=lst_query_load$state)
        
        updateTextInput(session, "huc_ID", value=lst_query_load$huc_ID)
        updateNumericInput(session,"LAT", value=lst_query_load$LAT, min = 0, max = 100)
        updateNumericInput(session,"LONG", value=lst_query_load$LONG, min = 0, max = 100)
        updateNumericInput(session,"distance", value=lst_query_load$distance, min = 0, max = 100)
        updateNumericInput(session,"North", value=lst_query_load$North, min = -100, max = 100)
        updateNumericInput(session,"South", value=lst_query_load$South, min = -100, max = 100)
        updateNumericInput(session,"East", value=lst_query_load$East, min = -100, max = 100)
        updateNumericInput(session,"West", value=lst_query_load$West, min = -100, max = 100)
        ## Sampling Parameters
        # Below variables don't work if a blank date.
        updateDateInput(session, "date_Lo", value="1776-07-04")
        updateDateInput(session, "date_Hi", value="1776-07-04")
        
        if(is.null(lst_query_load$state)) {
          countiesdt <- data.table(counties)
          updateSelectizeInput(session, "county"
                               , choices=as.character(countiesdt$desc)
                               , selected=lst_query_load$county #character(0)
                               , options = list(items=character(0))
          )
        } else {
          countiesdt <- data.table(counties)
          updateSelectizeInput(session, "county"
                               , choices=as.character(countiesdt$desc) #countydt[state %in% input$state ,as.character(unique(desc))]
                               , selected=lst_query_load$county
                               , options = list(items=lst_query_load$county)
          )
        }
        
        updateSelectizeInput(session, "media"
                             , choices=lst_query_load$media
                             , selected=lst_query_load$media
                             , options = list(items=lst_query_load$media)
        )
        updateSelectizeInput(session, "group"
                             , choices=lst_query_load$group
                             , selected=lst_query_load$group
                             , options = list(items=lst_query_load$group)
        )
        updateSelectizeInput(session, "chars"
                             , choices=lst_query_load$chars
                             , selected=lst_query_load$chars
                             , options = list(items=lst_query_load$chars)
        )
        ## Site Parameters
        updateSelectizeInput(session, "site_type"
                             , choices=lst_query_load$site_type
                             , selected=lst_query_load$site_type
                             , options = list(items=lst_query_load$site_type)
        )
        updateSelectizeInput(session, "org_id"
                             , choices=lst_query_load$org
                             , selected=lst_query_load$org
                             , options = list(items=lst_query_load$org#, 
                                              # valueField = 'value',
                                              # labelField = 'desc',
                                              # searchField = 'desc',
                                              # options = list(),
                                              # create = FALSE,
                                              # load = I("function(query, callback) {
                                              #           if (!query.length) return callback();
                                              #           $.ajax({
                                              #           url: 'https://www.waterqualitydata.us/Codes/organization?mimeType=json',
                                              #           type: 'GET',
                                              #           error: function() {
                                              #           callback();
                                              #           },
                                              #           success: function(res) {
                                              #           callback(res.codes);
                                              #           }
                                              #           });)}")
                             )
        )
        updateTextInput(session, "site_id", value=lst_query_load$site_id)
        # Update the Dates last
        ## Remove temp value
        updateDateInput(session, "date_Lo", value=NA)
        updateDateInput(session, "date_Hi", value=NA)
        ## Update with user provided value
        updateDateInput(session, "date_Lo", value=lst_query_load$date_Lo) #YYYY-MM-DD
        updateDateInput(session, "date_Hi", value=lst_query_load$date_Hi)
        
      }##FOR.i.END
    })
    
    observeEvent(input$ClearQuery, {
      # Clear User Selections for Query
      clearQuerySelection(session)
    })
    
        #
    # observeEvent(input$SaveQuery, {
    #   # Create List
    #   ls_query_save <- list(input$state
    #                        ,input$county
    #                        ,input$huc_ID
    #     
    #                   )
    #   # Set List Names
    #   names(ls_query_save) <- c("statecode"
    #                        ,"countycode"
    #                        ,"huc8s"
    #                        # ,"lat"
    #                        # ,"long"
    #                        # ,"within"
    #                        )
    #   # Save List
    #   strFile <- paste0("DDT_Query_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
    #   saveRDS(ls_query_save)
    # }) 
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    # Run the header pull
   # RECORDS<-eventReactive(input$CHECK, {
    #  HEAD(url())$headers$'total-result-count'
   # })
    # Check number of records - conditional panel trigger
    rec_count<-eventReactive(input$CHECK, {
      if(is.null(RECORDS())|as.numeric(RECORDS()) >= 200000|as.numeric(RECORDS())==0){#| (input$CHECK%%2==1 & input$CHECK != 1)) { # won't display if clicked an odd number of times
        return("no")
      } else {#(as.numeric(RECORDS()) < 100000 & as.numeric(RECORDS()) != 0){
        return("yes")
      }
    })
    
  Headerpull<-eventReactive(input$CHECK,{
    progress<-shiny::Progress$new()
    progress$set(message = "Checking Record Count", value = 0)
    on.exit(progress$close())
    return(HEAD(url()))
  })  
  RECORDS<-reactive({
   return(Headerpull()$header$'total-result-count')
  })
  STATIONS<-reactive({
   return(Headerpull()$header$'total-site-count')
  })
  
  #  STATIONS<-eventReactive(input$CHECK, {
    #  HEAD(url())$headers$'total-site-count'
   # })
    # passes to the condition to trigger conditional panel
    output$Rec_count<-renderText({
      rec_count()
    })
    outputOptions(output, 'Rec_count', suspendWhenHidden=FALSE)
    
    # displays record count to User
    output$REC_txt<-renderText({
      withProgress(message = 'Updating',
                   detail = 'Please wait...', value = 0, {
                     for (i in 1:5) {
                       incProgress(1/5)
                       Sys.sleep(0.25)
                     }
                   })
        #if(input$CHECK == 0 | is.null(input$CHECK)) return()
             return( paste("Your query returns ", RECORDS() , " records from ", STATIONS(), " stations."))  
      })

    

      
########################## Modal in Query tab ######################################
output$modal1 <- renderUI({
                    fluidRow(column(1),
                        column(10, h4("You may import your data", style  = "text-align:center")))
             })

output$modal2 <- renderUI({   
 # if(success() != 'yes'){
    fluidRow(column(5),
             column(2, actionButton("IMPORT", "Import Data")))
 # }
})
    
#################################################################################### 

#####    Import the data
    values <- reactiveValues(starting = TRUE)
    session$onFlushed(function() {
      values$starting <- FALSE
    })
url_display<-eventReactive(input$CHECK, {
  url()
})
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    QAQC_Apply_datapath <- NULL

    ## Tt Mod, CheckData, data() ####
    # Add 2nd trigger for Event
    # Allows for loading of data from saved file (if/else)
    data<-eventReactive({
        c(input$IMPORT, input$LoadAppData)
      },  {
      # Trying a reactive example from http://shiny.rstudio.com/gallery/progress-bar-example.html
      #
      # Get Import File specs
      q <- input$LoadAppData
      # regular (Load from web or upload file)
      if(is.null(q)) {##IF.START
        # default
        progress<-shiny::Progress$new()
        progress$set(message = "Downloading Data, please be patitient, this may take some time.", value = 0)
        on.exit(progress$close())
        updateProgress<-function(value = NULL, detail = NULL){
          if(is.null(value)){
            value<-progress$getValue()
            value<-value + (progress$getMax() - value)/5
          }
          progress$set(value = value, detail = detail)
        }
        url<-buildurl(bBox = c(input$West, input$South, input$East, input$North), lat = input$LAT, long = input$LONG, within = input$distance,
                      statecode = state_FIPS(), countycode = county_FIPS(), siteType = type(), organization = org(), 
                      siteid = site(), huc = huc8s(), sampleMedia = sample_media(), characteristicType = char_group(), characteristicName = char(),
                      startDateLo = as.Date(input$date_Lo, format = '%m-%d-%Y'), startDateHi = as.Date(input$date_Hi, format = '%m-%d-%Y'))
       #The next line of code is new, and calls the new module for getting the data 
        return(getWQPData_app(url))
      } else { # Use imported file  if(!is.null(q))
        # Import Data
        data_load <- readRDS(q$datapath)
        val$display2 <- "yes" # needed for leaflet map on View Data tab
        return(data_load)
      }##IF.END
      #
    })
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Tt Mod, CheckData, Load Button ####
    #Save App Data
    output$SaveAppData <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
      }
      , content = function(file) {
        #saveRDS(all_data(),file)
        saveRDS(data(),file)
        # testing, save environment
        #save.image(file)
        #save(data(), file)
        # attr(x,y)
        # x = data()
        # y = c("siteInfo", "variableInfo", "url","queryTime")
      }
    )
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # End one section and start another.
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Tt Mod, CheckData, QAQC tab ####
    
    # # QAQC Decision Data
    # data_QAQC2 <- reactive({
    #   #
    #   data.frame(read_dataQAQC(strFile="external/DDT_QAQC_Default.xlsx"))
    #   #
    # })
    
    # # Apply QAQC Decisions
    # observeEvent(input$ApplyQAQC, {
    #   # Run code in dataQAQC.R to update ALL DATA with QAQC Decisions
    #   #df.all.applyQAQC <-  ApplyQAQCDecisions()
    #   #
    #   #~~~~~~~~~~~~~~~~~~
    #   #
    #   df.data <- all_data()
    #   df.QAQC <- RV_QAQC$df_data #data_QAQC
    #   #
    #   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #   # *** TESTING ***
    #   # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
    #   # df.QAQC <- XLConnect::readWorksheetFromFile(strFile, sheet="Methods Table", startRow=6, header=TRUE) #, drop=c(1,2))
    #   # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_Data_20170804_081355_multipleParam.rds")
    #   # df.data <- readRDS(strFile)
    #   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #   
    #   # 1. Prep Sample Data
    #   {
    #     # create merge key
    #     df.data$mergeKey <- with(df.data, paste(ActivityMediaName, CharacteristicName, 
    #                                             ResultSampleFractionText, USGSPCode,
    #                                             ResultMeasure.MeasureUnitCode,sep="|")) 
    #     # rename some variables to *.orig
    #     data.table::setnames(df.data, old = c("Characteristic", "Unit", "ResultSampleFractionText"),
    #                          new = c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig"))
    #   }
    #   #
    #   # 2. Prep QAQC Data
    #   {
    #     # create merge key
    #     df.QAQC$mergeKey <- with(df.QAQC, paste(Activity.Media, Characteristic, 
    #                                             Sample.Fraction, PCODE,
    #                                             Units,sep="|")) 
    #     # identify list of variables to merge into with sample data
    #     df.QAQCvars <- c("Apply.QAQC", "Characteristic", "Units", "Units.Conv.Mult",
    #                      "Sample.Fraction.QAQC", "QC.Min", "QC.Max", "mergeKey") 
    #   }
    #   #
    #   # 3. Merge Data
    #   # apply range check, unit conversion, and fill in.
    #   {
    #     # do merge where df.QAQC$apply == TRUE and only merge in variables listed in df.QAQCvars
    #     df.data <- merge (df.data, df.QAQC[df.QAQC$apply, df.QAQCvars], by="mergeKey", all.x=TRUE)
    #     # drop merge key
    #     df.data <- df.data[,!(names(df.data) %in% c("mergeKey"))]
    #     # identify cases where data are outside qc range (do this before unit conversion because
    #     # the ranges in the df.QAQC are based on the original units)
    #     df.data$qcRange <- FALSE
    #     df.data[!is.na(df.data$Result) & !is.na(df.data$QC.Min) & df.data$Result < df.data$QC.Min, "qcRange"]<-TRUE
    #     df.data[!is.na(df.data$Result) & !is.na(df.data$QC.Max) & df.data$Result > df.data$QC.Max, "qcRange"]<-TRUE
    #     # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
    #     # i create a numeric conversion field but suppress warnings to not alarm user
    #     df.data$Units.Conv.Mult <- suppressWarnings(as.numeric(df.data$Units.Conv.Mult))
    #     df.data$Result      <- ifelse(!is.na(df.data$Result     ) & !is.na(df.data$Units.Conv.Mult), 
    #                                   df.data$Result      * df.data$Units.Conv.Mult, df.data$Result     )
    #     df.data$ResultLower <- ifelse(!is.na(df.data$ResultLower) & !is.na(df.data$Units.Conv.Mult), 
    #                                   df.data$ResultLower * df.data$Units.Conv.Mult, df.data$ResultLower)
    #     df.data$ResultUpper <- ifelse(!is.na(df.data$ResultUpper) & !is.na(df.data$Units.Conv.Mult), 
    #                                   df.data$ResultUpper * df.data$Units.Conv.Mult, df.data$ResultUpper)
    #     # apply special case unit conversion (Deg F to Deg C)
    #     df.data$Result      <- ifelse(!is.na(df.data$Result     ) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
    #                                   (df.data$Result      - 32) * (5/9) , df.data$Result     )
    #     df.data$ResultLower <- ifelse(!is.na(df.data$ResultLower) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
    #                                   (df.data$ResultLower - 32) * (5/9) , df.data$ResultLower     )
    #     df.data$ResultUpper <- ifelse(!is.na(df.data$ResultUpper) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
    #                                   (df.data$ResultUpper - 32) * (5/9) , df.data$ResultUpper     )
    #     # handle those cases where df.QAQC was not merged in (i.e., either df.QAQC$apply==FALSE or 
    #     # there was no record to process
    #     df.data[is.na(df.data$Apply.QAQC), "apply" ] <- FALSE
    #     df.data$Characteristic <- ifelse(df.data$Apply.QAQC, df.data$Characteristic, df.data$Characteristic.orig) 
    #     df.data$Unit           <- ifelse(df.data$Apply.QAQC, df.data$Unit          , df.data$Unit.orig          ) 
    #     df.data$SampleFraction <- ifelse(df.data$Apply.QAQC, df.data$SampleFraction, df.data$ResultSampleFractionText.orig)
    #     # drop non essential variables (Tt-JBH: dont implement till after testing)
    #     #Tt-JBH df.data <- df.data[,!(names(df.data) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
    #     #Tt-JBH df.data <- df.data[,!(names(df.data) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))] 
    #   }
    #   #
    #   # 4. Return df
    #   # return(df.data)
    #   #
    #   # 4. Save modified data (so can load later)
    #   strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
    #   saveRDS(df.data, file.path(getwd(),strFile))
    #   # 
    #   QAQC_Apply_datapath <- file.path(getwd(),strFile)
    #   # 4. Return df
    #   #return(df.data)
    #   #~~~~~~~~~~~~~~~~~~
    #   
    #   cat(QAQC_Apply_datapath)
    #   flush.console()
    #   
    #   # # Update "load data button"
    #   # q <- input$LoadAppData
    #   # q$name <- strFile
    #   # q$datapath <- file.path(getwd(),strFile) 
    #   # input$LoadAppData <- q
    #   # 
    #   # # update value of button to trigger reactiveEvent
    #   # z <- input$LoadAppData
    #   # z$value <- ifelse(is.na(z$value), 0, z$value + 1)
    #   #
    # }) #observeEvent(input$ApplyQAQC#END
    # #~~~~~~~~~~~~~~~~~~
    
    # observeEvent(input$ApplyQAQC2, {
    #   # dummy button so can monitor for eventReactive data()
    # })
    
    
    #QAQC Decisions Table - example from all_data()
    # output$dt_QAQC = DT::renderDataTable(
    #   all_data()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
    #   extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'),
    #                                          pageLength = 100,
    #                                          lengthMenu = c(100, 200, 500),
    #                                          columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
    #   ), server = TRUE)
    
  #data_QAQC <- XLConnect::readWorksheetFromFile("external/DDT_QAQC_Default.xlsx", sheet="Methods Table", startRow=6, header=TRUE)

  # Create reactive data for QAQC File
  # Trigger on IMPORT, LoadAppData, and UpdateQAQC
  # no data will show until have done one of these three
  # data_QAQC <- eventReactive({
  #   c(input$IMPORT, input$LoadAppData, input$UpdateQAQC)
  #   },  {
  #   #data_QAQC <- reactive({
  #   # Get Import File specs
  #   q <- input$LoadQAQCFile
  #   #
  #   if(is.null(q)) {
  #     # default; Loads default file for IMPORT and LoadAppData
  #     df_load <- read_data_QAQC(strFile="external/DDT_QAQC_Default.xlsx"
  #                               , strSheet = "Methods Table"
  #                               , intStartRow=6)
  #     return(df_load)
  #   } else { # User defined file instead of default
  #     # Import Data
  #     df_load <- read_data_QAQC(strFile=q$datapath
  #                               ,strSheet="Methods Table"
  #                               ,intStartRow=6)
  #     #
  #     #DT::replaceData(proxy_dt_QAQC, df_load, resetPaging=FALSE, rownames=FALSE)
  #     return(df_load)
  #   }
  # })

    RV_QAQC <- reactiveValues(df_data=NULL)
    RV_QAQC$df_data <-  XLConnect::readWorksheetFromFile("external/DDT_QAQC_Default.xlsx", sheet="Methods Table", startRow=6, header=TRUE)
  
    
    # Save QAQC (User)

    ApplyQAQC.column <- 8
    data_QAQC_caption <- "Double-click to edit a cell in column Apply.QAQC (TRUE or FALSE).
                          Edits are only allowed in this column and only for the values TRUE and FALSE (not case sensitive)."
    
    output$dt_QAQC <- DT::renderDataTable(DT::datatable(RV_QAQC$df_data
                                                       , caption=data_QAQC_caption
                                                       , rownames = FALSE
                                                       , selection='none'
                                                       )
                      )
                                                       #, server=TRUE)
                                                       # )

                                          #            #  ) %>% formatStyle(columns=ApplyQAQC.column
                                          #            #                    ,target="cell"
                                          #            #                    ,background=styleEqual(c(0,1)
                                          #            #                                           ,c('lightgreen','red'))
                                          #            #                    ,fontWeight='bold')
                                          # , rownames = FALSE
                                          # , server=TRUE
                                          # )

        #outputOptions(output, 'dt_QAQC', suspendWhenHidden=TRUE)
    
    proxy_dt_QAQC <- dataTableProxy('dt_QAQC')
    #DT::selectColumns(proxy_dt_QAQC, ApplyQAQC.column)
    
    observeEvent(input$dt_QAQC_cell_edit, {
      info=input$dt_QAQC_cell_edit
      str(info)
      i = info$row
      j = info$col + 1
      v = info$value
      # Change Value "v" only IF column = 8 AND logical (T/F)
      # coerceValue requires 3 ":"
      if(j==ApplyQAQC.column & (toupper(v)=="FALSE" | toupper(v)=="TRUE")) {
        RV_QAQC$df_data[i,j] <<- DT:::coerceValue(toupper(v), RV_QAQC$df_data[i,j])
        DT::replaceData(proxy_dt_QAQC, RV_QAQC$df_data, resetPaging=FALSE, rownames=FALSE)
      }
      # may need column for matching "data".
      
      #need to update actual table (might be done with above statement)
      
    })
    
    #Load QAQC
    observeEvent(input$UpdateQAQC, {
      # Get QAQC Load file
      strFile_LoadQAQC <- input$LoadQAQCFile
      #strFile_LoadQAQC <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
      # Error Check
      if(is.null(strFile_LoadQAQC)) return(NULL)
      # load file
      #data_QAQC_Update <- XLConnect::readWorksheetFromFile(strFile_LoadQAQC$datapath, sheet="Methods Table", startRow=6, header=TRUE, rownames=FALSE)
      # trigger with event reactive
      RV_QAQC$df_data <- read_data_QAQC(strFile=strFile_LoadQAQC$datapath
                                  ,strSheet="Methods Table"
                                  ,intStartRow=6)
      # reactive data auto uploads data
      DT::replaceData(proxy_dt_QAQC, RV_QAQC$df_data, resetPaging=TRUE, rownames=FALSE)
      # # # test
      # myDir <- file.path("C:","Users","Erik.Leppo","Downloads")
      # strFile <- paste0("DDT_QAQC_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
      # saveRDS(data_QAQC, file.path(myDir,strFile))
      #
    })
    
    # Save QAQC
    output$SaveQAQC <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_QAQC_",format(Sys.time(),"%Y%m%d_%H%M%S"),".xlsx")}
      , content = function(file) {
        #
        # Copy BLANK XLSX
        file.copy(from="external/DDT_QAQC_BLANK.xlsx"
                  , to=file)
        # Then copy in data
        mySheet <- "Methods Table"
        wb <- XLConnect::loadWorkbook(file)
        XLConnect::writeWorksheet(wb, data=RV_QAQC$df_data, sheet=mySheet, startRow=7, header=FALSE)
        XLConnect::saveWorkbook(wb)
        #
      }
    )
  
     # QAQC Combos
     QAQC_combos_data<-reactive({
       #
       # 0. get "all data"
       #data.frame(data_dt()) # reactive to get all_data()
       myData <- all_data()
       # define desired fields
       myFields <- c("ActivityMediaName", "CharacteristicName", "ResultSampleFractionText"
                     , "USGSPCode", "Unit", "Result")
       # subset to desired fields
       myData4QAQC <- myData[,myFields]
       # summarize with dplyr
       myData.QAQC.Summary <- myData4QAQC %>%
         group_by(ActivityMediaName, CharacteristicName, ResultSampleFractionText, USGSPCode, Unit) %>%
           summarise(n=n(),minObs=min(Result,na.rm=TRUE),maxObs=max(Result,na.rm=TRUE))
      # match with QAQC Decisions
       myFields.data_QAQC <- c("Activity.Media", "Characteristic", "Sample.Fraction"
                               , "PCODE", "Units")
       data_QAQC_temp <- RV_QAQC$df_data
       data_QAQC_temp$MatchQAQC <- TRUE  # add extra field, will be NA for all non-matches
       myData.QAQC.Summary.merge <- merge(myData.QAQC.Summary, data_QAQC_temp[,c(myFields.data_QAQC,"MatchQAQC")]
                                        , by.x=myFields[1:5], by.y=myFields.data_QAQC
                                        , all.x=TRUE)
       # fill in NA values on "match" field
       myData.QAQC.Summary.merge$MatchQAQC[is.na(myData.QAQC.Summary.merge$MatchQAQC)] <- FALSE
              # return data.frame
       return(data.frame(myData.QAQC.Summary.merge))
       #
     })
     #
     # QAQC Combos table
     dt_QAQC_combos_data_caption <- "Summary table of all combinations in 'all data'."
     output$dt_QAQC_combos_data = DT::renderDataTable(DT::datatable(QAQC_combos_data()
                                                                  , caption=dt_QAQC_combos_data_caption
                                                                  , rownames=FALSE
                                                                  , selection='none'
                                                                  # , server=TRUE
                                                                 )
                                                      )

    observeEvent(input$QAQC_CombosAdd, {
      # QAQC Decisions Table = RV_QAQC$df_data
      # QAQC Combos Table = dt_QAQC_combos_data but data is QAQC_combos_data()
      #names(RV_QAQC$df_data)
      #names(df.add)
      # 1.0 
      #Filter combos to new (MatchQAQC==FALSE)
      # 1.1. Rename QAQC_combos_data() to df.add so can munge
      df.add <- QAQC_combos_data()
      # 1.2. Filter for new records and only matching columns
      df.add <- df.add[df.add[,"MatchQAQC"]==FALSE,c(1:5)]
      # 1.3. Add extra columns (so can rbind)
      df.add[,6:14] <- NA
      names(df.add) <- names(RV_QAQC$df_data)
      # 1.4. ApplyQAQC column to FALSE
      df.add[,"Apply.QAQC"] <- FALSE
      # 2. Merge data frames
      df.merge <- rbind(RV_QAQC$df_data, df.add)
      # 3. 
      # 3.1. update QAQC decision table
      RV_QAQC$df_data <- df.merge
      # 3.2. reload QAQC Decisions table on screen
      DT::replaceData(proxy_dt_QAQC, RV_QAQC$df_data, resetPaging=TRUE, rownames=FALSE)
      # do not need to mark all entries in this table QAQC_combos_data().  Autoupdates since is a reactive table.
      #
    })
    
    
    # Tt Mod, Save QAQC as Applied to Various data sets ####
    # Save QAQC as Applied to data()
    output$SaveQAQCApply_data <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".tsv")}
      , content = function(file) {

        # Run code in dataQAQC.R to update ALL DATA with QAQC Decisions
        #df.all.applyQAQC <-  ApplyQAQCDecisions()
        #
        #~~~~~~~~~~~~~~~~~~
        #
        df.data <- data() #not all_data() or data()
        df.QAQC <- RV_QAQC$df_data #data_QAQC
        #
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # *** TESTING ***
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
        # df.QAQC <- XLConnect::readWorksheetFromFile(strFile, sheet="Methods Table", startRow=6, header=TRUE) #, drop=c(1,2))
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_Data_20170804_081355_multipleParam.rds")
        # df.data <- readRDS(strFile)
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        # 1. Prep Sample Data
        #{
        # create merge key
        d # create merge key
        df.data$mergeKey <- with(df.data, paste(ActivityMediaName, CharacteristicName,
                                                ResultSampleFractionText, USGSPCode,
                                                ResultMeasure.MeasureUnitCode,sep="|"))
        # # rename some variables to *.orig
        # data.table::setnames(df.merge, old = c("CharacteristicName", "Units", "ResultSampleFractionText"),
        #                      new = c("CharacteristicName.orig", "Units.orig", "ResultSampleFractionText.orig"))
        flds.old <- c("CharacteristicName", "ResultMeasure.MeasureUnitCode", "ResultSampleFractionText")
        flds.new <- paste0(flds.old,".orig")
        df.data[,flds.new] <- df.data[,flds.old]
        #}
        #
        # 2. Prep QAQC Data
        #{
        # create merge key
        df.QAQC$mergeKey <- with(df.QAQC, paste(Activity.Media, Characteristic,
                                                Sample.Fraction, PCODE,
                                                Units,sep="|"))
        # identify list of variables to merge into with sample data
        df.QAQCvars <- c("Apply.QAQC", "Characteristic", "Units", "Units.Conv.Mult",
                         "Sample.Fraction.QAQC", "QC.Min", "QC.Max", "mergeKey")
        #}
        #
        # 3. Merge Data
        # apply range check, unit conversion, and fill in.
        #{
        # do merge where df.QAQC$ApplyQAQC == TRUE and only merge in variables listed in df.QAQCvars
        df.merge <- merge (df.data, df.QAQC[df.QAQC[,"Apply.QAQC"], df.QAQCvars], by="mergeKey", all.x=TRUE)
        #~~~
        # Test Join instead of Merge
        # x<-NULL
        # x <- dplyr::left_join(df.merge, df.QAQC[df.QAQC$apply, df.QAQCvars], by="mergeKey")
        # dim(x)
        #~~~~
        
        # drop merge key
        df.merge <- df.merge[,!(names(df.merge) %in% c("mergeKey"))]
        # identify cases where data are outside qc range (do this before unit conversion because
        # the ranges in the df.QAQC are based on the original units)
        df.merge$qcRange <- FALSE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Min) & df.merge$ResultMeasureValue < df.merge$QC.Min, "qcRange"]<-TRUE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Max) & df.merge$ResultMeasureValue > df.merge$QC.Max, "qcRange"]<-TRUE
        # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
        # i create a numeric conversion field but suppress warnings to not alarm user
        df.merge$Units.Conv.Mult <- suppressWarnings(as.numeric(df.merge$Units.Conv.Mult))
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult),
                                                   df.merge$ResultMeasureValue      * df.merge$Units.Conv.Mult, df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult),
                                       df.merge$ResultLower * df.merge$Units.Conv.Mult, df.merge$ResultLower)
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult),
                                       df.merge$ResultUpper * df.merge$Units.Conv.Mult, df.merge$ResultUpper)
        # apply special case unit conversion (Deg F to Deg C)
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                                   (df.merge$ResultMeasureValue      - 32) * (5/9) , df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                       (df.merge$ResultLower - 32) * (5/9) , df.merge$ResultLower     )
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                       (df.merge$ResultUpper - 32) * (5/9) , df.merge$ResultUpper     )
        # handle those cases where df.QAQC was not merged in (i.e., either df.QAQC$apply==FALSE or
        # there was no record to process
        df.merge[is.na(df.merge$Apply.QAQC), "apply" ] <- FALSE
        df.merge$CharacteristicName <- ifelse(df.merge$Apply.QAQC, df.merge$CharacteristicName, df.merge$CharacteristicName.orig)
        df.merge$Units           <- ifelse(df.merge$Apply.QAQC, df.merge$Units          , df.merge$Unit.orig          )
        df.merge$ResultSampleFractionText <- ifelse(df.merge$Apply.QAQC, df.merge$ResultSampleFractionText, df.merge$ResultSampleFractionText.orig)
        # drop non essential variables (Tt-JBH: dont implement till after testing)
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))]
        #
        # # Reorder columns (merge puts the 'by' fields at the beginning)
        # NameOrder <- c(names(df.data), names(df.merge)[!(names(df.merge) %in% names(df.data))])
        # NameOrder2 <- names(df.merge)[!NameOrder %in% names(df.merge)]
        # df.merge <- df.merge[,NameOrder2]
        #}
        
        
        # 4. Return df
        # return(df.merge) # before changed format of reactive
        #
        # 4. Save modified data (so can load later)
        QAQC_Apply_datapath <- file.path(getwd(),file)
        # cat(QAQC_Apply_datapath)
        # flush.console()
        #
        # QC
        # names(data()) %in% names(df.merge)
        # names(df.merge) %in% names(data())
        
        ##saveRDS(data(),file) # QC check
        #saveRDS(df.merge,file)
        write.table(df.merge, file, row.names = FALSE, col.names = FALSE, sep = "\t")
        #write.csv(df.merge, file)
        #
      }
    )
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Save QAQC as Applied to filtered_data()
    output$SaveQAQCApply_filtered_data <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".tsv")}
      , content = function(file) {
        
        # Run code in dataQAQC.R to update ALL DATA with QAQC Decisions
        #df.all.applyQAQC <-  ApplyQAQCDecisions()
        #
        #~~~~~~~~~~~~~~~~~~
        #
        df.data <- filtered_data() #not all_data() or data()
        df.QAQC <- RV_QAQC$df_data #data_QAQC
        #
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # *** TESTING ***
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
        # df.QAQC <- XLConnect::readWorksheetFromFile(strFile, sheet="Methods Table", startRow=6, header=TRUE) #, drop=c(1,2))
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_Data_20170804_081355_multipleParam.rds")
        # df.data <- readRDS(strFile)
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        # 1. Prep Sample Data
        #{
        # create merge key
        df.data$mergeKey <- with(df.data, paste(ActivityMediaName, CharacteristicName,
                                                ResultSampleFractionText, USGSPCode,
                                                ResultMeasure.MeasureUnitCode,sep="|"))
        # # rename some variables to *.orig
        # data.table::setnames(df.merge, old = c("CharacteristicName", "Units", "ResultSampleFractionText"),
        #                      new = c("CharacteristicName.orig", "Units.orig", "ResultSampleFractionText.orig"))
        flds.old <- c("CharacteristicName", "ResultMeasure.MeasureUnitCode", "ResultSampleFractionText")
        flds.new <- paste0(flds.old,".orig")
        df.data[,flds.new] <- df.data[,flds.old]
        #}
        #
        # 2. Prep QAQC Data
        #{
        # create merge key
        df.QAQC$mergeKey <- with(df.QAQC, paste(Activity.Media, Characteristic,
                                                Sample.Fraction, PCODE,
                                                Units,sep="|"))
        # identify list of variables to merge into with sample data
        df.QAQCvars <- c("Apply.QAQC", "Characteristic", "Units", "Units.Conv.Mult",
                         "Sample.Fraction.QAQC", "QC.Min", "QC.Max", "mergeKey")
        #}
        #
        # 3. Merge Data
        # apply range check, unit conversion, and fill in.
        #{
        # do merge where df.QAQC$ApplyQAQC == TRUE and only merge in variables listed in df.QAQCvars
        df.merge <- merge (df.data, df.QAQC[df.QAQC[,"Apply.QAQC"], df.QAQCvars], by="mergeKey", all.x=TRUE)
        #~~~
        # Test Join instead of Merge
        # x<-NULL
        # x <- dplyr::left_join(df.merge, df.QAQC[df.QAQC$apply, df.QAQCvars], by="mergeKey")
        # dim(x)
        #~~~~
        
        # drop merge key
        df.merge <- df.merge[,!(names(df.merge) %in% c("mergeKey"))]
        # identify cases where data are outside qc range (do this before unit conversion because
        # the ranges in the df.QAQC are based on the original units)
        df.merge$qcRange <- FALSE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Min) & df.merge$ResultMeasureValue < df.merge$QC.Min, "qcRange"]<-TRUE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Max) & df.merge$ResultMeasureValue > df.merge$QC.Max, "qcRange"]<-TRUE
        # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
        # i create a numeric conversion field but suppress warnings to not alarm user
        df.merge$Units.Conv.Mult <- suppressWarnings(as.numeric(df.merge$Units.Conv.Mult))
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult),
                                                  df.merge$ResultMeasureValue      * df.merge$Units.Conv.Mult, df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult),
                                      df.merge$ResultLower * df.merge$Units.Conv.Mult, df.merge$ResultLower)
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult),
                                      df.merge$ResultUpper * df.merge$Units.Conv.Mult, df.merge$ResultUpper)
        # apply special case unit conversion (Deg F to Deg C)
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                                  (df.merge$ResultMeasureValue      - 32) * (5/9) , df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                      (df.merge$ResultLower - 32) * (5/9) , df.merge$ResultLower     )
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                      (df.merge$ResultUpper - 32) * (5/9) , df.merge$ResultUpper     )
        # handle those cases where df.QAQC was not merged in (i.e., either df.QAQC$apply==FALSE or
        # there was no record to process
        df.merge[is.na(df.merge$Apply.QAQC), "apply" ] <- FALSE
        df.merge$CharacteristicName <- ifelse(df.merge$Apply.QAQC, df.merge$CharacteristicName, df.merge$CharacteristicName.orig)
        df.merge$Units           <- ifelse(df.merge$Apply.QAQC, df.merge$Units          , df.merge$Unit.orig          )
        df.merge$ResultSampleFractionText <- ifelse(df.merge$Apply.QAQC, df.merge$ResultSampleFractionText, df.merge$ResultSampleFractionText.orig)
        # drop non essential variables (Tt-JBH: dont implement till after testing)
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))]
        #
        # # Reorder columns (merge puts the 'by' fields at the beginning)
        # NameOrder <- c(names(df.data), names(df.merge)[!(names(df.merge) %in% names(df.data))])
        # NameOrder2 <- names(df.merge)[NameOrder %in% names(df.merge)]
        # df.merge <- df.merge[,NameOrder2]
        #}
        
        
        # 4. Return df
        # return(df.merge) # before changed format of reactive
        #
        # 4. Save modified data (so can load later)
        QAQC_Apply_datapath <- file.path(getwd(),file)
        # cat(QAQC_Apply_datapath)
        # flush.console()
        #
        # QC
        # names(data()) %in% names(df.merge)
        # names(df.merge) %in% names(data())
        
        ##saveRDS(data(),file) # QC check
        #saveRDS(df.merge,file)
        write.table(df.merge, file, row.names = FALSE, col.names = FALSE, sep = "\t")
        #write.csv(df.merge, file)
        #
      }
    )
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Save QAQC as Applied to Map Table Data()
    output$SaveQAQCApply_MapTable_data <- downloadHandler(
      filename = function() {
        strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".tsv")}
      , content = function(file) {
        
        # Run code in dataQAQC.R to update ALL DATA with QAQC Decisions
        #df.all.applyQAQC <-  ApplyQAQCDecisions()
        #
        #~~~~~~~~~~~~~~~~~~
        #
        df.data <- dat_display() #not all_data() or data()
        df.QAQC <- RV_QAQC$df_data #data_QAQC
        #
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # *** TESTING ***
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
        # df.QAQC <- XLConnect::readWorksheetFromFile(strFile, sheet="Methods Table", startRow=6, header=TRUE) #, drop=c(1,2))
        # strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_Data_20170804_081355_multipleParam.rds")
        # df.data <- readRDS(strFile)
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        # 1. Prep Sample Data
        #{
        # create merge key
        df.data$mergeKey <- with(df.data, paste(ActivityMediaName, CharacteristicName,
                                                ResultSampleFractionText, USGSPCode,
                                                ResultMeasure.MeasureUnitCode,sep="|"))
        # # rename some variables to *.orig
        # data.table::setnames(df.merge, old = c("CharacteristicName", "Units", "ResultSampleFractionText"),
        #                      new = c("CharacteristicName.orig", "Units.orig", "ResultSampleFractionText.orig"))
        flds.old <- c("CharacteristicName", "ResultMeasure.MeasureUnitCode", "ResultSampleFractionText")
        flds.new <- paste0(flds.old,".orig")
        #df.data[,flds.new] <- df.data[,flds.old] #DT so fails
        for (i in 1:length(flds.old)){##FOR.i.START
          df.data[,flds.new[i]] <- df.data[,flds.old[i]]
        }##FOR.i.END
        #}
        #
        # 2. Prep QAQC Data
        #{
        # create merge key
        df.QAQC$mergeKey <- with(df.QAQC, paste(Activity.Media, Characteristic,
                                                Sample.Fraction, PCODE,
                                                Units,sep="|"))
        # identify list of variables to merge into with sample data
        df.QAQCvars <- c("Apply.QAQC", "Characteristic", "Units", "Units.Conv.Mult",
                         "Sample.Fraction.QAQC", "QC.Min", "QC.Max", "mergeKey")
        #}
        #
        # 3. Merge Data
        # apply range check, unit conversion, and fill in.
        #{
        # do merge where df.QAQC$ApplyQAQC == TRUE and only merge in variables listed in df.QAQCvars
        df.merge <- merge (df.data, df.QAQC[df.QAQC[,"Apply.QAQC"], df.QAQCvars], by="mergeKey", all.x=TRUE)
        #~~~
        # Test Join instead of Merge
        # x<-NULL
        # x <- dplyr::left_join(df.merge, df.QAQC[df.QAQC$apply, df.QAQCvars], by="mergeKey")
        # dim(x)
        #~~~~
        
        # drop merge key
        df.merge <- df.merge[,!(names(df.merge) %in% c("mergeKey"))]
        # identify cases where data are outside qc range (do this before unit conversion because
        # the ranges in the df.QAQC are based on the original units)
        df.merge$qcRange <- FALSE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Min) & df.merge$ResultMeasureValue < df.merge$QC.Min, "qcRange"]<-TRUE
        df.merge[!is.na(df.merge$ResultMeasureValue) & !is.na(df.merge$QC.Max) & df.merge$ResultMeasureValue > df.merge$QC.Max, "qcRange"]<-TRUE
        # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
        # i create a numeric conversion field but suppress warnings to not alarm user
        df.merge$Units.Conv.Mult <- suppressWarnings(as.numeric(df.merge$Units.Conv.Mult))
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult),
                                                   df.merge$ResultMeasureValue      * df.merge$Units.Conv.Mult, df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult),
                                       df.merge$ResultLower * df.merge$Units.Conv.Mult, df.merge$ResultLower)
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult),
                                       df.merge$ResultUpper * df.merge$Units.Conv.Mult, df.merge$ResultUpper)
        # apply special case unit conversion (Deg F to Deg C)
        df.merge$ResultMeasureValue      <- ifelse(!is.na(df.merge$ResultMeasureValue     ) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                                   (df.merge$ResultMeasureValue      - 32) * (5/9) , df.merge$ResultMeasureValue     )
        df.merge$ResultLower <- ifelse(!is.na(df.merge$ResultLower) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                       (df.merge$ResultLower - 32) * (5/9) , df.merge$ResultLower     )
        df.merge$ResultUpper <- ifelse(!is.na(df.merge$ResultUpper) & !is.na(df.merge$Units.Conv.Mult) & df.merge$Units.Conv.Mult == "F_to_C" ,
                                       (df.merge$ResultUpper - 32) * (5/9) , df.merge$ResultUpper     )
        # handle those cases where df.QAQC was not merged in (i.e., either df.QAQC$apply==FALSE or
        # there was no record to process
        df.merge[is.na(df.merge$Apply.QAQC), "apply" ] <- FALSE
        df.merge$CharacteristicName <- ifelse(df.merge$Apply.QAQC, df.merge$CharacteristicName, df.merge$CharacteristicName.orig)
        df.merge$Units           <- ifelse(df.merge$Apply.QAQC, df.merge$Units          , df.merge$Unit.orig          )
        df.merge$ResultSampleFractionText <- ifelse(df.merge$Apply.QAQC, df.merge$ResultSampleFractionText, df.merge$ResultSampleFractionText.orig)
        # drop non essential variables (Tt-JBH: dont implement till after testing)
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
        #Tt-JBH df.merge <- df.merge[,!(names(df.merge) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))]
        #
        # # Reorder columns (merge puts the 'by' fields at the beginning)
        # NameOrder <- c(names(df.data), names(df.merge)[!(names(df.merge) %in% names(df.data))])
        # NameOrder2 <- names(df.merge)[NameOrder %in% names(df.merge)]
        # df.merge <- df.merge[,NameOrder2]
        #}
        
        
        # 4. Return df
        # return(df.merge) # before changed format of reactive
        #
        # 4. Save modified data (so can load later)
        QAQC_Apply_datapath <- file.path(getwd(),file)
        # cat(QAQC_Apply_datapath)
        # flush.console()
        #
        # QC
        # names(data()) %in% names(df.merge)
        # names(df.merge) %in% names(data())
        
        ##saveRDS(data(),file) # QC check
        #saveRDS(df.merge,file)
        write.table(df.merge, file, row.names = FALSE, col.names = FALSE, sep = "\t")
        #write.csv(df.merge, file)
        #
      }
    )
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
    # Clear out import modal for each launch - This needs work 11/2/2015
    val<-reactiveValues( display = NULL, display2 = NULL, data = NULL)
    observeEvent(input$CHECK, {
      val$display<-"no"
      val$data<-NULL
      val$display2<-"no"
    })

    observeEvent(input$IMPORT, {
      val$display2<- "yes"
    })

    output$Display<-renderText({ val$display })
    outputOptions(output, 'Display', suspendWhenHidden=FALSE)
    output$Display2<-renderText({ val$display2 })
    outputOptions(output, 'Display2', suspendWhenHidden=FALSE)
    
    success<-reactive({
      if(RECORDS()>0 & dim(data())[1]>0){
        return("yes")
      }else{
        return("no")
      }
    })  
    output$data_check<-renderText({
      success()
    })
    outputOptions(output, 'data_check', suspendWhenHidden=FALSE)

  ### Begin server for Check Data Tab Panel
  # Adding a reactive to filter the data and provide the final dataset to be displayed in the data table and map
  # Using the data.table package for fast manipulations but re-converting to a data frame since the DT package requires this
    data_dt <- reactive({
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # Tt Mod, all_data ####
      # use default data unless a data file has been loaded.
      # if(is.null(input$LoadAppData)) {
        # default data
        data2 <- data.table(data())
        datatt <- attr(data(), "siteInfo")
        datatt<-unique(datatt[, c("MonitoringLocationIdentifier","MonitoringLocationName","LatitudeMeasure", "LongitudeMeasure")])
        data2<-merge(data2, datatt, 
                     by = "MonitoringLocationIdentifier", all.x = T)
        data2[is.na(ResultMeasure.MeasureUnitCode), ResultMeasure.MeasureUnitCode := DetectionQuantitationLimitMeasure.MeasureUnitCode]
        setnames(data2, c("MonitoringLocationIdentifier", "MonitoringLocationName","OrganizationIdentifier", "CharacteristicName", "ResultMeasureValue", 
                          "ResultMeasure.MeasureUnitCode", "ResultAnalyticalMethod.MethodName", "ResultAnalyticalMethod.MethodIdentifier"), 
                 c("Station", "Name","Organization", "Characteristic","Result", "Unit", "Method", "Method_ID"))
        data2[, Result := as.numeric(as.character(Result))]
        data2[, Station := as.factor(Station)]
        data2[, Name := as.factor(Name)]
        data2[, Organization := as.factor(Organization)]
        data2[, Characteristic := as.factor(Characteristic)]
        data2[, Unit := as.factor(Unit)]
        data2[, Method := as.factor(Method)]
        data2[, Method_ID := as.factor(as.character(Method_ID))]
        # put non detect method logic here
        if(input$ND_method==2){
          data2[ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantification Limit'), ':=' (Result = 0, 
                                                                                                                 Unit = DetectionQuantitationLimitMeasure.MeasureUnitCode)]
        } else if(input$ND_method == 3){
          data2[ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantification Limit'), ':=' (Result = DetectionQuantitationLimitMeasure.MeasureValue, 
                                                                                                                 Unit = DetectionQuantitationLimitMeasure.MeasureUnitCode)]
        } else if(input$ND_method ==4){
          data2[ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantification Limit'), ':=' (Result = 0.5*(DetectionQuantitationLimitMeasure.MeasureValue), 
                                                                                                                 Unit = DetectionQuantitationLimitMeasure.MeasureUnitCode)]
        }
        
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # Tt Mod, data, extra fields ####
        #Add extra fields so have original names (may remove later)
        # data2[,"LatitudeMeasure"]           <- data2[,"Latitude"]
        # data2[,"LongitudeMeasure"]           <- data2[,"Longitude"]
        data2[,"MonitoringLocationIdentifier"] <- data2[,"Station"]
        data2[,"OrganizationIdentifier"]       <- data2[,"Organization"]
        data2[,"CharacteristicName"]           <- data2[,"Characteristic"]
        data2[,"ResultMeasureValue"]           <- data2[,"Result"]
        data2[,"ResultMeasure.MeasureUnitCode"]           <- data2[,"Unit"]
        data2[,"ResultAnalyticalMethod.MethodIdentifier"] <- data2[,"Method_ID"]
        data2[,"ResultAnalyticalMethod.MethodName"]       <- data2[,"Method"]
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        return(data2)
        
      # } else {
      #   # Get Import File specs
      #   q <- input$LoadAppData
      #   # Error check
      #   if(is.null(q)) return(NULL)
      #   # Import Data
      #   data_load <- read.delim(q$datapath, skip=10)
      #   #data_load <- readRDS(q$datapath)
      #   data.frame(data_load)
      #   # need to parse URL at this point
      #   return(data_load)
      #   
      # }
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    })
    all_data<-reactive({
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # # Tt Mod, all_data ####
      # # use default data unless a data file has been loaded.
      # if(is.null(input$LoadAppData)) {
      #   # default data
         data.frame(data_dt())
      # } else {
      #   # Get Import File specs
      #   q <- input$LoadAppData
      #   # Error check
      #   if(is.null(q)) return(NULL)
      #   # Import Data
      #   data_load <- read.delim(q$datapath, skip=10)
      #   #data_load <- readRDS(q$datapath)
      #   data.frame(data_load)
      #   # need to parse URL at this point

      #}
      #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
    })
    
  output$All_Data = DT::renderDataTable(
  all_data()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
  extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                         pageLength = 100,
                                         lengthMenu = c(100, 200, 500),
                                         columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
  ), server = TRUE)
outputOptions(output, 'All_Data', suspendWhenHidden=TRUE)

    # Generating a character string for the method of non_detects 
    non_detect_method <- reactive({
        method <- switch(input$ND_method,
                         '1' = "Non-Detections removed from data set",
                         '2' = "Non-Detections set equal to zero",
                         '3' = "Non-Detections set equal to the Limit of Detection",
                         '4' = "Non-Detections set equal to the 1/2 times the Limit of Detection")
        return(method)
    })
    
 
    
    meta_gen_alldata <- reactive({
        data <- all_data()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "All data")
        metaurl <- data.table(x = "URL:", y = NA) #url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metaorg <- data.table(x = "Number of organizations:", y = length(unique(data$Organization)))
        metastat <- data.table(x = "Number of stations:", y = length(unique(data$Station)))
        metaparam <- data.table(x = 'Number of characteristics:', y = length(unique(data$Characteristic)))
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metaorg, metastat, metaparam, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_data1 <- downloadHandler(
        filename = function() {
            paste('All_data-', Sys.Date(), '.tsv', sep='')
        },
        content = function(con) {
           write.table(meta_gen_alldata(), con, row.names = F, col.names = FALSE, sep = "\t")
           write.table(all_data(), con, row.names = F, sep = "\t", append = TRUE)
        })
    
    duplicate_logic<-reactive({
      fields<-names(data_dt())
      fields[fields != "ActivityIdentifier"]
      fields[fields != "ActivityTypeCode"]
      return(duplicated(data_dt(), by = fields)) #creates a logical vector
    })
    method_logic<-reactive({ # create logical vector identifying data w/o methods
      !data_dt()$ActivityTypeCode %in% c('Field Msr/Obs', 'Field Msr/Obs-Habitat Assessment', 'Field Msr/Obs-Incidental',
                                                'Field Msr/Obs-Portable Data Logger', 'Quality Control Field Calibration Check',
                                                'Quality Control Field Replicate Habitat Assessment', 'Quality Control Field Replicate Msr/Obs',
                                                'Quality Control Field Replicate Portable Data Logger', 'Quality Control Field Sample Equipment Rinsate Blank',
                                                'Quality Control Sample-Lab Control Sample/Blank Spike', 'Quality Control Sample-Lab Control Sample/Blank Spike Duplicate',
                                                'Quality Control Sample-Lab Matrix Spike Duplicate', 'Quality Control Sample-Lab Spike of a Lab Blank',
                                                'Sample-Depletion Replicate') &
      data_dt()$Method_ID == ""
    })

    filtered_data<-reactive({
      if(input$ND_method==1){
        data.frame(data_dt()[!duplicate_logic()&
                               Unit != "" &
                               !method_logic() &
                               !ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantititation Limit')])
      } else {
        data.frame(data_dt()[!duplicate_logic()&
                               Unit != "" &
                               !method_logic()])
      }})
    output$Filtered = DT::renderDataTable(
      filtered_data()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
      extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                             pageLength = 100,
                                             lengthMenu = c(100, 200, 500),
                                             columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
      ), server = TRUE)
    outputOptions(output, 'Filtered', suspendWhenHidden=TRUE)
    
    meta_gen_filtered <- reactive({
        data <- filtered_data()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Filtered data")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_data6 <- downloadHandler(
      filename = function() {
        paste('Filtered_data-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_filtered(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(filtered_data(), con, row.names = F, sep = "\t", append = TRUE)
      })    
    no_units<-reactive({
      data.frame(data_dt()[Unit == "" & !ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantitation Limit')])
    })
    output$NO_UNITS = DT::renderDataTable(
      no_units()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
      extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                             pageLength = 100,
                                             lengthMenu = c(100, 200, 500),
                                             columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
      ), server = TRUE)
    outputOptions(output, 'NO_UNITS', suspendWhenHidden=TRUE)
    
    meta_gen_no_units <- reactive({
        data <- no_units()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Records with no units")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    
    output$Save_data3 <- downloadHandler(
      filename = function() {
        paste('Missing_Units-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_no_units(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(no_units(), con, row.names = F, sep = "\t", append = TRUE)
      })
    
    no_methods<-reactive({
      data.frame(data_dt()[!ActivityTypeCode %in% c('Field Msr/Obs', 'Field Msr/Obs-Habitat Assessment', 'Field Msr/Obs-Incidental',
                                               'Field Msr/Obs-Portable Data Logger', 'Quality Control Field Calibration Check',
                                               'Quality Control Field Replicate Habitat Assessment', 'Quality Control Field Replicate Msr/Obs',
                                               'Quality Control Field Replicate Portable Data Logger', 'Quality Control Field Sample Equipment Rinsate Blank',
                                               'Quality Control Sample-Lab Control Sample/Blank Spike', 'Quality Control Sample-Lab Control Sample/Blank Spike Duplicate',
                                               'Quality Control Sample-Lab Matrix Spike Duplicate', 'Quality Control Sample-Lab Spike of a Lab Blank',
                                               'Sample-Depletion Replicate') &
                             Method_ID == ""])
    })
    output$NO_METH = DT::renderDataTable(
      no_methods()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
      extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                             pageLength = 100,
                                             lengthMenu = c(100, 200, 500),
                                             columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
      ), server = TRUE)
    outputOptions(output, 'NO_METH', suspendWhenHidden=TRUE)
    
    meta_gen_no_methods <- reactive({
        data <- no_methods()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Records with no methods")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_data4 <- downloadHandler(
      filename = function() {
       paste('Missing_Methods-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_no_methods(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(no_methods(), con, row.names = F, sep = "\t", append = TRUE)
      })
    duplicates<-reactive({
      data.frame(data_dt()[duplicate_logic()])
    })
    output$DUPS = DT::renderDataTable(
      duplicates()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
      extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                             pageLength = 100,
                                             lengthMenu = c(100, 200, 500),
                                             columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
     ), server = TRUE)
    outputOptions(output, 'DUPS', suspendWhenHidden=TRUE)
    
    meta_gen_duplicates <- reactive({
        data <- duplicates()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Duplicate records")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_data5 <- downloadHandler(
      filename = function() {
        paste('Duplicates-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_duplicates(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(duplicates(), con, row.names = F, sep = "\t", append = TRUE)
     })
    non_detects<-reactive({
      data.frame(data_dt()[ResultDetectionConditionText %in% c('Not Detected', 'Present Below Quantification Limit')])
    })
    output$ND_Table = DT::renderDataTable(
      non_detects()[, display, drop=FALSE],  escape = -1, rownames = FALSE,
      extensions = 'Buttons', options = list(dom = 'lfrBtip', buttons = I('colvis'), 
                                             pageLength = 100,
                                             lengthMenu = c(100, 200, 500),
                                             columnDefs = list(list(visible =  F, targets = list(5,6,7,8)))
      ), server = TRUE)
    outputOptions(output, 'ND_Table', suspendWhenHidden=TRUE)
    
    meta_gen_non_detects <- reactive({
        data <- non_detects()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Non Detects")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_data2 <- downloadHandler(
      filename = function() {
        paste('Non_Detects-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_non_detects(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(non_detects(), con, row.names = F, sep = "\t", append = TRUE)
      })
    
    summarized<-eventReactive(input$SUMMARY, {
      withProgress(message = 'Summarizing Data',
                   detail = 'This may take a while...', value = 0, {
                     for (i in 1:15) {
                       incProgress(1/15)
                       Sys.sleep(0.25)
                       #return() # this is shortening the time to return the header info
                     }
                   })
      return(data.frame(data_dt()[,.(Minimum = min(Result, na.rm = TRUE), Maximum = max(Result, na.rm = TRUE), Average= mean(Result, na.rm = TRUE), Count = .N),
                                  by = c("Station", "Name", "ActivityMediaName", "Characteristic", "Unit", "ResultSampleFractionText" )]))
    })

    summ_success<-reactive({
      if(dim(summarized())[1]>0){
        return("yes")
      }else{
        return("no")
      }
    })  
    output$Summ_run<-renderText({
      summ_success()
    })
    outputOptions(output, 'Summ_run', suspendWhenHidden=FALSE)
    output$SUMMARIZED<-DT::renderDataTable(
      summarized(), escape = -1, rownames =FALSE, options=list(iDisplayLength = 50))
    outputOptions(output, 'SUMMARIZED', suspendWhenHidden = FALSE)
    
    meta_gen_summarized <- reactive({
        data <- summarized()
        metadate <- data.table(x = "Date:", y = paste(Sys.time()))
        metadata <- data.table(x = "Dataset:", y = "Summary data")
        metaurl <- data.table(x = "URL:", y = url_display())
        metanondet <- data.table(x = "Method for non-detects:", y = non_detect_method())
        metastat <- data.table(x = "Number of stations:", y = length(unique(data$Station)))
        metaparam <- data.table(x = 'Number of characteristics:', y = length(unique(data$Characteristic)))
        metarec <- data.table(x = "Number of records:", y = nrow(data))
        metabr <- data.table(x = "", y = "")
        metabr2 <- data.table(x = "---------------------------------------", y = "")
        
        meta <- rbind(metadate,metadata,metaurl,metanondet, metastat, metaparam, metarec, metabr, metabr2)
        
        return(meta)
    })
    
    output$Save_Summary_Data <- downloadHandler(
      filename = function() {
        paste('Summary_Data-', Sys.Date(), '.tsv', sep='')
      },
      content = function(con) {
          write.table(meta_gen_summarized(), con, row.names = F, col.names = FALSE, sep = "\t")
          write.table(summarized(), con, row.names = F, sep = "\t", append = TRUE)
      })
   output$check1 <- renderUI({
      data<-data.table(data_dt())
      stations<-length(unique(data$Station))
      parameters<-length(unique(data$Characteristic))
      h4("The total imported data set contains ", span(as.numeric(nrow(data_dt())), style = "font-weight: bold"), " records from", 
        span(stations, style = "font-weight: bold")," stations representing",
        span(parameters, style = "font-weight: bold"), "parameters with,",
        span(as.numeric(nrow(non_detects())), style = "font-weight: bold"), " non-detects.",
        span(as.numeric(nrow(no_units())), style = "font-weight: bold"), "records without units",
        span(as.numeric(nrow(no_methods())), style = "font-weight: bold"), "records without methods",
        span(as.numeric(nrow(duplicates())), style = "font-weight: bold"), "duplicate records")
    })
output$home_query<-renderUI({
  h5(span(url_display()), style = "text-align: center")
})
output$home_date<-renderUI({
  fluidRow(h5("Date: ", span(paste(Sys.time())), style = "text-align: center"))
})
##############################  View Data tab  #############################################
############################# Side Panel - View Data tab ###################################
##Create a single filtered Data Set that feeds the map, table and station summary charts
  spfilter_dat <- eventReactive (input$submit_filters, {
    data <- data.table(filtered_data())
   if(!is.null(input$org)) {
       data <- data[OrganizationFormalName %in% input$org]
   }
   if(!is.null(input$stt)) {
       data <- data[Name %in% input$stt]
   }
   if(!is.null(input$fmedia)) {
     data <- data[ActivityMediaName %in% input$fmedia]
   }
   if(!is.null(input$ffrac)) {
     data <- data[ResultSampleFractionText %in% input$ffrac]
   }
   if(!is.null(input$param)) {
       data <- data[Characteristic %in% input$param]
   }
   if(!is.null(input$sidepanelunit)) {
       data <- data[Unit %in% input$sidepanelunit]
   }
   if(!is.null(input$sidepanelmethod)) {
       data <- data[Method %in% input$sidepanelmethod]
   }
   if(!is.null(input$fqual)) {
     data <- data[MeasureQualifierCode %in% input$fqual]
   }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## Tt Mod, ViewData, Filters ####
    if(!is.null(input$facttype)) {
      data <- data[ActivityTypeCode %in% input$facttype]
    }
    if(!is.null(input$fequip)) {
      data <- data[SampleCollectionEquipmentName %in% input$fequip]
    }
    if(!is.null(input$fstatusid)) {
      data <- data[ResultStatusIdentifier %in% input$fstatusid]
    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
   if(!is.null(input$minvalue)) {
       data <- data[Result >= input$minvalue & Result <= input$maxvalue]
   }
   return(data)
  })

  test<-eventReactive (input$submit_filters, {
    data <- data.table(spfilter_dat())
    data<-data[ActivityStartDate>as.Date(as.character(input$spdate[1])) & ActivityStartDate<as.Date(as.character(input$spdate[2]))]
    })
  ## Create the data for the map from the filtered data
map_df <- reactive ({
  if(input$submit_filters==0){
    dat<-data.table(filtered_data())
    data_sum<-dat[,.(.N, Name = first(Name), LatitudeMeasure = first(LatitudeMeasure), LongitudeMeasure = first(LongitudeMeasure),
                     Samples = length(unique(ActivityIdentifier))), by = "Station"]
    data <- as.data.frame(data_sum)
    return(data)
  } else if(val$display2=="no"){
    dat<-data.table(filtered_data())
    data_sum<-dat[,.(.N, Name = first(Name), LatitudeMeasure = first(LatitudeMeasure), LongitudeMeasure = first(LongitudeMeasure),
                     Samples = length(unique(ActivityIdentifier))), by = "Station"]
    data <- as.data.frame(data_sum)
    return(data)
  } else {
    data_sum<-test()[,.(.N, Name = first(Name), LatitudeMeasure = first(LatitudeMeasure), LongitudeMeasure = first(LongitudeMeasure),
                        Samples = length(unique(ActivityIdentifier))), by = "Station"]
    data <- as.data.frame(data_sum)
    return(data)
  } 
})
######################################################################
## Filters
#####################################################################
output$sporg <- renderUI({
    data <- data.table(filtered_data())
    fluidRow(
        selectizeInput('org', h4("  Select organization:"),
                       choices = unique(data[, as.character(OrganizationFormalName)]),
                       multiple = TRUE,
                       selected = if(input$org_sel==1){
                         unique(data[, as.character(OrganizationFormalName)])
                         } else {NULL})
        
        )
})

output$spstation <- renderUI({
  data <- data.table(filtered_data())
  
  if(is.null(input$org)){
    data <- data
  } else {
    data <- data[OrganizationFormalName %in% input$org]
  }
    fluidRow(
        selectizeInput('stt', h4("  Select station:"),
                       choices = unique(data[, as.character(Name)]),
                       multiple = TRUE,
                       selected = if(input$stat_sel==1){
                         unique(data[, as.character(Name)])
                       } else {NULL})
    )
})

output$spmedia <- renderUI({
  data <- data.table(filtered_data())
  fluidRow(
    selectizeInput('fmedia', h4("  Select Sample Media:"),
                   choices = unique(data[, as.character(ActivityMediaName)]),
                   multiple = TRUE,
                   selected = if(input$media_sel==1){
                     unique(data[, as.character(ActivityMediaName)])
                   } else {NULL})
  )
})

output$spfraction <- renderUI({
  data <- data.table(filtered_data())
  fluidRow(if(length(unique(data[, as.character(ResultSampleFractionText)]))<1){
    h5("There are no values for sample fraction in this data set")
  } else {
    selectizeInput('ffrac', h4("  Select Sample Fraction:"),
                   choices = unique(data[, as.character(ResultSampleFractionText)]),
                   multiple = TRUE,
                   selected = if(input$frac_sel==1){
                     unique(data[, as.character(ResultSampleFractionText)])
                   } else {NULL})
  })
})

output$spparam <- renderUI({
    data <- data.table(filtered_data())
    if(is.null(input$stt)) {
      data <- data
    } else {
      data <- data[Name %in% input$stt]
    }
    fluidRow(
        selectizeInput('param', h4("  Select parameter:"),
                       choices = unique(data[, as.character(Characteristic)]),
                       multiple = TRUE,
                       selected = if(input$param_sel==1){
                         unique(data[, as.character(Characteristic)])
                       } else {NULL})
    )
})
    
output$spunit <- renderUI({
    data <- data.table(filtered_data())
    unit <- unique(data[Characteristic %in% input$param, as.character(Unit)])
    
    if(length(unit) > 1) {
        selectizeInput('sidepanelunit', h4(" "),
                                              choices = unit,
                       multiple = TRUE,
                       selected = if(input$unit_sel==1){
                         unit
                       } else {NULL})
    } else {
        p(h5('This station/parameter(s) combination only has one unit'), unit)
    }
})

output$spmethod <- renderUI({
    data <- data.table(filtered_data())
    method <- unique(data[Characteristic %in% input$param, as.character(Method)])
    
    if(length(method) > 1) {
        selectizeInput('sidepanelmethod', h4(" "),
                       choices = method,
                       multiple = TRUE,
                       selected = if(input$method_sel==1){
                         method
                       } else {NULL})
    }else {
        p(h5('This station/parameter/unit(s) combination only has one method'), method)
    }
})
output$spqual <- renderUI({
  data <- data.table(filtered_data())
  fluidRow(if(length(unique(data[, as.character(MeasureQualifierCode)]))>1){
    selectizeInput('fqual', h4("  Select Qualifier Code:"),
                   choices = unique(data[, as.character(MeasureQualifierCode)]),
                   multiple = TRUE,
                   selected = if(input$qual_sel==1){
                     unique(data[, as.character(MeasureQualifierCode)])
                   } else {NULL})
  } else {
    p(h5(paste("There is only one value for Result Measure Qualifier",unique(data[, as.character(MeasureQualifierCode)]), sep=" "))) 
  })
})

output$spvalue <- renderUI({
    data <- data.table(filtered_data())
    fluidRow(column(6,
                    numericInput('minvalue', h5("Minimum:"),
                                 value = min(as.numeric(as.character(filtered_data()$Result)), na.rm = TRUE)
                    )),
             column(6,
                    numericInput('maxvalue', h5("Maximum:"),
                                 value = max(as.numeric(as.character(filtered_data()$Result)), na.rm = TRUE)
                    )),
             bsPopover("minvalue", "Enter Minimum Value", "Do not leave this field blank.  You must enter a minimum value.",
                       "top", trigger = "hover", options = list(container = "body")),
             bsPopover("maxvalue", "Enter Maximum Value", "Do not leave this field blank.  You must enter a maximum value.",
                       "top", trigger = "hover", options = list(container = "body")))
    
})
observe({
  updateDateRangeInput(session, "spdate",
                       start = min(filtered_data()$ActivityStartDate, na.rm = TRUE),
                       end = max(filtered_data()$ActivityStartDate, na.rm = TRUE))
})
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Tt Mod, ViewData, Filters, Sidebar ####
output$spacttype <- renderUI({
  data <- data.table(filtered_data())
  myParam.Name <- "Activity Type Code"
  fluidRow(if(length(unique(data[, as.character(ActivityTypeCode)]))>1){
    selectizeInput('facttype', h4(paste0("  Select ",myParam.Name,":")),
                   choices = unique(data[, as.character(ActivityTypeCode)]),
                   multiple = TRUE,
                   selected = if(input$acttype_sel==1){
                     unique(data[, as.character(ActivityTypeCode)])
                   } else {NULL})
  } else {
    p(h5(paste("There is only one value for",myParam.Name,unique(data[, as.character(ActivityTypeCode)]), sep=" "))) 
  })
})
output$spequip <- renderUI({
  data <- data.table(filtered_data())
  myParam.Name <- "Sample Collection Equipment Name"
  fluidRow(if(length(unique(data[, as.character(SampleCollectionEquipmentName)]))>1){
    selectizeInput('fequip', h4(paste0("  Select ",myParam.Name,":")),
                   choices = unique(data[, as.character(SampleCollectionEquipmentName)]),
                   multiple = TRUE,
                   selected = if(input$equip_sel==1){
                     unique(data[, as.character(SampleCollectionEquipmentName)])
                   } else {NULL})
  } else {
    p(h5(paste("There is only one value for",myParam.Name,unique(data[, as.character(SampleCollectionEquipmentName)]), sep=" "))) 
  })
})
output$spstatusid <- renderUI({
  data <- data.table(filtered_data())
  myParam.Name <- "Result Status Identifier"
  fluidRow(if(length(unique(data[, as.character(ResultStatusIdentifier)]))>1){
    selectizeInput('fstatusid', h4(paste0("  Select ",myParam.Name,":")),
                   choices = unique(data[, as.character(ResultStatusIdentifier)]),
                   multiple = TRUE,
                   selected = if(input$statusid_sel==1){
                     unique(data[, as.character(ResultStatusIdentifier)])
                   } else {NULL})
  } else {
    p(h5(paste("There is only one value for",myParam.Name,unique(data[, as.character(ResultStatusIdentifier)]), sep=" "))) 
  })
})
# Tt Mod, ViewData, Save/Load Buttons ####
## Save
output$SaveFilters <- downloadHandler(
  filename = function() {
    strFile <- paste0("DDT_Filters_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")}
  ,content = function(file) {
    # Create List
    lst_filters_save <- list(input$org
                             ,input$stt
                             ,input$fmedia
                             ,input$ffrac
                             ,input$param
                             ,input$sidepanelunit
                             ,input$sidepanelmethod
                             ,input$fqual
                             ,input$facttype
                             ,input$fequip
                             ,input$fstatusid
                             ,input$minvalue
                             ,input$maxvalue
                             ,input$spdate[1]
                             ,input$spdate[2]
                          )
    # Set List Names
    names(lst_filters_save) <- c("org"
                                 ,"stt"
                                 ,"fmedia"
                                 ,"ffrac"
                                 ,"param"
                                 ,"sidepanelunit"
                                 ,"sidepanelmethod"
                                 ,"fqual"
                                 ,"facttype"
                                 ,"fequip"
                                 ,"fstatusid"
                                 ,"minvalue"
                                 ,"maxvalue"
                                 ,"spdate_1"
                                 ,"spdate_2"
                              )
    # Save List
    #strFile <- paste0("DDT_Query_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
    saveRDS(lst_filters_save, file)  
  }
)
# Load
# Update Filters based on User File
observeEvent(input$UpdateFilters, {
  # Get Filters File specs
  q <- input$LoadFiltersFile
  # Error check
  if(is.null(q)) return(NULL)
  # define list
  lst_filters_load <- readRDS(q$datapath)
  # Radio Button Choices
  myChoicesRadio <- c("Select All"=1, "Deselect All"=2)
  #
  # Update Filter Info onscreen
  #
  if(!is.null(lst_filters_load$org)) {##IF.org.START
    updateCollapse(session, id="view_sp", open="Filter by Organization")
    data <- data.table(filtered_data())
    org_Choices <- unique(data[, as.character(OrganizationFormalName)]) #lst_filters_load$org #unique(data[, as.character(OrganizationFormalName)])
    updateRadioButtons(session, "org_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "org"
                         , choices=org_Choices
                         , selected=lst_filters_load$org)
    #updateButton(session, "submit_filters", value = 0)
    #updateButton(session, "submit_filters", value = 1)
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Organization")
    data <- data.table(filtered_data())
    org_Choices <- unique(data[, as.character(OrganizationFormalName)]) #lst_filters_load$org #unique(data[, as.character(OrganizationFormalName)])
    updateRadioButtons(session, "org_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"org"
                         , choices=org_Choices
                         , selected=NULL)
    #updateButton(session, "submit_filters", value = 0)
    #updateButton(session, "submit_filters", value = 1)
    #updateCollapse(session, id="view_sp", close="Filter by Organization")
  }##IF.org.END
  #
  if(!is.null(lst_filters_load$stt)) {##IF.stt.START
    updateCollapse(session, id="view_sp", close="Filter by Station")
    data <- data.table(filtered_data())
    # if(is.null(input$org)){
    #   data <- data
    #   } else {
    #     data <- data[OrganizationFormalName %in% input$org]
    #   }
    stt_Choices <- unique(data[, as.character(Name)]) #lst_filters_load$stt #unique(data[, as.character(Name)])
    updateRadioButtons(session, "stat_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "stt"
                         , choices=stt_Choices
                         , selected=lst_filters_load$stt)
    #updateButton(session, "submit_filters", value = 0)
    #updateButton(session, "submit_filters", value = 1)
   # updateCollapse(session, id="view_sp", open="Filter by Station")
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Station")
    data <- data.table(filtered_data())
    if(is.null(input$org)){
      data <- data
      } else {
        data <- data[OrganizationFormalName %in% input$org]
      }
    stt_Choices <- lst_filters_load$stt #unique(data[, as.character(Name)])
    updateRadioButtons(session, "stat_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"stt"
                         , choices=stt_Choices
                         , selected=NULL)
    #updateButton(session, "submit_filters", value = 0)
    #updateButton(session, "submit_filters", value = 1)
  }##IF.stt.END
  #
  if(!is.null(lst_filters_load$media)) {##IF.media.START
    updateCollapse(session, id="view_sp", open="Filter by Sample Media")
    data <- data.table(filtered_data())
    media_Choices <- unique(data[, as.character(ActivityMediaName)])
    updateRadioButtons(session, "media_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "fmedia"
                         , choices=media_Choices
                         , selected=lst_filters_load$media )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Sample Media")
    data <- data.table(filtered_data())
    media_Choices <- unique(data[, as.character(ActivityMediaName)])
    updateRadioButtons(session, "media_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"fmedia"
                         , choices=media_Choices
                         , selected=NULL)
  }##IF.media.END
  #
  if(!is.null(lst_filters_load$frac)) {##IF.frac.START
    updateCollapse(session, id="view_sp", open="Filter by Sample Fraction")
    data <- data.table(filtered_data())
    frac_Choices <- unique(data[, as.character(ResultSampleFractionText)])
    updateRadioButtons(session, "frac_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "ffrac"
                         , choices=frac_Choices
                         , selected=lst_filters_load$frac )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Sample Fraction")
    data <- data.table(filtered_data())
    frac_Choices <- unique(data[, as.character(ResultSampleFractionText)])
    updateRadioButtons(session, "frac_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"ffrac"
                         , choices=frac_Choices
                         , selected=NULL)
  }##IF.frac.END
  #
  if(!is.null(lst_filters_load$param)) {##IF.param.START
    updateCollapse(session, id="view_sp", open="Filter by Parameter")
    data <- data.table(filtered_data())
    if(is.null(input$stt)) {
      data <- data
    } else {
      data <- data[Name %in% input$stt]
    }
    param_Choices <- unique(data[, as.character(Characteristic)])
    updateRadioButtons(session, "param_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "param"
                         , choices=param_Choices
                         , selected=lst_filters_load$param )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Parameter")
    data <- data.table(filtered_data())
    if(is.null(input$stt)) {
      data <- data
    } else {
      data <- data[Name %in% input$stt]
    }
    param_Choices <- unique(data[, as.character(Characteristic)])
    updateRadioButtons(session, "param_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"param"
                         , choices=param_Choices
                         , selected=NULL)
  }##IF.param.END
  #
  if(!is.null(lst_filters_load$unit)) {##IF.unit.START
    updateCollapse(session, id="view_sp", open="Filter by Units")
    data <- data.table(filtered_data())
    unit_Choices <- unique(data[Characteristic %in% input$param, as.character(Unit)])
    updateRadioButtons(session, "unit_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "sidepanelunit"
                         , choices=unit_Choices
                         , selected=lst_filters_load$unit )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Units")
    data <- data.table(filtered_data())
    unit_Choices <- unique(data[Characteristic %in% input$param, as.character(Unit)])
    updateRadioButtons(session, "unit_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"sidepanelunit"
                         , choices=unit_Choices
                         , selected=NULL)
  }##IF.unit.END
  #
  if(!is.null(lst_filters_load$method)) {##IF.method.START
    updateCollapse(session, id="view_sp", open="Filter by Methods")
    data <- data.table(filtered_data())
    method_Choices <- unique(data[Characteristic %in% input$param, as.character(Method)])
    updateRadioButtons(session, "method_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "sidepanelmethod"
                         , choices=method_Choices
                         , selected=lst_filters_load$method )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Methods")
    data <- data.table(filtered_data())
    method_Choices <- unique(data[Characteristic %in% input$param, as.character(Method)])
    updateRadioButtons(session, "method_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"sidepanelmethod"
                         , choices=method_Choices
                         , selected=NULL)
  }##IF.method.END
  #
  if(!is.null(lst_filters_load$qual)) {##IF.qual.START
    updateCollapse(session, id="view_sp", open="Filter by Result Qualifier")
    data <- data.table(filtered_data())
    qual_Choices <- unique(data[, as.character(MeasureQualifierCode)])
    updateRadioButtons(session, "qual_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "fqual"
                         , choices=lst_filters_load$qual
                         , selected=lst_filters_load$qual )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Result Qualifier")
    data <- data.table(filtered_data())
    qual_Choices <- unique(data[, as.character(MeasureQualifierCode)])
    updateRadioButtons(session, "qual_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"fqual"
                         , choices=qual_Choices
                         , selected=NULL)
  }##IF.qual.END
  #
  if(!is.null(lst_filters_load$acttype)) {##IF.acttype.START
    updateCollapse(session, id="view_sp", open="Filter by Activity Type Code")
    data <- data.table(filtered_data())
    acttype_Choices <- unique(data[, as.character(ActivityTypeCode)])
    updateRadioButtons(session, "acttype_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "facttype"
                         , choices=acttype_Choices
                         , selected=lst_filters_load$acttype )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Activity Type Code")
    data <- data.table(filtered_data())
    acttype_Choices <- unique(data[, as.character(ActivityTypeCode)])
    updateRadioButtons(session, "acttype_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"facttype"
                         , choices=acttype_Choices
                         , selected=NULL)
  }##IF.acttype.END
  #
  if(!is.null(lst_filters_load$equip)) {##IF.equip.START
    updateCollapse(session, id="view_sp", open="Filter by Equipment Name")
    data <- data.table(filtered_data())
    equip_Choices <- unique(data[, as.character(SampleCollectionEquipmentName)])
    updateRadioButtons(session, "equip_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "fequip"
                         , choices=equip_Choices
                         , selected=lst_filters_load$equip )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Equipment Name")
    data <- data.table(filtered_data())
    equip_Choices <- unique(data[, as.character(SampleCollectionEquipmentName)])
    updateRadioButtons(session, "equip_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"fequip"
                         , choices=equip_Choices
                         , selected=NULL)
  }##IF.equip.END
  #
  if(!is.null(lst_filters_load$statusid)) {##IF.statusid.START
    updateCollapse(session, id="view_sp", open="Filter by Result Status ID")
    data <- data.table(filtered_data())
    statusid_Choices <- unique(data[, as.character(ResultStatusIdentifier)])
    updateRadioButtons(session, "statusid_sel", choices=myChoicesRadio, selected=2)
    updateSelectizeInput(session, "fstatusid"
                         , choices=statusid_Choices
                         , selected=lst_filters_load$statusid )
  } else {
    updateCollapse(session, id="view_sp", open="Filter by Result Status ID")
    data <- data.table(filtered_data())
    statusid_Choices <- unique(data[, as.character(ResultStatusIdentifier)])
    updateRadioButtons(session, "statusid_sel", choices=myChoicesRadio, selected=1)
    updateSelectizeInput(session,"fstatusid"
                         , choices=statusid_Choices
                         , selected=NULL)
  }##IF.statusid.END
  
  # Value and Date fields always populated
  updateNumericInput(session, "minvalue", value=lst_filters_load$minvalue)
  updateNumericInput(session, "maxvalue", value=lst_filters_load$maxvalue)
  updateDateRangeInput(session, "spdate"
                       , start=lst_filters_load$spdate_1
                       , end=lst_filters_load$spdate_2)
  
  #if(is.null(lst_filters_load$minvalue)) {
  #  updateNumericInput(session, "minvalue", value=lst_filters_load$minvalue)
  # }
  #
  # if(is.null(lst_filters_load$maxvalue)) {
  #  updateNumericInput(session, "maxvalue", value=lst_filters_load$maxvalue)
  #}
  #
  # if(is.null(lst_filters_load$spdate_1) | is.null(lst_filters_load$spdate_2)) {
  #  updateDateRangeInput(session, "spdate"
  #                       , start=lst_filters_load$spdate_1
  #                       , end=lst_filters_load$spdate_2)
  # } else { # same code from line 991
  #   updateDateRangeInput(session, "spdate"
  #                        , start = min(filtered_data()$ActivityStartDate, na.rm = TRUE)
  #                        , end = max(filtered_data()$ActivityStartDate, na.rm = TRUE))
  # }
  #
  # Apply (submit) Filters (by changing value of button to cause Observe to trigger)
  # for (j in 0:1) {
  #   updateButton(session, "submit_filters", value = j)
  #   #updateButton(session, "submit_filters", value = 1)
  #   # updateButton(session, "submit_filters", value = 2)
  #   # updateButton(session, "submit_filters", value = 3)
  #   # updateButton(session, "submit_filters", value = 4)
  #   # updateButton(session, "submit_filters", value = 5)
  # }

})##observeEvent(input$UpdateFilters - END
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#################################  Map and draggable panel #############################################
    output$Map_title<-renderUI({
      h3("Map Displays ", span("Filtered Data"))
    })

    addPopover(session, "Map_title", "Mapped Data", placement = "top", content = paste(
      " The ", span("Filtered Dataset", style = "color:#0099CC"), " includes only results with units and methods. All results with non detections have been removed, as have duplicate records.",
      " The complete ", span("Filtered Dataset", style = "color:#0099CC"), " is displayed at the bottom of this screen.", 
      fluidRow(br()), 
      "The data displayed on the map can be interactively queried using the filters in the side panel. The map will automatically redraw based on the queries applied in the table"))
    
    output$map<-renderLeaflet({
      radiusFactor <- 50
      leaflet(map_df()) %>%
        fitBounds(lng1 = ~min(LongitudeMeasure), lat1 = ~min(LatitudeMeasure), 
                  lng2 = ~max(LongitudeMeasure), lat2 = ~max(LatitudeMeasure)) %>%
        addTiles( "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png") %>%
        addCircleMarkers(
          lng= ~LongitudeMeasure, 
          lat= ~LatitudeMeasure, 
          radius = (log(map_df()$N) + 2)  * radiusFactor / 5^2,
          layerId = row.names(map_df())
         # color = ~ifelse(Tot_Exceed == 0, 'black','blue'),
        )
    })
    
    observeEvent(input$map_marker_click, {
      leafletProxy("map")%>%clearPopups()
      content<- as.character(tagList(
        tags$strong(paste("Latitude ", map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["LatitudeMeasure"]], 
                          ", Longtitude ", map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["LongitudeMeasure"]])),
        tags$br(),
        tags$strong(paste("Station ID:", map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["Station"]], ',')),
        tags$strong(paste("Station Name:", map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["Name"]], ',')),
        tags$strong(paste(map_df()[row.names(map_df()) == input$map_marker_mouseover["id"], ][['Samples']], " sample(s), ")),
       tags$strong(paste(map_df()[row.names(map_df()) == input$map_marker_mouseover["id"], ][["N"]], " results"))
       ))
      leafletProxy("map")%>% addPopups(map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["LongitudeMeasure"]], map_df()[row.names(map_df()) == input$map_marker_click["id"], ][["LatitudeMeasure"]], 
                                        paste(content, '<br></br>',
                                              actionButton("Stat_Summary", "Select this Location", 
                                                           onclick = 'Shiny.onInputChange(\"button_click\",  Math.random())'),
                                              sep = ""))
    })
    
    
    
    #################################  Station Summary  ##########################################
 
    station_info<-eventReactive(input$button_click,{
     data <- map_df()[row.names(map_df()) == input$map_marker_click$id,]
     data <- data.table(data)
     data[, Name := as.character(Name)]
     data[, Station := as.character(Station)]
     
     return(data)
    })
    
    station_data <- eventReactive(input$button_click, {
      mapData <- data.table(dat_display())
      data1<- mapData[Station == station_info()$Station, ]
      data1[, Name := as.character(Name)]
      data1[, Station := as.character(Station)]
      data1[, Characteristic := as.character(Characteristic)]
      
      return(data1)
    })   

output$param_range_freq <- renderUI({
 
  data2 <- station_data()
    if(is.null(data2) | is.na(data2)) {
      br()
      br()
      h3('Please select a station on the map.', style  = "text-align:center ; color: #990000 ;")
    }else{
      if(is.null(input$param)){
        data2 <- data2
      } else {
        data2 <- data2[Characteristic %in% input$param]
      }
      wellPanel(selectizeInput('param_range_freq_sel', h4('Select parameters to view date range and frequency (up to 30 parameters)'),
                     choices = unique(as.character(data2$Characteristic)), 
                     selected = unique(as.character(data2$Characteristic))[c(1:10)],
                     multiple = TRUE),
      bsPopover("param_range_freq_sel", "Sampling Frequency",
                "Please select Characteristics of interest to view date range and sample collection frequency. Multiple characterisitcs may be selected.",
                "top", trigger = "hover", options = list(container = "body")))
    }
    
})

    output$Station_Summary_Panel <- renderUI({
      h4(paste("Summary for station ", station_info()$Name))
    })
    
    output$Station_Summary_Panel2 <- renderUI({
      h4(paste("Summary for station ", station_info()$Name))
    })
    
    output$Station_Summary_text<-renderUI({
   
        dataStat <- station_data()
        records<-dim(dataStat)[1]
        parameters<-length(unique(dataStat$Characteristic))
      p(paste("There are ", records, " records representing ", parameters, " characteristics at this station."))
    })

    
    output$Station_data_time_plot<-renderPlot({
      station_subset<-station_data()[Characteristic %in% input$param_range_freq_sel] # this could be  modified
      p1 <- ggplot(station_subset, aes(x=ActivityStartDate, y=Characteristic))+
        geom_point(color = "blue", size = 5, alpha = 1/2)+
        labs(x = '',y='')+
        theme_bw()+
        scale_y_discrete(labels = function(y) str_wrap(y, width = 20))+
        scale_x_date(labels = date_format("%b-%d-%y"))+
        theme(axis.text.x=element_text(angle=35, vjust=1, hjust=1))
      
      print(p1)
    })
    
## Begin Code for Filtering Data table
    dat_display<-reactive({
      if(input$submit_filters==0){
        filtered_data()
      } else {test()}
    })
    output$Map_Table = DT::renderDataTable(
      data.frame(dat_display())[, display_Map, drop=FALSE], rownames = FALSE, server = TRUE, 
      options = list(dom = 'lfrtip', pageLength = 100,
                                             lengthMenu = c(100, 200, 500)
      ))
    outputOptions(output, 'Map_Table', suspendWhenHidden=TRUE)

    output$save_map_data <- downloadHandler(
        filename = function() {
            paste('Map_data-', Sys.Date(), '.tsv', sep='')
        },
        content = function(con) {
            write.table(data.frame(dat_display()), con, row.names = F, sep = "\t")
        })

# Highcharts portion
output$pieplot <- renderChart2({
 
  data <- station_data()
  data[, charnum := length(Station), by = 'Characteristic']
  data <- data[!duplicated(data[, list(Characteristic)])]
  if(is.null(input$param)){
    data <- data
  } else {
    data <- data[Characteristic %in% input$param]
  }
  
  m <- rCharts::Highcharts$new()
  m$series(
    data = toJSONArray2(data[, list(Characteristic, charnum)], names = FALSE, json = FALSE),
    zIndex = 1,
    type = 'pie',
    name = 'Result count'
  )
  return(m)
})

output$piepresent <- renderUI({
  station <- station_info()$Name
    if(is.null(station)) {
        br()
        br()
        h3('Please select a station on the map.', style  = "text-align:center ; color: #990000 ;")
    }else{
        h4(station, style  = "text-align:center")
        showOutput("pieplot", "highcharts")
    }
    })

output$scatterpresent <- renderUI({
  station <- station_info()$Name
  
    if(is.null(station)) {
        br()
        br()
        h3('', style  = "text-align:center ; color: #990000 ;")
    }else{
        p(h4(station, style  = "text-align:center"))
        plotOutput("Station_data_time_plot")
    }
    
})

# Creating a data table with the combined parameter/unit columns
charunit <- reactive({
  data<- if(input$submit_filters==0){
    data.table(filtered_data())
  } else {  data.table(test())}  #[s, , drop = FALSE])
  data <- data[Station == station_info()$Station]
  if(is.null(input$param)){
    data <- data
  } else {
    data <- data[Characteristic %in% input$param]
  }
  data[, CharUnit := paste(Characteristic, " (", Unit, ")", sep = "")]
  setnames(data, "ActivityStartDateTime", "Date")
  data <- data[, list(Result, CharUnit, Date, Characteristic)]
  data[, charlength := length(Date), by = 'CharUnit']
  data <- data[charlength > 0]
  return(data)
})

output$paramgraph2 <- renderUI({
  data <- charunit()
  data <- data[!duplicated(data[, list(Date, CharUnit)])]  
  
  selectizeInput("G1_PU1", label = p("First Parameter/Unit Choice"),
                 choices = unique(data[, CharUnit]), multiple = FALSE)
})

output$paramgraph3 <- renderUI({
  data <- charunit()
  data <- data[!duplicated(data[, list(Date, CharUnit)])]  
  
  selectizeInput("G1_PU2", label = p("Second Parameter/Unit Choice"),
                 choices = unique(data[, CharUnit]), multiple = FALSE,
                 selected = unique(data[, CharUnit])[2])
})

output$paramgraph4 <- renderUI({
  data <- charunit()
  data <- data[!duplicated(data[, list(Date, CharUnit)])]  
  
  selectizeInput("G1_PU3", label = p("Third Parameter/Unit Choice"),
                 choices = unique(data[, CharUnit]), multiple = FALSE,
                 selected = unique(data[, CharUnit])[3])
})

output$timepresent <- renderUI({
    station <- unique(station_data()[['Station']])
    if(is.null(station)) {
        br()
        br()
        h2('Please select a station on the map.', style  = "text-align:center ; color: #990000 ;")
    }else{
        p(h4(station, style  = "text-align:center"))
        showOutput('timeseries', 'highcharts')
    }
    
})

timedata <- reactive({
  data <- charunit()
  data[, Characteristic := NULL]
  data <- data[CharUnit %in% c(input$G1_PU1, input$G1_PU2, input$G1_PU3)]
  data <- data[!duplicated(data[, list(Date, CharUnit)])]  
  testc <- dcast.data.table(data, Date ~ CharUnit, value.var = 'Result')
  return(testc)
})

output$timeseries <- renderChart2({
  datatime <- timedata()
  datatime[, Date := gsub(" UTC", "", Date)]
  datatime$Date =  as.numeric(as.POSIXct(datatime$Date))*1000
  
  ln <- rCharts::Highcharts$new()
  ln$colors("#FFCC00", "#08519C","#D94801" )
  ln$xAxis(type = 'datetime', labels = list(format = '{value:%Y-%m-%d}'))
  ln$yAxis(list(list(title = list(text = names(datatime)[2]))
                , list(title = list(text = names(datatime)[3]), 
                       opposite = TRUE)
                , list(title = list(text = names(datatime)[4]), 
                       opposite = TRUE)))

  for(i in 2:ncol(datatime)) {
      ln$series(
        data = toJSONArray2(datatime[, c(1,i), with = FALSE], names = FALSE, json = FALSE),
        name = names(datatime)[i],
        type = 'spline',
        yAxis = (i-2)
      )
    }

    ln$plotOptions(spline = list(connectNulls = TRUE))
    ln$chart(marginTop = 70, zoomType = 'xy', panKey = 'shift', panning = TRUE) 
    ln$exporting(filename = "Line chart")

  return(ln)
  })
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tt Mod, ViewData, Data Summary Plots/Tables ####
# output$plot.CDF.Year.Site <- renderChart2({
#   # data to use
#   data_plot <- filtered_data()
#   # add extras to data for ploting
#   data_plot$begYear <- year(data_plot$begDate)
#   data_plot$endYear <- year(data_plot$endDate)
#   # plotting
#   #par(mfrow = c(2, 2))
#   with(data_plot, plot.ecdf(begYear, ylab="CDF(x)", xlab="", main="A) Begin Year by Site",
#                         panel.first=grid(lty=3)))
#   # with(sites, plot.ecdf(endYear, ylab="CDF(x)", xlab="", main="B) End Year by Site",
#   #                       panel.first=grid(lty=3)))
#   # 
#   # with(sites, plot.ecdf((endYear-begYear+1), ylab="CDF(x)", xlab="", main="C) Num Years by Site",
#   #                       panel.first=grid(lty=3)))
#   # 
#   # with(sites, plot(begYear, endYear, ylab="End Year", xlab="Begin Year", main="D) End vs. Beg. Year by Site",
#   #                  panel.first=grid(lty=3)))
# })

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
})