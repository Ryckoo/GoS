local Heroes = {"Graves"}

if not table.contains(Heroes, myHero.charName) then return end


----------------------------------------------------
--|          Lib and Update Checks               |--
----------------------------------------------------

if not FileExist(COMMON_PATH .. "PussyDamageLib.lua") then
	print("PussyDamageLib. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/Pussykate/GoS/master/PussyDamageLib.lua", COMMON_PATH .. "PussyDamageLib.lua", function() end)
	while not FileExist(COMMON_PATH .. "PussyDamageLib.lua") do end
end
    
require('PussyDamageLib')

if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
	print("GsoPred. installed Press 2x F6")
	DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GOS-EXT/master/Common/GamsteronPrediction.lua", COMMON_PATH .. "GamsteronPrediction.lua", function() end)
	while not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") do end
end
    
require('GamsteronPrediction')


--[[
-- [ AutoUpdate ]
do
    
    local Version = 0.02
    
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "Chogath.lua",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyIrelia.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "Chogath.version",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/PussyIrelia.version"
        }
    }
    
    local function AutoUpdate()
        
        local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
        
        local function ReadFile(path, fileName)
            local file = io.open(path .. fileName, "r")
            local result = file:read()
            file:close()
            return result
        end
        
        DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
        local textPos = myHero.pos:To2D()
        local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
        if NewVersion > Version then
            DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
            print("New Yoshi-Chogath Version Press 2x F6")
        else
            print("Chogath loaded")
        end
    
    end
    
    AutoUpdate()

end
]]


----------------------------------------------------
				--|      Utils     |--
----------------------------------------------------

local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - myHero.team
local TEAM_JUNGLE = 300
local Orb
local Allies, Enemies, Turrets, Units = {}, {}, {}, {}
local TableInsert = table.insert

function LoadUnits()
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i); Units[i] = {unit = unit, spell = nil}
		if unit.team ~= myHero.team then TableInsert(Enemies, unit)
		elseif unit.team == myHero.team and unit ~= myHero then TableInsert(Allies, unit) end
	end
	for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i)
		if turret and turret.isEnemy then TableInsert(Turrets, turret) end
	end
end

local function EnemyHeroes()
	return Enemies
end

local function Ready(spell)
    return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0
end

local function IsValid(unit)
    if (unit and unit.valid and unit.isTargetable and unit.alive and unit.visible and unit.networkID and unit.pathing and unit.health > 0) then
        return true;
    end
    return false;
end

local function IsRecalling(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and buff.name == 'recall' and buff.duration > 0 then
            return true, Game.Timer() - buff.startTime
        end
    end
    return false
end

local function MyHeroNotReady()
    return myHero.dead or Game.IsChatOpen() or (_G.JustEvade and _G.JustEvade:Evading()) or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) or IsRecalling(myHero)
end

local function GetTarget(range) 
	if Orb == 1 then
		if myHero.ap > myHero.totalDamage then
			return EOW:GetTarget(range, EOW.ap_dec, myHero.pos)
		else
			return EOW:GetTarget(range, EOW.ad_dec, myHero.pos)
		end
	elseif Orb == 2 and SDK.TargetSelector then
		if myHero.ap > myHero.totalDamage then
			return SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_MAGICAL)
		else
			return SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL)
		end
	elseif _G.GOS then
		if myHero.ap > myHero.totalDamage then
			return GOS:GetTarget(range, "AP")
		else
			return GOS:GetTarget(range, "AD")
        end
    elseif _G.gsoSDK then
		return _G.gsoSDK.TS:GetTarget()
	end
end

local function GetMode()
    
    if Orb == 1 then
        if combo == 1 then
            return 'Combo'
        elseif harass == 2 then
            return 'Harass'
        elseif lastHit == 3 then
            return 'Lasthit'
        elseif laneClear == 4 then
            return 'Clear'
        end
    elseif Orb == 2 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
    elseif Orb == 3 then
        return GOS:GetMode()
    elseif Orb == 4 then
        return _G.gsoSDK.Orbwalker:GetMode()
    end
