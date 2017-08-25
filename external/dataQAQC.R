#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tt Mod, data QA QC function ####
# library(XLConnect) [added to server.R]
read_data_QAQC <- function(strFile, strSheet, intStartRow) {
                XLConnect::readWorksheetFromFile(strFile
                                                 , sheet=strSheet
                                                 , startRow=intStartRow
                                                 , header=TRUE) #, drop=c(1,2))
}
  #data_QAQC <- XLConnect::readWorksheetFromFile("external/DDT_QAQC_Default.xlsx", sheet="Methods Table", startRow=6, header=TRUE)
  #
data_QAQC <- read_data_QAQC(strFile="external/DDT_QAQC_Default.xlsx", strSheet = "Methods Table", intStartRow=6)

# Apply QAQC Decisions
ApplyQAQCDecisions <- function(...){ #df.Data, df.QAQC) {
  #
  # df.Data <- All_data()
  # df.QAQC <- data_QAQC
  #
  # TESTING ***
  strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_QAQC_Default.xlsx")
  data_QAQC <- XLConnect::readWorksheetFromFile(strFile, sheet="Methods Table", startRow=6, header=TRUE) #, drop=c(1,2))
  
  #
  strFile <- file.path("C:","Users","Erik.Leppo","Downloads","DDT_Data_20170804_081355_multipleParam.rds")
  myData <- readRDS(strFile)
  
  # 1. Prep Sample Data
  {
    # create merge key
    myData$mergeKey <- with(myData, paste(ActivityMediaName, CharacteristicName, 
                                          ResultSampleFractionText, USGSPCode,
                                          ResultMeasure.MeasureUnitCode,sep="|")) 
    # rename some variables to *.orig
    data.table::setnames(myData, old = c("Characteristic", "Unit", "ResultSampleFractionText"),
                         new = c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig"))
  }
  #
  # 2. Prep QAQC Data
  {
    # create merge key
    data_QAQC$mergeKey <- with(data_QAQC, paste(ActivityMediaName, CharacteristicName, 
                                                ResultSampleFractionText, USGSPCode,
                                                ResultMeasure.MeasureUnitCode,sep="|")) 
    # identify list of variables to merge into with sample data
    data_QAQCvars <- c("apply", "Characteristic", "Unit", "unitsConvMult",
                       "SampleFraction", "qcMin", "qcMax", "mergeKey") 
  }
  #
  # 3. Merge Data
  # apply range check, unit conversion, and fill in.
  {
    # do merge where data_QAQC$apply == TRUE and only merge in variables listed in data_QAQCvars
    myData <- merge (myData, data_QAQC[data_QAQC$apply, data_QAQCvars], by="mergeKey", all.x=TRUE)
    # drop merge key
    myData <- myData[,!(names(myData) %in% c("mergeKey"))]
    # identify cases where data are outside qc range (do this before unit conversion because
    # the ranges in the data_QAQC are based on the original units)
    myData$qcRange <- FALSE
    myData[!is.na(myData$Result) & !is.na(myData$qcMin) & myData$Result < myData$qcMin, "qcRange"]<-TRUE
    myData[!is.na(myData$Result) & !is.na(myData$qcMax) & myData$Result > myData$qcMax, "qcRange"]<-TRUE
    # apply unit conversions (because unitsConvMult can be character to accomodate for Deg F->Deg C
    # i create a numeric conversion field but suppress warnings to not alarm user
    myData$unitsConvMult.num <- suppressWarnings(as.numeric(myData$unitsConvMult))
    myData$Result      <- ifelse(!is.na(myData$Result     ) & !is.na(myData$unitsConvMult.num), 
                                 myData$Result      * myData$unitsConvMult.num, myData$Result     )
    myData$ResultLower <- ifelse(!is.na(myData$ResultLower) & !is.na(myData$unitsConvMult.num), 
                                 myData$ResultLower * myData$unitsConvMult.num, myData$ResultLower)
    myData$ResultUpper <- ifelse(!is.na(myData$ResultUpper) & !is.na(myData$unitsConvMult.num), 
                                 myData$ResultUpper * myData$unitsConvMult.num, myData$ResultUpper)
    # apply special case unit conversion (Deg F to Deg C)
    myData$Result      <- ifelse(!is.na(myData$Result     ) & !is.na(myData$unitsConvMult) & myData$unitsConvMult == "F_to_C" , 
                                 (myData$Result      - 32) * (5/9) , myData$Result     )
    myData$ResultLower <- ifelse(!is.na(myData$ResultLower) & !is.na(myData$unitsConvMult) & myData$unitsConvMult == "F_to_C" , 
                                 (myData$ResultLower - 32) * (5/9) , myData$ResultLower     )
    myData$ResultUpper <- ifelse(!is.na(myData$ResultUpper) & !is.na(myData$unitsConvMult) & myData$unitsConvMult == "F_to_C" , 
                                 (myData$ResultUpper - 32) * (5/9) , myData$ResultUpper     )
    # handle those cases where data_QAQC was not merged in (i.e., either data_QAQC$apply==FALSE or 
    # there was no record to process
    myData[is.na(myData$apply), "apply" ] <- FALSE
    myData$Characteristic <- ifelse(myData$apply, myData$Characteristic, myData$Characteristic.orig) 
    myData$Unit           <- ifelse(myData$apply, myData$Unit          , myData$Unit.orig          ) 
    myData$SampleFraction <- ifelse(myData$apply, myData$SampleFraction, myData$ResultSampleFractionText.orig)
    # drop non essential variables (Tt-JBH: dont implement till after testing)
    #Tt-JBH myData <- myData[,!(names(myData) %in% c("Characteristic.orig", "Unit.orig", "ResultSampleFractionText.orig" ))]
    #Tt-JBH myData <- myData[,!(names(myData) %in% c("unitsConvMult", "qcMin", "qcMax", "unitsConvMult.num" ))] 
  }
  #
  # 4. Return df
  return(myData)
  #
}

#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~