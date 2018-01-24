READ ME
If you're having issues with the log remora not including all lines that you checked in the effort selection menu, go to triton/Remoras/writeEffort.m, and change the debug flag on line 8 to true, so the line should read:
debug = true;
Doing this will allow you to see which lines have been deleted from the triton/Remoras/log_data/Detection_Effort_Template.xls template have been removed. If you go check the corresponding lines in the Detection_Effort_Template.xls, make sure that the format is consistent with the rest of the entries. 