end



----------------------------------------------------
--|                Checks              		     |--
----------------------------------------------------

local function GetDistanceSqr(p1, p2)
	if not p1 then return math.huge end
	p2 = p2 or myHero
	local dx = p1.x - p2.x
	local dz = (p1.z or p1.y) - (p2.z or p2.y)
	return dx*dx + dz*dz
end

local function GetDistance(p1, p2)
	p2 = p2 or myHero
	return math.sqrt(GetDistanceSqr(p1, p2))
end

local function GetMinionCount(range, pos)
    local pos = pos.pos
	local count = 0
	for i = 1,Game.MinionCount() do
	local hero = Game.Minion(i)
	local Range = range * range
		if hero.team ~= TEAM_ALLY and hero.dead == false and GetDistanceSqr(pos, hero.pos) < Range then
		count = count + 1
		end
	end
	return count
end
	
----------------------------------------------------
--|                Champion               		|--
----------------------------------------------------

class "Graves"

function Graves:__init()	
	self:LoadMenu()                                            
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end) 
	
	if _G.EOWLoaded then
		Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
		Orb = 2
	elseif _G.GOS then
		Orb = 3
	elseif _G.gsoSDK then
		Orb = 4
	end	
end

local QData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 50, Range = 925, Speed = 900, Collision = false 
}

local WData =
{
Type = _G.SPELLTYPE_CIRCLE, Delay = 0.25, Radius = 250, Range = 950, Speed = 1650, Collision = false
}

local RData =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 100, Range = 1000, Speed = 1400, Collision = false	
}

local R2Data =
{
Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 100, Range = 1800, Speed = 1400, Collision = false	
}

function Graves:LoadMenu()                     
	
--MainMenu
self.Menu = MenuElement({type = MENU, id = "Rycko_Graves", name = "Graves Version 0.02"})
		
--ComboMenu  
self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Mode"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})	

--LaneClear Menu
self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear Mode"})	
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.Clear:MenuElement({id = "countQ", name = "[Q] min Minions", value = 2, min = 0, max = 7, identifier = "Minion/s"})	
	self.Menu.Clear:MenuElement({id = "UseW", name = "[W]", value = true})	
	self.Menu.Clear:MenuElement({id = "countW", name = "[W] min Minions", value = 2, min = 0, max = 7, identifier = "Minion/s"})
	self.Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})
		
--JungleClear Menu
self.Menu:MenuElement({type = MENU, id = "JClear", name = "JungleClear Mode"})
	self.Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.JClear:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.JClear:MenuElement({id = "UseE", name = "[E]", value = true})	
	self.Menu.JClear:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})	

--HarassMenu
self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})		
	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Harass:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})
	
--Prediction
self.Menu:MenuElement({type = MENU, id = "Pred", name = "Prediction"})
	self.Menu.Pred:MenuElement({id = "PredQ", name = "Hitchance[Q]", value = 1, drop = {"Normal", "High", "Immobile"}})
	self.Menu.Pred:MenuElement({id = "PredW", name = "Hitchance[W]", value = 1, drop = {"Normal", "High", "Immobile"}})
	self.Menu.Pred:MenuElement({id = "PredR", name = "Hitchance[R]", value = 1, drop = {"Normal", "High", "Immobile"}})	

--KillSteal
self.Menu:MenuElement({type = MENU, id = "ks", name = "KillSteal Settings"})
	self.Menu.ks:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.ks:MenuElement({id = "UseW", name = "[W]", value = true})		
	self.Menu.ks:MenuElement({id = "UseR", name = "[R]", value = true})	
	self.Menu.ks:MenuElement({id = "UseE", name = "Use[E] for Gapclose (Full Spells Dmg)", value = true})

--AntiGapClose 
self.Menu:MenuElement({type = MENU, id = "AntiGap", name = "AntiGapclose Mode"})
	self.Menu.AntiGap:MenuElement({id = "UseE", name = "[E]", value = true})		

