-- Copyright (C) Anjia (anjia0532)
local cjson = require "cjson"
local redis_c = require("resty.redis")

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 54)

_M._VERSION = '0.07'

local mt = {__index = _M}


local ngx_log               = ngx.log
local debug                 = ngx.config.debug

local DEBUG                 = ngx.DEBUG
local CRIT                  = ngx.CRIT

local MAX_PORT              = 65535


-- redis host,default: 127.0.0.1
local host                  = '127.0.0.1'
-- redis port,default:6379
local port                  = 6379
-- redis库索引(默认0-15 共16个库)，默认的就是0库(建议用不同端口开不同实例或者用不同前缀，因为换库需要用select命令),default:0
local db_index              = 0
-- redis auth 认证的密码
local password              = nil
-- reids连接超时时间,default: 1000 (1s)
local keepalive             = 60000 --60s
-- redis连接池的最大闲置时间, default: 60000 (1m)
local pool_size             = 100
-- redis连接池大小, default: 100
local timeout             = 3000 --3s   --modify by hirryli


-- if res is ngx.null or nil or type(res) is table and all value is ngx.null return true else false
local function _is_null(res)
    if res == ngx.null or res ==nil then
        return true
    elseif type(res) == "table" then
        for _, v in pairs(res) do
            if v ~= ngx.null then
                return false
            end
        end
        return true
    end
    return false
end


local function _debug_err(msg,err)
    if debug then
        ngx_log(DEBUG, msg ,err)
    end
end

-- encapsulation redis connect
local function _connect_mod(self,redis)
    -- set timeout -- add by hirryli
    -- ngx.say("timeout:", timeout)
    if timeout then
        redis:set_timeout(timeout)
    else
        redis:set_timeout(3000)
    end

    local ok, err
    -- set redis unix socket
    if host:find("unix:/", 1, true) == 1 then
        ok, err = redis:connect(host)
        -- set redis host,port
    else
        ok, err = redis:connect(host, port)
    end
    if not ok or err then

        _debug_err("previous connection not finished,reason::",err)

        return nil, err
    end

    -- set auth
    if password then
        -- 该方法用于返回当前连接被成功重用的次数，如果出现错误返回nil，并返回错误描述
        -- 如果链接不是来自链接池，此方法返回0（及链接从未被重用，及新建连接）；如果来自链接池返回值始终大于0；因此该方法可以用于判断当前连接是否来自连接池。
        -- 如果需要密码，来自连接池的链接不需要再进行auth验证；如果不做这个判断，连接池不起作用
        local times, err = redis:get_reused_times()

        if times == 0 then

            local ok, err = redis:auth(password)
            if not ok or err then
                _debug_err("failed to set redis password,reason::",err)
                return nil, err
            end
        elseif err then
            _debug_err( "failed to get this connect reused times,reason::",err)
            return nil, err
        end
    end

    if db_index >0 then
        local ok, err = redis:select(db_index)
        if not ok or err then
            _debug_err( "failed to select redis databse index to" , db_index , ",reason::",err)
            return nil, err
        end
    end

    return redis, nil
end


local function _init_connect()
    -- init redis
    local redis, err = redis_c:new()
    if not redis then
        _debug_err( "failed to init redis,reason::",err)
        return nil, err
    end

    -- get connect
    local ok, err = _connect_mod(self,redis)
    if not ok or err then
        _debug_err( "failed to create redis connection,reason::",err)
        return nil, err
    end
    return redis,nil
end

-- put it into the connection pool of size (default 100), with max idle time (default 60s)
local function _set_keepalive_mod(self,redis )
    return redis:set_keepalive(keepalive, pool_size)
end

-- encapsulation subscribe
function _M.subscribe( self, channel )

    -- init redis
    local redis, err = _init_connect()
    if not redis then
        _debug_err( "failed to init redis,reason::",err)
        return nil, err
    end
    -- sub channel
    local res, err = redis:subscribe(channel)

    if not res then
        _debug_err("failed to subscribe channel,reason:",err)
        return nil, err
    end
    ngx.say("1: subscribe: ", cjson.encode(res))
    local function do_read_func ( do_read )
        if do_read == nil or do_read == true then
            res, err = redis:read_reply()
            if not res then
                _debug_err("failed to read subscribe channel reply,reason:",err)
                return nil, err
            end
            return res
        end

        -- if do_read is false
        redis:unsubscribe(channel)
        if not res then
            ngx.log(ngx.ERR, err)
            return
        else
            -- redis 推送的消息格式，可能是
            -- {"message", ...} 或
            -- {"unsubscribe", $channel_name, $remain_channel_num}
            -- 如果返回的是前者，说明我们还在读取 Redis 推送过的数据
            if res[1] ~= "unsubscribe" then
                repeat
                    -- 需要抽空已经接收到的消息
                    res, err = red:read_reply()
                    if not res then
                        ngx.log(ngx.ERR, err)
                        return
                    end
                until res[1] == "unsubscribe"
            end
        end
        _set_keepalive_mod(self,redis)
        return
    end

    return do_read_func
