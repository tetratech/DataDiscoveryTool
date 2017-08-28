NEWS; Data Discovery Tool QAQC Updates
================

<!-- NEWS.md is generated from NEWS.Rmd. Please edit that file -->
    #> Last Update: 2017-08-28 14:14:23

Version history.

Planned Updates
===============

-   Entered issues on GitHub for remaining planned updates. <https://github.com/tetratech/DataDiscoveryTool/issues>

-   Query Data
-   Boxes not always updating. Sometimes have to his "update" a 2nd time.
-   Entering a County without a state.

-   View Data
-   Filters not always updating. Sometimes have to hit "update" a 2nd time.
-   Error in original with removing then readding things. Leave "as is".

-   Check Data
-   QAQC. Need ability to "upload" a new decision file.
-   QAQC. Need ability to update decisions on screen.
-   QAQC. Summary stats by decision.
-   QAQC. Add all existing parameter combinations to decision file. Save to file and reload.

v1.1.1.9008
===========

2017-08-28

-   Working versions of buttons for Save and Load data on Check Data tab.
-   Added Save/Load Data tab on Check Data tab.

v1.1.1.9007
===========

2017-08-25

-   Moved "Load Data" from "Home" tab on Check Data to its own tab.
-   Modified "Load Data" button to use file saved from DDT via "All Data" tab.
-   Uses TSV file format instead of RDS.

v1.1.1.9006
===========

2017-08-25

-   Check Data. QAQC. Advanced. Added table for all combinations for QAQC. 2070825.

v1.1.1.9005
===========

2017-08-25

-   Address comments from USEPA HQ review.
-   Move new "action" buttons to same locations as existing buttons.
-   QAQC Decision file. Change header names.
-   Filters clean up names of new ones.
-   QAQC Decision table.
-   Fix bug to allow edits to Apply column.
-   Color code and bold Apply column.

v1.1.1.9004
===========

2017-08-21

-   QAQC. Decision file use different row for display.

v1.1.1.9003
===========

2017-08-18

-   Updates after USEPA review.
-   Query Data. Move new buttons alongside existing buttons. 20170818.
-   View Data. Move new buttons alongside existing buttons. 20170818.
-   View Data. Remove "code", "name", and "id" from new filters. 20170818.

v1.1.1.9002
===========

2017-08-18

-   QAQC. Renamed tab to QAQC Decisions and added QAQC Summary. 20170809.

-   Added QAQC Decisions table. 20170809.

-   QAQC Decisions table. Added "edit" feature. 20170809.
-   devtools::install\_github(<'rstudio/DT@feature/editor'>)

v1.1.1.9001
===========

2017-08-08

-   Various interim updates.

-   Add CheckData - QAQC buttons for save/load.
-   Save button keeps the header info and adds in the decision info.
-   Default decisions loaded at start up.

-   dataQAQC.R
-   Function to import QAQC decisions from Excel.
-   Function to merge and apply QAQC decisions (returns a data table).

-   Added DDT\_QAQC\_BLANK.xlsx and DDT\_QAQC\_Default.xlsx to "external".

-   UI.r. Identified Tt Mods.

v1.1.1.0000
===========

2017-08-04

-   Release version for EPA review.

v1.1.0.9014
===========

2017-08-04

-   Clean up formatting in 9013 code in Server.R. 20170804.
-   Query Data. Moved buttons up a line so all 4 appear on the screen without scrolling. 20170804.
-   

v1.1.0.9013
===========

2017-08-03

-   Updated Query Load button. Issue \#2. 20170803
-   Fixed issue with Counties not loading more than the first.
-   Fixed issue with UpdateSelectizeInput fields needing "items" in JSON options.
-   Fixed issue with UpdateSelectizeInput fields not working unless a date is provided.

v1.1.0.9012
===========

2017-08-02

-   Enabled "Load Data" button on the Check Data tab. Issue \#7. 20170802.

v1.1.0.9011
===========

2017-08-02

-   Had used a function in a file for the button. Removed but left in source() command. Removed here. Issue \#2. 20170802.

v1.1.0.9010
===========

2017-08-02

-   Added button to clear Query selections. Issue \#2. 20170802.

v1.1.0.9009
===========

2017-08-02

-   Fixed update Query so all input boxes are emptied before updating.
    Previously only new informatoin was being added. Issue \#2. 20170802.

v1.1.0.9008
===========

2017-08-02

-   Add additional fields to data in getData.R and server.R that are needed for the QAQC module. 20170802.

-   Minor edits to the QAQC tab. 20170331.

v1.1.0.9007
===========

2017-07-31

-   Another attempt to get ResultLower and ResultUpper in getData.R added to the commit. 20170731.

v1.1.0.9006
===========

2017-07-31

-   Name change for ResultLower and ResultUpper not picked up in last commit. 20170731.

v1.1.0.9005
===========

2017-07-31 (Interim Build)

-   Add tab "QA/QC" on the "Check Data" tab.
    This is the section with the checking for units, methods, and parameter names.

-   Previously modified "data" download (getData.R) to add 2 new fields "DetectionLimit\_Lo" (0) and "DetectionLimit\_Hi" (MDL). Changed names to "ResultLower" and "ResultUpper".

v1.1.0.9004
===========

2017-07-26

-   Non Detects on Check Data tab. Issue \#8
-   Comment out (remove) "Remove ND" option. 20170726.
-   Change ND default option to "1/2 MDL" (\#4). 20170726.

v1.1.0.9003
===========

2017-07-26

-   Resubmitted previous commit due to error in version number.

v0.0.0.9003
===========

2017-07-26

-   Added additional filters on the View Data page. Issue \#5.

-   Completed save/load queries. Issue \#2.

-   Added buttons to save/load filters. (not complete). Issue \#4.

-   Added button to save data on Check Data. (not complete). Issue \#7

v1.1.0.9002
===========

2017-07-18

-   Added ability to save and load queries. (not complete). Issue \#2. 20170718.

v1.1.0.9001
===========

2017-07-11

-   Added NEWS and README.

-   Added RStudio project file.

-   Added Notebook for tracking items with the update.

v1.1.0.9000
===========

2017-07-11

-   Created GitHub repository. 2017-06-16.

-   Pulled /app/tool/ files from v1.1 of the ddt into stand alone folder.

-   Uses R v3.3.1.
