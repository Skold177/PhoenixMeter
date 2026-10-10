require('common');

local imgui    = require('imgui');
local settings = require('settings');
local theme    = require('theme');
local combat   = require('combat');

local COLOR = theme.COLOR;

local BASE_WIDTH      = 480;
local PADDING         = theme.PADDING;
local BAR_HEIGHT      = 18;
local LIST_ROWS       = 12;
local GRAPH_HEIGHT    = 72;
local GRAPH_WINDOW    = 5;
local MAX_HEIGHT      = 760;
local CLOSE           = ICON_FA_XMARK;
local CLOSE_CODEPOINT = 0xF00D;
local SKULL           = ICON_FA_SKULL;
local HAND_ATTACKS    = T{ 'Single attack', 'Double Attack', 'Triple Attack' };

local breakdown = T{
    BASE_WIDTH = BASE_WIDTH,
    bars       = T{},
    expanded   = T{},
};

function breakdown.forget()
    breakdown.bars     = T{};
    breakdown.expanded = T{};
end

local function stat(label, value, color)
    theme.stat_cell(label, value, color);
end

local function average(total, count)
    if (count <= 0) then
        return '-';
    end
    return theme.commas(total / count);
end

local function entry_label(entry)
    if (entry.pet) then
        return ('%s (%s)'):fmt(entry.name, entry.pet);
    end
    return entry.name;
end

local function kind_color(kind)
    local found = theme.KINDS[kind];
    return found and found.color or COLOR.peach;
end

local function sorted_entries(book)
    local list = T{};
    for _, entry in pairs(book) do
        if (entry.total > 0 or entry.misses > 0) then
            list:append(entry);
        end
    end
    table.sort(list, function (a, b)
        if (a.total == b.total) then
            return a.key < b.key;
        end
        return a.total > b.total;
    end);
    return list;
end

local function sorted_amounts(book)
    local list = T{};
    for name, amount in pairs(book) do
        if (amount > 0) then
            list:append(T{ name = name, total = amount });
        end
    end
    table.sort(list, function (a, b)
        if (a.total == b.total) then
            return a.name < b.name;
        end
        return a.total > b.total;
    end);
    return list;
end

local function bar_list(id, items, scale, factor, full)
    if (#items == 0) then
        imgui.TextColored(COLOR.faint, 'Nothing recorded.');
        return;
    end

    local height = math.floor(BAR_HEIGHT * scale);
    local scroll = #items > LIST_ROWS;
    local top    = full or 0;
    if (not full) then
        for _, item in ipairs(items) do
            top = math.max(top, item.value);
        end
    end

    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 8, 2 });
    local open = true;
    if (scroll) then
        open = imgui.BeginChild(id, { 0, LIST_ROWS * (height + 2) }, ImGuiChildFlags_None, ImGuiWindowFlags_None);
    end

    if (open) then
        local draw  = imgui.GetWindowDrawList();
        local width = theme.available();
        for _, item in ipairs(items) do
            local key = id .. '|' .. item.key;
            local x, y = theme.cursor();
            local clicked = imgui.InvisibleButton(key, { width, height });
            local hovered = imgui.IsItemHovered();

            local fraction = 0;
            if (top > 0) then
                fraction = item.value / top;
            end
            breakdown.bars[key] = theme.smooth(breakdown.bars[key] or 0, fraction, factor);
            theme.bar(draw, x, y, x + width, y + height, breakdown.bars[key], item.color, hovered);

            local ty          = y + (height - imgui.GetFontSize()) / 2;
            local right_width = theme.text_width(item.right);
            local left        = item.left;
            if (item.detail) then
                left = (breakdown.expanded[key] and '- ' or '+ ') .. left;
            end
            theme.label(draw, x + 6, ty, COLOR.text, theme.fit(left, width - right_width - 18));
            theme.label(draw, x + width - 6 - right_width, ty, COLOR.text, item.right);

            if (clicked and item.detail) then
                breakdown.expanded[key] = not breakdown.expanded[key];
            end
            if (hovered and item.tip) then
                imgui.BeginTooltip();
                item.tip();
                imgui.EndTooltip();
            end
            if (item.detail and breakdown.expanded[key]) then
                imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 8, 4 });
                item.detail();
                imgui.PopStyleVar(1);
                imgui.Spacing();
            end
        end
    end

    if (scroll) then
        imgui.EndChild();
    end
    imgui.PopStyleVar(1);
end

