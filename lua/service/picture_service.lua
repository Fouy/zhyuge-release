local cjson = require "cjson"
local mysql = require("libs.mysql")
local html_util = require("libs.html")
local string_util = require("libs.string_util")
local utf8sub = require("libs.utf8sub")
local redis = require "libs.redis_iresty"

local _M = {}

_M._VERSION="0.1"

-- 查询列表 查询条件：分类 type(type_id)
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local typeId = args["type"]

	local db = mysql:new()
	local sql = "select * from picture where 1=1 "
	local tempSql = ''
	-- 分类 type(type_id)
	if typeId ~= nil and typeId ~= "" and typeId ~= '-1' then
		tempSql = " and type_id = %d "
		tempSql = string.format(tempSql, tonumber(typeId))
		sql = sql .. tempSql
	end

	-- 分页
	tempSql = " order by `picture_id` desc limit %d, %d "
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

-- 查询分页总数 查询条件：分类 type(type_id)
function _M:count( args )
	local typeId = args["type"]

	local db = mysql:new()
	local sql = "select count(1) as count from picture where 1=1 "
	-- 分类 type(type_id)
	if typeId ~= nil and typeId ~= "" then
		tempSql = " and type_id = %d "
		tempSql = string.format(tempSql, tonumber(typeId))
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

-- 查询详情
function _M:detail( pictureId )
	-- ngx.log(ngx.ERR, "Detail ranking: ", pictureId)
	
	local db = mysql:new()
	local sql = "select * from picture where picture_id = %d"
	sql = string.format(sql, tonumber(pictureId))

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	-- 设置类型名称
	local entity = res[1]

	-- ngx.log(ngx.ERR, "+++++++++++++: ", cjson.encode(entity))

	return entity
end

-- 猜你喜欢 number 图片个数
function _M:like(number)
	local param = {pageSize=number}
	
	local count = self:count(param)
	local pageNo = 1
	if count % number == 0 then
		pageNo = count / number
	else
		pageNo = count / number + 1
	end

	math.randomseed(os.time())
	param['pageNo'] = math.random(1, pageNo)

	local list = self:list(param)
	return list
end

return _M
