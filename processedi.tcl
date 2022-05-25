#!/usr/bin/expect
######################################################################
##
## NAME
##  processedi.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Implement SMB for CommerciaHub
## TODO: Maybe enhance with sqlite database file instead of txt customer files
## TODO: #14 Implement archive by moth for Jay 👎
##
## HISTORY
##  V0.01 05.30.2020 - Initial script for United Rentals
##  V0.02 04.01.2021 - File copy for logo team
## NOTES
##  This program takes a list of files in a msg-out directory parses them for a unique customer number and matches to a list of customer attributes.
##  customer files should be in this format
##  CustomerName     ABC Corp
##  customerNumber   1234
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
set timeout 20
# log_file -a /var/log/edi.log
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

# Proceedure to parse customer data files into a key value list.
#--------------------------------------------------------------------

proc GetCustomerData {filename} {
    set openfile [open $filename r]
    set data [read -nonewline $openfile]
    close $openfile
    ## split the file into lines
    set datalist [split $data "\n"]
    ## parse each line for key/value pairs with tab "\t" as the delimiter
    foreach dataline $datalist {
        lappend customerdata [string trim [string range $dataline 0 [string first "\t" $dataline]]]
        lappend customerdata [string trim [string range $dataline [string first "\t" $dataline] [string length $dataline]]]
    }
     return $customerdata
}

# Returns a dictionary of customers given a directly list of config files.
#-------------------------------------------------------------------------

proc CustomerList {filelist} {
    set index 0
    foreach file $filelist {
        incr index
        dict set customer $index [GetCustomerData $file]
    }
    return $customer
}

# Parses data files and extracts the customer ID an matches with a connection string.
#-------------------------------------------------------------------------

proc ParseFile {filename configpath} {
    # search file for unique key
    set dataFile [open $filename r]
    set dataline [gets $dataFile]
    close $dataFile
    set customers [CustomerList [ListFiles $configpath]]
    dict for {index customer} $customers {
        set customerNumber [dict get $customer customerNumber]
        set occurs [string first $customerNumber $dataline]
        if { $occurs > 0 } {
            puts $filename $CustomerNumber
            return $customer
        }
    }
    return 0
}

# Sends files via sftp or smb.
#-------------------------------------------------------------------------

proc SendFile {file connectionstring } {

    ## populate our working variables from the customer dictionary of key value pairs

    set username [dict get $connectionstring Username]
    set password [dict get $connectionstring Password]
    set ipaddress [dict get $connectionstring Host]
    set protocol [dict get $connectionstring Protocol]
    set customername [dict get $connectionstring CustomerName]

    ## make sure that a value exists for the PushDirectory

    if {[dict exists $connectionstring PushDirectory]} {
        set pushdirectory [dict get $connectionstring PushDirectory]
    } else {
        set pushdirectory ""
    }

    ## make sure that a value exists for the PullDirectory

    if {[dict exists $connectionstring PullDirectory]} {
        set pulldirectory [dict get $connectionstring PullDirectory]
    } else {
        set pulldirectory ""
    }
    puts "$customerName"
    puts "$protocol"
    switch $protocol {
        sftp {
            puts "$username $password $ipaddress"
            spawn sftp "$username@$ipaddress"
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
            expect "> " {send "cd $pushdirectory\r"}
            expect "> " { send "put $file\r" }
            expect "> " { send "quit\r" }
            return 0
        }
        smb {
            puts "$connectionstring"
            return 0
        }
        local {
            MoveInboundFile $file $pushDirectory

            return 0
        }
        default {
            puts "Invalid protocol"
            return -code error \ "protocol not set or invalid."
        }
    }
}

# moves outbound files that have been succesffully processed.
#-------------------------------------------------------------------------

proc MoveOutboundFile {filename customer} {
    # move file after success
    upvar 2 ProcessedPath path
    set systemTime [clock seconds]
    set month [clock format $systemTime -format %b-%Y]
    set pathcheck "$path/$customer"
    if { [file exists $pathcheck] == 0 } {
        exec mkdir $pathcheck
    }
    set pathdate "$path/$customer/$month"
    if { [file exists $pathdate] == 0 } {
        exec mkdir $pathdate
    }
    file rename $filename $pathdate
    }

