#!/usr/bin/expect
######################################################################
##
## NAME
##  parsetime.tcl
## #14
## AUTHOR
##  Brian P. Wood
##
## HISTORY
##  V0.01 04.01.2021 - Initial script for time parsing
##
## NOTES
##  This program takes system variable time and returns current month
##
#######################################################################

#======================================================================
# Global Variables
#======================================================================
set systemTime [clock seconds]
set month [clock format $systemTime -format %b]