#sudo apt-get update
# Installing missing packages: 
# Before every install, we test if the package already exists
package1="docker"
if apt list --installed 2>/dev/null | grep -q "\<$package1\>"; then
    echo "$package1 is already installed."
else
    sudo apt-get install -y $package1
fi
package2="expect"
if apt list --installed 2>/dev/null | grep -q "\<$package2\>"; then
    echo "$package2 is already installed."
else
    sudo apt-get install -y $package2
fi
package3="jq" # package for json 
if apt list --installed 2>/dev/null | grep -q "\<$package3\>"; then
    echo "$package3 is already installed."
else
    sudo apt-get install -y $package3
fi
# variables needed ... I use a lot of variables for the names of things 
# beacause it is a good practice, and also to not make mistakes
mysqlimage="mysql/mysql-server:5.6"
mysqlcname="mysql"
defaultpassword="yosr"
mysql_user="yosr"
mysql_password="yosr"
mysql_database="mysql_sqoop"
tableName="EMP"
sqoopimage="hadoop-sqoop-image"
sqoopcname="hadoop-sqoop"
networkname="sqoop-mysql-network"

# ---- part1 : mysql ----
# Check if the mysql image already exists
if [[ "$(sudo docker images -q $mysqlimage 2> /dev/null)" == "" ]]; then
  sudo docker pull $mysqlimage
else
  echo "Docker image '$mysqlimage' exists."
fi
# Check if the MySQL Docker container is already running
mysqlcid=$(sudo docker ps -a -q -f name=$mysqlcname)
if [[ "$mysqlcid" == "" ]]; then
  # Run the MySQL Docker container
  sudo docker run -d --name $mysqlcname -e MYSQL_ROOT_PASSWORD=$defaultpassword $mysqlimage
else
  # remove running instance and run new container
  echo "Docker container '$mysqlcname' is already running."
  echo "Stopping container"
  sudo docker stop $mysqlcid
  sudo docker rm $mysqlcid
  sleep 5
  echo "Running new container"
  sudo docker run -d --name $mysqlcname -e MYSQL_ROOT_PASSWORD=$defaultpassword $mysqlimage
fi
# Wait for a few seconds to ensure the MySQL container is fully up and running
echo "waiting for 10 seconds to ensure the MySQL container is fully up and running ..."
sleep 10
# Extract the comtainer id 
mysqlcid=$(sudo docker ps -a -q -f name=$mysqlcname)
echo "cid is: $mysqlcid"

# Setting up MySQL server 
expect <<END
spawn sudo docker exec -it $mysqlcid bash
expect "# " { send "mysql -uroot -p\r" }
expect "Enter password: " { send "$defaultpassword\r" }
expect "mysql> " { send "SET PASSWORD = PASSWORD('$mysql_password');\r" }
expect "mysql> " { send "CREATE USER '$mysql_user'@'%' IDENTIFIED BY '$mysql_password';\r" }
expect "mysql> " { send "GRANT ALL PRIVILEGES ON *.* TO '$mysql_user'@'%';\r" }
expect "mysql> " { send "FLUSH PRIVILEGES;\r" }
expect "mysql> " { send "exit\r" }
expect "# " { send "mysql -u$mysql_user -p\r" }
expect "Enter password: " { send "$mysql_password\r" }
expect "mysql> " { send "CREATE DATABASE $mysql_database;\r" }
expect "mysql> " { send "USE $mysql_database;\r" }
expect "mysql> " { send "CREATE TABLE $tableName (EMPNO INT NOT NULL PRIMARY KEY,ENAME VARCHAR(10),JOB VARCHAR(9),MGR INT,HIREDATE VARCHAR(15),SAL DECIMAL(7,2),COMM DECIMAL(7,2),DEPTNO INT);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7839, 'KING', 'PRESIDENT', NULL, '17-nov-1981',5000,NULL, 10);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7566, 'JONES', 'MANAGER', 7839, '02-apr-1981',2975,NULL, 20);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7902, 'FORD', 'ANALYST', 7566, '03-dec-1981',3000, NULL,20);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7369, 'SMITH', 'CLERK', 7902, '17-dec-1980', 800,NULL,20);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7698, 'BLAKE', 'MANAGER', 7839, '01-may-1981',2850,NULL,30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7499, 'ALLEN', 'SALESMAN', 7698, '20-feb-1981',1600,300,30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7521, 'WARD', 'SALESMAN', 7698, '22-feb-1981',1250,500,30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7654, 'MARTIN', 'SALESMAN', 7698, '28-sep-1981',1250,1400,30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7844, 'TURNER', 'SALESMAN', 7698, '08-sep-1981',1500, 0,30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7900, 'JAMES', 'CLERK', 7698, '03-dec-1981', 950,NULL, 30);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7782, 'CLARK', 'MANAGER', 7839, '09-jun-1981',2450, NULL, 10);\r" }
expect "mysql> " { send "INSERT INTO $tableName VALUES(7934, 'MILLER', 'CLERK', 7782, '23-jan-1982', 1300,NULL, 10);\r" }
expect "mysql> " { send "select * from $tableName;\r" }
expect "mysql> " { send "exit\r" }
expect "# " { send "exit\r" }
expect "# " { send "exit\r" }
END

