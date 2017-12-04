local cjson = require "cjson"
local mysql = require("libs.mysql")

local _M = {}

_M._VERSION="0.1"

-- 查询列表
function _M:list(type, movie_id)
	local db = mysql:new()
	local sql = "select * from download_url where type = %s and movie_id = %s order by `order` asc"
	sql = string.format(sql, type, movie_id)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	return res
end

return _M
