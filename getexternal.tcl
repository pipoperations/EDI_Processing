#!/usr/bin/expect
set env(TERM) "xterm"
#log_file -a /var/log/edi.log
set ConfigFile {opentest.txt}
set Username ""
set Password ""
set GlobalPathin "/home/eclipseftp/ftp-in/"
set GlobalPathout "/home/eclipseftp/ftp-out"
set ConfigPath "/home/eclipseftp/scripts/config/"
set ProcessedPath "/home/eclipseftp/processed/"

## This program takes a list of connection config files in 
## Customer files should be in this format
## CustomerName     ABC Corp
## CustomerNumber   1234
## Protocol         sftp
## Host       10.10.10.10
## Username         Brianisawesome
## Password         W3lc0m3!
## PushDirectory    ftp-in
## PullDirectory    ftp-out
##  Use tabs between keys and values
