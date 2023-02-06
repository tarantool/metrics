local log = require('log')

local function check_symbols(s)
    if string.find(s, '%c') ~= nil then
        log.error('Do not use control characters, this will raise an error in the future.')
    end
end

return {
    check_symbols = check_symbols,
}
