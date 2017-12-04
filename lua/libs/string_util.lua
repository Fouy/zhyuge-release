local _M = {}

_M._VERSION="0.1"

-- 字符串切割
function _M:strSplit(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t={}
    local i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       t[i] = str
       i = i + 1
    end
    return t
end

return _M