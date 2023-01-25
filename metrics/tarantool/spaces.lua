local utils = require('metrics.utils')

local collectors_list = {}
local spaces = {}

local function update_spaces_metrics()
    if not utils.box_is_configured() then
        return
    end

    local include_vinyl_count = rawget(_G, 'include_vinyl_count') or false

    local new_spaces = {}
    for _, s in box.space._space:pairs() do
        local total = 0
        local space_name = s[3]
        local flags = s[6]

        if s[1] <= box.schema.SYSTEM_ID_MAX or flags.temporary or space_name:match('^_') then
            goto continue
        end

        local sp = box.space[space_name]
        if sp == nil or sp.index[0] == nil then
            goto continue
        end

        new_spaces[space_name] = {indexes = {}}

        local labels = { name = sp.name }

        for space_id, i in pairs(sp.index) do
            if type(space_id) == 'number' then
                local l = table.copy(labels)
                l.index_name = i.name
                collectors_list.space_index_bsize =
                    utils.set_gauge('space_index_bsize', 'Index bsize', i:bsize(), l,
                        nil, {default = true})
                total = total + i:bsize()

                if spaces[space_name] ~= nil then
                    spaces[space_name].indexes[space_id] = nil
                end
                new_spaces[space_name].indexes[space_id] = l
            end
        end

        if spaces[space_name] ~= nil then
            for _, index in pairs(spaces[space_name].indexes) do
                collectors_list.space_index_bsize:remove(index)
            end
        end

        if sp.engine == 'memtx' then
            local sp_bsize = sp:bsize()

            labels.engine = 'memtx'

            collectors_list.space_len =
                utils.set_gauge('space_len' , 'Space length', sp:len(), labels,
                    nil, {default = true})

            collectors_list.space_bsize =
                utils.set_gauge('space_bsize', 'Space bsize', sp_bsize, labels,
                    nil, {default = true})

            collectors_list.space_total_bsize =
                utils.set_gauge('space_total_bsize', 'Space total bsize', sp_bsize + total, labels,
                    nil, {default = true})
            new_spaces[space_name].memtx_labels = labels

            spaces[space_name] = nil
        else
            if include_vinyl_count then
                labels.engine = 'vinyl'
                local count = sp:count()
                collectors_list.vinyl_tuples =
                    utils.set_gauge('vinyl_tuples', 'Vinyl space tuples count', count, labels,
                        nil, {default = true})
                new_spaces[space_name].vinyl_labels = labels

                spaces[space_name] = nil
            end
        end

        ::continue::
    end

    for _, space in pairs(spaces) do
        for _, index in pairs(space.indexes) do
            collectors_list.space_index_bsize:remove(index)
        end
        if space.memtx_labels ~= nil then
            collectors_list.space_len:remove(space.memtx_labels)
            collectors_list.space_bsize:remove(space.memtx_labels)
            collectors_list.space_total_bsize:remove(space.memtx_labels)
        end
        if space.vinyl_labels ~= nil then
            collectors_list.vinyl_tuples:remove(space.vinyl_labels)
        end
    end
    spaces = new_spaces
end

return {
    update = update_spaces_metrics,
    list = collectors_list,
}
