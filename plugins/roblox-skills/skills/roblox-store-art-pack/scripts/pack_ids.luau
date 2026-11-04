-- List every icon in an inserted Creator Store pack as "Folder/Name = image id", check that
-- each one loads, and lay them all out in StarterGui.IconSheet for one screenshot.
-- Run with Studio MCP execute_luau (Edit) after insert_asset put the pack under ServerStorage.
-- Single decals: game:GetObjects("rbxassetid://<decalId>")[1].Texture gives the image id.
-- Delete StarterGui.IconSheet afterwards.
local ROOT = game.ServerStorage:FindFirstChild("IconPack") -- the name given to insert_asset

local SG = game:GetService("StarterGui")
if SG:FindFirstChild("IconSheet") then
	SG.IconSheet:Destroy()
end
local sg = Instance.new("ScreenGui")
sg.Name = "IconSheet"
local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(70, 90, 120)
bg.Parent = sg
local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(70, 70)
grid.CellPadding = UDim2.fromOffset(4, 4)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = bg

local labels, lines = {}, {}
for _, d in ROOT:GetDescendants() do
	local id = (d:IsA("Decal") and d.Texture) or ((d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Image) or nil
	if id and id ~= "" then
		local name = d.Parent.Parent.Name .. "/" .. d.Parent.Name
		local l = Instance.new("ImageLabel")
		l.BackgroundTransparency = 1
		l.ScaleType = Enum.ScaleType.Fit
		l.Image = id
		l.LayoutOrder = #labels + 1
		l.Name = name
		l.Parent = bg
		table.insert(labels, l)
		table.insert(lines, string.format("%d %s = %s", #labels, name, id))
	end
end
sg.Parent = SG

local failed = {}
game:GetService("ContentProvider"):PreloadAsync(labels, function(id, status)
	if status ~= Enum.AssetFetchStatus.Success then
		table.insert(failed, id .. " " .. status.Name)
	end
end)
return table.concat(lines, "\n") .. "\nfailed: " .. (#failed == 0 and "none" or table.concat(failed, ", "))
