# gs_selldrugs
An optimized, lightweight drug selling system for ESX servers with **ox_inventory**, **ox_lib**, **redutzu_mdt** (or cd_dispatch) integration, and optional live police tracking. 

---

## Features
- Sell configured drugs to **ambient NPCs** anywhere in the world.
- Configurable **quantities, prices, and cooldowns**.
- **Chance-based events**:
  - Snitches (call police with 10-47 and live tracking)
  - Ambient police suspicion alerts
  - Bad product (sale fails)
- **Live police tracking**: updates every 5s for 60s after alert.
- **redutzu_mdt** or **cd_dispatch** support (auto-detects).
- Step-toward-you ped animation for immersive sales.
- **Configurable minimum police** requirement.
- Debug mode for development/testing.

---

## Requirements
- ESX (latest)
- [ox_inventory](https://overextended.dev/ox_inventory)
- [ox_lib](https://overextended.dev/ox_lib)
- [redutzu_mdt](https://github.com/redutzu/redutzu_mdt) or [cd_dispatch](https://codesign.pro/dispatch)
- jg_hud (optional HUD compatibility)

---

## Installation
1. Download and place `gs_selldrugs` in your server’s `resources` folder.
2. Ensure it’s started **after** ESX, ox_inventory, ox_lib, and dispatch resources.

```cfg
ensure ox_lib
ensure ox_inventory
ensure redutzu_mdt  # or cd_dispatch
ensure gs_selldrugs
````

3. Add your drug items to **ox\_inventory**.

---

## Configuration

Edit `config.lua` to:

* Set sellable items and their **price/quantity ranges**.
* Adjust **chance percentages** for snitches, bad product, and police alerts.
* Change police tracking **duration** and **update intervals**.
* Set **minimum police** on duty to allow sales.
* Define cooldown times and restricted zones.

---

## Commands & Usage

* **Default Keybind:** `E` to offer drugs (change in config).
* **Command:** `/selldrug` (if keybind is disabled).
* Approach an **NPC pedestrian** and press your key or use ox\_target.
* Sale success/failure is based on configured chance rolls.

---

## Police / MDT Integration

* **Snitch or alert events** send a 10-47 dispatch with location + street name.
* **Live blip tracking** for on-duty police (60s default).
* Auto-uses redutzu\_mdt if running, else cd\_dispatch.

---

## Debugging

* Set `Config.Debug = true` in `config.lua` to enable:

  * Server console logs for RNG rolls.
  * Ped/entity detection info.
  * Tracking updates printed for devs.

---