--导入common函数库
local common = require("common")
local read_http = common.read_http
local read_nginx_cache = common.read_nginx_cache
local read_redis_cluster = common.read_redis_cluster
local level_cache = common.level_cache
--导入json转化库
local cjson = require('cjson')
-- 获取请求参数
local id = ngx.var[1]
--redis集群连接配置
local redis_cluster_config = {
    dict_name = "redis_cluster_slot_locks",               --shared dictionary name for locks, if default value is not used
    refresh_lock_key = "refresh_lock",      --shared dictionary name prefix for lock of each worker, if default value is not used
    name = "itemCluster",                   --rediscluster name
    serv_list = {                           --redis cluster node list(host and port),
        { ip = "127.0.0.1", port = 7001 },
        { ip = "127.0.0.1", port = 7002 },
        { ip = "127.0.0.1", port = 7003 },
        { ip = "127.0.0.1", port = 8001 },
        { ip = "127.0.0.1", port = 8002 },
        { ip = "127.0.0.1", port = 8003 }
    },
    keepalive_timeout = 60000,              --redis connection pool idle timeout
    keepalive_cons = 1000,                  --redis connection pool size
    connect_timeout = 1000,              --timeout while connecting
    max_redirection = 5,                    --maximum retry attempts for redirection
    max_connection_attempts = 1             --maximum retry attempts for connection
}

-- 查询商品信息
-- local itemJSON = read_http('/item/' .. id,nil)
local item_key= "item:id:" .. id
local item_http_path = '/item/' .. id
local itemJSON = level_cache("item_cache",redis_cluster_config,item_key,item_http_path,nil,300)
-- 查询库存信息
-- local stockJSON = read_http('/item/stock/' .. id,nil)
local stock_key="stock:id:" .. id
local stock_http_path = '/item/stock/' .. id
local stockJSON = level_cache("item_cache",redis_cluster_config,stock_key,stock_http_path,nil,5)
--json转化为lua的table

local item = cjson.decode(itemJSON)
local stock = cjson.decode(stockJSON)
--组合数据
item.stock = stock.stock
item.sold = stock.sold
--将table转化为json
local result = cjson.encode(item)


-- 返回结果

ngx.say(
        result
)