local function ability_detail(entry, actor)
    local attempts = entry.hits + entry.misses;
    if (not imgui.BeginTable('##pm_ability_' .. entry.key, 4, ImGuiTableFlags_SizingStretchSame)) then
        return;
    end
    stat('Uses', theme.commas(entry.uses));
    stat('Hits', theme.commas(entry.hits));
    stat('Misses', theme.commas(entry.misses));
    stat('Accuracy', theme.percent(entry.hits, attempts));
    stat('Crits', theme.commas(entry.crits));
    stat('Crit Rate', theme.percent(entry.crits, entry.hits));
    stat('Avg / Use', average(entry.total, entry.uses));
    stat('Share', theme.percent(entry.total, actor.damage));
    if (entry.normal.count > 0) then
        stat('Hit Min', theme.commas(entry.normal.min));
        stat('Hit Avg', average(entry.normal.total, entry.normal.count));
        stat('Hit Max', theme.commas(entry.normal.max));
        stat('Hit Total', theme.commas(entry.normal.total));
    end
    if (entry.crit.count > 0) then
        stat('Crit Min', theme.commas(entry.crit.min));
        stat('Crit Avg', average(entry.crit.total, entry.crit.count));
        stat('Crit Max', theme.commas(entry.crit.max));
        stat('Crit Total', theme.commas(entry.crit.total));
    end
    if (entry.bursts > 0) then
        stat('Bursts', theme.commas(entry.bursts));
        stat('Burst Rate', theme.percent(entry.bursts, entry.hits));
    end
    imgui.EndTable();
end

local function heal_detail(entry, actor)
    if (not imgui.BeginTable('##pm_heal_' .. entry.key, 4, ImGuiTableFlags_SizingStretchSame)) then
        return;
    end
    stat('Uses', theme.commas(entry.uses));
    stat('Heals', theme.commas(entry.hits));
    stat('Avg', average(entry.normal.total, entry.normal.count));
    stat('Share', theme.percent(entry.total, actor.healing));
    stat('Min', theme.commas(entry.normal.min));
    stat('Max', theme.commas(entry.normal.max));
    imgui.EndTable();
end

local function focus_name(key)
    local owner, pet = key:match('^(.-)|(.+)$');
    if (owner) then
        return ('%s (%s)'):fmt(pet, owner);
    end
    return key;
end

local function draw_header(pm, actor, segment, now, width, scale)
    local job       = theme.job(actor and actor.job);
    local chip_text = job.abbr;
    local color     = job.color;
    if (actor and actor.kind == 'pet') then
        chip_text = 'PET';
        color     = theme.shade(color, 0.75);
    end
    local draw      = imgui.GetWindowDrawList();
    local chip      = math.floor(theme.text_width('WAR') + 10 * scale);
    local tall      = imgui.GetFrameHeight();
    local close     = theme.text_width(CLOSE) + 12 * scale;
    local x, y      = theme.cursor();

    theme.chip(draw, x, y, x + chip, y + tall, color, chip_text);
    imgui.Dummy({ chip, tall });
    imgui.SameLine();
    imgui.AlignTextToFramePadding();
    imgui.TextColored(COLOR.peach, actor and actor.name or focus_name(pm.focus));
    if (actor) then
        imgui.SameLine();
        imgui.TextColored(COLOR.muted, theme.subtitle(actor));
    end
    imgui.SameLine(PADDING + width - close);
    if (theme.icon_button('##pm_close', CLOSE, CLOSE_CODEPOINT, false, close)) then
        pm.focus = nil;
    end

    local seconds = combat.duration(segment, now);
    local where   = combat.name(segment);
    if (combat.live(segment)) then
        where = where .. '  (live)';
    end
    local line = ('%s  |  %s'):fmt(where, theme.clock(seconds));
    if (actor and actor.damage > 0) then
        line = ('%s  |  active %s'):fmt(line, theme.clock(math.min(combat.active_time(actor), seconds)));
    end
    imgui.TextColored(COLOR.muted, line);
end

local function draw_tiles(actor, segment, now)
    local seconds = combat.duration(segment, now);
    local active  = math.min(combat.active_time(actor), seconds);
    if (not imgui.BeginTable('##pm_tiles', 4, ImGuiTableFlags_SizingStretchSame)) then
        return;
    end
    stat('Damage', theme.commas(actor.damage));
    stat('DPS', theme.rate(actor.damage / seconds));
    stat('Share', theme.percent(actor.damage, combat.damage_total(segment)));
    stat('Active DPS', actor.damage > 0 and theme.rate(actor.damage / combat.active_time(actor)) or '-');
    stat('Healing', theme.commas(actor.healing));
    stat('Taken', theme.commas(actor.taken));
    stat('Deaths', tostring(actor.deaths), actor.deaths > 0 and COLOR.danger or COLOR.text);
    stat('Activity', actor.damage > 0 and ('%.0f%%'):fmt(active * 100 / seconds) or '-');
    imgui.EndTable();

    if ((actor.pet_damage or 0) > 0) then
        local names = T{};
        for _, pet in ipairs(actor.pets) do
            names:append(pet.name);
        end
        imgui.TextColored(COLOR.muted, ('Includes %s: %s damage (%s)'):fmt(table.concat(names, ', '), theme.commas(actor.pet_damage), theme.percent(actor.pet_damage, actor.damage)));
    end
end

