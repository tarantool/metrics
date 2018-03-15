checkers = checkers or {}

local function matches(checked_value, expected_types, is_of_type)
    if not is_of_type then
        is_of_type = function (checked_value, expected_type)
            return type(checked_value) == expected_type
        end
    end
    assert(type(is_of_type) == 'function')

    local start = 1
    while true do
        local ending = string.find(expected_types, '|', start)
        if ending == nil then
            -- last exp. type
            return is_of_type(checked_value, expected_types:sub(start, -1))
        end

        local expected_type = expected_types:sub(start, ending - 1)
        if is_of_type(checked_value, expected_type) then
            return true
        end
        start = ending + 1  -- after | symbol is start of new exp. type
    end
    return false
end

local function is_leaf(node)
    local num_keys = 0
    local has_default = false
    local has_type = false

    for k, v in pairs(node) do
        if k == 'default' then has_default = true end
        if k == 'type' then has_type = true end
        num_keys = num_keys + 1
    end

    if has_default and num_keys == 1 then
        node.type = type(node.default)
        has_type = true
        num_keys = 2
    end
    return (num_keys == 2 and has_default and has_type) or (num_keys == 1 and has_type)
end



local function check_string_argument(checked_value, expected_types)
    -- 1. Check for nil if type is optional.
    local is_optional = expected_types:sub(1, 1) == '?'
    if is_optional then
        if checked_value == nil then
            return true
        end
        expected_types = expected_types:sub(2, -1)
    end

    -- 2. Check real type.
    if matches(checked_value, expected_types) then
        return true
    end

    -- 3. Check for type name in metatable.
    local mt = getmetatable(checked_value)
    if mt and type(mt.__type) == 'string' then
        -- pass type as first parameter (instead of value)
        local function are_equal(checked_value, expected_type)
            return checked_value == expected_type
        end
        if matches(mt.__type, expected_types, are_equal) then
            return true
        end
    end

    -- 4. Check for a custom typechecking function.
    local function is_of_func_type(checked_value, expected_type)
        local func = checkers[expected_type]
        if type(func) ~= 'function' then return false end
        return func(checked_value)
    end
    if matches(checked_value, expected_types, is_of_func_type) then
        return true
    end

    return false
end


local function validate_option(opt, helpname, check_params)
    local fmt = 'validate_option: bad validate_option usage %s: %s expected, got %s'
    do
        if type(check_params) ~= 'table' then
            error(string.format(fmt, 'check_params', 'table', type(check_params)))
        end
        if type(helpname) ~= 'string' then
            error(string.format(fmt, 'helpname', 'string', type(helpname)))
        end
    end

    if is_leaf(check_params) then
        local fmt = 'validate_option: bad format %s: %s expected, got %s'
        opt = opt or check_params.default
        if not check_string_argument(opt, check_params.type) then
            error(string.format(fmt, helpname, check_params.type, type(opt)))
        end
        return opt
    end

    opt = opt or {}
    if type(opt) ~= 'table' then
        local fmt = 'validate_option: %s must be table'
        error(string.format(fmt, helpname))
    end

    for k, v in pairs(opt) do
        local new_helpname = helpname .. '.' .. k
        if check_params[k] == nil then
            local fmt = 'validate_option: unexpected field %s'
            error(string.format(fmt, new_helpname))
        end
    end
    for k, v in pairs(check_params) do
        local new_helpname = helpname .. '.' .. k
        opt[k] = validate_option(opt[k], new_helpname, v)
    end
    return opt
end


local function checks_error(level, i, err)
    local info = debug.getinfo(level + 1, 'nSl')
    local where_fmt = '%s:%d bad argument #%d to %s: '
    return string.format(where_fmt, info.short_src, info.currentline, i, info.name) .. err
end


function checks(...)
    local level = 2

    local args = {...}
    if type(args[1]) == 'number' then
        level = 1 + args[1]
        args:remove(1)
    end

    for i = 1, #args do
        local expected_types = args[i]
        if not expected_types then break end
        local checked_name, checked_value = debug.getlocal(level, i)

        if type(expected_types) == 'string' then
            local ok = check_string_argument(checked_value, expected_types)
            if not ok then
                local err = string.format('%s expected, got %s',
                    expected_types, type(checked_value))
                error(checks_error(level, i, err))
            end
        elseif type(expected_types) == 'table' then
            local ok, retval = xpcall(
                validate_option,
                function (err)
                    return checks_error(level + 3, i, err)
                end,
                checked_value,
                checked_name,
                expected_types
            )
            if not ok then error(retval) end

            debug.setlocal(level, i, retval)
        else
            local fmt = 'checks: argument type %s is not supported'
            error(string.format(fmt, type(expected_types)))
        end
    end
end
