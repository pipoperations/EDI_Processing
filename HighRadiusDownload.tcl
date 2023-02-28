#!/usr/bin/expect -f
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

#======================================================================
## Test Constants
#======================================================================

set username bpwood
set sftpsite devny-web01.pipusa.com
set rsakeyfile /home/pipadmin/.ssh/id_rsa_bpwood
set PullDirectory /home/bpwood
set processingpath /home/kore_sftp/processing
set path /home/kore_sftp/inbound/test/arextract
set processedpath /home/bpwood/Processed
set pushDirectory /home/kore_sftp/outbound/test
set timeout 30

#======================================================================
## Production Constants
#======================================================================

set systemTime [clock seconds]

#=======================================================================
# Procedures
#=======================================================================

proc ListFiles {filepath} {
    # list file in the directory
    set filelist [glob -types f -nocomplain -directory $filepath *]
    return $filelist
}

proc getfiles {rsaKey userName sftpSite path processingPath} { 
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "$prompt" {send "lcd $processingPath\r"}
    expect "$prompt" {send "cd $path\r" }
    expect "$prompt" {send "mget *\r"}
    expect "$prompt" {send "rm *\r"}
    expect "$prompt" {send "quit\r"}
    expect eof
}
proc putfiles {from to} {
    set filelist [ListFiles $from]
    foreach filename $filelist {
    file rename $filename $to
    }
}

proc uploadfiles {rsaKey userName sftpSite path processingPath} {
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "sftp>" {send "lcd $processingPath\r"}
    expect "sftp>" {send "cd $path\r" }
    expect "sftp>" {send "mput *\r"}
    expect "sftp>" {send "quit\r"}
    expect eof    
}
proc chkduplicates {rsaKey userName sftpSite path processedPath} {
    spawn sftp -i $rsaKey "$userName@$sftpSite"
    set prompt "sftp>"
    expect "sftp>" {send "lcd $processedPath\r"}
    expect "sftp>" {send "ls -1\r"}
    expect "ls -1"
    expect "sftp>"
    puts "buffer $expect_out(buffer)"
    set file_list1 $expect_out(buffer)
    send "cd $path\r"
    expect "sftp>" {send "ls -1\r"}
    expect "ls -1"
    expect "sftp>"
    puts "buffer $expect_out(buffer)"
    set file_list2 $expect_out(buffer)
    foreach remote_file1 [split $file_list1 "\r"] {
        # get the file name without the path
        set remote_file_name1 [file tail $remote_file1]

        # loop through the files in the second directory
        set i 1
        foreach remote_file2 [split $file_list2 "\r"] {
            # get the file name without the path
            set remote_file_name2 [file tail $remote_file2]
            puts "index $i"
            foreach char [split $remote_file_name1 {}] {
                puts [scan $char c%]
            }
            puts "and"
            puts [scan $remote_file_name2 c%]
            incr i
            # check if the two file names match and contain the search string
            if {$remote_file_name1 ne "ls -1" | $remote_file_name2 ne "sftp>" | $remote_file_name1 ne "" | $remote_file_name2 ne ""} {
                if {$remote_file_name1 eq $remote_file_name2} {
                    puts "Found a match: $remote_file_name1 and $remote_file_name2\r"
                    send "exit\r"
                    expect eof
                    exit
                }
            }
        }
    }
    send "exit\r"
    expect eof
}


#==========================================================================
# Main
#==========================================================================

puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
puts "Starting script"
puts "The time is: [clock format $systemTime -format %H:%M:%S]"
puts "The date is: [clock format $systemTime -format %D]\r\n\r\n"
chkduplicates $rsakeyfile $username $sftpsite $PullDirectory $processedpath
puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
getfiles $rsakeyfile $username $sftpsite $PullDirectory $processingpath
puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
uploadfiles $rsakeyfile $username $sftpsite $processedpath $processingpath
puts "\r\n\r\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
putfiles $processingpath $pushDirectory
return 0