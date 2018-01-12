local cjson = require "cjson"
local req = require "dispatch.req"
local result = require "common.result"
local movie_service = require "service.movie_service"
local movie_type_service = require "service.movie_type_service"
local common_service = require "service.common_service"
local region_service = require "service.region_service"
local hot_search_service = require "service.hot_search_service"
local download_url_service = require "service.download_url_service"
local template = require("resty.template")
local configCache = ngx.shared.configCache;
local redis = require "libs.redis_iresty"

local _M = {}

_M._VERSION="0.1"


-- 主页
function _M:index()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 20
	end

	-- ngx.log(ngx.ERR, "FUCK YOU MAN: ")
	-- 增加近期热播
	local hotList = movie_service:hot()
	local context = { hotList = hotList }
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	-- 增加高分电影
	context["scoreList"] = movie_service:highmarks()
	-- 增加电视剧更新
	context['dramaList'] = movie_service:dramaindex()
	-- 获取排行榜
	context['ranking'] = movie_service:ranking('1')
	-- ngx.log(ngx.ERR, "+++++++++++++: ", cjson.encode(context))
	
	template.render("index.html", context)
end

-- 分页接口
function _M:list()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 20
	end
	args["classify"] = '1'

	local list = movie_service:list(args)
	ngx.say(cjson.encode(result:success("查询成功", list)))
end

-- 高分电影接口（主页）
function _M:highmarks()
	local list = movie_service:highmarks()
	ngx.say(cjson.encode(result:success("查询成功", list)))
end

-- 搜索页
function _M:search()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local keyword = args["keyword"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	-- 去空格
	-- if keyword ~= nil or keyword ~= "" then
	-- 	args["keyword"] = args["keyword"]
	-- end
	args["pageSize"] = 20
	args["sort"] = '1'

	local list = movie_service:list(args)
	local context = { list = list }
	
	-- 设置分页内容
	local count = movie_service:count(args)
	local page = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	context['page'] = page
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	-- ngx.log(ngx.ERR, "++++++++++++ " .. cjson.encode(page))

	-- 封装搜索条件
	context['args'] = args

	template.render("search.html", context)
end

-- 片库页
function _M:repertory()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local classify = args["classify"]
	local _type = args["type"]
	local region = args["region"]
	local year = args["year"]
	local sort = args["sort"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	args["pageSize"] = 20
	if classify == nil or classify == "" then
		args["classify"] = '1'
	end
	if _type == nil or _type == "" then
		args["type"] = '-1'
	end
	if region == nil or region == "" then
		args["region"] = '-1'
	end
	if year == nil or year == "" then
		args["year"] = '-1'
	end
	if sort == nil or sort == "" then
		args["sort"] = '1'
	end

	local list = movie_service:list(args)
	local context = { list = list }
	
	-- 设置分页内容
	local count = movie_service:count(args)
	local page = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	context['page'] = page
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	-- ngx.log(ngx.ERR, "++++++++++++ " .. cjson.encode(page))

	-- 封装搜索条件
	context['args'] = args
	-- 获取类型列表
	context['typeList'] = movie_type_service:top10()
	-- 获取地区列表
	context['regionList'] = region_service:top10()

	template.render("list.html", context)
end

-- 电视剧列表页
function _M:drama()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local region = args["region"]
	local year = args["year"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	args["pageSize"] = 20
	args["classify"] = '2'
	args["sort"] = '1'
	if region == nil or region == "" then
		args["region"] = '-1'
	end
	if year == nil or year == "" then
		args["year"] = '-1'
	end

	local list = movie_service:list(args)
	local context = {list = list}
	
	-- 设置分页内容
	local count = movie_service:count(args)
	local page = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	context['page'] = page
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()

	-- 封装搜索条件
	context['args'] = args
	-- 获取地区列表
	context['regionList'] = region_service:top10()

	template.render("drama.html", context)
end

-- 排行榜页
function _M:ranking()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local year = args["year"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	args["pageSize"] = 20
	args["classify"] = '1'
	if year == nil or year == "" then
		args["year"] = '-1'
	end

	local list = movie_service:list(args)
	local context = { list = list }
	
	-- 设置分页内容
	local count = movie_service:count(args)
	local page = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	context['page'] = page
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	-- ngx.log(ngx.ERR, "++++++++++++ " .. cjson.encode(page))

	-- 封装搜索条件
	context['args'] = args

	template.render("ranking.html", context)
end

-- 影片详情页
function _M:detail()
	local args = req.getArgs()
	local movieId = args["movieId"]

	if movieId == nil or movieId == "" then
		ngx.say(cjson.encode(result:error("ID为空")))
		return
	end

	local entity = movie_service:detail(movieId)
	local context = {entity = entity}

	-- 增加访问数量
	local red = redis:new()
	local typeKey = '1'
	if entity['type'] == 2 then
		typeKey = '2'
	end
	local ok, err = red:zincrby('day:rank:'..typeKey, 1, movieId)
	red:expire('day:rank:'..typeKey, 1*24*3600)
	local ok, err = red:zincrby('week:rank:'..typeKey, 1, movieId)
	red:expire('week:rank:'..typeKey, 7*24*3600)
	local ok, err = red:zincrby('month:rank:'..typeKey, 1, movieId)
	red:expire('month:rank:'..typeKey, 31*24*3600)
	if not ok then
	    ngx.log(ngx.ERR, "failed to set ranking: ", err)
	end

	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	-- 增加下载链接
	context['urlList'] = download_url_service:list(movieId)
	-- 增加猜你喜欢
	context['likeList'] = movie_service:like(entity['type'])

	template.render("detail.html", context)
end


return _M