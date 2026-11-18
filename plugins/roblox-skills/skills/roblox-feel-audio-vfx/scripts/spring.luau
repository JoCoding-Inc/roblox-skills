--!nonstrict
-- Spring: a damped spring that draws the same curve at any frame rate. Closed form, exact while the
-- target holds still during one step, so a phone at 30 fps and a PC at 240 fps see the same motion.
-- Use it for camera follow, UI pops, recoil, lean and any value that should overshoot and settle.
-- x and target may be numbers or Vector3s.
--
-- Measured in Studio (2026-11-18, 2 Hz, start 0, target 1): x after 0.5 s was the same to 5 decimals at
-- 30, 60 and 240 steps per second; peak 1.163 at damping 0.5, 1.046 at 0.7, none at 1. A hand-written
-- Euler spring with the same settings peaked at 1.119 (30 fps) vs 1.158 (240 fps), and an 8 Hz one blew
-- up at 30 fps. Guide: roblox-feel-audio-vfx section 3b.
--
--   local Spring = require(path.to.spring)
--   local s = Spring.new(1, 4, 0.5) -- start value, frequency in Hz, damping ratio
--   s:impulse(6)                     -- a pop: the button's UIScale overshoots and settles at 1
--   RunService.PreRender:Connect(function(dt)
--   	uiScale.Scale = s:step(dt)
--   end)

local Spring = {}
Spring.__index = Spring

function Spring.new(x, hz: number, damping: number)
	return setmetatable({ x = x, v = x * 0, target = x, w = 2 * math.pi * hz, z = damping }, Spring)
end

-- Coefficients of the exact step (Ryan Juckett's damped springs). Returns pp, pv, vp, vv with
-- x' = (x - t) * pp + v * pv + t and v' = (x - t) * vp + v * vv.
function Spring.coefficients(w: number, z: number, dt: number): (number, number, number, number)
	if z > 1 + 1e-4 then
		local za, zb = -w * z, w * math.sqrt(z * z - 1)
		local z1, z2 = za - zb, za + zb
		local e1, e2 = math.exp(z1 * dt), math.exp(z2 * dt)
		local inv = 1 / (2 * zb)
		local e1o, e2o = e1 * inv, e2 * inv
		local z1e1o, z2e2o = z1 * e1o, z2 * e2o
		return e1o * z2 - z2e2o + e2, -e1o + e2o, (z1e1o - z2e2o + e2) * z2, -z1e1o + z2e2o
	elseif z < 1 - 1e-4 then
		local oz = w * z
		local a = w * math.sqrt(1 - z * z)
		local e = math.exp(-oz * dt)
		local c, s = math.cos(a * dt), math.sin(a * dt)
		local es, ec = e * s, e * c
		local k = e * oz * s / a
		return ec + k, es / a, -es * a - oz * k, ec - k
	end
	local e = math.exp(-w * dt)
	local te = dt * e
	local tef = te * w
	return tef + e, te, -w * tef, -tef + e
end

function Spring:step(dt: number)
	local pp, pv, vp, vv = Spring.coefficients(self.w, self.z, dt)
	local d = self.x - self.target
	self.x, self.v = d * pp + self.v * pv + self.target, d * vp + self.v * vv
	return self.x
end

-- Kick it: add velocity (recoil, a pop on a button press).
function Spring:impulse(dv)
	self.v += dv
end

return Spring
