bash目录下

./git_export.sh 是git 差异文件导出工具，用于差异文件上传至生产环境

./publish.sh 是用于测试机和生产环境的文件部署

使用前，需要先把文件最上面的配置变量，改成自己环境下对应的

使用方法：
./git_export.sh site 3dafaa af3fae

然后把这个脚本生成的tar.gz压缩文件，上传到服务器

再到服务器上运行./publish.sh

./publish.sh site

要回滚文件，可以使用
./publish.sh site revert 2019-03-08
后面的日期是指backup目录下对应的文件名，不需要输入.tar.gz扩展名
