--Test suite for the moretables library
--
-- Author:  J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Date:    2016
-- Version: 1.1.0
-- License: MIT (X11) License



local tables = require 'moretables'

local a, e -- actual, expected



---- settings for module -----------------------------------------------------

assert(tables:getTolerance() == 1e-12,
       'default tolerance')
assert(not pcall(tables.setTolerance, tables, '4'),
       'setTolerance requires number')
assert(not pcall(tables.setTolerance, tables, {}),
       'setTolerance requires number')

tables:setTolerance(1)
assert(tables:getTolerance() == 1)

tables:setTolerance()
assert(tables:getTolerance() == 1e-12,
       'setTolerance(nil) resets to default')



---- tables.len --------------------------------------------------------------

assert(tables.len({}) == 0,
       'empty table')
assert(tables.len({3, 2, 0.05, "blue", {}, nil, 8}) == 6, 
       'nil is ignored')
assert(tables.len({a=4, b={}, c="cerise"}) == 3,
       'counts non-numeric indices')
assert(tables.len({a={b={c={d=true, true, "true"}}}, f=false}) == 2,
       'does not count nested tables')

for _,v in ipairs{nil, 3, 'e', function () return nil end} do
    local result, msg = tables.len(v)
    assert(result == nil)
    assert(msg == "Table expected, received " .. type(v),
           'error condition when not a table')
end



---- tables.alike ------------------------------------------------------------

-- non-tables works like '=='

local ok, msg = tables.alike(-3, {})
assert(ok == false,
       'failure is a boolean-false value')
assert(msg == "Differing types: number ~= table",
       'number/table')

ok, msg = tables.alike({a=2, b=1}, "oranges")
assert(not ok)
assert(msg == "Differing types: table ~= string",
       'table/string')

ok, msg = tables.alike(nil, {2, "glue"})
assert(not ok)
assert(msg == "Differing types: nil ~= table",
       'nil/table')

assert(tables.alike(nil, nil),
       "nil is like nil")
assert(tables.alike('s', "s"),
       "like strings")
assert(tables.alike(4, 4),
       "like numbers")
assert(tables.alike(4, 4.01, 0.1),
       "delta param works here too")



-- comparing tables

assert(tables.alike({}, {}),
       'empty tables are alike')
assert(tables.alike({}, {}) == true,
       'confirm that this returns a boolean-true value')
assert(tables.alike({a=5, b=1.1}, {a=5, b=1.1}),
       'alike tables are alike')
assert(tables.alike({a="blue", b={{4, math.pi}, {{{k=1.2}}, nil}}},
                    {a="blue", b={{4, math.pi}, {{{k=1.2}}, nil}}}),
       'compares nested elements')
assert(tables.alike({1 + 6e-13}, {1}),
       'implicit tolerance for rounding errors') -- default 1e-12
assert(not tables.alike({0.0000000000096}, {1}),
       'difference is too large for default delta')
assert(tables.alike({a=0,            b=1.0000001}, 
                    {a=0.0000000034, b=1}, 
                    1e-4), 
       'third argument adjusts tolerance')
assert(tables.alike({{1.04}}, {{1}}, 0.05),
       'nested values "close enough"')


local mt = {__eq = function() return true end} 
local t1, t2 = {5}, {{{}}} -- definitely not equal
assert(not tables.alike(t1, t2),
       'assuredly different')
setmetatable(t1, mt)
setmetatable(t2, mt)
assert(not tables.alike(t1, t2),
       'does not use metatables by default')
assert(tables.alike(t1, t2, nil, true),
       'use the metatable which says they are equal')


local ok, msg = tables.alike(-3, {})
assert(ok == false,
       'failure is a boolean-false value')
assert(msg == "Differing types: number ~= table")

ok, msg = tables.alike({a=2, b=1}, "oranges")
assert(not ok)
assert(msg == "Differing types: table ~= string",
       'table/string')

ok, msg = tables.alike(nil, {2, "glue"})
assert(not ok)
assert(msg == "Differing types: nil ~= table",
       'nil/table')