--Drawing 
self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings Mode"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true})
	self.Menu.Drawing:MenuElement({id = "DrawW", name = "Draw [W] Range", value = true})	
	self.Menu.Drawing:MenuElement({id = "DrawE", name = "Draw [E] Range", value = true})	
	self.Menu.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true})		
end	

function Graves:Tick()
if MyHeroNotReady() then return end

local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
		
	elseif Mode == "Harass" then
		self:Harass()
		
	elseif Mode == "Clear" then
		self:JungleClear()
		self:Clear()	
	end		
	
	self:KillSteal()
	self:AntiGapClose()	
  	
end
 
function Graves:Draw()
  if myHero.dead then return end
                                                 
	if self.Menu.Drawing.DrawQ:Value() and Ready(_Q) then
    Draw.Circle(myHero, 925, 1, Draw.Color(225, 225, 0, 10))
	end
	if self.Menu.Drawing.DrawW:Value() and Ready(_W) then
    Draw.Circle(myHero, 950, 1, Draw.Color(225, 225, 125, 10))
	end
	if self.Menu.Drawing.DrawE:Value() and Ready(_E) then
    Draw.Circle(myHero, 425, 1, Draw.Color(225, 125, 125, 10))
	end
	if self.Menu.Drawing.DrawR:Value() and Ready(_R) then
    Draw.Circle(myHero, 1000, 1, Draw.Color(125, 225, 125, 10))
	end	
	local textPos = myHero.dir	
	if not FileExist(COMMON_PATH .. "GamsteronPrediction.lua") then
		Draw.Text("GsoPred. installed Press 2x F6", 50, textPos.x + 100, textPos.y - 250, Draw.Color(255, 255, 0, 0))
	end			
end

function Graves:AntiGapClose()
	for i, target in ipairs(EnemyHeroes()) do
		if myHero.pos:DistanceTo(target.pos) <= 1000 and IsValid(target) and self.Menu.AntiGap.UseE:Value() and Ready(_E) then
			if target.pathing.isDashing and target.pathing.dashSpeed > 500 and GetDistance(target.pos, myHero.pos) > GetDistance(Vector(target.pathing.endPos), myHero.pos) then
			local castPos = myHero.pos:Extended(target.pos, -425)	
				Control.CastSpell(HK_E, castPos)
			end	
		end
	end
end	

function Graves:Combo()
local target = GetTarget(1000)     	
if target == nil then return end
	if IsValid(target) then
		
		if myHero.pos:DistanceTo(target.pos) <= 925 and self.Menu.Combo.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 and not myHero.pathing.isDashing then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end

		if myHero.pos:DistanceTo(target.pos) <= 950 and self.Menu.Combo.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredW:Value() + 1 and not myHero.pathing.isDashing then	
				Control.CastSpell(HK_W, pred.CastPosition)
			end	
		end
		
		if self.Menu.Combo.UseE:Value() and Ready(_E) then
			if myHero.pos:DistanceTo(target.pos) <= 425 + myHero.range and myHero.pos:DistanceTo(target.pos) > myHero.range then 
				Control.CastSpell(HK_E, target.pos)				
			end
			if myHero.pos:DistanceTo(target.pos) <= 350 then 
				local castPos = Vector(target) - (Vector(myHero) - Vector(target)):Perpendicular():Normalized() * myHero.range
				Control.CastSpell(HK_E, castPos)				
			end
		end		
	end	
end	

