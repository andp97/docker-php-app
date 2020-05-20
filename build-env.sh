#!/bin/bash
APP_NAME=$1
TMP_DIR="tmp_dir"
RND_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
echo -e "Createing dir ../$APP_NAME\n"

CURR_USR=$(whoami)

mkdir -p ../$APP_NAME
cd ../$APP_NAME
mkdir -p docker-compose/nginx
mkdir -p docker-compose/mysql

sudo mkdir -p /opt/mysql-docker/$CURR_USR/$APP_NAME
sudo chown -R $CURR_USR. /opt/mysql-docker/$CURR_USR/

#Download file
cp ../docker-php-app/docker-compose.yml docker-compose.yml || wget https://raw.githubusercontent.com/andp97/docker-php-app/master/docker-compose.yml
cp ../docker-php-app/Dockerfile Dockerfile || wget https://raw.githubusercontent.com/andp97/docker-php-app/master/Dockerfile
cp ../docker-php-app/docker-compose/nginx/app.conf docker-compose/nginx/app.conf || https://raw.githubusercontent.com/andp97/docker-php-app/master/docker-compose/nginx/app.conf

sed -i "s/main_php_app_img/$APP_NAME/g" docker-compose.yml
sed -i "s/\/opt\/mysql-docker/\/opt\/mysql-docker\/$CURR_USR\/$APP_NAME/g" docker-compose.yml

echo -e "Building docker image $APP_NAME from Dockerfile\n"

docker-compose build app >> /dev/null
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

docker-compose ps

exit 0
