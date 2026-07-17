--!strict
-- Shared type definitions.

export type TeamId = "Alpha" | "Bravo"

export type RoundPhase = "PreRound" | "Active" | "Overtime" | "PostRound"

export type MatchPhase = "WaitingForPlayers" | "InProgress" | "PostMatch"

export type WeaponSlot = "Primary" | "Special" | "Heavy" | "Knife"

export type ClassId = "Specter" | "Conduit" | "Bulwark"

export type MatchState = {
	MatchId: string,
	Phase: MatchPhase,
	RoundNumber: number,
	RoundPhase: RoundPhase,
	Scores: { [TeamId]: number },
}

return nil