function Graves:Harass()
local target = GetTarget(1000)     	
if target == nil then return end
	if IsValid(target) and myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 then
			
		if myHero.pos:DistanceTo(target.pos) <= 925 and self.Menu.Harass.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 and not myHero.pathing.isDashing then
				Control.CastSpell(HK_Q, pred.CastPosition)
			end
		end

		if myHero.pos:DistanceTo(target.pos) <= 950 and self.Menu.Harass.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredW:Value() + 1 and not myHero.pathing.isDashing then
				Control.CastSpell(HK_W, pred.CastPosition)
			end	
		end
		
		if self.Menu.Harass.UseE:Value() and Ready(_E) then
			if myHero.pos:DistanceTo(target.pos) <= 425 + myHero.range and myHero.pos:DistanceTo(target.pos) > myHero.range then 
				Control.CastSpell(HK_E, target.pos)				
			end
			if myHero.pos:DistanceTo(target.pos) <= 350 then 
				local castPos = Vector(target) - (Vector(myHero) - Vector(target)):Perpendicular():Normalized() * myHero.range
				Control.CastSpell(HK_E, castPos)				
			end
		end			
	end	
end	

function Graves:JungleClear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_JUNGLE and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.JClear.Mana:Value() / 100 then

			if myHero.pos:DistanceTo(minion.pos) <= 925 and self.Menu.JClear.UseQ:Value() and Ready(_Q) and not myHero.pathing.isDashing then
				Control.CastSpell(HK_Q, minion.pos)
			end

			if myHero.pos:DistanceTo(minion.pos) <= 950 and self.Menu.JClear.UseW:Value() and Ready(_W) and not myHero.pathing.isDashing then
				Control.CastSpell(HK_W, minion.pos)
			end 
			
			if self.Menu.JClear.UseE:Value() and Ready(_E) then
				if myHero.pos:DistanceTo(minion.pos) <= 425 + myHero.range and myHero.pos:DistanceTo(minion.pos) > myHero.range then 
					Control.CastSpell(HK_E, minion.pos)				
				end
				if myHero.pos:DistanceTo(minion.pos) <= 350 then 
					local castPos = Vector(minion) - (Vector(myHero) - Vector(minion)):Perpendicular():Normalized() * myHero.range
					Control.CastSpell(HK_E, castPos)				
				end
			end		 			
        end
    end
end
			
function Graves:Clear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= 1000 and minion.team == TEAM_ENEMY and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 then		
			
			if myHero.pos:DistanceTo(minion.pos) <= 925 and self.Menu.Clear.UseQ:Value() and Ready(_Q) and not myHero.pathing.isDashing then
				local Qcount = GetMinionCount(175, minion)
				if Qcount >= self.Menu.Clear.countQ:Value() then
				Control.CastSpell(HK_Q, minion.pos)	
				end
			end
			if myHero.pos:DistanceTo(minion.pos) <= 950 and self.Menu.Clear.UseW:Value() and Ready(_W) and not myHero.pathing.isDashing then
				local Wcount = GetMinionCount(175, minion)
				if Wcount >= self.Menu.Clear.countW:Value() then
				Control.CastSpell(HK_W, minion.pos)	
				end
			end
			
			if self.Menu.Clear.UseE:Value() and Ready(_E) then
				if myHero.pos:DistanceTo(minion.pos) <= 425 + myHero.range and myHero.pos:DistanceTo(minion.pos) > myHero.range then 
					Control.CastSpell(HK_E, minion.pos)				
				end
				if myHero.pos:DistanceTo(minion.pos) <= 350 then 
					local castPos = Vector(minion) - (Vector(myHero) - Vector(minion)):Perpendicular():Normalized() * myHero.range
					Control.CastSpell(HK_E, castPos)				
				end
			end	
		end
	end
end

