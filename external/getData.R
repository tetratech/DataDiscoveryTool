library(dataRetrieval)
#This is a new module that retrieves the data and replaces readWQPdata_app.R.  It appears to perform much faster
getWQPData_app <- function(urlCall){
  retval <- importWQP(urlCall,FALSE, tz="")
  urlStation <- gsub("/Result/", "/Station/", urlCall)
  if(!all(is.na(retval))){
    siteInfo <- importWQP(urlStation, FALSE, tz="")
    
    siteInfoCommon <- data.frame(station_nm=siteInfo$MonitoringLocationName,
                                 agency_cd=siteInfo$OrganizationIdentifier,
                                 site_no=siteInfo$MonitoringLocationIdentifier,
                                 dec_lat_va=siteInfo$LatitudeMeasure,
                                 dec_lon_va=siteInfo$LongitudeMeasure,
                                 hucCd=siteInfo$HUCEightDigitCode,
                                 stringsAsFactors=FALSE)
    
    siteInfo <- cbind(siteInfoCommon, siteInfo)
    
    retvalVariableInfo <- retval[,c("CharacteristicName","USGSPCode",
                                    "ResultMeasure.MeasureUnitCode","ResultSampleFractionText")]
    retvalVariableInfo <- unique(retvalVariableInfo)
    
    variableInfo <- data.frame(characteristicName=retval$CharacteristicName,
                               parameterCd=retval$USGSPCode,
                               param_units=retval$ResultMeasure.MeasureUnitCode,
                               valueType=retval$ResultSampleFractionText,
                               stringsAsFactors=FALSE)
    
    if(any(!is.na(variableInfo$parameterCd))){
      pcodes <- unique(variableInfo$parameterCd[!is.na(variableInfo$parameterCd)])
      pcodes <- pcodes["" != pcodes]
      paramINFO <- readNWISpCode(pcodes)
      names(paramINFO)["parameter_cd" == names(paramINFO)] <- "parameterCd"
      
      pCodeToName <- pCodeToName
      varExtras <- pCodeToName[pCodeToName$parm_cd %in% unique(variableInfo$parameterCd[!is.na(variableInfo$parameterCd)]),]
      names(varExtras)[names(varExtras) == "parm_cd"] <- "parameterCd"
      variableInfo <- merge(variableInfo, varExtras, by="parameterCd", all = TRUE)
      variableInfo <- merge(variableInfo, paramINFO, by="parameterCd", all = TRUE)
      variableInfo <- unique(variableInfo)
    }
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    # Tt Mod, Add data fields ####
    ## Additional fields for QA/QC
    retval$ResultLower     <- NA
    retval$ResultUpper     <- NA
    ## If DL is NA will Lo will return NA otherwise will be zero.  Hi is DL.
    retval$ResultLower     <- 0 * retval$DetectionQuantitationLimitMeasure.MeasureValue 
    retval$ResultUpper     <- retval$DetectionQuantitationLimitMeasure.MeasureValue
    ## more fields from stations file
    MoreFlds <- c("OrganizationIdentifier", "MonitoringLocationIdentifier"
                  , "MonitoringLocationName"
                  , "LatitudeMeasure"
                  , "LongitudeMeasure"
                  , "HUCEightDigitCode"
                  , "huc8name"
                  , "StateName"
                  , "CountyName"
                  , "MonitoringLocationTypeName"
                  )
    # Add Field - siteInfo - StateName
    siteInfo[,"FIPS"] <- paste0(siteInfo[,"CountryCode"],":",siteInfo[,"StateCode"])
    siteInfo <- merge(siteInfo, states, by="FIPS", all.x=TRUE, sort=FALSE)
    colnames(siteInfo)[colnames(siteInfo)=="desc"] <- "StateName"
    # Add Field - siteInfo - huc8name
    myHUCinfo <- data.frame(HUCEightDigitCode=hucs$HUC8, huc8name=hucs$NAME)
    siteInfo <- merge(siteInfo, myHUCinfo, by="HUCEightDigitCode", all.x=TRUE, sort=FALSE)
    rm(myHUCinfo)
    # Add Field - siteInfo - CountyName
    myCountyInfo <- read.csv("external/Counties.csv", header=FALSE
                             ,colClasses=c("factor","integer","character","factor","factor"))[,2:4]
    names(myCountyInfo) <- c("StateCode","CountyCode","CountyName")
    siteInfo <- merge(siteInfo, myCountyInfo
                      , by = c("StateCode","CountyCode")
                      , all.x = TRUE, sort=FALSE)
    # Add "MoreFlds" to retval
    retval.merge <- merge(retval,siteInfo[,MoreFlds]
                          , by.x=c("OrganizationIdentifier", "MonitoringLocationIdentifier")
                          , by.y=c("OrganizationIdentifier", "MonitoringLocationIdentifier")
                          , all.x=TRUE, sort=FALSE)
    #
    retval[,"HUCEightDigitCode"]   <- retval.merge[,"HUCEightDigitCode"]
    retval[,"huc8name"]   <- retval.merge[,"huc8name"]
    retval[,"StateName"]  <- retval.merge[,"StateName"]
    retval[,"CountyName"] <- retval.merge[,"CountyName"]
    retval[,"MonitoringLocationTypeName"] <- retval.merge[,"MonitoringLocationTypeName"]
    #
    rm(retval.merge)
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
    attr(retval, "siteInfo") <- siteInfo
    attr(retval, "variableInfo") <- variableInfo
    attr(retval, "url") <- urlCall
    attr(retval, "queryTime") <- Sys.time()  
  
    return(retval)
  } else {
    message("The following url returned no data:\n")
    message(urlCall)
  }
}

