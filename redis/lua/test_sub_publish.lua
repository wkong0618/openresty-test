--[[发布-订阅简单示例]]
local cjson = require "cjson"
local redis = require "libs.redis-util"

local red = redis:new()
local red2 = redis:new()


local func = red:subscribe("dog")
if not func then
    ngx.say("1: failed to subscribe: ", err)
    return
end

-- 判断是否成功订阅
if not func then
    return nil
end

res, err = red2:publish("dog", "Hello")
if not res then
    ngx.say("2: failed to publish: ", err)
    return
end

ngx.say("2: publish: ", cjson.encode(res))

while true do
    local res, err = func()
    if err then
        func(false)
        return
    end
    -- 如果取到结果，进行页面输出
    if res then
        ngx.say("receive: ", cjson.encode(res))
    end
    if not res then
        func(false)
        return
    end
end

--[[发布-订阅简单示例]]
local cjson = require "cjson"
local redis = require "libs.redis-util"

local red = redis:new()
local red2 = redis:new()


local func = red:subscribe("dog")
if not func then
    ngx.say("1: failed to subscribe: ", err)
    return
end

-- 判断是否成功订阅
if not func then
    return nil
end

res, err = red2:publish("dog", "Hello")
if not res then
    ngx.say("2: failed to publish: ", err)
    return
end

ngx.say("2: publish: ", cjson.encode(res))

--下面代码是单次获取数据
-- 获取值
local res, err = func() --func()=func(true)
-- 如果失败，取消订阅
if err then
    func(false)
end

-- 如果取到结果，进行页面输出
if res then
    ngx.say("receive: ", cjson.encode(res))
end


-- 循环获取数据,
--[[while true do
    local res, err = func()
    if err then
        func(false)
    end
--    ...

end]]