local function draw_graph(actor, segment, now, width, scale)
    local seconds = math.max(1, math.ceil(combat.duration(segment, now)));
    local prefix  = { [0] = 0 };
    for second = 0, seconds - 1 do
        prefix[second + 1] = prefix[second] + (actor.timeline[second] or 0);
    end

    local columns = math.max(2, math.min(seconds, math.floor(width / (3 * scale))));
    local values  = {};
    local peak    = 1;
    for column = 1, columns do
        local stop  = math.max(1, math.floor(column * seconds / columns));
        local start = math.max(0, stop - GRAPH_WINDOW);
        values[column] = (prefix[stop] - prefix[start]) / math.max(1, stop - start);
        peak = math.max(peak, values[column]);
    end

    theme.caption('DPS OVER TIME');
    local height = math.floor(GRAPH_HEIGHT * scale);
    local x, y   = theme.cursor();
    imgui.InvisibleButton('##pm_graph', { width, height });
    local hovered = imgui.IsItemHovered();

    local draw   = imgui.GetWindowDrawList();
    local color  = theme.job(actor.job).color;
    local top    = y + imgui.GetFontSize() + 4;
    local bottom = y + height - 3;
    local span   = bottom - top;
    local step   = width / columns;

    draw:AddRectFilled({ x, y }, { x + width, y + height }, theme.u32(COLOR.lane), 4);

    local mean = actor.damage / combat.duration(segment, now);
    local my   = bottom - span * math.min(1, mean / peak);
    draw:AddLine({ x + 4, my }, { x + width - 4, my }, theme.u32(theme.shade(COLOR.muted, 1.0, 0.7)), 1);

    local fill  = theme.u32(theme.shade(color, 1.0, 0.22));
    local line  = theme.u32(color);
    local prior = nil;
    for column = 1, columns do
        local px = x + (column - 0.5) * step;
        local py = bottom - span * values[column] / peak;
        draw:AddRectFilled({ x + (column - 1) * step, py }, { x + column * step, bottom }, fill);
        if (prior) then
            draw:AddLine(prior, { px, py }, line, 2);
        end
        prior = { px, py };
    end

    theme.label(draw, x + 6, y + 2, COLOR.muted, ('Peak %s'):fmt(theme.rate(peak)));
    local avg = ('Avg %s'):fmt(theme.rate(mean));
    theme.label(draw, x + width - 6 - theme.text_width(avg), y + 2, COLOR.muted, avg);

    if (hovered) then
        local mx     = theme.mouse();
        local column = math.max(1, math.min(columns, math.floor((mx - x) / step) + 1));
        local px     = x + (column - 0.5) * step;
        local py     = bottom - span * values[column] / peak;
        draw:AddLine({ px, top }, { px, bottom }, theme.u32(theme.shade(COLOR.peach, 1.0, 0.5)), 1);
        draw:AddCircleFilled({ px, py }, 4, theme.u32(COLOR.abyss), 12);
        draw:AddCircleFilled({ px, py }, 3, line, 12);
        imgui.BeginTooltip();
        imgui.TextColored(COLOR.muted, theme.clock(column * seconds / columns));
        imgui.TextColored(COLOR.text, ('%s DPS'):fmt(theme.rate(values[column])));
        imgui.EndTooltip();
    end
end

local function draw_legend(entries)
    local present = T{};
    for _, entry in ipairs(entries) do
        present[entry.kind] = true;
    end
    local draw  = imgui.GetWindowDrawList();
    local size  = imgui.GetFontSize();
    local first = true;
    for _, kind in ipairs(theme.KIND_ORDER) do
        if (present[kind]) then
            if (not first) then
                imgui.SameLine();
            end
            first = false;
            local x, y = theme.cursor();
            draw:AddRectFilled({ x, y + size * 0.2 }, { x + size * 0.6, y + size * 0.8 }, theme.u32(theme.KINDS[kind].color), 2);
            imgui.Dummy({ size * 0.6, size });
            imgui.SameLine();
            imgui.TextColored(COLOR.muted, theme.KINDS[kind].label);
        end
    end
end

local function draw_abilities(actor, scale, factor)
    local entries = sorted_entries(actor.abilities);
    draw_legend(entries);
    local items = T{};
    for _, entry in ipairs(entries) do
        items:append(T{
            key    = entry.key,
            left   = entry_label(entry),
            right  = ('%s (%s)'):fmt(theme.commas(entry.total), theme.percent(entry.total, actor.damage)),
            value  = entry.total,
            color  = kind_color(entry.kind),
            detail = function () ability_detail(entry, actor); end,
        });
    end
    bar_list('##pm_abilities', items, scale, factor);
end

local function accuracy_cells(entry)
    stat('Accuracy', theme.percent(entry.hits, entry.hits + entry.misses));
    stat('Crit Rate', theme.percent(entry.crits, entry.hits));
    stat('Avg Hit', average(entry.normal.total, entry.normal.count));
    stat('Max Hit', theme.commas(math.max(entry.normal.max, entry.crit.max)));
end

