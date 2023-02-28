#!/usr/bin/expect
######################################################################
##
## NAME
##  parse820.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Find 820s in downloaded files
##
## HISTORY
##  V0.01 05.24.2022 - Initial script for Home Depot
## 
## NOTES
##  Looking for EDI 820s to push to HighRadius
##
#######################################################################

#======================================================================
# Global Variables
#======================================================================

set GlobalPathin "/home/eclipseftp/processed/Lowes-HomeDepot"

proc ParseFile {filename} {
    # search file for unique key
    set EDI820 "ST*820"
    set dataFile [open $filename r]
    set dataLine [gets $dataFile]
    close $dataFile
    set occurs [string first $EDI820 $dataLine]
    if { $occurs > 0 } {
            # return filename, and connection info (protocol, ip address, username, password)
            set puts $filename
    }
}
proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

proc Find820 {filelist} {
     foreach item $filelist {
             if { [llength $filelist] > 1 } {
                    Find820 $item
             } else {
                    # Place holder for ParseFile
                    ParseFile $item
             }
     }
}
puts $GlobalPathin
puts [Find820 [ListFiles $GlobalPathin]]
