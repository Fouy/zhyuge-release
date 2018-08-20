local cjson = require "cjson"
local req = require "dispatch.req"
local result = require "common.result"
local picture_service = require "service.picture_service"
local picture_type_service = require "service.picture_type_service"
local common_service = require "service.common_service"
local picture_url_service = require "service.picture_url_service"
local template = require("resty.template")
local configCache = ngx.shared.configCache;
local redis = require "libs.redis_iresty"

local hot_search_service = require "service.hot_search_service"

local _M = {}

_M._VERSION="0.1"

-- 图片库分页 (主页)
function _M:index()
	local args = req.getArgs()
	local _type = args["type"]
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]

	if _type == nil or _type == "" then
		args["type"] = '-1'
	end
	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 30
	end

	-- 增加热搜关键词
	local context = {}
	context["searchList"] = hot_search_service:list()
	-- 获取类型列表
	context['typeList'] = picture_type_service:top10()
	context['args'] = args
	-- 增加猜你喜欢
	context["likeList"] = picture_service:like(10)
	-- 数据分页
	context["list"] = picture_service:list(args)
	-- 设置分页内容
	local count = picture_service:count(args)
	context['page'] = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	
	-- ngx.log(ngx.ERR, "+++++++++++++: ", cjson.encode(page))

	template.render("girls/index.html", context)
end

-- 图片详情页
function _M:detail()
	local args = req.getArgs()
	local pageNo = args["pageNo"]
	local pageSize = args["pageSize"]
	local pictureId = args["pictureId"]

	if pageNo == nil or pageNo == "" then
		args["pageNo"] = 1
	end
	if pageSize == nil or pageSize == "" then
		args["pageSize"] = 10
	end

	if pictureId == nil or pictureId == "" then
		ngx.say(cjson.encode(result:error("ID为空")))
		return
	end

	local entity = picture_service:detail(pictureId)
	local context = {entity = entity}

	-- 增加下载链接
	context['list'] = picture_url_service:list(args)
	-- 设置分页内容
	local count = picture_url_service:count(args)
	local page = common_service:generatePage(args["pageNo"], args["pageSize"], tonumber(count))
	context['page'] = page
	-- 增加热搜关键词
	context["searchList"] = hot_search_service:list()
	context['args'] = args
	-- 增加猜你喜欢
	context["likeList"] = picture_service:like(10)
	-- 增加图片信息
	context["picture"] = picture_service:detail(pictureId)
	-- 获取类型列表
	context['typeList'] = picture_type_service:top10()

	-- ngx.log(ngx.ERR, "+++++++++++++: ", cjson.encode(count))

	template.render("girls/detail.html", context)
end

-- 点赞接口
function _M:favorite()
	local args = req.getArgs()
	local pictureId = args["pictureId"]

	if pictureId == nil or pictureId == "" then
		ngx.say(cjson.encode(result:error("ID为空")))
		return
	end

	picture_service:favorite(args)
	ngx.say(cjson.encode(result:success("点赞成功", '')))
end


return _M