local function has_melee(actor)
    for _, entry in pairs(actor.abilities) do
        if (entry.kind == 'melee' or entry.kind == 'ranged') then
            return true;
        end
    end
    return false;
end

local function hand_attacks(book)
    local list = T{};
    for count = 1, combat.SWING_LIMIT do
        local label = HAND_ATTACKS[count] or ('%d attacks'):fmt(count);
        if (count == combat.SWING_LIMIT) then
            label = ('%d+ attacks'):fmt(count);
        end
        list:append(T{ key = tostring(count), label = label, count = book[count] or 0 });
    end
    return list;
end

local function attack_bars(id, attacks, total, color, scale, factor)
    local items = T{};
    for _, attack in ipairs(attacks) do
        if (attack.count > 0) then
            items:append(T{
                key   = attack.key,
                left  = attack.label,
                right = ('%s (%s)'):fmt(theme.percent(attack.count, total), theme.commas(attack.count)),
                value = attack.count,
                color = color,
                tip   = attack.tip,
            });
        end
    end
    bar_list(id, items, scale, factor, total);
end

local function hand_table(actor, h2h)
    local hands = actor.hands;
    local rows  = T{};
    if (hands.main.swings > 0) then
        rows:append(T{ h2h and 'Fists' or 'Main Hand', hands.main });
    end
    if (hands.off.swings > 0) then
        rows:append(T{ 'Off Hand', hands.off });
    end
    if (hands.kick.swings > 0) then
        rows:append(T{ 'Kicks', hands.kick });
    end
    if (hands.daken.swings > 0) then
        rows:append(T{ 'Daken', hands.daken });
    end

    local flags = bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersInnerH, ImGuiTableFlags_PadOuterX);
    if (#rows == 0 or not imgui.BeginTable('##pm_hands', 6, flags)) then
        return;
    end
    local number  = theme.text_width('00,000') + 8;
    local percent = theme.text_width('100.0%') + 8;
    imgui.TableSetupColumn('Hand', ImGuiTableColumnFlags_WidthStretch, 0, 0);
    imgui.TableSetupColumn('Swings', ImGuiTableColumnFlags_WidthFixed, math.max(number, theme.text_width('Swings') + 8), 0);
    imgui.TableSetupColumn('Acc.', ImGuiTableColumnFlags_WidthFixed, percent, 0);
    imgui.TableSetupColumn('Crit', ImGuiTableColumnFlags_WidthFixed, percent, 0);
    imgui.TableSetupColumn('Avg', ImGuiTableColumnFlags_WidthFixed, number, 0);
    imgui.TableSetupColumn('Max', ImGuiTableColumnFlags_WidthFixed, number, 0);
    imgui.TableHeadersRow();
    for _, row in ipairs(rows) do
        local hand = row[2];
        imgui.TableNextRow();
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.secondary, row[1]);
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.text, theme.commas(hand.swings));
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.text, theme.percent(hand.hits, hand.swings));
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.text, theme.percent(hand.crits, hand.hits));
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.text, average(hand.total, hand.hits));
        imgui.TableNextColumn();
        imgui.TextColored(COLOR.text, theme.commas(hand.max));
    end
    imgui.EndTable();
end

