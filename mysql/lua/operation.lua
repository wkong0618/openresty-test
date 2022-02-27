local cjson = require("cjson");
local db_config = ngx.shared.db_config;
local args = ngx.req.get_uri_args()
local action = args['action']
local mysql = require("libs.mysql")
local db = mysql:new()


-- 查询列表操作
function lists()
    local data = {}
    ngx.req.read_body()
    local posts = ngx.req.get_post_args()
    local page, pagesize, offset = 0, 15, 0
    if posts.page then
        page = posts.page
    end
    if posts.pagesize then
        pagesize = posts.pagesize
    end
    if page > 1 then
        offset = (page -1)*pagesize
    end

    local res, err, errno, sqlstate = db:query('SELECT * FROM `'.. db_config:get("table") ..'` LIMIT '..offset..','..pagesize)
    db:close()
    if not res then
        ngx.say(cjson.encode({code=200, message=err, data=nil}))
    else
        ngx.say(cjson.encode({code=200, message="", data=res}))
    end
end

-- 添加操作
function add()
    ngx.req.read_body()
    local data = ngx.req.get_post_args()
    if  data.name ~= nil then
        local sql = 'INSERT INTO '..db_config:get("table")..'(name) VALUES ("'..data.name..'")';
        local res, err, errno, sqlstate = db:query(sql)
        db:close()
        if not res then
            ngx.say(cjson.encode({code=501, message="添加失败"..err..';sql:'..sql, data=nil}))
        else
            ngx.say(cjson.encode({code=200, message="添加成功", data=res.insert_id}))
        end
    else
        ngx.say(cjson.encode({code=501, message="参数不对", data=nil}))
    end
end

-- 详情页
function detail()
    ngx.req.read_body()
    local post_args = ngx.req.get_post_args()
    if post_args.id ~= nil then
        local data, err, errno, sqlstate = db:query('SELECT * FROM '..db_config:get("table")..' WHERE id='..post_args.id..' LIMIT 1', 1)
        db:close()
        local res = {}
        if data ~= nil then
            res.code = 200
            res.message = '请求成功'
            res.data = data[1]
        else
            res.code = 502
            res.message = '没有数据'
            res.data = data
        end
        ngx.say(cjson.encode(res))
    else
        ngx.say(cjson.encode({code = 501, message = '参数错误', data = nil}))
    end

end

-- 删除操作
function delete()
    ngx.req.read_body()
    local data = ngx.req.get_post_args()
    if data.id ~= nil then
        local res, err, errno, sqlstate = db:query('DELETE FROM '..db_config:get("table")..' WHERE id='..data.id)
        db:close()
        if not res or res.affected_rows < 1 then
            ngx.say(cjson.encode({code = 504, message = '删除失败', data = nil}))
        else
            ngx.say(cjson.encode({code = 200, message = '修改成功', data = nil}))
        end
    else
        ngx.say(cjson.encode({code = 501, message = '参数错误', data = nil}))
    end
end

-- 修改操作
function update()
    ngx.req.read_body()
    local post_args = ngx.req.get_post_args()
    if post_args.id ~= nil and post_args.name ~= nil then
        local res, err, errno, sqlstate = db:query('UPDATE '..db_config:get("table")..' SET `name` = "'..post_args.name..'" WHERE id='..post_args.id)
        db:close()
        if  not res or res.affected_rows < 1 then
            ngx.say(cjson.encode({code = 504, message = '修改失败', data = nil}));
        else
            ngx.say(cjson.encode({code = 200, message = '修改成功', data = nil}))
        end
    else
        ngx.say(cjson.encode({code = 501, message = '参数错误', data = nil}));
    end
end

if action == 'lists' then
    lists()
elseif action == 'detail' then
    detail()
elseif action == 'add' then
    add()
elseif action == 'delete' then
    delete()
elseif action == 'update' then
    update()
end