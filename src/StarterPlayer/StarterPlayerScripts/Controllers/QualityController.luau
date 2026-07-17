--!strict
-- Applies the active graphics quality tier (visual-direction pivot;
-- docs/GRAPHICS_QUALITY_TIERS.md). It owns the global lighting technology and
-- shadow toggle, and publishes the tier's settings so other client systems
-- (viewmodel, environment, impact VFX) can scale themselves. Presentation only —
-- never affects gameplay, hit detection, or competitive visibility.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraphicsConfig = require(ReplicatedStorage.Shared.Config.GraphicsConfig)
local QualityLogic = require(ReplicatedStorage.Shared.Utility.QualityLogic)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)

local QualityController = {
	Name = "QualityController",
	-- (tier: string, settings: GraphicsConfig.Settings)
	Changed = Signal.new(),
}

local currentTier: string = GraphicsConfig.AutoFallbackTier
local currentSettings = GraphicsConfig.Tiers[GraphicsConfig.AutoFallbackTier]

-- Device auto-detection is limited on Roblox; the slice uses the fallback tier.
-- Future: probe UserGameSettings.SavedQualityLevel or a short frame-time sample.
local function detectAutoTier(): string
	return GraphicsConfig.AutoFallbackTier
end

local function apply(tier: string)
	local settings = GraphicsConfig.Tiers[tier]
	if not settings then
		return
	end
	currentTier = tier
	currentSettings = settings

	local technology = (Enum.Technology :: any)[settings.LightingTechnology]
	if technology then
		Lighting.Technology = technology
	end
	Lighting.GlobalShadows = settings.GlobalShadows

	QualityController.Changed:Fire(tier, settings)
end

function QualityController.GetTier(_self: any): string
	return currentTier
end

function QualityController.GetSettings(_self: any)
	return currentSettings
end

-- Change tier from a settings UI: "Auto" | "Low" | "Medium" | "High".
function QualityController.SetSelection(_self: any, selection: string)
	local tier =
		QualityLogic.resolveTier(GraphicsConfig.Order, selection, detectAutoTier(), GraphicsConfig.AutoFallbackTier)
	apply(tier)
end

function QualityController.Start(_self: any)
	QualityController:SetSelection(GraphicsConfig.DefaultSelection)
end

return QualityController
