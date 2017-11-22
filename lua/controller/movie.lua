local cjson = require "cjson"
local req = require "dispatch.req"
local result = require "common.result"
local movie_service = require "service.movie_service"
local movie_type_service = require "service.movie_type_service"
local common_service = require "service.common_service"
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

	ngx.log(ngx.ERR, "FUCK YOU MAN: ")
	local list = movie_service:list(args)
	-- local typeList = movie_type_service:listTop6()
	local context = { list = list }
	
	-- 增加热门文章数据
	-- context["hotList"] = common_service:hotList()
	template.render("index.html", context)

end

-- 分类页
function _M:category()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]
	local typeId = args["typeId"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 10
	end
	if typeId == nil or typeId == "" then
		ngx.say(cjson.encode(result:error("分类ID为空")))
		return
	end

	local list = movie_service:list(args)
	local typeEntity = movie_type_service:detail(typeId)
	local context = {list = list, pageNo = tonumber(args["pageNo"])+1, typeEntity = typeEntity }
	
	-- 增加热门文章数据
	context["hotList"] = common_service:hotList()
	template.render("blog/category.html", context)

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

	-- 增加热门文章数据
	-- context["hotList"] = common_service:hotList()
	-- 增加推荐文章数据
	-- context["relaList"] = common_service:relaList(entity["type_id"])
	template.render("detail.html", context)

end


return _M