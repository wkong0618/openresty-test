local cjson = require "cjson"
ngx.req.read_body()
local body_data = ngx.req.get_body_data()
local unjson = cjson.decode(body_data)
if  unjson["routerId"] == 1 then
    res = '127.0.0.1:9001'
else
    res = '127.0.0.1:9002'
end
ngx.var.backend = res