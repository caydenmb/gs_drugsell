# gs_selldrugs

Optimized NPC street-dealing for **ESX** using **ox_inventory** + **ox_lib**, with **redutzu_mdt** (or cd_dispatch) 10-47 dispatch, **live police tracking**, optional **third-eye (ox_target)** interaction, **ped handoff animation**, and **anti-exploit sale lock**.

## ✨ Features

- Sell configured drugs to **ambient NPCs** (no extra ped spawns).
- Secure **two-step** server flow (offer → completion) with token validation.
- **Third-eye** (ox_target) + keybind + command — all supported.
- **Snitch chance** + **ambient alert chance** + **bad product** (sale fails).
- **10-47** MDT dispatch (redutzu_mdt preferred; falls back to cd_dispatch).
- **Live suspect tracking** (default 60s, updates every 5s) for on-duty police.
- **Ped steps toward you** and plays a quick handoff animation.
- **Anti-exploit lock**: players cannot cancel/restart to dupe/abuse.
- Lightweight & production-tuned; detailed logger with levels.

---

## ✅ Requirements

- **ESX** (latest)  
- **ox_lib**  
- **ox_inventory**  
- **redutzu_mdt** *(preferred)* or **cd_dispatch** *(fallback)*  
- **ox_target** *(optional, for third-eye)*  
- (Optional) Your anti-cheat (e.g., Reaper). DevMode should be **off** in production.

---

## 📦 Installation

1. Drop the folder into `resources/[crime]/gs_selldrugs`.
2. Ensure start order in `server.cfg`:
   ```cfg
   ensure ox_lib
   ensure ox_inventory
   # ensure redutzu_mdt   # or: ensure cd_dispatch
   # ensure ox_target     # if using third-eye
   ensure gs_selldrugs
````

3. Make sure your **ox\_inventory** has items that match **`Config.Items`** names.

---

## ⚙️ Configuration

Open `config.lua` and adjust:

* **Payout account**: `Config.Account = 'black_money'` or `'cash'`.
* **Items & pricing**: edit `Config.Items` (min/max qty, min/max price, risk, acceptance).
* **Chances**:

  * `Config.SnitchChancePercent` (default 15)
  * `Config.BadProductFailPercent` (default 15)
  * `Config.BasePoliceAlertChance` (default 4)
* **Dispatch**: choose provider or auto-detect; tune tracking duration & interval.
* **Third-eye**: `Config.ThirdEye.enabled = true` (ox\_target auto-detected).
* **Ped handoff**: tweak `Config.PedApproach` for distance/anim behavior.
* **Cooldowns**: global, player, and per-ped in seconds.
* **Min cops**: block sales if fewer than `Config.MinCops` on duty.
* **No-sale zones**: add entries to `Config.BlacklistZones`.

---

## 🎮 How to Sell

* **Keybind**: Face a nearby NPC (≈2–3m) and press **E** (default).
* **Command**: `/selldrug`
* **Third-eye**: Aim ox\_target at an NPC → **Offer Drugs**.

> Each sale uses a **single item type** from your inventory and rolls a random quantity + price within your configured ranges.

---

## 🚓 Police & MDT

* **Snitch** or **ambient alert** triggers a **10-47** to MDT with street & coords.
* **Live tracking**: cops get a moving blip for **60s** (every **5s** update).
* If `Config.Dispatch.callOnSuccess = true`, finishing a sale can also alert.

---

## 🛡️ Anti-Exploit & Integrity

* **No cancel** during the progress bar (`canCancel=false`).
* **Active deal lock**: While a token is alive, **no new offers** are permitted.
* **Server-side validation**: ped, distance, token, inventory, and payout are all verified.
* **Sweeper**: expired tokens are auto-cleared; locks are released safely.
* **Reaper/AC friendly**: short ped control timeouts, minimal per-frame work.

---

## 🔍 Debugging

Logging lives in `shared/debug.lua`.

* **Production**: `Debug.level = 2` (info only).
* **Testing**: set to `3` or `4` for verbose/trace logs.
* Logs are pre-formatted (no `%d` leftovers, single-line messages).

Common messages:

* `Police roster rebuilt (N officers)` — periodic ESX sync.
* `SNITCH:` / `BAD PRODUCT:` — RNG outcomes for auditing.
* `Tracking started/ended` — live blip lifecycle.

---

## 🛠️ Troubleshooting

* **“No sellable items”** → ensure your ox\_inventory item names match `Config.Items` keys.
* **No MDT entry** → confirm `redutzu_mdt` is started; otherwise, the script falls back to `cd_dispatch`.
* **Third-eye option doesn’t show** → verify `ox_target` is running and `Config.ThirdEye.enabled = true`.
* **Reaper spam/“invalid action”** → disable Reaper **DevMode** in production.