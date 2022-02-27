
local mysql = require "resty.mysql"
local db_config = ngx.shared.db_config;

local _M = {}
local config = {
    host = db_config:get("mysql.host"),
    port = db_config:get("mysql.port"),
    database = db_config:get("mysql.database"),
    user = db_config:get("mysql.user"),
    password = db_config:get("mysql.password"),
    max_package_size = db_config:get("mysql.max_package_size"),
}

function _M.new( self )
    local db, err = mysql:new()
    if not db then
        ngx.log(ngx.ERR, "failed to instantiate mysql: ", err)
        return nil
    end
    -- 1 sec
    db:set_timeout(1000)
    local ok, err, errcode, sqlstate = db:connect(config)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect:  ", err, errcode, sqlstate)
        return nil
    end
    ngx.log(ngx.ERR, "connected to mysql.")
    return db
end

function _M.close( self )
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    if self.subscribed then
        return nil, "subscribed state"
    end
    -- put it into the connection pool of size 100,
    -- with 10 seconds max idle timeout
    local ok, err = self.sock:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive:", err)
        return
    end
end

return _M