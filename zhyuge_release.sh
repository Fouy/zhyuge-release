#!/bin/bash
# author: xuefeihu

# 项目目录
zhyugePath="/root/project"
convertzhyugePath=${zhyugePath//\//\\\/} #将${zhyugePath}变为转义串

gitzhyugePath="/Users/xuefeihu/hugege/code-sublime"
convertGitzhyugePath=${gitzhyugePath//\//\\\/}

projectPath=${zhyugePath}"/zhyuge"
convertProjectPath=${projectPath//\//\\\/} #将${projectPath}变为转义串

gitProjectPath=${gitzhyugePath}"/zhyuge"
convertGitProjectPath=${gitProjectPath//\//\\\/}

# openresty 安装目录
openrestyPath="/root/software/openresty"
convertOpenrestyPath=${openrestyPath//\//\\\/}

gitOpenrestyPath="/Users/xuefeihu/software/openresty"
convertGitOpenrestyPath=${gitOpenrestyPath//\//\\\/}

# github地址
projectUrl="https://codeload.github.com/Fouy/zhyuge-release/zip/master"

# stop server
sudo ${openrestyPath}/nginx/sbin/nginx -c ${projectPath}/config/nginx.conf -p ${projectPath} -s stop
echo "OpenResty stoped"
echo -e "########################################################################\n\n"

# remove old project path
if [ -d "$projectPath" ]; then
	sudo rm -rf ${projectPath}
fi

# get source code and publish
sudo wget ${projectUrl} -O ${zhyugePath}/zhyuge-release-master.zip
sudo unzip ${zhyugePath}/zhyuge-release-master.zip -d ${zhyugePath}
sudo mv ${zhyugePath}/zhyuge-release-master ${projectPath}
sudo rm -rf ${zhyugePath}/zhyuge-release-master.zip

# replace /bin/* files
sudo sed -i 's/'${convertGitProjectPath}'/'${convertProjectPath}'/g' ${projectPath}/bin/*
sudo sed -i 's/'${convertGitOpenrestyPath}'/'${convertOpenrestyPath}'/g' ${projectPath}/bin/*

# replace config/* files
sudo sed -i 's/'${convertGitProjectPath}'/'${convertProjectPath}'/g' ${projectPath}/config/*
sudo sed -i 's/'${convertGitzhyugePath}'/'${convertzhyugePath}'/g' ${projectPath}/config/*
sudo sed -i 's/'${convertGitOpenrestyPath}'/'${convertOpenrestyPath}'/g' ${projectPath}/config/*

sudo sed -i 's/#user  nobody;/user  root;/g' ${projectPath}/config/nginx.conf
sudo sed -i 's/lua_code_cache off;/lua_code_cache on;/g' ${projectPath}/config/nginx.conf

# replace lua/* files
sudo sed -i 's/'${convertGitProjectPath}'/'${convertProjectPath}'/g' ${projectPath}/lua/init.lua

sudo chmod a+x ${projectPath}/*

# start server
sudo ${openrestyPath}/nginx/sbin/nginx -c ${projectPath}/config/nginx.conf -p ${projectPath}
echo "OpenResty start"
echo -e "########################################################################\n\n"
tail -f ${projectPath}/logs/error.log

