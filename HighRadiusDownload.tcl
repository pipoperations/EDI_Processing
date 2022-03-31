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

## Constants

set path /home/jpmorgan_sftp/upload/
set processingpath /home/jpmorgan_sftp/processing/
set processedpath /outbound/test/caa/ftp/Processed

set baifile "*EFT*"

## Production Constants
########################################################################
## set username ProtectiveIndustrialProducts
## set sftpsite sftp.highradius.com
## set rsakeyfile /root/highradius_id_rsa
## set Pulldirectory /inbound/prod/caapaymentremittance
## set imagepushDirectory inbound/prod/caaimagefiles

set username PIP
set sftpsite sftptest.receivablesradius.com
set rsakeyfile /root/highradius_id_rsa
set PullDirectory /outbound/test/caa/ftp
set processingpath /home/kore_sftp/processing



proc getfiles {rsaKey userName sftpSite path processingPath} { 
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "$prompt" {send "lcd $processingPath\r"}
    expect "$prompt" {send "cd $path\r" }
    expect "$prompt" {send "mget *\r"}
    expect "$prompt" {send "quit\r"}
}

#puts "$expect_out(1,string)"
#set responseIndex [lindex [split $expect_out(buffer) "\n"] end]
#foreach response $responseIndex {
#    puts "This is the response $responseIndex\r\r"
#}
# expect "sftp>" {send "quit\r"}
getfiles $rsakeyfile $username $sftpsite $PullDirectory $processingpath
return 0
