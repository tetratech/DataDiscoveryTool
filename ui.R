library(shiny)
library(shinyBS)
library(DT)
library(leaflet)
library(rCharts)
library(dplyr)
library(dataRetrieval)
library(data.table)
library(ggplot2)
library(stringr)
#~~~~~~~~~~~~~~~~~~~~~~~~~~
## Tt Mod, Add Library ####
library(XLConnect)
# Special version of DT needed to enable editable tables
#devtools::install_github('rstudio/DT@feature/editor')
#~~~~~~~~~~~~~~~~~~~~~~~~~~


# Load files for individual screens
QueryData<-source("external/QueryData.R",local=T)$value
CheckData<-source("external/CheckData.R",local=T)$value
Help<-source("external/Help.R",local=T)$value
ViewData <- source("external/ViewData.R", local = TRUE)$value
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tt Mod, QAQC tab, source ####
#QAQC <- source("external/QAQC.R", local=TRUE)$value
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

shinyUI(navbarPage("WQP STORET Data Discovery Tool (QAQC Mod)", 
                   theme = "bootstrap.css",
                   inverse = TRUE,
                   QueryData(),
                   CheckData(),
                   ViewData(),
                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                   # Tt Mod, QAQC tab, add ####
                   # QAQC(),
                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                   Help()
                           
))











