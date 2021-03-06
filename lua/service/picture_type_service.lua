local cjson = require "cjson"
local mysql = require("libs.mysql")

local _M = {}

_M._VERSION="0.1"

-- 查询列表
function _M:list()
	local db = mysql:new()
	local sql = "select * from picture_type"

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	return res
end

-- 查询列表(TOP10)
function _M:top10()
	local db = mysql:new()
	local sql = "select * from picture_type order by type_id asc limit 10 "

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
function _M:detail( typeId )
	local db = mysql:new()
	local sql = "select * from picture_type where type_id = %d"
	sql = string.format(sql, tonumber(typeId))

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
