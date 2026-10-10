require('common');

local imgui = require('imgui');

local theme = T{
    PADDING = 14,
    FRAME_X = 6,
};

local function rgb(hex, alpha)
    return {
        tonumber(hex:sub(1, 2), 16) / 255,
        tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255,
        alpha or 1.0,
    };
end

local function shade(color, factor, alpha)
    return {
        math.min(1, color[1] * factor),
        math.min(1, color[2] * factor),
        math.min(1, color[3] * factor),
        alpha or color[4] or 1.0,
    };
end

theme.rgb   = rgb;
theme.shade = shade;

theme.COLOR = T{
    abyss     = rgb('180e0e'),
    surface1  = rgb('291c1c'),
    surface2  = rgb('321f1f'),
    lane      = rgb('211515'),
    border    = rgb('d2abab', 0.20),
    subtle    = rgb('d2abab', 0.12),
    text      = rgb('fff8f8'),
    secondary = rgb('eae1e1'),
    peach     = rgb('d2abab'),
    muted     = rgb('8a6b6b'),
    faint     = rgb('5a4545'),
    royal     = rgb('c55151'),
    tint      = rgb('c55151', 0.30),
    hover     = rgb('d45e5e'),
    ember     = rgb('ff8d79'),
    danger    = rgb('e04040'),
    gold      = rgb('c5a131'),
    success   = rgb('63ba8a'),
    outline   = rgb('0d0707', 0.85),
    clear     = { 0, 0, 0, 0 },
};

theme.JOBS = T{
    [0]  = T{ abbr = '---', color = rgb('8a6b6b') },
    [1]  = T{ abbr = 'WAR', color = rgb('c69b6d') },
    [2]  = T{ abbr = 'MNK', color = rgb('d8683f') },
    [3]  = T{ abbr = 'WHM', color = rgb('dfcfb0') },
    [4]  = T{ abbr = 'BLM', color = rgb('6e4d88') },
    [5]  = T{ abbr = 'RDM', color = rgb('a92738') },
    [6]  = T{ abbr = 'THF', color = rgb('cdbb2a') },
    [7]  = T{ abbr = 'PLD', color = rgb('0787bf') },
    [8]  = T{ abbr = 'DRK', color = rgb('b258b4') },
    [9]  = T{ abbr = 'BST', color = rgb('7f5303') },
    [10] = T{ abbr = 'BRD', color = rgb('962b7a') },
    [11] = T{ abbr = 'RNG', color = rgb('75a823') },
    [12] = T{ abbr = 'SAM', color = rgb('b45d6c') },
    [13] = T{ abbr = 'NIN', color = rgb('3953ba') },
    [14] = T{ abbr = 'DRG', color = rgb('5f91fa') },
    [15] = T{ abbr = 'SMN', color = rgb('336c3a') },
    [16] = T{ abbr = 'BLU', color = rgb('0d807e') },
    [17] = T{ abbr = 'COR', color = rgb('4bd2a0') },
    [18] = T{ abbr = 'PUP', color = rgb('a37ee1') },
    [19] = T{ abbr = 'DNC', color = rgb('e56389') },
    [20] = T{ abbr = 'SCH', color = rgb('785dcc') },
    [21] = T{ abbr = 'GEO', color = rgb('169338') },
    [22] = T{ abbr = 'RUN', color = rgb('0fa8bb') },
};

theme.KINDS = T{
    melee    = T{ label = 'Melee',        color = rgb('c55151') },
    ranged   = T{ label = 'Ranged',       color = rgb('3aa39a') },
    ws       = T{ label = 'Weapon Skill', color = rgb('c5a131') },
    spell    = T{ label = 'Magic',        color = rgb('f08a6c') },
    ja       = T{ label = 'Ability',      color = rgb('9c8f7a') },
    sc       = T{ label = 'Skillchain',   color = rgb('9a7ee0') },
    add      = T{ label = 'Add. Effect',  color = rgb('c6609a') },
    reactive = T{ label = 'Reactive',     color = rgb('4f86d0') },
};

theme.KIND_ORDER = T{ 'melee', 'ranged', 'ws', 'spell', 'ja', 'sc', 'add', 'reactive' };

