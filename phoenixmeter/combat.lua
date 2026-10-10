require('common');

local dots = require('dots');

local combat = T{};

local ACTIVE_GAP   = 10;
local ACTIVE_FLOOR = 3;
local SETTLE       = 2;
local LINGER       = 30;
local RECENT_SIZE  = 12;
local RECENT_SPAN  = 30;
local DEATH_KEEP   = 10;
local SWING_LIMIT  = 8;
local REFRESH_MISS = 0.25;
local REFRESH_IDLE = 1.0;
local FIRST_MOB_ID = 0x01000000;
local EFFECT_STEP  = 0.25;
local EFFECT_GAP   = 1.0;
local SAMURAI      = 12;
local CHAIN_WINDOW = 10;
local EXP_WINDOW   = 600;
local EXP_FLOOR    = 60;
local WEAR_OFF     = 206;
local MERIT_COST   = 10000;

local HIT = T{
    [1]   = true, [2]   = true, [67]  = true, [77]  = true, [110] = true, [157] = true, [185] = true,
    [187] = true, [197] = true, [227] = true, [252] = true, [264] = true, [265] = true, [274] = true,
    [317] = true, [352] = true, [353] = true, [379] = true, [522] = true, [576] = true, [577] = true,
    [648] = true, [650] = true, [747] = true, [748] = true, [749] = true, [802] = true, [803] = true,
};

local CRIT = T{ [67] = true, [353] = true };

local BURST = T{ [252] = true, [265] = true, [274] = true, [379] = true, [650] = true, [747] = true, [748] = true, [749] = true, [803] = true };

local HEAL = T{ [7] = true, [24] = true, [102] = true, [103] = true, [238] = true, [263] = true, [306] = true, [318] = true, [367] = true, [651] = true };

local MISS = T{
    [15]  = 'evade', [32]  = 'evade', [63]  = 'evade', [158] = 'evade', [188] = 'evade', [282] = 'evade', [324] = 'evade', [354] = 'evade',
    [30]  = 'anticipate',
    [31]  = 'shadow',
    [70]  = 'parry',
    [106] = 'intimidate',
};

local RESOLUTION = T{ [1] = 'evade', [3] = 'parry' };

local RESIST = T{ [85] = true, [284] = true, [653] = true, [654] = true, [655] = true, [656] = true };

local ENFEEBLE = T{ [82] = true, [236] = true, [237] = true, [268] = true, [271] = true, [277] = true, [278] = true };

local ADDED = T{ [163] = true, [229] = true };

local SPIKES = T{ [44] = true, [132] = true };

local DEFEAT = T{ [6] = true, [20] = true, [97] = true };

local EXP_GAIN = T{ [8] = 'level', [253] = 'level', [371] = 'merit', [372] = 'merit' };

local DEBUFF = T{
    [1]   = true, [2]   = true, [3]   = true, [4]   = true, [5]   = true, [6]   = true, [7]   = true, [8]   = true,
    [9]   = true, [10]  = true, [11]  = true, [12]  = true, [13]  = true, [14]  = true, [15]  = true, [16]  = true,
    [17]  = true, [18]  = true, [19]  = true, [20]  = true, [21]  = true, [23]  = true, [28]  = true, [29]  = true,
    [30]  = true, [31]  = true, [128] = true, [129] = true, [130] = true, [131] = true, [132] = true, [133] = true,
    [134] = true, [135] = true, [136] = true, [137] = true, [138] = true, [139] = true, [140] = true, [141] = true,
    [142] = true, [144] = true, [145] = true, [146] = true, [147] = true, [148] = true, [149] = true, [156] = true,
    [167] = true, [168] = true, [174] = true, [175] = true, [177] = true, [186] = true, [189] = true, [192] = true,
    [193] = true, [194] = true, [217] = true, [223] = true, [259] = true, [260] = true, [261] = true, [262] = true,
    [263] = true, [264] = true, [291] = true, [298] = true, [309] = true, [404] = true, [572] = true, [802] = true,
};

local SKILLCHAINS = T{
    [288] = 'Light',         [289] = 'Darkness',     [290] = 'Gravitation',   [291] = 'Fragmentation',
    [292] = 'Distortion',    [293] = 'Fusion',       [294] = 'Compression',   [295] = 'Liquefaction',
    [296] = 'Induration',    [297] = 'Reverberation', [298] = 'Transfixion',  [299] = 'Scission',
    [300] = 'Detonation',    [301] = 'Impaction',    [302] = 'Cosmic Elucidation',
    [732] = 'Universal Enlightenment', [767] = 'Radiance', [768] = 'Umbra',
};

local KIND = T{ [1] = 'melee', [2] = 'ranged', [3] = 'ws', [4] = 'spell', [5] = 'ja', [6] = 'ja', [11] = 'ws', [13] = 'ja', [14] = 'ja', [15] = 'ja' };

local CHAIN_STEP = T{ [3] = true, [11] = true, [13] = true };

local ABILITY_MESSAGE = T{
    [100] = true, [102] = true, [108] = true, [110] = true, [115] = true, [116] = true, [117] = true, [118] = true,
    [119] = true, [120] = true, [121] = true, [122] = true, [123] = true, [125] = true, [126] = true, [127] = true,
    [129] = true, [131] = true, [133] = true, [134] = true, [136] = true, [137] = true, [138] = true, [139] = true,
    [140] = true, [141] = true, [143] = true, [144] = true, [146] = true, [148] = true, [150] = true, [153] = true,
    [156] = true, [158] = true, [306] = true, [317] = true, [318] = true, [319] = true, [320] = true, [321] = true,
    [322] = true, [323] = true, [324] = true, [326] = true, [364] = true, [379] = true, [414] = true, [417] = true,
    [420] = true, [421] = true, [422] = true, [424] = true, [425] = true, [426] = true, [427] = true, [435] = true,
    [437] = true, [439] = true, [441] = true, [443] = true, [444] = true, [451] = true, [452] = true, [453] = true,
    [519] = true, [520] = true, [521] = true, [522] = true, [525] = true, [526] = true, [527] = true, [528] = true,
    [529] = true, [532] = true, [560] = true, [585] = true, [591] = true, [593] = true, [594] = true, [595] = true,
    [596] = true, [597] = true, [598] = true, [599] = true, [602] = true, [608] = true, [644] = true, [645] = true,
    [646] = true, [647] = true, [657] = true, [658] = true, [663] = true, [664] = true, [667] = true, [668] = true,
    [670] = true, [671] = true, [672] = true, [674] = true, [730] = true, [734] = true, [736] = true, [737] = true,
    [738] = true, [743] = true, [746] = true, [798] = true, [799] = true, [802] = true, [803] = true, [804] = true,
};

