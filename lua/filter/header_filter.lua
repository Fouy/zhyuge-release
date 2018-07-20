
-- 设置响应头信息
local uri = ngx.var.request_uri

-- ngx.log(ngx.ERR, "+++++++++++++: ", string.find(uri, "meizitu.net"))

if string.find(uri, "meizitu.net") then -- 妹子图代理请求
	ngx.header["Content-Type"] = "image/jpeg"
elseif string.find(uri, "mtl.ttsqgs.com") then -- 美图录代理请求
	ngx.header["Content-Type"] = "image/jpeg"
else 
    ngx.header["Content-Type"] = "text/html;charset=UTF-8"
end

