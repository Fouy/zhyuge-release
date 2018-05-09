local cjson = require "cjson"
local mysql = require("libs.mysql")

local _M = {}

_M._VERSION="0.1"

-- 查询列表 查询条件：图片ID pictureId
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local pictureId = args["pictureId"]

	local db = mysql:new()
	local sql = "select * from picture_url where 1=1 "
	local tempSql = ''
	-- 图片ID pictureId
	if pictureId ~= nil and pictureId ~= "" then
		tempSql = " and picture_id = %d "
		tempSql = string.format(tempSql, tonumber(pictureId))
		sql = sql .. tempSql
	end

	-- 分页
	tempSql = " order by `order` asc limit %d, %d "
	tempSql = string.format(tempSql, start, pageSize)
	sql = sql .. tempSql
	-- ngx.log(ngx.ERR, "++++++++++++ " .. sql)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	return res
end

-- 查询分页总数 查询条件：图片ID pictureId
function _M:count( args )
	local pictureId = args["pictureId"]

	local db = mysql:new()
	local sql = "select count(1) as count from picture_url where 1=1 "
	-- 图片ID pictureId
	if pictureId ~= nil and pictureId ~= "" then
		tempSql = " and picture_id = %d "
		tempSql = string.format(tempSql, tonumber(pictureId))
		sql = sql .. tempSql
	end
	
	-- ngx.log(ngx.ERR, "++++++++++++ " .. sql)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return 0
	end

	-- ngx.log(ngx.ERR, "+++++++++++++" .. cjson.encode(res[1]['count']))
	return res[1]['count']
end


return _M
