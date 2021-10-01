#!/usr/bin/expect
######################################################################
##
## NAME
##  PIMMove.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Create expect file copy 
##
## HISTORY
##  V0.01 09.30.2021 - Initial script
##  
## NOTES 
##  This program moves files from the PIM export to eclipse and New products file from eclipse msg-in to PIM import
##
#######################################################################

## Constants
#--------------------------------------------------------------------

set pimexportpath /mnt/cifs-prod/import
set msginpath /mnt/eclipse/msg-in
set pimimportpath /mnt/cifs-prod/export/eclipse/
set stringmatch *PIM_Upload_NewProduct_Created*
set date [clock seconds]
set lengthofday 86400

# procedure to list files in a directory
#--------------------------------------------------------------------

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

# moves files proceedure
#-------------------------------------------------------------------------

proc MoveInboundFile {from to} {
    # move local file from drop to pushdirectory
    file copy -force $from $to
}

# procedure to move files from PIM Export to eclipse msg-in
#--------------------------------------------------------------------

proc pimtoeclipse {pathfrom pathto} {
    upvar #0 date mydate
    upvar #0 lengthofday lengthofday
    set filelist [ListFiles $pathfrom]
    foreach filename $filelist {
    file stat $filename attributes
    set Reference_Date $attributes(mtime)
    if {[expr $mydate - $Reference_Date] < $lengthofday } {
        puts $filename
        MoveInboundFile $filename $pathto
        }
    }
}

# procedure to move files from eclipse msg-in to PIM Import
#--------------------------------------------------------------------

proc eclipsetopim {pathfrom pathto} {
    upvar #0 date mydate
    upvar #0 stringmatch mystringmatch
    upvar #0 lengthofday mylengthofday
    set filelist [ListFiles $pathfrom]
    foreach filename $filelist {
    file stat $filename attributes
    set Reference_Date $attributes(mtime)
    if {[expr [expr $mydate - $Reference_Date] < $mylengthofday] && [string match $mystringmatch $filename]} {
        set namesuffix "[clock format $attributes(mtime) -format {%Y%m%d}].csv"
        set filerename "PIP_IREF_IMPORT_$namesuffix"
        puts $filerename
        set path "$pathto$filerename"
        MoveInboundFile $filename $path
        }
    }
}

# main
#--------------------------------------------------------------------

puts [clock format $date -format {%m-%d-%y}]
pimtoeclipse $pimexportpath $msginpath
eclipsetopim $msginpath $pimimportpath
