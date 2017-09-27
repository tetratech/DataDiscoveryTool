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
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       ## Tt Mod, Save/Load Data Button ####
                       tabPanel("Save/Load App Data",
                                wellPanel(fluidRow(h4("Save or Load Data Discovery Tool Data", style = "text-align: center"))
                                          #, fluidRow(br())
                                          , fluidRow("As an alternative to retrieving data each time the app is used the buttons below can be used to save data for a future session or load previously saved data for the current session.")
                                          , fluidRow(br())
                                          , fluidRow("After loading a dataset if you want to download a new dataset you must exit and re-enter the application.")
                                          , fluidRow(br())
                                          , fluidRow(column(2, downloadButton("SaveAppData","Save Data")))
                                          , fluidRow(br())
                                          , fluidRow(
                                                    column(7,
                                                   fileInput("LoadAppData","Load Data File",accept=".rda")  #future could add .rds for smaller files
                                                          )
                                                  )
                                          # fluidRow(br())
                                          # able to do in one step, don't need 'update' button (like query)
                                          # ,fluidRow(column(1,
                                          #                  bsButton("UpdateData", label="Update Data From File **NOT ACTIVE**", style="primary")
                                          #                  ,bsPopover("UpdateData", "Update Data", trigger = "hover", placement="right", options = list(container = "body")
                                          #                             ,"This button updates the data from a user selected data file. Must upload file first before clicking this button."))
                                          # )
                                          )
                                ),
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       # Tt Mod, QAQC tab ####
                       # tabPanel("QAQC Combinations",
                       #          fluidRow((h3("Quality Assurance / Quality Control Combinations", style="text-align: center")))
                       #          #, fluidRow("button for generating summary by decision.  2nd button for output.")
                       #          #, fluidRow("button for generating and adding all parameter combinations to decision table.  Could then export on the basic tab.")
                       #          
                       #          , fluidRow(column(12,DT::dataTableOutput('dt_QAQC_combos_data')))
                       # ),
                       tabPanel("QAQC Decisions",
                                fluidRow((h3("Quality Assurance / Quality Control Decisions", style = "text-align: center")))
                                , fluidRow(h4("Modify characteristic data for consistent name, units, and sample fraction.", style = "text-align: center"))
                                , fluidRow("Use the 'Add New Combinations' button below to add all new combinations of media, characteristic, sample fraction, and unit in the current data set 
                                            that are not represented in the QAQC Decisions table at the bottom of the page.
                                            Afterwards, you can use the 'Save QAQC File' button to save the combinations to Excel.")
                                , br()
                                , fluidRow(column(4, bsButton("QAQC_CombosAdd","Add New QAQC Decision Combinations", style="primary")
                                                  , bsPopover("QAQC_CombosAdd", "Update QA/QC Combinations", trigger = "hover", placement="right", options = list(container = "body")
                                                              ,"This button updates the QA/QC decisions table with any new combinations from the current data."))
                                                  )
                                , br()
                                , fluidRow(wellPanel(fluidRow(column(1), column(10, h3("QA/QC Decision File", style = "text-align: center")))
                                                    #, fluidRow(column(1), column(10, "Save/load Excel file with QAQC information.", style = "text-align: center"))
                                                    #, fluidRow(column(1), column(10, "Changes made here will be reflected in the 'Filtered' data set.", style = "text-align: center"))
                                                    , fluidRow(column(1), column(10, "The table below contains the unique combinations of activity media, parameter names, units, and sample fractions. 
                                                                                  The combinations are from the QAQC Decisions Excel file.  The user can edit the 'Apply QAQC' field below 
                                                                                or edit the Excel file and reload with the 'Browse' button below..
                                                                                Clicking the 'Apply QAQC Decions to Data and Save' allows the user has the ability to accept (Apply QAQC=TRUE) or refute (Apply QAQC=FALSE) each transformation.
                                                                                "
                                                                                 , style = "text-align: center"
                                                    )
                                                    )
                                                    #, fluidRow(column(3, downloadButton("SaveQAQC_Default", "Save Default QAQC File"))
                                                    #            # , bsPopover("SaveQAQC_Default", "Save Default QAQC", "Click to save an .XLSX file containing the default QAQC decisions."
                                                    #            #             , placement="top", trigger = "hover", options = list(container = "body"))
                                                    #           )
                                                    
                                                   # , fluidRow(br())
                                                    , fluidRow(column(3, downloadButton("SaveQAQC","Save QAQC Decisions File"))
                                                               , bsPopover("SaveQAQC", "Save QAQC", "Click to save an .XLSX file containing the QAQC decisions.",
                                                                           "top", trigger = "hover", options = list(container = "body"))
                                                               )
                                                    , br()
                                                    , fluidRow(column(7, fileInput("LoadQAQCFile","Load QAQC File",accept=".xlsx"))
                                                              )
                                                    , fluidRow(column(1,bsButton("UpdateQAQC", label="Update QAQC Decisions From File", style="primary")
                                                                     ,bsPopover("UpdateQAQC", "Update QA/QC", trigger = "hover", placement="right", options = list(container = "body")
                                                                                ,"This button updates the QA/QC selections from a user selected QA/QC Excel file. Must upload file first before clicking this button."))
                                                              )
                                                    , br()
                                                   #, br()
                                                    #, fluidRow(column(3, bsButton("ApplyQAQC", label="Apply QAQC Decisions to Data", style="primary")))
                                                    
                                                    # , fluidRow(column(1,bsButton("UpdateQAQC_Default", label="Update QAQC Defaults", style="primary")
                                                    #                  ,bsPopover("UpdateQAQC_Default", "Default QA/QC", trigger = "hover", placement="right", options = list(container = "body")
                                                    #                             ,"This button updates the QA/QC selections from a user selected QA/QC Excel file. Must upload file first before clicking this button."))
                                                    # )
                                                   
                                                    )#wellPanel.END
                                          )#fluidRow.big.END
                                , fluidRow("The button below applies the QAQC decisions to the filtered data and saves the file to a tab-separated file (TSV).")
                                , fluidRow(column(3, downloadButton("SaveQAQCApply_filtered_data", "Apply QAQC Decisions to Data and Save")))
                                # ,bsPopover("SaveQAQCApply", "Save QA/QC Applied to Data", trigger = "hover", placement="right", options = list(container = "body")
                                #            ,"This button saves the QA/QC decisions as applied to the current data set. 
                                #            To continue working with the revised data set you must return to 'Save/Load App Data' and load the file you are creating."))))
                                , fluidRow(column(12,DT::dataTableOutput('dt_QAQC')))
                                ),
                       # #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       # # Tt Mod, Data Summary ####
                       tabPanel("Data Summary Plots",
                                fluidRow(h4("Data summary plots and tables based on filtered data.", style="text-align:center"))
                                ,br()
                                , fluidRow("Data used is 'filtered' data.")
                                ,br()
                                , fluidRow("Plots A:G are CDFs by Site for results, activities, samples, parameters, begin year, end year, and number of years.")
                                , fluidRow("Plot H is a scatterplot by site for begin and end year.")
                                ,br()
                                , fluidRow("Table 1 is number of sites by county.")
                                , fluidRow("Table 2 is number of sites by county and monitoring location type.")
                                , fluidRow("Table 3 is SiteID with number of results, begin/end year, number of activities, samples, and paramters.")
                                ,br()
                                ,fluidRow("Click the button below to save the plots and tables report as an HTML file.")
                                , br()
                                ,fluidRow(column(1, downloadButton("SaveViewDataSummary","Save Data Summary")))
                       ),
                       # #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                       # tabPanel("QAQC Data Set",
                       #          fluidRow((h3("Quality Assurance / Quality Control Data Set", style="text-align: center")))
                       #          #, fluidRow("button for generating summary by decision.  2nd button for output.")
                       #          #, fluidRow("button for generating and adding all parameter combinations to decision table.  Could then export on the basic tab.")
                       #          , fluidRow("Shown in table below are all of the QAQC Decisions as applied (in the QAQC Decisions tab) to the 'filtered' data.")
                       #          , fluidRow("Use the button below to download the QAQC data set.")
                       #          , fluidRow(column(3, downloadButton("SaveQAQCDataSet","Save QAQC Data Set"))
                       #                            , bsPopover("SaveQAQCDataSet", "Save QAQCed Data Set).", trigger = "hover", placement="right", options = list(container = "body")
                       #                                        ,"This buttons saves the data as a TSV file with the QAQC decisions applied (in the QAQC Advanced tab)."))
                       #          ),
                       #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