# moves inbound files
#-------------------------------------------------------------------------

proc MoveInboundFile {from to} {
    # move local file from drop to pushdirectory
    file attributes $from -group eclipseftp -permissions 00666
    if { [file exists $to] == 0 } {
        exec mkdir $to
    }
    file copy -force $from $to
    foreach filename [ListFiles $to] {
        file attributes $filename -permissions 00666
    }
}
# gets a list of files from a directory
#-------------------------------------------------------------------------

proc PrintDir { inlist } {
     foreach item $inlist {
             if { [llength $inlist] > 1 } {
                    PrintDir $item
             } else {
                    # Place holder for ParseFile
                    puts "parse procedure $item"
                    ParseFile $item
             }
     }
}

# Finds customer number in the data files.
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

# Returns customer by index in the dict (array).
#--------------------------------------------------------------------------

proc GetCustomerbyIndex {customercict index} {
    set customer [dict get $customercict $index]

    return $customer
}

# Reads data files and matches them to customers, then sends them via protocol
#--------------------------------------------------------------------------

proc ProcessFilesOut {path configpath} {
    set dataFileList [ListFiles $path]
    foreach file $dataFileList {
        set hasCustomer [ParseFile $file $configpath]
        if { $hasCustomer > 0 } {
            set customername [dict get $hasCustomer CustomerName]
            set success [SendFile $file $hasCustomer]
            puts "Result code $success"
            if {$success == 0} {
                # SendFile should return 0 if it is successful
                MoveOutboundFile $file $customername
            }
        } else {
            puts "$file Doesn't have a customer $hascustomer"
        }
    }
    return 0
}

# Reads config files and looks for input files in the PushDirectory
#--------------------------------------------------------------------------

proc ProcessFilesIn {pathout path} {
#    upvar GlobalPathout pathin
    upvar ProcessedPath processedpath
    set customerFiles [ListFiles $path]
    set list [CustomerList $customerFiles]
    dict for {index customer} $list {
        if {[dict exist $customer PullDirectory]} {
            set protocol [dict get $customer Protocol]
            set customername [dict get $customer CustomerName]
            switch $protocol {
                local {
                    set directory [dict get $customer PullDirectory]
                    puts $customername
                    foreach filename [ListFiles $directory] {
                        MoveInboundFile $filename $pathout
                        MoveOutboundFile $filename $customername
                    }
                }
                sftp {
                    set username [dict get $customer Username]
                    set password [dict get $customer Password]
                    set ipAddress [dict get $customer Host]
                    set pullDirectory [dict get $customer PullDirectory]
                    puts $customername
                    ## puts "$username $password $ipAddress"
                    spawn sftp "$username@$ipAddress"
                    expect {
                        "assword:" {
                           send "$password\r"
                        }
                        "yes/no" {
                            send "yes\r"
                        }
                        "Permission"{
                            close
                            continue
                        }
                    }
                    expect "> " {send "cd $pullDirectory\r"}
                    expect "> " { send "mget * $pathout\r"}
                    expect {
                        " not found." {
                            send "quit\r"
                            continue
                        }
                        "> " {
                            send "rm * \r"
                        }
                    }
                    expect "> " {send "quit\r" }
                    foreach file [ListFiles $pathout] {
                        file attributes $file -group eclipseftp -permissions 00666
                        set fullprocessedpath "$processedpath/$customername"
                        MoveInboundFile $file $fullprocessedpath

                    }
                }
            }
        }
    }
    return 0
}

#==========================================================================
# Main
#==========================================================================

puts "Starting script"
puts "The time is: [clock format $systemTime -format %H:%M:%S]"
puts "The date is: [clock format $systemTime -format %D]"

# copy output files
puts "Files out succeded [ProcessFilesOut $GlobalPathin $ConfigPath]"

# copy input files
puts "Files in succeded [ProcessFilesIn $GlobalPathout $ConfigPath]"
set systemTime [clock seconds]
set month [clock format $systemTime -format %b-%Y]
puts $month
# expect -timeout -1 eof

exit 0
