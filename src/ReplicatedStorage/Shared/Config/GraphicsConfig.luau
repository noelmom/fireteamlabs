--!strict
-- Graphics quality tiers (visual-direction pivot; docs/GRAPHICS_QUALITY_TIERS.md).
-- Client-side presentation only — never affects gameplay, hit detection, or
-- competitive visibility. Systems (lighting, viewmodel, effects) read the active
-- tier's settings and scale themselves; gameplay-critical visibility is preserved
-- at every tier.

export type Tier = "Low" | "Medium" | "High"

export type Settings = {
	LightingTechnology: string, -- Enum.Technology name applied to Lighting
	GlobalShadows: boolean,
	ShadowDistanceStuds: number,
	SmallPropShadows: boolean, -- shadows on small props (disabled on Low)
	MaxDynamicLights: number, -- budget for authored non-essential dynamic lights
	ParticleScale: number, -- 0..1 multiplier on emitter rates/counts
	DecalLifetimeScale: number, -- 0..1 multiplier on impact-decal lifetimes
	EnvRenderFidelity: string, -- Enum.RenderFidelity name for environment meshes
	ViewmodelRenderFidelity: string, -- viewmodel is preserved as high as possible
	ReflectionsEnabled: boolean,
}

local GraphicsConfig = {
	-- "Auto" resolves to a concrete tier (see QualityLogic); the slice defaults
	-- to Medium until device auto-detection is wired.
	DefaultSelection = "Auto",
	AutoFallbackTier = "Medium" :: Tier,

	Order = { "Low", "Medium", "High" },

	Tiers = {
		Low = {
			LightingTechnology = "ShadowMap",
			GlobalShadows = true,
			ShadowDistanceStuds = 60,
			SmallPropShadows = false,
			MaxDynamicLights = 4,
			ParticleScale = 0.4,
			DecalLifetimeScale = 0.5,
			EnvRenderFidelity = "Performance",
			ViewmodelRenderFidelity = "Automatic",
			ReflectionsEnabled = false,
		} :: Settings,

		Medium = {
			LightingTechnology = "Future",
			GlobalShadows = true,
			ShadowDistanceStuds = 120,
			SmallPropShadows = false,
			MaxDynamicLights = 8,
			ParticleScale = 0.75,
			DecalLifetimeScale = 0.8,
			EnvRenderFidelity = "Automatic",
			ViewmodelRenderFidelity = "Precise",
			ReflectionsEnabled = true,
		} :: Settings,

		High = {
			LightingTechnology = "Future",
			GlobalShadows = true,
			ShadowDistanceStuds = 200,
			SmallPropShadows = true,
			MaxDynamicLights = 16,
			ParticleScale = 1.0,
			DecalLifetimeScale = 1.0,
			EnvRenderFidelity = "Precise",
			ViewmodelRenderFidelity = "Precise",
			ReflectionsEnabled = true,
		} :: Settings,
	},
}

return GraphicsConfig
