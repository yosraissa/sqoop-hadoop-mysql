# part4 : import ./importscript.sh mysql yosr yosr mysql_sqoop EMP 00be30a9c6c5 172.31.0.2

echo "Starting import part (from mysql to hadoop) "
echo " args order:    mysqlcname mysqluser mysqlpassword mysqldatabase mysqltable scoopcid mysqladdress"
# Access command-line arguments
mysqlcname=$1
mysqluser=$2
password=$3
mysqldatabase=$4
mysqltable=$5
sqoopcid=$6
mysqladdress=$7

expect <<END
spawn sudo docker exec -it $sqoopcid bash
expect "# " { send "hadoop fs -mkdir import\r" }
expect "# " { send "hadoop fs -ls\r" }
expect "# " { send "sqoop import --connect jdbc:$mysqlcname://$mysqladdress:3306/$mysqldatabase --username $mysqluser --P --table $mysqltable --m 1 --target-dir /import --driver com.mysql.jdbc.Driver\r" }
expect "Enter password: " { send "$password\r" }
expect "Submitting tokens for job: " { }
expect "Retrieved"
expect "# "
END



