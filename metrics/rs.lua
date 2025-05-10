--- Bridge between Lua and Rust
--- We do some conversions here, for speed-ups
local M = {}
local checks = require('checks')
local rust = require('metrics_rs')

function M.set_labels(label_pairs)
    checks('table')
    label_pairs = table.copy(label_pairs)
    for k, v in pairs(label_pairs) do
        label_pairs[k] = tostring(v)
    end
    rust.set_labels(label_pairs)
end

function M.gather()
    return rust.gather()
end

function M.new_histogram_vec(opts, label_names)
    checks('table', '?table')
    return rust.new_histogram_vec(opts, label_names)
end

return M
