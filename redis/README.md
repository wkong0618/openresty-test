openresty test mysql 
本测试主要基于lua-resty-redis-util(https://github.com/anjia0532/lua-resty-redis-util)进行相关的代码测试,
并且基于OpenResty最佳实践中的(https://moonbingbing.gitbooks.io/openresty-best-practices/content/redis/pub_sub_package.html) 这篇文章对subscribe方法进行了退订了对应的频道后，清空当前读取到的数据然后再复用连接的小优化。
