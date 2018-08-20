local cjson = require "cjson"
local mysql = require("libs.mysql")

local _M = {}

_M._VERSION="0.1"

-- 生成分页内容
function _M:generatePage(pageNo, pageSize, count)
	if count <= pageSize then
		return nil
	end

	local page = {}
	page['current'] = pageNo
	-- 获取总页数
	local totalPage = 0
	if count % pageSize == 0 then
		totalPage = count / pageSize
	else
		totalPage = count / pageSize + 1
	end
	-- 获取页码列表
	local pageList = {}
	for i = 1, totalPage do
		if math.abs(pageNo - i) <= 4 then
			table.insert(pageList, i)
		end
	end
	page['pageList'] = pageList
	-- 获取上一页/下一页
	if pageNo - 1 >= 1 then
		page['prev'] = pageNo - 1
	end
	if pageNo + 1 <= totalPage then
		page['next'] = pageNo + 1
	end

	return page
end

return _M