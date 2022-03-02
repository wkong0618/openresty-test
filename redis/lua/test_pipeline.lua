local cjson = require "cjson"
local redis = require "libs.redis-util"

local red = redis:new();

red:init_pipeline()

red:set("cat", "Marry")
red:set("horse", "Bob")
red:get("cat")
red:get("horse")

local results, err = red:commit_pipeline()

if not results then
    ngx.say("failed to commit the pipelined requests: ", err)
    return
else
    ngx.say("pipeline",cjson.encode(results))
end
