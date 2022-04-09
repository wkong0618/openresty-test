local limit_req = require "resty.limit.req"
local rate = 2 -- 固定平均速率 2r/s
local burst = 3 -- 桶容量
local error_status = 503
local nodelay = false -- 是否需要不延迟处理
local lim, err = limit_req.new("limit_req_store", rate, burst)
if not lim then -- 没定义共享字典
    ngx.log(ngx.ERR, "没定义共享字典", delay)
    ngx.exit(error_status)
end
local key = ngx.var.binary_remote_addr -- IP维度限流,如果想根据参数可以查询所需参数进行限流
-- 流入请求，如果请求需要被延迟，则delay > 0
local delay, err = lim:incoming(key, true)
if not delay and err == "rejected" then -- 超出桶大小了
    ngx.log(ngx.ERR, "超出桶大小：", err)
    ngx.exit(error_status)
end
if delay > 0 then -- 根据需要决定是延迟还是不延迟处理
    if nodelay then
        -- 直接突发处理
        ngx.log(ngx.ERR, "突发处理,正常需要延迟时间", delay)
    else
        ngx.sleep(delay) -- 延迟处理
        ngx.log(ngx.ERR, "延迟处理,延迟时间:", delay)
    end
end