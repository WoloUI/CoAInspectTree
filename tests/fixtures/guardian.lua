return {
  tree = {
    { ID = 1719,  Name = "Seasoned Fighter", Icon = "Ability_SteelMelee",
      Tab = "Protection", PositionX = 2, PositionY = 4, SizeX = 64, SizeY = 64,
      NodeType = "SpendCircle", Type = "Talent", Color = "TEAL", Quality = "Normal",
      ConnectedNodes = { 6712, 11060 }, RequiredIDs = {} },
    { ID = 31319, Name = "With Honor", Icon = "inv_shoulder_plate_raidpaladin_s_01",
      Tab = "Protection", PositionX = 6, PositionY = 2, SizeX = 64, SizeY = 64,
      NodeType = "SpendCircle", Type = "Talent", Color = "TEAL", Quality = "Normal",
      ConnectedNodes = { 30056 }, RequiredIDs = {} },
    { ID = 30056, Name = "Iron Guardian", Icon = "garrison_building_armory",
      Tab = "Protection", PositionX = 4, PositionY = 1, SizeX = 64, SizeY = 64,
      NodeType = "SpendCircle", Type = "Talent", Color = "TEAL", Quality = "Normal",
      ConnectedNodes = { 31169 }, RequiredIDs = {} },
    { ID = 31169, Name = "Heavy Blow", Icon = "spell_paladin_hammerofwrath",
      Tab = "Protection", PositionX = 4, PositionY = 0, SizeX = 64, SizeY = 64,
      NodeType = "SpendSquare", Type = "Talent", Color = "TEAL", Quality = "Normal",
      ConnectedNodes = {}, RequiredIDs = { 4019, 30057 } },
    { ID = 6455,  Name = "Gallant", Icon = "INV_Chest_Plate04",
      Tab = "Class", PositionX = 4, PositionY = 1, SizeX = 64, SizeY = 64,
      NodeType = "SpendCircle", Type = "Talent", Color = "TEAL", Quality = "Normal",
      ConnectedNodes = {}, RequiredIDs = {} },
  },
  -- Build aprendida (subconjunto): With Honor rank1, Iron Guardian rank2.
  build = {
    [31319] = { rank = 1, maxRank = 1 },
    [30056] = { rank = 2, maxRank = 3 },
  },
}
