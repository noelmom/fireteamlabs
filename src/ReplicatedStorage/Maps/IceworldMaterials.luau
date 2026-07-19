--!strict
-- Iceworld PBR material variants (visual-direction pivot, #57's FY_ICEWORLD
-- fidelity target). Generated with Studio's material generator on 2026-07-18;
-- each entry carries the full PBR map set as cloud assets. ensure() creates
-- the MaterialVariants in MaterialService at runtime — parts opt in by setting
-- Material = BaseMaterial and MaterialVariant = the variant name.

local MaterialService = game:GetService("MaterialService")

export type VariantDef = {
	BaseMaterial: Enum.Material,
	Pattern: Enum.MaterialPattern,
	ColorMap: string,
	NormalMap: string,
	MetalnessMap: string,
	RoughnessMap: string,
	StudsPerTile: number,
}

local IceworldMaterials = {
	Variants = {
		iceworld_fortress_stone = {
			BaseMaterial = Enum.Material.Slate,
			Pattern = Enum.MaterialPattern.Organic,
			ColorMap = "rbxassetid://75401131085822",
			NormalMap = "rbxassetid://87859877363799",
			MetalnessMap = "rbxassetid://99917766936762",
			RoughnessMap = "rbxassetid://119701954000131",
			StudsPerTile = 14,
		},
		iceworld_metal_panel = {
			BaseMaterial = Enum.Material.Metal,
			Pattern = Enum.MaterialPattern.Regular,
			ColorMap = "rbxassetid://96769573181023",
			NormalMap = "rbxassetid://85655002070927",
			MetalnessMap = "rbxassetid://136023943188685",
			RoughnessMap = "rbxassetid://91886985151282",
			StudsPerTile = 8,
		},
		iceworld_concrete_floor = {
			BaseMaterial = Enum.Material.Concrete,
			Pattern = Enum.MaterialPattern.Regular,
			ColorMap = "rbxassetid://114212530949411",
			NormalMap = "rbxassetid://121705041407447",
			MetalnessMap = "rbxassetid://106664646119260",
			RoughnessMap = "rbxassetid://86062971136629",
			StudsPerTile = 10,
		},
		iceworld_deck_grate = {
			BaseMaterial = Enum.Material.DiamondPlate,
			Pattern = Enum.MaterialPattern.Regular,
			ColorMap = "rbxassetid://120801989296998",
			NormalMap = "rbxassetid://108494966190573",
			MetalnessMap = "rbxassetid://75379405145033",
			RoughnessMap = "rbxassetid://102728743016818",
			StudsPerTile = 6,
		},
	} :: { [string]: VariantDef },
}

-- Creates every variant in MaterialService (idempotent).
function IceworldMaterials.ensure()
	for name, def in IceworldMaterials.Variants do
		if MaterialService:FindFirstChild(name) then
			continue
		end
		local variant = Instance.new("MaterialVariant")
		variant.Name = name
		variant.BaseMaterial = def.BaseMaterial
		variant.MaterialPattern = def.Pattern
		variant.ColorMap = def.ColorMap
		variant.NormalMap = def.NormalMap
		variant.MetalnessMap = def.MetalnessMap
		variant.RoughnessMap = def.RoughnessMap
		variant.StudsPerTile = def.StudsPerTile
		variant.Parent = MaterialService
	end
end

return IceworldMaterials