local COUNTER_REF     = T{ key = 'counter',     name = 'Counter',           kind = 'reactive' };
local RETALIATION_REF = T{ key = 'retaliation', name = 'Retaliation',       kind = 'reactive' };
local SPIKES_REF      = T{ key = 'spikes',      name = 'Spikes',            kind = 'reactive' };
local ADDED_REF       = T{ key = 'add',         name = 'Additional Effect', kind = 'add'      };

local state = T{
    roster    = T{},
    pets      = T{},
    known     = T{},
    names     = T{},
    effects   = T{},
    effect_names = T{},
    last_sample  = -math.huge,
    recent    = T{},
    engaged   = T{},
    resonance = T{},
    chain_mode = 'closer',
    refreshed = -math.huge,
    zone      = nil,
    serial    = 0,
    version   = 0,
    limit     = 20,
    current   = nil,
    overall   = nil,
    empty     = nil,
    history   = T{},
    exp       = nil,
    dots      = T{},
};

local function memory()
    return AshitaCore:GetMemoryManager();
end

local function clean(text)
    if (type(text) ~= 'string') then
        return nil;
    end
    text = text:gsub('%z.*', '');
    if (text == '') then
        return nil;
    end
    return text;
end

local function new_segment(now, overall)
    return T{
        overall = overall,
        started = now,
        last    = now,
        ended   = nil,
        time    = 0,
        fights  = 0,
        actors  = T{},
        foes    = T{},
        damage  = 0,
        healing = 0,
        taken   = 0,
        deaths  = 0,
        kills   = 0,
        chained = 0,
    };
end

local function new_ledger()
    return T{ damage = 0, abilities = T{}, targets = T{}, timeline = T{} };
end

local function new_stat()
    return T{ count = 0, total = 0, min = 0, max = 0 };
end

local function add_stat(stat, amount)
    if (stat.count == 0 or amount < stat.min) then
        stat.min = amount;
    end
    if (amount > stat.max) then
        stat.max = amount;
    end
    stat.count = stat.count + 1;
    stat.total = stat.total + amount;
end

local function new_actor(who)
    return T{
        key        = who.key,
        name       = who.name,
        owner      = who.owner,
        job        = who.job,
        sub        = who.sub,
        level      = who.level,
        sublevel   = who.sublevel,
        kind       = who.kind,
        damage     = 0,
        healing    = 0,
        taken      = 0,
        deaths     = 0,
        kills      = 0,
        active     = 0,
        abilities  = T{},
        heals      = T{},
        healed     = T{},
        targets    = T{},
        sources    = T{},
        enfeebles  = T{},
        effects    = T{},
        defense    = T{ hit = 0, crit = 0, evade = 0, parry = 0, block = 0, guard = 0, shadow = 0, anticipate = 0, intimidate = 0, counter = 0, resist = 0 },
        rounds     = T{
            count         = 0,
            measured      = 0,
            h2h           = 0,
            dual          = 0,
            kick_rounds   = 0,
            daken_rounds  = 0,
            main          = T{},
            off           = T{},
            fists         = T{},
            clean         = 0,
            clean_double  = 0,
            missed        = 0,
            missed_double = 0,
        },
        hands      = T{
            main  = T{ swings = 0, hits = 0, crits = 0, total = 0, max = 0 },
            off   = T{ swings = 0, hits = 0, crits = 0, total = 0, max = 0 },
            kick  = T{ swings = 0, hits = 0, crits = 0, total = 0, max = 0 },
            daken = T{ swings = 0, hits = 0, crits = 0, total = 0, max = 0 },
        },
        timeline   = T{},
        death_log  = T{},
        chains     = T{ closer = new_ledger(), split = new_ledger() },
    };
end

local function find_index(id)
    local entity = memory():GetEntity();
    if (id >= FIRST_MOB_ID) then
        local index = id % 0x1000;
        if (index < 2304 and entity:GetServerId(index) == id) then
            return index;
        end
        return nil;
    end
    for index = 0x400, 0x6FF do
        if (entity:GetServerId(index) == id) then
            return index;
        end
    end
    return nil;
end

local function entity_name(id)
    local known = state.known[id];
    local index = (known and known.index) or find_index(id);
    if (index) then
        local entity = memory():GetEntity();
        if (entity:GetServerId(index) == id) then
            local name = clean(entity:GetName(index));
            if (name) then
                state.known[id] = T{ index = index, name = name };
                return name;
            end
        end
    end
    return known and known.name or nil;
end

local function refresh(now)
    local party  = memory():GetParty();
    local entity = memory():GetEntity();
    local roster = T{};
    local pets   = T{};

    for slot = 0, 17 do
        local id   = party:GetMemberServerId(slot);
        local name = clean(party:GetMemberName(slot));
        if (party:GetMemberIsActive(slot) == 1 and id ~= 0 and name) then
            local index  = party:GetMemberTargetIndex(slot);
            local member = T{
                id       = id,
                key      = name,
                name     = name,
                job      = party:GetMemberMainJob(slot),
                level    = party:GetMemberMainJobLevel(slot),
                sub      = party:GetMemberSubJob(slot),
                sublevel = party:GetMemberSubJobLevel(slot),
            };
            if (slot == 0) then
                member.kind = 'me';
                if ((member.job or 0) == 0) then
                    local player = memory():GetPlayer();
                    member.job      = player:GetMainJob();
                    member.level    = player:GetMainJobLevel();
                    member.sub      = player:GetSubJob();
                    member.sublevel = player:GetSubJobLevel();
                end
            elseif (index >= 0x700) then
                member.kind = 'trust';
            elseif (slot < 6) then
                member.kind = 'party';
            else
                member.kind = 'alliance';
            end
            roster[id] = member;

            if (index > 0 and index < 2304) then
                local pet = entity:GetPetTargetIndex(index);
                if (pet and pet > 0 and pet < 2304) then
                    local pet_id = entity:GetServerId(pet);
                    if (pet_id and pet_id ~= 0) then
                        local pet_name = clean(entity:GetName(pet)) or 'Pet';
                        pets[pet_id] = T{
                            id       = pet_id,
                            key      = member.name .. '|' .. pet_name,
                            name     = pet_name,
                            owner    = member.name,
                            mine     = slot == 0,
                            kind     = 'pet',
                            job      = member.job,
                            level    = member.level,
                            sub      = member.sub,
                            sublevel = member.sublevel,
                        };
                    end
                end
            end
        end
    end

    state.roster    = roster;
    state.pets      = pets;
    state.refreshed = now;
