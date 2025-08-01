local OOP = require "src/LuaOOP"

local class = OOP.class
local property = OOP.property

---@class A
local A = class()

function A:init()
    print("A")
end

---@class B
local B = class()

function B:init()
    print("B")
end

local a = A()
local b = B()

---@class C : A, B
local C = class(A, B)

function C:init()
    A.init(self)
    B.init(self)
    print("C")
end

C.myProperty = property {
    get = function(self)
        return self._myProperty .. "!"
    end,
    set = function(self, value)
        self._myProperty = value
    end
}

local c = C()

c.myProperty = "Hello"
print(c.myProperty)
