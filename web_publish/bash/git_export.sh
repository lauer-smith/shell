#!/bin/bash
##########################################################
#   git archive export
#   use this shell in local computer
#   git 差异文件导出工具，用于差异文件上传至生产环境
#   Author:Lauer Smith
#   Date: 2019-03-08
##########################################################

if [ "" == "$1" ]; then
    echo "please input site type param"
    exit 0
fi

if [ "" == "$2" ]; then
    echo "please input first commit id param"
    exit 0
fi

if [ "" == "$3" ]; then
    echo "skip last commit id"
fi

############## config start #################
#git file base dir
GIT_BASE_DIR=/www/develop
#archive dir
ARCHIVE_BASE_DIR=../archive

#GIT_DIR is the git file directory
#SAFE_FILE_LIST is the ignore files or directory
case $1 in
	site)
		GIT_DIR="$GIT_BASE_DIR/www.xxx.com/"
        SAFE_FILE_LIST=".git release/database.php data/logs data/runtime data/upload data/install.lock"
		;;
	app)
		GIT_DIR="$GIT_BASE_DIR/app.xxx.com/"
        SAFE_FILE_LIST=".git release/database.php data/runtime public/data"
		;;
	admin)
		GIT_DIR="$GIT_BASE_DIR/admin.xxx.com/"
        SAFE_FILE_LIST=".git release/database.php data/backup data/logs data/runtime data/upload data/install.lock"
		;;
	*)
		echo "usage: $0 [site|app|admin] 3dafaa af3fae"
		exit 1
		;;
esac

############## config end #################

myEcho()
{
    echo "[`date +"%F %T"`] $*"
}

if [ ! -e $GIT_DIR ] || [ ! -d $GIT_DIR ]; then
    myEcho "GIT directory is not exists, please check: $GIT_DIR"
    exit 0
fi

echo "please make sure the git branch is switch to export branch, and it is new, and then press Enter, input no for cancel"
#echo "请确认请本机的GIT已切换至相应分支，并且已是最新的文件，并按回车即可，输入no取消"
read git_is_new
if [ "no" == "$git_is_new" ]; then
    exit 0
fi

NOW_DATE=`date +%F`
archive_file=$ARCHIVE_BASE_DIR/$1/$NOW_DATE.tar.gz
if [ ! -e $ARCHIVE_BASE_DIR/$1 ]; then
    mkdir $ARCHIVE_BASE_DIR/$1
fi
if [ -e $archive_file ]; then
	rm -f $archive_file
fi

cd $GIT_DIR

exclude=""
for safe_file in $SAFE_FILE_LIST
do
    exclude="$exclude --exclude=\"$safe_file\""
done

git diff --name-only --diff-filter=ACMRT $2 $3|xargs tar $exclude -zcvf $archive_file

myEcho "finish  $archive_file"