end

-- init pipeline,default cmds num is 4
function _M.init_pipeline(self, n)
    self._reqs = new_tab(n or 4, 0)
end

-- cancel pipeline
function _M.cancel_pipeline(self)
    self._reqs = nil
end

-- commit pipeline
function _M.commit_pipeline(self)
    -- get cache cmds
    local _reqs = rawget(self, "_reqs")
    if not _reqs then
        _debug_err("failed to commit pipeline,reason:no pipeline")
        return nil, "no pipeline"
    end

    self._reqs = nil

    -- init redis
    local redis, err = _init_connect()
    if not redis then
        _debug_err( "failed to init redis,reason::",err)
        return nil, err
    end

    redis:init_pipeline()

    --redis command like set/get ...
    for _, vals in ipairs(_reqs) do
        -- vals[1] is redis cmd
        local fun = redis[vals[1]]
        -- get params without cmd
        table.remove(vals , 1)
        -- invoke redis cmd
        fun(redis, unpack(vals))
    end

    -- commit pipeline
    local results, err = redis:commit_pipeline()
    if not results or err then
        _debug_err( "failed to commit pipeline,reason:",err)
        return {}, err
    end

    -- check null
    if _is_null(results) then
        results = {}
        ngx.log(ngx.WARN, "redis result is null")
    end

    -- put it into the connection pool
    _set_keepalive_mod(self,redis)

    -- if null set default value nil
    for i,value in ipairs(results) do
        if _is_null(value) then
            results[i] = nil
        end
    end

    return results, err
end

-- common method
local function do_command(self, cmd, ...)

    -- pipeline reqs
    local _reqs = rawget(self, "_reqs")
    if _reqs then
        -- append reqs
        _reqs[#_reqs + 1] = {cmd,...}
        return
    end

    -- init redis
    local redis, err = _init_connect()
    if not redis then
        _debug_err( "failed to init redis,reason::",err)
        return nil, err
    end

    -- exec redis cmd
    local method = redis[cmd]
    local result, err = method(redis, ...)
    if not result or err then
        return nil, err
    end

    -- check null
    if _is_null(result) then
        result = nil
    end

    -- put it into the connection pool
    local ok, err = _set_keepalive_mod(self,redis)
    if not ok or err then
        return nil, err
    end

    return result, nil
end

-- init options
function _M.new(self, opts)
    opts = opts or {}
    if (type(opts) ~= "table") then
        return nil, "user_config must be a table"
    end

    for k, v in pairs(opts) do
        if k == "host" then
            if type(v) ~= "string" then
                return nil, '"host" must be a string'
            end
            host = v
        elseif k == "port" then
            if type(v) ~= "number" then
                return nil, '"port" must be a number'
            end
            if v < 0 or v > MAX_PORT then
                return nil, ('"port" out of range 0~%s'):format(MAX_PORT)
            end
            port = v
        elseif k == "password" then
            if type(v) ~= "string" then
                return nil, '"password" must be a string'
            end
            password = v
        elseif k == "db_index" then
            if type(v) ~= "number" then
                return nil, '"db_index" must be a number'
            end
            if v < 0 then
                return nil, '"db_index" must be >= 0'
            end
            db_index = v
        elseif k == "timeout" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "timeout"'
            end
            timeout = v
        elseif k == "keepalive" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "keepalive"'
            end
            keepalive = v
        elseif k == "pool_size" then
            if type(v) ~= "number" or v < 0 then
                return nil, 'invalid "pool_size"'
            end
            pool_size = v
        end
    end

    if not (host and port) then
        return nil, "no redis server configured. \"host\"/\"port\" is required."
    end

    return setmetatable({},mt)
end

-- dynamic cmd
setmetatable(_M, {__index = function(self, cmd)
    local method =
    function (self, ...)
        return do_command(self, cmd, ...)
    end

    -- cache the lazily generated method in our
    -- module table
    _M[cmd] = method
    return method
end})

return _M