function Graves:KillSteal()
	for i, target in pairs(EnemyHeroes()) do

		if myHero.pos:DistanceTo(target.pos) <= 2000 and IsValid(target) then
		
			if self.Menu.ks.UseE:Value() and Ready(_E) then	
			local QDmg = getdmg("Q", target, myHero)
			local WDmg = getdmg("W", target, myHero)
			local RDmg = getdmg("R", target, myHero, 1)
			local FullDmg = QDmg + WDmg + RDmg
			local ReadySpells = Ready(_Q) and Ready(_W) and Ready(_R)
				
				if ReadySpells and myHero.pos:DistanceTo(target.pos) < 1300 and myHero.pos:DistanceTo(target.pos) > 925 and FullDmg > target.health then
					Control.CastSpell(HK_E, target.pos)
				end
				
				if FullDmg > target.health then
					self:FullKS(target)
				end	
			end				
			
			if self.Menu.ks.UseQ:Value() and Ready(_Q) then
			local pred = GetGamsteronPrediction(target, QData, myHero)
			local QDmg = getdmg("Q", target, myHero)		
				if myHero.pos:DistanceTo(target.pos) <= 925 then
					if QDmg >= target.health and pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 and not myHero.pathing.isDashing then
						Control.CastSpell(HK_Q, pred.CastPosition)
					end
				end
				if myHero.pos:DistanceTo(target.pos) < 1300 and myHero.pos:DistanceTo(target.pos) > 925 and Ready(_E) then
					if QDmg >= target.health then
						Control.CastSpell(HK_E, target.pos)
					end
				end				
			end

			if myHero.pos:DistanceTo(target.pos) <= 950 and self.Menu.ks.UseW:Value() and Ready(_W) then
			local pred = GetGamsteronPrediction(target, WData, myHero)
			local WDmg = getdmg("W", target, myHero)		
				if myHero.pos:DistanceTo(target.pos) <= 950 then
					if WDmg >= target.health and pred.Hitchance >= self.Menu.Pred.PredW:Value() + 1 and not myHero.pathing.isDashing then
						Control.CastSpell(HK_W, pred.CastPosition)
					end
				end
				if myHero.pos:DistanceTo(target.pos) < 1350 and myHero.pos:DistanceTo(target.pos) > 950 and Ready(_E) then 
					if WDmg >= target.health then
						Control.CastSpell(HK_E, target.pos)
					end
				end		
			end	

			if self.Menu.ks.UseR:Value() and Ready(_R) then
				if myHero.pos:DistanceTo(target.pos) <= 1000 then
					local pred = GetGamsteronPrediction(target, RData, myHero)
					local RDmg = getdmg("R", target, myHero, 1)	
					if RDmg >= target.health and pred.Hitchance >= self.Menu.Pred.PredR:Value() + 1 and not myHero.pathing.isDashing then
						Control.CastSpell(HK_R, pred.CastPosition)
					end
				end
				if myHero.pos:DistanceTo(target.pos) > 1000 and myHero.pos:DistanceTo(target.pos) < 1800 then
					local pred = GetGamsteronPrediction(target, R2Data, myHero)
					local RDmg = getdmg("R", target, myHero, 2)	
					if RDmg >= target.health and pred.Hitchance >= self.Menu.Pred.PredR:Value() + 1 and not myHero.pathing.isDashing then
						Control.CastSpell(HK_R, pred.CastPosition)
					end
				end				
			end	
		end
	end
end

function Graves:FullKS(target)
		
	if myHero.pos:DistanceTo(target.pos) <= 925 and Ready(_Q) then
		local pred = GetGamsteronPrediction(target, QData, myHero) 
		if pred.Hitchance >= self.Menu.Pred.PredQ:Value() + 1 and not myHero.pathing.isDashing then
			Control.CastSpell(HK_Q, pred.CastPosition)
		end
	end

	if myHero.pos:DistanceTo(target.pos) <= 950 and Ready(_W) then
		local pred = GetGamsteronPrediction(target, WData, myHero)
		if pred.Hitchance >= self.Menu.Pred.PredW:Value() + 1 and not myHero.pathing.isDashing then
			Control.CastSpell(HK_W, pred.CastPosition)
		end	
	end	

	if Ready(_R) then
		if myHero.pos:DistanceTo(target.pos) <= 1000 then
			local pred = GetGamsteronPrediction(target, RData, myHero)
			if pred.Hitchance >= self.Menu.Pred.PredR:Value() + 1 and not myHero.pathing.isDashing then
				Control.CastSpell(HK_R, pred.CastPosition)
			end
		end			
	end	
end	

function OnLoad()
	if table.contains(Heroes, myHero.charName) then
		_G[myHero.charName]()
		LoadUnits()
	end
end
