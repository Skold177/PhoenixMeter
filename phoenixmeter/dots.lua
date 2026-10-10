require('common');

local dots = T{};

dots.TICK = 3;

local POISON  = 3;
local BURN    = 128;
local FROST   = 129;
local CHOKE   = 130;
local RASP    = 131;
local SHOCK   = 132;
local DROWN   = 133;
local DIA     = 134;
local BIO     = 135;
local REQUIEM = 192;

local AUTOMATON_MAGIC = 24;
local ENFEEBLING      = 35;
local DARK            = 37;
local INT             = 4;
local TOP_RANK        = 1;

local RANKS = T{
    [ENFEEBLING] = T{ [3] = 7, [4] = 6, [5] = 1, [8] = 7, [20] = 9, [21] = 6 },
    [DARK]       = T{ [4] = 2, [5] = 10, [8] = 2, [20] = 9, [21] = 7 },
};

local CAPS = T{
    [1]  = T{ 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99, 102, 105, 108, 111, 114, 117, 120, 123, 126, 129, 132, 135, 138, 141, 144, 147, 150, 153, 158, 163, 168, 173, 178, 183, 188, 193, 198, 203, 207, 212, 217, 222, 227, 232, 236, 241, 246, 251, 256, 261, 266, 271, 276, 281, 286, 291, 296, 301, 307, 313, 319, 325, 331, 337, 343, 349, 355, 361, 368, 375, 382, 389, 396, 403, 410, 417, 424 },
    [2]  = T{ 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 48, 51, 54, 57, 60, 63, 66, 69, 72, 75, 78, 81, 84, 87, 90, 93, 96, 99, 102, 105, 108, 111, 114, 117, 120, 123, 126, 129, 132, 135, 138, 141, 144, 147, 150, 153, 158, 163, 168, 173, 178, 183, 188, 193, 198, 203, 207, 211, 215, 219, 223, 227, 231, 235, 239, 244, 249, 254, 259, 264, 269, 274, 279, 284, 289, 294, 300, 306, 312, 318, 324, 330, 336, 342, 348, 354, 361, 368, 375, 382, 389, 396, 403, 410, 417 },
    [6]  = T{ 5, 7, 10, 13, 16, 19, 21, 24, 27, 30, 33, 35, 38, 41, 44, 47, 49, 52, 55, 58, 61, 63, 66, 69, 72, 75, 77, 80, 83, 86, 89, 91, 94, 97, 100, 103, 105, 108, 111, 114, 117, 119, 122, 125, 128, 131, 133, 136, 139, 142, 146, 151, 156, 161, 166, 170, 175, 180, 185, 190, 192, 195, 197, 200, 202, 205, 207, 210, 212, 215, 218, 221, 224, 227, 230, 235, 240, 245, 250, 255, 261, 267, 273, 279, 285, 291, 297, 303, 309, 315, 322, 329, 336, 343, 350, 357, 364, 371, 378 },
    [7]  = T{ 5, 7, 10, 13, 16, 19, 21, 24, 27, 30, 33, 35, 38, 41, 44, 47, 49, 52, 55, 58, 61, 63, 66, 69, 72, 75, 77, 80, 83, 86, 89, 91, 94, 97, 100, 103, 105, 108, 111, 114, 117, 119, 122, 125, 128, 131, 133, 136, 139, 142, 146, 151, 156, 161, 166, 170, 175, 180, 185, 190, 192, 194, 196, 199, 201, 203, 205, 208, 210, 212, 214, 217, 219, 222, 225, 230, 235, 240, 245, 250, 256, 262, 268, 274, 280, 286, 292, 298, 304, 310, 317, 324, 331, 338, 345, 352, 359, 366, 373 },
    [9]  = T{ 4, 6, 9, 12, 14, 17, 20, 22, 25, 28, 31, 33, 36, 39, 41, 44, 47, 49, 52, 55, 58, 60, 63, 66, 68, 71, 74, 76, 79, 82, 85, 87, 90, 93, 95, 98, 101, 103, 106, 109, 112, 114, 117, 120, 122, 125, 128, 130, 133, 136, 140, 145, 150, 154, 159, 164, 168, 173, 178, 183, 184, 186, 188, 190, 192, 194, 195, 197, 199, 201, 203, 205, 207, 208, 210, 214, 218, 222, 226, 230, 235, 240, 245, 250, 255, 260, 265, 270, 275, 280, 286, 292, 298, 304, 310, 316, 322, 328, 334 },
    [10] = T{ 4, 6, 9, 11, 14, 16, 19, 21, 24, 26, 29, 31, 34, 36, 39, 41, 44, 46, 49, 51, 54, 56, 59, 61, 64, 66, 69, 71, 74, 76, 79, 81, 84, 86, 89, 91, 94, 96, 99, 101, 104, 106, 109, 111, 114, 116, 119, 121, 124, 126, 130, 135, 139, 144, 148, 153, 157, 162, 166, 171, 172, 174, 176, 178, 180, 182, 184, 186, 188, 190, 192, 194, 196, 198, 200, 203, 206, 209, 212, 215, 219, 223, 227, 231, 235, 239, 243, 247, 251, 255, 260, 265, 270, 275, 280, 285, 290, 295, 300 },
};

local function clamp(value, low, high)
    return math.max(low, math.min(high, value));
end

local function bio(stats)
    return clamp(math.ceil(stats.dark / 40), 1, 3);
end

local function bio_ii(stats)
    return clamp(math.floor((stats.dark + 29) / 40), 3, 8);
end

local function bio_iii(stats)
    local skill = stats.dark;
    local power = 5 + math.floor((skill - 106) / 35);
    if (skill > 291) then
        power = 13 + math.floor((skill - 291) / 27);
    elseif (skill > 246) then
        power = 9 + math.floor((skill - 246) / 11);
    end
    return clamp(power, 5, 17);
