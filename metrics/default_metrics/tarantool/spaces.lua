local utils = require('metrics.default_metrics.tarantool.utils')

local function update_spaces_metrics()
    if not utils.box_is_configured() then
        return
    end

    for _, s in box.space._space:pairs {} do
        local total = 0
        local space_name = s[3]
        local flags = s[6]

        if not flags.temporary and not space_name:match('^_') then
            local sp = box.space[space_name]

            local labels = { name = sp.name };

            for _, i in pairs(sp.index) do
                if type(_) == 'number' then
                    utils.set_gauge('space_index_' .. i.name .. '_bsize', 'Index ' .. i.name .. ' bsize', i:bsize(), labels)
                    total = total + i:bsize()
                end
            end

            if sp.engine == 'memtx' then
                local sp_bsize = sp:bsize()

                labels.engine = 'memtx'

                utils.set_gauge('space_len' , 'Space length', sp:len(), labels)

                utils.set_gauge('space_bsize', 'Space bsize', sp_bsize, labels)

                utils.set_gauge('space_index_bsize', 'Space index bsize', total, labels)

                utils.set_gauge('space_total_bsize', 'Space total bsize', sp_bsize + total, labels)

            else
                labels.engine = 'vinyl'

                if include_vinyl_count then
                    utils.set_gauge( 'space_count', 'Space count', sp:count(), labels)
                end

                utils.set_gauge('space_index_bsize', 'Space index bsize', total, labels)
            end
        end
    end
end

return {
    update = update_spaces_metrics,
}