theme.CHAINS = T{
    [1]  = rgb('e9e2c8'),
    [2]  = rgb('9a8fb5'),
    [3]  = rgb('f0604f'),
    [4]  = rgb('c9a640'),
    [5]  = rgb('4f86e0'),
    [6]  = rgb('72d67c'),
    [7]  = rgb('7fe0ea'),
    [8]  = rgb('e070e8'),
    [9]  = rgb('b98a5a'),
    [10] = rgb('5aa8f2'),
    [11] = rgb('ff8a3d'),
    [12] = rgb('f29ce8'),
    [13] = rgb('fff3c4'),
    [14] = rgb('8f7fe0'),
    [15] = rgb('fff3c4'),
    [16] = rgb('8f7fe0'),
};

function theme.job(id)
    return theme.JOBS[id or 0] or theme.JOBS[0];
end

function theme.jobs_text(actor)
    local text = ('%s%d'):fmt(theme.job(actor.job).abbr, actor.level or 0);
    if ((actor.sub or 0) > 0) then
        text = ('%s/%s%d'):fmt(text, theme.job(actor.sub).abbr, actor.sublevel or 0);
    end
    return text;
end

function theme.display_name(actor)
    if (actor.kind == 'pet') then
        return ('%s (%s)'):fmt(actor.name, actor.owner);
    end
    return actor.name;
end

function theme.subtitle(actor)
    if (actor.kind == 'pet') then
        return ("%s's pet"):fmt(actor.owner);
    end
    return theme.jobs_text(actor);
end

function theme.u32(color)
    return imgui.GetColorU32(color);
end

function theme.text_width(text)
    local width = imgui.CalcTextSize(text);
    if (type(width) == 'table') then
        return width.x or width[1] or 0;
    end
    return width or 0;
end

function theme.fit(text, width)
    if (theme.text_width(text) <= width) then
        return text;
    end
    local cut = #text;
    while (cut > 1 and theme.text_width(text:sub(1, cut) .. '..') > width) do
        cut = cut - 1;
    end
    return text:sub(1, cut) .. '..';
end

function theme.commas(value)
    local text   = ('%d'):fmt(math.floor(value + 0.5));
    local sign   = text:sub(1, 1) == '-' and '-' or '';
    local digits = text:gsub('^-', ''):reverse():gsub('(%d%d%d)', '%1,'):reverse();
    return sign .. digits:gsub('^,', '');
end

function theme.short(value)
    if (value >= 1000000) then
        return ('%.2fM'):fmt(value / 1000000);
    end
    if (value >= 100000) then
        return ('%.1fK'):fmt(value / 1000);
    end
    return theme.commas(value);
end

function theme.rate(value)
    if (value >= 1000) then
        return theme.short(value);
    end
    return ('%.1f'):fmt(value);
end

function theme.percent(part, total)
    if (not total or total <= 0) then
        return '-';
    end
    return ('%.1f%%'):fmt(part * 100 / total);
end

function theme.clock(seconds)
    seconds = math.max(0, math.floor(seconds));
    if (seconds >= 3600) then
        return ('%d:%02d:%02d'):fmt(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60);
    end
    return ('%d:%02d'):fmt(math.floor(seconds / 60), seconds % 60);
end

function theme.smooth(current, target, factor)
    return current + (target - current) * factor;
end

function theme.label(list, x, y, color, text)
    local outline = theme.u32(theme.COLOR.outline);
    list:AddText({ x - 1, y }, outline, text);
    list:AddText({ x + 1, y }, outline, text);
    list:AddText({ x, y - 1 }, outline, text);
    list:AddText({ x, y + 1 }, outline, text);
    list:AddText({ x, y }, theme.u32(color), text);
end

