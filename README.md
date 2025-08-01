# LuaOOP

Very simple and versatile OOP library for Lua.

## Examples

### Basic usage

```lua
local OOP = require 'LuaOOP'

local class = OOP.class

---@class Person
local Person = class("Person")

---@param name string
---@param age number
function Person:init(name, age)
    self.name = name
    self.age = age
end

local person = Person('John Doe', 30)
print(person.name) -- John Doe
print(person.age) -- 30

```

### Inheritance

```lua
local OOP = require 'LuaOOP'

local class = OOP.class

---@class Person
local Person = class("Person")

---@param name string
---@param age number
function Person:init(name, age)
    self.name = name
    self.age = age
end

---@return boolean
function Person:isAdult()
    return self.age >= 18
end

---@class Student : Person
local Student = class("Student", Person)

---@param name string
---@param age number
---@param grade number
function Student:init(name, age, grade)
    Person.init(self, name, age)
    self.grade = grade
end

local student = Student('John Doe', 30, 10)
print(student.name) -- John Doe
print(student.age) -- 30
print(student.grade) -- 10
print(student:isAdult()) -- true
```

### Multiple inheritance

```lua
local OOP = require 'LuaOOP'

local class = OOP.class

---@class A
local A = class("A")
function A:aFunction()
    print("A function")
end


---@class B
local B = class("B")
function B:bFunction()
    print("B function")
end

---@class C : A, B
local C = class("C", A, B)


local c = C()
c:aFunction() -- A function
c:bFunction() -- B function

```

### Properties

```lua
local OOP = require 'LuaOOP'

local class = OOP.class
local property = OOP.property

---@class A
local A = class("A")

function A:init()
    self._x = 0
end

A.x = property {
    get = function(self)
        return self._x
    end,
    set = function(self, value)
        assert(type(value) == "number", "x must be a number")
        self._x = value
    end
}

local a = A()
a.x = 10
print(a.x) -- 10
a.x = "hello" -- error: x must be a number

```

## Notes and limitations

### New fields

You can add new fields into an existing class, but it's derived classes won't have them if they were added after derived classes were created.

```lua
local OOP = require 'LuaOOP'

local class = OOP.class

---@class A
local A = class("A")
function A:aFunction()
    print("A function")
end

---@class B : A
local B = class("B", A)

local b = B()
b:aFunction() -- A function

function A:a2Function()
    print("A2 function")
end

b:a2Function() -- attempt to call a nil value (method 'a2Function')

```

### Multiple inheritance

If base classes have fields with same names and they were not altered within derived class, then there will be an error:

```lua
local OOP = require 'LuaOOP'

local class = OOP.class

---@class A
local A = class("A")
function A:f()
    print("A function")
end


---@class B
local B = class("B")
function B:f()
    print("B function")
end

---@class C : A, B
local C = class("C", A, B)

local c = C() -- error: Ambiguous field 'f' among base classes <class A> and <class B>
```

To fix this we need to add our own implementation of `f` in derived class.

```lua
...
---@class C : A, B
local C = class("C", A, B)

function C:f()
    A.f(self)
    B.f(self)
    print("C function")
end
local c = C() -- now it won't throw an error
```
