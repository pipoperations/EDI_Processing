#!/usr/bin/expect
######################################################################
##
## NAME
##  jpmorganhighradius.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Create expect to decrypt, encrypt with new key and upload for JPMorgan to HighRadius bank files
##
## HISTORY
##  V0.01 11.04.2021 - Initial script
##  V0.02 11.09.2021 - Working test code
##
## NOTES 
##
#######################################################################

## Constants
set AuthToken "Authorization: Token cb16790fafa2e6a12095e3f097aa54bfd3812095e9457cc473df85d1a426e41d"
set path /home/jpmorgan_sftp/upload/
set processingpath /home/jpmorgan_sftp/processing/
set processedpath /home/jpmorgan_sftp/processed/
set baifile "*EFT*"
set username ProtectiveIndustrialProducts
set sftpsite sftp.highradius.com
set rsakeyfile /root/highradius_id_rsa
set pushDirectory /inbound/prod/caapaymentremittance
set imagepushDirectory inbound/prod/caaimagefiles
set timeout 30

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

set filelist [ListFiles $path]
foreach filename $filelist {
    puts $filename
    set justfilename [file tail $filename]
    eval exec -ignorestderr --  gpg --output $processingpath${justfilename} -v --decrypt --batch $filename
    file delete $filename
}

set filelist [ListFiles $processingpath]
foreach filename $filelist {
        eval exec -ignorestderr -- gpg -e -r saisriker.peddi@highradius.com $filename
        file rename $filename $processedpath
}

set filelist [ListFiles $processingpath]
puts "$username $sftpsite"
spawn sftp -i $rsakeyfile "$username@$sftpsite"
expect "> " {send "progress \r"}
foreach filename $filelist {
    if [string match $baifile $filename] {
        expect "> " {send "cd \r"}
        expect "> " {send "cd $pushDirectory\r"}
        expect "> " {send "put $filename\r" }
    } else {
        expect "> " {send "cd \r"}
        expect "> " {send "cd $imagepushDirectory\r"}
        expect "> " {send "put $filename\r" }
    }
}
expect "> " { send "quit\r" }
puts Done

foreach filename $filelist {
    file delete $filename
}