sleep 10
# to check if you're out of the mysql container run ls
# ls

# ---- part2 : sqoop ----
echo "Starting Sqoop part"

# Check if a folder called hadoop-sqoop-pig already exists to delete it:
if [ -d "hadoop-sqoop-pig" ]; then
  sudo rm -rf hadoop-sqoop-pig
fi
# cloning git repository:
git clone https://github.com/Mouez2019/hadoop-sqoop-pig.git
cd hadoop-sqoop-pig
# Check if the sqoop image already exists, remove it if exists
if [[ "$(sudo docker images -q $sqoopimage 2> /dev/null)" == "" ]]; then
  sudo docker build -t $sqoopimage .
else
  echo "another docker image with the name '$sqoopimage' already exists. will remove it and build "
  sudo docker rmi $sqoopimage
  sleep 5
  echo "Building new image"
  sudo docker build -t $sqoopimage .
fi
# Check if the sqoop container is already running
sqoopcid=$(sudo docker ps -a -q -f name=$sqoopcname)
if [[ "$sqoopcid" == "" ]]; then
  sudo docker run -d --name $sqoopcname $sqoopimage
else
  # remove running instance and run new container
  echo "another docker container named '$sqoopcname' is already running..... Stopping container"
  sudo docker stop $sqoopcid
  sudo docker rm $sqoopcid
  sleep 5
  echo "Running new container"
  sudo docker run -d --name $sqoopcname $sqoopimage
fi
# Wait for a few seconds to ensure the container is fully up and running
echo "waiting for 10 seconds to ensure the container is fully up and running ..."
sleep 10
sqoopcid=$(sudo docker ps -a -q -f name=$sqoopcname)
# part3 : network
echo "Starting network part"
# Check if the network already exists, remove it if exists
if docker network inspect $networkname &>/dev/null; then
  echo "Docker network '$networkname' exists. Removing it and making a new one ..."
  docker network rm $networkname
  sleep 3
  docker network create --driver=bridge $networkname
  docker network connect $networkname $mysqlcname
  docker network connect $networkname $sqoopcname
else 
  docker network create --driver=bridge $networkname
  docker network connect $networkname $mysqlcname
  docker network connect $networkname $sqoopcname
fi
sleep 5
# Run docker network inspect and store the result in a variable
# the result is json, therefor we use jq package to parse it and 
# extract needed info
network_info=$(docker network inspect $networkname)
# Extracting the container ids, names and IPv4 addresses
containers_info=$(echo "$network_info" | jq -r '.[0].Containers | to_entries[] | "\(.key) \(.value.Name) \(.value.IPv4Address)"')
# Declare an associative array to store container info
declare -A container_info
# Populate the associative array with container info
while IFS= read -r line; do
  key=$(echo "$line" | awk '{print $1}')
  name=$(echo "$line" | awk '{print $2}')
  ipv4=$(echo "$line" | awk '{print $3}' | cut -d '/' -f 1)
  container_info["$name"]=$ipv4
done <<< "$containers_info"
# Print each container's info from the associative array
for key in "${!container_info[@]}"; do
  echo "Container $key address: ${container_info[$key]}"
done
sqoopaddress=${container_info[$sqoopcname]}
mysqladdress=${container_info[$mysqlcname]}

# part4 : resume
echo "resume:"
echo "Info needed for next parts: import-export "
echo "scoop container id: $sqoopcid   scoop container name: $sqoopcname   scoop address: $sqoopaddress"
echo "mysql container id: $mysqlcid   mysql container name: $mysqlcname   mysql address: $mysqladdress"
echo "mysql_user: $mysql_user   mysql_password: $mysql_password"
echo "mysql_database: $mysql_database   tableName: $tableName"

