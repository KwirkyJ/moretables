--Test suite for the moretables library
--
-- Author:  J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Date:    2016
-- Version: 1.1.0
-- License: MIT (X11) License



local tables = require 'moretables'



local a, e -- actual, expected
local ok, msg -- output stuff
local mt -- metatable
local t1, t2 -- comparison tables



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
assert(tables.len({a=4, b={}, c="cerise", [{}] = true}) == 4,
       'counts non-numeric indices')
assert(tables.len({a={b={c={d=true, true, "true"}}}, f=false}) == 2,
       'does not count nested tables')

for _,v in ipairs{nil, 3, 'e', function () return nil end} do
    local result, out = tables.len(v)
    assert(result == nil)
    assert(out == "Table expected, received " .. type(v),
           'error condition when not a table')
end



---- tables.alike ------------------------------------------------------------

-- non-tables works like '=='

ok, msg = tables.alike(-3, {})
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


mt = {__eq = function() return true end} 
t1, t2 = {5}, {{{}}} -- definitely not equal
assert(not tables.alike(t1, t2),
       'assuredly different')
setmetatable(t1, mt)
setmetatable(t2, mt)
assert(not tables.alike(t1, t2),
       'does not use metatables by default')
assert(tables.alike(t1, t2, nil, true),
       'use the metatable which says they are equal')


ok, msg = tables.alike(-3, {})
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


-- test tables as indices

t1 = {5}
ok, msg = tables.alike({[t1] = 'blue'}, {})
assert(not ok)
assert(msg == "Tables of differing length: 1 ~= 0")

assert (tables.alike ({[t1] = 'hay'}, {[t1] = 'hay'}))
assert (tables.alike ({hay = {[t1] = true}}, {hay = {[t1] = true}}))


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
mt = {__eq = function(self) return self[1] ~= nil end}
setmetatable(t1, mt)
setmetatable(t2, mt)
ok, msg = tables.alike(t1, t2, nil, true)
assert(not ok and msg == 'Tables unequal')

--metatable will cause nested t=t1 to fail
ok, msg = tables.alike({{4,{t=t1}, 3}}, {{4, {t=t2}, 3}}, nil, true)
assert (not ok)
assert(msg == "Tables unequal at: [1][2]['t']", msg)



t1 = {a=5}
ok, msg = tables.alike ({[t1] = true}, {[t1] = false})
assert (not ok)
assert(msg == string.format (
              "First differing element at [%s]: true ~= false", 
              tostring (t1)),
       msg)

ok, msg = tables.alike ({hay = {[t1] = true}}, {hay = {[t1] = 5}})
assert (not ok)
assert(msg == string.format (
              "Differing types at ['hay'][%s]: boolean ~= number", 
              tostring (t1)),
       msg)

-- mismatched elements are difficult to handle even with sensible keys
-- t1 and t2 are alike, but are different tables and accordingly have
--     different hashes
t2 = {a=5}
assert (tables.alike (t1, t2))
ok, msg = tables.alike ({[t1] = true}, {[t2] = true})
assert (not ok)
assert(msg == string.format (
              "Differing types at [%s]: boolean ~= nil", 
              tostring (t1)),
       msg)



---- tables.clone ------------------------------------------------------------

local f = function () return 4 end

e, a = {}, tables.clone ({})
assert (tables.alike (e, a), "empty clones are alike")
assert (not (a == e), "clones are distinct")

t1 = {5,'blue', false, f}
e, a = t1, tables.clone (t1)
assert (tables.alike (e, a), "array clones are alike")
assert (not (a == e), "clones are distinct from original")

t1 = {blue=7, f=true, [1]='orange'}
e, a = t1, tables.clone (t1)
assert (tables.alike (e, a), "table clones are alike")

t1 = {
      {
       {false}, 
       {['none'] = {5, 
        {[5]='intrepid'},
       },
      },
     }, 
     spam = {5}, 
     [123] = false,
    }
e, a = t1, tables.clone (t1)
assert (tables.alike (e, a), "nested clones are alike")
 
for _,v in ipairs {5, true, function () return false end, "string"} do
    ok, msg = pcall (tables.clone, v)
    assert (not ok, "type error")
    assert (msg, 
            "mildly-informative error messages are better than uninformative")
end

t1 = {oranges = 7, limes =  7}
t2 = {oranges = 7, limes = 17}
assert (not tables.alike (t1, t2))
assert (not tables.alike (t1, tables.clone (t2)))
assert (not tables.alike (tables.clone (t1), tables.clone (t2)))
assert (not tables.alike (t2, tables.clone (t1)),
        "mismatched tables will have clone(s) mismatch")

t1 = {oranges = 6, limes = {sale=true, cost=0.75}}
t2 = {oranges = 7, limes = {sale=false, cost=0.75}}
assert (not tables.alike (t1, t2))
assert (not tables.alike (t1, tables.clone (t2)))
assert (not tables.alike (tables.clone (t1), tables.clone (t2)))
assert (not tables.alike (t2, tables.clone (t1)),
        "mismatched nested tables will have clone(s) mismatch")

t1 = {oranges = 6}
t2 = {oranges = 7, limes = 6}
assert (not tables.alike (t1, t2))
assert (not tables.alike (t1, tables.clone (t2)))
assert (not tables.alike (tables.clone (t1), tables.clone (t2)))
assert (not tables.alike (t2, tables.clone (t1)),
        "tables with different/missing keys will have clone(s) mismatch")

t1 = {"spam", "eggs"}
t2 = tables.clone (t1)
assert (tables.alike (t2, t1))
t1[1] = "green eggs"
assert (not tables.alike (t1, t2), "changing original does not change clone")

local in_t = {'blue', 'orange'}
t1 = {[in_t] = 5}
t2 = tables.clone (t1)
assert (tables.alike (t2, t1))
in_t[3] = 'yellow'
assert (tables.alike (t1,t2))
assert (tables.alike (in_t, {'blue', 'orange', 'yellow'}))



---- tables.getOrderedKeys ---------------------------------------------------

local getOrd = tables.getOrderedKeys
e = {{}, 
     {1, 6}, 
     {'Red', '_blue', 'apples'}, 
     {-4, 1, 'kumquat'}
    }
a = {{}, 
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
           function (x,y) return x > y end, -- comparison
           function (s) return not s:find('i') end) -- filter
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


t1 = {5}
t2 = {martians = {[t1] = 'blue'}}
assert (tables.tostring (t2) == string.format ([=[{
  ['martians'] = {
    [%s] = 'blue'
  }
}]=], tostring(t1)))




print("==== TEST MORETABLES PASSED ====")
