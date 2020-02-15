local Heroes = {"Kindred"}

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

-- [ AutoUpdate ]
do
    
    local Version = 0.06
    
    local Files = {
        Lua = {
            Path = SCRIPT_PATH,
            Name = "Kindred.lua",
            Url = "https://raw.githubusercontent.com/Ryckoo/GoS/master/Kindred.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "Kindred.version",
            Url = "https://raw.githubusercontent.com/Ryckoo/GoS/master/Kindred.version"
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
            print("New Kindred Version Press 2x F6")
        else
            print("Rycko`s Kindred loaded")
        end
    
    end
    
    AutoUpdate()

end

----------------------------------------------------
--|                    Utils                     |--
----------------------------------------------------

local TEAM_ALLY = myHero.team
local TEAM_ENEMY = 300 - myHero.team
local TEAM_JUNGLE = 300
local Orb
local Allies, Enemies, Turrets, Units = {}, {}, {}, {}
local TableInsert = table.insert
local Q

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

local function AllyHeroes()
	return Allies
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
--|                Checks              		|--
----------------------------------------------------

local function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

----------------------------------------------------
--|                Champion               		|--
----------------------------------------------------

class "Kindred"

function Kindred:__init()	
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


function Kindred:LoadMenu()                     
	
--MainMenu
self.Menu = MenuElement({type = MENU, id = "RycKo_Kindred", name = "Kindred v 0.06"})
		
--ComboMenu  
self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo Mode"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Combo:MenuElement({id = "UseE", name = "[E]", value = true})	
	
--UltMenu  
self.Menu:MenuElement({type = MENU, id = "Ult", name = "Ultimate Settings"})
	self.Menu.Ult:MenuElement({id = "Move", name = "Stop Orbwalk in UltField", value = true})	
	self.Menu.Ult:MenuElement({id = "UseRself", name = "Use[R] Self", value = true})
	self.Menu.Ult:MenuElement({id = "HpSelf", name = "If Kindred Hp lower than >", value = 30, min = 0, max = 100, identifier = "%"})	
	self.Menu.Ult:MenuElement({id = "UseRally", name = "Use[R] Ally", value = true})	
	self.Menu.Ult:MenuElement({id = "HpAlly", name = "If Ally Hp lower than >", value = 30, min = 0, max = 100, identifier = "%"})	

--LaneClear Menu
self.Menu:MenuElement({type = MENU, id = "Clear", name = "Clear Mode"})	
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Clear:MenuElement({id = "UseW", name = "[W]", value = true})	
	self.Menu.Clear:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})
	
--JungleClear Menu
self.Menu:MenuElement({type = MENU, id = "JClear", name = "JungleClear Mode"})
	self.Menu.JClear:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.JClear:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.JClear:MenuElement({id = "UseE", name = "[E]", value = true})	
	self.Menu.JClear:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})

--LastHitMode Menu
self.Menu:MenuElement({type = MENU, id = "LastHit", name = "LastHit Mode"})
	self.Menu.LastHit:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.LastHit:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.LastHit:MenuElement({id = "UseE", name = "[E]", value = true})
	
--HarassMenu
self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})		
	self.Menu.Harass:MenuElement({id = "UseQ", name = "[Q]", value = true})	
	self.Menu.Harass:MenuElement({id = "UseW", name = "[W]", value = true})
	self.Menu.Harass:MenuElement({id = "UseE", name = "[E]", value = true})
	self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana", value = 40, min = 0, max = 100, identifier = "%"})
		

--KillSteal
self.Menu:MenuElement({type = MENU, id = "ks", name = "KillSteal Settings"})	
	self.Menu.ks:MenuElement({id = "UseQ", name = "[Q]", value = true})
	self.Menu.ks:MenuElement({id = "UseW", name = "[W]", value = true})	
	self.Menu.ks:MenuElement({id = "UseE", name = "[E]", value = true})		

--Drawing 
self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings Mode"})
	self.Menu.Drawing:MenuElement({id = "DrawW", name = "Draw [W] Range", value = true})
	self.Menu.Drawing:MenuElement({id = "DrawE", name = "Draw [E] Range", value = true})		
	
end	

function Kindred:Tick()
if MyHeroNotReady() then return end

