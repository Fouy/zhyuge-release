local cjson = require "cjson"
local mysql = require("libs.mysql")
local html_util = require("libs.html")
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

-- 查询列表
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local typeId = args["typeId"]
	local keyword = args["keyword"]

	local db = mysql:new()
	local sql = "select * from movie where 1=1 "
	if typeId ~= nil and typeId ~= "" then
		sql = sql .. " and type_id = %d "
		sql = string.format(sql, tonumber(typeId))
	end
	if keyword ~= nil and keyword ~= "" then
		sql = sql .. " and name like %s "
		sql = string.format(sql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
	end

	sql = sql .. " order by create_time desc limit %d, %d "
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
	if entity["type_id"] then
		local typeEntity = type_service:detail(entity["type_id"])
		entity["type_name"] = typeEntity["name"]
	end

	-- 设置地区名称
	if entity['region_id'] then
		local regionEntity = region_service:detail(entity["region_id"])
		entity["region_name"] = regionEntity["name"]
	end

	-- 设置源站信息
	if entity["station_id"] then
		local stationEntity = station_service:detail(entity["station_id"])
		entity["station_name"] = stationEntity["name"]
		entity["station_type"] = stationEntity["type"]
	end
end

return _M
