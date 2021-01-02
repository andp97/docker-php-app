#!/bin/bash
CURR_PWD=$(pwd)
PROJECTS_DIR="$HOME/projects"
DOCKER_PHP_APP_DIR="$PROJECTS_DIR/docker-php-app"

if -d $DOCKER_PHP_APP_DIR then
	echo -n "Check for updates: cd $DOCKER_PHP_APP_DIR && git pull"
else
	cd $PROJECTS_DIR && git clone https://github.com/andp97/docker-php-app.git
	cd $PWD
fi

APP_NAME=$1
if -z $APP_NAME then
	echo "Invalid APP_NAME"
	exit 1
fi

APP_NAME=$(echo $APP_NAME | sed 's/ /_/g')

DEFAULT_APP_DIR="$PROJECTS_DIR/$APP_NAME"

TMP_DIR="/tmp/.docker-php-app-"
RND_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
RND_DIR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
echo -e "Createing dir $DEFAULT_APP_DIR\n"

TMP_DIR="$TMP_DIR$RND_DIR"

CURR_USR=$(whoami)

mkdir -p $DEFAULT_APP_DIR
cd $DEFAULT_APP_DIR
mkdir -p docker-compose/nginx
mkdir -p docker-compose/mysql

APP_DB_PATH="$DEFAULT_APP_DIR/.db/"

if test -f $APP_DB_PATH; then
else
	sudo mkdir -p $APP_DB_PATH
fi
#Download file

cp $DOCKER_PHP_APP_DIR/docker-compose.yml docker-compose.yml
cp $DOCKER_PHP_APP_DIR/Dockerfile Dockerfile
cp $DOCKER_PHP_APP_DIR/docker-compose/nginx/app.conf docker-compose/nginx/app.conf

sed -i "s/main_php_app_img/$APP_NAME/g" docker-compose.yml

echo -e "Building docker image $APP_NAME from Dockerfile\n"

docker-compose build app >> /dev/null ||  exit 0
docker-compose up -d
docker-compose exec app composer create-project --prefer-dist laravel/laravel $TMP_DIR
mv $TMP_DIR/* .
mv $TMP_DIR/.{editorconfig,env,env.example,gitattributes,gitignore,styleci.yml} .
rm -rf $TMP_DIR
git init

ENV_FILE=".env"

if test -f "$ENV_FILE"; then

	sed -i "s/DB_HOST.*/DB_HOST=db/g" $ENV_FILE
	sed -i "s/DB_DATABASE.*/DB_DATABASE=$APP_NAME/g" $ENV_FILE
	sed -i "s/DB_USERNAME.*/DB_USERNAME=$APP_NAME/g" $ENV_FILE
	sed -i "s/DB_PASSWORD.*/DB_PASSWORD=$RND_PW/g" $ENV_FILE
	docker-compose up -d
	docker-compose exec app php artisan migrate

fi

echo ".db/" >> $DEFAULT_APP_DIR/.gitignore

docker-compose ps


exit 0
