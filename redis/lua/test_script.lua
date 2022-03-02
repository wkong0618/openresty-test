local redis = require "libs.redis-util"

local red = redis:new();
-- 插入键值
local ok,err = red:set("1","{\"gid\":2}")
-- 判断结果
if not ok then
    ngx.say("failed to set dog:",err)
    return
end

-- 插入键值
local ok,err = red:set("2","Hello World")
-- 判断结果
if not ok then
    ngx.say("failed to set dog:",err)
    return
end

local id = 1
local res, err = red:eval([[
        -- 注意在 Redis 执行脚本的时候，从 KEYS/ARGV 取出来的值类型为 string
        local info = redis.call('get', KEYS[1])
        info = cjson.decode(info)
        local g_id = info.gid

        local g_info = redis.call('get', g_id)
        return g_info
        ]], 1, id)

if not res then
    ngx.say("failed to get the group info: ", err)
    return
end

ngx.say("script:",res)