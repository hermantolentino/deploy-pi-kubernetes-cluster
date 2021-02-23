#!/usr/bin/expect -f
# wrapper to make passwd(1) be non-interactive
# username is passed as 1st arg, passwd as 2nd

set username [lindex $argv 0]
set password [lindex $argv 1]
set serverid [lindex $argv 2]
set newpassword [lindex $argv 3]

spawn ssh -tt -oStrictHostKeyChecking=no $username@$serverid passwd
expect "${username}@${serverid}'s password:"
send "$password\r"
expect "Current password:"
send "$password\r"
expect "New password:"
send "$newpassword\r"
expect "Retype new password:"
send "$newpassword\r"
expect eof
