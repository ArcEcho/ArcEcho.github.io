@echo off
call npm install hexo  --save  
call npm install hexo-cli --save
call npm install hexo-deployer-git --save
call npm install hexo-fs --save
call npm install hexo-asset-image --save
call npm install hexo-server --save
call  npm audit fix
call npm install

