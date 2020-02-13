# V2ray云端Docker部署脚本

## 部署
cloud目录下存放了模板文件夹，可以在custom中自定义模板

使用nginx模板部署websocket+nginx+letsencrpytion方案：
1. 打开nginx模板文件夹
   1. 填写`docker-compose.yml`中的`VIRTUAL_HOST`, `LETSENCRYPT_HOST`为你的域名，以及`LETSENCRYPT_EMAIL`  
   2. 更改`v2ray/config.json`中`ENTER UUID HERE`为你生成的uuid v4
2. 开启内核BBR算法
   `./install.sh bbr on`
3. 执行安装脚本，脚本会自动检测系统中是否安装docker
   `./install.sh up nginx`

卸载模板：
`./install.sh down nginx`

