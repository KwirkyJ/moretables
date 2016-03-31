# moretables

Lua library providing some 'missing' functions for tables.
Requires the lua_stringbuffer library.

## API Reference

#### ```moretables:getTolerance()```
Query the module for the acceptable tolerance (delta) between two numbers. Module default is 1e-12.

#### ```moretables:setTolerance([delta])```
Set the default tolerance when comparing numbers within tables. Must be a number. If ```delta``` is nil, it resets the module to the default of 1e-12.

#### ```moretables.len(t)```
Gets the number of elements in a given table, excluding metatable entries. Does not count nested tables. Equivalent to:
```lua
local count = 0
for _,_ in pairs(t) do
    count = count + 1
end
return count
```

#### ```moretables.alike(a, b[, delta][, use_metatable])```
Returns true if ```a``` and ```b``` are alike. If neither is a table, tries to compare with ```==```; if both are numbers, will return true if ```|(|a| - |b|)| <= delta``` (if ```delta``` is not provided, uses the module's set default); if both are tables, will return true if all elements and nested elements satisfy the above equalities; a type mismatch will result in immediate failure. ```use_metatable``` is a boolean flag to use the tables' ```__eq``` metamethod if it exists (defaults to false).

#### ```moretables.getOrderedKeys(t[,comp][, filter])```
Returns a list of keys to the table. By default, returns all element keys/indices sorted alphanumerically (0..20, a, zoo). ```comp``` can be a function that takes two elements(keys) and returns true if the first element is to come before the second (default is equivalent to ```function(a,b) return a < b end```). ```filter``` is a function that takes one argument (key) and returns true if that key is to be included. Raises an error if ```t``` is not a table.

#### ```moretables.tostring(a)```
For non-tables, returns ```tostring(a)```; if a is a table, returns a formatted string representing the table's contents (keys ordered with the default ```getOrderedKeys```)

