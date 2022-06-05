local redis_cluster = require "rediscluster"

-- 封装函数，发送http请求，并解析响应
local function read_http(path, params)
    local resp = ngx.location.capture(path,{
        method = ngx.HTTP_GET,
        args = params,
    })
    if not resp then
        -- 记录错误信息，返回404
        ngx.log(ngx.ERR, "http not found, path: ", path , ", args: ", args)
        ngx.exit(404)
    end
    return resp.body
end

-- 封装函数，从redis集群中读取数据
local function read_redis_cluster(config,key)
    local red_c = redis_cluster:new(config)
    local v, err = red_c:get(key)
    if err then
        ngx.log(ngx.ERR, "err: ", err)
    else
        return v
    end
end
-- 封装函数，从nginx集群中读取数据
local function read_nginx_cache(dic_name,key)
    local dic_cache = ngx.shared[dic_name]
    local val = dic_cache:get(key)
    return val
end

-- 封装函数，向nginx集群中写入数据
local function write_nginx_cache(dic_name,key,value,expire)
    local dic_cache = ngx.shared[dic_name]
    local val = dic_cache:set(key,value,expire)
    return val
end

-- 分级缓存
local function level_cache(ngx_dic_name,redis_cluster_config,cache_key,http_path,http_params,expire)
    --先查本地缓存
    local cache = read_nginx_cache(ngx_dic_name,cache_key)
    if not cache then
        --查询redis缓存
        cache = read_redis_cluster(redis_cluster_config,cache_key)
        if not cache then
            --查询服务器
            cache = read_http(http_path,http_params)
        end
        if cache and expire then
            --从redis或服务器中查到了缓存，保存到本地缓存
            write_nginx_cache(ngx_dic_name,cache_key,cache,expire)

        end
    end
    return cache
end

-- 将方法导出
local _M = {
    read_http = read_http,
    read_nginx_cache = read_nginx_cache,
    read_redis_cluster = read_redis_cluster,
    level_cache = level_cache
}
return _M
