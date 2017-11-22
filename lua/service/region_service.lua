local cjson = require "cjson"
local mysql = require("libs.mysql")

local _M = {}

_M._VERSION="0.1"

-- 查询列表
function _M:list()
	local db = mysql:new()
	local sql = "select * from region"

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	return res
end

-- 查询详情
function _M:detail( regionId )
	ngx.log(ngx.ERR, "FUCK YOU MAN: " .. regionId)
	local db = mysql:new()
	local sql = "select * from region where region_id = %d"
	sql = string.format(sql, tonumber(regionId))

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	return res[1]
end

return _M
