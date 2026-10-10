addon.name    = 'phoenixmeter';
addon.author  = 'Skold';
addon.version = '1.1';
addon.desc    = 'Job-themed damage meter with live bars and per-player breakdowns.';
addon.link    = 'https://phoenix-xi.com/';

require('common');

local chat      = require('chat');
local settings  = require('settings');
local actions   = require('actions');
local combat    = require('combat');
local meter     = require('meter');
local breakdown = require('breakdown');
local popup     = require('popup');

local SPEED        = 9;
local REPORT_GAP   = 1.2;
local REPORT_COUNT = 5;
local CHANNELS     = T{ p = true, l = true, l2 = true, s = true };
local CHAIN_MODES  = T{ split = true, closer = true, ignored = true };

local default_settings = T{
    visible  = true,
    locked   = false,
    mode     = 'damage',
    pets     = 'together',
    chains   = 'closer',
    rows     = 10,
    width    = 340,
    idle     = 8,
    history  = 20,
    scale    = 1.0,
    alpha    = 0.94,
    x             = 60,
    y             = 220,
    detail_custom = false,
    detail_dx     = 0,
    detail_dy     = 0,
    popup         = true,
    popup_scale   = 1.2,
    popup_custom  = false,
    popup_x       = 0,
    popup_y       = 0,
};

local pm = T{
    settings         = settings.load(default_settings),
    segment          = 'current',
    focus            = nil,
    place_window     = true,
    place_detail     = true,
    place_popup      = true,
    reset_position   = false,
    show_settings    = false,
    clear            = false,
    pending          = T{},
    last_pos_save    = 0,
    last_detail_save = 0,
    last_popup_save  = 0,
    last_frame       = nil,
    meter_w          = 0,
    meter_moved      = false,
    report           = nil,
    outbox           = T{},
    next_send        = 0,
};

local function say(message)
    print(chat.header(addon.name):append(chat.message(message)));
end

local function sanitize()
    if (not meter.mode(pm.settings.mode)) then
        pm.settings.mode = default_settings.mode;
    end
    pm.settings.rows = math.min(25, math.max(3, math.floor(tonumber(pm.settings.rows) or default_settings.rows)));
    pm.settings.idle = math.min(30, math.max(3, tonumber(pm.settings.idle) or default_settings.idle));
    pm.settings.width = math.min(meter.MAX_WIDTH, math.max(meter.MIN_WIDTH, math.floor(tonumber(pm.settings.width) or default_settings.width)));
    if (pm.settings.pets ~= 'together' and pm.settings.pets ~= 'separate') then
        pm.settings.pets = default_settings.pets;
    end
    if (not CHAIN_MODES[pm.settings.chains]) then
        pm.settings.chains = default_settings.chains;
    end
end

local function clear_fights(now)
    combat.reset(now);
    meter.forget();
    breakdown.forget();
    pm.segment = 'current';
end

