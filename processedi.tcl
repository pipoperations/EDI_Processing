#!/usr/bin/expect
######################################################################
##
## NAME
##  processedi.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO
##  Implement SMB for CommerciaHub
## 
## HISTORY
##  V0.01 05.30.2020 - Initial script for United Rentals
##
## NOTES
##  This program takes a list of files in a msg-out directory parses them for a unique customer number and matches to a list of customer attributes.
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

#======================================================================
# Global Variables
#======================================================================

set env(TERM) "xterm"
#log_file -a /var/log/edi.log
set ConfigFile {opentest.txt}
set Username ""
set Password ""
set GlobalPathin "/home/eclipseftp/ftp-in/"
set GlobalPathout "/home/eclipseftp/ftp-out"
set ConfigPath "/home/eclipseftp/scripts/config/"
set ProcessedPath "/home/eclipseftp/processed/"
set systemTime [clock seconds]

#=======================================================================
# Procedures
#=======================================================================

# Proceedure to list files in a directory specfied by "filepath"
#--------------------------------------------------------------------

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

# Proceedure to parse customer data files into a key value list
#--------------------------------------------------------------------

proc getCustomerData {filename} {
    set openFile [open $filename r]
    set data [read -nonewline $openFile]
    close $openFile
    ## split the file into lines
    set dataList [split $data "\n"]
    ## parse each line for key/value pairs with tab "\t" as the delimiter
    foreach dataLine $dataList {
        lappend CustomerData [string trim [string range $dataLine 0 [string first "\t" $dataLine]]]
        lappend CustomerData [string trim [string range $dataLine [string first "\t" $dataLine] [string length $dataLine]]]
    }
     return $CustomerData
}

# Returns a dictionary of customers given a directly list of config files.
#-------------------------------------------------------------------------

proc CustomerList {filelist} {
    set index 0
    foreach file $filelist {
        incr index
        dict set Customer $index [getCustomerData $file]
    }
    return $Customer
}

# Parses data files and extracts the customer ID an matches with a connection string
#-------------------------------------------------------------------------

proc ParseFile {filename ConfigPath} {
    # search file for unique key
    set dataFile [open $filename r]
    set dataLine [gets $dataFile]
    close $dataFile
    set Customers [CustomerList [ListFiles $ConfigPath]]
    dict for {index customer} $Customers {
        set CustomerNumber [dict get $customer CustomerNumber]
        set occurs [string first $CustomerNumber $dataLine]
        if { $occurs > 0 } {
            # return filename, and connection info (protocol, ip address, username, password)
            return $customer
        }
    }
    return 0
}

# Sends files via sftp or smb
#-------------------------------------------------------------------------

proc SendFile {file connectionstring} {

    ## populate our working variables from the customer dictionary of key value pairs

    set username [dict get $connectionstring Username]
    set password [dict get $connectionstring Password]
    set ipAddress [dict get $connectionstring Host]
    set protocol [dict get $connectionstring Protocol]
    set customerName [dict get $connectionstring CustomerName]

    ## make sure that a value exists for the PushDirectory

    if {[dict exists $connectionstring PushDirectory]} {
        set pushDirectory [dict get $connectionstring PushDirectory]
    } else {
        set pushDirectory ""
    }

    ## make sure that a value exists for the PullDirectory

    if {[dict exists $connectionstring PullDirectory]} {
        set pullDirectory [dict get $connectionstring PullDirectory]
    } else {
        set pushDirectory ""
    }
    puts "$protocol"
    switch $protocol {
        sftp {
            puts "$username $password $ipAddress"
            spawn sftp "$username@$ipAddress"
            expect {
                "assword:" {
                    send "$password\r"
                }
                "yes/no" {
                    send "yes\r"
                }
                "Permission"{
                    return 0
                }
            }
            expect "> " {send "cd $pushDirectory\r"}
            expect "> " { send "put $file\r" }
            expect "> " { send "quit" }
            return 0
        }
        smb {
            puts "$connectionstring"
            return 0
        }
        default {
            puts "Invalid protocol"
            return -code error \ "protocol not set or invalid."
        }
    }
}

# moves files that have been succesffully processed
#-------------------------------------------------------------------------

proc MoveFile {filename} {
    # move file after success
    upvar 2 ProcessedPath path
    file rename $filename $path
}

# gets a list of files from a directory
#-------------------------------------------------------------------------

proc printDir { inlist } {
     foreach item $inlist {
             if { [llength $inlist] > 1 } {
                    printDir $item
             } else {
                    # Place holder for ParseFile
                    puts "parse procedure $item"
                    ParseFile $item
             }
     }
}

# Finds customer number in the data files
#-------------------------------------------------------------------------

proc FindCustomerNumber {filelist} {
     foreach item $filelist {
             if { [llength $filelist] > 1 } {
                    FindCustomerNumber $item
             } else {
                    # Place holder for ParseFile
                    puts "parse procedure $item"
                    ParseFile $item
             }
     }
}

# Returns Customer by index in the dict (array)
#--------------------------------------------------------------------------

proc getCustomerbyIndex {CustomerDict Index} {
    set Customer [dict get $CustomerDict $Index]
    return $Customer
}

# Reads data files and matches them to customers, returns connection string
#--------------------------------------------------------------------------

proc ProcessCustomer {path configpath} {
    set dataFileList [ListFiles $path]
    foreach file $dataFileList {
        set hasCustomer [ParseFile $file $configpath]
        if { $hasCustomer > 0 } {
            set success [SendFile $file $hasCustomer]
            puts "Result code $success"
            if {$success == 0} {
                # SendFile should return 0 if it is successful 
                MoveFile $file
            }
        } else {
            puts "$file Doesn't have a customer $hasCustomer"
        }
    }
    return 0
}

#==========================================================================
# Main
#==========================================================================

puts "The time is: [clock format $systemTime -format %H:%M:%S]"
puts "The date is: [clock format $systemTime -format %D]"
puts [ProcessCustomer $GlobalPathin $ConfigPath]
# expect -timeout -1 eof
exit 0