ok, msg = tables.alike(3, 8)
assert(not ok)
assert(msg == "(8 - 3) > 1e-12",
       'beyond delta')



-- test error messages

ok, msg = tables.alike({a=1, b=2}, {a=1}, 1e-9)
assert(not ok)
assert(msg == "Tables of differing length: 2 ~= 1")

ok, msg = tables.alike({a=1, b={1,2}}, {a=1, b={1,2,3}})
assert(not ok)
assert(msg == "Tables of differing length at ['b']: 2 ~= 3",
       msg)

ok, msg = tables.alike({a=1, b=2}, {a="green", b=2}, 1e-9)
assert(not ok)
assert(msg == "Differing types at ['a']: number ~= string")

ok, msg = tables.alike({a=0, b=1}, {b=1, c=2})
assert(not ok)
assert(msg == "Differing types at ['a']: number ~= nil")

ok, msg = tables.alike({a=0}, {a=1})
assert(not ok)
assert(msg == "First differing element at ['a']: (1 - 0) > 1e-12")

ok, msg = tables.alike({4, {['1'] = {a="blue"}}}, {4, {['1'] = {a="green"}}})
assert(not ok)
assert(msg == "First differing element at [2]['1']['a']: 'blue' ~= 'green'")

ok, msg = tables.alike({a=0, b=1, c=1}, 
                           {a=0, b=1, c=0.9999999}, 
                           1e-12)
assert(not ok)
assert(msg == "First differing element at ['c']: (1 - 0.9999999) > 1e-12")

t1, t2 = {a=5}, {[3] = true}
local mt = {__eq = function(self) return self[1] ~= nil end}
setmetatable(t1, mt)
setmetatable(t2, mt)
_,msg = tables.alike(t1, t2, nil, true)
assert(msg == 'Tables unequal')

--metatable will cause nested t=t1 to fail
ok, msg = tables.alike({{4,{t=t1}, 3}}, {{4, {t=t2}, 3}}, nil, true)
assert (not ok)
assert(msg == "Tables unequal at: [1][2]['t']", msg)



---- tables.getOrderedKeys ---------------------------------------------------

local getOrd = tables.getOrderedKeys
local e = {{}, 
           {1, 6}, 
           {'Red', '_blue', 'apples'}, 
           {-4, 1, 'kumquat'}
          }
local a = {{}, 
           {[6]='orange', [1]=function() end},
           {['_blue'] = true, Red = false, ['apples'] = {}},
           {{}, [-4] = '', kumquat = 'pickelbarrel'}
          }
for i=1, 4 do
    assert(tables.alike(getOrd(a[i]), e[i]),
           'unexpected mismatch at ' .. tostring(i))
end


e = {'oranges', 'bananas'}
a = getOrd({bananas     = true, 
            blueberries = true,
            oranges     = true,
            tangerienes = true,
           },
           function(a,b) return a > b end, -- comparison
           function(s) return not s:find('i') end) -- filter
assert(tables.alike(a, e),
       'filter and comp at work')

assert(not pcall(getOrd, 5),
       'non-tables raises an error')
assert(not pcall(getOrd, nil),
       'nil values are not tables')



---- tables.tostring ---------------------------------------------------------

local str = tables.tostring

--non-tables return tostring of the thing
assert(str() == 'nil')
assert(str(5) == '5')
assert(str('s') == 's')
assert(str(str) == tostring(str),
       'something like "function: 0x12345678910"')

assert(str{} == '{}')

t1 = {{{ ['b'] = {['1'] = 1,
                  1, -- [1] = 1,
                  [5]   = 'k',
                  blue  = {},
                  green = true,
                 }
     }}}
assert(str(t1) == [=[{
  [1] = {
    [1] = {
      ['b'] = {
        [1] = 1
        [5] = 'k'
        ['1'] = 1
        ['blue'] = {}
        ['green'] = true
      }
    }
  }
}]=], str(t1))




print("==== TEST MORETABLES PASSED ====")