local function queue_report(now)
    local request = pm.report;
    pm.report = nil;
    local lines = meter.report(pm, combat.view(pm.segment), now, request.count or REPORT_COUNT);
    if (#lines == 0) then
        say('Nothing to report yet.');
        return;
    end
    pm.outbox = T{};
    for _, line in ipairs(lines) do
        pm.outbox:append(('/%s %s'):fmt(request.channel, line));
    end
end

local function send_report(now)
    if (#pm.outbox > 0 and now >= pm.next_send) then
        AshitaCore:GetChatManager():QueueCommand(1, table.remove(pm.outbox, 1));
        pm.next_send = now + REPORT_GAP;
    end
end

local function render(now)
    if (pm.reset_position) then
        pm.settings.x             = default_settings.x;
        pm.settings.y             = default_settings.y;
        pm.settings.detail_custom = false;
        pm.settings.popup_custom  = false;
        pm.place_window           = true;
        pm.place_detail           = true;
        pm.place_popup            = true;
        pm.reset_position         = false;
        settings.save();
    end

    if (pm.clear) then
        pm.clear = false;
        clear_fights(now);
    end

    if (pm.report) then
        queue_report(now);
    end
    send_report(now);

    local frame = now - (pm.last_frame or now);
    pm.last_frame = now;
    local factor = 1 - math.exp(-math.min(0.25, math.max(0, frame)) * SPEED);

    popup.render(pm, now);

    if (not pm.settings.visible) then
        return;
    end

    local segment = combat.view(pm.segment);
    if (type(pm.segment) == 'table' and segment ~= pm.segment) then
        pm.segment = 'current';
    end

    meter.render(pm, segment, now, factor);
    breakdown.render(pm, segment, now, factor);
    pm.meter_moved = false;
end

local function print_help()
    say('/pmeter - show or hide the meter');
    say(('/pmeter mode <%s> - what the bars rank'):fmt(table.concat(meter.mode_keys(), '|')));
    say('/pmeter pets <together|separate> - add pet damage to its master, or give pets their own rows');
    say('/pmeter sc <split|closer|ignored> - skillchain damage: halved between opener and closer, all to the closer, or left out');
    say('/pmeter popup [on|off] - skillchain popup: what your weaponskills make on your target');
    say('/pmeter popup size <0.5-3> - skillchain popup size');
    say(('/pmeter report [p|l|l2|s] [1-18] - post the meter to chat (party, top %d by default)'):fmt(REPORT_COUNT));
    say('/pmeter clear - forget every recorded fight');
    say('/pmeter rows <3-25> - rows shown before the list is cut');
    say('/pmeter idle <3-30> - seconds without combat before a fight ends');
    say('/pmeter scale <0.5-3> - window size');
    say('Click a name for its breakdown. Right-click the meter for more options.');
end

ashita.events.register('command', 'phoenixmeter_command', function (e)
    local args = e.command:args();
    if (#args == 0) then
        return;
    end
    local command = args[1]:lower();
    if (command ~= '/pmeter' and command ~= '/phoenixmeter') then
        return;
    end
    e.blocked = true;

    local sub   = (args[2] or ''):lower();
    local value = args[3];
    if (sub == '') then
        pm.settings.visible = not pm.settings.visible;
        settings.save();
    elseif (sub == 'show' or sub == 'hide') then
        pm.settings.visible = sub == 'show';
        settings.save();
    elseif (sub == 'mode') then
        local mode = meter.mode((value or ''):lower());
        if (not mode) then
            say(('Usage: /pmeter mode <%s>'):fmt(table.concat(meter.mode_keys(), '|')));
            return;
        end
        pm.settings.mode = mode.key;
        settings.save();
    elseif (sub == 'pets') then
        local choice = (value or ''):lower();
        if (choice ~= 'together' and choice ~= 'separate') then
            say('Usage: /pmeter pets <together|separate>');
            return;
        end
        pm.settings.pets = choice;
        settings.save();
    elseif (sub == 'sc' or sub == 'skillchain') then
        local choice = (value or ''):lower();
        if (not CHAIN_MODES[choice]) then
            say('Usage: /pmeter sc <split|closer|ignored>');
            return;
        end
        pm.settings.chains = choice;
        settings.save();
    elseif (sub == 'popup') then
        local choice = (value or ''):lower();
        if (choice == 'size') then
            local number = tonumber(args[4]);
            if (not number) then
                say('Usage: /pmeter popup size <0.5-3>');
                return;
            end
            pm.settings.popup_scale = math.min(3.0, math.max(0.5, number));
            settings.save();
            return;
        end
        if (choice == 'on' or choice == 'off') then
            pm.settings.popup = choice == 'on';
        elseif (choice == '') then
            pm.settings.popup = not pm.settings.popup;
        else
            say('Usage: /pmeter popup [on|off]');
            return;
        end
        settings.save();
        say(('Skillchain popup %s.'):fmt(pm.settings.popup and 'on' or 'off'));
    elseif (sub == 'report') then
        local channel = 'p';
        local count   = REPORT_COUNT;
        for index = 3, #args do
            local word = args[index]:lower();
            if (CHANNELS[word]) then
                channel = word;
            elseif (tonumber(word)) then
                count = math.min(18, math.max(1, math.floor(tonumber(word))));
            else
                say('Usage: /pmeter report [p|l|l2|s] [1-18]');
                return;
            end
        end
        pm.report = T{ channel = channel, count = count };
    elseif (sub == 'clear' or sub == 'reset') then
        pm.clear = true;
        say('Recorded fights cleared.');
    elseif (sub == 'rows' or sub == 'idle' or sub == 'scale') then
        local number = tonumber(value);
        if (not number) then
            say(('Usage: /pmeter %s <number>'):fmt(sub));
            return;
        end
        if (sub == 'rows') then
            pm.settings.rows = math.min(25, math.max(3, math.floor(number)));
        elseif (sub == 'idle') then
            pm.settings.idle = math.min(30, math.max(3, number));
        else
            pm.settings.scale = math.min(3.0, math.max(0.5, number));
        end
        settings.save();
    else
        print_help();
    end
end);

ashita.events.register('packet_in', 'phoenixmeter_packet_in', function (e)
    if (e.id == 0x028) then
        combat.action(actions.decode(e.data), os.clock());
    elseif (e.id == 0x029) then
        combat.message(actions.message(e.data), os.clock());
    elseif (e.id == 0x02D) then
        combat.experience(actions.points(e.data), os.clock());
    elseif (e.id == 0x076) then
        combat.group_effects(actions.group_effects(e.data));
    end
end);

ashita.events.register('d3d_present', 'phoenixmeter_present', function ()
    local now = os.clock();
    combat.tick(now, pm.settings.idle, pm.settings.history, pm.settings.chains);
    render(now);
end);

settings.register('settings', 'phoenixmeter_settings_update', function (s)
    if (s) then
        pm.settings = s;
    end
    sanitize();
    settings.save();
    pm.place_window = true;
    pm.place_detail = true;
    pm.place_popup  = true;
end);

sanitize();
combat.reset(os.clock());
