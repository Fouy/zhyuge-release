local cjson = require "cjson"
local mysql = require("libs.mysql")
local html_util = require("libs.html")
local string_util = require("libs.string_util")
local type_service = require("service.movie_type_service")
local region_service = require("service.region_service")
local station_service = require("service.station_service")
local utf8sub = require("libs.utf8sub")
local redis = require "libs.redis_iresty"

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

-- 查询列表 查询条件：分类 type(classify)、类型 type_ids、地区 region_ids、年份 year、关键字 keyword、排序 sort、评分 score
function _M:list( args )
	local pageSize = tonumber(args["pageSize"])
	local start = (tonumber(args["pageNo"])-1) * pageSize
	local classify = args["classify"]
	local typeId = args["type"]
	local regionId = args["region"]
	local year = args["year"]
	local keyword = args["keyword"]
	local sort = args["sort"]
	local score = args["score"]

	local db = mysql:new()
	local sql = "select * from movie where 1=1 "
	local tempSql = ''
	-- 分类 type(classify)
	if classify ~= nil and classify ~= "" then
		tempSql = " and type = %d "
		tempSql = string.format(tempSql, tonumber(classify))
		sql = sql .. tempSql
	end
	-- 类型 type_ids
	if typeId ~= nil and typeId ~= '' and typeId ~= '-1' then
		tempSql = " and ( type_ids = %s or type_ids like CONCAT('%%,', %s, ',%%') or type_ids like CONCAT('%%,', %s) or type_ids like CONCAT(%s, ',%%') ) "
		tempSql = string.format(tempSql, typeId, typeId, typeId, typeId)
		sql = sql .. tempSql
	end
	-- 地区 region_ids
	if regionId ~= nil and regionId ~= '' and regionId ~= '-1' then
		tempSql = " and ( region_ids = %s or region_ids like CONCAT('%%,', %s, ',%%') or region_ids like CONCAT('%%,', %s) or region_ids like CONCAT(%s, ',%%') ) "
		tempSql = string.format(tempSql, regionId, regionId, regionId, regionId)
		sql = sql .. tempSql
	end
	-- 年份 year
	if year ~= nil and year ~= '' and year ~= '-1' then
		tempSql = " and year = %d "
		tempSql = string.format(tempSql, year)
		sql = sql .. tempSql
		-- ngx.log(ngx.ERR, "++++++++++++ " .. year)
	end
	-- 关键字 keyword
	if keyword ~= nil and keyword ~= "" then
		tempSql = " and name like %s "
		tempSql = string.format(tempSql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
		sql = sql .. tempSql
	end
	-- 评分 score
	if score ~= nil and score ~= "" then
		tempSql = " and score >= %s "
		tempSql = string.format(tempSql, score)
		sql = sql .. tempSql
	end

	-- 排序
	if sort == '2' then 
		sql = sql .. ' order by score desc '
	else
		sql = sql .. ' order by release_date desc '
	end

	-- 分页
	tempSql = " limit %d, %d "
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
		self.convert(v)
		self.convertList(v)
	end

	return res
end

-- 查询分页总数 查询条件：分类 type、类型 type_ids、地区 region_ids、年份 year、关键字 keyword
function _M:count( args )
	local classify = args["classify"]
	local typeId = args["type"]
	local regionId = args["region"]
	local year = args["year"]
	local keyword = args["keyword"]
	local score = args["score"]

	local db = mysql:new()
	local sql = "select count(1) as count from movie where 1=1 "
	-- 分类 type(classify)
	if classify ~= nil and classify ~= "" then
		tempSql = " and type = %d "
		tempSql = string.format(tempSql, tonumber(classify))
		sql = sql .. tempSql
	end
	-- 类型 type_ids
	if typeId ~= nil and typeId ~= '' and typeId ~= '-1' then
		tempSql = " and ( type_ids = %s or type_ids like CONCAT('%%,', %s, ',%%') or type_ids like CONCAT('%%,', %s) or type_ids like CONCAT(%s, ',%%') ) "
		tempSql = string.format(tempSql, typeId, typeId, typeId, typeId)
		sql = sql .. tempSql
	end
	-- 地区 region_ids
	if regionId ~= nil and regionId ~= '' and regionId ~= '-1' then
		tempSql = " and ( region_ids = %s or region_ids like CONCAT('%%,', %s, ',%%') or region_ids like CONCAT('%%,', %s) or region_ids like CONCAT(%s, ',%%') ) "
		tempSql = string.format(tempSql, regionId, regionId, regionId, regionId)
		sql = sql .. tempSql
	end
	-- 年份 year
	if year ~= nil and year ~= '' and year ~= '-1' then
		tempSql = " and year = %d "
		tempSql = string.format(tempSql, year)
		sql = sql .. tempSql
	end
	-- 关键字 keyword
	if keyword ~= nil and keyword ~= "" then
		tempSql = " and name like %s "
		tempSql = string.format(tempSql, ngx.quote_sql_str('%%' .. keyword .. '%%'))
		sql = sql .. tempSql
	end
	-- 评分 score
	if score ~= nil and score ~= "" then
		tempSql = " and score >= %s "
		tempSql = string.format(tempSql, score)
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

-- 高分电影（主页）
function _M:highmarks()
	local param = {pageSize=10}
	param["score"] = '8'
	param['classify'] = '1'
	
	local count = self:count(param)
	local pageNo = 1
	if count % 10 == 0 then
		pageNo = count / 10
	else
		pageNo = count / 10 + 1
	end

	math.randomseed(os.time())
	param['pageNo'] = math.random(1, pageNo)

	local list = self:list(param)
	return list
end

-- 电视剧更新（主页）
function _M:dramaindex()
	local param = {}
	param["pageNo"] = 1
	param["pageSize"] = 10
	param["classify"] = '2'
	param["sort"] = '1'

	return self:list(param)
end

-- 查询近期热播(电影)
function _M:hot()
	local db = mysql:new()
	local sql = "select * from movie where type = 1 order by modify_time desc limit 4 "

	db:query("SET NAMES utf8")
	local res, err, errno, sqlstate = db:query(sql)
	db:close()
	if not res then
		ngx.say(err)
		return {}
	end

	for i,v in ipairs(res) do
		self.convert(v)
		self.convertList(v)
	end

	return res
end

-- 查询排行榜 typeKey: 1 电影、2 电视剧
function _M:ranking(typeKey)
	local result = {}
	local red = redis:new()

	-- local res, err = red:zrevrange('day:rank:'..typeKey, 0, 20, 'withscores')
	local res, err = red:zrevrange('day:rank:'..typeKey, 0, 20)
	if not res then
	    ngx.log(ngx.ERR, "failed to get day ranking: ", err)
	    result['dayRank'] = {}
	else
		local temp = {}
		for i,v in ipairs(res) do
			local entity = self:detail(v)
			local tempRes, tempErr = red:zscore('day:rank:'..typeKey, v)
			-- ngx.log(ngx.ERR, "Get day score: ", cjson.encode(tempRes))
			entity['downCount'] = tempRes
			table.insert(temp, entity)
		end
		result['dayRank'] = temp
	end
	-- ngx.log(ngx.ERR, "Get day ranking: ", cjson.encode(res))

	local res, err = red:zrevrange('week:rank:'..typeKey, 0, 20)
	if not res then
	    ngx.log(ngx.ERR, "failed to get week ranking: ", err)
	    result['weekRank'] = {}
	else
		local temp = {}
		for i,v in ipairs(res) do
			local entity = self:detail(v)
			local tempRes, tempErr = red:zscore('week:rank:'..typeKey, v)
			entity['downCount'] = tempRes
			table.insert(temp, entity)
		end
		result['weekRank'] = temp
	end
	-- ngx.log(ngx.ERR, "Get week ranking: ", cjson.encode(res))

	local res, err = red:zrevrange('month:rank:'..typeKey, 0, 20)
	if not res then
	    ngx.log(ngx.ERR, "failed to get month ranking: ", err)
	    result['monthRank'] = {}
	else
		local temp = {}
		for i,v in ipairs(res) do
			local entity = self:detail(v)
			local tempRes, tempErr = red:zscore('month:rank:'..typeKey, v)
			entity['downCount'] = tempRes
			table.insert(temp, entity)
		end
		result['monthRank'] = temp
	end
	-- ngx.log(ngx.ERR, "Get month ranking: ", cjson.encode(res))
	return result
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
		self.convertList(v)
	end

	return res
end

-- 查询详情
function _M:detail( movieId )
	-- ngx.log(ngx.ERR, "Detail ranking: ", movieId)
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
	-- 设置分类名称
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
	-- 设置评分(当score在MySQL中为null时，entity['score']的类型为userdata，暂时不知道如何转化)
	if type(entity['score']) ~= 'userdata' and entity['score'] ~= "" then
		-- ngx.log(ngx.ERR,  entity['score'])
		if entity['score'] % 2 == 0 then
			entity['scoreimg'] = entity['score'] * 5
		else
			entity['scoreimg'] = math.floor(entity['score']/2) * 10 + 5
		end
	else
		entity['score'] = nil
	end

end


-- 字段长度处理
function _M.convertList( entity )
	-- 简介保留（100）
	entity["introduction"] = html_util:clearHTML(entity["introduction"])
	if utf8sub:utf8len(entity["introduction"]) > 100 then
		entity["introduction"] = utf8sub:utf8sub(entity["introduction"], 1, 100)
	end
	-- 电影名保留（10）
	if utf8sub:utf8len(entity["name"]) > 10 then
		entity["name"] = utf8sub:utf8sub(entity["name"], 1, 10)
		entity["name"] = entity["name"] .. '...'
	end
	-- type_names保留（5）
	if entity["type_names"] ~= nil and utf8sub:utf8len(entity["type_names"]) > 5 then
		entity["type_names"] = utf8sub:utf8sub(entity["type_names"], 1, 5)
		entity["type_names"] = entity["type_names"] .. '...'
	end
	-- region_names保留（5）
	if entity["region_names"] ~= nil and utf8sub:utf8len(entity["region_names"]) > 5 then
		entity["region_names"] = utf8sub:utf8sub(entity["region_names"], 1, 5)
		entity["region_names"] = entity["region_names"] .. '...'
	end

end

return _M
