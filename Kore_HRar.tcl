#!/usr/bin/expect
######################################################################
##
## NAME
##  Kore_HRar.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Create expect curl program to upload
##
## HISTORY
##  V0.01 01.07.2022 - Working alpha script
##
## NOTES 
##
#######################################################################

## Constants
set AuthToken "Authorization: Token cb16790fafa2e6a12095e3f097aa54bfd3812095e9457cc473df85d1a426e41d"
set path /home/kore_sftp/inbound/test/arextract
set processedpath /home/kore_sftp/processed/
set username PIP
set sftpsite sftptest.receivablesradius.com
set rsakeyfile /root/highradius_id_rsa
set pushDirectory /inbound/test/arextract

# Proceedure to list files in a directory specfied by "filepath"
#--------------------------------------------------------------------
set Ledger_Type ar
set date [clock format [clock seconds] -format {%y-%m-%d}]

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}


set filelist [ListFiles $path]
puts "$username $sftpsite"
spawn sftp -i $rsakeyfile "$username@$sftpsite"
foreach filename $filelist {
        expect "> " {send "cd \r"}
        expect "> " {send "cd $pushDirectory\r"}
        expect "> " {send "put $filename\r" }
}
expect "> " { send "quit\r" }
puts Done

foreach filename $filelist {
    file rename $filename $processedpath
}