local function draw_melee(actor, scale, factor)
    local melee  = actor.abilities['melee'];
    local rounds = actor.rounds;
    local hands  = actor.hands;
    local color  = theme.job(actor.job).color;
    local multi  = combat.multi_attack(actor);

    if (melee) then
        theme.caption('MELEE');
        local swings = hands.main.swings + hands.off.swings + hands.kick.swings + hands.daken.swings;
        if (imgui.BeginTable('##pm_melee', 4, ImGuiTableFlags_SizingStretchSame)) then
            accuracy_cells(melee);
            stat('Rounds', theme.commas(rounds.count));
            stat('Per Round', rounds.count > 0 and ('%.2f'):fmt(swings / rounds.count) or '-');
            stat('Kick Rate', rounds.h2h > 0 and theme.percent(rounds.kick_rounds, rounds.h2h) or '-');
            stat('Daken Rate', rounds.daken_rounds > 0 and theme.percent(rounds.daken_rounds, rounds.measured) or '-');
            imgui.EndTable();
        end
        imgui.Spacing();
        hand_table(actor, rounds.h2h > multi.rounds);
    end

    if (multi.rounds > 0) then
        local main = hand_attacks(rounds.main);
        main[2].count = multi.double;
        table.insert(main, 3, T{
            key   = 'zanshin',
            label = 'Zanshin (estimated)',
            count = multi.zanshin,
            tip   = function ()
                imgui.TextColored(COLOR.secondary, 'Estimated. A Zanshin swing looks like a double attack in the packet.');
                imgui.TextColored(COLOR.muted, 'Counted from extra swings after a missed or countered first swing,');
                imgui.TextColored(COLOR.muted, 'minus the double attack rate seen on rounds that opened with a hit.');
                imgui.TextColored(COLOR.muted, ('%s of %s missed or countered first swings.'):fmt(theme.percent(multi.zanshin, multi.chances), theme.commas(multi.chances)));
            end,
        });

        theme.section('MAIN HAND MULTI-ATTACK');
        attack_bars('##pm_main_attacks', main, multi.rounds, color, scale, factor);
        if (rounds.dual > 0) then
            theme.section('OFF HAND MULTI-ATTACK');
            attack_bars('##pm_off_attacks', hand_attacks(rounds.off), rounds.dual, color, scale, factor);
        end
    end

    if (rounds.h2h > 0) then
        local fists = T{};
        for count = 1, combat.SWING_LIMIT do
            local label = 'Normal round';
            if (count == 1) then
                label = 'Single attack';
            elseif (count == 3) then
                label = '1 extra attack';
            elseif (count == combat.SWING_LIMIT) then
                label = ('%d+ extra attacks'):fmt(count - 2);
            elseif (count > 3) then
                label = ('%d extra attacks'):fmt(count - 2);
            end
            fists:append(T{ key = tostring(count), label = label, count = rounds.fists[count] or 0 });
        end

        theme.section('HAND-TO-HAND MULTI-ATTACK');
        attack_bars('##pm_fist_attacks', fists, rounds.h2h, color, scale, factor);
    end

    local ranged = actor.abilities['ranged'];
    if (ranged) then
        theme.section('RANGED');
        if (imgui.BeginTable('##pm_ranged', 4, ImGuiTableFlags_SizingStretchSame)) then
            accuracy_cells(ranged);
            imgui.EndTable();
        end
    end

    for _, entry in ipairs(sorted_entries(actor.abilities)) do
        if (entry.pet and (entry.kind == 'melee' or entry.kind == 'ranged')) then
            theme.section(('%s %s'):fmt(entry.pet:upper(), entry.kind == 'melee' and 'MELEE' or 'RANGED'));
            if (imgui.BeginTable('##pm_pet_' .. entry.key, 4, ImGuiTableFlags_SizingStretchSame)) then
                accuracy_cells(entry);
                imgui.EndTable();
            end
        end
    end
end

local function draw_targets(actor, scale, factor)
    local color = theme.job(actor.job).color;
    local items = T{};
    for _, target in ipairs(sorted_amounts(actor.targets)) do
        items:append(T{
            key   = target.name,
            left  = target.name,
            right = ('%s (%s)'):fmt(theme.commas(target.total), theme.percent(target.total, actor.damage)),
            value = target.total,
            color = color,
        });
    end
    bar_list('##pm_targets', items, scale, factor);
end

local function draw_healing(actor, segment, scale, factor)
    theme.caption('SPELLS & ABILITIES');
    local items = T{};
    for _, entry in ipairs(sorted_entries(actor.heals)) do
        items:append(T{
            key    = entry.key,
            left   = entry_label(entry),
            right  = ('%s (%s)'):fmt(theme.commas(entry.total), theme.percent(entry.total, actor.healing)),
            value  = entry.total,
            color  = kind_color(entry.kind),
            detail = function () heal_detail(entry, actor); end,
        });
    end
    bar_list('##pm_heals', items, scale, factor);

    theme.section('RECIPIENTS');
    local recipients = T{};
    for _, patient in ipairs(sorted_amounts(actor.healed)) do
        local other = segment.actors[patient.name];
        recipients:append(T{
            key   = patient.name,
            left  = patient.name,
            right = ('%s (%s)'):fmt(theme.commas(patient.total), theme.percent(patient.total, actor.healing)),
            value = patient.total,
            color = other and theme.job(other.job).color or COLOR.peach,
        });
    end
    bar_list('##pm_recipients', recipients, scale, factor);
end

local function draw_taken(actor, scale, factor)
    local d       = actor.defense;
    local landed  = d.hit + d.crit;
    local attacks = landed + d.evade + d.parry + d.shadow + d.anticipate + d.counter + d.intimidate;
    local biggest = 0;
    for _, entry in pairs(actor.sources) do
        biggest = math.max(biggest, entry.max);
    end

    if (imgui.BeginTable('##pm_defense', 4, ImGuiTableFlags_SizingStretchSame)) then
        stat('Taken', theme.commas(actor.taken));
        stat('Max Hit', theme.commas(biggest));
        stat('Evasion', theme.percent(d.evade, attacks));
        stat('Parry', theme.percent(d.parry, attacks));
        stat('Shadows', theme.commas(d.shadow));
        stat('Blocks', ('%d (%s)'):fmt(d.block, theme.percent(d.block, landed)));
        stat('Guards', ('%d (%s)'):fmt(d.guard, theme.percent(d.guard, landed)));
        stat('Counters', theme.commas(d.counter));
        stat('Crit Taken', theme.percent(d.crit, landed));
        stat('Anticipate', theme.commas(d.anticipate));
        stat('Resisted', theme.commas(d.resist));
        stat('Pet Taken', actor.merged and theme.commas(actor.pet_taken) or '-');
        imgui.EndTable();
    end

    theme.section('SOURCES');
    local entries = T{};
    for _, entry in pairs(actor.sources) do
        entries:append(entry);
    end
    table.sort(entries, function (a, b)
        if (a.total == b.total) then
            return a.key < b.key;
        end
        return a.total > b.total;
    end);

    local items = T{};
    for _, entry in ipairs(entries) do
        items:append(T{
            key   = entry.key,
            left  = ('%s: %s'):fmt(entry.foe, entry.name),
            right = ('%s (%s)'):fmt(theme.commas(entry.total), theme.percent(entry.total, actor.taken)),
            value = entry.total,
            color = kind_color(entry.kind),
            tip   = function ()
                imgui.TextColored(COLOR.peach, ('%s: %s'):fmt(entry.foe, entry.name));
                imgui.TextColored(COLOR.secondary, ('Hits %d  |  Crits %d  |  Max %s  |  Avoided %d'):fmt(entry.hits, entry.crits, theme.commas(entry.max), entry.avoided));
            end,
        });
    end
    bar_list('##pm_sources', items, scale, factor);
