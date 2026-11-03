--[[
    Frosted Glass UI Library
    Vikings Studio Project Delta
    Matte frosted glass design
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local COLORS = {
    bg = Color3.fromRGB(18, 18, 24),
    bgGlass = Color3.fromRGB(25, 25, 35),
    surface = Color3.fromRGB(30, 30, 42),
    surfaceHover = Color3.fromRGB(38, 38, 52),
    border = Color3.fromRGB(55, 55, 75),
    borderLight = Color3.fromRGB(70, 70, 95),
    accent = Color3.fromRGB(110, 140, 255),
    accentDim = Color3.fromRGB(80, 105, 200),
    accentGlow = Color3.fromRGB(130, 160, 255),
    text = Color3.fromRGB(220, 220, 235),
    textDim = Color3.fromRGB(140, 140, 165),
    textMuted = Color3.fromRGB(90, 90, 115),
    toggleOn = Color3.fromRGB(100, 200, 130),
    toggleOff = Color3.fromRGB(60, 60, 80),
    sliderFill = Color3.fromRGB(110, 140, 255),
    danger = Color3.fromRGB(255, 80, 80),
    white = Color3.fromRGB(255, 255, 255),
    black = Color3.fromRGB(0, 0, 0),
    shadow = Color3.fromRGB(8, 8, 12),
}

local FONT = {
    regular = Enum.Font.Gotham,
    semibold = Enum.Font.GothamSemibold,
    bold = Enum.Font.GothamBold,
    mono = Enum.Font.RobotoMono,
}

local tweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenMedium = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenSlow = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function tween(obj, props, info)
    TweenService:Create(obj, info or tweenFast, props):Play()
end

local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Children" then
            inst[k] = v
        end
    end
    if props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function addCorner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or COLORS.border,
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        Parent = parent,
    })
end

local function addPadding(parent, t, b, l, r)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft = UDim.new(0, l or 8),
        PaddingRight = UDim.new(0, r or 8),
        Parent = parent,
    })
end

