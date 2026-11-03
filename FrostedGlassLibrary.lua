--[[
    Frosted Glass UI Library v3
    Vikings Studio Project Delta
    Five-panel translucent design
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local THEMES = {
    { bg = Color3.fromRGB(45, 42, 38),  border = Color3.fromRGB(75, 70, 65),  accent = Color3.fromRGB(165, 155, 140) },
    { bg = Color3.fromRGB(40, 43, 38),  border = Color3.fromRGB(68, 72, 65),  accent = Color3.fromRGB(150, 160, 140) },
    { bg = Color3.fromRGB(38, 42, 45),  border = Color3.fromRGB(65, 70, 75),  accent = Color3.fromRGB(140, 155, 165) },
    { bg = Color3.fromRGB(42, 40, 45),  border = Color3.fromRGB(70, 68, 75),  accent = Color3.fromRGB(155, 148, 168) },
    { bg = Color3.fromRGB(40, 40, 40),  border = Color3.fromRGB(68, 68, 68),  accent = Color3.fromRGB(155, 155, 155) },
}

local C = {
    text       = Color3.fromRGB(225, 225, 235),
    textDim    = Color3.fromRGB(155, 155, 172),
    textMuted  = Color3.fromRGB(95, 95, 112),
    headerText = Color3.fromRGB(240, 240, 248),
    checkOff   = Color3.fromRGB(38, 38, 50),
    inputBg    = Color3.fromRGB(26, 26, 34),
    inputBorder= Color3.fromRGB(55, 55, 70),
    white      = Color3.fromRGB(255, 255, 255),
    danger     = Color3.fromRGB(255, 80, 80),
    popupBg    = Color3.fromRGB(30, 30, 40),
    popupBorder= Color3.fromRGB(60, 60, 75),
}

local FONT = {
    regular  = Enum.Font.Gotham,
    semibold = Enum.Font.GothamSemibold,
    bold     = Enum.Font.GothamBold,
    mono     = Enum.Font.RobotoMono,
}

local tweenFast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenMed  = TweenInfo.new(0.2,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenOpen = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tw(obj, props, info)
    TweenService:Create(obj, info or tweenFast, props):Play()
end

local function cr(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(p, r) return cr("UICorner", {CornerRadius = UDim.new(0, r or 6), Parent = p}) end
local function stroke(p, col, t, a) return cr("UIStroke", {Color = col or C.inputBorder, Thickness = t or 1, Transparency = a or 0.5, Parent = p}) end
local function pad(p, t, b, l, r) return cr("UIPadding", {PaddingTop=UDim.new(0,t or 6), PaddingBottom=UDim.new(0,b or 6), PaddingLeft=UDim.new(0,l or 8), PaddingRight=UDim.new(0,r or 8), Parent=p}) end
local function layoutList(p, gap) return cr("UIListLayout", {Padding=UDim.new(0,gap or 3), FillDirection=Enum.FillDirection.Vertical, SortOrder=Enum.SortOrder.LayoutOrder, Parent=p}) end

local PANEL_W   = 215
local PANEL_GAP = 6
local MARGIN_Y  = 25

local Library = {}

function Library.new(title, cfgFolder)
    local lib = {}
    lib._title    = title or "Menu"
    lib._cfgFolder= cfgFolder or "Cfg"
    lib._tabs     = {}
    lib._panels   = {}
    lib._elements = {}
    lib._elemOrd  = 0
    lib._visible  = true
    lib._toggleKey= Enum.KeyCode.RightShift

    local screenGui = cr("ScreenGui", {
        Name = "FGlass_" .. lib._cfgFolder,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui,
    })
    lib._screenGui = screenGui

    local popupHolder = cr("Frame", {
        Name = "Popups",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100,
        Parent = screenGui,
    })

    local function repositionPanels()
        local n = #lib._panels
        if n == 0 then return end
        local totalW = n * PANEL_W + (n - 1) * PANEL_GAP
        for i, panel in ipairs(lib._panels) do
            local xOff = math.floor(-totalW / 2 + (i - 1) * (PANEL_W + PANEL_GAP))
            panel.Position = UDim2.new(0.5, xOff, 0, MARGIN_Y)
        end
    end

    local function showAll()
        lib._visible = true
        for i, panel in ipairs(lib._panels) do
            panel.Visible = true
            local tx = panel.Position.X
            panel.Position = UDim2.new(tx.Scale, tx.Offset, 0, MARGIN_Y - 18)
            task.delay((i - 1) * 0.045, function()
                tw(panel, {Position = UDim2.new(tx.Scale, tx.Offset, 0, MARGIN_Y)}, tweenOpen)
            end)
        end
    end

    local function hideAll()
        lib._visible = false
        for i, panel in ipairs(lib._panels) do
            local idx = #lib._panels - i
            task.delay(idx * 0.04, function()
                local tx = panel.Position.X
                tw(panel, {Position = UDim2.new(tx.Scale, tx.Offset, 0, MARGIN_Y - 18)}, tweenOpen)
                task.delay(0.32, function()
                    if not lib._visible then panel.Visible = false end
                end)
            end)
        end
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == lib._toggleKey then
            if lib._visible then hideAll() else showAll() end
        end
    end)

    function lib.new_tab(iconId)
        local tabIdx = #lib._tabs + 1
        local theme  = THEMES[((tabIdx - 1) % #THEMES) + 1]
        local tab = {
            _sections = {},
            _theme = theme,
            _titleSet = false,
            _layoutOrder = 0,
        }

        local panel = cr("Frame", {
            Name = "Panel_" .. tabIdx,
            BackgroundColor3 = theme.bg,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Size = UDim2.new(0, PANEL_W, 1, -(MARGIN_Y * 2)),
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = screenGui,
        })
        corner(panel, 8)
        stroke(panel, theme.border, 1, 0.45)
        tab._panel = panel

        cr("ImageLabel", {
            Name = "Shadow",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, -12, 0, -12),
            Size = UDim2.new(1, 24, 1, 24),
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.fromRGB(5, 5, 8),
            ImageTransparency = 0.55,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = 0,
            Parent = panel,
        })

        local hdr = cr("Frame", {
            Name = "Header",
            BackgroundColor3 = theme.bg,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            ZIndex = 5,
            Parent = panel,
        })
        corner(hdr, 8)
        cr("Frame", {
            BackgroundColor3 = theme.bg,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 10),
            ZIndex = 5,
            Parent = panel,
        })
        cr("Frame", {
            BackgroundColor3 = theme.border,
            BackgroundTransparency = 0.45,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 30),
            Size = UDim2.new(1, -16, 0, 1),
            ZIndex = 6,
            Parent = panel,
        })

        local iconOffset = 10
        if iconId and iconId ~= "" then
            cr("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                Image = iconId,
                ImageColor3 = theme.accent,
                ZIndex = 6,
                Parent = hdr,
            })
            iconOffset = 26
        end

        local titleLabel = cr("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, iconOffset, 0, 0),
            Size = UDim2.new(1, -(iconOffset + 22), 1, 0),
            Font = FONT.semibold,
            Text = "",
            TextColor3 = C.headerText,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 6,
            Parent = hdr,
        })
        tab._titleLabel = titleLabel

        local minBtn = cr("TextButton", {
            Name = "Min",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 0.5, -7),
            Size = UDim2.new(0, 14, 0, 14),
            Font = FONT.regular,
            Text = "\226\128\148",
            TextColor3 = C.textMuted,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 7,
            Parent = hdr,
        })
        minBtn.MouseEnter:Connect(function() tw(minBtn, {TextColor3 = C.text}) end)
        minBtn.MouseLeave:Connect(function() tw(minBtn, {TextColor3 = C.textMuted}) end)

        local content = cr("ScrollingFrame", {
            Name = "Content",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 33),
            Size = UDim2.new(1, 0, 1, -33),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.accent,
            ScrollBarImageTransparency = 0.6,
            ZIndex = 3,
            Parent = panel,
        })
        pad(content, 5, 10, 10, 10)
        local contentLayout = layoutList(content, 2)
        tab._content = content

        local function updateCanvas()
            task.defer(function()
                content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 16)
            end)
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

        local minimized = false
        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            if minimized then
                tw(content, {Size = UDim2.new(1, 0, 0, 0)}, tweenMed)
                tw(panel, {Size = UDim2.new(0, PANEL_W, 0, 32)}, tweenMed)
                minBtn.Text = "+"
            else
                tw(panel, {Size = UDim2.new(0, PANEL_W, 1, -(MARGIN_Y * 2))}, tweenMed)
                task.delay(0.12, function()
                    tw(content, {Size = UDim2.new(1, 0, 1, -33)}, tweenMed)
                end)
                minBtn.Text = "\226\128\148"
            end
        end)

        function tab.new_section(sectionName)
            local section = { _name = sectionName }

            if not tab._titleSet then
                titleLabel.Text = sectionName
                tab._titleSet = true
            end

            if #tab._sections > 0 then
                tab._layoutOrder = tab._layoutOrder + 1
                cr("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 5),
                    LayoutOrder = tab._layoutOrder,
                    Parent = content,
                })
            end

            tab._layoutOrder = tab._layoutOrder + 1
            local secHdr = cr("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                LayoutOrder = tab._layoutOrder,
                ZIndex = 4,
                Parent = content,
            })
            cr("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = FONT.semibold,
                Text = sectionName:upper(),
                TextColor3 = theme.accent,
                TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = secHdr,
            })
            cr("Frame", {
                BackgroundColor3 = theme.border,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                ZIndex = 4,
                Parent = secHdr,
            })

            function section.new_sector(sectorName, _side)
                local sector = {}

                if sectorName ~= sectionName then
                    tab._layoutOrder = tab._layoutOrder + 1
                    cr("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 13),
                        Font = FONT.regular,
                        Text = sectorName,
                        TextColor3 = C.textMuted,
                        TextSize = 9,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = tab._layoutOrder,
                        ZIndex = 3,
                        Parent = content,
                    })
                end

                function sector.element(elemType, elemName, default, callback)
                    tab._layoutOrder = tab._layoutOrder + 1
                    lib._elemOrd = lib._elemOrd + 1
                    local elemId = lib._cfgFolder .. "_" .. elemName .. "_" .. lib._elemOrd
                    local elemData = {
                        id = elemId,
                        type = elemType,
                        name = elemName,
                        value = nil,
                        callback = callback,
                        _keybind = nil,
                        _colorPicker = nil,
                    }
                    local elemObj = {_hasKb = false, _hasCol = false}
                    local lo = tab._layoutOrder

                    if elemType == "Toggle" then
                        local toggled = false
                        elemData.value = toggled

                        local row = cr("Frame", {
                            Name = "Tog_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 20),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })

                        local hoverBg = cr("Frame", {
                            BackgroundColor3 = C.white,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, -4, 0, -1),
                            Size = UDim2.new(1, 8, 1, 2),
                            ZIndex = 2,
                            Parent = row,
                        })
                        corner(hoverBg, 4)

                        local checkBox = cr("Frame", {
                            BackgroundColor3 = C.checkOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0.5, -6),
                            Size = UDim2.new(0, 12, 0, 12),
                            ZIndex = 4,
                            Parent = row,
                        })
                        corner(checkBox, 3)
                        stroke(checkBox, theme.border, 1, 0.55)

                        local checkMark = cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Font = FONT.bold,
                            Text = "\226\156\147",
                            TextColor3 = C.white,
                            TextSize = 9,
                            TextTransparency = 1,
                            ZIndex = 5,
                            Parent = checkBox,
                        })

                        local label = cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 18, 0, 0),
                            Size = UDim2.new(1, -18, 1, 0),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = C.textDim,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 3,
                            Parent = row,
                        })
                        elemObj._label = label
                        elemObj._row = row

                        local function setToggle(val)
                            toggled = val
                            elemData.value = val
                            tw(checkBox, {BackgroundColor3 = val and theme.accent or C.checkOff}, tweenFast)
                            tw(checkMark, {TextTransparency = val and 0 or 1}, tweenFast)
                            tw(label, {TextColor3 = val and C.text or C.textDim}, tweenFast)
                        end
                        elemData._setToggle = setToggle

                        local clickBtn = cr("TextButton", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            ZIndex = 6,
                            Parent = row,
                        })
                        clickBtn.MouseEnter:Connect(function() tw(hoverBg, {BackgroundTransparency = 0.93}, tweenFast) end)
                        clickBtn.MouseLeave:Connect(function() tw(hoverBg, {BackgroundTransparency = 1}, tweenFast) end)
                        clickBtn.MouseButton1Click:Connect(function()
                            setToggle(not toggled)
                            if callback then callback({Toggle = toggled}) end
                        end)

                        local function repositionExtras()
                            local rOff = 0
                            if elemObj._hasCol and elemObj._colInd then
                                elemObj._colInd.Position = UDim2.new(1, -(rOff + 10), 0.5, -5)
                                if elemObj._colBtn then
                                    elemObj._colBtn.Position = UDim2.new(1, -(rOff + 14), 0.5, -9)
                                end
                                rOff = rOff + 16
                            end
                            if elemObj._hasKb and elemObj._kbBtn then
                                elemObj._kbBtn.Position = UDim2.new(1, -(rOff + 38), 0.5, -7)
                                rOff = rOff + 42
                            end
                            label.Size = UDim2.new(1, -(18 + rOff), 1, 0)
                        end
                        elemObj._reposition = repositionExtras

                    elseif elemType == "Slider" then
                        local opts = default and default.default or {}
                        local minV = opts.min or 0
                        local maxV = opts.max or 100
                        local curV = opts.default or minV
                        elemData.value = curV

                        local container = cr("Frame", {
                            Name = "Sld_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 32),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })
                        elemObj._row = container

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, -32, 0, 14),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local valLbl = cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -32, 0, 0),
                            Size = UDim2.new(0, 32, 0, 14),
                            Font = FONT.mono,
                            Text = tostring(curV),
                            TextColor3 = theme.accent,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Right,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local track = cr("Frame", {
                            BackgroundColor3 = C.checkOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 18),
                            Size = UDim2.new(1, 0, 0, 5),
                            ZIndex = 3,
                            Parent = container,
                        })
                        corner(track, 3)

                        local frac = (curV - minV) / math.max(maxV - minV, 1)
                        local fill = cr("Frame", {
                            BackgroundColor3 = theme.accent,
                            BackgroundTransparency = 0.2,
                            BorderSizePixel = 0,
                            Size = UDim2.new(frac, 0, 1, 0),
                            ZIndex = 4,
                            Parent = track,
                        })
                        corner(fill, 3)

                        local knob = cr("Frame", {
                            BackgroundColor3 = C.white,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(frac, 0, 0.5, 0),
                            Size = UDim2.new(0, 10, 0, 10),
                            ZIndex = 5,
                            Parent = track,
                        })
                        corner(knob, 5)
                        stroke(knob, theme.accent, 1, 0.4)

                        local sldBtn = cr("TextButton", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 0, 0, 12),
                            Size = UDim2.new(1, 0, 0, 18),
                            Text = "",
                            ZIndex = 6,
                            Parent = container,
                        })

                        local dragging = false
                        local function updSlider(input)
                            local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                            local v = math.floor(minV + rel * (maxV - minV) + 0.5)
                            curV = v
                            elemData.value = v
                            valLbl.Text = tostring(v)
                            local f = (v - minV) / math.max(maxV - minV, 1)
                            fill.Size = UDim2.new(f, 0, 1, 0)
                            knob.Position = UDim2.new(f, 0, 0.5, 0)
                            if callback then callback({Slider = v}) end
                        end

                        elemData._updateSlider = function(v)
                            curV = v; elemData.value = v; valLbl.Text = tostring(v)
                            local f = (v - minV) / math.max(maxV - minV, 1)
                            fill.Size = UDim2.new(f, 0, 1, 0)
                            knob.Position = UDim2.new(f, 0, 0.5, 0)
                        end

                        sldBtn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true; updSlider(input)
                            end
                        end)
                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updSlider(input) end
                        end)
                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                        end)

                    elseif elemType == "Dropdown" then
                        local opts = default and default.options or {}
                        local cleanOpts = {}
                        for _, v in ipairs(opts) do if v ~= nil then table.insert(cleanOpts, v) end end
                        local selected = cleanOpts[1]
                        elemData.value = selected
                        local dropOpen = false

                        local container = cr("Frame", {
                            Name = "Drop_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 36),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })
                        elemObj._row = container

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 13),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local dropBtn = cr("TextButton", {
                            BackgroundColor3 = C.inputBg,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 15),
                            Size = UDim2.new(1, 0, 0, 20),
                            Font = FONT.regular,
                            Text = "  " .. (selected or "..."),
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        corner(dropBtn, 4)
                        stroke(dropBtn, C.inputBorder, 1, 0.6)

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -16, 0, 0),
                            Size = UDim2.new(0, 12, 1, 0),
                            Font = FONT.regular,
                            Text = "\226\150\190",
                            TextColor3 = C.textDim,
                            TextSize = 10,
                            ZIndex = 5,
                            Parent = dropBtn,
                        })

                        local dropList = cr("ScrollingFrame", {
                            BackgroundColor3 = C.popupBg,
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 180, 0, 0),
                            CanvasSize = UDim2.new(0, 0, 0, 0),
                            ScrollBarThickness = 2,
                            ScrollBarImageColor3 = theme.accent,
                            Visible = false,
                            ZIndex = 101,
                            Parent = popupHolder,
                        })
                        corner(dropList, 4)
                        stroke(dropList, C.popupBorder, 1, 0.35)
                        pad(dropList, 2, 2, 2, 2)
                        layoutList(dropList, 1)

                        for _, opt in ipairs(cleanOpts) do
                            local ob = cr("TextButton", {
                                BackgroundColor3 = C.white,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 19),
                                Font = FONT.regular,
                                Text = "  " .. opt,
                                TextColor3 = C.text,
                                TextSize = 10,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                AutoButtonColor = false,
                                ZIndex = 102,
                                Parent = dropList,
                            })
                            corner(ob, 3)
                            ob.MouseEnter:Connect(function() tw(ob, {BackgroundTransparency = 0.88}) end)
                            ob.MouseLeave:Connect(function() tw(ob, {BackgroundTransparency = 1}) end)
                            ob.MouseButton1Click:Connect(function()
                                selected = opt; elemData.value = opt
                                dropBtn.Text = "  " .. opt
                                dropOpen = false; dropList.Visible = false
                                if callback then callback({Dropdown = opt}) end
                            end)
                        end

                        local totalH = #cleanOpts * 20 + 6
                        dropList.CanvasSize = UDim2.new(0, 0, 0, totalH)

                        elemData._setDropdown = function(v)
                            selected = v; elemData.value = v; dropBtn.Text = "  " .. tostring(v)
                        end

                        dropBtn.MouseButton1Click:Connect(function()
                            dropOpen = not dropOpen
                            if dropOpen then
                                local ap = dropBtn.AbsolutePosition
                                local as = dropBtn.AbsoluteSize
                                dropList.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
                                dropList.Size = UDim2.new(0, as.X, 0, math.min(totalH, 160))
                                dropList.Visible = true
                            else
                                dropList.Visible = false
                            end
                        end)

                        UserInputService.InputBegan:Connect(function(input)
                            if dropOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local p = input.Position
                                local dp, ds = dropList.AbsolutePosition, dropList.AbsoluteSize
                                local bp, bs = dropBtn.AbsolutePosition, dropBtn.AbsoluteSize
                                local inL = p.X >= dp.X and p.X <= dp.X+ds.X and p.Y >= dp.Y and p.Y <= dp.Y+ds.Y
                                local inB = p.X >= bp.X and p.X <= bp.X+bs.X and p.Y >= bp.Y and p.Y <= bp.Y+bs.Y
                                if not inL and not inB then dropOpen = false; dropList.Visible = false end
                            end
                        end)

                    elseif elemType == "Button" then
                        local container = cr("Frame", {
                            Name = "Btn_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 22),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })
                        elemObj._row = container

                        local btn = cr("TextButton", {
                            BackgroundColor3 = theme.accent,
                            BackgroundTransparency = 0.65,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 20),
                            Font = FONT.semibold,
                            Text = elemName,
                            TextColor3 = C.text,
                            TextSize = 10,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        corner(btn, 4)
                        stroke(btn, theme.border, 1, 0.55)

                        btn.MouseEnter:Connect(function() tw(btn, {BackgroundTransparency = 0.45}) end)
                        btn.MouseLeave:Connect(function() tw(btn, {BackgroundTransparency = 0.65}) end)
                        btn.MouseButton1Click:Connect(function()
                            tw(btn, {BackgroundTransparency = 0.2})
                            task.delay(0.1, function() tw(btn, {BackgroundTransparency = 0.65}) end)
                            if callback then callback(true) end
                        end)

                    elseif elemType == "TextBox" then
                        local container = cr("Frame", {
                            Name = "Txt_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 34),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })
                        elemObj._row = container

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 13),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local tbox = cr("TextBox", {
                            BackgroundColor3 = C.inputBg,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 15),
                            Size = UDim2.new(1, 0, 0, 18),
                            Font = FONT.regular,
                            PlaceholderText = elemName,
                            PlaceholderColor3 = C.textMuted,
                            Text = "",
                            TextColor3 = C.text,
                            TextSize = 10,
                            ClearTextOnFocus = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        corner(tbox, 4)
                        stroke(tbox, C.inputBorder, 1, 0.6)
                        pad(tbox, 0, 0, 5, 5)
                        elemData.value = ""

                        tbox.FocusLost:Connect(function()
                            elemData.value = tbox.Text
                            if callback then callback({Text = tbox.Text}) end
                        end)
                        elemData._setText = function(v) tbox.Text = v; elemData.value = v end

                    elseif elemType == "Combo" then
                        local opts = default and default.options or {}
                        local cleanOpts = {}
                        for _, v in ipairs(opts) do if v ~= nil then table.insert(cleanOpts, v) end end
                        local selectedSet = {}
                        elemData.value = selectedSet
                        local comboOpen = false

                        local container = cr("Frame", {
                            Name = "Cmb_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 36),
                            LayoutOrder = lo,
                            ZIndex = 3,
                            Parent = content,
                        })
                        elemObj._row = container

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 13),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local comboBtn = cr("TextButton", {
                            BackgroundColor3 = C.inputBg,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 15),
                            Size = UDim2.new(1, 0, 0, 20),
                            Font = FONT.regular,
                            Text = "  ...",
                            TextColor3 = C.text,
                            TextSize = 10,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        corner(comboBtn, 4)
                        stroke(comboBtn, C.inputBorder, 1, 0.6)

                        cr("TextLabel", {
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -16, 0, 0),
                            Size = UDim2.new(0, 12, 1, 0),
                            Font = FONT.regular,
                            Text = "\226\150\190",
                            TextColor3 = C.textDim,
                            TextSize = 10,
                            ZIndex = 5,
                            Parent = comboBtn,
                        })

                        local comboList = cr("ScrollingFrame", {
                            BackgroundColor3 = C.popupBg,
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 180, 0, 0),
                            CanvasSize = UDim2.new(0, 0, 0, 0),
                            ScrollBarThickness = 2,
                            ScrollBarImageColor3 = theme.accent,
                            Visible = false,
                            ZIndex = 101,
                            Parent = popupHolder,
                        })
                        corner(comboList, 4)
                        stroke(comboList, C.popupBorder, 1, 0.35)
                        pad(comboList, 2, 2, 2, 2)
                        layoutList(comboList, 1)

                        local checks = {}
                        local function updateComboLabel()
                            local sel = {}
                            for _, o in ipairs(cleanOpts) do if selectedSet[o] then table.insert(sel, o) end end
                            if #sel == 0 then comboBtn.Text = "  ..."
                            elseif #sel <= 2 then comboBtn.Text = "  " .. table.concat(sel, ", ")
                            else comboBtn.Text = "  " .. #sel .. " sel." end
                        end
                        local function getComboResult()
                            local r = {}
                            for _, o in ipairs(cleanOpts) do if selectedSet[o] then table.insert(r, o) end end
                            return r
                        end

                        for _, opt in ipairs(cleanOpts) do
                            local oRow = cr("TextButton", {
                                BackgroundColor3 = C.white,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 19),
                                Text = "",
                                AutoButtonColor = false,
                                ZIndex = 102,
                                Parent = comboList,
                            })
                            corner(oRow, 3)

                            local chk = cr("TextLabel", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 3, 0, 0),
                                Size = UDim2.new(0, 14, 1, 0),
                                Font = FONT.regular,
                                Text = "\226\152\144",
                                TextColor3 = C.textDim,
                                TextSize = 12,
                                ZIndex = 103,
                                Parent = oRow,
                            })
                            checks[opt] = chk

                            cr("TextLabel", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 18, 0, 0),
                                Size = UDim2.new(1, -22, 1, 0),
                                Font = FONT.regular,
                                Text = opt,
                                TextColor3 = C.text,
                                TextSize = 10,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 103,
                                Parent = oRow,
                            })

                            oRow.MouseEnter:Connect(function() tw(oRow, {BackgroundTransparency = 0.88}) end)
                            oRow.MouseLeave:Connect(function() tw(oRow, {BackgroundTransparency = 1}) end)
                            oRow.MouseButton1Click:Connect(function()
                                selectedSet[opt] = not selectedSet[opt]
                                chk.Text = selectedSet[opt] and "\226\152\145" or "\226\152\144"
                                chk.TextColor3 = selectedSet[opt] and theme.accent or C.textDim
                                updateComboLabel()
                                if callback then callback({Combo = getComboResult()}) end
                            end)
                        end

                        local totalH = #cleanOpts * 20 + 6
                        comboList.CanvasSize = UDim2.new(0, 0, 0, totalH)

                        elemData._setCombo = function(vals)
                            selectedSet = {}
                            for _, v in ipairs(vals) do selectedSet[v] = true end
                            for o, ch in pairs(checks) do
                                ch.Text = selectedSet[o] and "\226\152\145" or "\226\152\144"
                                ch.TextColor3 = selectedSet[o] and theme.accent or C.textDim
                            end
                            updateComboLabel()
                        end

                        comboBtn.MouseButton1Click:Connect(function()
                            comboOpen = not comboOpen
                            if comboOpen then
                                local ap = comboBtn.AbsolutePosition
                                local as = comboBtn.AbsoluteSize
                                comboList.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
                                comboList.Size = UDim2.new(0, as.X, 0, math.min(totalH, 170))
                                comboList.Visible = true
                            else
                                comboList.Visible = false
                            end
                        end)

                        UserInputService.InputBegan:Connect(function(input)
                            if comboOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                                local p = input.Position
                                local dp, ds = comboList.AbsolutePosition, comboList.AbsoluteSize
                                local bp, bs = comboBtn.AbsolutePosition, comboBtn.AbsoluteSize
                                local inL = p.X>=dp.X and p.X<=dp.X+ds.X and p.Y>=dp.Y and p.Y<=dp.Y+ds.Y
                                local inB = p.X>=bp.X and p.X<=bp.X+bs.X and p.Y>=bp.Y and p.Y<=bp.Y+bs.Y
                                if not inL and not inB then comboOpen = false; comboList.Visible = false end
                            end
                        end)
                    end

                    function elemObj:add_keybind(mode, keybindCallback)
                        local currentKey = nil
                        local active = false
                        local listening = false
                        local row = elemObj._row
                        if not row then return elemObj end

                        local kbBtn = cr("TextButton", {
                            BackgroundColor3 = C.inputBg,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, 0, 0.5, 0),
                            Size = UDim2.new(0, 38, 0, 14),
                            Font = FONT.mono,
                            Text = "[...]",
                            TextColor3 = C.textMuted,
                            TextSize = 8,
                            AutoButtonColor = false,
                            ZIndex = 8,
                            Parent = row,
                        })
                        corner(kbBtn, 3)
                        elemObj._kbBtn = kbBtn
                        elemObj._hasKb = true
                        if elemObj._reposition then elemObj._reposition() end

                        kbBtn.MouseButton1Click:Connect(function()
                            listening = true; kbBtn.Text = "[?]"
                            tw(kbBtn, {BackgroundColor3 = theme.accent})
                        end)

                        UserInputService.InputBegan:Connect(function(input, gpe)
                            if listening then
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    if input.KeyCode == Enum.KeyCode.Escape then
                                        currentKey = nil; kbBtn.Text = "[...]"
                                        elemData._keybind = {mode = mode, key = nil}
                                    else
                                        currentKey = input.KeyCode
                                        kbBtn.Text = "[" .. input.KeyCode.Name .. "]"
                                        elemData._keybind = {mode = mode, key = currentKey.Name}
                                    end
                                    listening = false
                                    tw(kbBtn, {BackgroundColor3 = C.inputBg})
                                    return
                                end
                            end
                            if not gpe and currentKey and input.KeyCode == currentKey then
                                if mode == "Hold" then
                                    active = true
                                    if keybindCallback then keybindCallback({Active=true, Key=currentKey.Name}) end
                                elseif mode == "Toggle" then
                                    active = not active
                                    if keybindCallback then keybindCallback({Active=active, Key=currentKey.Name}) end
                                end
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if currentKey and input.KeyCode == currentKey and mode == "Hold" then
                                active = false
                                if keybindCallback then keybindCallback({Active=false, Key=currentKey.Name}) end
                            end
                        end)

                        elemData._keybind = {mode = mode, key = nil}
                        elemData._setKeybind = function(keyName)
                            if not keyName then return end
                            local ok, key = pcall(function() return Enum.KeyCode[keyName] end)
                            if ok and key then
                                currentKey = key
                                kbBtn.Text = "[" .. keyName .. "]"
                                elemData._keybind = {mode = mode, key = keyName}
                            end
                        end
                        return elemObj
                    end

                    function elemObj:add_color(colorDefault, _, colorCallback)
                        local currentColor = colorDefault and colorDefault.Color or Color3.fromRGB(255,255,255)
                        local pickerOpen = false
                        local row = elemObj._row
                        if not row then return elemObj end

                        local colInd = cr("Frame", {
                            BackgroundColor3 = currentColor,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, 0, 0.5, 0),
                            Size = UDim2.new(0, 10, 0, 10),
                            ZIndex = 8,
                            Parent = row,
                        })
                        corner(colInd, 2)
                        stroke(colInd, C.inputBorder, 1, 0.4)
                        elemObj._colInd = colInd

                        local colBtn = cr("TextButton", {
                            BackgroundTransparency = 1,
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, 4, 0.5, 0),
                            Size = UDim2.new(0, 18, 0, 18),
                            Text = "",
                            ZIndex = 9,
                            Parent = row,
                        })
                        elemObj._colBtn = colBtn
                        elemObj._hasCol = true
                        if elemObj._reposition then elemObj._reposition() end

                        local picker = cr("Frame", {
                            BackgroundColor3 = C.popupBg,
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            Size = UDim2.new(0, 130, 0, 98),
                            Visible = false,
                            ZIndex = 101,
                            Parent = popupHolder,
                        })
                        corner(picker, 5)
                        stroke(picker, C.popupBorder, 1, 0.35)
                        pad(picker, 6, 6, 6, 6)

                        local function rgbRow(lbl, y, col, init)
                            cr("TextLabel", {
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 0, 0, y),
                                Size = UDim2.new(0, 12, 0, 16),
                                Font = FONT.mono, Text = lbl,
                                TextColor3 = col, TextSize = 9,
                                ZIndex = 102, Parent = picker,
                            })
                            local box = cr("TextBox", {
                                BackgroundColor3 = C.inputBg, BorderSizePixel = 0,
                                Position = UDim2.new(0, 14, 0, y),
                                Size = UDim2.new(0, 30, 0, 16),
                                Font = FONT.mono, Text = tostring(init),
                                TextColor3 = C.text, TextSize = 9,
                                ZIndex = 102, Parent = picker,
                            })
                            corner(box, 3)
                            return box
                        end

                        local rBox = rgbRow("R", 0, C.danger, math.floor(currentColor.R*255))
                        local gBox = rgbRow("G", 18, Color3.fromRGB(100,200,130), math.floor(currentColor.G*255))
                        local bBox = rgbRow("B", 36, theme.accent, math.floor(currentColor.B*255))

                        local preview = cr("Frame", {
                            BackgroundColor3 = currentColor, BorderSizePixel = 0,
                            Position = UDim2.new(0, 52, 0, 0),
                            Size = UDim2.new(0, 58, 0, 54),
                            ZIndex = 102, Parent = picker,
                        })
                        corner(preview, 4)
                        stroke(preview, C.inputBorder, 1, 0.4)

                        local applyBtn = cr("TextButton", {
                            BackgroundColor3 = theme.accent, BackgroundTransparency = 0.4,
                            BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 58),
                            Size = UDim2.new(1, 0, 0, 18),
                            Font = FONT.semibold, Text = "Apply",
                            TextColor3 = C.text, TextSize = 9,
                            AutoButtonColor = false, ZIndex = 102,
                            Parent = picker,
                        })
                        corner(applyBtn, 3)

                        local function updPreview()
                            local rv = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
                            local gv = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
                            local bv = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
                            preview.BackgroundColor3 = Color3.fromRGB(rv, gv, bv)
                        end
                        rBox:GetPropertyChangedSignal("Text"):Connect(updPreview)
                        gBox:GetPropertyChangedSignal("Text"):Connect(updPreview)
                        bBox:GetPropertyChangedSignal("Text"):Connect(updPreview)

                        applyBtn.MouseButton1Click:Connect(function()
                            local rv = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
                            local gv = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
                            local bv = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
                            currentColor = Color3.fromRGB(rv, gv, bv)
                            colInd.BackgroundColor3 = currentColor
                            elemData._colorPicker = {color = currentColor}
                            picker.Visible = false; pickerOpen = false
                            if colorCallback then colorCallback({Color = currentColor}) end
                        end)

                        colBtn.MouseButton1Click:Connect(function()
                            pickerOpen = not pickerOpen
                            if pickerOpen then
                                local ap = colInd.AbsolutePosition
                                picker.Position = UDim2.new(0, ap.X - 120, 0, ap.Y + 14)
                                picker.Visible = true
                            else
                                picker.Visible = false
                            end
                        end)

                        elemData._colorPicker = {color = currentColor}
                        elemData._setColor = function(col)
                            currentColor = col; colInd.BackgroundColor3 = col
                            rBox.Text = tostring(math.floor(col.R*255))
                            gBox.Text = tostring(math.floor(col.G*255))
                            bBox.Text = tostring(math.floor(col.B*255))
                            preview.BackgroundColor3 = col
                            elemData._colorPicker = {color = col}
                        end
                        return elemObj
                    end

                    lib._elements[elemId] = elemData
                    return elemObj
                end

                return sector
            end

            table.insert(tab._sections, section)
            return section
        end

        table.insert(lib._tabs, tab)
        table.insert(lib._panels, panel)
        repositionPanels()
        return tab
    end

    function lib.save_cfg(name)
        local data = {}
        for id, elem in pairs(lib._elements) do
            local entry = {type = elem.type}
            if elem.type == "Toggle" then entry.value = elem.value
            elseif elem.type == "Slider" then entry.value = elem.value
            elseif elem.type == "Dropdown" then entry.value = elem.value
            elseif elem.type == "TextBox" then entry.value = elem.value
            elseif elem.type == "Combo" then
                local sel = {}
                if typeof(elem.value) == "table" then
                    for k, v in pairs(elem.value) do if v then table.insert(sel, k) end end
                end
                entry.value = sel
            end
            if elem._keybind then entry.keybind = elem._keybind end
            if elem._colorPicker then
                local c = elem._colorPicker.color
                entry.color = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
            end
            data[id] = entry
        end
        writefile(lib._cfgFolder .. "_" .. name .. ".json", HttpService:JSONEncode(data))
    end

    function lib.load_cfg(name)
        local path = lib._cfgFolder .. "_" .. name .. ".json"
        if not isfile(path) then return end
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if not ok or not data then return end
        for id, entry in pairs(data) do
            local elem = lib._elements[id]
            if elem then
                if elem.type == "Toggle" and entry.value ~= nil then
                    if elem._setToggle then elem._setToggle(entry.value) end
                    if elem.callback then elem.callback({Toggle = entry.value}) end
                elseif elem.type == "Slider" and entry.value ~= nil then
                    if elem._updateSlider then elem._updateSlider(entry.value) end
                    if elem.callback then elem.callback({Slider = entry.value}) end
                elseif elem.type == "Dropdown" and entry.value ~= nil then
                    if elem._setDropdown then elem._setDropdown(entry.value) end
                    if elem.callback then elem.callback({Dropdown = entry.value}) end
                elseif elem.type == "TextBox" and entry.value ~= nil then
                    if elem._setText then elem._setText(entry.value) end
                    if elem.callback then elem.callback({Text = entry.value}) end
                elseif elem.type == "Combo" and entry.value ~= nil then
                    if elem._setCombo then elem._setCombo(entry.value) end
                    local r = {}
                    for _, v in ipairs(entry.value) do table.insert(r, v) end
                    if elem.callback then elem.callback({Combo = r}) end
                end
                if entry.keybind and elem._setKeybind then elem._setKeybind(entry.keybind.key) end
                if entry.color and elem._setColor then
                    elem._setColor(Color3.fromRGB(entry.color[1], entry.color[2], entry.color[3]))
                end
            end
        end
    end

    return lib
end

return Library