local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
		
	elseif Mode == "Harass" then
		self:Harass()
		
	elseif Mode == "Clear" then
		self:JungleClear()
		self:Clear()
		
	elseif Mode == "LastHit" then
		self:LastHit()	
	end	
	self:KillSteal()

	if self.Menu.Ult.Move:Value() and myHero:GetSpellData(_R).level > 0 then
		self:RBuff()
	end
	
	if myHero:GetSpellData(_R).level > 0 then
		for i, target in pairs(EnemyHeroes()) do
			if myHero.pos:DistanceTo(target.pos) <= 1000 and IsValid(target) then	
				self:AutoUltSelf()	
			end
			
			for i, ally in pairs(AllyHeroes()) do
				if myHero.pos:DistanceTo(ally.pos) <= 800 and IsValid(ally) and ally.pos:DistanceTo(target.pos) <= 1000 and IsValid(target) then
					self:AutoUltAlly(ally)
				end
			end
		end	
	end	
end

function Kindred:QBuff()
	if HasBuff(myHero, "kindredqasbuff") then
		return true
	end
	return false
end

function Kindred:RBuff()
	if HasBuff(myHero, "KindredRNoDeathBuff") then
		_G.SDK.Orbwalker:SetMovement(false)
	else
		_G.SDK.Orbwalker:SetMovement(true)
	end	
end
 
function Kindred:Draw()
  if myHero.dead then return end
                                                 
	if self.Menu.Drawing.DrawW:Value() and Ready(_W) then
    Draw.Circle(myHero, 570, 1, Draw.Color(225, 225, 125, 10))
	end
	if self.Menu.Drawing.DrawE:Value() and Ready(_E) then
    Draw.Circle(myHero, myHero.range + 70, 1, Draw.Color(225, 225, 125, 10))
	end			
end

function Kindred:AutoUltSelf()
	if self.Menu.Ult.UseRself:Value() and Ready(_R) then
		if myHero.health/myHero.maxHealth <= self.Menu.Ult.HpSelf:Value() / 100 then
			Control.CastSpell(HK_R)
		end
	end
end

function Kindred:AutoUltAlly(ally)
	if myHero.pos:DistanceTo(ally.pos) <= 500 and self.Menu.Ult.UseRally:Value() and Ready(_R) then
		if ally.health/ally.maxHealth <= self.Menu.Ult.HpAlly:Value() / 100 then
			Control.CastSpell(HK_R)
		end
	end
end

function Kindred:Combo()
local target = GetTarget(myHero.range + 340)     	
if target == nil then return end
	if IsValid(target) then
		
		if self.Menu.Combo.UseQ:Value() and Ready(_Q) then 
			if myHero.pos:DistanceTo(target.pos) <= 340 + myHero.range and myHero.pos:DistanceTo(target.pos) > myHero.range then 
				Control.CastSpell(HK_Q)
		
			end
			if myHero.pos:DistanceTo(target.pos) <= 500 then 
				local castPos = Vector(target) - (Vector(myHero) - Vector(target)):Perpendicular():Normalized() * myHero.range
				Control.CastSpell(HK_Q)				
			end
		end	
		
		if myHero.pos:DistanceTo(target.pos) <= 570 and self.Menu.Combo.UseW:Value() and Ready(_W) and not self:QBuff() then
			Control.CastSpell(HK_W, target.pos)
		end	

		if myHero.pos:DistanceTo(target.pos) <= myHero.range +70 and self.Menu.Combo.UseE:Value() and Ready(_E) then
			Control.CastSpell(HK_E, target)
		end			
	end	
end	

function Kindred:Harass()
local target = GetTarget(myHero.range +340)    	
if target == nil then return end
	if IsValid(target) and myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 then
			
		if self.Menu.Harass.UseQ:Value() and Ready(_Q)  then
			if myHero.pos:DistanceTo(target.pos) <= 340 + myHero.range and myHero.pos:DistanceTo(target.pos) > myHero.range then
				Control.CastSpell(HK_Q)				
			end
			if myHero.pos:DistanceTo(target.pos) <= 500 then 
				local castPos = Vector(target) - (Vector(myHero) - Vector(target)):Perpendicular():Normalized() * myHero.range
				Control.CastSpell(HK_Q)				
			end
		end	
		
		if myHero.pos:DistanceTo(target.pos) <= 570 and self.Menu.Harass.UseW:Value() and Ready(_W) then
				Control.CastSpell(HK_W, target.pos)
		end	

		if myHero.pos:DistanceTo(target.pos) <= myHero.range + 70 and self.Menu.Harass.UseE:Value() and Ready(_E) then
			Control.CastSpell(HK_E, target)
		end			
	end	
