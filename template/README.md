从https://github.com/bungle/lua-resty-template 下载后将lib/resty下面的template.lua放到我们安装的openresty下面的lualib/resty下。然后我们就可以通过如下方式引用来使用：

`local template = require("resty.template")
`