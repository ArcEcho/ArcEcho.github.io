var exec = require('child_process').exec;
// Hexo 3 用户复制这段
hexo.on('new', function(data){
  exec('start  "C:/Program Files (x86)/Microsoft VS Code/Code.exe" ' + data.path);
});