#!/bin/bash
APP_NAME=$1
TMP_DIR="tmp_dir"
echo "Build APP: $APP_NAME";


mkdir -p $APP_NAME
cd $APP_NAME
mkdir -p docker-compose/nginx
mkdir -p docker-compose/mysql

#Download file
wget https://raw.githubusercontent.com/andp97/docker-php-app/master/docker-compose.yml
wget https://raw.githubusercontent.com/andp97/docker-php-app/master/Dockerfile

sed -i "s/main_php_app_img/$APP_NAME/g" docker-compose.yml

docker-compose build app
docker-compose up -d
docker-compose exec app composer create-project --prefer-dist laravel/laravel $TMP_DIR
mv $TMP_DIR/* .
mv $TMP_DIR/.{editorconfig,env,env.example,gitattributes,gitignore} .

git init

cd ../
exit 0
