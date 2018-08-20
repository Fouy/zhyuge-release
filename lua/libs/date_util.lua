local _M = {}

_M._VERSION="0.1"

-- 将日期时间 yyyy-MM-dd hh:mm:ss 转化为 秒数
function _M:getTimeByDate(date)
    local a = self:split(date, " ")
    local b = self:split(a[1], "-")
    local c = self:split(a[2], ":")
    local t = os.time({year=b[1], month=b[2], day=b[3], hour=c[1], min=c[2], sec=c[3]}) 
    return t
end

function _M:split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

-- 将秒数转换成字符串格式
function _M:formatDate(seconds, dateformat)
    return os.date(dateformat,tonumber(seconds))
end

return _M