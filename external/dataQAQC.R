#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tt Mod, data QAQC functions ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# library(XLConnect) [added to server.R]
read_data_QAQC <- function(strFile, strSheet, intStartRow) {
                XLConnect::readWorksheetFromFile(strFile
                                                 , sheet=strSheet
                                                 , startRow=intStartRow
                                                 , header=TRUE
                                                 , rownames=FALSE
                                                 #, drop=c(1,2)
                                                 )
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# load QAQC file
# ** DEPRECATED *** now a reactive value; RV_QAQC$df_data
  #data_QAQC <- XLConnect::readWorksheetFromFile("external/DDT_QAQC_Default.xlsx", sheet="Methods Table", startRow=6, header=TRUE, rownames=FALSE)
  #
#data_QAQC <- read_data_QAQC(strFile="external/DDT_QAQC_Default.xlsx", strSheet = "Methods Table", intStartRow=6)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Apply QAQC Decisions
ApplyQAQCDecisions_test <- function(...){ #df.Data, df.QAQC) {
  #
  df.data <- all_data()
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
  {
    # create merge key
    df.data$mergeKey <- with(df.data, paste(ActivityMediaName, CharacteristicName, 
                                          ResultSampleFractionText, USGSPCode,
                                          ResultMeasure.MeasureUnitCode,sep="|")) 
    # rename some variables to *.orig
    data.table::setnames(df.data, old = c("Characteristic", "Unit", "ResultSampleFractionText"),
                         new = c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig"))
  }
  #
  # 2. Prep QAQC Data
  {
    # create merge key
    df.QAQC$mergeKey <- with(df.QAQC, paste(Activity.Media, Characteristic, 
                                            Sample.Fraction, PCODE,
                                            Units,sep="|")) 
    # identify list of variables to merge into with sample data
    df.QAQCvars <- c("Apply.QAQC", "Characteristic", "Units", "Units.Conv.Mult",
                       "Sample.Fraction.QAQC", "QC.Min", "QC.Max", "mergeKey") 
  }
  #
  # 3. Merge Data
  # apply range check, unit conversion, and fill in.
  {
    # do merge where df.QAQC$apply == TRUE and only merge in variables listed in df.QAQCvars
    df.data <- merge (df.data, df.QAQC[df.QAQC$apply, df.QAQCvars], by="mergeKey", all.x=TRUE)
    # drop merge key
    df.data <- df.data[,!(names(df.data) %in% c("mergeKey"))]
    # identify cases where data are outside qc range (do this before unit conversion because
    # the ranges in the df.QAQC are based on the original units)
    df.data$qcRange <- FALSE
    df.data[!is.na(df.data$Result) & !is.na(df.data$QC.Min) & df.data$Result < df.data$QC.Min, "qcRange"]<-TRUE
    df.data[!is.na(df.data$Result) & !is.na(df.data$QC.Max) & df.data$Result > df.data$QC.Max, "qcRange"]<-TRUE
    # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
    # i create a numeric conversion field but suppress warnings to not alarm user
    df.data$Units.Conv.Mult <- suppressWarnings(as.numeric(df.data$Units.Conv.Mult))
    df.data$Result      <- ifelse(!is.na(df.data$Result     ) & !is.na(df.data$Units.Conv.Mult), 
                                 df.data$Result      * df.data$Units.Conv.Mult, df.data$Result     )
    df.data$ResultLower <- ifelse(!is.na(df.data$ResultLower) & !is.na(df.data$Units.Conv.Mult), 
                                 df.data$ResultLower * df.data$Units.Conv.Mult, df.data$ResultLower)
    df.data$ResultUpper <- ifelse(!is.na(df.data$ResultUpper) & !is.na(df.data$Units.Conv.Mult), 
                                 df.data$ResultUpper * df.data$Units.Conv.Mult, df.data$ResultUpper)
    # apply special case unit conversion (Deg F to Deg C)
    df.data$Result      <- ifelse(!is.na(df.data$Result     ) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
                                 (df.data$Result      - 32) * (5/9) , df.data$Result     )
    df.data$ResultLower <- ifelse(!is.na(df.data$ResultLower) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
                                 (df.data$ResultLower - 32) * (5/9) , df.data$ResultLower     )
    df.data$ResultUpper <- ifelse(!is.na(df.data$ResultUpper) & !is.na(df.data$Units.Conv.Mult) & df.data$Units.Conv.Mult == "F_to_C" , 
                                 (df.data$ResultUpper - 32) * (5/9) , df.data$ResultUpper     )
    # handle those cases where df.QAQC was not merged in (i.e., either df.QAQC$apply==FALSE or 
    # there was no record to process
    df.data[is.na(df.data$Apply.QAQC), "apply" ] <- FALSE
    df.data$Characteristic <- ifelse(df.data$Apply.QAQC, df.data$Characteristic, df.data$Characteristic.orig) 
    df.data$Unit           <- ifelse(df.data$Apply.QAQC, df.data$Unit          , df.data$Unit.orig          ) 
    df.data$SampleFraction <- ifelse(df.data$Apply.QAQC, df.data$SampleFraction, df.data$ResultSampleFractionText.orig)
    # drop non essential variables (Tt-JBH: dont implement till after testing)
    #Tt-JBH df.data <- df.data[,!(names(df.data) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
    #Tt-JBH df.data <- df.data[,!(names(df.data) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))] 
  }
  #
  # 4. Return df
 # return(df.data)
  #
  # 4. Save modified data (so can load later)
  strFile <- paste0("DDT_Data_",format(Sys.time(),"%Y%m%d_%H%M%S"),".rds")
  saveRDS(df.data, file.path(getwd(),strFile))
  # 4. Return df
   return(df.data)
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Clear Query Selections
clearQuerySelection <- function(mySession) {
  # reset all fields
  updateSelectizeInput(mySession, "state", choices=as.character(states$desc), selected=character(0))
  updateSelectizeInput(mySession, "county", choices=NULL, selected=character(0))
  updateTextInput(mySession, "huc_ID", value=character(0))
  updateNumericInput(mySession,"LAT", value=0)
  updateNumericInput(mySession,"LONG", value=0)
  updateNumericInput(mySession,"distance", value=0)
  updateNumericInput(mySession,"North", value=0)
  updateNumericInput(mySession,"South", value=0)
  updateNumericInput(mySession,"East", value=0)
  updateNumericInput(mySession,"West", value=0)
  updateDateInput(mySession, "date_Lo", value=NA)
  updateDateInput(mySession, "date_Hi", value=NA)
  updateSelectizeInput(mySession, "media", choices=NULL, selected=character(0))
  updateSelectizeInput(mySession, "group", choices=NULL, selected=character(0))
  updateSelectizeInput(mySession, "chars", choices=NULL, selected=character(0))
  updateSelectizeInput(mySession, "site_type", choices=NULL, selected=character(0))
  updateSelectizeInput(mySession, "org_id", choices=NULL, selected=character(0))
  updateTextInput(mySession, "site_id", value=character(0))
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~