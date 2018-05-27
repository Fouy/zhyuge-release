
-- 设置响应头信息
local uri = ngx.var.request_uri

-- ngx.log(ngx.ERR, "+++++++++++++: ", string.find(uri, "meizitu.net"))

local result = string.find(uri, "meizitu.net")
if result == nil then -- 普通请求
    ngx.header["Content-Type"] = "text/html;charset=UTF-8"
else -- 妹子图代理请求
    ngx.header["Content-Type"] = "image/jpeg"
end

