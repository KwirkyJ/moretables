-- Utility library to support useful operations on tables not present in the 
-- standard library.
-- 
-- Author:  J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Date:    2016
-- Version: 1.1.0
-- License: MIT (X11) License



local Buffer = require 'lua_stringbuffer'



local DEFAULT_DELTA = 1e-12

local t = {_VERSION = "1.1.0",
           _delta   = DEFAULT_DELTA,
          }



---moretables:getTolerance()
-- Get the delta/tolerance used in tables.alike when none is supplied.
-- @return number.
local getTolerance = function(self)
    return self._delta
end
t.getTolerance = getTolerance

---moretables:setTolerance(delta)
-- Set the delta/tolerance used in tables.alike when none is supplied.
-- @param delta {Number} (default: DEFAULT_DELTA).
-- @error iff delta is neither number nor nil.
local setTolerance = function(self, delta)
    delta = delta or DEFAULT_DELTA
    assert(type(delta) == 'number', 'delta argument must be a number')
    self._delta = delta
end
t.setTolerance = setTolerance



---moretables.len(t)
-- Get the number of elements in a table (shallow count).
-- @param t The table.
-- @return nil and failure message iff not a table;
--         else the count of elements in the table.
len = function(t)
 if type(t) ~= 'table' then 
        return nil, "Table expected, received "..type(t)
    end
    local count = 0
    for _,_ in pairs(t) do
        count = count + 1
    end
    return count
end
t.len = len

---moretables.alike(t1, t2[, maxdelta] [, use_mt] [, loc])
-- Check whether two tables are equivalent;
-- Will accept non-tables; (searches nested tables).
-- @param t1
-- @param t2
-- @param maxdelta Maximum difference between values, useful with
--                 rounding errors (default DEFAULT_DELTA).
-- @param use_mt   Boolean flag to use metatables (default false).
-- @param loc      Internal string to place mismatched elements.
-- @return True iff tables share same keys and respective values differ by 
--         less than maxdelta; else false and failure message.tab1
alike = function(t1, t2, maxdelta, use_mt, loc)
    -- the code would be much more elegant if it was not as concerned with
    -- providing error messages.
    maxdelta = maxdelta or t._delta
    local preface = ''
    if type(t1) ~= type(t2) then 
        preface = 'Differing types'
        if loc then preface = 'Differing types at ' .. loc end
        return false,string.format('%s: %s ~= %s', preface, type(t1), type(t2))
    elseif type(t1) == 'number' then
        if (math.max(t1,t2) - math.min(t1,t2) > maxdelta) then
            if loc then
                preface = 'First differing element at ' .. loc .. ': '
            end
            return false, string.format('%s(%s - %s) > %s',
                          preface,
                          tostring(math.max(t1,t2)),
                          tostring(math.min(t1,t2)),
                          maxdelta)
        end
    elseif type(t1) == 'table' then
        if use_mt and (getmetatable(t1) or getmetatable(t2) )then
            preface = 'Tables unequal'
            if t1 == t2 then return true end
            if loc then preface = 'Tables unequal at: ' .. loc end
            return false, preface
        end
        local len1, len2 = len(t1), len(t2)
        if len1 ~= len2 then
            preface = 'Tables of differing length'
            if loc then
                preface = 'Tables of differing length at ' .. loc
            end
            return false, string.format('%s: %s ~= %s', preface, len1, len2)
        end
        
        loc = loc or ""
        local key
        for k, v1 in pairs(t1) do
            if type(k) == 'string' then 
                key = string.format("%s['%s']", loc, k)
            else
                key = string.format("%s[%d]", loc, k)
            end
            local ok, err = alike(v1, t2[k], maxdelta, use_mt, key)
            if not ok then return ok, err end
        end
    else -- same-type, neither tables nor numbers
        if type(t1) == 'string' then t1 = "'"..t1.."'"end
        if type(t2) == 'string' then t2 = "'"..t2.."'"end
        if loc then preface = 'First differing element at '..loc..': ' end
        if t1 ~= t2 then
            return false, string.format('%s%s ~= %s', 
                                        preface, tostring(t1), tostring(t2))
        end
    end
    return true
end
t.alike = alike



---Inner function for sorting a list by keys;
-- assumption: only numbers and strings can be keys (values in orderedI);
-- if same type, uses '<'
-- else, numbers come first.
local function _comp(a,b)
    if type(a) == type(b) then
        return a < b
    elseif type(a) == 'number' then
        return true
    else 
        return false
    end
end

---moretables.getOrderedKeys(t[, comp][, filter])
-- Get a list of keys in the table in the order specified by the comp function
-- (default: alphabetic with sorted numeric keys first).
-- @param t      {Table} Element from which to get keys.
-- @param comp   {Function} Specifies key order;
--               must accept two elements and return true if the first element
--               is to come before the latter (Optional).
-- @param filter {Function} Provides rules for which keys are to be retained;
--               must accept one argument (string or number)
--               must return true if the given key is to be added to the list
--               (Optional).
-- @error Raised iff <t> is not a function 
--               or comp is neither function nor nil.
-- @return {Table} List of keys in specified order.
local getOrderedKeys = function(t, comp, filter)
    comp = comp or _comp
    filter = filter or function(_) return true end

    assert(type(t) == 'table', "t must be a table; was ".. type(t))
    assert(type(filter) == 'function', 'filter must be a function')
    assert(type(comp) == 'function', 'comp must be a function')

    local list, count = {}, 0

    for k,_ in pairs(t) do
        if filter(k) then
            count = count + 1
            list[count] = k
        end
    end
    table.sort(list, comp)
    return list
end
t.getOrderedKeys = getOrderedKeys



---moretables.tostring(t[, indent])
-- Convert the provided entity to a pretty string.
-- @param t      Should be a table, but accepts anything.
-- @param indent Number for the number of spaces to indent (default 0).
-- @return Iff type(t) ~= 'table' then tostring(t);
--         else, pretty-prints the table and any nested contents.
toStr = function(t, indent)
    if type(t) ~= 'table' then return tostring(t) end
    
    local sb, indices, key
    sb = Buffer.new('\n') -- set buffer to add newlines after each addition
    indices= getOrderedKeys(t)

    if #indices == 0 then return '{}' end -- empty table
    
    indent = indent or 0
    local ins, value = string.rep(' ', indent+2), nil
    sb:add('{')
    for i=1, #indices do
        key = indices[i]
        value = t[key]
        if type(t[key]) == 'string' then
            value = "'"..value.."'"
        else
            value = toStr(value, indent + 2)
        end
        if type(key) == 'string' then
            key = "'" .. key .. "'"
        else
            key = tostring(key)
        end
        sb:add(string.format('%s[%s] = %s', ins, key, value))
    end
    sb:setSuffix() -- stop auto-adding newlines
    sb:add(string.rep(' ', indent) .. '}')
    return sb:getString()
end
t.tostring = toStr



return t

