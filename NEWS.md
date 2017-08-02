NEWS; Data Discovery Tool QAQC Updates
================

<!-- NEWS.md is generated from NEWS.Rmd. Please edit that file -->
    #> Last Update: 2017-08-02 19:38:33

Version history.

Planned Updates
===============

-   Entered issues on GitHub for remaining planned updates. <https://github.com/tetratech/DataDiscoveryTool/issues>

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