end

local function identify(id, now)
    local who = state.roster[id] or state.pets[id];
    if (not who and now - state.refreshed > REFRESH_MISS) then
        refresh(now);
        who = state.roster[id] or state.pets[id];
    end
    return who;
end

local function is_enemy(id)
    return id >= FIRST_MOB_ID and not state.roster[id] and not state.pets[id];
end

local function action_name(category, param)
    local key  = ('%d:%d'):fmt(category, param);
    local name = state.names[key];
    if (name) then
        return name;
    end

    local resource = AshitaCore:GetResourceManager();
    if (category == 4) then
        local spell = resource:GetSpellById(param);
        name = spell and clean(spell.Name[1]);
    elseif (category == 5) then
        local item = resource:GetItemById(param);
        name = item and clean(item.Name[1]);
    elseif ((category == 3 or category == 11) and param < 256) then
        local ability = resource:GetAbilityById(param);
        name = ability and clean(ability.Name[1]);
    elseif (category == 3 or category == 11) then
        name = clean(resource:GetString('monsters.abilities', param - 256));
    else
        local ability = resource:GetAbilityById(param + 0x200);
        name = ability and clean(ability.Name[1]);
    end

    name = name or ('Action %d'):fmt(param);
    state.names[key] = name;
    return name;
end

local function primary_message(act)
    for _, target in ipairs(act.targets) do
        for _, result in ipairs(target.results) do
            if (result.message ~= 0) then
                return result.message;
            end
        end
    end
    return 0;
end

local function action_ref(act)
    local category = act.category;
    local param    = act.param;
    if ((category == 3 or category == 11) and ABILITY_MESSAGE[primary_message(act)]) then
        category = 6;
    end

    local kind = KIND[category];
    if (not kind) then
        return nil;
    end

    local ref = T{ kind = kind, category = category };
    if (category == 1) then
        ref.key  = 'melee';
        ref.name = 'Melee';
    elseif (category == 2) then
        ref.key  = 'ranged';
        ref.name = 'Ranged';
    else
        ref.key  = ('%d:%d'):fmt(category, param);
        ref.name = action_name(category, param);
    end
    return ref;
end

local function engage(now)
    local segment = state.current;
    if (not segment) then
        segment = new_segment(now, false);
        state.current = segment;
    end
    segment.last = now;
    return segment;
end

local function active(now)
    return T{ state.overall, engage(now) };
end

local function settled(now)
    local list = T{ state.overall };
    if (state.current) then
        list:append(state.current);
    elseif (state.history[1] and now - state.history[1].ended <= LINGER) then
        list:append(state.history[1]);
    end
    return list;
end

local function listening()
    local list = T{ state.overall };
    if (state.current) then
        list:append(state.current);
    end
    return list;
end

local function actor_in(segment, who)
    local actor = segment.actors[who.key];
    if (not actor) then
        actor = new_actor(who);
        segment.actors[who.key] = actor;
    elseif ((who.job or 0) > 0) then
        actor.job      = who.job;
        actor.sub      = who.sub;
        actor.level    = who.level;
        actor.sublevel = who.sublevel;
    end
    return actor;
end

local function entry_in(book, ref)
    local entry = book[ref.key];
    if (not entry) then
        entry = T{
            key     = ref.key,
            name    = ref.name,
            kind    = ref.kind,
            total   = 0,
            uses    = 0,
            hits    = 0,
            misses  = 0,
            crits   = 0,
            bursts  = 0,
            landed  = 0,
            resists = 0,
            normal  = new_stat(),
            crit    = new_stat(),
            serial  = 0,
        };
        book[ref.key] = entry;
    end
    if (entry.serial ~= state.serial) then
        entry.serial = state.serial;
        entry.uses   = entry.uses + 1;
    end
    return entry;
end

local function note_activity(actor, now)
    if (actor.last_action) then
        local gap = now - actor.last_action;
        actor.active = actor.active + ((gap <= ACTIVE_GAP) and gap or ACTIVE_FLOOR);
    else
        actor.active = ACTIVE_FLOOR;
    end
    actor.last_action = now;
end

local function book_damage(segment, actor, entry, foe, amount, crit, burst, now)
    entry.hits  = entry.hits + 1;
    entry.total = entry.total + amount;
    if (crit) then
        entry.crits = entry.crits + 1;
        add_stat(entry.crit, amount);
    else
        add_stat(entry.normal, amount);
    end
    if (burst) then
        entry.bursts = entry.bursts + 1;
    end

    actor.damage = actor.damage + amount;
    actor.targets[foe]   = (actor.targets[foe] or 0) + amount;
    segment.damage       = segment.damage + amount;
    segment.foes[foe]    = (segment.foes[foe] or 0) + amount;
    note_activity(actor, now);

    if (not segment.overall) then
        local second = math.floor(now - segment.started);
        actor.timeline[second] = (actor.timeline[second] or 0) + amount;
    end
end

local function add_damage(segment, member, ref, foe, amount, crit, burst, now)
    local actor = actor_in(segment, member);
    book_damage(segment, actor, entry_in(actor.abilities, ref), foe, amount, crit, burst, now);
end

local function dot_key(target, effect)
    return ('%d:%d'):fmt(target, effect);
end

