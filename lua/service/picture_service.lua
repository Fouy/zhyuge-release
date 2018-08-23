local cjson = require "cjson"
local mysql = require("libs.mysql")
local html_util = require("libs.html")
local string_util = require("libs.string_util")
local utf8sub = require("libs.utf8sub")
local redis = require "libs.redis_iresty"
local picture_url_service = require "service.picture_url_service"
local date_util = require "libs.date_util"

local _M = {}

_M._VERSION="0.1"

-- 查询列表 查询条件：分类 type(type_id)
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local typeId = args["type"]
	local keyword = args["keyword"]
	local promote = args['promote']

	local db = mysql:new()
	local sql = "select * from picture where 1=1 "
	local tempSql = ''
	-- 分类 type(type_id)
	if typeId ~= nil and typeId ~= "" and typeId ~= '-1' then
		tempSql = " and type_id = %d "
		tempSql = string.format(tempSql, tonumber(typeId))
		sql = sql .. tempSql
	end
	-- 推荐 promote
	if promote ~= nil and promote ~= "" then
		tempSql = " and promote = %d "
		tempSql = string.format(tempSql, tonumber(promote))
		sql = sql .. tempSql
	end
	-- 关键词
	if keyword ~= nil and keyword ~= "" then
		sql = sql .. " and name like %s "
		sql = string.format(sql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
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

	for i,v in ipairs(res) do
		self:convert(v)
	end

	return res
end

-- 查询分页总数 查询条件：分类 type(type_id)
function _M:count( args )
	local typeId = args["type"]
	local keyword = args["keyword"]
	local promote = args['promote']

	local db = mysql:new()
	local sql = "select count(1) as count from picture where 1=1 "
	-- 分类 type(type_id)
	if typeId ~= nil and typeId ~= "" and typeId ~= '-1' then
		tempSql = " and type_id = %d "
		tempSql = string.format(tempSql, tonumber(typeId))
		sql = sql .. tempSql
	end
	-- 推荐 promote
	if promote ~= nil and promote ~= "" then
		tempSql = " and promote = %d "
		tempSql = string.format(tempSql, tonumber(promote))
		sql = sql .. tempSql
	end
	-- 关键词
	if keyword ~= nil and keyword ~= "" then
		sql = sql .. " and name like %s "
		sql = string.format(sql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
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
	param['promote'] = '1'
	
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

-- 实体转化
function _M:convert( entity )
	-- 设置图片张数
	local diff = os.time() - date_util:getTimeByDate(entity['create_time'])

	if diff >= 15*60 and entity['number'] <= 0 then
		local count = picture_url_service:count({pictureId = entity['picture_id']})
		local param = {pictureId = entity['picture_id'], number = count}
		param['favorite'] = entity['favorite']   -- 保持原值
		self:update(param)
		entity['number'] = count
	end

	-- 设置点赞数
	if entity['favorite'] <= 0 then
		math.randomseed(os.time())
		local param = {pictureId = entity['picture_id']}
		local tempFavorite = 200 + math.random(1, 100)
		param['favorite'] = tempFavorite
		param['number'] = entity['number']	-- 保持原值
		self:update(param)

		entity['favorite'] = tempFavorite
	end

	-- 前端图片张数 容错
	if tonumber(entity['number']) <= 0 then
		entity['number'] = '10'
	end

end


-- 更新图片 (number 图片数、favorite 点赞数)
function _M:update( picture_entity )
	picture_entity['number'] = ngx.quote_sql_str(picture_entity['number'])
	picture_entity['favorite'] = ngx.quote_sql_str(picture_entity['favorite'])

	local pictureId = tonumber(picture_entity["pictureId"])

	local db = mysql:new()
	local sql = "update picture set `number`=%s, `favorite`=%s, `modify_time`=now() "
			.. " where picture_id = %d"
	sql = string.format(sql, picture_entity['number'], picture_entity['favorite'], pictureId)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end
end

-- 点赞
function _M:favorite( args )
	local pictureId = tonumber(args["pictureId"])

	local db = mysql:new()
	local sql = "update picture set `favorite` = `favorite` + 1, `modify_time`=now() "
			.. " where picture_id = %d"
	sql = string.format(sql, pictureId)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end
end

return _M
