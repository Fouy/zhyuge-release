local cjson = require "cjson"
local mysql = require("libs.mysql")
local html_util = require("libs.html")
local string_util = require("libs.string_util")
local type_service = require("service.movie_type_service")
local region_service = require("service.region_service")
local station_service = require("service.station_service")
local utf8sub = require("libs.utf8sub")

local _M = {}

_M._VERSION="0.1"


-- 更新文章
function _M:update( movie_entity )
	movie_entity['name'] = ngx.quote_sql_str(movie_entity['name'])
	movie_entity['type_id'] = ngx.quote_sql_str(movie_entity['type_id'])
	movie_entity['year'] = ngx.quote_sql_str(movie_entity['year'])
	movie_entity['logo_url'] = ngx.quote_sql_str(movie_entity['logo_url'])
	movie_entity['score'] = ngx.quote_sql_str(movie_entity['score'])
	movie_entity['director'] = ngx.quote_sql_str(movie_entity['director'])
	movie_entity['playwright'] = ngx.quote_sql_str(movie_entity['playwright'])
	movie_entity['actor'] = ngx.quote_sql_str(movie_entity['actor'])
	movie_entity['region_id'] = ngx.quote_sql_str(movie_entity['region_id'])
	movie_entity['language'] = ngx.quote_sql_str(movie_entity['language'])
	movie_entity['release_date'] = ngx.quote_sql_str(movie_entity['release_date'])
	movie_entity['length'] = ngx.quote_sql_str(movie_entity['length'])
	movie_entity['en_name'] = ngx.quote_sql_str(movie_entity['en_name'])
	movie_entity['introduction'] = ngx.quote_sql_str(movie_entity['introduction'])
	movie_entity['station_id'] = ngx.quote_sql_str(movie_entity['station_id'])
	movie_entity['station_movie_id'] = ngx.quote_sql_str(movie_entity['station_movie_id'])
	movie_entity['status'] = ngx.quote_sql_str(movie_entity['status'])
	movie_entity['create_time'] = ngx.quote_sql_str(movie_entity['create_time'])
	movie_entity['modify_time'] = ngx.quote_sql_str(movie_entity['modify_time'])

	local movieId = tonumber(movie_entity["movieId"])

	local db = mysql:new()
	local sql = "update movie set `name`=%s, `type_id`=%s, `year`=%s, `logo_url`=%s, `score`=%s, `director`=%s, `playwright`=%s, " 
			.. " `actor`=%s, `region_id`=%s, `language`=%s, `release_date`=%s, `length`=%s, `en_name`=%s, `introduction`=%s, `station_id`=%s, "
			.. " `station_movie_id`=%s, `status`=%s, `modify_time`=now() "
			.. " where movie_id = %d"
	sql = string.format(sql, movie_entity['name'], movie_entity['type_id'], movie_entity['year'], movie_entity['logo_url'], movie_entity['score'], movie_entity['director'], movie_entity['playwright'], 
		movie_entity['actor'], movie_entity['region_id'], movie_entity['language'], movie_entity['release_date'], movie_entity['length'], movie_entity['en_name'], movie_entity['introduction'], movie_entity['station_id'], 
		movie_entity['station_movie_id'], movie_entity['status'],
		movieId)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end
end

