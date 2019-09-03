local cjson = require "cjson"
local mysql = require("libs.mysql")
local redis = require "libs.redis_iresty"

local _M = {}

_M._VERSION="0.1"

-- 查询随机广告
function _M:randAds()
	local red = redis:new()
	local res, err = red:get("Zpc:Count")
    if not res then
        return '/images/zpc/1.jpg'
    end

    if res == ngx.null then
        return '/images/zpc/2.jpg'
    end

	math.randomseed(os.time())
	local seq = math.random(1, res)

	return '/images/zpc/' .. seq .. '.jpg'
end

return _M
