#!/usr/bin/expect
######################################################################
##
## NAME
##  processedi.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Implement sftp retrieve 
## 
## HISTORY
##  V0.0 06.24.2020 - Initial script
##
## NOTES
##  This program retrieves files from EDI partners via sftp/ftp
##  Customer files should be in this format
##  CustomerName     ABC Corp
##  CustomerNumber   1234
##  Protocol         sftp
##  Host       10.10.10.10
##  Username         Brianisawesome
##  Password         W3lc0m3!
##  PushDirectory    ftp-in
##  PullDirectory    ftp-out
##  Use tabs between keys and values
##
#######################################################################

set env(TERM) "xterm"
#log_file -a /var/log/edi.log
set ConfigFile {opentest.txt}
set Username ""
set Password ""
set GlobalPathin "/home/eclipseftp/ftp-in/"
set GlobalPathout "/home/eclipseftp/ftp-out"
set ConfigPath "/home/eclipseftp/scripts/config/"
set ProcessedPath "/home/eclipseftp/processed/"