local function addListLayout(parent, padding, dir, hAlign, vAlign, sortOrder)
    return create("UIListLayout", {
        Padding = UDim.new(0, padding or 4),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local Library = {}

function Library.new(title, cfgFolder)
    local lib = {}
    lib._title = title or "Menu"
    lib._cfgFolder = cfgFolder or "DefaultCfg"
    lib._tabs = {}
    lib._activeTab = nil
    lib._elements = {}
    lib._elementOrder = 0
    lib._visible = true
    lib._toggleKey = Enum.KeyCode.RightShift

    local screenGui = create("ScreenGui", {
        Name = "FrostedGlassUI_" .. lib._cfgFolder,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = CoreGui,
    })
    lib._screenGui = screenGui

    local shadow = create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, -15, 0, -15),
        Size = UDim2.new(1, 30, 1, 30),
        Image = "rbxassetid://6014261993",
        ImageColor3 = COLORS.shadow,
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
    })

    local mainFrame = create("Frame", {
        Name = "Main",
        BackgroundColor3 = COLORS.bg,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -340, 0.5, -260),
        Size = UDim2.new(0, 680, 0, 520),
        ClipsDescendants = true,
        Parent = screenGui,
    })
    addCorner(mainFrame, 10)
    addStroke(mainFrame, COLORS.border, 1, 0.4)
    shadow.Parent = mainFrame
    lib._mainFrame = mainFrame

    local glassOverlay = create("Frame", {
        Name = "GlassOverlay",
        BackgroundColor3 = COLORS.bgGlass,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 0,
        Parent = mainFrame,
    })
    addCorner(glassOverlay, 10)

    local titleBar = create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = COLORS.surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 5,
        Parent = mainFrame,
    })
    addCorner(titleBar, 10)

    local titleBarBottom = create("Frame", {
        Name = "TitleBarBottom",
        BackgroundColor3 = COLORS.surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 10),
        ZIndex = 5,
        Parent = mainFrame,
    })

    local accentLine = create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 1),
        ZIndex = 6,
        Parent = mainFrame,
    })

    local titleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Font = FONT.bold,
        Text = lib._title,
        TextColor3 = COLORS.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
        Parent = titleBar,
    })

    local accentDot = create("TextLabel", {
        Name = "Dot",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -48, 0.5, -5),
        Size = UDim2.new(0, 10, 0, 10),
        Font = FONT.bold,
        Text = "●",
        TextColor3 = COLORS.toggleOn,
        TextSize = 10,
        ZIndex = 6,
        Parent = titleBar,
    })

    local closeBtn = create("TextButton", {
        Name = "Close",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0.5, -8),
        Size = UDim2.new(0, 16, 0, 16),
        Font = FONT.bold,
        Text = "×",
        TextColor3 = COLORS.textDim,
        TextSize = 18,
        ZIndex = 6,
        Parent = titleBar,
    })
    closeBtn.MouseEnter:Connect(function() tween(closeBtn, {TextColor3 = COLORS.danger}) end)
    closeBtn.MouseLeave:Connect(function() tween(closeBtn, {TextColor3 = COLORS.textDim}) end)
    closeBtn.MouseButton1Click:Connect(function()
        lib._visible = false
        tween(mainFrame, {Position = UDim2.new(0.5, -340, 0.5, -240), Size = UDim2.new(0, 680, 0, 0)}, tweenMedium)
        task.delay(0.25, function() mainFrame.Visible = false end)
    end)

    makeDraggable(mainFrame, titleBar)

    local tabBar = create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = COLORS.surface,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 37),
        Size = UDim2.new(0, 52, 1, -37),
        ZIndex = 3,
        Parent = mainFrame,
    })

    local tabBarBg = create("Frame", {
        Name = "TabBarBg",
        BackgroundColor3 = COLORS.bg,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 0,
        Parent = tabBar,
    })

    local tabDivider = create("Frame", {
        Name = "TabDivider",
        BackgroundColor3 = COLORS.border,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 4,
        Parent = tabBar,
    })

    local tabList = create("Frame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 8),
        Size = UDim2.new(1, 0, 1, -8),
        Parent = tabBar,
    })
    addListLayout(tabList, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

    local contentArea = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 52, 0, 37),
        Size = UDim2.new(1, -52, 1, -37),
        ClipsDescendants = true,
        ZIndex = 2,
        Parent = mainFrame,
    })
    lib._contentArea = contentArea

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == lib._toggleKey then
            lib._visible = not lib._visible
            if lib._visible then
                mainFrame.Visible = true
                mainFrame.Size = UDim2.new(0, 680, 0, 0)
                tween(mainFrame, {Size = UDim2.new(0, 680, 0, 520)}, tweenMedium)
            else
                tween(mainFrame, {Size = UDim2.new(0, 680, 0, 0)}, tweenMedium)
                task.delay(0.25, function() mainFrame.Visible = false end)
            end
        end
    end)

    local function switchTab(idx)
        if lib._activeTab == idx then return end
        lib._activeTab = idx
        for i, tab in ipairs(lib._tabs) do
            local isActive = (i == idx)
            tween(tab._button, {BackgroundTransparency = isActive and 0.5 or 1})
            tween(tab._indicator, {BackgroundTransparency = isActive and 0 or 1})
            if tab._icon then
                tween(tab._icon, {ImageColor3 = isActive and COLORS.accent or COLORS.textMuted, ImageTransparency = isActive and 0 or 0.4})
            end
            for _, sectionFrame in ipairs(tab._sectionFrames) do
                sectionFrame.Visible = isActive
            end
        end
    end
    lib._switchTab = switchTab

    function lib.new_tab(iconId)
        local tabIdx = #lib._tabs + 1
        local tab = {
            _index = tabIdx,
            _sections = {},
            _sectionFrames = {},
        }

        local tabButton = create("TextButton", {
            Name = "Tab" .. tabIdx,
            BackgroundColor3 = COLORS.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 44, 0, 40),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 4,
            Parent = tabList,
        })
        addCorner(tabButton, 8)
        tab._button = tabButton

        local indicator = create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = COLORS.accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0.5, -10),
            Size = UDim2.new(0, 3, 0, 20),
            ZIndex = 5,
            Parent = tabButton,
        })
        addCorner(indicator, 2)
        tab._indicator = indicator

        if iconId and iconId ~= "" then
            local icon = create("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, -10, 0.5, -10),
                Size = UDim2.new(0, 20, 0, 20),
                Image = iconId,
                ImageColor3 = COLORS.textMuted,
                ImageTransparency = 0.4,
                ZIndex = 5,
                Parent = tabButton,
            })
            tab._icon = icon
        end

        tabButton.MouseEnter:Connect(function()
            if lib._activeTab ~= tabIdx then
                tween(tabButton, {BackgroundTransparency = 0.7})
            end
        end)
        tabButton.MouseLeave:Connect(function()
            if lib._activeTab ~= tabIdx then
                tween(tabButton, {BackgroundTransparency = 1})
            end
        end)
        tabButton.MouseButton1Click:Connect(function()
            switchTab(tabIdx)
        end)

        function tab.new_section(sectionName)
            local section = { _name = sectionName, _sectors = {} }

            local sectionFrame = create("ScrollingFrame", {
                Name = "Section_" .. sectionName,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = COLORS.accentDim,
                ScrollBarImageTransparency = 0.5,
                Visible = false,
                ZIndex = 2,
                Parent = contentArea,
            })
            addPadding(sectionFrame, 10, 10, 10, 10)

            local columns = create("Frame", {
                Name = "Columns",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = sectionFrame,
            })

            local leftColumn = create("Frame", {
                Name = "Left",
                BackgroundTransparency = 1,
                Size = UDim2.new(0.5, -5, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = columns,
            })
            addListLayout(leftColumn, 8)

            local rightColumn = create("Frame", {
                Name = "Right",
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 5, 0, 0),
                Size = UDim2.new(0.5, -5, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = columns,
            })
            addListLayout(rightColumn, 8)

            section._frame = sectionFrame
            section._columns = columns
            section._leftColumn = leftColumn
            section._rightColumn = rightColumn

            table.insert(tab._sectionFrames, sectionFrame)

            local function updateCanvasSize()
                task.defer(function()
                    local leftH = leftColumn.AbsoluteSize.Y
                    local rightH = rightColumn.AbsoluteSize.Y
                    local maxH = math.max(leftH, rightH) + 30
                    sectionFrame.CanvasSize = UDim2.new(0, 0, 0, maxH)
                end)
            end

            leftColumn:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasSize)
            rightColumn:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasSize)

            function section.new_sector(sectorName, side)
                local sector = { _name = sectorName, _elements = {} }
                local parentCol = (side == "Right") and rightColumn or leftColumn

                local sectorFrame = create("Frame", {
                    Name = "Sector_" .. sectorName,
                    BackgroundColor3 = COLORS.surface,
                    BackgroundTransparency = 0.4,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 2,
                    Parent = parentCol,
                })
                addCorner(sectorFrame, 8)
                addStroke(sectorFrame, COLORS.border, 1, 0.6)

                local sectorHeader = create("TextLabel", {
                    Name = "Header",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    Font = FONT.semibold,
                    Text = "  " .. sectorName,
                    TextColor3 = COLORS.textDim,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 3,
                    Parent = sectorFrame,
                })

                local headerLine = create("Frame", {
                    Name = "HeaderLine",
                    BackgroundColor3 = COLORS.border,
                    BackgroundTransparency = 0.6,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 8, 0, 28),
                    Size = UDim2.new(1, -16, 0, 1),
                    ZIndex = 3,
                    Parent = sectorFrame,
                })

                local elementContainer = create("Frame", {
                    Name = "Elements",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 32),
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 2,
                    Parent = sectorFrame,
                })
                addPadding(elementContainer, 2, 8, 10, 10)
                addListLayout(elementContainer, 3)

                sector._frame = sectorFrame
                sector._elementContainer = elementContainer

                function sector.element(elemType, elemName, default, callback)
                    lib._elementOrder = lib._elementOrder + 1
                    local elemId = lib._cfgFolder .. "_" .. elemName .. "_" .. lib._elementOrder
                    local elemData = {
                        id = elemId,
                        type = elemType,
                        name = elemName,
                        value = nil,
                        callback = callback,
                        _keybind = nil,
                        _colorPicker = nil,
                    }

                    local elemObj = {}

                    if elemType == "Toggle" then
                        local toggled = false
                        elemData.value = toggled

                        local row = create("Frame", {
                            Name = "Toggle_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local label = create("TextLabel", {
                            Name = "Label",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 0, 0, 0),
                            Size = UDim2.new(1, -50, 1, 0),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 3,
                            Parent = row,
                        })

                        local toggleBg = create("Frame", {
                            Name = "ToggleBg",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(1, -38, 0.5, -8),
                            Size = UDim2.new(0, 32, 0, 16),
                            ZIndex = 4,
                            Parent = row,
                        })
                        addCorner(toggleBg, 8)

                        local toggleKnob = create("Frame", {
                            Name = "Knob",
                            BackgroundColor3 = COLORS.white,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 2, 0.5, -6),
                            Size = UDim2.new(0, 12, 0, 12),
                            ZIndex = 5,
                            Parent = toggleBg,
                        })
                        addCorner(toggleKnob, 6)

                        local toggleBtn = create("TextButton", {
                            Name = "ToggleBtn",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0),
                            Text = "",
                            ZIndex = 6,
                            Parent = row,
                        })

                        local function setToggle(val)
                            toggled = val
                            elemData.value = val
                            tween(toggleBg, {BackgroundColor3 = val and COLORS.toggleOn or COLORS.toggleOff}, tweenFast)
                            tween(toggleKnob, {Position = val and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}, tweenFast)
                            tween(label, {TextColor3 = val and COLORS.text or COLORS.textDim}, tweenFast)
                        end
                        elemData._setToggle = setToggle

                        toggleBtn.MouseButton1Click:Connect(function()
                            setToggle(not toggled)
                            if callback then
                                callback({ Toggle = toggled })
                            end
                        end)

                        elemObj._row = row
                        elemObj._toggleBg = toggleBg

                    elseif elemType == "Slider" then
                        local opts = default and default.default or {}
                        local minVal = opts.min or 0
                        local maxVal = opts.max or 100
                        local curVal = opts.default or minVal
                        elemData.value = curVal

                        local container = create("Frame", {
                            Name = "Slider_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 38),
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local label = create("TextLabel", {
                            Name = "Label",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, -40, 0, 16),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local valLabel = create("TextLabel", {
                            Name = "Value",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -40, 0, 0),
                            Size = UDim2.new(0, 40, 0, 16),
                            Font = FONT.mono,
                            Text = tostring(curVal),
                            TextColor3 = COLORS.accent,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Right,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local sliderBg = create("Frame", {
                            Name = "SliderBg",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 20),
                            Size = UDim2.new(1, 0, 0, 6),
                            ZIndex = 3,
                            Parent = container,
                        })
                        addCorner(sliderBg, 3)

                        local frac = (curVal - minVal) / math.max(maxVal - minVal, 1)
                        local sliderFill = create("Frame", {
                            Name = "Fill",
                            BackgroundColor3 = COLORS.sliderFill,
                            BackgroundTransparency = 0.15,
                            BorderSizePixel = 0,
                            Size = UDim2.new(frac, 0, 1, 0),
                            ZIndex = 4,
                            Parent = sliderBg,
                        })
                        addCorner(sliderFill, 3)

                        local sliderKnob = create("Frame", {
                            Name = "Knob",
                            BackgroundColor3 = COLORS.white,
                            BorderSizePixel = 0,
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.new(frac, 0, 0.5, 0),
                            Size = UDim2.new(0, 12, 0, 12),
                            ZIndex = 5,
                            Parent = sliderBg,
                        })
                        addCorner(sliderKnob, 6)
                        addStroke(sliderKnob, COLORS.accent, 2, 0.3)

                        local sliderBtn = create("TextButton", {
                            Name = "SliderBtn",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0, 0, 0, 14),
                            Size = UDim2.new(1, 0, 0, 20),
                            Text = "",
                            ZIndex = 6,
                            Parent = container,
                        })

                        local dragging = false
                        local function updateSlider(input)
                            local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                            local val = math.floor(minVal + rel * (maxVal - minVal) + 0.5)
                            curVal = val
                            elemData.value = val
                            valLabel.Text = tostring(val)
                            local f = (val - minVal) / math.max(maxVal - minVal, 1)
                            sliderFill.Size = UDim2.new(f, 0, 1, 0)
                            sliderKnob.Position = UDim2.new(f, 0, 0.5, 0)
                            if callback then callback({ Slider = val }) end
                        end
                        elemData._updateSlider = function(val)
                            curVal = val
                            elemData.value = val
                            valLabel.Text = tostring(val)
                            local f = (val - minVal) / math.max(maxVal - minVal, 1)
                            sliderFill.Size = UDim2.new(f, 0, 1, 0)
                            sliderKnob.Position = UDim2.new(f, 0, 0.5, 0)
                        end

                        sliderBtn.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                updateSlider(input)
                            end
                        end)
                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                updateSlider(input)
                            end
                        end)
                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end)

                    elseif elemType == "Dropdown" then
                        local opts = default and default.options or {}
                        local cleanOpts = {}
                        for _, v in ipairs(opts) do
                            if v ~= nil then table.insert(cleanOpts, v) end
                        end
                        local selected = cleanOpts[1]
                        elemData.value = selected
                        local dropOpen = false

                        local container = create("Frame", {
                            Name = "Dropdown_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 42),
                            ClipsDescendants = false,
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local label = create("TextLabel", {
                            Name = "Label",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 14),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local dropBtn = create("TextButton", {
                            Name = "DropBtn",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 16),
                            Size = UDim2.new(1, 0, 0, 24),
                            Font = FONT.regular,
                            Text = "  " .. (selected or "Select..."),
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        addCorner(dropBtn, 5)
                        addStroke(dropBtn, COLORS.border, 1, 0.6)

                        local arrow = create("TextLabel", {
                            Name = "Arrow",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -20, 0, 0),
                            Size = UDim2.new(0, 16, 1, 0),
                            Font = FONT.regular,
                            Text = "▾",
                            TextColor3 = COLORS.textDim,
                            TextSize = 14,
                            ZIndex = 5,
                            Parent = dropBtn,
                        })

                        local dropList = create("Frame", {
                            Name = "DropList",
                            BackgroundColor3 = COLORS.surface,
                            BackgroundTransparency = 0.1,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 42),
                            Size = UDim2.new(1, 0, 0, 0),
                            ClipsDescendants = true,
                            Visible = false,
                            ZIndex = 50,
                            Parent = container,
                        })
                        addCorner(dropList, 5)
                        addStroke(dropList, COLORS.border, 1, 0.4)
                        addPadding(dropList, 3, 3, 3, 3)
                        local dlLayout = addListLayout(dropList, 1)

                        for i, opt in ipairs(cleanOpts) do
                            local optBtn = create("TextButton", {
                                Name = "Opt_" .. opt,
                                BackgroundColor3 = COLORS.surfaceHover,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 22),
                                Font = FONT.regular,
                                Text = "  " .. opt,
                                TextColor3 = COLORS.text,
                                TextSize = 11,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                AutoButtonColor = false,
                                ZIndex = 51,
                                Parent = dropList,
                            })
                            addCorner(optBtn, 4)
                            optBtn.MouseEnter:Connect(function()
                                tween(optBtn, {BackgroundTransparency = 0.4})
                            end)
                            optBtn.MouseLeave:Connect(function()
                                tween(optBtn, {BackgroundTransparency = 1})
                            end)
                            optBtn.MouseButton1Click:Connect(function()
                                selected = opt
                                elemData.value = opt
                                dropBtn.Text = "  " .. opt
                                dropOpen = false
                                dropList.Visible = false
                                tween(dropList, {Size = UDim2.new(1, 0, 0, 0)}, tweenFast)
                                if callback then callback({ Dropdown = opt }) end
                            end)
                        end

                        elemData._setDropdown = function(val)
                            selected = val
                            elemData.value = val
                            dropBtn.Text = "  " .. tostring(val)
                        end

                        dropBtn.MouseButton1Click:Connect(function()
                            dropOpen = not dropOpen
                            if dropOpen then
                                local listH = #cleanOpts * 23 + 8
                                dropList.Size = UDim2.new(1, 0, 0, 0)
                                dropList.Visible = true
                                tween(dropList, {Size = UDim2.new(1, 0, 0, math.min(listH, 180))}, tweenFast)
                            else
                                tween(dropList, {Size = UDim2.new(1, 0, 0, 0)}, tweenFast)
                                task.delay(0.15, function() dropList.Visible = false end)
                            end
                        end)

                    elseif elemType == "Button" then
                        local container = create("Frame", {
                            Name = "Button_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 28),
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local btn = create("TextButton", {
                            Name = "Btn",
                            BackgroundColor3 = COLORS.accentDim,
                            BackgroundTransparency = 0.4,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 26),
                            Font = FONT.semibold,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 12,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        addCorner(btn, 6)
                        addStroke(btn, COLORS.accent, 1, 0.5)

                        btn.MouseEnter:Connect(function()
                            tween(btn, {BackgroundTransparency = 0.2}, tweenFast)
                        end)
                        btn.MouseLeave:Connect(function()
                            tween(btn, {BackgroundTransparency = 0.4}, tweenFast)
                        end)
                        btn.MouseButton1Click:Connect(function()
                            tween(btn, {BackgroundTransparency = 0}, tweenFast)
                            task.delay(0.1, function() tween(btn, {BackgroundTransparency = 0.4}, tweenFast) end)
                            if callback then callback(true) end
                        end)

                    elseif elemType == "TextBox" then
                        local container = create("Frame", {
                            Name = "TextBox_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 40),
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local label = create("TextLabel", {
                            Name = "Label",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 14),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local textBox = create("TextBox", {
                            Name = "Input",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 16),
                            Size = UDim2.new(1, 0, 0, 22),
                            Font = FONT.regular,
                            PlaceholderText = elemName,
                            PlaceholderColor3 = COLORS.textMuted,
                            Text = "",
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            ClearTextOnFocus = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        addCorner(textBox, 5)
                        addStroke(textBox, COLORS.border, 1, 0.6)
                        addPadding(textBox, 0, 0, 6, 6)
                        elemData.value = ""

                        textBox.FocusLost:Connect(function(enter)
                            elemData.value = textBox.Text
                            if callback then callback({ Text = textBox.Text }) end
                        end)

                        elemData._setText = function(val)
                            textBox.Text = val
                            elemData.value = val
                        end

                    elseif elemType == "Combo" then
                        local opts = default and default.options or {}
                        local cleanOpts = {}
                        for _, v in ipairs(opts) do
                            if v ~= nil then table.insert(cleanOpts, v) end
                        end
                        local selectedSet = {}
                        elemData.value = selectedSet

                        local container = create("Frame", {
                            Name = "Combo_" .. elemName,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 42),
                            ClipsDescendants = false,
                            ZIndex = 3,
                            Parent = elementContainer,
                        })

                        local label = create("TextLabel", {
                            Name = "Label",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 14),
                            Font = FONT.regular,
                            Text = elemName,
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex = 3,
                            Parent = container,
                        })

                        local comboBtn = create("TextButton", {
                            Name = "ComboBtn",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 16),
                            Size = UDim2.new(1, 0, 0, 24),
                            Font = FONT.regular,
                            Text = "  Select...",
                            TextColor3 = COLORS.text,
                            TextSize = 11,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            AutoButtonColor = false,
                            ZIndex = 4,
                            Parent = container,
                        })
                        addCorner(comboBtn, 5)
                        addStroke(comboBtn, COLORS.border, 1, 0.6)

                        local comboArrow = create("TextLabel", {
                            Name = "Arrow",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -20, 0, 0),
                            Size = UDim2.new(0, 16, 1, 0),
                            Font = FONT.regular,
                            Text = "▾",
                            TextColor3 = COLORS.textDim,
                            TextSize = 14,
                            ZIndex = 5,
                            Parent = comboBtn,
                        })

                        local comboList = create("Frame", {
                            Name = "ComboList",
                            BackgroundColor3 = COLORS.surface,
                            BackgroundTransparency = 0.1,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 0, 0, 42),
                            Size = UDim2.new(1, 0, 0, 0),
                            ClipsDescendants = true,
                            Visible = false,
                            ZIndex = 50,
                            Parent = container,
                        })
                        addCorner(comboList, 5)
                        addStroke(comboList, COLORS.border, 1, 0.4)
                        addPadding(comboList, 3, 3, 3, 3)
                        addListLayout(comboList, 1)

                        local comboOpen = false
                        local checkmarks = {}

                        local function updateComboLabel()
                            local sel = {}
                            for _, opt in ipairs(cleanOpts) do
                                if selectedSet[opt] then table.insert(sel, opt) end
                            end
                            if #sel == 0 then
                                comboBtn.Text = "  Select..."
                            elseif #sel <= 2 then
                                comboBtn.Text = "  " .. table.concat(sel, ", ")
                            else
                                comboBtn.Text = "  " .. #sel .. " selected"
                            end
                        end

                        local function getComboResult()
                            local result = {}
                            for _, opt in ipairs(cleanOpts) do
                                if selectedSet[opt] then table.insert(result, opt) end
                            end
                            return result
                        end

                        for i, opt in ipairs(cleanOpts) do
                            local optRow = create("TextButton", {
                                Name = "Opt_" .. opt,
                                BackgroundColor3 = COLORS.surfaceHover,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2.new(1, 0, 0, 22),
                                Font = FONT.regular,
                                Text = "",
                                AutoButtonColor = false,
                                ZIndex = 51,
                                Parent = comboList,
                            })
                            addCorner(optRow, 4)

                            local check = create("TextLabel", {
                                Name = "Check",
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 4, 0, 0),
                                Size = UDim2.new(0, 18, 1, 0),
                                Font = FONT.regular,
                                Text = "☐",
                                TextColor3 = COLORS.textDim,
                                TextSize = 13,
                                ZIndex = 52,
                                Parent = optRow,
                            })
                            checkmarks[opt] = check

                            local optLabel = create("TextLabel", {
                                Name = "Label",
                                BackgroundTransparency = 1,
                                Position = UDim2.new(0, 22, 0, 0),
                                Size = UDim2.new(1, -26, 1, 0),
                                Font = FONT.regular,
                                Text = opt,
                                TextColor3 = COLORS.text,
                                TextSize = 11,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 52,
                                Parent = optRow,
                            })

                            optRow.MouseEnter:Connect(function() tween(optRow, {BackgroundTransparency = 0.4}) end)
                            optRow.MouseLeave:Connect(function() tween(optRow, {BackgroundTransparency = 1}) end)
                            optRow.MouseButton1Click:Connect(function()
                                selectedSet[opt] = not selectedSet[opt]
                                check.Text = selectedSet[opt] and "☑" or "☐"
                                check.TextColor3 = selectedSet[opt] and COLORS.accent or COLORS.textDim
                                updateComboLabel()
                                if callback then callback({ Combo = getComboResult() }) end
                            end)
                        end

                        elemData._setCombo = function(vals)
                            selectedSet = {}
                            for _, v in ipairs(vals) do selectedSet[v] = true end
                            for opt, check in pairs(checkmarks) do
                                check.Text = selectedSet[opt] and "☑" or "☐"
                                check.TextColor3 = selectedSet[opt] and COLORS.accent or COLORS.textDim
                            end
                            updateComboLabel()
                        end

                        comboBtn.MouseButton1Click:Connect(function()
                            comboOpen = not comboOpen
                            if comboOpen then
                                local listH = #cleanOpts * 23 + 8
                                comboList.Size = UDim2.new(1, 0, 0, 0)
                                comboList.Visible = true
                                tween(comboList, {Size = UDim2.new(1, 0, 0, math.min(listH, 200))}, tweenFast)
                            else
                                tween(comboList, {Size = UDim2.new(1, 0, 0, 0)}, tweenFast)
                                task.delay(0.15, function() comboList.Visible = false end)
                            end
                        end)
                    end

                    function elemObj:add_keybind(mode, keybindCallback)
                        local currentKey = nil
                        local active = false
                        local listening = false

                        local row = elemObj._row or (elementContainer:FindFirstChild(elemType .. "_" .. elemName))
                        if not row then
                            row = create("Frame", {
                                Name = "KB_" .. elemName,
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 0, 22),
                                ZIndex = 3,
                                Parent = elementContainer,
                            })
                        end

                        local kbBtn = create("TextButton", {
                            Name = "KeyBind",
                            BackgroundColor3 = COLORS.toggleOff,
                            BorderSizePixel = 0,
                            Position = UDim2.new(1, -58, 0.5, -9),
                            Size = UDim2.new(0, 52, 0, 18),
                            Font = FONT.mono,
                            Text = mode == "None" and "[...]" or "[...]",
                            TextColor3 = COLORS.textDim,
                            TextSize = 10,
                            AutoButtonColor = false,
                            ZIndex = 6,
                            Parent = row,
                        })
                        addCorner(kbBtn, 4)

                        kbBtn.MouseButton1Click:Connect(function()
                            listening = true
                            kbBtn.Text = "[?]"
                            tween(kbBtn, {BackgroundColor3 = COLORS.accentDim}, tweenFast)
                        end)

                        UserInputService.InputBegan:Connect(function(input, gpe)
                            if listening then
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    if input.KeyCode == Enum.KeyCode.Escape then
                                        currentKey = nil
                                        kbBtn.Text = "[...]"
                                    else
                                        currentKey = input.KeyCode
                                        kbBtn.Text = "[" .. input.KeyCode.Name .. "]"
                                    end
                                    listening = false
                                    tween(kbBtn, {BackgroundColor3 = COLORS.toggleOff}, tweenFast)
                                    return
                                end
                            end
                            if not gpe and currentKey and input.KeyCode == currentKey then
                                if mode == "Hold" then
                                    active = true
                                    if keybindCallback then keybindCallback({ Active = true, Key = currentKey.Name }) end
                                elseif mode == "Toggle" then
                                    active = not active
                                    if keybindCallback then keybindCallback({ Active = active, Key = currentKey.Name }) end
                                elseif mode == "None" then
                                    active = not active
                                    if keybindCallback then keybindCallback({ Active = active, Key = currentKey.Name }) end
                                end
                            end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if currentKey and input.KeyCode == currentKey and mode == "Hold" then
                                active = false
                                if keybindCallback then keybindCallback({ Active = false, Key = currentKey.Name }) end
                            end
                        end)

                        elemData._keybind = { mode = mode, key = currentKey }
                        elemData._setKeybind = function(keyName)
                            local ok, key = pcall(function() return Enum.KeyCode[keyName] end)
                            if ok and key then
                                currentKey = key
                                kbBtn.Text = "[" .. keyName .. "]"
                            end
                        end
                        return elemObj
                    end

                    function elemObj:add_color(colorDefault, _, colorCallback)
                        local currentColor = colorDefault and colorDefault.Color or Color3.fromRGB(255, 255, 255)
                        local pickerOpen = false

                        local row = elemObj._row or (elementContainer:FindFirstChild(elemType .. "_" .. elemName))
                        if not row then return elemObj end

                        local colorIndicator = create("Frame", {
                            Name = "ColorInd",
                            BackgroundColor3 = currentColor,
                            BorderSizePixel = 0,
                            Position = UDim2.new(1, -16, 0.5, -6),
                            Size = UDim2.new(0, 12, 0, 12),
                            ZIndex = 6,
                            Parent = row,
                        })
                        addCorner(colorIndicator, 3)
                        addStroke(colorIndicator, COLORS.border, 1, 0.4)

                        local colorBtn = create("TextButton", {
                            Name = "ColorBtn",
                            BackgroundTransparency = 1,
                            Position = UDim2.new(1, -20, 0.5, -10),
                            Size = UDim2.new(0, 20, 0, 20),
                            Text = "",
                            ZIndex = 7,
                            Parent = row,
                        })

                        local pickerFrame = create("Frame", {
                            Name = "Picker",
                            BackgroundColor3 = COLORS.surface,
                            BackgroundTransparency = 0.05,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, -110, 1, 4),
                            Size = UDim2.new(0, 130, 0, 100),
                            Visible = false,
                            ZIndex = 60,
                            Parent = row,
                        })
                        addCorner(pickerFrame, 6)
                        addStroke(pickerFrame, COLORS.border, 1, 0.3)
                        addPadding(pickerFrame, 8, 8, 8, 8)

                        local rLabel = create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0, 14, 0, 18),
                            Font = FONT.mono, Text = "R", TextColor3 = COLORS.danger, TextSize = 10,
                            ZIndex = 61, Parent = pickerFrame,
                        })
                        local rBox = create("TextBox", {
                            BackgroundColor3 = COLORS.toggleOff, BorderSizePixel = 0,
                            Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(0, 30, 0, 18),
                            Font = FONT.mono, Text = tostring(math.floor(currentColor.R * 255)),
                            TextColor3 = COLORS.text, TextSize = 10, ZIndex = 61, Parent = pickerFrame,
                        })
                        addCorner(rBox, 3)

                        local gLabel = create("TextLabel", {
                            BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 22),
                            Size = UDim2.new(0, 14, 0, 18),
                            Font = FONT.mono, Text = "G", TextColor3 = COLORS.toggleOn, TextSize = 10,
                            ZIndex = 61, Parent = pickerFrame,
                        })
                        local gBox = create("TextBox", {
                            BackgroundColor3 = COLORS.toggleOff, BorderSizePixel = 0,
                            Position = UDim2.new(0, 18, 0, 22), Size = UDim2.new(0, 30, 0, 18),
                            Font = FONT.mono, Text = tostring(math.floor(currentColor.G * 255)),
                            TextColor3 = COLORS.text, TextSize = 10, ZIndex = 61, Parent = pickerFrame,
                        })
                        addCorner(gBox, 3)

                        local bLabel = create("TextLabel", {
                            BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 44),
                            Size = UDim2.new(0, 14, 0, 18),
                            Font = FONT.mono, Text = "B", TextColor3 = COLORS.accent, TextSize = 10,
                            ZIndex = 61, Parent = pickerFrame,
                        })
                        local bBox = create("TextBox", {
                            BackgroundColor3 = COLORS.toggleOff, BorderSizePixel = 0,
                            Position = UDim2.new(0, 18, 0, 44), Size = UDim2.new(0, 30, 0, 18),
                            Font = FONT.mono, Text = tostring(math.floor(currentColor.B * 255)),
                            TextColor3 = COLORS.text, TextSize = 10, ZIndex = 61, Parent = pickerFrame,
                        })
                        addCorner(bBox, 3)

                        local previewBox = create("Frame", {
                            BackgroundColor3 = currentColor, BorderSizePixel = 0,
                            Position = UDim2.new(0, 60, 0, 0), Size = UDim2.new(0, 46, 0, 62),
                            ZIndex = 61, Parent = pickerFrame,
                        })
                        addCorner(previewBox, 5)
                        addStroke(previewBox, COLORS.border, 1, 0.4)

                        local applyBtn = create("TextButton", {
                            BackgroundColor3 = COLORS.accentDim, BackgroundTransparency = 0.3,
                            BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 68),
                            Size = UDim2.new(1, 0, 0, 18), Font = FONT.semibold,
                            Text = "Apply", TextColor3 = COLORS.text, TextSize = 10,
                            AutoButtonColor = false, ZIndex = 61, Parent = pickerFrame,
                        })
                        addCorner(applyBtn, 4)

                        local function updatePreview()
                            local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
                            local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
                            local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
                            previewBox.BackgroundColor3 = Color3.fromRGB(r, g, b)
                        end

                        rBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
                        gBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)
                        bBox:GetPropertyChangedSignal("Text"):Connect(updatePreview)

                        applyBtn.MouseButton1Click:Connect(function()
                            local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
                            local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
                            local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
                            currentColor = Color3.fromRGB(r, g, b)
                            colorIndicator.BackgroundColor3 = currentColor
                            pickerFrame.Visible = false
                            pickerOpen = false
                            if colorCallback then colorCallback({ Color = currentColor }) end
                        end)

                        colorBtn.MouseButton1Click:Connect(function()
                            pickerOpen = not pickerOpen
                            pickerFrame.Visible = pickerOpen
                        end)

                        elemData._colorPicker = { color = currentColor }
                        elemData._setColor = function(col)
                            currentColor = col
                            colorIndicator.BackgroundColor3 = col
                            rBox.Text = tostring(math.floor(col.R * 255))
                            gBox.Text = tostring(math.floor(col.G * 255))
                            bBox.Text = tostring(math.floor(col.B * 255))
                            previewBox.BackgroundColor3 = col
                        end

                        return elemObj
                    end

                    lib._elements[elemId] = elemData
                    return elemObj
                end

                table.insert(section._sectors, sector)
                return sector
            end

            table.insert(tab._sections, section)
            return section
        end

        table.insert(lib._tabs, tab)
        if tabIdx == 1 then
            task.defer(function() switchTab(1) end)
        end
        return tab
    end

    function lib.save_cfg(name)
        local data = {}
        for id, elem in pairs(lib._elements) do
            local entry = { type = elem.type, value = nil }
            if elem.type == "Toggle" then
                entry.value = elem.value
            elseif elem.type == "Slider" then
                entry.value = elem.value
            elseif elem.type == "Dropdown" then
                entry.value = elem.value
            elseif elem.type == "TextBox" then
                entry.value = elem.value
            elseif elem.type == "Combo" then
                local sel = {}
                if typeof(elem.value) == "table" then
                    for k, v in pairs(elem.value) do
                        if v then table.insert(sel, k) end
                    end
                end
                entry.value = sel
            end
            if elem._keybind then
                entry.keybind = elem._keybind
            end
            if elem._colorPicker then
                local c = elem._colorPicker.color
                entry.color = { math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) }
            end
            data[id] = entry
        end
        local json = HttpService:JSONEncode(data)
        local cfgPath = lib._cfgFolder .. "_" .. name .. ".json"
        writefile(cfgPath, json)
    end

    function lib.load_cfg(name)
        local cfgPath = lib._cfgFolder .. "_" .. name .. ".json"
        if not isfile(cfgPath) then return end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(cfgPath))
        end)
        if not ok or not data then return end
        for id, entry in pairs(data) do
            local elem = lib._elements[id]
            if elem then
                if elem.type == "Toggle" and entry.value ~= nil then
                    if elem._setToggle then elem._setToggle(entry.value) end
                    if elem.callback then elem.callback({ Toggle = entry.value }) end
                elseif elem.type == "Slider" and entry.value ~= nil then
                    if elem._updateSlider then elem._updateSlider(entry.value) end
                    if elem.callback then elem.callback({ Slider = entry.value }) end
                elseif elem.type == "Dropdown" and entry.value ~= nil then
                    if elem._setDropdown then elem._setDropdown(entry.value) end
                    if elem.callback then elem.callback({ Dropdown = entry.value }) end
                elseif elem.type == "TextBox" and entry.value ~= nil then
                    if elem._setText then elem._setText(entry.value) end
                    if elem.callback then elem.callback({ Text = entry.value }) end
                elseif elem.type == "Combo" and entry.value ~= nil then
                    if elem._setCombo then elem._setCombo(entry.value) end
                    local result = {}
                    for _, v in ipairs(entry.value) do table.insert(result, v) end
                    if elem.callback then elem.callback({ Combo = result }) end
                end
                if entry.keybind and elem._setKeybind then
                    elem._setKeybind(entry.keybind.key)
                end
                if entry.color and elem._setColor then
                    elem._setColor(Color3.fromRGB(entry.color[1], entry.color[2], entry.color[3]))
                end
            end
        end
    end

    return lib
end

return Library
