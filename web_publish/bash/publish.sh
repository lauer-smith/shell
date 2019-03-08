#!/bin/bash
#########################################
#    web file publish shell
#    测试机及生产环境的文件部署
#    Author:Lauer Smith
#    Date: 2019-03-08
##########################################


############## config start #################
#production web directory
SITE_BASE_DIR=/www
#production file backup directory
BACKUP_BASE_DIR=../backup
#archive file directory, same set from git_export.sh
ARCHIVE_BASE_DIR=../archive
#temp directory
TMP_BASE_DIR=../tmp

NOW_DATE=`date +%F`
SITE_PARAM=$1

case $1 in
    site)
        PRODUCTION_DIR="$SITE_BASE_DIR/www.xxx.com/"
        ;;
    app)
        PRODUCTION_DIR="$SITE_BASE_DIR/app.xxx.com/"
        ;;
   admin)
        PRODUCTION_DIR="$SITE_BASE_DIR/admin.xxx.com/"
        ;;
    *)
        echo "usage: $0 [site|app|admin]"
        echo "usage: $0 [site|app|admin] revert 2019-03-08"
        exit 1
        ;;
esac

############## config end #################

myEcho()
{
    echo "[`date +"%F %T"`] $*"
}

initDirectory()
{
    if [ ! -e $PRODUCTION_DIR ]; then
        myEcho "网站正式文件目录不存在，请检查. $PRODUCTION_DIR"
        exit 0
    fi

    if [ ! -e $BACKUP_BASE_DIR/$1 ]; then
        mkdir $BACKUP_BASE_DIR/$1
    fi
    if [ ! -e $ARCHIVE_BASE_DIR/$1 ]; then
        mkdir $ARCHIVE_BASE_DIR/$1
    fi
}

clearTmpDir()
{
    if [ -e $1 ]; then
        rm -rf $1
    fi
    mkdir $1
}

#检测要上传的程序版本文件是否存在
checkReleaseFile()
{
    myEcho "正在检测要上传的程序版本文件是否存在..."
    archive_file_enable="no"
    archive_file_tmp=$ARCHIVE_BASE_DIR/$1/${NOW_DATE}.tar.gz
    archive_file=$archive_file_tmp

    if [ -e $archive_file_tmp ]; then
        archive_file_enable="tar"
        archive_file=$archive_file_tmp
    else
        archive_file_tmp=$ARCHIVE_BASE_DIR/$1/${NOW_DATE}.zip
        if [ -e $archive_file_tmp ]; then
            archive_file_enable="zip"
            archive_file=$archive_file_tmp
        fi
    fi

    if [ "no" == "$archive_file_enable" ] || [ ! -e $archive_file ]; then
        myEcho "要上传的程序版本文件不存在，请先上传：$archive_file"
        exit 0
    fi
}

#读取压缩包里的文件，并将线上的对应文件进行整理，以便备份线上文件
readXFile()
{
    for file in `ls $1`
    do
        if [ -d $1/$file ]; then
            readXFile $1/$file
        else
            file_path=${1/$TMP_BASE_DIR\/$SITE_PARAM}/$file
            file_path=${file_path:1}
            echo $file_path
            newfile_param="$newfile_param $file_path"
            if [ -e ${PRODUCTION_DIR}$file_path ]; then
                xfile_param="$xfile_param $file_path"
            fi
        fi
    done
}

#先解压要上线的文件到临时目录
tractArchiveFile()
{
    cd $TMP_BASE_DIR/$1
    if [ "zip" == $archive_file_enable ]; then
        unzip -o -q $archive_file
    else
        tar -zxf $archive_file
    fi
}

#备份线上文件
backupFile()
{
    if [ "" == "$xfile_param" ]; then
        myEcho "没有需要备份的文件"
    else
        cd $PRODUCTION_DIR
        backup_file=$BACKUP_BASE_DIR/$1/${NOW_DATE}.tar.gz
        if [ ! -e $backup_file ]; then
            tar -zcf $backup_file $xfile_param
        else
            for ((i = 1; i <= 20; i++))
            do
                backup_file=$BACKUP_BASE_DIR/$1/${NOW_DATE}_${i}.tar.gz
                if [ ! -e $backup_file ]; then
                    tar -zcf $backup_file $xfile_param
                    break
                fi
            done
        fi

        if [ ! -e $backup_file ]; then
            myEcho "网站备份失败，请重试，如果多次尝试不成功，请手动处理"
            exit 0
        fi
        myEcho "网站文件备份成功：$backup_file"
    fi
}

tractToRelease()
{
    myEcho "开始部署新程序代码到线上"

    cd $PRODUCTION_DIR
    if [ "zip" == $archive_file_enable ]; then
        unzip -o -q $archive_file
    else
        tar -zxf $archive_file
    fi
}



#修改文件权限
changeFilePermission()
{
    echo $1
    for x in $1
    do
        echo ${PRODUCTION_DIR}${x}
        if [ -e ${PRODUCTION_DIR}${x} ]; then
            chmod 0750 ${PRODUCTION_DIR}${x}
            adir=`dirname ${PRODUCTION_DIR}${x}`
            chmod 0770 $adir
            chown -R www:www $adir
        fi
    done
}



if [ "revert" == "$2" ]; then
    if [ "" == "$3" ]; then
        myEcho "请输入第三个参数，要恢复的压缩包文件名，不需要输入.tar.gz"
        exit 0
    fi
    backup_file=$BACKUP_BASE_DIR/$1/$3.tar.gz
    if [ ! -e $backup_file ]; then
        myEcho "备份的压缩包不存在，请检查：$backup_file"
        exit 0
    fi
    cd $PRODUCTION_DIR
    tar -zxvf $backup_file
    myEcho "$1 网站文件已恢复: $backup_file"
    exit 0
fi


initDirectory $1

clearTmpDir $TMP_BASE_DIR/$1

checkReleaseFile $1

#开始备份网站文件
myEcho "开始备份网站文件..."

clearTmpDir $TMP_BASE_DIR/$1

tractArchiveFile $1

xfile_param=""
newfile_param=""
readXFile $TMP_BASE_DIR/$1 $PRODUCTION_DIR 

backupFile $1

tractToRelease

echo "开始修改文件权限"
changeFilePermission "$newfile_param"
echo "修改文件权限结束"

clearTmpDir $TMP_BASE_DIR/$1

myEcho "${1} 程序文件部署完毕"

exit 0
