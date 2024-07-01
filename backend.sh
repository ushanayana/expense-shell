USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "please enter DB password"
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
VALIDATE $? "disable nodejs modules"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "enabling nodejs modules"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing Nodejs.."

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then 
useradd expense &>>$LOGFILE
VALIDATE $? "creating expense user"
else
echo -e "expense user already created...$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "creating app directory..."

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "downloading the code..."

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "extract the backend code"

npm install &>>$LOGFILE
VALIDATE $? "installing nodejs dependencies..."

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "validate backend services.."

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "validate demon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "start backend services"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling Backend"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "installing mysql..."

mysql -h db.daws78s.blog -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "schema reloading"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "restart backend..."
