function(){
  tabPanel("Check Data",
           #            wellPanel(fluidRow(column(1),
           #                               column(5,
           #                       h3("Data Summary", style = "text-align:center"),
           #                       fluidRow(uiOutput('check1'))),
           #                       column(1),
           #                       column(5, 
           #                       fluidRow(radioButtons("ND_method", "Select method for Non-Detects",
           #                                             c("Ignore Non-Detections - remove from data set"=1,
           #                                               "Set Non-Detections equal to zero"=2,
           #                                               "Set Non-Detections equal to the Limit of Detection"=3,
           #                                               "Set Non-Detections equal to the 1/2 times the Limit of Detection"=4)))))),
           tabsetPanel(type = "tabs",
                       tabPanel("Home",
                                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                ## Tt Mod, Load/Save Buttons ####
                                wellPanel(fluidRow(h4("Tt Mod, load data (load button is here as a placeholder)", style = "text-align: center"))
                                          , fluidRow(column(5),column(2, downloadButton("SaveData","Save Data")))
                                          , fluidRow(br())
                                          , fluidRow("As an alternative to retrieving data the buttons below can be used to load a previously saved dataset.")
                                          , fluidRow(br())
                                          , fluidRow(
                                            column(3,
                                                   fileInput("LoadDataFile","Load Data File",accept=".rds")
                                            )
                                          )
                                          # fluidRow(br())
                                          ,fluidRow(column(1,
                                                           bsButton("UpdateData", label="Update Data From File **NOT ACTIVE**", style="primary")
                                                           ,bsPopover("UpdateData", "Update Data", trigger = "hover", placement="right", options = list(container = "body")
                                                                      ,"This button updates the data from a user selected data file. Must upload file first before clicking this button."))
                                          )
                                ),
                                #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                wellPanel(fluidRow(column(1),
                                                   column(10,
                                                          h3("Data Summary", style = "text-align:center"),
                                                          fluidRow(uiOutput('check1'))),
                                                   column(1)),
                                          fluidRow(column(1),
                                                   column(10, uiOutput('home_date'))),
                                          fluidRow(column(12, h5("Web Query:", style = "text-align: center"))),
                                          fluidRow(column(12, uiOutput('home_query')))),
                                wellPanel(fluidRow(column(1),
                                                   column(10,
                                                          fluidRow(h3(" Please select a method to deal with Non-Detections", style = "text-align: center")),
                                                          #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                          ## Tt Mod, Non Detect Options ####
                                                          fluidRow(radioButtons("ND_method", " ",
                                                                                c(#"Ignore Non-Detections - remove from data set"=1,
                                                                                  "Set Non-Detections equal to zero"=2,
                                                                                  "Set Non-Detections equal to the Limit of Detection"=3,
                                                                                  "Set Non-Detections equal to the 1/2 times the Limit of Detection"=4)
                                                                                ,selected=4))))),
                                                          #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                wellPanel(fluidRow(h3("Available Data Sets", style = "text-align: center")),
                                          fluidRow(h4("All Data: "), h5("This table  displays all of the raw data records imported from the Water Quality Portal")),
                                          fluidRow(h4("Non Detects: "), h5("These are the records with values for the 'Result Detection Condition Text' field equal to 'Not Detected' or 'Present below Quantitation Limit'")),
                                          fluidRow(h4("W/O Units: "), h5("These data records have no data entered in either the 'Result Measure - Measure Unit Code' or the 
                                                                         'Quantitation Limit Measure - Measure Unit Code' fields.")),
                                          fluidRow(h4("W/O Methods: "), h5("There are 14 Activity Type Codes which do not require a sample to have a specified method.  These data records 
                                                                           do not match those 14 Activity Type Codes AND have no data entered in the 'Result Analytical Method - Method Identifier' field.")),
                                          fluidRow(h4("Duplicates: "), h5("These data records are duplicated within the imported data set. This means these records match all fields of 
                                                                          another record in the data set except for the 'Activity Type' and 'Activity ID' fields")),
                                          fluidRow(h4("Filtered Data: "), h5("The Filtered Dataset includes only results with units and methods. Duplicate records have been removed. 
                                                                             This is the data set passed to the map and table on the 'View Data' page.")),
                                          fluidRow(h4("Summary: "), h5("This table shows summary statistics of all unique combinations of station, media, characteristic, unit, and sample
                                                                       fraction.")))),
                       tabPanel("All Data",
                                fluidRow(
                                  h3("All Imported Data Records", style = "text-align: center")),
                                fluidRow(h4("This table  displays all of the raw data records imported from the Water Quality Portal", style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data1", "Save Data"))),
                                bsPopover("Save_data1", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("All_Data"))),
                       tabPanel("Non Detects",
                                fluidRow(
                                  h3("Data Records with Non Detections", style = "text-align: center")),
                                fluidRow(h4("These are the records with values for the 'Result Detection Condition Text' field equal to 
                                            'Not Detected' or 'Present below Quantitation Limit'", style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data2", "Save Data"))),
                                bsPopover("Save_data2", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("ND_Table"))),
                       tabPanel("W/O Units",
                                fluidRow(
                                  h3("Data Records without Units", style = "text-align: center")),
                                fluidRow(h4("These data records have no data entered in either the 'Result Measure - Measure Unit Code' or the 
                                            'Quantitation Limit Measure - Measure Unit Code' fields.", style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data3", "Save Data"))),
                                bsPopover("Save_data3", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("NO_UNITS"))),
                       tabPanel("W/O Methods",
                                fluidRow(
                                  h3("Data Records Without Methods", style = "text-align: center")),
                                fluidRow(h4("There are 14 Activity Type Codes which do not require a sample to have a specified method.  These data records 
        do not match those 14 Activity Type Codes AND have no data entered in the 'Result Analytical Method - Method Identifier' field.", style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data4", "Save Data"))),
                                bsPopover("Save_data4", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("NO_METH"))),
                       tabPanel("Duplicates",
                                fluidRow(
                                  h3("Duplicate Data Records", style = "text-align: center")),
                                fluidRow(h4("These data records are duplicated within the imported data set. This means these records match all fields of 
       another record in the data set except for the 'Activity Type' and 'Activity ID' fields", style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data5", "Save Data"))),
                                bsPopover("Save_data5", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("DUPS"))),
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       # Tt Mod, QAQC tabs ####
                       tabPanel("QAQC Decisions",
                                fluidRow((h3("Quality Assurance / Quality Control Decisions", style = "text-align: center")))
                                , fluidRow(h4("Modify characteristic data for consistent name, units, and sample fraction.", style = "text-align: center"))
                                , fluidRow(wellPanel(fluidRow(column(1), column(10, h3("QA/QC Data Set", style = "text-align: center")))
                                                    , fluidRow(column(1), column(10, "Changes made here will be reflected in the 'Filtered' data set.", style = "text-align: center"))
                                                    , fluidRow(column(1), column(10, "In the table below will be a table of records of parameter names, units, and sample fractions. 
                                                                                The user will have the ability to accept (Apply=TRUE) or refute (Apply=FALSE) each transformation.
                                                                                The user can edit the file below and save or edit in Excel and reload."
                                                                                , style = "text-align: center"
                                                                                )
                                                              )
                                                     #, fluidRow(column(3, downloadButton("SaveQAQC_Default", "Save Default QAQC File"))
                                                     #            # , bsPopover("SaveQAQC_Default", "Save Default QAQC", "Click to save an .XLSX file containing the default QAQC decisions."
                                                     #            #             , placement="top", trigger = "hover", options = list(container = "body"))
                                                     #           )
                                                    )
                                          )
                                , fluidRow(wellPanel(fluidRow(column(1), column(10, h3("QA/QC Decision File", style = "text-align: center")))
                                                    , fluidRow(column(1), column(10, "Save/load Excel file with QAQC information.", style = "text-align: center"))
                                                    , fluidRow(column(1), column(2, "Describe needing to use Excel and iterative nature of the process, save file
                                                                                , TRUE/FALSE, fields included, etc."))
                                                    
                                                    , fluidRow(br())
                                                    , fluidRow(column(3, fileInput("LoadQAQCFile","Load QAQC File",accept=".xlsx"))
                                                              )
                                                    , fluidRow(column(1,bsButton("UpdateQAQC", label="Update QAQC From File", style="primary")
                                                                     ,bsPopover("UpdateQAQC", "Update QA/QC", trigger = "hover", placement="right", options = list(container = "body")
                                                                                ,"This button updates the QA/QC selections from a user selected QA/QC Excel file. Must upload file first before clicking this button."))
                                                    )
                                                    # , fluidRow(column(1,bsButton("UpdateQAQC_Default", label="Update QAQC Defaults", style="primary")
                                                    #                  ,bsPopover("UpdateQAQC_Default", "Default QA/QC", trigger = "hover", placement="right", options = list(container = "body")
                                                    #                             ,"This button updates the QA/QC selections from a user selected QA/QC Excel file. Must upload file first before clicking this button."))
                                                    # )
                                                    )
                                          )
                                , fluidRow("show the Excel file here so can edit")
                                , fluidRow(column(3, downloadButton("SaveQAQC","Save QAQC File"))
                                           , bsPopover("SaveQAQC", "Save QAQC", "Click to save an .XLSX file containing the QAQC decisions.",
                                                       "top", trigger = "hover", options = list(container = "body"))
                                )
                                , br()
                                , fluidRow(column(3, bsButton("ApplyQAQC", label="Apply QAQC Decisions to Data", style="primary")))
                                , fluidRow(DT::dataTableOutput("dt_QAQC"))
                                #, fluidRow(DT::dataTableOutput("All_Data")) # adding lines disable upload of Saved Query.
                                ),
                       tabPanel("QAQC Advanced",
                                fluidRow((h3("Quality Assurance / Quality Control Advanced", style="text-align: center")))
                                , fluidRow("button for generating summary by decision.  2nd button for output.")
                                , fluidRow("button for generating and adding all parameter combinations to decision table.  Could then export on the basic tab.")
                                ),
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       tabPanel("Filtered Data",
                                fluidRow(
                                  h3("Filtered Data Set", style = "text-align: center")),
                                fluidRow( h4(" The Filtered Dataset includes only results with units and methods. Duplicate records have been removed. 
                                 This is the data set passed to the map and table on the 'View Data' page.",
                                             style = "text-align: center")),
                                fluidRow(column(5), column(2, downloadButton("Save_data6", "Save Data"))),
                                bsPopover("Save_data6", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                          "top", trigger = "hover", options = list(container = "body")),
                                br(),
                                fluidRow(DT::dataTableOutput("Filtered"))),
                       tabPanel("Summary",
                                fluidRow(
                                  h3("Click the button below to run a summary of the data", style = "text-align: center")),
                                fluidRow(column(5), column(2,
                                                           actionButton("SUMMARY", "Summarize Data"))),
                                br(),
                                conditionalPanel("output.Summ_run == 'yes'",
                                                 fluidRow(h4(" This table shows summary statistics of all unique combinations of station, media, characteristic, unit, and sample
                                fraction.", style = "text-align: center")),
                                                 fluidRow(column(5), column(2, downloadButton("Save_Summary_Data", "Save Data"))),
                                                 bsPopover("Save_Summary_Data", "Save Data", "Click to download a .tsv file containing the data being viewed.",
                                                           "top", trigger = "hover", options = list(container = "body")),
                                                 br()),
                                fluidRow(DT::dataTableOutput("SUMMARIZED"))))
  )}
