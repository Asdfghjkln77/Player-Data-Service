# 📦 PlayerDataService Module

A modular and flexible data management system for Roblox, supporting both traditional and ordered data storage. This module abstracts DataStore operations and simplifies saving and loading player data.

---

## 🔧 Setup

You can set up the module in two ways:

* **Manually**: Require the [`PlayerDataService`](./PlayerDataService.lua) module directly in your scripts.
* **Using [`SetupHelper`](./SetupHelper.lua)**: A helper script bundled with the module (child of [`PlayerDataService`](./PlayerDataService.lua)) for easier integration.

---

## 🧪 Supported Data Types

* **`"DataObject"`**
  Uses [`ProfileStore`](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543) for structured data (ideal for folders containing `ValueBase` instances).

* **`"OrderedDataObject"`**
  Uses Roblox's `OrderedDataStore`, ideal for leaderboards and simple numeric rankings.

---

## 🧱 API Overview

### 🗃️ Get a Data Store

```lua
PlayerDataService.GetDataStore(storeName, objectType, defaultData)
```

Returns a data handler object for either a `DataObject` or `OrderedDataObject`.

### 📂 Setup & Load

#### For ProfileService-based data:

```lua
<DataObject>:SetupPlayerForDataObject(player, folder, autoSaveTime)
```
Creates and loads player data into a cloned folder. Returns the session profile and folder.

#### For OrderedDataStore-based data:

```lua
<OrderedDataObject>:SetupPlayerForOrderedDataObject(player: Player, valueInstance: IntValue | NumberValue, autoSaveTime: number)
```
Loads a numeric value (`IntValue` or `NumberValue`) into the provided instance.

### 🔄 Save & Load Methods

```lua
<DataObject | OrderedDataObject>:LoadPlayer(player, instance)
<DataObject | OrderedDataObject>:SavePlayer(player, instance)
```
Loads or saves data using the provided instance (`Folder` or `ValueBase`).

### 📊 Leaderboard Utilities

```lua
<OrderedDataObject>:GetSortedAsync(isAncending: boolean, pageSize: number, minValue: number?, maxValue: number?)
```

Returns a sorted page of leaderboard results.

---

## 📌 Notes & Behaviors

* Uses **data reconciliation** to apply missing fields in saved data.
* **Auto-saves** player data at intervals and on exit.
* **Fails gracefully**: Player is kicked if profile fails to load.
* Supports `IsA("DataObject")` or `IsA("OrderedDataObject")` for type checks.
* **Auto session cleanup** and error handling included.

---

## 🔒 Security & Reliability

* All critical operations (e.g., data saving/loading) use **safe retries** to handle transient DataStore errors.
* Designed to be **extensible**—you can integrate with [`ErrorService`](./ErrorService.lua) for custom logging and alerts.

---

## 💭 Examples of how to use

* [`ServerScriptExample`](./ServerScriptExample.lua)

---

## 📄 Author

**Created by:** \[its\_asdf]
You’re welcome to customize or extend this module to fit your game’s data handling needs.
