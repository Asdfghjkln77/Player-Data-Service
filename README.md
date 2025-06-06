# 🔧 Roblox PlayerDataService Module

A modular data storage system for Roblox, easy to integrate and highly extensible. Ideal for developers who want to create persistent profiles for players, with support for ordered objects, integration with value folders and much more.

---
## 📦 Modules

### 📁 `PlayerDataService`

Main module that deals with DataStores and offers support for two types:

- `DataObject`: Data table saved by player, that use the ProfileStore (new ProfileService) to handle all requirements.
- `OrderedDataObject`: Object with support for ordering by values ​​(e.g. for ranking systems).

### 🧰 `SetupHelper`

Auxiliary module that makes it easier to use `PlayerDataService`, ideal for beginners or for projects that only need to connect existing values ​​in folders and get it working.

---

## 🚀 How to Use

You can easily use it with the Auxiliary module [`SetupHelper`](./SetupHelper.lua)
