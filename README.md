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
