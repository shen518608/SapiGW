local jwt = require('jwt_token')
local my_verify = require('my_verify')
local user_info = ngx.shared.user_info
local tools = require "tools"

local _M = {}
function _M.check()
    -- 获取白名单
    local svc_code = user_info.svc_code
    -- ngx.log(ngx.ERR,'svc_code--->',svc_code)
    local is_white = tools.is_include(svc_code,white_list)
    -- ngx.log(ngx.ERR,'--->',is_white)

    if is_white == false then
        -- 获取cook
        local auth_key = ngx.var.cookie_auth_key
        -- ngx.log(ngx.ERR,'auth_key--->',auth_key)

        if auth_key == nil then
            -- ngx.var.login_uri = login_uri
            -- ngx.exec("/login")
            ngx.exit(ngx.HTTP_UNAUTHORIZED)
            return
        end

        -- 解密auth_key
        local load_token = jwt.decode_auth_token(auth_key)
        -- ngx.log(ngx.ERR,'load_token--->',json.encode(load_token))

        -- 获得用户id
        local user_id = load_token.payload.data.id
        -- ngx.log(ngx.ERR,'user_id--->',user_id)
        user_info['username'] = load_token.payload.data.username
        user_info['nickname'] = load_token.payload.data.nickname

        -- 获取真正的RUI
        local uri = user_info.real_uri

        -- 获取请求方法
        local method = ngx.req.get_method()

        -- 根据用户id获取权限列表
        local is_permission =  my_verify.get_verify(user_id,uri,method) -- 从权限系统redis获取
        -- ngx.log(ngx.ERR,'is_permission-->',is_permission)
        if is_permission ~= true then
            -- 第一次没有就先刷新下redis
            my_verify.write_verify(user_id)
            local is_permission =  my_verify.get_verify(user_id,uri,method)
            if is_permission ~= true then
                ngx.exit(ngx.HTTP_FORBIDDEN)
                return
            end
        end

    end
end

return _M