end

local function effect_items(list, debuff, color, seconds)
    local items = T{};
    for _, effect in ipairs(list) do
        if (effect.debuff == debuff) then
            items:append(T{
                key   = tostring(effect.id),
                left  = effect.name,
                right = ('%s (%s)'):fmt(theme.percent(effect.share, 1), theme.clock(effect.seconds)),
                value = effect.share,
                color = color,
                tip   = function ()
                    imgui.TextColored(COLOR.peach, effect.name);
                    imgui.TextColored(COLOR.secondary, ('Up %s of %s  |  Applied %d %s'):fmt(
                        theme.clock(effect.seconds), theme.clock(seconds), effect.count, effect.count == 1 and 'time' or 'times'));
                end,
            });
        end
    end
    return items;
end

local function draw_buffs(actor, segment, now, scale, factor)
    if (actor.kind ~= 'me' and actor.kind ~= 'party') then
        imgui.TextColored(COLOR.faint, 'The server only sends buffs for you and the players in your own party.');
        imgui.TextColored(COLOR.faint, 'Trusts, alliance members and pets are not included.');
        return;
    end

    local list    = combat.uptimes(segment, actor.key, now);
    local seconds = combat.duration(segment, now);
    if (#list == 0) then
        imgui.TextColored(COLOR.faint, 'No effects were active during this fight.');
        return;
    end

    local buffs   = effect_items(list, false, theme.job(actor.job).color, seconds);
    local debuffs = effect_items(list, true, COLOR.royal, seconds);
    theme.caption('BUFFS');
    bar_list('##pm_buffs', buffs, scale, factor, 1);
    if (#debuffs > 0) then
        theme.section('DEBUFFS');
        bar_list('##pm_debuffs', debuffs, scale, factor, 1);
    end
end

local function draw_deaths(actor)
    local flags = bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersInnerH, ImGuiTableFlags_PadOuterX);
    for index = #actor.death_log, 1, -1 do
        local death = actor.death_log[index];
        imgui.TextColored(COLOR.danger, SKULL);
        imgui.SameLine();
        imgui.TextColored(COLOR.secondary, ('Death %d  %s'):fmt(index, os.date('%H:%M:%S', death.stamp)));
        if (death.killer) then
            imgui.SameLine();
            imgui.TextColored(COLOR.muted, 'by ' .. death.killer);
        end

        if (#death.events == 0) then
            imgui.TextColored(COLOR.faint, 'Nothing was recorded before this death.');
        elseif (imgui.BeginTable(('##pm_death_%d'):fmt(index), 4, flags)) then
            imgui.TableSetupColumn('Time', ImGuiTableColumnFlags_WidthFixed, theme.text_width('-00.0s') + 4, 0);
            imgui.TableSetupColumn('Source', ImGuiTableColumnFlags_WidthStretch, 0, 0);
            imgui.TableSetupColumn('Action', ImGuiTableColumnFlags_WidthStretch, 0, 0);
            imgui.TableSetupColumn('Amount', ImGuiTableColumnFlags_WidthFixed, theme.text_width('-00,000') + 4, 0);
            imgui.TableHeadersRow();
            for _, event in ipairs(death.events) do
                imgui.TableNextRow();
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.muted, ('%.1fs'):fmt(event.time - death.time));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.secondary, event.who);
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.secondary, event.what);
                imgui.TableNextColumn();
                if (event.kind == 'heal') then
                    imgui.TextColored(COLOR.success, '+' .. theme.commas(event.amount));
                elseif (event.kind == 'avoid') then
                    imgui.TextColored(COLOR.muted, event.outcome);
                else
                    imgui.TextColored(event.kind == 'crit' and COLOR.ember or COLOR.danger, '-' .. theme.commas(event.amount));
                end
            end
            imgui.EndTable();
        end
        imgui.Spacing();
    end
