require('common');

local imgui    = require('imgui');
local settings = require('settings');
local theme    = require('theme');
local combat   = require('combat');

local COLOR = theme.COLOR;

local MIN_WIDTH     = 340;
local MAX_WIDTH     = 720;
local PADDING       = theme.PADDING;
local ROW_HEIGHT    = 22;
local ROW_GAP       = 3;
local TIP_ROWS      = 6;
local DOT_RADIUS    = 3.5;
local COG           = ICON_FA_GEAR;
local COG_CODEPOINT = 0xF013;
local CARET         = ICON_FA_CARET_DOWN;

local MODES = T{
    T{ key = 'damage',  label = 'Damage Done'  },
    T{ key = 'dps',     label = 'DPS'          },
    T{ key = 'healing', label = 'Healing Done' },
    T{ key = 'taken',   label = 'Damage Taken' },
    T{ key = 'deaths',  label = 'Deaths'       },
};

local meter = T{
    MIN_WIDTH  = MIN_WIDTH,
    MAX_WIDTH  = MAX_WIDTH,
    rows       = T{},
    height     = nil,
};

function meter.mode(key)
    for _, mode in ipairs(MODES) do
        if (mode.key == key) then
            return mode;
        end
    end
    return nil;
end

function meter.mode_keys()
    local keys = T{};
    for _, mode in ipairs(MODES) do
        keys:append(mode.key);
    end
    return keys;
end

function meter.forget()
    meter.rows   = T{};
    meter.height = nil;
end

local function measure(mode, actor)
    if (mode == 'damage') then
        return actor.damage;
    elseif (mode == 'dps') then
        return actor.damage / combat.active_time(actor);
    elseif (mode == 'healing') then
        return actor.healing;
    elseif (mode == 'taken') then
        return actor.taken;
    end
    return actor.deaths;
end

local function describe(mode, actor, value, totals, seconds)
    if (mode == 'damage') then
        return ('%s (%s, %s)'):fmt(theme.short(value), theme.rate(value / seconds), theme.percent(value, totals.damage));
    elseif (mode == 'dps') then
        return ('%s (%s, %s)'):fmt(theme.rate(value), theme.short(actor.damage), theme.percent(actor.damage, totals.damage));
    elseif (mode == 'healing') then
        return ('%s (%s, %s)'):fmt(theme.short(value), theme.rate(value / seconds), theme.percent(value, totals.healing));
    elseif (mode == 'taken') then
        return ('%s (%s)'):fmt(theme.short(value), theme.percent(value, totals.taken));
    end
    return ('%d'):fmt(math.floor(value + 0.5));
end

local function collect(mode, segment, merge)
    local list   = T{};
    local totals = T{ damage = 0, healing = 0, taken = 0, deaths = 0 };
    for _, actor in ipairs(combat.rows(segment, merge)) do
        totals.damage  = totals.damage + actor.damage;
        totals.healing = totals.healing + actor.healing;
        totals.taken   = totals.taken + actor.taken;
        totals.deaths  = totals.deaths + actor.deaths;
        local value = measure(mode, actor);
        if (value > 0) then
            list:append(T{ actor = actor, value = value });
        end
    end
    table.sort(list, function (a, b)
        if (a.value == b.value) then
            return a.actor.key < b.actor.key;
        end
        return a.value > b.value;
    end);
    for index, item in ipairs(list) do
        item.rank = index;
    end
    return list, totals;
end

