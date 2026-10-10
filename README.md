# Phoenix Meter

Phoenix Meter is a damage meter for Phoenix XI. It ranks you, your party, your alliance and your trusts on live bars coloured by job, and a click on any name opens a full breakdown of what that player did.

It works from what the server already sends your client, the same actions that fill your chat log. Nothing is sent anywhere unless you ask it to post a report to chat.

## Features

- **Live bars:** one row per player, coloured by job and ranked, with bars that slide as the order changes. Your own row is marked and never drops off the list.
- **Five modes:** Damage Done, DPS, Healing Done, Damage Taken and Deaths.
- **Fights:** the current fight, an overall total, and the last 20 fights, each named after the monster that took the most damage.
- **Breakdowns:** click a name for that player's abilities, melee rounds, targets, healing, damage taken, buff uptime, deaths and magic, with a DPS graph over the fight.
- **Pets:** avatars, wyverns, automatons, jug pets and charmed monsters count toward their master, or get rows of their own.
- **Skillchains:** choose whether skillchain damage goes to the closer, is split with the opener, or is left out.
- **Skillchain popup:** when a weapon skill lands on your target, a small window lists which of your own weapon skills will chain off it, and what each one makes.
- **Damage over time:** Dia, Bio, poison, Requiem and elemental debuff ticks are estimated, because the server never sends them.
- **EXP per hour:** experience or limit points per hour, and the time left to your next level or merit point.
- **Report to chat:** post the top of the meter to party, linkshell or say.

## Installing