end

local function poison(stats)
    local skill = stats.enfeebling;
    if (skill > 400) then
        return math.floor(math.min((skill - 225) / 5, 55));
    end
    return math.floor(math.max(skill / 25, 1));
end

local function poison_ii(stats)
    local skill = stats.enfeebling;
    if (skill > 400) then
        return math.floor(skill * 49 / 183 - 55);
    end
    return math.floor(math.max(skill / 20, 4));
end

local function elemental(stats)
    if (stats.int > 150) then
        return 5;
    elseif (stats.int > 100) then
        return 4;
    elseif (stats.int > 70) then
        return 3;
    elseif (stats.int > 40) then
        return 2;
    end
    return 1;
end

local function disseverment(stats)
    return math.floor(3 + stats.level / 5);
end

local SPELLS = T{
    [23]  = T{ effect = DIA,     power = 1,            duration = 60,  tier = 1, rival = BIO },
    [24]  = T{ effect = DIA,     power = 2,            duration = 120, tier = 3, rival = BIO },
    [25]  = T{ effect = DIA,     power = 3,            duration = 150, tier = 5, rival = BIO },
    [33]  = T{ effect = DIA,     power = 1,            duration = 60,  tier = 1, rival = BIO },
    [220] = T{ effect = POISON,  power = poison,       duration = 90  },
    [221] = T{ effect = POISON,  power = poison_ii,    duration = 120 },
    [225] = T{ effect = POISON,  power = poison,       duration = 90  },
    [230] = T{ effect = BIO,     power = bio,          duration = 60,  tier = 2, rival = DIA },
    [231] = T{ effect = BIO,     power = bio_ii,       duration = 120, tier = 4, rival = DIA },
    [232] = T{ effect = BIO,     power = bio_iii,      duration = 150, tier = 6, rival = DIA },
    [235] = T{ effect = BURN,    power = elemental,    duration = 90,  clears = FROST },
    [236] = T{ effect = FROST,   power = elemental,    duration = 90,  clears = CHOKE },
    [237] = T{ effect = CHOKE,   power = elemental,    duration = 90,  clears = RASP  },
    [238] = T{ effect = RASP,    power = elemental,    duration = 90,  clears = SHOCK },
    [239] = T{ effect = SHOCK,   power = elemental,    duration = 90,  clears = DROWN },
    [240] = T{ effect = DROWN,   power = elemental,    duration = 90,  clears = BURN  },
    [350] = T{ effect = POISON,  power = 3,            duration = 60  },
    [351] = T{ effect = POISON,  power = 10,           duration = 120 },
    [352] = T{ effect = POISON,  power = 20,           duration = 360 },
    [368] = T{ effect = REQUIEM, power = 1,            duration = 64  },
    [369] = T{ effect = REQUIEM, power = 2,            duration = 80  },
    [370] = T{ effect = REQUIEM, power = 3,            duration = 96  },
    [371] = T{ effect = REQUIEM, power = 4,            duration = 112 },
    [372] = T{ effect = REQUIEM, power = 5,            duration = 128 },
    [373] = T{ effect = REQUIEM, power = 6,            duration = 144 },
    [374] = T{ effect = REQUIEM, power = 8,            duration = 160 },
    [513] = T{ effect = POISON,  power = 6,            duration = 60  },
    [536] = T{ effect = POISON,  power = 4,            duration = 60,  silent = true },
    [599] = T{ effect = POISON,  power = 3,            duration = 90,  silent = true },
    [604] = T{ effect = POISON,  power = 4,            duration = 60,  silent = true },
    [611] = T{ effect = POISON,  power = disseverment, duration = 180, silent = true },
    [638] = T{ effect = POISON,  power = 1,            duration = 180, silent = true },
};

local SKILLS = T{
    [16]  = T{ effect = POISON, power = 1,  duration = 90, silent = true },
    [17]  = T{ effect = POISON, power = 3,  duration = 90, silent = true },
    [66]  = T{ effect = CHOKE,  power = 5,  duration = 90, silent = true, clears = RASP },
    [139] = T{ effect = POISON, power = 10, duration = 90, silent = true },
};

local function cap(rank, level)
    local row = CAPS[rank];
    return row and row[clamp(level, 1, #row)] or 0;
end

local function job_cap(skill, who)
    local ranks = RANKS[skill];
    if (ranks[who.job]) then
        return cap(ranks[who.job], who.level or 0);
    end
    return cap(ranks[who.sub], who.sublevel or 0);
end

local function stats_of(who)
    local level  = who.level or 0;
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local stats  = T{ level = level, int = 20 + 1.3 * level };

    if (who.kind == 'me') then
        stats.enfeebling = player:GetCombatSkill(ENFEEBLING):GetSkill();
        stats.dark       = player:GetCombatSkill(DARK):GetSkill();
        stats.int        = player:GetStat(INT) + player:GetStatModifier(INT);
    elseif (who.mine) then
        stats.enfeebling = player:GetCombatSkill(AUTOMATON_MAGIC):GetSkill();
        stats.dark       = stats.enfeebling;
    elseif (who.kind == 'pet') then
        stats.enfeebling = cap(TOP_RANK, level);
        stats.dark       = stats.enfeebling;
    else
        stats.enfeebling = job_cap(ENFEEBLING, who);
        stats.dark       = job_cap(DARK, who);
    end
    return stats;
end

function dots.source(category, id)
    if (category == 4) then
        return SPELLS[id];
    elseif (category == 3) then
        return SKILLS[id];
    end
    return nil;
end

function dots.power(source, who)
    if (type(source.power) == 'function') then
        return source.power(stats_of(who));
    end
    return source.power;
end

return dots;