end

function Kindred:LastHit()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= myHero.range +340 and minion.team == TEAM_ENEMY and IsValid(minion) then
			
			if myHero.pos:DistanceTo(minion.pos) <= 340 + myHero.range and self.Menu.LastHit.UseQ:Value() and Ready(_Q) then
				local QDmg = getdmg("Q", minion, myHero)				
				if QDmg >= minion.health then
					Control.CastSpell(HK_Q, castPos)
				end
			end				
			
			if myHero.pos:DistanceTo(minion.pos) <= 570 and self.Menu.LastHit.UseW:Value() and Ready(_W) then
				local WDmg = getdmg("W", minion, myHero)
				if WDmg >= minion.health then
					Control.CastSpell(HK_W) 
				end
			end	
			
			if myHero.pos:DistanceTo(minion.pos) <= myHero.range +70 and self.Menu.LastHit.UseE:Value() and Ready(_E) then
				local EDmg = getdmg("E", minion, myHero)
				if EDmg >= minion.health then
				Control.CastSpell(HK_E, minion)
				end
			end			
		end
	end
end

function Kindred:JungleClear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= myHero.range +340 and minion.team == TEAM_JUNGLE and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.JClear.Mana:Value() / 100 then

			if self.Menu.JClear.UseQ:Value() and Ready(_Q) and not HasBuff(myHero, "KindredRNoDeathBuff") then 
				if myHero.pos:DistanceTo(minion.pos) <= (340 + myHero.range) and myHero.pos:DistanceTo(minion.pos) > myHero.range then 
					Control.CastSpell(HK_Q)				
				end
			end
			if myHero.pos:DistanceTo(minion.pos) <= 500 and self.Menu.JClear.UseW:Value() and Ready(_W) then
				Control.CastSpell(HK_W)
			end 
			
			if myHero.pos:DistanceTo(minion.pos) <= myHero.range +70 and self.Menu.JClear.UseE:Value() and Ready(_E) then
				Control.CastSpell(HK_E, minion)
			end	
		end
	end
end
			
function Kindred:Clear()
	for i = 1, Game.MinionCount() do
    local minion = Game.Minion(i)

		if myHero.pos:DistanceTo(minion.pos) <= myHero.range +340 and minion.team == TEAM_ENEMY and IsValid(minion) and myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 then

			if self.Menu.Clear.UseQ:Value() and Ready(_Q) and not HasBuff(myHero, "KindredRNoDeathBuff") then
				if myHero.pos:DistanceTo(minion.pos) <= 340 + myHero.range and myHero.pos:DistanceTo(minion.pos) > myHero.range then 
					Control.CastSpell(HK_Q)				
				end
				if myHero.pos:DistanceTo(minion.pos) <= 500 then 
					local castPos = Vector(minion) - (Vector(myHero) - Vector(minion)):Perpendicular():Normalized() * myHero.range
					Control.CastSpell(HK_Q)				
				end
			end
	
			if myHero.pos:DistanceTo(minion.pos) <= 570 and self.Menu.Clear.UseW:Value() and Ready(_W) then
				Control.CastSpell(HK_W)
			end	 
			
			if myHero.pos:DistanceTo(minion.pos) <= myHero.range + 70 and self.Menu.Clear.UseE:Value() and Ready(_E) then
				Control.CastSpell(HK_E, minion)
			end	
		end
    end
end

function Kindred:KillSteal()
	for i, target in pairs(EnemyHeroes()) do
	
		if myHero.pos:DistanceTo(target.pos) <= myHero.range +340 and IsValid(target) then
		
			if myHero.pos:DistanceTo(target.pos) <= 340 + myHero.range and self.Menu.ks.UseQ:Value() and Ready(_Q) then
				local QDmg = getdmg("Q", target, myHero)			
				if QDmg >= target.health then
					Control.CastSpell(HK_Q, target.pos)
				end
			end			
			
			if myHero.pos:DistanceTo(target.pos) <= 570 and self.Menu.ks.UseW:Value() and Ready(_W) then
				local WDmg = getdmg("W", target, myHero)
				if WDmg >= target.health then
					Control.CastSpell(HK_W)
				end
			end	

			if myHero.pos:DistanceTo(target.pos) <= myHero.range +70 and self.Menu.ks.UseE:Value() and Ready(_E) then
				local EDmg = getdmg("E", target, myHero)
				if EDmg >= target.health then
					Control.CastSpell(HK_E, target)
				end
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
