require('common');

local imgui       = require('imgui');
local settings    = require('settings');
local theme       = require('theme');
local combat      = require('combat');
local skillchains = require('skillchains');
local meter       = require('meter');

local COLOR = theme.COLOR;

local WIDTH      = 250;
local PADDING    = theme.PADDING;
local BAR_HEIGHT = 6;
local MAX_ROWS   = 8;
local GAP        = 8;
local EMPTY      = 'None of your weaponskills chain';
local LEVEL      = 'Lv.0';
local TIMER      = 'Wait 0.0';

local SAMPLE = T{
    title     = 'Skillchain Popup',
    who       = 'drag to place',
    resonance = T{ T{ skillchains.name(4), theme.CHAINS[4] } },
    rows      = T{
        T{ name = 'Decimation',    result = skillchains.name(5), color = theme.CHAINS[5], level = 'Lv.1' },
        T{ name = 'Steel Cyclone', result = skillchains.name(6), color = theme.CHAINS[6], level = 'Lv.1' },
    },
    more      = 0,
};

local popup = T{};

local function target_id()
    local memory = AshitaCore:GetMemoryManager();
    local target = memory:GetTarget();
    local slot   = (target:GetIsSubTargetActive() == 0) and 0 or 1;
    return memory:GetEntity():GetServerId(target:GetTargetIndex(slot));
end

local function sample_window(now)
    local started = now - now % skillchains.WINDOW;
    return T{ started = started, opens = started + skillchains.WAIT, closes = started + skillchains.WINDOW };
end

local function resonance_of(window)
    local parts = T{};
    if (window.bound) then
        parts:append(T{ 'Chainbound', COLOR.muted });
        return parts;
    end

    for index, property in ipairs(window.properties) do
        if (index > 1) then
            parts:append(T{ ' / ', COLOR.faint });
        end
        parts:append(T{ skillchains.name(property), theme.CHAINS[property] });
    end
    if (window.element) then
        parts:append(T{ ('  Lv.%d'):fmt(skillchains.level(window.element)), COLOR.muted });
    end
    return parts;
end

