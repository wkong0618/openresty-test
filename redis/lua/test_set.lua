-- 依赖库
local redis = require "libs.redis-util"
-- 初始化
local red = redis:new();
-- 插入键值
local ok,err = red:set("dog","an cute animal")
-- 判断结果
if not ok then
    ngx.say("failed to set dog:",err)
    return
end
local res, err = red:get("dog")
if not res then
    ngx.say("failed to get dog: ", err)
    return
end
if res == ngx.null then
    ngx.say("dog not found.")
    return
end
-- 页面打印结果
ngx.say("get dog: ", res)

