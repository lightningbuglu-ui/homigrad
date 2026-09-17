-- Gun bash for Homigrad/JMod guns.
-- Hold USE (E) and press ATTACK (LMB) to strike with the weapon instead of firing it.

local GUN_BASH_ANIMATION = "Melee_gunhit"
local GUN_BASH_RANGE = 58
local GUN_BASH_DAMAGE = 25
local GUN_BASH_COOLDOWN = 0.75
local GUN_BASH_HIT_DELAY = 0.22

local function isGunBashWeapon(wep)
    if not IsValid(wep) then return false end
    if wep.CanBash == false then return false end
    if wep:GetClass() == "weapon_hands" then return false end

    return wep.GunBash == true
        or wep.ArcCW == true
        or wep.ishgweapon == true
        or wep.Base == "wep_jack_gmod_gunbase"
end

local function playGunBashAnimation(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return end

    if CLIENT then
        local vm = ply:GetViewModel()
        if IsValid(vm) then
            local sequence = vm:LookupSequence(GUN_BASH_ANIMATION)
            if sequence and sequence >= 0 then
                vm:SendViewModelMatchingSequence(sequence)
                vm:SetPlaybackRate(1)
            else
                wep:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            end
        end

        ply:ViewPunch(Angle(-2, -3, 0))
    end

    ply:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2)
end

local function applyGunBashDamage(wep, ply)
    if not IsValid(wep) or not IsValid(ply) or not ply:Alive() then return end
    if ply:GetActiveWeapon() ~= wep then return end

    ply:LagCompensation(true)

    local start = ply:GetShootPos()
    local trace = util.TraceHull({
        start = start,
        endpos = start + ply:GetAimVector() * GUN_BASH_RANGE,
        filter = ply,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),
        mask = MASK_SHOT_HULL
    })

    if trace.Hit and IsValid(trace.Entity) then
        local damage = DamageInfo()
        damage:SetAttacker(ply)
        damage:SetInflictor(wep)
        damage:SetDamage(GUN_BASH_DAMAGE)
        damage:SetDamageType(DMG_CLUB)
        damage:SetDamagePosition(trace.HitPos)
        damage:SetDamageForce(ply:GetAimVector() * 4500)
        trace.Entity:TakeDamageInfo(damage)

        local physics = trace.Entity:GetPhysicsObject()
        if IsValid(physics) then
            physics:ApplyForceOffset(ply:GetAimVector() * 250 * physics:GetMass(), trace.HitPos)
        end

        wep:EmitSound("physics/body/body_medium_impact_hard2.wav", 65, 100)
    else
        wep:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 65, 100)
    end

    ply:LagCompensation(false)
end

local function startGunBash(ply, wep)
    local nextBash = wep.HG_GunBashNext or 0
    if nextBash > CurTime() then return end

    wep.HG_GunBashNext = CurTime() + GUN_BASH_COOLDOWN
    wep:SetNextPrimaryFire(wep.HG_GunBashNext)
    wep:SetNextSecondaryFire(wep.HG_GunBashNext)
    playGunBashAnimation(ply, wep)

    timer.Simple(GUN_BASH_HIT_DELAY, function()
        if SERVER then
            applyGunBashDamage(wep, ply)
        end
    end)
end

hook.Add("StartCommand", "HG_GunBash", function(ply, cmd)
    if not IsValid(ply) or not ply:Alive() then return end

    local wep = ply:GetActiveWeapon()
    local buttons = cmd:GetButtons()
    local useDown = bit.band(buttons, IN_USE) ~= 0
    local attackDown = bit.band(buttons, IN_ATTACK) ~= 0
    local attackPressed = attackDown and not ply.HG_GunBashAttackDown

    -- Store the LMB state so holding E and holding LMB does not repeatedly
    -- bash. LMB must transition from up to down while E is already held.
    ply.HG_GunBashAttackDown = attackDown

    if not isGunBashWeapon(wep) or not useDown or not attackPressed then return end

    local commandNumber = cmd:CommandNumber()
    if ply.HG_GunBashCommand == commandNumber then return end
    ply.HG_GunBashCommand = commandNumber

    -- Prevent this LMB press from also firing a bullet.
    cmd:SetButtons(bit.band(buttons, bit.bnot(IN_ATTACK)))
    startGunBash(ply, wep)
end)

hook.Add("PlayerDeath", "HG_GunBashCleanup", function(ply)
    ply.HG_GunBashCommand = nil
    ply.HG_GunBashAttackDown = nil
end)
