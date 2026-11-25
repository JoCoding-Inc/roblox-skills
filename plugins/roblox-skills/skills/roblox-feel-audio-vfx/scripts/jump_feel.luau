--!strict
-- JumpFeel (client): coyote time, a faster fall and a lower jump on an early release, on top of the
-- default Humanoid jump. Attach once per character from a LocalScript in StarterCharacterScripts:
--   local stop = require(ReplicatedStorage.JumpFeel).attach(script.Parent)
--
-- Input: reads Humanoid.Jump, which the default PlayerModule's ControlModule writes every render step from
-- the keyboard, the gamepad and the touch jump button. A game that replaces the PlayerModule must write
-- Humanoid.Jump the same way.
--
-- Tested in Studio Play on 2026-11-25 (R15, scripted input and real keyboard presses, desktop client at about
-- 15 fps); the numbers are in roblox-feel-audio-vfx section 6. Touch and gamepad not tested; not checked in a
-- published game or on a real phone. The three values below are our starting values, not tuned in the hands.

local RunService = game:GetService("RunService")

local JumpFeel = {}
JumpFeel.coyoteSeconds = 0.1 -- a jump still starts this long after walking off an edge (0 = off)
JumpFeel.fallGravity = 1.6 -- gravity multiplier while falling (1 = engine default)
JumpFeel.releaseCut = 0.5 -- share of the upward speed kept when the jump input ends early (1 = off)

local bindCount = 0

function JumpFeel.attach(character: Model): () -> ()
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart

	local attachment = Instance.new("Attachment")
	attachment.Name = "JumpFeelAttachment"
	attachment.Parent = root
	local fall = Instance.new("VectorForce")
	fall.Name = "JumpFeelFall"
	fall.Attachment0 = attachment
	fall.RelativeTo = Enum.ActuatorRelativeTo.World
	fall.ApplyAtCenterOfMass = true
	fall.Enabled = false
	fall.Parent = root

	local walkedOffAt: number? = nil -- left the ground without a jump
	local heldAt = -math.huge -- last render step that saw the jump input held
	local armed = false -- this jump came from the input and may still be cut

	local stateConn = hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Jumping then
			walkedOffAt = nil
			armed = os.clock() - heldAt < 0.2 -- a scripted launch with no input is never cut
		elseif new == Enum.HumanoidStateType.Freefall then
			if old ~= Enum.HumanoidStateType.Jumping then
				walkedOffAt = os.clock()
			end
		else
			walkedOffAt = nil
			armed = false
		end
	end)

	-- Runs right after the ControlModule (RenderPriority.Input), so Humanoid.Jump is this frame's input.
	bindCount += 1
	local bindName = "JumpFeel" .. bindCount
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Input.Value + 1, function()
		local now = os.clock()
		local held = hum.Jump
		if held then
			heldAt = now
		end
		if held and walkedOffAt and hum:GetState() == Enum.HumanoidStateType.Freefall then
			if now - walkedOffAt <= JumpFeel.coyoteSeconds then
				walkedOffAt = nil
				hum:ChangeState(Enum.HumanoidStateType.Jumping) -- Humanoid.Jump alone does nothing in Freefall
				return
			end
		end
		if armed and not held then
			armed = false
			local v = root.AssemblyLinearVelocity
			if v.Y > 0 then
				root.AssemblyLinearVelocity = Vector3.new(v.X, v.Y * JumpFeel.releaseCut, v.Z)
			end
		end
	end)

	local stepConn = RunService.PreSimulation:Connect(function()
		local falling = root.AssemblyLinearVelocity.Y < 0 and hum:GetState() == Enum.HumanoidStateType.Freefall
		fall.Force = Vector3.new(0, -root.AssemblyMass * workspace.Gravity * (JumpFeel.fallGravity - 1), 0)
		fall.Enabled = falling and JumpFeel.fallGravity ~= 1
	end)

	return function()
		stateConn:Disconnect()
		stepConn:Disconnect()
		RunService:UnbindFromRenderStep(bindName)
		fall:Destroy()
		attachment:Destroy()
	end
end

return JumpFeel