local function visible(list, limit, me)
    if (#list <= limit) then
        return list;
    end
    local shown = T{};
    for index = 1, limit do
        shown:append(list[index]);
    end
    for index = limit + 1, #list do
        if (list[index].actor.key == me) then
            shown[limit] = list[index];
        end
    end
    return shown;
end

local function top_entries(book, limit)
    local list = T{};
    for _, entry in pairs(book) do
        if (entry.total > 0) then
            list:append(entry);
        end
    end
    table.sort(list, function (a, b)
        if (a.total == b.total) then
            return a.key < b.key;
        end
        return a.total > b.total;
    end);
    while (#list > limit) do
        table.remove(list);
    end
    return list;
end

local function entry_label(entry)
    if (entry.pet) then
        return ('%s (%s)'):fmt(entry.name, entry.pet);
    end
    return entry.name;
end

local function draw_tooltip(mode, actor, seconds)
    imgui.BeginTooltip();
    imgui.TextColored(COLOR.peach, actor.name);
    imgui.SameLine();
    imgui.TextColored(COLOR.muted, theme.subtitle(actor));

    local rows = T{};
    if (mode == 'damage' or mode == 'dps') then
        imgui.TextColored(COLOR.secondary, ('Damage %s  |  DPS %s  |  Active DPS %s'):fmt(
            theme.commas(actor.damage),
            theme.rate(actor.damage / seconds),
            theme.rate(actor.damage / combat.active_time(actor))));

        local melee    = actor.abilities['melee'];
        local ranged   = actor.abilities['ranged'];
        local accuracy = T{};
        if (melee) then
            accuracy:append(('Melee Acc %s'):fmt(theme.percent(melee.hits, melee.hits + melee.misses)));
        end
        if (ranged) then
            accuracy:append(('Ranged Acc %s'):fmt(theme.percent(ranged.hits, ranged.hits + ranged.misses)));
        end
        if (#accuracy > 0) then
            imgui.TextColored(COLOR.secondary, table.concat(accuracy, '  |  '));
        end

        for _, entry in ipairs(top_entries(actor.abilities, TIP_ROWS)) do
            rows:append(T{ entry_label(entry), theme.commas(entry.total), theme.percent(entry.total, actor.damage) });
        end
        if ((actor.pet_damage or 0) > 0) then
            imgui.TextColored(COLOR.muted, ('Pets %s (%s)'):fmt(theme.commas(actor.pet_damage), theme.percent(actor.pet_damage, actor.damage)));
        end
    elseif (mode == 'healing') then
        imgui.TextColored(COLOR.secondary, ('Healing %s  |  HPS %s'):fmt(theme.commas(actor.healing), theme.rate(actor.healing / seconds)));
        for _, entry in ipairs(top_entries(actor.heals, TIP_ROWS)) do
            rows:append(T{ entry_label(entry), theme.commas(entry.total), theme.percent(entry.total, actor.healing) });
        end
    elseif (mode == 'taken') then
        imgui.TextColored(COLOR.secondary, ('Taken %s'):fmt(theme.commas(actor.taken)));
        for _, entry in ipairs(top_entries(actor.sources, TIP_ROWS)) do
            rows:append(T{ ('%s: %s'):fmt(entry.foe, entry.name), theme.commas(entry.total), theme.percent(entry.total, actor.taken) });
        end
    else
        local death = actor.death_log[#actor.death_log];
        if (death) then
            imgui.TextColored(COLOR.secondary, ('Last death %s%s'):fmt(os.date('%H:%M:%S', death.stamp), death.killer and (' by ' .. death.killer) or ''));
        end
    end

    if (#rows > 0 and imgui.BeginTable('##pm_tip', 3, ImGuiTableFlags_SizingFixedFit)) then
        for _, row in ipairs(rows) do
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(COLOR.secondary, row[1]);
            imgui.TableNextColumn();
            imgui.TextColored(COLOR.text, row[2]);
            imgui.TableNextColumn();
            imgui.TextColored(COLOR.muted, row[3]);
        end
        imgui.EndTable();
    end
    imgui.TextColored(COLOR.faint, 'Click for the full breakdown');
    imgui.EndTooltip();
end

local function segment_label(pm, segment)
    if (pm.segment == 'overall') then
        return 'Overall';
    end
    if (next(segment.actors) == nil) then
        return 'Current Fight';
    end
    return combat.name(segment);
end

local function setting_slider(pm, id, key, low, high, format, step, width, live)
    imgui.SetNextItemWidth(width);
    local buffer = { pm.pending[key] or pm.settings[key] };
    if (imgui.SliderFloat(('##pm_%s_%s'):fmt(id, key), buffer, low, high, format, ImGuiSliderFlags_AlwaysClamp)) then
        local value = math.floor(buffer[1] / step + 0.5) * step;
        if (live) then
            pm.settings[key] = value;
        else
            pm.pending[key] = value;
        end
    end
    if (imgui.IsItemDeactivatedAfterEdit()) then
        if (pm.pending[key]) then
            pm.settings[key] = pm.pending[key];
            pm.pending[key]  = nil;
        end
        settings.save();
    end
end

local function draw_header(pm, segment, width, scale)
    local cog_width = theme.text_width(COG) + 12 * scale;

    imgui.PushStyleColor(ImGuiCol_Button, COLOR.clear);
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, COLOR.tint);
    imgui.PushStyleColor(ImGuiCol_ButtonActive, COLOR.tint);
    imgui.PushStyleColor(ImGuiCol_Text, COLOR.peach);
    if (imgui.Button(('%s %s##pm_mode'):fmt(meter.mode(pm.settings.mode).label, CARET))) then
        imgui.OpenPopup('##pm_mode_menu');
    end
    imgui.PopStyleColor(1);

    imgui.SameLine();
    local x     = theme.cursor();
    local start = theme.window_position();
    local room  = width + PADDING - (x - start) - cog_width - 8 * scale - 2 * theme.FRAME_X - theme.text_width(' ' .. CARET);
    local label = theme.fit(segment_label(pm, segment), math.max(40, room));
    imgui.PushStyleColor(ImGuiCol_Text, COLOR.secondary);
    if (imgui.Button(('%s %s##pm_segment'):fmt(label, CARET))) then
        imgui.OpenPopup('##pm_segment_menu');
    end
    imgui.PopStyleColor(4);

    imgui.SameLine(PADDING + width - cog_width);
    if (theme.icon_button('##pm_settings', COG, COG_CODEPOINT, pm.show_settings, cog_width)) then
        pm.show_settings = not pm.show_settings;
    end

    if (imgui.BeginPopup('##pm_mode_menu')) then
        for _, mode in ipairs(MODES) do
            if (imgui.Selectable(mode.label, pm.settings.mode == mode.key)) then
                pm.settings.mode = mode.key;
                settings.save();
            end
        end
        imgui.EndPopup();
    end

    if (imgui.BeginPopup('##pm_segment_menu')) then
        if (imgui.Selectable('Current Fight', pm.segment == 'current')) then
            pm.segment = 'current';
        end
        if (imgui.Selectable('Overall', pm.segment == 'overall')) then
            pm.segment = 'overall';
        end
        local history = combat.history();
        if (#history > 0) then
            imgui.Separator();
        end
        for index, fight in ipairs(history) do
            local text = ('%s  %s##pm_fight_%d'):fmt(combat.name(fight), theme.clock(fight.ended - fight.started), index);
            if (imgui.Selectable(text, pm.segment == fight)) then
                pm.segment = fight;
            end
        end
        imgui.EndPopup();
    end
end

local SETTING_LABELS = T{ 'Scale', 'Opacity', 'Rows', 'Fight ends', 'Pets', 'Skillchains' };

local function label_column()
    local widest = 0;
    for _, label in ipairs(SETTING_LABELS) do
        widest = math.max(widest, theme.text_width(label));
    end
    return widest + 12;
end

local function settings_row(pm, label, key, low, high, format, step, width, live)
    local indent = label_column();
    imgui.AlignTextToFramePadding();
    imgui.TextColored(COLOR.muted, label);
    imgui.SameLine(PADDING + indent);
    setting_slider(pm, 'panel', key, low, high, format, step, width - indent, live);
end

local function set_pets(pm, choice)
    if (pm.settings.pets ~= choice) then
        pm.settings.pets = choice;
        settings.save();
    end
end

local function set_chains(pm, choice)
    if (pm.settings.chains ~= choice) then
        pm.settings.chains = choice;
        settings.save();
    end
end

local function draw_settings(pm, width)
    imgui.Spacing();
    theme.caption('SETTINGS');
    settings_row(pm, 'Scale', 'scale', 0.5, 3.0, '%.2f', 0.05, width, false);
    settings_row(pm, 'Opacity', 'alpha', 0.3, 1.0, '%.2f', 0.01, width, true);
    settings_row(pm, 'Rows', 'rows', 3, 25, '%.0f', 1, width, true);
    settings_row(pm, 'Fight ends', 'idle', 3, 30, '%.0f s idle', 1, width, true);

    local indent = label_column();
    local half   = (width - indent - 8) / 2;
    imgui.AlignTextToFramePadding();
    imgui.TextColored(COLOR.muted, 'Pets');
    imgui.SameLine(PADDING + indent);
    if (theme.toggle_button('Together##pm_pets_together', pm.settings.pets == 'together', half)) then
        set_pets(pm, 'together');
    end
    imgui.SameLine();
    if (theme.toggle_button('Separate##pm_pets_separate', pm.settings.pets == 'separate', half)) then
        set_pets(pm, 'separate');
    end

    local third = (width - indent - 16) / 3;
    imgui.AlignTextToFramePadding();
    imgui.TextColored(COLOR.muted, 'Skillchains');
    imgui.SameLine(PADDING + indent);
    if (theme.toggle_button('Split##pm_chains_split', pm.settings.chains == 'split', third)) then
        set_chains(pm, 'split');
    end
    imgui.SameLine();
    if (theme.toggle_button('Closer##pm_chains_closer', pm.settings.chains == 'closer', third)) then
        set_chains(pm, 'closer');
    end
    imgui.SameLine();
    if (theme.toggle_button('Ignored##pm_chains_ignored', pm.settings.chains == 'ignored', third)) then
        set_chains(pm, 'ignored');
    end

    imgui.Spacing();
    local clicked = theme.button_row('pm_panel', T{ 'Lock', 'Reset Position', 'Clear Fights' }, T{ pm.settings.locked, false, false }, width);
    if (clicked == 1) then
        pm.settings.locked = not pm.settings.locked;
        settings.save();
    elseif (clicked == 2) then
        pm.reset_position = true;
    elseif (clicked == 3) then
        pm.clear = true;
    end
    imgui.Spacing();
    imgui.Separator();
end

local function draw_row(list, x, y, width, height, badge, item, row, hovered, text, me)
    local actor = item.actor;
    local color = theme.job(actor.job).color;
    local chip  = theme.job(actor.job).abbr;
    local lane  = x + badge + 3;
    local ty    = y + (height - imgui.GetFontSize()) / 2;
    if (actor.kind == 'pet') then
        color = theme.shade(color, 0.75);
        chip  = 'PET';
    end

    theme.chip(list, x, y, x + badge, y + height, color, chip);
    theme.bar(list, lane, y, x + width, y + height, row.fraction, color, hovered);
    if (actor.key == me) then
        list:AddRectFilled({ lane, y + 2 }, { lane + 2, y + height - 2 }, theme.u32(COLOR.ember));
    end

    local value_width = theme.text_width(text);
    local name        = theme.fit(('%d. %s'):fmt(item.rank, theme.display_name(actor)), x + width - lane - value_width - 18);
    theme.label(list, lane + 6, ty, COLOR.text, name);
    theme.label(list, x + width - 6 - value_width, ty, COLOR.text, text);
end

local function draw_rows(pm, segment, now, width, scale, factor)
    local mode         = pm.settings.mode;
    local seconds      = combat.duration(segment, now);
    local list, totals = collect(mode, segment, pm.settings.pets ~= 'separate');
    local height  = math.floor(ROW_HEIGHT * scale);
    local step    = height + ROW_GAP;
    local me      = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0);
    local shown   = visible(list, math.floor(pm.settings.rows), me);
    local top     = list[1] and list[1].value or 1;
    local badge   = math.floor(theme.text_width('WAR') + 10 * scale);
    local x, y    = theme.cursor();
    local draw    = imgui.GetWindowDrawList();

    local target = math.max(height, #shown * step - ROW_GAP);
    meter.height = meter.height and theme.smooth(meter.height, target, factor) or target;

    for _, row in pairs(meter.rows) do
        row.seen = false;
    end

    local hovered_item = nil;
    meter.totals = totals;
    for index, item in ipairs(shown) do
        local key = item.actor.key;
        local row = meter.rows[key];
        if (not row) then
            row = T{ y = (index - 1) * step, fraction = 0, value = 0 };
            meter.rows[key] = row;
        end
        row.seen     = true;
        row.y        = theme.smooth(row.y, (index - 1) * step, factor);
        row.fraction = theme.smooth(row.fraction, item.value / top, factor);
        row.value    = theme.smooth(row.value, item.value, factor);
        if (math.abs(row.value - item.value) < 0.05) then
            row.value = item.value;
        end

        local ry = y + row.y;
        imgui.SetCursorScreenPos({ x, ry });
        if (imgui.InvisibleButton(('##pm_row_%s'):fmt(key), { width, height })) then
            if (pm.focus == key) then
                pm.focus = nil;
            elseif (pm.focus) then
                pm.focus = key;
            else
                pm.focus        = key;
                pm.place_detail = true;
            end
        end
        local hovered = imgui.IsItemHovered();
        if (hovered) then
            hovered_item = item;
        end
        draw_row(draw, x, ry, width, height, badge, item, row, hovered, describe(mode, item.actor, row.value, totals, seconds), me);
    end

    for key, row in pairs(meter.rows) do
        if (not row.seen) then
            meter.rows[key] = nil;
        end
    end

    if (#shown == 0) then
        local text = (next(segment.actors) == nil) and 'Waiting for combat' or 'Nothing to show for this mode';
        theme.bar(draw, x, y, x + width, y + height, 0, COLOR.faint, false);
        theme.label(draw, x + (width - theme.text_width(text)) / 2, y + (height - imgui.GetFontSize()) / 2, COLOR.muted, text);
    end

    imgui.SetCursorScreenPos({ x, y });
    imgui.Dummy({ width, math.max(1, meter.height) });

    if (hovered_item) then
        draw_tooltip(mode, hovered_item.actor, seconds);
    end
end

local function draw_grip(pm, width, size, scale)
    imgui.SameLine(PADDING + width - size);
    imgui.InvisibleButton('##pm_resize', { size, size });
    local hovered = imgui.IsItemHovered();
    local active  = imgui.IsItemActive();
    if (imgui.IsItemActivated()) then
        pm.resize_from = T{ theme.mouse(), pm.settings.width };
    end
    if (active and pm.resize_from) then
        local grown = (theme.mouse() - pm.resize_from[1]) / scale;
        pm.settings.width = math.floor(math.min(MAX_WIDTH, math.max(MIN_WIDTH, pm.resize_from[2] + grown)));
    end
    if (imgui.IsItemDeactivated()) then
        pm.resize_from = nil;
        settings.save();
    end
    if (hovered or active) then
        imgui.SetMouseCursor(ImGuiMouseCursor_ResizeEW);
    end

    local x0, y0 = imgui.GetItemRectMin();
    local x1, y1 = imgui.GetItemRectMax();
    local color  = (active and COLOR.ember) or (hovered and COLOR.muted) or COLOR.faint;
    imgui.GetWindowDrawList():AddTriangleFilled({ x1, y0 + 2 }, { x1, y1 }, { x0 + 2, y1 }, theme.u32(color));
end

local function draw_footer(pm, segment, now, width, scale, grip)
    local seconds = combat.duration(segment, now);
    local live    = combat.live(segment);
    local draw    = imgui.GetWindowDrawList();
    local size    = imgui.GetFontSize();
    local radius  = DOT_RADIUS * scale;
    local x, y    = theme.cursor();

    if (next(segment.actors) == nil) then
        imgui.TextColored(COLOR.faint, 'No fights recorded yet');
        if (grip > 0) then
            draw_grip(pm, width, grip, scale);
        end
        return;
    end

    local totals = meter.totals or T{ damage = 0, healing = 0, taken = 0, deaths = 0 };
    local dot    = COLOR.faint;
    if (live) then
        dot = theme.shade(COLOR.ember, 1.0, 0.45 + 0.55 * math.abs(math.sin(now * 3)));
    end
    draw:AddCircleFilled({ x + radius, y + size / 2 + 1 }, radius, theme.u32(dot), 12);
    imgui.Dummy({ radius * 2, size });
    imgui.SameLine();

    local mode  = pm.settings.mode;
    local parts = T{ theme.clock(seconds) };
    if (mode == 'damage' or mode == 'dps') then
        parts:append(theme.short(totals.damage));
        parts:append(('%s DPS'):fmt(theme.rate(totals.damage / seconds)));
    elseif (mode == 'healing') then
        parts:append(theme.short(totals.healing));
        parts:append(('%s HPS'):fmt(theme.rate(totals.healing / seconds)));
    elseif (mode == 'taken') then
        parts:append(('%s taken'):fmt(theme.short(totals.taken)));
    else
        parts:append(('%d %s'):fmt(totals.deaths, totals.deaths == 1 and 'death' or 'deaths'));
    end

    local kills       = ('%d %s'):fmt(segment.kills, segment.kills == 1 and 'kill' or 'kills');
    local kills_width = theme.text_width(kills);
    local kills_right = PADDING + width - ((grip > 0) and (grip + 6 * scale) or 0);
    local room        = kills_right - (theme.cursor() - theme.window_position()) - kills_width - 10 * scale;
    local summary     = table.concat(parts, '  |  ');
    if (theme.text_width(summary) > room) then
        summary = table.concat(parts, ' | ');
    end
    if (theme.text_width(summary) > room and #parts > 2) then
        summary = table.concat(T{ parts[1], parts[3] }, ' | ');
    end
    imgui.TextColored(COLOR.muted, summary);

    imgui.SameLine(kills_right - kills_width);
    imgui.TextColored(COLOR.muted, kills);
    if (grip > 0) then
        draw_grip(pm, width, grip, scale);
    end
end

local function draw_exp(pm, exp, width, scale, grip)
    local gained = ('%s exp'):fmt(theme.commas(exp.total));
    local right  = PADDING + width - ((grip > 0) and (grip + 6 * scale) or 0);
    local parts  = T{ ('%s exp/hr'):fmt(theme.short(exp.rate)) };
    if (exp.eta) then
        local minutes = math.max(1, math.floor(exp.eta / 60 + 0.5));
        local wait    = ('%dm'):fmt(minutes);
        if (minutes >= 60) then
            wait = ('%dh %02dm'):fmt(math.floor(minutes / 60), minutes % 60);
        end
        parts:append(('%s to %s'):fmt(wait, exp.goal));
    end

    imgui.Dummy({ DOT_RADIUS * 2 * scale, imgui.GetFontSize() });
    imgui.SameLine();
    local room    = right - (theme.cursor() - theme.window_position()) - theme.text_width(gained) - 10 * scale;
    local summary = table.concat(parts, '  |  ');
    if (theme.text_width(summary) > room) then
        summary = table.concat(parts, ' | ');
    end
    imgui.TextColored(COLOR.muted, summary);
    if (theme.text_width(summary) <= room) then
        imgui.SameLine(right - theme.text_width(gained));
        imgui.TextColored(COLOR.muted, gained);
    end
    if (grip > 0) then
        draw_grip(pm, width, grip, scale);
    end
end

local function draw_context_menu(pm)
    if (not imgui.BeginPopupContextWindow('##pm_context')) then
        return;
    end
    if (imgui.MenuItem('Lock Window', nil, pm.settings.locked)) then
        pm.settings.locked = not pm.settings.locked;
        settings.save();
    end
    if (imgui.MenuItem('Merge Pets Into Owners', nil, pm.settings.pets == 'together')) then
        set_pets(pm, pm.settings.pets == 'together' and 'separate' or 'together');
    end
    if (imgui.BeginMenu('Skillchain Damage')) then
        if (imgui.MenuItem('Split Opener / Closer', nil, pm.settings.chains == 'split')) then
            set_chains(pm, 'split');
        end
        if (imgui.MenuItem('Closer Only', nil, pm.settings.chains == 'closer')) then
            set_chains(pm, 'closer');
        end
        if (imgui.MenuItem('Ignored', nil, pm.settings.chains == 'ignored')) then
            set_chains(pm, 'ignored');
        end
        imgui.EndMenu();
    end
    if (imgui.MenuItem('Report to Party')) then
        pm.report = T{ channel = 'p' };
    end
    if (imgui.MenuItem('Clear Fights')) then
        pm.clear = true;
    end
    if (imgui.MenuItem('Reset Position')) then
        pm.reset_position = true;
    end
    if (imgui.MenuItem('Hide')) then
        pm.settings.visible = false;
        settings.save();
    end
    imgui.Separator();
    imgui.TextColored(COLOR.muted, 'Scale');
    setting_slider(pm, 'menu', 'scale', 0.5, 3.0, '%.2f', 0.05, 160, false);
    imgui.TextColored(COLOR.muted, 'Opacity');
    setting_slider(pm, 'menu', 'alpha', 0.3, 1.0, '%.2f', 0.01, 160, true);
    imgui.EndPopup();
end

local function remember_position(pm)
    local w = theme.window_size();
    if (w ~= pm.meter_w) then
        pm.meter_moved = true;
    end
    pm.meter_w = w;
    local x, y = theme.window_position();
    if (not x or not y) then
        return;
    end
    x = math.floor(x);
    y = math.floor(y);
    if (x == pm.settings.x and y == pm.settings.y) then
        return;
    end
    pm.settings.x  = x;
    pm.settings.y  = y;
    pm.meter_moved = true;
    if (os.clock() - pm.last_pos_save > 1.0) then
        pm.last_pos_save = os.clock();
        settings.save();
    end
end

local function draw_accent(color)
    local x, y = theme.window_position();
    local w, h = theme.window_size();
    local draw = imgui.GetWindowDrawList();
    draw:PushClipRect({ x, y }, { x + w, y + h }, false);
    draw:AddRectFilled({ x + 10, y }, { x + w - 10, y + 2 }, theme.u32(color));
    draw:PopClipRect();
end

meter.draw_accent = draw_accent;

function meter.render(pm, segment, now, factor)
    local scale = pm.settings.scale;
    local width = pm.settings.width * scale;

    local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse, ImGuiWindowFlags_NoFocusOnAppearing);
    if (pm.settings.locked) then
        flags = bit.bor(flags, ImGuiWindowFlags_NoMove);
    end

    local color_count, var_count = theme.push(pm.settings.alpha);
    if (pm.place_window) then
        imgui.SetNextWindowPos({ pm.settings.x, pm.settings.y }, ImGuiCond_Always);
        pm.place_window = false;
    end

    if (imgui.Begin('PhoenixMeter##phoenixmeter', { true }, flags)) then
        local font      = imgui.GetFont();
        local font_size = imgui.GetFontSize() * scale;
        imgui.PushFont(font, font_size);
        draw_accent(COLOR.ember);
        draw_header(pm, segment, width, scale);
        if (pm.show_settings) then
            draw_settings(pm, width);
        end
        draw_rows(pm, segment, now, width, scale, factor);
        imgui.Spacing();
        local grip = (not pm.settings.locked) and math.floor(imgui.GetFontSize()) or 0;
        local exp  = combat.exp(now);
        if (exp.total > 0) then
            draw_footer(pm, segment, now, width, scale, 0);
            draw_exp(pm, exp, width, scale, grip);
        else
            draw_footer(pm, segment, now, width, scale, grip);
        end
        draw_context_menu(pm);
        remember_position(pm);
        imgui.PopFont();
    end
    imgui.End();
    imgui.PopStyleVar(var_count);
    imgui.PopStyleColor(color_count);
end

function meter.report(pm, segment, now, count)
    local mode    = pm.settings.mode;
    local seconds = combat.duration(segment, now);
    local list, totals = collect(mode, segment, pm.settings.pets ~= 'separate');
    local lines   = T{};
    if (#list == 0) then
        return lines;
    end
    lines:append(('PhoenixMeter: %s, %s (%s)'):fmt(meter.mode(mode).label, segment_label(pm, segment), theme.clock(seconds)));
    for index = 1, math.min(count, #list) do
        local item = list[index];
        lines:append(('%d. %s %s'):fmt(item.rank, theme.display_name(item.actor), describe(mode, item.actor, item.value, totals, seconds)));
    end
    return lines;
end

return meter;