end

local function magic_entries(actor)
    local enfeebles = T{};
    for _, entry in pairs(actor.enfeebles) do
        enfeebles:append(entry);
    end
    table.sort(enfeebles, function (a, b)
        if (a.uses == b.uses) then
            return a.key < b.key;
        end
        return a.uses > b.uses;
    end);

    local bursts = T{};
    for _, entry in ipairs(sorted_entries(actor.abilities)) do
        if (entry.bursts > 0) then
            bursts:append(entry);
        end
    end
    return enfeebles, bursts, sorted_entries(actor.closed);
end

local function draw_magic(actor)
    local enfeebles, bursts, chains = magic_entries(actor);
    local flags = bit.bor(ImGuiTableFlags_RowBg, ImGuiTableFlags_BordersInnerH, ImGuiTableFlags_PadOuterX);

    if (#enfeebles > 0) then
        theme.caption('ENFEEBLES');
        if (imgui.BeginTable('##pm_enfeebles', 5, flags)) then
            imgui.TableSetupColumn('Spell', ImGuiTableColumnFlags_WidthStretch, 0, 0);
            imgui.TableSetupColumn('Casts', ImGuiTableColumnFlags_WidthFixed, theme.text_width('Casts') + 8, 0);
            imgui.TableSetupColumn('Landed', ImGuiTableColumnFlags_WidthFixed, theme.text_width('Landed') + 8, 0);
            imgui.TableSetupColumn('Resisted', ImGuiTableColumnFlags_WidthFixed, theme.text_width('Resisted') + 8, 0);
            imgui.TableSetupColumn('Rate', ImGuiTableColumnFlags_WidthFixed, theme.text_width('100.0%') + 8, 0);
            imgui.TableHeadersRow();
            for _, entry in ipairs(enfeebles) do
                imgui.TableNextRow();
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.secondary, entry_label(entry));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.uses));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.landed));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.resists));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.percent(entry.landed, entry.landed + entry.resists));
            end
            imgui.EndTable();
        end
        imgui.Spacing();
    end

    if (#bursts > 0) then
        theme.caption('MAGIC BURSTS');
        if (imgui.BeginTable('##pm_bursts', 4, flags)) then
            imgui.TableSetupColumn('Action', ImGuiTableColumnFlags_WidthStretch, 0, 0);
            imgui.TableSetupColumn('Bursts', ImGuiTableColumnFlags_WidthFixed, theme.text_width('Bursts') + 8, 0);
            imgui.TableSetupColumn('Rate', ImGuiTableColumnFlags_WidthFixed, theme.text_width('100.0%') + 8, 0);
            imgui.TableSetupColumn('Damage', ImGuiTableColumnFlags_WidthFixed, theme.text_width('000,000') + 8, 0);
            imgui.TableHeadersRow();
            for _, entry in ipairs(bursts) do
                imgui.TableNextRow();
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.secondary, entry_label(entry));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.bursts));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.percent(entry.bursts, entry.hits));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.total));
            end
            imgui.EndTable();
        end
        imgui.Spacing();
    end

    if (#chains > 0) then
        theme.caption('SKILLCHAINS CLOSED');
        if (imgui.BeginTable('##pm_chains', 4, flags)) then
            imgui.TableSetupColumn('Skillchain', ImGuiTableColumnFlags_WidthStretch, 0, 0);
            imgui.TableSetupColumn('Count', ImGuiTableColumnFlags_WidthFixed, theme.text_width('Count') + 8, 0);
            imgui.TableSetupColumn('Avg', ImGuiTableColumnFlags_WidthFixed, theme.text_width('000,000') + 8, 0);
            imgui.TableSetupColumn('Max', ImGuiTableColumnFlags_WidthFixed, theme.text_width('000,000') + 8, 0);
            imgui.TableHeadersRow();
            for _, entry in ipairs(chains) do
                imgui.TableNextRow();
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.secondary, entry_label(entry));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.hits));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, average(entry.total, entry.hits));
                imgui.TableNextColumn();
                imgui.TextColored(COLOR.text, theme.commas(entry.normal.max));
            end
            imgui.EndTable();
        end
    end
end

