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
## TODO: #14 Implement archive by month for Jay 👎
##
## HISTORY
##  V0.01 05.30.2020 - Initial script for United Rentals
##  V0.02 04.01.2021 - File copy for logo team
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
set timeout 20
# log_file -a /var/log/edi.log
set ConfigFile {opentest.txt}
set Username ""
set Password ""
set GlobalPathin "/home/eclipseftp/test/ftp-in/"
set GlobalPathout "/home/eclipseftp/test/ftp-out"
set ConfigPath "/home/eclipseftp/scripts/config/test/"
set ProcessedPath "/home/eclipseftp/processed/"
set systemTime [clock seconds]

#=======================================================================
# Procedures
#=======================================================================

proc is_empty {string} {
    expr {![binary scan $string c c]}
}

proc not_empty {string} {
    expr {![is_empty $string]}
}


# Proceedure to list files in a directory specfied by "filepath"
#--------------------------------------------------------------------

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

# Proceedure to parse customer data files into a key value list.
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

# Parses data files and extracts the customer ID an matches with a connection string.
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

# Sends files via sftp or smb.
#-------------------------------------------------------------------------

proc SendFile {file connectionstring } {

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
        set pullDirectory ""
    }
    if {[dict exists $connectionstring RsaKey]} {
        set RsaKey [dict get $connectionstring RsaKey]
    } else {
        set RsaKey ""
        puts "No RSAKey"
    }
    puts "$customerName"
    puts "$protocol"
    switch $protocol {
        sftp {
            if {[not_empty $RsaKey]} {
                    spawn sftp -i /root/.ssh/$RsaKey -P 1224 "$username@$ipAddress"
                } else {
                    spawn sftp "$username@$ipAddress"
            }
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

# Returns Customer by index in the dict (array).
#--------------------------------------------------------------------------

proc getCustomerbyIndex {CustomerDict Index} {
    set Customer [dict get $CustomerDict $Index]

    return $Customer
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
            puts "$file Doesn't have a customer $hasCustomer"
        }
    }
    return 0
}

# Reads config files and looks for input files in the PushDirectory
#--------------------------------------------------------------------------

proc ProcessFilesIn {pathout path} {
#    upvar GlobalPathout pathin
    upvar ProcessedPath processedpath
    set 820Path "/home/inovis/820/"
    set customerFiles [ListFiles $path]
    set list [CustomerList $customerFiles]
    dict for {index customer} $list {
        if {[dict exist $customer PullDirectory]} {
            set protocol [dict get $customer Protocol]
            set customername [dict get $customer CustomerName]
            puts $protocol
            switch $protocol {
                local {
                    set directory [dict get $customer PullDirectory]
                    puts $customername
                    foreach filename [ListFiles $directory] {
                        MoveInboundFile $filename $pathout
                        MoveOutboundFile $filename $customername
                    }
                    foreach file [ListFiles $pathout] {
                        file attributes $file -group eclipseftp -permissions 00666
                    }
                }
                sftp {
                    set username [dict get $customer Username]
                    set password [dict get $customer Password]
                    set ipAddress [dict get $customer Host]
                    set pullDirectory [dict get $customer PullDirectory]
                    puts $customername
                    if {[dict exists $customer RsaKey]} {
                        set RsaKey [dict get $customer RsaKey]
                    } else {
                        set RsaKey ""
                        puts "No RSAKey"
                    }
                    ## puts "$username $password $ipAddress"
                    if {[not_empty $RsaKey]} {
                        spawn sftp -i /root/.ssh/$RsaKey -P 1224 "$username@$ipAddress"
                    } else {
                        spawn sftp "$username@$ipAddress"
                    }

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
                        timeout {
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
    foreach file [ListFiles $pathout] {
            set is820 [Parse820File $file]
            if {$is820 > 0} {
                set ediFile "$file.edi"
                file rename  $file $ediFile
                puts $file
                MoveInboundFile $ediFile $820Path
            }
        }
    return 0

}

# Parses file to identify 820s
#---------------------------------------------------------------------------

proc Parse820File {filename} {
    # search file for unique key
    set EDI820 "ST*820"
    set dataFile [open $filename r]
    set dataLine [gets $dataFile]
    close $dataFile
    set occurs [string first $EDI820 $dataLine]
    if { $occurs > 0 } {
           return 1
    }
    return 0
}

#==========================================================================
# Main
#==========================================================================

puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Starting script"
puts "The time is: [clock format $systemTime -format %H:%M:%S]"
puts "The date is: [clock format $systemTime -format %D]"

# copy output files
puts "Files out succeded [ProcessFilesOut $GlobalPathin $ConfigPath]"

# copy input files
puts "Files in succeded [ProcessFilesIn $GlobalPathout $ConfigPath]"
puts "820 Files" 
set systemTime [clock seconds]
set month [clock format $systemTime -format %b-%Y]
puts $month
# expect -timeout -1 eof

exit 0
