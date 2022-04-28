CoD.FlappyBirdContainer = InheritFrom(LUI.UIElement)

game:addlocalizedstring("MENU_FLAPPY_BIRD", "Flappy Bird")
game:addlocalizedstring("MENU_FLAPPY_BIRD_DESC", "Play Flappy Bird.")

LUI.addmenubutton("main_campaign", {
	index = 4,
	text = "@MENU_FLAPPY_BIRD",
	description = Engine.Localize("@MENU_FLAPPY_BIRD_DESC"),
	callback = function()
		LUI.FlowManager.RequestAddMenu(nil, "flappy_bird")
	end
})

local birdcolors = {"yellow", "red", "blue"}
local birdstates = {}

for k, v in pairs(birdcolors) do
	birdstates[v] = {
		RegisterMaterial("flappybird/" .. v .."bird-downflap"),
		RegisterMaterial("flappybird/" .. v .."bird-midflap"),
		RegisterMaterial("flappybird/" .. v .."bird-upflap"),
	}
end

local birdcolor = "yellow"

function CoD.FlappyBirdContainer.new()
	local root = LUI.UIElement.new({
		topAnchor = true,
		leftAnchor = true,
		top = 0,
		left = 0,
		width = 1280,
		height = 720
	})
	root:setClass(CoD.FlappyBirdContainer)
	root.id = "FlappyBirdContainer"
	root.soundSet = "HUD"
	root.anyChildUsesUpdateState = true

	local backgroundleft = LUI.UIImage.new()
	backgroundleft:setLeftRight(true, true, 0, -1280 / 2)
	backgroundleft:setTopBottom(true, true, 0, 0)
	backgroundleft:setImage(RegisterMaterial("flappybird/background-day"))
	root:addElement(backgroundleft)

	local backgroundright = LUI.UIImage.new()
	backgroundright:setLeftRight(true, true, 1280 / 2, 0)
	backgroundright:setTopBottom(true, true, 0, 0)
	backgroundright:setImage(RegisterMaterial("flappybird/background-day"))
	root:addElement(backgroundright)

	local foregroundleft = LUI.UIImage.new({
		topAnchor = true,
		leftAnchor = true,
		height = 200,
		top = 630,
	})
	foregroundleft:setLeftRight(true, true, 0, -1280 / 2)
	foregroundleft:setPriority(LUI.UIMouseCursor.priority)
	foregroundleft:setImage(RegisterMaterial("flappybird/base"))
	root:addElement(foregroundleft)

	local foregroundright = LUI.UIImage.new({
		topAnchor = true,
		leftAnchor = true,
		height = 200,
		top = 630,
	})
	foregroundright:setLeftRight(true, true, 1280 / 2, 0)
	foregroundright:setPriority(LUI.UIMouseCursor.priority)
	foregroundright:setImage(RegisterMaterial("flappybird/base"))
	root:addElement(foregroundright)

	local w, h = GetMaterialDimensions(RegisterMaterial("flappybird/message"))
	local messagescale = 1.5
	local message = LUI.UIImage.new({
		leftAnchor = true,
		topAnchor = true,
		left = 1280 / 2 - w * messagescale / 2,
		top = 720 / 2 - h * messagescale / 2,
		width = w * messagescale,
		height = h * messagescale
	})
	message:setImage(RegisterMaterial("flappybird/message"))
	root:addElement(message)
	
	local birdimage = LUI.UIImage.new()
	birdimage:setLeftRight(true, false, 80, 150)
	birdimage:setTopBottom(false, false, -25, 25)
	birdimage:setPriority(LUI.UIMouseCursor.priority)
	birdimage:setImage(birdstates[birdcolor][1])
	root:addElement(birdimage)

	local scorelabel = LUI.UIText.new({
		font = RegisterFont("fonts/flappy-bird.ttf", 50),
	})
	scorelabel:setLeftRight(true, false, 50, 100)
	scorelabel:setTopBottom(true, false, 30, 80)
	scorelabel:setPriority(LUI.UIMouseCursor.priority)
	scorelabel:setText("SCORE: 0")
	root:addElement(scorelabel)

	local highscorelabel = LUI.UIText.new({
		font = RegisterFont("fonts/flappy-bird.ttf", 50)
	})
	highscorelabel:setLeftRight(false, true, -100, -50)
	highscorelabel:setTopBottom(true, false, 30, 80)
	highscorelabel:setPriority(LUI.UIMouseCursor.priority)
	root:addElement(highscorelabel)

	local gameoverimage = LUI.UIImage.new()
	gameoverimage:setLeftRight(false, false, -200, 200)
	gameoverimage:setTopBottom(false, false, -50, 50)
	gameoverimage:setPriority(LUI.UIMouseCursor.priority)
	gameoverimage:setAlpha(0)
	gameoverimage:setImage(RegisterMaterial("flappybird/gameover"))
	root:addElement(gameoverimage)

	local frametime = 15
	local updatescale = (frametime / 30)
	local updatescaleinv = 1 / updatescale
	local pipewidth = 70
	local pipegap = 200
	local pipes = {}
	local pipeaddcount = 0
	local pipespeed = 6
	local pipeaddtiming = 60 * updatescaleinv * (4 / pipespeed)

	local active = false
	local hitpipe = false

	local score = 0

	local birdgravity = 0.6 * updatescale
	local birdjump = 20 * updatescale
	local birdflaptiming = 5
	local birdflapstate = 0
	local birdflapaddcount = 0
	local velocity = 0
	local birdy = -25
	local birdsize = 50

	local function gethighscore()
		local text = io.readfile("flappybird_hs")
		return text == "" and 0 or tonumber(text)
	end

	local function sethighscore(score)
		io.writefile("flappybird_hs", score .. "", false)
	end
	
	highscorelabel:setText("HIGHSCORE: " .. gethighscore())

	local function newpipe(height)
		local top = LUI.UIImage.new({
			rightAnchor = true,
			bottom = height,
			top = height - 640,
		})
		top:setZRotInC(180)
		top:setImage(RegisterMaterial("flappybird/pipe-green"))
		root:addElement(top)

		local bottom = LUI.UIImage.new({
			rightAnchor = true,
			height = 640,
			top = height + pipegap,
		})
		bottom:setImage(RegisterMaterial("flappybird/pipe-green"))
		root:addElement(bottom)
		table.insert(pipes, {
			bottom = bottom,
			top = top,
			topextend = topextend,
			x = -10,
			y = height
		})
	end

	local function deletepipe(pipe)
		pipe.bottom:close()
		pipe.top:close()
		pipe = nil
	end

	local function restartgame()
		gameoverimage:setAlpha(0)
		for k, v in pairs(pipes) do
			if v.deleted == nil then
				deletepipe(v)
			end
		end
		birdy = -25
		velocity = 0
		pipes = {}
		hitpipe = false
		score = 0
		pipeaddcount = 0
		birdflapaddcount = 0
		birdflapstate = 0
		newpipe(-100)
	end

	local function istouchingpipe(pipe)
		if pipe.x < -1130 and pipe.x + pipewidth > -1210 then
			if pipe.y > birdy or pipe.y + pipegap < birdy + birdsize then
				return true
			end
		end
		
		return false
	end

	local function update()
		if (not hitpipe) then
			birdflapaddcount = birdflapaddcount + 1
			if (birdflapaddcount == birdflaptiming) then
				birdflapaddcount = 1
				birdflapstate = birdflapstate + 1
				if (birdflapstate > #birdstates[birdcolor]) then
					birdflapstate = 1
				end
	
				birdimage:setImage(birdstates[birdcolor][birdflapstate])
			end
		end

		if (not active) then
			return
		end
		
		-- Stuff for moving the pipes
		if hitpipe == false then
			for k, v in ipairs(pipes) do
				if v.deleted == nil then
					v.x = v.x - updatescale * pipespeed
					v.bottom:setLeftRight(false, true, v.x, v.x + pipewidth)
					v.top:setLeftRight(false, true, v.x, v.x + pipewidth)
					if istouchingpipe(v) then
						Engine.PlaySound("uin_flappybird_hit")
						hitpipe = true
						break
					end
					if v.x < -1280 - pipewidth then
						v.deleted = true
						deletepipe(v)
						Engine.PlaySound("uin_flappybird_point")
						score = score + 1
					end
				end
			end
		end

		-- Checking for the next pipe
		pipeaddcount = pipeaddcount + 1
		if (pipeaddcount == pipeaddtiming) then
			pipeaddcount = 0
			newpipe(math.random(-300, 80))
		end

		-- Stuff for moving the bird
		velocity = velocity + birdgravity
		birdy = birdy + velocity
		if birdy < -360 then
			birdy = -360
			velocity = 0
		end
		
		if birdy > 210 then
			-- Hit ground, starting again
			if hitpipe == false then
				Engine.PlaySound("uin_flappybird_hit")
			end
			hitpipe = true
			if score > gethighscore() then
				sethighscore(score)
				highscorelabel:setText("HIGHSCORE: " .. score)
			end
			gameoverimage:setAlpha(1)
			active = false
			return
		end

		local function clamp(x, min, max)
			if x < min then
				return min
			end
			if x > max then
				return max
			end
			return x
		end

		-- Give the bird the right rotation and height
		birdimage:setZRotInC(clamp(velocity * -4, -85, 85))
		birdimage:setTopBottom(false, false, birdy, birdy + birdsize)

		scorelabel:setText("SCORE: " .. score)
	end

	-- Add the first pipe
	newpipe(-100)
	
	-- Start the frames
	root:registerEventHandler("update", update)
	root:addElement(LUI.UITimer.new(frametime, "update"))

	local started = false

	local function fly()
		if (not started) then
			started = true
			root:removeElement(message)
		end

		if (active and not hitpipe) then
			Engine.PlaySound("uin_flappybird_wing")
			velocity = velocity - birdjump
		elseif (not active) then
			restartgame()
			active = true
			update()
		end
		return true
	end

	local keys = {}
	local keybinds = {}
	keybinds["SPACE"] = fly
	keybinds["MOUSE1"] = fly

	local birdcolorindex = 1
	keybinds["MOUSE2"] = function()
		if (started) then
			return
		end

		birdcolorindex = birdcolorindex + 1
		if (birdcolorindex > 3) then
			birdcolorindex = 1
		end

		birdcolor = birdcolors[birdcolorindex]
	end
	keybinds["ESCAPE"] = function()
		LUI.FlowManager.RequestLeaveMenu(root)
	end

	root:registerEventHandler("keydown", function(element, event)
		if (keybinds[event.key] and not keys[event.key]) then
			keys[event.key] = true
			keybinds[event.key]()
		end
	end)
	
	root:registerEventHandler("keyup", function(element, event)
		keys[event.key] = false
	end)

	return root
end

LUI.MenuBuilder.registerType("flappy_bird", CoD.FlappyBirdContainer.new)