local function draw_tabs(actor, segment, now, scale, factor)
    if (not imgui.BeginTabBar('##pm_tabs', ImGuiTabBarFlags_None)) then
        return;
    end

    if (imgui.BeginTabItem('Abilities')) then
        draw_abilities(actor, scale, factor);
        imgui.EndTabItem();
    end
    if (has_melee(actor) and imgui.BeginTabItem('Melee')) then
        draw_melee(actor, scale, factor);
        imgui.EndTabItem();
    end
    if (next(actor.targets) ~= nil and imgui.BeginTabItem('Targets')) then
        draw_targets(actor, scale, factor);
        imgui.EndTabItem();
    end
    if (actor.healing > 0 and imgui.BeginTabItem('Healing')) then
        draw_healing(actor, segment, scale, factor);
        imgui.EndTabItem();
    end
    if (next(actor.sources) ~= nil and imgui.BeginTabItem('Taken')) then
        draw_taken(actor, scale, factor);
        imgui.EndTabItem();
    end
    if (actor.kind ~= 'pet' and imgui.BeginTabItem('Buffs')) then
        draw_buffs(actor, segment, now, scale, factor);
        imgui.EndTabItem();
    end
    if (actor.deaths > 0 and imgui.BeginTabItem('Deaths')) then
        draw_deaths(actor);
        imgui.EndTabItem();
    end
    local enfeebles, bursts, chains = magic_entries(actor);
    if ((#enfeebles + #bursts + #chains) > 0 and imgui.BeginTabItem('Magic')) then
        draw_magic(actor);
        imgui.EndTabItem();
    end

    imgui.EndTabBar();
end

local function follow_meter(pm, placed)
    local x, y = theme.window_position();
    if (placed or not x or not y) then
        return;
    end
    if (pm.detail_pos and x == pm.detail_pos[1] and y == pm.detail_pos[2]) then
        return;
    end
    local dx = math.floor(x - pm.settings.x);
    local dy = math.floor(y - pm.settings.y);
    if (pm.settings.detail_custom and dx == pm.settings.detail_dx and dy == pm.settings.detail_dy) then
        return;
    end
    if (not pm.settings.detail_custom and dx == pm.detail_default_dx and dy == 0) then
        return;
    end
    pm.settings.detail_custom = true;
    pm.settings.detail_dx     = dx;
    pm.settings.detail_dy     = dy;
    if (os.clock() - pm.last_detail_save > 1.0) then
        pm.last_detail_save = os.clock();
        settings.save();
    end
end

function breakdown.render(pm, segment, now, factor)
    if (not pm.focus) then
        return;
    end

    local scale = pm.settings.scale;
    local width = BASE_WIDTH * scale;
    local outer = width + PADDING * 2;
    local actor = combat.lookup(segment, pm.focus, pm.settings.pets ~= 'separate');

    local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse);
    if (pm.settings.locked) then
        flags = bit.bor(flags, ImGuiWindowFlags_NoMove);
    end

    pm.detail_default_dx = math.floor((pm.meter_w or 0) + 8);
    local dx, dy = pm.detail_default_dx, 0;
    if (pm.settings.detail_custom) then
        dx, dy = pm.settings.detail_dx, pm.settings.detail_dy;
    end

    local color_count, var_count = theme.push(pm.settings.alpha);
    local display = imgui.GetIO().DisplaySize;
    local rect    = pm.detail_rect;
    local target  = nil;
    if (pm.place_detail or pm.meter_moved) then
        target = T{ pm.settings.x + dx, pm.settings.y + dy };
        if (not pm.settings.detail_custom and target[1] + outer > display.x) then
            target[1] = pm.settings.x - outer - 8;
        end
        pm.place_detail = false;
    elseif (pm.detail_grew and rect) then
        target = T{ rect[1], rect[2] };
    end
    if (target) then
        local height = rect and rect[4] or 0;
        pm.detail_pos = T{
            math.floor(math.max(0, math.min(target[1], display.x - outer))),
            math.floor(math.max(0, math.min(target[2], display.y - height))),
        };
        imgui.SetNextWindowPos({ pm.detail_pos[1], pm.detail_pos[2] }, ImGuiCond_Always);
    end
    local placed = target ~= nil;
    imgui.SetNextWindowSizeConstraints({ outer, 0 }, { outer, MAX_HEIGHT * scale });

    if (imgui.Begin('PhoenixMeter Breakdown##pm_breakdown', { true }, flags)) then
        local font      = imgui.GetFont();
        local font_size = imgui.GetFontSize() * scale;
        imgui.PushFont(font, font_size);

        local x, y = theme.window_position();
        local w, h = theme.window_size();
        local draw = imgui.GetWindowDrawList();
        draw:PushClipRect({ x, y }, { x + w, y + h }, false);
        draw:AddRectFilled({ x + 10, y }, { x + w - 10, y + 3 }, theme.u32(theme.job(actor and actor.job).color));
        draw:PopClipRect();

        draw_header(pm, actor, segment, now, width, scale);
        if (actor) then
            imgui.Spacing();
            draw_tiles(actor, segment, now);
            if (not segment.overall and actor.damage > 0) then
                imgui.Spacing();
                draw_graph(actor, segment, now, width, scale);
            end
            imgui.Spacing();
            draw_tabs(actor, segment, now, scale, factor);
        else
            imgui.TextColored(COLOR.faint, 'No activity in this fight.');
        end

        follow_meter(pm, placed);
        pm.detail_grew = pm.detail_rect == nil or h ~= pm.detail_rect[4];
        pm.detail_rect = T{ x, y, w, h };
        imgui.PopFont();
    end
    imgui.End();
    imgui.PopStyleVar(var_count);
    imgui.PopStyleColor(color_count);
end

return breakdown;
