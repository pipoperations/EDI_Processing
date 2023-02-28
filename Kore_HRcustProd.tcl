#!/usr/bin/expect
######################################################################
##
## NAME
##  Kore_HRcust.tcl
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
set path /home/kore_sftp/inbound/prod/custextract
set processedpath /home/kore_sftp/processed/
set username ProtectiveIndustrialProducts
set sftpsite sftp.highradius.com
set rsakeyfile /root/highradius_id_rsa
set pushDirectory /inbound/prod/custextract

# Proceedure to list files in a directory specfied by "filepath"
#--------------------------------------------------------------------
set Ledger_Type ar
set date [clock format [clock seconds] -format {%y-%m-%d}]
set time [clock format [clock seconds] -format %H:%M:%S]

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}


set filelist [ListFiles $path]
puts "$username $sftpsite"
puts "$time"
puts "$date"
puts "==============================================================="
spawn sftp -i $rsakeyfile "$username@$sftpsite"
foreach filename $filelist {
        expect "> " {send "cd \r"
        puts "$time"
        }
        expect "> " {send "cd $pushDirectory\r"
        puts "$time"
        }
        expect "> " {send "put $filename\r"
        puts "$time"
        }
}
expect "> " { send "quit\r" }
puts Done

foreach filename $filelist {
    file rename $filename $processedpath
}