function theme.bar(list, x0, y0, x1, y1, fraction, color, hovered)
    local rounding = 3;
    list:AddRectFilled({ x0, y0 }, { x1, y1 }, theme.u32(theme.COLOR.lane), rounding);

    local fill = x0 + (x1 - x0) * math.max(0, math.min(1, fraction));
    if (fill - x0 >= 2) then
        list:AddRectFilled({ x0, y0 }, { fill, y1 }, theme.u32(shade(color, 0.55)), rounding);
        if (fill - x0 >= 4) then
            local top    = theme.u32(shade(color, 1.10));
            local bottom = theme.u32(shade(color, 0.78));
            list:AddRectFilledMultiColor({ x0 + 1, y0 + 1 }, { fill - 1, y1 - 1 }, top, top, bottom, bottom);
        end
    end

    if (hovered) then
        list:AddRect({ x0, y0 }, { x1, y1 }, theme.u32(theme.COLOR.ember), rounding, 0, 1.0);
    end
end

function theme.chip(list, x0, y0, x1, y1, color, text)
    list:AddRectFilled({ x0, y0 }, { x1, y1 }, theme.u32(shade(color, 0.85)), 3);
    local y = y0 + (y1 - y0 - imgui.GetFontSize()) / 2;
    theme.label(list, x0 + (x1 - x0 - theme.text_width(text)) / 2, y, theme.COLOR.text, text);
end

function theme.push(alpha)
    local COLOR  = theme.COLOR;
    local colors = {
        { ImGuiCol_WindowBg,                  { COLOR.abyss[1], COLOR.abyss[2], COLOR.abyss[3], alpha } },
        { ImGuiCol_ChildBg,                   COLOR.clear    },
        { ImGuiCol_TitleBg,                   COLOR.surface1 },
        { ImGuiCol_TitleBgActive,             COLOR.surface2 },
        { ImGuiCol_TitleBgCollapsed,          COLOR.surface1 },
        { ImGuiCol_Border,                    COLOR.border   },
        { ImGuiCol_Separator,                 COLOR.border   },
        { ImGuiCol_Text,                      COLOR.text     },
        { ImGuiCol_TextDisabled,              COLOR.muted    },
        { ImGuiCol_FrameBg,                   COLOR.surface2 },
        { ImGuiCol_FrameBgHovered,            COLOR.tint     },
        { ImGuiCol_FrameBgActive,             COLOR.surface2 },
        { ImGuiCol_SliderGrab,                COLOR.royal    },
        { ImGuiCol_SliderGrabActive,          COLOR.hover    },
        { ImGuiCol_PlotHistogram,             COLOR.royal    },
        { ImGuiCol_Header,                    COLOR.surface2 },
        { ImGuiCol_HeaderHovered,             COLOR.tint     },
        { ImGuiCol_HeaderActive,              COLOR.royal    },
        { ImGuiCol_TableHeaderBg,             COLOR.surface2 },
        { ImGuiCol_TableBorderLight,          COLOR.subtle   },
        { ImGuiCol_TableBorderStrong,         COLOR.border   },
        { ImGuiCol_TableRowBg,                COLOR.clear    },
        { ImGuiCol_TableRowBgAlt,             COLOR.surface1 },
        { ImGuiCol_PopupBg,                   COLOR.surface1 },
        { ImGuiCol_CheckMark,                 COLOR.royal    },
        { ImGuiCol_Button,                    COLOR.royal    },
        { ImGuiCol_ButtonHovered,             COLOR.hover    },
        { ImGuiCol_ButtonActive,              COLOR.royal    },
        { ImGuiCol_Tab,                       COLOR.surface1 },
        { ImGuiCol_TabHovered,                COLOR.tint     },
        { ImGuiCol_TabSelected,               COLOR.surface2 },
        { ImGuiCol_TabSelectedOverline,       COLOR.ember    },
        { ImGuiCol_TabDimmed,                 COLOR.surface1 },
        { ImGuiCol_TabDimmedSelected,         COLOR.surface2 },
        { ImGuiCol_TabDimmedSelectedOverline, COLOR.royal    },
        { ImGuiCol_ScrollbarBg,               COLOR.abyss    },
        { ImGuiCol_ScrollbarGrab,             COLOR.surface2 },
        { ImGuiCol_ScrollbarGrabHovered,      COLOR.tint     },
        { ImGuiCol_ScrollbarGrabActive,       COLOR.royal    },
        { ImGuiCol_ResizeGrip,                COLOR.clear    },
    };
    for _, color in ipairs(colors) do
        imgui.PushStyleColor(color[1], color[2]);
    end

    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 8.0);
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 4.0);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { theme.PADDING, 12 });
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, { 8, 6 });
    imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { theme.FRAME_X, 4 });
    imgui.PushStyleVar(ImGuiStyleVar_CellPadding, { 8, 4 });
    imgui.PushStyleVar(ImGuiStyleVar_TabRounding, 4.0);
    imgui.PushStyleVar(ImGuiStyleVar_GrabMinSize, 6.0);
    imgui.PushStyleVar(ImGuiStyleVar_GrabRounding, 3.0);

    return #colors, 9;
