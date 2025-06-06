# 📦 Module PlayerDataService

Roblox's versatile and adaptable data management system that supports both structured and conventional data storage. This module makes it easier to save and load player data by abstracting DataStore operations.

---

## 🔧 Configuration

The module can be configured in two ways:

* **Manually**: Require [`PlayerDataService`](./PlayerDataService.lua) and do it yourserlf based in the Module API.
* **With SetupHelper**: Has plug-and-play functions.

---

## 🧪 DataObject types

* "DataObject": Uses [`ProfileStore`](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543) for structured data (perfect for folders holding ValueBase instances).

* "OrderedDataObject": Utilizes the default Roblox's OrderedDataStore, which is perfect for basic numerical rankings and leaderboards.

---

## Overview of the 🧱 API

### 🗃️ Obtain a Data Store

```lua
PlayerDataService.GetDataStore(defaultData, objectType, storeName)
```
for a DataObject or OrderedDataObject, returns a data handler object.

### 📂 Configuration & Upload

#### For data based on ProfileService:

```lua
<DataObject>:SetupPlayerForDataObject(player, folder, autoSaveTime)
```

creates a cloned folder and loads player data into it. gives back the folder and session profile.

#### For data based on OrderedDataStores:

```lua
<OrderedDataObject>:SetupPlayerForOrderedDataObject(player: Player, valueInstance: IntValue | NumberValue, autoSaveTime: number)
```
loads a numeric value into the specified instance (either IntValue or NumberValue).

### 🔄 Methods to Save and Load

```lua
<DataObject | OrderedDataObject>:LoadPlayer(player: Player, instance: Folder | NumberValue | IntValue) DataObject | OrderedDataObject>:SavePlayer(player: Player, instance: Folder | NumberValue | IntValue)
```
Uses the supplied instance ({Folder or ValueBase) to load or store data.

### 📊 List of Leaderboard Features

```lua
<OrderedDataObject>:GetSortedAsync(IsAncending: boolean, pageSize: number, minValue: number?, maxValue: number?)
```
returns a page with the leaderboard results sorted.

---

## 📌 Remarks & Actions

* **Auto-saves** player data on exit and at intervals. 
* **Fails gracefully**: Apply missing fields in saved data using **data reconciliation**. If the profile does not load, the player gets kicked.
* **Auto session cleanup** and error handling are included. IsA("DataObject") or IsA("OrderedDataObject") are supported for type checks.

---

## 🔒 Safety & Reliability

**Safe retries** are used to handle temporary DataStore problems in all key processes, such as data loading and saving.
* Designed to be **extensible** - for custom logging and alarms, you can integrate with [`ErrorService`](./ErrorService.lua).

---

## 💭 How to use

* You must ensure that the [`ProfileStore`](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543) and the [`ErrorService`](./ErrorService.lua) are parented to the parent as the [`PlayerDataService`](./PlayerDataService.lua). A parent [`SetupHelper`](./SetupHelper.lua) to the [`PlayerDataService`](./PlayerDataService.lua) is also an option if you would like.
* To learn how to use the module, view the [`ServerScriptExample`](./ServerScriptExample.lua).

---

## 📄 Writer
The author of this work is [`its_asdf`](https://www.roblox.com/users/1706537119/profile)