local function run_dot(dot, now)
    local due = math.floor((math.min(now, dot.expires) - dot.started) / dots.TICK);
    while (dot.ticks < due) do
        dot.ticks = dot.ticks + 1;
        for _, segment in ipairs(active(now)) do
            local actor = actor_in(segment, dot.who);
            local entry = actor.abilities[dot.ref.key];
            if (not entry) then
                entry = entry_in(actor.abilities, dot.ref);
            elseif (dot.ticks == 1) then
                entry.uses = entry.uses + 1;
            end
            book_damage(segment, actor, entry, dot.foe, dot.power, false, false, now);
        end
        state.engaged[dot.target] = now;
        state.version = state.version + 1;
    end
end

local function stop_dot(key, now)
    local dot = state.dots[key];
    if (dot) then
        run_dot(dot, now);
        state.dots[key] = nil;
    end
end

local function stop_dots(target, now)
    for key, dot in pairs(state.dots) do
        if (dot.target == target) then
            stop_dot(key, now);
        end
    end
end

local function start_dot(source, ref, member, target, foe, now)
    local key = dot_key(target, source.effect);
    local old = state.dots[key];
    if (old and (source.silent or (old.tier or 0) > (source.tier or 0))) then
        return;
    end
    if (source.rival) then
        local rival = state.dots[dot_key(target, source.rival)];
        if (rival and rival.tier > source.tier) then
            return;
        end
        stop_dot(dot_key(target, source.rival), now);
    end
    if (source.clears) then
        stop_dot(dot_key(target, source.clears), now);
    end
    stop_dot(key, now);

    state.dots[key] = T{
        who     = member,
        ref     = T{ key = 'dot:' .. ref.key, name = ref.name .. ' (DoT)', kind = ref.kind },
        target  = target,
        foe     = foe,
        tier    = source.tier,
        power   = dots.power(source, member),
        started = now,
        expires = now + source.duration,
        ticks   = 0,
    };
end

local function credit(segment, ledger, ref, foe, amount, now)
    local entry = entry_in(ledger.abilities, ref);
    entry.hits  = entry.hits + 1;
    entry.total = entry.total + amount;
    add_stat(entry.normal, amount);
    ledger.damage       = ledger.damage + amount;
    ledger.targets[foe] = (ledger.targets[foe] or 0) + amount;
    if (not segment.overall) then
        local second = math.floor(now - segment.started);
        ledger.timeline[second] = (ledger.timeline[second] or 0) + amount;
    end
end

local function add_chain(member, target, foe, element, amount, now)
    local closed = T{ key = 'sc:' .. element, name = 'Skillchain: ' .. element, kind = 'sc' };
    local opened = T{ key = 'sc:' .. element .. ':open', name = ('Skillchain: %s (Opened)'):fmt(element), kind = 'sc' };
    local last   = state.resonance[target];
    local opener = nil;
    if (last and now <= last.expires and last.who.key ~= member.key) then
        opener = last.who;
    end
    local half = opener and math.floor(amount / 2) or 0;

    for _, segment in ipairs(active(now)) do
        local chains = actor_in(segment, member).chains;
        credit(segment, chains.closer, closed, foe, amount, now);
        credit(segment, chains.split, closed, foe, amount - half, now);
        if (half > 0) then
            credit(segment, actor_in(segment, opener).chains.split, opened, foe, half, now);
        end
        segment.chained = segment.chained + amount;
    end
end

local function add_miss(segment, member, ref, foe, now)
    local actor = actor_in(segment, member);
    local entry = entry_in(actor.abilities, ref);
    entry.misses = entry.misses + 1;
    segment.foes[foe] = segment.foes[foe] or 0;
    note_activity(actor, now);
end

local function add_enfeeble(segment, member, ref, foe, landed)
    local actor = actor_in(segment, member);
    local entry = entry_in(actor.enfeebles, ref);
    if (landed) then
        entry.landed = entry.landed + 1;
    else
        entry.resists = entry.resists + 1;
    end
    segment.foes[foe] = segment.foes[foe] or 0;
end

local function add_heal(segment, member, ref, patient, amount)
    local actor = actor_in(segment, member);
    local entry = entry_in(actor.heals, ref);
    entry.hits  = entry.hits + 1;
    entry.total = entry.total + amount;
    add_stat(entry.normal, amount);
    actor.healing         = actor.healing + amount;
    actor.healed[patient] = (actor.healed[patient] or 0) + amount;
    segment.healing       = segment.healing + amount;
end

local function source_in(actor, foe, ref)
    local key   = foe .. '|' .. ref.key;
    local entry = actor.sources[key];
    if (not entry) then
        entry = T{ key = key, foe = foe, name = ref.name, kind = ref.kind, total = 0, hits = 0, crits = 0, max = 0, avoided = 0 };
        actor.sources[key] = entry;
    end
    return entry;
end

local function add_taken(segment, member, foe, ref, amount, crit)
    local actor = actor_in(segment, member);
    local entry = source_in(actor, foe, ref);
    entry.hits  = entry.hits + 1;
    entry.total = entry.total + amount;
    entry.max   = math.max(entry.max, amount);
    if (crit) then
        entry.crits = entry.crits + 1;
    end
    actor.taken       = actor.taken + amount;
    segment.taken     = segment.taken + amount;
    segment.foes[foe] = segment.foes[foe] or 0;
end

local function add_avoid(segment, member, foe, ref, outcome, melee)
    local actor = actor_in(segment, member);
    local entry = source_in(actor, foe, ref);
    entry.avoided = entry.avoided + 1;
    if (melee or outcome == 'resist') then
        actor.defense[outcome] = actor.defense[outcome] + 1;
    end
    segment.foes[foe] = segment.foes[foe] or 0;
end

