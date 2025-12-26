export type SoldierData = {
	Owner : number,
	Name : string,
	---Class---
	Class : {
		["Cost"] : number,
		["Bloom"] : number,
		["ClipSize"] : number,
		["Damage"] : number,
		["FiringRate"] : number,
		["Range"] : number,
		["ReloadTime"] : number
	},
	---Inventory---
	Inventory: {
		Meds: number,
		Walls: number
	},
	---varuables---
	Shots : number,
	LaststateChange : number,
	StateQueue : {},
	LeftShoulder : CFrame,
	RightShoulder : CFrame,
	Soldier : Model,
	LastEnemieSet : number,
	Connections: {RBXScriptConnection},
	Humanoid: Humanoid,
	HumanoidRootPart : BasePart,
	ShotRules : RaycastParams,
	Loaded : {},
	ClosesEnemy : any?,
	State : any?,
	DistanceToCloses : any?,
	ClosesHumanoid : any?,
	PlantingBomb : any?
}

return {
	Controls = {
	Covering = "Covering",
	Building = "Building",
	Healing = "Healing",
	StopWalking = "StopWalking",
	GunCoolDown = "GunCoolDown",
	PlantingBomb = "PlantingBomb",
	}
}
