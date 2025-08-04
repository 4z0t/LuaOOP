--#region upvalues
local setmetatable = setmetatable
local type = type
local getmetatable = getmetatable
local pairs = pairs
local ipairs = ipairs
local next = next
local rawset = rawset

--#endregion

local weakKey = { __mode = "k" }

---@param t table
---@return boolean
local function TableEmpty(t)
    return next(t, nil) == nil
end

---@class PropertyPrototype
---@field get fun(self: Class): any
---@field set fun(self: Class, value: any): any

---@class ClassProperty : PropertyPrototype
local ClassPropertyMeta = { __property = true }
ClassPropertyMeta.__index = ClassPropertyMeta

---@param prototype PropertyPrototype
---@return ClassProperty
local function property(prototype)
    return setmetatable(prototype, ClassPropertyMeta) --[[@as ClassProperty]]
end

---@class Class
---@operator call(...):Class
---@field __name string
---@field __bases Class[]?
---@field __finalized boolean
---@field __subClasses table<Class, true>?
---@field init fun(self: Class, ...: any)?
---@field destroy fun(self: Class)?

local excludeLookup = {
    __name = true,
    __bases = true,
    __finalized = true,
    __index = true,
    __newindex = true,
}

---@param bases Class[]
---@param ambiguousBase Class
---@param key any
---@param value any
local function findAmbiguousBases(bases, ambiguousBase, key, value)
    for _, base in ipairs(bases) do
        if base ~= ambiguousBase then
            if base[key] == value then
                error(string.format("Ambiguous field '%s' among base classes %s and %s", key, base, ambiguousBase))
                return
            end
        end
    end
    error(string.format("Ambiguous field '%s' among base classes", key))
end

---@param cls Class
---@param bases Class[]
local function processBasesTable(cls, bases)
    local seen = {}
    for _, base in ipairs(bases) do
        for key, value in pairs(base) do
            if cls[key] == nil and not excludeLookup[key] then
                local seenValue = seen[key]
                if seenValue == nil then
                    seen[key] = value
                elseif seenValue ~= value then
                    findAmbiguousBases(bases, base, key, seenValue)
                end
            end
        end
    end

    for key, value in pairs(seen) do
        cls[key] = value
    end
end

local function populateProperties(cls)
    local get = {}
    local set = {}
    for key, value in pairs(cls) do
        if type(value) == "table" and value.__property then
            if value.get then
                get[key] = value.get
            end
            if value.set then
                set[key] = value.set
            end
        end
    end

    if TableEmpty(get) then
        cls.__index = cls
    else
        cls.__index = function(self, key)
            local getf = get[key]
            if getf then
                return getf(self, key)
            end
            return cls[key]
        end
    end
    if not TableEmpty(set) then
        cls.__newindex = function(self, key, value)
            local setf = set[key]
            if setf then
                setf(self, value, key)
                return
            end
            rawset(self, key, value)
        end
    end
end

---@param cls Class
---@param subclass Class
local function addSubClass(cls, subclass)
    local subClasses = cls.__subClasses
    if not subClasses then
        subClasses = setmetatable({}, weakKey)
        cls.__subClasses = subClasses
    end
    subClasses[subclass] = true
end

---@param cls Class
local function finalizeClass(cls)
    local bases = cls.__bases
    if bases then
        for _, base in ipairs(bases) do
            if not base.__finalized then
                finalizeClass(base)
                base.__finalized = true
            end
        end
        processBasesTable(cls, bases)
        for _, base in ipairs(bases) do
            addSubClass(base, cls)
        end
    end
    populateProperties(cls)
end

---@class ClassFactory
local ClassFactory = {
    ---@generic Args
    ---@param self Class
    ---@param ... Args
    __call = function(self, ...)
        if not self.__finalized then
            finalizeClass(self)
            self.__finalized = true
        end
        local instance = setmetatable({}, self)
        local constructor = self.init
        if constructor then
            constructor(instance, ...)
        end
        return instance
    end,

    ---@param self Class
    ---@return string
    __tostring = function(self)
        return string.format("<class %s>", self.__name)
    end,

}


---Creates class with given bases
---@generic T
---@generic C : Class
---@param name string
---@param ... T
---@return C
local function class(name, ...)
    ---@type Class[]|false
    local bases = { ... }
    if #bases == 0 then
        bases = false
    end

    return setmetatable(
        {
            __name = name,
            __finalized = false,
            __bases = bases,
            __subClasses = false,
        },
        ClassFactory)
end

---Returns whether object is an instance of the given class or its subclasses
---@param obj any
---@param cls Class|any
---@return boolean
local function isinstance(obj, cls)
    local objClass = getmetatable(obj)
    if not objClass then
        return false
    end
    if objClass == cls then
        return true
    end
    local subClasses = cls.__subClasses
    if not subClasses then
        return false
    end
    return subClasses[objClass]
end

return {
    class = class,
    property = property,
    isinstance = isinstance
}
