#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "Please enter DB password:"
read -s mysql_root_password
VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
 VALIDATE $? "Diabilong default nodesjs"

 dnf module enable nodejs:20 -y &>>$LOGFILE
 VALIDATE $? "Enabling  nodejs 20"

 dnf install nodejs -y &>>$LOGFILE
 VALIDATE $? "instaling  nodejs 20"

 id expense &>>$LOGFILE

 if [ $? -ne 0 ]
 then
     useradd expense
     VALIDATE $? "Creating a new user"

     else
      echo -e "User is already created...$Y SKIPPING $N"
fi

  mkdir -p /app &>>$LOGFILE
     VALIDATE $? "Creating  app directory" 

     curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
  VALIDATE $? "Downloading Backend code" 

  cd /app
  rm -rf /app/*
  unzip /tmp/backend.zip &>>$LOGFILE

  VALIDATE $? "Extracted backend code"

  npm install
VALIDATE $? "Isntalling nodejs dependencies"  
 
 cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service
  VALIDATE $? "Copied backend service"

  systemctl daemon-reload &>>$LOGFILE
 VALIDATE $? "Daemon reload"

  systemctl start backend &>>$LOGFILE
   VALIDATE $? "Start backend"

  systemctl enable backend &>>$LOGFILE
   VALIDATE $? "enable backend"

 dnf install mysql-server -y &>>$LOGFILE
VALIDATE $? "Installing MySQL Server"

mysql -h db.viswaws.online -uroot -p${mysql_root_password} -e 'show databases;' &>>$LOGFILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ${mysql_root_password} &>>$LOGFILE
    VALIDATE $? "MySQL Root password Setup"
else
    echo -e "MySQL Root password is already setup...$Y SKIPPING $N"
fi
systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting Backend"


 