Requires [Ashita v4](https://github.com/AshitaXI/Ashita-v4beta).

1. Download the `phoenixmeter` zip from the [latest release](https://github.com/Skold177/PhoenixMeter/releases/latest) and extract it.
2. Copy the `phoenixmeter` folder into your Ashita `addons` folder, so you end up with `addons/phoenixmeter/phoenixmeter.lua`.
3. In game, type `/addon load phoenixmeter`.

To load it every time you play, add `/addon load phoenixmeter` to your Ashita startup script. To update, replace the old folder; your settings are kept.

## Commands

| Command | What it does |
|---|---|
| `/pmeter` | Show or hide the meter |
| `/pmeter show` / `/pmeter hide` | Show or hide the meter |
| `/pmeter mode <damage\|dps\|healing\|taken\|deaths>` | Choose what the bars rank |
| `/pmeter pets <together\|separate>` | Add pet damage to its master, or give pets their own rows |
| `/pmeter sc <split\|closer\|ignored>` | Choose who gets skillchain damage |
| `/pmeter popup [on\|off]` | Turn the skillchain popup on or off |
| `/pmeter popup size <0.5-3>` | Change the size of the skillchain popup |
| `/pmeter report [p\|l\|l2\|s] [1-18]` | Post the meter to chat. Party and the top 5 unless you say otherwise |
| `/pmeter clear` | Forget every recorded fight |
| `/pmeter rows <3-25>` | Rows shown before the list is cut |
| `/pmeter idle <3-30>` | Seconds without combat before a fight ends |
| `/pmeter scale <0.5-3>` | Change the window size |
| `/pmeter help` | List the commands in game |

`/phoenixmeter` works in place of `/pmeter`.

## Using the meter

- **Mode** (top left): click it to switch between Damage Done, DPS, Healing Done, Damage Taken and Deaths.
- **Fight** (next to the mode): click it to switch between Current Fight, Overall and any of the earlier fights.
- **Cog** (top right): opens the settings panel with Scale, Opacity, Rows, Fight ends, Pets, Skillchains, SC Popup, Popup size, Lock, Reset Position and Clear Fights. It works with a left click, so it's usable on a controller or Steam Deck.
- **Rows:** hover a row for a quick summary, click it to open the breakdown. Click the same name again to close it, or another name to switch.
- **Right-click** anywhere on the meter for Lock Window, Merge Pets Into Owners, Skillchain Damage, Skillchain Popup, Report to Party, Clear Fights, Reset Position, Hide, Scale and Opacity.
- **Corner grip** (bottom right): drag it to make the meter wider or narrower. It's hidden while the window is locked.

The footer shows a dot that pulses while the fight is live, the fight's length, the group total for the mode, and the number of kills.

What each row shows depends on the mode:

| Mode | Each row shows |
|---|---|
| Damage Done | Damage, DPS over the whole fight, and share of the group's damage |
| DPS | DPS over the time the player was actually attacking, then damage and share |
| Healing Done | Healing, healing per second, and share of the group's healing |
| Damage Taken | Damage taken and share of the group's damage taken |
| Deaths | Number of deaths |

If more players are fighting than there are rows, the list is cut. If you fall below the cut, your row takes the last slot.

## How fights are tracked

- The meter tracks you, your party, your alliance, your trusts and all of their pets. Players outside your alliance are ignored.
- A fight starts the first time anyone tracked hits, misses or takes damage. Healing on its own never starts a fight or keeps one going.
- A fight ends after 8 seconds without combat, or when you change zone. Change the 8 seconds with the Fight ends slider or `/pmeter idle`.
- Each fight is named after the monster that took the most damage. If there were others, the name ends with how many, like `Goblin Smithy +2`.
- The last 20 fights are kept, and Overall adds up everything since the last Clear Fights. Fights aren't saved when you log out or reload the addon.

## The breakdown

Click a name on the meter to open that player's breakdown beside it. The top shows Damage, DPS, Share, Active DPS, Healing, Taken, Deaths and Activity (how much of the fight the player spent attacking), and a graph of DPS over the fight. Hover the graph to read any point.

Below that is a tab for each kind of detail. A tab only appears when there is something to show.

| Tab | What it shows |
|---|---|
| Abilities | Every source of damage as a bar, coloured by type: melee, ranged, weapon skill, magic, ability, skillchain, additional effect and reactive (counters, Retaliation, spikes). Click a bar for uses, hits, misses, accuracy, crit rate, the smallest, average and biggest hit, and magic bursts |
| Melee | Accuracy, crit rate, average and biggest hit, attack rounds and swings per round, a line for each hand (main hand or fists, off hand, kicks, Daken), how often each hand made a single, Double or Triple Attack, Zanshin for Samurai, and ranged and pet accuracy |
| Targets | Damage dealt to each monster |
| Healing | Each healing spell and ability, and who received the healing |
| Taken | Damage taken, the biggest hit, evasion, parry, shadows, blocks, guards, counters, crits taken, anticipated attacks and resists, and a line for each monster attack |
| Buffs | How much of the fight each buff and debuff was up |
| Deaths | Each death, what dealt the killing blow, and everything that hit, missed or healed the player in the 30 seconds before |
| Magic | Enfeebles landed and resisted, magic bursts, and skillchains closed |

The breakdown sits to the right of the meter, or to the left when there's no room. Drag it somewhere else and it stays that far from the meter when the meter moves. Reset Position puts both windows back.

## Pets

Avatars, wyverns, automatons, jug pets and charmed monsters are tracked along with their masters.

- **Together** (the default): a pet's damage, healing and kills are added to its master. Pet abilities are listed in the master's breakdown with the pet's name beside them.
- **Separate:** each pet gets its own row, marked `PET`, in a darker shade of its master's job colour.

Damage a pet takes and pet deaths always stay with the pet. With pets together, the master's Taken tab shows the pet's total as Pet Taken.

## Skillchain damage

Skillchain damage is kept apart from each player's own damage, so you can choose who gets it:

- **Closer** (the default): all of it goes to the player who closed the skillchain.
- **Split:** half goes to the player who opened it and half to the closer. The opener is whoever last landed a weapon skill or pet skill on that monster in the 10 seconds before. If that was the same player, or nobody, the closer gets all of it.
- **Ignored:** skillchain damage is left out of every total.

The Magic tab's Skillchains Closed list shows the full damage of each skillchain a player closed, whichever of these you pick.

## Skillchain popup

When someone in your party or alliance lands a weapon skill on your target, a small window appears listing which of your own weapon skills will make a skillchain off it, and which skillchain each one makes. Only weapon skills you can use right now, with the weapons you have equipped, are listed.

- The top line shows what was used and who used it, with the skillchain properties it left on the monster underneath. Once a skillchain closes, the popup shows that skillchain instead, so you can see what continues it.
- The timer reads `Wait` for the first 3 seconds, when a weapon skill won't chain yet, then `Go` with the time you have left. You get 10 seconds after an opener, and a second less after each skillchain.
- Your options are listed with the highest level skillchain first.
- The popup follows your current target. It closes when the time runs out, when the monster dies, or when the chain can't go any further.

Pet skills, blood pacts, blue magic cast under Chain Affinity or Azure Lore, and Wild Flourish open a window the same way a weapon skill does.

The popup starts near the top middle of the screen. Open the settings panel with the cog and a sample popup appears: drag it where you want it, and use the Popup size slider or `/pmeter popup size` to make it bigger or smaller. Its size is separate from the meter's Scale, and it widens to fit the longest line. Reset Position puts it back. Turn it off with `/pmeter popup off`, the SC Popup setting, or Skillchain Popup in the right-click menu. It still appears when the meter itself is hidden.

The popup only knows about actions your client was sent, so a weapon skill used out of range won't open it.

## Damage over time

Phoenix never tells your client when a damage over time effect ticks, so the meter works the ticks out. It sees the spell or weapon skill land, knows how strong the effect is and how long it lasts, and adds the damage every 3 seconds. Each one shows up as its own line named after its source, like `Dia II (DoT)`.

These are covered:

- Dia, Dia II, Dia III and Diaga
- Bio, Bio II and Bio III
- Poison, Poison II and Poisonga
- Burn, Frost, Choke, Rasp, Shock and Drown
- Foe Requiem I to VII
- Dokumori: Ichi, Ni and San
- Venom Shell, Poison Breath, Queasyshroom, Bad Breath, Disseverment and Feather Storm
- Wasp Sting, Viper Bite, Gale Axe and Blade: Yu

Because these are estimates, a few things can be slightly off:

- Your own effects use your real magic skill and INT. Everyone else is assumed to have capped skill for their job and level.
- The server only tells you when your own effects wear off. Other players' effects are counted for their full length, or until the monster dies or the effect is replaced.
- Poison from weapon skills and blue magic is assumed to land every time.
- Pet and avatar effects, helix spells, and damage over time on players aren't estimated.

## Multi-attack and Zanshin

The server doesn't say which swings were a Double or Triple Attack, so the meter counts the swings from each hand in every attack round and works the rates out from that. Rounds that ended early because the monster died aren't counted.

The Melee tab shows the result as one bar per outcome: Single attack, Double Attack and Triple Attack, each with its share of the rounds and the number of rounds. Dual wielders get a second set for the off hand. Hand-to-hand has its own set, where two fists is a Normal round and anything more is listed as extra attacks.

A Zanshin swing looks exactly like a Double Attack, so the Zanshin bar is an estimate: extra swings after a missed or countered first swing, less the Double Attack rate seen on rounds that opened with a hit. It's only shown for Samurai, main or sub job. Hover the bar for how often it went off after a missed first swing.

## Buff uptime

The server only sends buffs for you and the players in your own party. The Buffs tab stays empty for trusts and alliance members, and pets don't have one.

## EXP per hour

Once you gain experience or limit points, a second line appears at the bottom of the meter with your rate per hour over the last 10 minutes, the time left to your next level at that rate, and the total gained. While you're earning limit points it shows the time to your next merit point. Clear Fights resets it.

## Reporting to chat

`/pmeter report` posts a header and the top 5 of whatever the meter is showing, in the mode and fight you have selected, to party chat. Add `l`, `l2` or `s` for linkshell, second linkshell or say, and a number from 1 to 18 to change how many rows are posted: `/pmeter report l 3`. Report to Party in the right-click menu does the same as `/pmeter report`. Lines go out one at a time, a little over a second apart.
