local cjson = require("cjson");
local dbConfig = ngx.shared.db_config;

if dbConfig:get('isload') then
    return
end

local confFile = io.open("/Users/wukong/Desktop/tool/openresty-test/src/common/config/mysql_conf.properties", "r");
local confStr = confFile:read("*a");
confFile:close();

local confJson = cjson.decode(confStr);
ngx.log(ngx.ERR, ">>>>>>>>>>>>>Begin Config>>>>>>>>>>>");
for k,v in pairs(confJson) do
    dbConfig:set(k, v, 0)
    ngx.log(ngx.ERR, "key:" .. k .. ", value:" .. v);
end
ngx.log(ngx.ERR, "<<<<<<<<<<<<<<<<<<<<<<<<<<<End Config>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
dbConfig:set('isload', 1)