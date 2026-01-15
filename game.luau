--/Commented out code can be used to place balls in scene!! Just click/scroll over the canvas

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AssetService = game:GetService("AssetService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

type metaball = {
	Position : Vector2,
	Radius : number,
	Velocity : Vector2,
}

local CANVAS_SIZE = Vector2.new(128, 256)
local CENTER = CANVAS_SIZE // 2
local MAGNITUDE = CANVAS_SIZE.Magnitude / 2

local BACKGROUND_COLOR = Color3.new(0.0784314, 0.0784314, 0.0784314)
local BALL_COLOR = Color3.new(0.788235, 0.360784, 1)
local OUTLINE_COLOR = Color3.new(0.321569, 0, 0.45098)
local THRESHOLD = 0.7
local OUTLINE_THRESHOLD = 0.8

local player = Players.LocalPlayer

local canvas = AssetService:CreateEditableImage({Size = CANVAS_SIZE})

local _canvasUI = script.CanvasUI
local _display = _canvasUI.Display

local metaballs : {metaball} = {}

_canvasUI.Parent = player.PlayerGui
_display.UIAspectRatioConstraint.AspectRatio = CANVAS_SIZE.X / CANVAS_SIZE.Y
_display.ImageContent = Content.fromObject(canvas)

for _, des in workspace:WaitForChild("Lava Lamp - zomkilla123"):WaitForChild("glass"):GetChildren() do
	if des:IsA("Decal") then
		print("decal")
		des.TextureContent = Content.fromObject(canvas)
	end
end

local function getMouseOnCanvas()
	local mousePos = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local displayPos = _display.AbsolutePosition
	local displaySize = _display.AbsoluteSize

	-- Convert mouse position to local coordinates (0 to 1 range)
	local localX = (mousePos.X - displayPos.X) / displaySize.X
	local localY = (mousePos.Y - displayPos.Y) / displaySize.Y

	-- Convert to canvas coordinates
	local canvasX = localX * CANVAS_SIZE.X
	local canvasY = localY * CANVAS_SIZE.Y

	if localX >= 0 and localX <= 1 and localY >= 0 and localY <= 1 then
		return Vector2.new(canvasX, canvasY)
	end

	return nil 
end

local function getColorOfIndex(pixelBuffer : buffer, pixelIndex : number)
	local r = buffer.readu8(pixelBuffer, pixelIndex)
	local g = buffer.readu8(pixelBuffer, pixelIndex + 1)
	local b = buffer.readu8(pixelBuffer, pixelIndex + 2)
	
	return Color3.fromRGB(r, g, b)
end

local function writeColorAtIndex(pixelBuffer : buffer, pixelIndex : number, color : Color3, alpha : number?)
	local r, g, b = color.R * 255, color.G * 255, color.B * 255
	
	buffer.writeu8(pixelBuffer, pixelIndex, r)
	buffer.writeu8(pixelBuffer, pixelIndex + 1, g)
	buffer.writeu8(pixelBuffer, pixelIndex + 2, b)
	buffer.writeu8(pixelBuffer, pixelIndex + 3, alpha or 255)
end

--local function place(inputName, inputState : Enum.UserInputState, inputObject : InputObject)
--	if inputState == Enum.UserInputState.Begin then
--		local newBall = table.clone(metaballs[1])
		
--		local angle = math.random(2 * math.pi)
--		newBall.Velocity = Vector2.new(math.cos(angle), math.sin(angle)) * math.random()
--		table.insert(metaballs, newBall)
--	end
--end
--ContextActionService:BindAction("Place", place, false, Enum.UserInputType.MouseButton1)

--local function resize(inputName, inputState : Enum.UserInputState, inputObject : InputObject)
--	if inputState == Enum.UserInputState.Change then
--		local scroll = inputObject.Position
--		if scroll.Z == 1 then
--			metaballs[1].Radius += 5
--		elseif scroll.Z == -1 then
--			metaballs[1].Radius -= 5
--		end
--	end
--end
--ContextActionService:BindAction("Resize", resize, false, Enum.UserInputType.MouseWheel)

local function newBall()
	local angle = math.random(0, 2*math.pi)
	
	local ball : metaball = {
		Position = Vector2.new(math.random(CANVAS_SIZE.X), math.random(CANVAS_SIZE.Y)),
		Radius = math.random(7, 15),
		Velocity = Vector2.new(math.cos(angle), math.sin(angle)) * math.random()
	}
	table.insert(metaballs, ball)
end

local function update()
	--local mousePos = getMouseOnCanvas()
	--if mousePos then
	--	metaballs[1].Position = mousePos
	--end
	
	local pixelBuffer = canvas:ReadPixelsBuffer(Vector2.zero, CANVAS_SIZE)
	
	for index, ball in metaballs do
		ball.Position += ball.Velocity
		
		local xVel = ball.Velocity.X
		local yVel = ball.Velocity.Y


		local x = ball.Position.X + xVel  
		local y = ball.Position.Y + yVel 

		if x < ball.Radius/2 or x > CANVAS_SIZE.X - ball.Radius/2 then
			xVel *= -1
		end
		if y < ball.Radius/2 or y > CANVAS_SIZE.Y - ball.Radius/2 then
			yVel *= -1
		end
		
		ball.Position = Vector2.new(x, y)
		ball.Velocity = Vector2.new(xVel, yVel)
	end
	
	for y = 0, CANVAS_SIZE.Y - 1 do
		for x = 0, CANVAS_SIZE.X - 1 do
			local pixelIndex = (y * CANVAS_SIZE.X + x) * 4
			local pixelPosition = Vector2.new(x, y)
			
			local brightness = 0
			for _, ball in metaballs do
				-- Use squared distance to avoid sqrt
				local distSq = (pixelPosition - ball.Position).Magnitude^2
				local influence = ball.Radius^2 / (distSq + ball.Radius^2)
				brightness += influence
			end
			brightness = math.clamp(brightness, 0, 1)
			
			local color : Color3
			local alpha = 255
			if brightness < THRESHOLD then
				color = BACKGROUND_COLOR
				alpha = 0
			elseif brightness > OUTLINE_THRESHOLD then
				color = BALL_COLOR
			else
				color = OUTLINE_COLOR
			end
			
			writeColorAtIndex(pixelBuffer, pixelIndex, color, alpha)
		end
	end
	
	canvas:WritePixelsBuffer(Vector2.zero, CANVAS_SIZE, pixelBuffer)
end

for i = 1, 10 do
	newBall()
end

RunService.RenderStepped:Connect(function(dt : number)	
	canvas:DrawRectangle(Vector2.zero, CANVAS_SIZE, BACKGROUND_COLOR, 1, Enum.ImageCombineType.Overwrite)
	
	update()
end)