local function view_of(window)
    local player  = AshitaCore:GetMemoryManager():GetPlayer();
    local options = skillchains.options(window.properties, function (id)
        return player:HasWeaponSkill(id);
    end);

    local view = T{
        title     = window.label or 'Skillchain',
        who       = theme.display_name(window.who),
        resonance = resonance_of(window),
        rows      = T{},
        more      = math.max(0, #options - MAX_ROWS),
    };
    for index = 1, math.min(MAX_ROWS, #options) do
        local option = options[index];
        view.rows:append(T{
            name   = combat.skill_name(option.id),
            result = skillchains.name(option.element),
            color  = theme.CHAINS[option.element],
            level  = ('Lv.%d'):fmt(option.level),
        });
    end
    return view;
end

local function width_of(view, scale)
    local level     = theme.text_width(LEVEL);
    local resonance = 0;
    for _, part in ipairs(view.resonance) do
        resonance = resonance + theme.text_width(part[1]);
    end

    local width = math.max(WIDTH * scale, resonance, theme.text_width(view.title) + theme.text_width(view.who) + theme.text_width(TIMER) + GAP * 3);
    for _, row in ipairs(view.rows) do
        width = math.max(width, theme.text_width(row.name) + theme.text_width(row.result) + level + GAP * 3);
    end
    if (#view.rows == 0) then
        width = math.max(width, theme.text_width(EMPTY));
    end
    return width;
end

local function draw_header(view, window, now, width)
    local ready = now >= window.opens;
    local timer = ready and ('Go %.1f'):fmt(window.closes - now) or ('Wait %.1f'):fmt(window.opens - now);

    imgui.TextColored(COLOR.text, view.title);
    imgui.SameLine();
    imgui.TextColored(COLOR.muted, view.who);
    imgui.SameLine(PADDING + width - theme.text_width(timer));
    imgui.TextColored(ready and COLOR.success or COLOR.muted, timer);
end

local function draw_resonance(view)
    for index, part in ipairs(view.resonance) do
        if (index > 1) then
            imgui.SameLine(0, 0);
        end
        imgui.TextColored(part[2], part[1]);
    end
end

local function draw_timer(window, now, width, scale)
    local x, y   = theme.cursor();
    local height = math.floor(BAR_HEIGHT * scale);
    local draw   = imgui.GetWindowDrawList();
    if (now < window.opens) then
        theme.bar(draw, x, y, x + width, y + height, (now - window.started) / (window.opens - window.started), COLOR.muted, false);
    else
        theme.bar(draw, x, y, x + width, y + height, (window.closes - now) / (window.closes - window.opens), COLOR.success, false);
    end
    imgui.Dummy({ width, height });
end

local function draw_rows(view, width)
    if (#view.rows == 0) then
        imgui.TextColored(COLOR.faint, EMPTY);
        return;
    end

    local level = theme.text_width(LEVEL);
    for _, row in ipairs(view.rows) do
        imgui.TextColored(COLOR.text, row.name);
        imgui.SameLine(PADDING + width - level - GAP - theme.text_width(row.result));
        imgui.TextColored(row.color, row.result);
        imgui.SameLine(PADDING + width - level);
        imgui.TextColored(COLOR.muted, row.level);
    end
    if (view.more > 0) then
        imgui.TextColored(COLOR.faint, ('+%d more'):fmt(view.more));
    end
end

local function remember_position(pm)
    local x, y = theme.window_position();
    if (not x or not y) then
        return;
    end
    x = math.floor(x);
    y = math.floor(y);
    if (pm.popup_pos and x == pm.popup_pos[1] and y == pm.popup_pos[2]) then
        return;
    end
    pm.popup_pos             = T{ x, y };
    pm.settings.popup_custom = true;
    pm.settings.popup_x      = x;
    pm.settings.popup_y      = y;
    if (os.clock() - pm.last_popup_save > 1.0) then
        pm.last_popup_save = os.clock();
        settings.save();
    end
end

function popup.render(pm, now)
    if (not pm.settings.popup) then
        return;
    end

    local window  = combat.window(target_id(), now);
    local preview = pm.show_settings and pm.settings.visible;
    if (not window and not preview) then
        return;
    end

    local scale = pm.settings.popup_scale;

    local flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoScrollWithMouse, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav);
    if (pm.settings.locked) then
        flags = bit.bor(flags, ImGuiWindowFlags_NoMove);
    end

    local color_count, var_count = theme.push(pm.settings.alpha);
    if (pm.place_popup) then
        local x, y = pm.settings.popup_x, pm.settings.popup_y;
        if (not pm.settings.popup_custom) then
            local display = imgui.GetIO().DisplaySize;
            x = math.floor((display.x - WIDTH * scale) / 2 - PADDING);
            y = math.floor(display.y * 0.25);
        end
        pm.popup_pos = T{ x, y };
        imgui.SetNextWindowPos({ x, y }, ImGuiCond_Always);
        pm.place_popup = false;
    end

    if (imgui.Begin('PhoenixMeter Skillchain##pm_popup', { true }, flags)) then
        local font      = imgui.GetFont();
        local font_size = imgui.GetFontSize() * scale;
        imgui.PushFont(font, font_size);

        local view = SAMPLE;
        if (window) then
            view = view_of(window);
        else
            window = sample_window(now);
        end
        local width = width_of(view, scale);

        meter.draw_accent((now >= window.opens) and COLOR.success or COLOR.ember);
        draw_header(view, window, now, width);
        draw_resonance(view);
        draw_timer(window, now, width, scale);
        draw_rows(view, width);

        remember_position(pm);
        imgui.PopFont();
    end
    imgui.End();
    imgui.PopStyleVar(var_count);
    imgui.PopStyleColor(color_count);
end

return popup;
