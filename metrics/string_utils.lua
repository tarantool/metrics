local log = require('log')

local function check_symbols(s)
    if string.find(s, '%c') ~= nil then
        log.error('Do not use control characters, this will raise an error in the future.')
    end
end

local function build_name(prefix, suffix)
    if #suffix == 0 then
        return prefix
    end

    return prefix .. '_' .. suffix
end

return {
    check_symbols = check_symbols,
    build_name = build_name,
}
