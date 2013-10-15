local canFire = true
local launchV = 0.8
local bombs = {}

local allowedTeams = {["Army"] = true}

local biggestDiff = 0

function isPedAiming ( thePedToCheck )
	if isElement(thePedToCheck) then
		if getElementType(thePedToCheck) == "player" or getElementType(thePedToCheck) == "ped" then
			if getPedTask(thePedToCheck, "secondary", 0) == "TASK_SIMPLE_USE_GUN" then
				return true
			end
		end
	end
	return false
end

function fireNade()
	if getPlayerTeam(localPlayer) and allowedTeams[getTeamName(getPlayerTeam(localPlayer))] then
		if getPedWeapon(localPlayer) == 30 and not(isPlayerDead(localPlayer)) and (not isPedInVehicle(localPlayer)) and isPedAiming(localPlayer) then
			if canFire then
				local pvx, pvy, pvz = getElementVelocity(localPlayer)
				local px, py, pz = getElementPosition(localPlayer)
				local mx, my, mz = getPedWeaponMuzzlePosition(localPlayer)
				local tx, ty, tz = getPedTargetCollision(localPlayer)
				if not (tx and ty and tz) then
					tx, ty, tz = getPedTargetEnd(localPlayer)
				end
				if mx and my and mz and tx and ty and tz then
					local speed = getDistanceBetweenPoints3D(mx, my, mz, tx, ty, tz)
					local coef = launchV / speed
					local nx, ny, nz = ((tx-mx) * coef) + pvx, ((ty-my) * coef) + pvy, ((tz-mz) * coef) + pvz + 0.1
					local nade = createProjectile(localPlayer, 16, mx, my, mz, 0, nil, 0, 0, 0, nx, ny, nz, 321) --, nil, 0, 0, 0, nx, ny, nz) 321
					if nade then
						setElementVelocity(nade, nx, ny, nz)
						table.insert(bombs, {nx, ny, nz, nade})
						addEventHandler("onClientElementDestroy", nade, function() unlistBomb(source) end)
						setProjectileCounter(nade, 10000)
						canFire = false
					end
				end
			else
				outputChatBox("You need to reload before firing another round!", 255, 255, 0)
			end
		end
	end
end
bindKey("e", "down", fireNade)

function trackBombs()
	for i,v in ipairs(bombs) do
		local bomb = v[4]
		if isElement(bomb) then
			local vx, vy, vz = getElementVelocity(bomb)
			local ox, oy, oz = unpack(v)
			local diff = math.abs(getDistanceBetweenPoints3D(vx, vy, vz, ox, oy, oz))
			--[[ DEBUG
				--if diff > biggestDiff then biggestDiff = diff end
				--dxDrawText(tostring(biggestDiff), 500, 500, 700, 700)
			--]]
			if diff > 0.1 or isElementInWater(bomb) then
				setElementVelocity(bomb, 0, 0, 0)
				destroyElement(bomb)
			else
				bombs[i] = {vx, vy, vz, bomb}
			end
		else
			unlistBomb(v)
		end
	end
end
addEventHandler("onClientRender", root, trackBombs)

function unlistBomb(bomb)
	for i,v in ipairs(bombs) do
		if v == bomb then
			table.remove(bombs, i)
			return
		end
	end
end

function newAmmo()
	canFire = true
end
addEvent("onClientPlayerFinishReload", true)
addEventHandler("onClientPlayerFinishReload", localPlayer, newAmmo)
addEventHandler("onClientPlayerSpawn", localPlayer, newAmmo)

function noAmmo()
	canFire = false
end
addEvent("onClientPlayerStartReload", true)
addEventHandler("onClientPlayerStartReload", localPlayer, noAmmo)