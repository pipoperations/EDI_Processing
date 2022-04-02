#!/usr/bin/expect
######################################################################
##
## NAME
##  HighRadiusDownload.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: 
##
## HISTORY
##  V0.01 03.08.2022 - Initial script
##  
##
## NOTES 
##
#######################################################################

#======================================================================
## Test Constants
#======================================================================

set username PIP
set sftpsite sftptest.receivablesradius.com
set rsakeyfile /root/highradius_id_rsa
set PullDirectory /outbound/test/caa/ftp
set processingpath /home/kore_sftp/processing
set path /home/kore_sftp/inbound/test/arextract
set processedpath /outbound/test/caa/ftp/Processed
set pushDirectory /home/kore_sftp/outbound/test

#======================================================================
## Production Constants
#======================================================================

set systemTime [clock seconds]

#=======================================================================
# Procedures
#=======================================================================

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

proc getfiles {rsaKey userName sftpSite path processingPath} { 
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "$prompt" {send "lcd $processingPath\r"}
    expect "$prompt" {send "cd $path\r" }
    expect "$prompt" {send "mget *\r"}
    expect "$prompt" {send "rm *\r"}
    expect "$prompt" {send "quit\r"}
}
proc putfiles {from to} {
    set filelist [ListFiles $from]
    foreach filename $filelist {
    file rename $filename $to
    }
}

proc uploadfiles {rsaKey userName sftpSite path processingPath} {
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "$prompt" {send "lcd $processingPath\r"}
    expect "$prompt" {send "cd $path\r" }
    expect "$prompt" {send "mput *\r"}
    expect "$prompt" {send "quit\r"}    
}

#==========================================================================
# Main
#==========================================================================

puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Starting script"
puts "The time is: [clock format $systemTime -format %H:%M:%S]"
puts "The date is: [clock format $systemTime -format %D]\r\n\r\n"
getfiles $rsakeyfile $username $sftpsite $PullDirectory $processingpath
puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
uploadfiles $rsakeyfile $username $sftpsite $processedpath $processingpath
puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
putfiles $processingpath $pushDirectory
return 0
