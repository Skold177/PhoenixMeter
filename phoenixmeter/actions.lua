require('common');

local actions = T{};

local function read(state, count)
    local value = 0;
    local scale = 1;
    local pos   = state.pos;
    while (count > 0) do
        local byte   = state.data:byte(math.floor(pos / 8) + 1) or 0;
        local offset = pos % 8;
        local take   = math.min(8 - offset, count);
        value = value + (math.floor(byte / 2 ^ offset) % 2 ^ take) * scale;
        scale = scale * 2 ^ take;
        count = count - take;
        pos   = pos + take;
    end
    state.pos = pos;
    return value;
end

local function u16(data, offset)
    local low, high = data:byte(offset + 1, offset + 2);
    return (low or 0) + (high or 0) * 256;
end

local function u32(data, offset)
    return u16(data, offset) + u16(data, offset + 2) * 65536;
end

function actions.decode(data)
    local state = { data = data, pos = 40 };
    local act   = T{ targets = T{} };

    act.actor = read(state, 32);
    local count = read(state, 6);
    read(state, 4);
    act.category = read(state, 4);
    act.param    = read(state, 32);
    act.recast   = read(state, 32);

    for _ = 1, count do
        local target = T{ results = T{} };
        target.id = read(state, 32);
        local results = read(state, 4);
        for _ = 1, results do
            local result = T{};
            result.resolution = read(state, 3);
            result.kind       = read(state, 2);
            result.animation  = read(state, 12);
            result.info       = read(state, 5);
            read(state, 5);
            result.value    = read(state, 17);
            result.message  = read(state, 10);
            result.modifier = read(state, 31);
            if (read(state, 1) == 1) then
                result.proc_kind    = read(state, 6);
                result.proc_info    = read(state, 4);
                result.proc_value   = read(state, 17);
                result.proc_message = read(state, 10);
            end
            if (read(state, 1) == 1) then
                result.react_kind    = read(state, 6);
                result.react_info    = read(state, 4);
                result.react_value   = read(state, 14);
                result.react_message = read(state, 10);
            end
            target.results:append(result);
        end
        act.targets:append(target);
    end

    return act;
end

function actions.group_effects(data)
    local members = T{};
    for slot = 0, 4 do
        local base = 0x04 + slot * 0x30;
        local id   = u32(data, base);
        if (id ~= 0) then
            local low_bits  = u32(data, base + 0x08);
            local high_bits = u32(data, base + 0x0C);
            local effects   = T{};
            for index = 0, 31 do
                local bits = index < 16 and low_bits or high_bits;
                local high = math.floor(bits / 4 ^ (index % 16)) % 4;
                local effect = (data:byte(base + 0x10 + index + 1) or 255) + high * 256;
                if (effect == 255) then
                    break;
                end
                effects:append(effect);
            end
            members:append(T{ id = id, effects = effects });
        end
    end
    return members;
end

function actions.message(data)
    return T{
        actor   = u32(data, 0x04),
        target  = u32(data, 0x08),
        param   = u32(data, 0x0C),
        message = u16(data, 0x18) % 0x8000,
    };
end

function actions.points(data)
    return T{
        amount  = u32(data, 0x10),
        message = u16(data, 0x18) % 0x8000,
    };
end

return actions;
