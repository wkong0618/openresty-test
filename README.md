# openresty-test
1.OpenResty反向代理以及负载均衡相关简单配置(nginx.conf)

2.openresty-lua-mysql 简单增删查改

3.openresty test 之upload 使用openresty-practices(https://github.com/shixinke/openresty-practices/tree/master/upload)进行相应修改后的上传代码进行上传测试

4.openresty test mysql 本测试主要基于lua-resty-redis-util(https://github.com/anjia0532/lua-resty-redis-util)进行相关的代码测试, 并且基于OpenResty最佳实践中的(https://moonbingbing.gitbooks.io/openresty-best-practices/content/redis/pub_sub_package.html) 这篇文章对subscribe方法进行了退订了对应的频道后，清空当前读取到的数据然后再复用连接的小优化。

5.从https://github.com/bungle/lua-resty-template 下载后将lib/resty下面的template.lua放到我们安装的openresty下面的lualib/resty下。然后我们就可以通过如下方式引用来使用：
