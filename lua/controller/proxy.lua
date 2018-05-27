local cjson = require "cjson"
local req = require "dispatch.req"
local result = require "common.result"
local httpdns = require "libs.http_dns"

local _M = {}

_M._VERSION="0.1"

-- 获取类型列表
function _M:picture()
	local args = req.getArgs()
	local imgUrl = args['imgUrl']

    local param = {}
    param['method'] = "GET"
    param['headers'] = {
            	['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36',
			  	['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
			  	['Accept-Language'] = 'zh-CN,zh;q=0.9',
			  	['Referer'] = imgUrl
        	}
    local res = httpdns:http_request_with_dns(imgUrl, param)

    ngx.say(res.body)
end

return _M