end

function theme.toggle_button(label, on, width)
    local COLOR = theme.COLOR;
    imgui.PushStyleColor(ImGuiCol_Button, on and COLOR.royal or COLOR.surface2);
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, on and COLOR.hover or COLOR.tint);
    imgui.PushStyleColor(ImGuiCol_ButtonActive, COLOR.royal);
    imgui.PushStyleColor(ImGuiCol_Text, on and COLOR.text or COLOR.muted);
    local clicked = imgui.Button(label, { width, 0 });
    imgui.PopStyleColor(4);
    return clicked;
end

function theme.button_row(id, labels, states, width)
    local gap    = 8;
    local widths = T{};
    local total  = gap * (#labels - 1);
    for index, label in ipairs(labels) do
        widths[index] = theme.text_width(label) + theme.FRAME_X * 2;
        total = total + widths[index];
    end

    local clicked = nil;
    if (total <= width) then
        local spare = (width - total) / #labels;
        for index, label in ipairs(labels) do
            if (index > 1) then
                imgui.SameLine(0, gap);
            end
            if (theme.toggle_button(('%s##%s_%d'):fmt(label, id, index), states[index], widths[index] + spare)) then
                clicked = index;
            end
        end
    else
        for index, label in ipairs(labels) do
            if (theme.toggle_button(('%s##%s_%d'):fmt(label, id, index), states[index], width)) then
                clicked = index;
            end
        end
    end
    return clicked;
end

function theme.icon_button(id, glyph, codepoint, on, width)
    local clicked = theme.toggle_button(id, on, width);
    local found   = imgui.GetFontBaked():FindGlyph(codepoint);
    local x0, y0  = imgui.GetItemRectMin();
    local x1, y1  = imgui.GetItemRectMax();
    local pos     = { (x0 + x1 - found.X0 - found.X1) / 2, (y0 + y1 - found.Y0 - found.Y1) / 2 };
    imgui.GetWindowDrawList():AddText(pos, theme.u32(on and theme.COLOR.text or theme.COLOR.muted), glyph);
    return clicked;
end

function theme.stat_cell(label, value, color)
    imgui.TableNextColumn();
    imgui.TextColored(theme.COLOR.muted, label);
    imgui.TextColored(color or theme.COLOR.text, value);
end

function theme.caption(text)
    imgui.TextColored(theme.COLOR.muted, text);
end

function theme.section(text)
    imgui.Spacing();
    imgui.Spacing();
    imgui.TextColored(theme.COLOR.muted, text);
end

function theme.window_position()
    local x, y = imgui.GetWindowPos();
    if (type(x) == 'table') then
        y = x.y or x[2];
        x = x.x or x[1];
    end
    return x, y;
end

function theme.window_size()
    local w, h = imgui.GetWindowSize();
    if (type(w) == 'table') then
        h = w.y or w[2];
        w = w.x or w[1];
    end
    return w, h;
end

function theme.cursor()
    local x, y = imgui.GetCursorScreenPos();
    if (type(x) == 'table') then
        y = x.y or x[2];
        x = x.x or x[1];
    end
    return x, y;
end

function theme.available()
    local w, h = imgui.GetContentRegionAvail();
    if (type(w) == 'table') then
        h = w.y or w[2];
        w = w.x or w[1];
    end
    return w, h;
end

function theme.mouse()
    local x, y = imgui.GetMousePos();
    if (type(x) == 'table') then
        y = x.y or x[2];
        x = x.x or x[1];
    end
    return x, y;
end

return theme;