local function remember(who, entry)
    local log = state.recent[who.key];
    if (not log) then
        log = T{};
        state.recent[who.key] = log;
    end
    log:append(entry);
    if (#log > RECENT_SIZE) then
        table.remove(log, 1);
    end
end

local function patient_name(id)
    local member = state.roster[id];
    if (member) then
        return member.name;
    end
    local pet = state.pets[id];
    if (pet) then
        return pet.name;
    end
    return entity_name(id) or 'Unknown';
end

local function hand_of(animation, h2h)
    if (animation == 2 or animation == 3) then
        return 'kick';
    elseif (animation == 4) then
        return 'daken';
    elseif (h2h or animation == 0) then
        return 'main';
    end
    return 'off';
end

local function tally(book, count)
    if (count > 0) then
        local bucket = math.min(count, SWING_LIMIT);
        book[bucket] = (book[bucket] or 0) + 1;
    end
end

local function add_round(member, swings, results, now)
    local h2h       = swings[1].animation == 1;
    local first     = swings[1];
    local clean     = HIT[first.message] == true and first.resolution == 0 and first.react_kind ~= 63;
    local truncated = results >= 8;
    local count     = T{ main = 0, off = 0, kick = 0, daken = 0 };
    for _, swing in ipairs(swings) do
        local hand = hand_of(swing.animation, h2h);
        count[hand] = count[hand] + 1;
        if (bit.band(swing.info, 1) ~= 0) then
            truncated = true;
        end
    end

    for _, segment in ipairs(active(now)) do
        local actor  = actor_in(segment, member);
        local rounds = actor.rounds;

        for _, swing in ipairs(swings) do
            local stat = actor.hands[hand_of(swing.animation, h2h)];
            stat.swings = stat.swings + 1;
            if (HIT[swing.message]) then
                stat.hits  = stat.hits + 1;
                stat.total = stat.total + swing.value;
                stat.max   = math.max(stat.max, swing.value);
                if (CRIT[swing.message]) then
                    stat.crits = stat.crits + 1;
                end
            end
        end

        rounds.count = rounds.count + 1;

        if (not truncated) then
            rounds.measured = rounds.measured + 1;
            if (count.kick > 0) then
                rounds.kick_rounds = rounds.kick_rounds + 1;
            end
            if (count.daken > 0) then
                rounds.daken_rounds = rounds.daken_rounds + 1;
            end
            if (h2h) then
                rounds.h2h = rounds.h2h + 1;
                tally(rounds.fists, count.main);
            else
                tally(rounds.main, count.main);
                if (count.off > 0) then
                    rounds.dual = rounds.dual + 1;
                    tally(rounds.off, count.off);
                elseif (count.daken == 0 and clean) then
                    rounds.clean = rounds.clean + 1;
                    if (count.main == 2) then
                        rounds.clean_double = rounds.clean_double + 1;
                    end
                elseif (count.daken == 0) then
                    rounds.missed = rounds.missed + 1;
                    if (count.main == 2) then
                        rounds.missed_double = rounds.missed_double + 1;
                    end
                end
            end
        end
    end
end

local function strike(act, ref, member, target, foe, result, now)
    local message  = result.message;
    local physical = act.category == 1 or act.category == 2;
    local swung    = false;

    if (HIT[message]) then
        for _, segment in ipairs(active(now)) do
            add_damage(segment, member, ref, foe, result.value, CRIT[message] == true, BURST[message] == true, now);
        end
        swung = true;
    elseif (MISS[message] or (physical and RESOLUTION[result.resolution]) or (message == 0 and result.react_kind == 63)) then
        for _, segment in ipairs(active(now)) do
            add_miss(segment, member, ref, foe, now);
        end
        swung = true;
    elseif (act.category == 4 and (ENFEEBLE[message] or RESIST[message])) then
        for _, segment in ipairs(active(now)) do
            add_enfeeble(segment, member, ref, foe, ENFEEBLE[message] == true);
        end
    end

    if (swung) then
        state.engaged[target] = now;
    end

    if (result.proc_message and result.proc_value > 0) then
        local element = SKILLCHAINS[result.proc_message];
        if (element) then
            add_chain(member, target, foe, element, result.proc_value, now);
        elseif (ADDED[result.proc_message]) then
            for _, segment in ipairs(active(now)) do
                add_damage(segment, member, ADDED_REF, foe, result.proc_value, false, false, now);
            end
        end
    end

    if (result.react_message and result.react_value > 0) then
        local reaction = nil;
        if (SPIKES[result.react_message]) then
            reaction = SPIKES_REF;
        elseif (result.react_kind == 63 and result.react_message == 536) then
            reaction = RETALIATION_REF;
        elseif (result.react_kind == 63 and result.react_message == 33) then
            reaction = COUNTER_REF;
        end
        if (reaction) then
            for _, segment in ipairs(active(now)) do
                add_taken(segment, member, foe, reaction, result.react_value, false);
            end
            remember(member, T{ time = now, kind = 'hit', who = foe, what = reaction.name, amount = result.react_value });
        end
    end

    return swung;
end

local function offense(act, member, now)
    local ref = action_ref(act);
    if (not ref) then
        return;
    end

    for _, target in ipairs(act.targets) do
        if (is_enemy(target.id)) then
            local foe    = entity_name(target.id) or 'Unknown';
            local swings = T{};
            local landed = false;
            local stuck  = false;
            for _, result in ipairs(target.results) do
                if (strike(act, ref, member, target.id, foe, result, now) and act.category == 1) then
                    swings:append(result);
                end
                landed = landed or HIT[result.message] == true;
                stuck  = stuck or ENFEEBLE[result.message] == true;
            end
            if (act.category == 1 and #swings > 0) then
                add_round(member, swings, #target.results, now);
            end
            if (landed and CHAIN_STEP[ref.category]) then
                state.resonance[target.id] = T{ who = member, expires = now + CHAIN_WINDOW };
            end
            local source = dots.source(ref.category, act.param);
            if (source and (landed or stuck)) then
                start_dot(source, ref, member, target.id, foe, now);
            end
        else
            for _, result in ipairs(target.results) do
                if (HEAL[result.message] and result.value > 0) then
                    local patient = patient_name(target.id);
                    for _, segment in ipairs(listening()) do
                        add_heal(segment, member, ref, patient, result.value);
                    end
                    local healed = state.roster[target.id] or state.pets[target.id];
                    if (healed) then
                        remember(healed, T{ time = now, kind = 'heal', who = member.name, what = ref.name, amount = result.value });
                    end
                end
            end
        end
    end
end

local function guard(act, ref, member, foe, result, now)
    local message = result.message;
    local melee   = act.category == 1;

    if (HIT[message]) then
        local crit = CRIT[message] == true;
        for _, segment in ipairs(active(now)) do
            add_taken(segment, member, foe, ref, result.value, crit);
            if (melee) then
                local defense = actor_in(segment, member).defense;
                if (crit) then
                    defense.crit = defense.crit + 1;
                else
                    defense.hit = defense.hit + 1;
                end
                if (result.resolution == 4) then
                    defense.block = defense.block + 1;
                elseif (result.resolution == 2) then
                    defense.guard = defense.guard + 1;
                end
            end
        end
        remember(member, T{ time = now, kind = crit and 'crit' or 'hit', who = foe, what = ref.name, amount = result.value });
    else
        local outcome = MISS[message];
        if (not outcome and result.react_kind == 63) then
            outcome = 'counter';
        elseif (not outcome and melee) then
            outcome = RESOLUTION[result.resolution];
        end
        if (not outcome and RESIST[message]) then
            outcome = 'resist';
        end
        if (outcome) then
            for _, segment in ipairs(active(now)) do
                add_avoid(segment, member, foe, ref, outcome, melee);
            end
            remember(member, T{ time = now, kind = 'avoid', who = foe, what = ref.name, outcome = outcome });
        end
    end

    if (result.proc_message and ADDED[result.proc_message] and result.proc_value > 0) then
        for _, segment in ipairs(active(now)) do
            add_taken(segment, member, foe, ADDED_REF, result.proc_value, false);
        end
        remember(member, T{ time = now, kind = 'hit', who = foe, what = ADDED_REF.name, amount = result.proc_value });
    end

    if (result.react_message and result.react_value > 0) then
        local reaction = nil;
        if (SPIKES[result.react_message]) then
            reaction = SPIKES_REF;
        elseif (result.react_kind == 63 and result.react_message == 536) then
            reaction = RETALIATION_REF;
        elseif (result.react_kind == 63 and result.react_message == 33) then
            reaction = COUNTER_REF;
        end
        if (reaction) then
            for _, segment in ipairs(active(now)) do
                add_damage(segment, member, reaction, foe, result.react_value, false, false, now);
            end
        end
    end
end

local function defense(act, now)
    local ref = action_ref(act);
    if (not ref) then
        return;
    end

    local foe = nil;
    for _, target in ipairs(act.targets) do
        local who = identify(target.id, now);
        if (who) then
            foe = foe or entity_name(act.actor) or 'Unknown';
            state.engaged[act.actor] = now;
            for _, result in ipairs(target.results) do
                guard(act, ref, who, foe, result, now);
            end
        end
    end
end

local function note_effect(actor, id, now)
    local entry = actor.effects[id];
    if (not entry) then
        entry = T{ id = id, spans = T{}, total = 0, count = 0 };
        actor.effects[id] = entry;
    end
    local last = entry.spans[#entry.spans];
    if (last and now - last[2] <= EFFECT_GAP) then
        last[2] = now;
    else
        entry.spans:append(T{ now, now });
    end
end

local function overlap(spans, first, stop)
    local seconds, count = 0, 0;
    for _, span in ipairs(spans) do
        local covered = math.min(span[2], stop) - math.max(span[1], first);
        if (covered > 0) then
            seconds = seconds + covered;
            count   = count + 1;
        end
    end
    return seconds, count;
end

local function own_effects()
    local list  = T{};
    local buffs = memory():GetPlayer():GetBuffs();
    if (type(buffs) ~= 'table') then
        return list;
    end
    for _, id in pairs(buffs) do
        if (type(id) == 'number' and id > 0 and id < 0x400 and id ~= 255) then
            list:append(id);
        end
    end
    return list;
end

local function sample_effects(now)
    local segment = state.current;
    if (not segment or now - state.last_sample < EFFECT_STEP) then
        return;
    end
    state.last_sample = now;

    for id, who in pairs(state.roster) do
        local effects = nil;
        if (who.kind == 'me') then
            effects = own_effects();
        elseif (who.kind == 'party') then
            effects = state.effects[id];
        end
        if (effects) then
            local actor = actor_in(segment, who);
            for _, effect in ipairs(effects) do
                note_effect(actor, effect, now);
            end
        end
    end
end

local function fold_effects(segment)
    for _, actor in pairs(segment.actors) do
        if (next(actor.effects) ~= nil) then
            local total = actor_in(state.overall, actor);
            for id, entry in pairs(actor.effects) do
                local seconds, count = overlap(entry.spans, segment.started, segment.ended);
                if (seconds > 0) then
                    local sum = total.effects[id];
                    if (not sum) then
                        sum = T{ id = id, spans = T{}, total = 0, count = 0 };
                        total.effects[id] = sum;
                    end
                    sum.total = sum.total + seconds;
                    sum.count = sum.count + count;
                end
            end
        end
    end
end

local function close()
    local segment = state.current;
    if (not segment) then
        return;
    end
    state.current = nil;
    segment.ended = segment.last;
    if (segment.damage + segment.taken + segment.healing == 0 and segment.deaths == 0) then
        return;
    end

    state.version = state.version + 1;
    segment.name = combat.name(segment);
    state.overall.time   = state.overall.time + (segment.ended - segment.started);
    state.overall.fights = state.overall.fights + 1;
    fold_effects(segment);
    table.insert(state.history, 1, segment);
    while (#state.history > state.limit) do
        table.remove(state.history);
    end
end

local function record_death(member, killer, now)
    local events = T{};
    for _, entry in ipairs(state.recent[member.key] or T{}) do
        if (now - entry.time <= RECENT_SPAN) then
            events:append(entry);
        end
    end
    state.recent[member.key] = nil;

    local death = T{ time = now, stamp = os.time(), killer = killer, events = events };
    for _, segment in ipairs(settled(now)) do
        local actor = actor_in(segment, member);
        actor.deaths   = actor.deaths + 1;
        segment.deaths = segment.deaths + 1;
        actor.death_log:append(death);
        if (#actor.death_log > DEATH_KEEP) then
            table.remove(actor.death_log, 1);
        end
    end
end

local function record_kill(killer, now)
    for _, segment in ipairs(settled(now)) do
        segment.kills = segment.kills + 1;
        if (killer) then
            local actor = actor_in(segment, killer);
            actor.kills = actor.kills + 1;
        end
    end
end

function combat.action(act, now)
    if (#act.targets == 0) then
        return;
    end
    state.serial  = state.serial + 1;
    state.version = state.version + 1;

    local who = identify(act.actor, now);
    if (who) then
        offense(act, who, now);
    elseif (is_enemy(act.actor)) then
        defense(act, now);
    end
end

function combat.message(packet, now)
    if (packet.message == WEAR_OFF) then
        local key = dot_key(packet.target, packet.param);
        if (state.dots[key] and state.dots[key].who.kind == 'me') then
            stop_dot(key, now);
        end
        return;
    end
    if (not DEFEAT[packet.message]) then
        return;
    end

    state.version = state.version + 1;
    local victim = identify(packet.target, now);
    if (victim) then
        local killer = nil;
        if (packet.actor ~= packet.target) then
            killer = entity_name(packet.actor);
        end
        record_death(victim, killer, now);
        return;
    end
    stop_dots(packet.target, now);

    local seen = state.engaged[packet.target];
    if (is_enemy(packet.target) and seen and now - seen <= LINGER) then
        state.engaged[packet.target] = nil;
        record_kill(identify(packet.actor, now), now);
    end
end

function combat.experience(packet, now)
    if (not EXP_GAIN[packet.message]) then
        return;
    end

    local exp = state.exp;
    if (#exp.gains == 0) then
        exp.since = state.current and state.current.started or now;
    end
    exp.gains:append(T{ time = now, amount = packet.amount });
    exp.recent = exp.recent + packet.amount;
    exp.total  = exp.total + packet.amount;
    exp.goal   = EXP_GAIN[packet.message];
end

function combat.exp(now)
    local exp    = state.exp;
    local span   = math.max(EXP_FLOOR, math.min(EXP_WINDOW, now - exp.since));
    local rate   = exp.recent * 3600 / span;
    local player = memory():GetPlayer();
    local left   = player:GetExpNeeded() - player:GetExpCurrent();
    if (exp.goal == 'merit') then
        left = MERIT_COST - player:GetLimitPoints();
    end

    local eta = nil;
    if (rate > 0) then
        eta = left * 3600 / rate;
    end
    return T{ total = exp.total, rate = rate, goal = exp.goal, eta = eta };
end

function combat.tick(now, idle, limit, chains)
    state.limit = limit;
    if (chains ~= state.chain_mode) then
        state.chain_mode = chains;
        state.version    = state.version + 1;
    end
    if (not state.overall) then
        combat.reset(now);
    end

    local zone = memory():GetParty():GetMemberZone(0);
    if (zone ~= state.zone) then
        close();
        state.zone      = zone;
        state.known     = T{};
        state.engaged   = T{};
        state.resonance = T{};
        state.recent    = T{};
        state.dots      = T{};
        state.refreshed = -math.huge;
    end

    for key, dot in pairs(state.dots) do
        run_dot(dot, now);
        if (now >= dot.expires) then
            state.dots[key] = nil;
        end
    end

    if (state.current and now - state.current.last > idle) then
        close();
    end
    sample_effects(now);

    local exp = state.exp;
    while (exp.gains[1] and now - exp.gains[1].time > EXP_WINDOW) do
        exp.recent = exp.recent - table.remove(exp.gains, 1).amount;
    end

    while (#state.history > state.limit) do
        table.remove(state.history);
    end

    if (now - state.refreshed > REFRESH_IDLE) then
        refresh(now);
    end
end

function combat.reset(now)
    state.version = state.version + 1;
    state.current = nil;
    state.history = T{};
    state.recent  = T{};
    state.engaged = T{};
    state.resonance = T{};
    state.dots    = T{};
    state.overall = new_segment(now, true);
    state.empty   = new_segment(now, false);
    state.empty.ended = now;
    state.exp     = T{ total = 0, recent = 0, since = now, gains = T{} };
end

function combat.view(which)
    if (which == 'overall') then
        return state.overall;
    end
    if (which ~= 'current') then
        for _, segment in ipairs(state.history) do
            if (segment == which) then
                return segment;
            end
        end
    end
    return state.current or state.history[1] or state.empty;
end

function combat.duration(segment, now)
    if (segment.overall) then
        local live = 0;
        if (state.current) then
            live = combat.duration(state.current, now);
        end
        return math.max(1, segment.time + live);
    end
    local stop = segment.ended or math.min(now, segment.last + SETTLE);
    return math.max(1, stop - segment.started);
end

function combat.damage_total(segment)
    if (state.chain_mode == 'ignored') then
        return segment.damage;
    end
    return segment.damage + segment.chained;
end

function combat.active_time(actor)
    return math.max(actor.active, ACTIVE_FLOOR);
end

function combat.multi_attack(actor)
    local rounds  = actor.rounds;
    local zanshin = 0;
    if (actor.kind ~= 'pet' and (actor.job == SAMURAI or actor.sub == SAMURAI)) then
        local rate = 0;
        if (rounds.clean > 0) then
            rate = rounds.clean_double / rounds.clean;
        end
        zanshin = math.floor(rounds.missed_double - rate * rounds.missed + 0.5);
        zanshin = math.max(0, math.min(rounds.missed_double, zanshin));
    end

    local more = 0;
    for count = 5, SWING_LIMIT do
        more = more + (rounds.main[count] or 0);
    end

    return T{
        rounds  = rounds.measured - rounds.h2h,
        double  = (rounds.main[2] or 0) - zanshin,
        triple  = rounds.main[3] or 0,
        more    = more,
        zanshin = zanshin,
        chances = rounds.missed,
    };
end

local function tag_into(book, source, pet)
    for key, entry in pairs(source) do
        local tagged = T{};
        for field, value in pairs(entry) do
            tagged[field] = value;
        end
        tagged.key  = pet .. '|' .. key;
        tagged.pet  = pet;
        book[tagged.key] = tagged;
    end
end

local function copy(source)
    local out = T{};
    for key, value in pairs(source) do
        out[key] = value;
    end
    return out;
end

local function add_into(book, source)
    for key, amount in pairs(source) do
        book[key] = (book[key] or 0) + amount;
    end
end

local function chain_view(actor)
    local view   = copy(actor);
    local ledger = actor.chains[state.chain_mode];
    view.closed  = actor.chains.closer.abilities;
    if (not ledger or ledger.damage == 0) then
        return view;
    end

    view.damage    = actor.damage + ledger.damage;
    view.abilities = copy(actor.abilities);
    view.targets   = copy(actor.targets);
    view.timeline  = copy(actor.timeline);
    for key, entry in pairs(ledger.abilities) do
        view.abilities[key] = entry;
    end
    add_into(view.targets, ledger.targets);
    add_into(view.timeline, ledger.timeline);
    return view;
end

local function build_merged(segment, key)
    local base = segment.actors[key];
    local pets = T{};
    for _, actor in pairs(segment.actors) do
        if (actor.kind == 'pet' and actor.owner == key) then
            pets:append(chain_view(actor));
        end
    end
    if (#pets == 0) then
        return base and chain_view(base);
    end
    table.sort(pets, function (a, b) return a.key < b.key; end);

    if (not base) then
        local pet = pets[1];
        base = new_actor(T{ key = key, name = key, job = pet.job, sub = pet.sub, level = pet.level, sublevel = pet.sublevel, kind = 'party' });
    end
    base = chain_view(base);

    local view = copy(base);
    view.abilities   = copy(base.abilities);
    view.heals       = copy(base.heals);
    view.enfeebles   = copy(base.enfeebles);
    view.targets     = copy(base.targets);
    view.healed      = copy(base.healed);
    view.timeline    = copy(base.timeline);
    view.closed      = copy(base.closed);
    view.pets        = pets;
    view.merged      = true;
    view.pet_damage  = 0;
    view.pet_healing = 0;
    view.pet_taken   = 0;

    for _, pet in ipairs(pets) do
        view.damage      = view.damage + pet.damage;
        view.healing     = view.healing + pet.healing;
        view.kills       = view.kills + pet.kills;
        view.active      = math.max(view.active, pet.active);
        view.pet_damage  = view.pet_damage + pet.damage;
        view.pet_healing = view.pet_healing + pet.healing;
        view.pet_taken   = view.pet_taken + pet.taken;
        tag_into(view.abilities, pet.abilities, pet.name);
        tag_into(view.heals, pet.heals, pet.name);
        tag_into(view.enfeebles, pet.enfeebles, pet.name);
        tag_into(view.closed, pet.closed, pet.name);
        add_into(view.targets, pet.targets);
        add_into(view.healed, pet.healed);
        add_into(view.timeline, pet.timeline);
    end
    return view;
end

function combat.lookup(segment, key, merge)
    local cache = segment.view_cache;
    if (not cache or cache.version ~= state.version) then
        cache = T{ version = state.version, merged = T{}, single = T{} };
        segment.view_cache = cache;
    end
    local views = merge and cache.merged or cache.single;
    local view  = views[key];
    if (view == nil) then
        if (merge) then
            view = build_merged(segment, key) or false;
        else
            view = segment.actors[key] and chain_view(segment.actors[key]) or false;
        end
        views[key] = view;
    end
    return view or nil;
end

function combat.rows(segment, merge)
    local list = T{};
    if (not merge) then
        for key in pairs(segment.actors) do
            list:append(combat.lookup(segment, key, false));
        end
        return list;
    end

    local owners = T{};
    for key, actor in pairs(segment.actors) do
        if (actor.kind == 'pet') then
            owners[actor.owner] = true;
        else
            list:append(combat.lookup(segment, key, true));
        end
    end
    for owner in pairs(owners) do
        if (not segment.actors[owner]) then
            list:append(combat.lookup(segment, owner, true));
        end
    end
    return list;
end

function combat.group_effects(members)
    local effects = T{};
    for _, member in ipairs(members) do
        effects[member.id] = member.effects;
    end
    state.effects = effects;
end

local function effect_name(id)
    local name = state.effect_names[id];
    if (not name) then
        name = clean(AshitaCore:GetResourceManager():GetString('buffs.names', id)) or ('Effect %d'):fmt(id);
        state.effect_names[id] = name;
    end
    return name;
end

function combat.uptimes(segment, key, now)
    local found = T{};
    local function add(id, seconds, count)
        if (seconds > 0) then
            local item = found[id];
            if (not item) then
                item = T{ id = id, seconds = 0, count = 0 };
                found[id] = item;
            end
            item.seconds = item.seconds + seconds;
            item.count   = item.count + count;
        end
    end

    local actor = segment.actors[key];
    if (segment.overall) then
        if (actor) then
            for id, entry in pairs(actor.effects) do
                add(id, entry.total, entry.count);
            end
        end
        local live = state.current and state.current.actors[key];
        if (live) then
            local stop = math.min(now, state.current.last + SETTLE);
            for id, entry in pairs(live.effects) do
                add(id, overlap(entry.spans, state.current.started, stop));
            end
        end
    elseif (actor) then
        local stop = segment.ended or math.min(now, segment.last + SETTLE);
        for id, entry in pairs(actor.effects) do
            add(id, overlap(entry.spans, segment.started, stop));
        end
    end

    local duration = combat.duration(segment, now);
    local list     = T{};
    for id, item in pairs(found) do
        item.name   = effect_name(id);
        item.share  = math.min(1, item.seconds / duration);
        item.debuff = DEBUFF[id] == true;
        list:append(item);
    end
    table.sort(list, function (a, b)
        if (a.share == b.share) then
            return a.name < b.name;
        end
        return a.share > b.share;
    end);
    return list;
end

function combat.live(segment)
    return segment ~= nil and segment == state.current;
end

function combat.in_combat()
    return state.current ~= nil;
end

function combat.history()
    return state.history;
end

function combat.name(segment)
    if (segment.overall) then
        return 'Overall';
    end
    if (segment.name) then
        return segment.name;
    end

    local best, top, count = nil, -1, 0;
    for foe, damage in pairs(segment.foes) do
        count = count + 1;
        if (damage > top or (damage == top and foe < best)) then
            best = foe;
            top  = damage;
        end
    end
    if (not best) then
        return 'No Target';
    end
    if (count > 1) then
        return ('%s +%d'):fmt(best, count - 1);
    end
    return best;
end

combat.SWING_LIMIT = SWING_LIMIT;

return combat;
