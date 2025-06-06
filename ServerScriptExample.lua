-- Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Module References
local dataModule = ServerStorage.Modules.PlayerDataService
local setupHelper = dataModule.SetupHelper

-- Sub-Services
local PlayerDataService = require(dataModule)
local PlayerDataService_SetupHelper = require(setupHelper)

-- DataStore References
local dataFolder = ServerStorage.DataFolders.PlayerAttributes -- Remove if you don't want a DataStore
local tableTemplate = PlayerDataService_SetupHelper:ConvertFolderToTableTemplate(dataFolder) -- Remove if you don't want a DataStore
local data = PlayerDataService_SetupHelper:GetDataObject(dataFolder.Name, tableTemplate) -- Remove if you don't want a DataStore

-- OrderedDataStore References
local leaderstats = ServerStorage.DataFolders.leaderstats -- Remove if you don't want a OrderedDataStore
local orderedDataList = PlayerDataService_SetupHelper:GetOrderedDataObjectListFromFolder(leaderstats) -- Remove if you don't want a OrderedDataStore

-- Leaderboard References
local KillsData = PlayerDataService.GetDataStore("Kills_Data", "OrderedDataObject") -- Remove if you don't want a Leaderboard
local leaderPart = workspace.LeaderPart -- Remove if you don't want a Leaderboard
local surfacegui = leaderPart.SurfaceGui -- Remove if you don't want a Leaderboard
local container = surfacegui.Container -- Remove if you don't want a Leaderboard
local template: TextLabel = container.Template -- Remove if you don't want a Leaderboard

-- Control
local autoSaveTime = 250
local leaderboardAutoUpdateTime = 300 -- Remove if you don't want a Leaderboard
local isAncending = false -- Remove if you don't want a Leaderboard
local pageSize = 10 -- Remove if you don't want a Leaderboard
local minValue = 1 -- Remove if you don't want a Leaderboard

-- Remove if you don't want a OrderedDataStore
task.spawn(function()
	while true do
		-- Creates a page (a table value)
		local pages = KillsData:GetSortedAsync(isAncending, pageSize, minValue)
		local firstPage = pages:GetCurrentPage()
		
		-- Loop through the page
		for rank, dict in ipairs(firstPage) do
			-- Extracts the UserId and Kills from the dictionary
			local userId = string.sub(dict.key, 8)
			local kills = dict.value
			local username = Players:GetNameFromUserIdAsync(userId)
			local clone = template:Clone()
			
			-- Remove the previous clone if it exists
			local oldTextLabel = container:FindFirstChild(rank)
			if oldTextLabel then
				oldTextLabel:Destroy()
			end
			
			-- Sets the properties of the new clone
			clone.Text = string.format("%d° | %s | Kills: %d", rank, username, kills)
			clone.Name = rank
			clone.LayoutOrder = rank
			clone.Visible = true
			clone.Parent = container
		end
		
		-- Wait for the next update
		task.wait(leaderboardAutoUpdateTime)
	end
end)

-- Function that handles when a player is added
local function OnPlayerAdded(player: Player)
	-- Setup the player for the DataObject and OrderedDataObject
	data:SetupPlayerForDataObject(player, dataFolder, autoSaveTime) -- Remove if you don't want a DataStore
	PlayerDataService_SetupHelper:SetupPlayerForOrderedDataObjectList(player, orderedDataList, autoSaveTime) -- Remove if you don't want a OrderedDataStore
end

-- Connect the function to the PlayerAdded event
Players.PlayerAdded:Connect(OnPlayerAdded)
