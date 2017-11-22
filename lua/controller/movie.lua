local cjson = require "cjson"
local req = require "dispatch.req"
local result = require "common.result"
local movie_service = require "service.movie_service"
local movie_type_service = require "service.movie_type_service"
local common_service = require "service.common_service"
local hot_search_service = require "service.hot_search_service"
local template = require("resty.template")
local configCache = ngx.shared.configCache;

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

	local list = movie_service:list(args)
	ngx.say(cjson.encode(result:success("查询成功", list)))
end

-- 搜索页
function _M:search()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]
	local keyword = args["keyword"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 10
	end
	if keyword == nil or keyword == "" then
		args["keyword"] = ""
	end

	local list = movie_service:list(args)
	local context = {list = list, pageNo = tonumber(args["pageNo"])+1, keyword = args["keyword"] }
	
	-- 增加热门文章数据
	context["hotList"] = common_service:hotList()
	template.render("blog/search.html", context)

end


-- 获取单个文章
function _M:detail()
	local args = req.getArgs()
	local movieId = args["movieId"]

	if movieId == nil or movieId == "" then
		ngx.say(cjson.encode(result:error("ID为空")))
		return
	end

	local entity = movie_service:detail(movieId)
	local context = {entity = entity}

	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()

	template.render("detail.html", context)
end


return _M