-- 查询列表 查询条件：分类 type、类型 type_ids、地区 region_ids、年份 year、关键字 keyword
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local _type = args["type"]
	local typeId = args["typeId"]
	local regionId = args["regionId"]
	local year = args["year"]
	local keyword = args["keyword"]

	local db = mysql:new()
	local sql = "select * from movie where 1=1 "
	-- 分类 type
	if _type ~= nil and _type ~= "" then
		sql = sql .. " and type = %d "
		sql = string.format(sql, tonumber(typeId))
	end
	-- 类型 type_ids
	if typeId ~= nil and typeId ~= "" then
		sql = sql .. " and ( type_ids = %s or type_ids like CONCAT('%', %s, ',%') or type_ids like CONCAT('%,', %s, '%') ) "
		sql = string.format(sql, typeId, typeId, typeId)
	end
	-- 地区 region_ids
	if regionId ~= nil and regionId ~= "" then
		sql = sql .. " and ( region_ids = %s or region_ids like CONCAT('%', %s, ',%') or region_ids like CONCAT('%,', %s, '%') ) "
		sql = string.format(sql, regionId, regionId, regionId)
	end
	-- 年份 year
	if year ~= nil and year ~= "" then
		sql = sql .. " and year = %s "
		sql = string.format(sql, ngx.quote_sql_str(year))
	end
	-- 关键字 keyword
	if keyword ~= nil and keyword ~= "" then
		sql = sql .. " and name like %s "
		sql = string.format(sql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
	end

	sql = sql .. " order by movie_id desc limit %d, %d "
	sql = string.format(sql, start, pageSize)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	for i,v in ipairs(res) do
		self.convert(v)
	end

	return res
end

-- 查询分页总数 查询条件：分类 type、类型 type_ids、地区 region_ids、年份 year、关键字 keyword
function _M:count( args )
	local _type = args["type"]
	local typeId = args["typeId"]
	local regionId = args["regionId"]
	local year = args["year"]
	local keyword = args["keyword"]

	local db = mysql:new()
	local sql = "select count(1) as count from movie where 1=1 "
	-- 分类 type
	if _type ~= nil and _type ~= "" then
		sql = sql .. " and type = %d "
		sql = string.format(sql, tonumber(typeId))
	end
	-- 类型 type_ids
	if typeId ~= nil and typeId ~= "" then
		sql = sql .. " and ( type_ids = %s or type_ids like CONCAT('%', %s, ',%') or type_ids like CONCAT('%,', %s, '%') ) "
		sql = string.format(sql, typeId, typeId, typeId)
	end
	-- 地区 region_ids
	if regionId ~= nil and regionId ~= "" then
		sql = sql .. " and ( region_ids = %s or region_ids like CONCAT('%', %s, ',%') or region_ids like CONCAT('%,', %s, '%') ) "
		sql = string.format(sql, regionId, regionId, regionId)
	end
	-- 年份 year
	if year ~= nil and year ~= "" then
		sql = sql .. " and year = %s "
		sql = string.format(sql, ngx.quote_sql_str(year))
	end
	-- 关键字 keyword
	if keyword ~= nil and keyword ~= "" then
		sql = sql .. " and name like %s "
		sql = string.format(sql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
	end

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return 0
	end

	-- ngx.log(ngx.ERR, sql)
	-- ngx.log(ngx.ERR, "+++++++++++++" .. cjson.encode(res[1]['count']))

	return res[1]['count']
end

-- 查询近期热播
function _M:hot()
	local db = mysql:new()
	local sql = "select * from movie order by modify_time desc limit 4 "

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	for i,v in ipairs(res) do
		self.convert(v)
	end

	return res
end

-- 猜你喜欢
function _M:like(type)
	local db = mysql:new()
	local sql = "select * from movie where type = %s order by modify_time desc limit 5 "
	sql = string.format(sql, type)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	for i,v in ipairs(res) do
		self.convert(v)
	end

	return res
end

-- 查询详情
function _M.detail( self, movieId )
	movieId = ngx.quote_sql_str(movieId)

	local db = mysql:new()
	local sql = "select * from movie where movie_id = %s"
	sql = string.format(sql, movieId)

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	-- 设置类型名称
	local entity = res[1]
	self.convert(entity)

	return entity
end

-- 实体转化
function _M.convert( entity )
	if entity["type_ids"] then
		local typeList = string_util:strSplit(entity["type_ids"], ',')
		local typeNames = ''
		for i,v in ipairs(typeList) do
			local typeEntity = type_service:detail(v)
			if typeNames == '' then
				typeNames = typeEntity['name']
			else
				typeNames = typeNames .. ',' .. typeEntity['name']
			end
		end
		entity["type_names"] = typeNames
	end

	-- 设置地区名称
	if entity['region_ids'] then
		local regionList = string_util:strSplit(entity["region_ids"], ',')
		local regionNames = ''
		for i,v in ipairs(regionList) do
			local regionEntity = region_service:detail(v)
			if regionNames == '' then
				regionNames = regionEntity['name']
			else
				regionNames = regionNames .. ',' .. regionEntity['name']
			end
		end
		entity["region_names"] = regionNames
	end

	-- 设置源站信息
	if entity["station_id"] then
		local stationEntity = station_service:detail(entity["station_id"])
		entity["station_name"] = stationEntity["name"]
		entity["station_type"] = stationEntity["type"]
	end
end

return _M
