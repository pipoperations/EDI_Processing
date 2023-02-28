#!/usr/bin/expect
######################################################################
##
## NAME
##  UploadFileRest.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Create expect curl program to upload
##
## HISTORY
##  V0.01 08.20.2021 - Initial script
##  V1.00 09.06.2021 - Working alpha script
##
## NOTES 
##
#######################################################################

## Constants
set AuthToken "Authorization: Token bc4a678384584fbd92ee0c0fc6deaa11506a61d6f6218d0f633ef011da2c0906"
set path /home/kore_sftp/ftp-up/
set processedpath /home/kore_sftp/processed/

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
foreach filename $filelist {
    file stat $filename attributes
    set Reference_Date [clock format $attributes(mtime) -format {%Y-%m-%d}]
    puts $filename
    puts $Reference_Date
    if {[string match "*OPENAR*" $filename]} { 
        set Report_Type open
        set headers [list -vsSH "Authorization: Token bc4a678384584fbd92ee0c0fc6deaa11506a61d6f6218d0f633ef011da2c0906" -H "Content-Type: text/csv" -H "Reference-Date: $Reference_Date" -H "Report-Type: $Report_Type" -H "Ledger-Type: $Ledger_Type" -H "Ledger-Code: PIP_INC_AR" -X POST -T $filename https://pip.cashanalytics.com/api/ledger_transaction_uploaders]
        catch {exec -keepnewline curl {*}$headers} options result
        puts "$options $result"
        file rename $filename $processedpath
    } elseif {[string match "*_INVPAY_*" $filename]} {
        set Report_Type cleared
        set headers [list -vsSH "Authorization: Token bc4a678384584fbd92ee0c0fc6deaa11506a61d6f6218d0f633ef011da2c0906" -H "Content-Type: text/csv" -H "Reference-Date: $Reference_Date" -H "Report-Type: $Report_Type" -H "Ledger-Type: $Ledger_Type" -H "Ledger-Code: PIP_INC_AR" -X POST -T $filename https://pip.cashanalytics.com/api/ledger_transaction_uploaders]
        catch {exec -keepnewline curl {*}$headers} options result
        puts "$options $result"
        file rename $filename $processedpath
    }
}