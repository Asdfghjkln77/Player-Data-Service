# 🔧 Roblox PlayerDataService Module

A modular data storage system for Roblox, easy to integrate and highly extensible. Ideal for developers who want to create persistent profiles for players, with support for ordered objects, integration with value folders and much more.

---
## 📦 Modules

### 📁 `PlayerDataService`

Main module that deals with DataStores and offers support for two types:

- `DataObject`: Data table saved by player, that use the ProfileStore (new ProfileService) to handle all requirements.
- `OrderedDataObject`: Object with support for ordering by values ​​(e.g. for ranking systems).

### 🧰 `SetupHelper`

Auxiliary module that makes it easier to use [`PlayerDataService`](./PlayerDataService.lua), ideal for beginners or for projects that only need to connect existing values ​​in folders and get it working.

---

## 🚀 How to Use

You can easily use it with the [`ServerScriptExample`](./ServerScriptExample.lua)

---

### 👨‍💻 API

## Getting the DataObject
```lua
PlayerDataService.GetDataStore()
```
- Parameters: |string| storeName, |string| objectType, |{[string]: any}| defaultData
- Return: |DataObject || OrderedDataObject|
- Description: Returns a handler object of the chosen type based on a store name and data template.

## Checking the DataObject type
```lua
|DataObject || OrderedDataObject|:IsA()
```
- Parameters: |string| className
- Return: |bool|
- Description: Returns if the type is equals to the className passed on the argument

## Setuping the player for the DataObjec
```lua
|DataObject|:SetupPlayerForDataObject()
```
- Parameters: |Player| player, |Folder| folder
- Return: |PlayerProfile|, |Folder|
- Description: Creates session data for the player and loads the values ​​into the cloned folder.

## Setting-up the player for the DataObject
```lua
|OrderedDataObject|:SetupPlayerForOrderedDataObject()
```
- Parameters: |Player| player, |NumberValue || IntValue| valueInstance
- Return: |void|
- Description: Loads the ordered DataStore value into a number instance.
