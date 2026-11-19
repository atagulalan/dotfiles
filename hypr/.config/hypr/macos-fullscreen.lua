-- Aynı uygulamadan birden fazla fullscreen pencere olursa
-- workspace isimleri çakışmasın diye sayaç tutuyoruz.
local app_counters = {}

-- Window address -> move already queued. The fullscreen event fires while
-- Hyprland is still applying maximize. Moving in that handler leaves the
-- previous workspace's windows drawn on top of the new one: they look like
-- the front window, but hit-testing ignores them, so clicks do nothing.
local pending = {}
-- Bumped when fullscreen ends, so a queued move from the previous enter is dropped.
local generation = {}

local function sanitize(value)
  if not value or value == "" then
    return "App"
  end

  value = value
    :gsub("^%s+", "")
    :gsub("%s+$", "")
    :gsub("[^%w%-_]", "-")
    :gsub("%-+", "-")
    :gsub("^%-+", "")
    :gsub("%-+$", "")

  if value == "" then
    return "App"
  end

  return value
end

local function window_key(window)
  local addr = window.address
  if addr and tostring(addr) ~= "" then
    return tostring(addr)
  end
  return tostring(window)
end

local function is_fullscreen(window)
  local state = window.fullscreen
  return state == true or state == 1 or state == 2
end

local function app_name(window)
  local name = window.class

  if not name or name == "" then
    name = window.initialClass
  end

  if not name or name == "" then
    name = window.title
  end

  -- Wayland uygulamaları class olarak sıkça ters-domain kimliği kullanır:
  --   com.mitchellh.ghostty -> ghostty
  -- Workspace etiketinde paket kimliği yerine uygulama adını gösteriyoruz.
  if name and name:find("%.") then
    name = name:match("([^.]+)$") or name
  end

  name = sanitize(name)

  -- zen -> Zen, steam -> Steam, ghostty -> Ghostty
  return name:gsub("^%l", string.upper)
end

-- Dedicated workspaces are named after the app: "Cursor", "Cursor-2".
local function on_own_workspace(window)
  local ws = window.workspace
  local name = ws and ws.name or ""
  local app = app_name(window)
  if name == app then
    return true
  end
  local pattern = "^" .. app:gsub("%-", "%%-") .. "%-%d+$"
  return name:match(pattern) ~= nil
end

local function create_workspace_name(window)
  local app = app_name(window)

  app_counters[app] = (app_counters[app] or 0) + 1

  local index = app_counters[app]

  -- İlk pencere:
  --   Zen
  --
  -- İkinci fullscreen Zen:
  --   Zen-2
  if index == 1 then
    return "name:" .. app
  end

  return "name:" .. app .. "-" .. tostring(index)
end

local function schedule_move(window, follow)
  local key = window_key(window)

  if pending[key] or on_own_workspace(window) then
    return
  end

  local gen = generation[key] or 0
  local workspace = create_workspace_name(window)
  pending[key] = true

  -- Run after setFullscreenMode returns, so the old workspace is not
  -- recalculated after the window has already left it.
  hl.timer(function()
    if (generation[key] or 0) ~= gen then
      return
    end
    pending[key] = nil
    if not window or on_own_workspace(window) then
      return
    end
    -- Keep the view on the window the user just maximized. A window that
    -- dropped out of fullscreen (or was only in the way) still leaves,
    -- without stealing focus.
    local do_follow = follow and is_fullscreen(window)
    hl.dispatch(
      hl.dsp.window.move({
        window = window,
        workspace = workspace,
        follow = do_follow,
      })
    )
  end, { timeout = 50, type = "oneshot" })
end

-- Maximizing one window used to leave the others on that workspace, so Zen
-- stayed put when Cursor was maximized. Send every other window to its own
-- app workspace. The maximized window is queued last so follow lands on it.
local function evict_others(window)
  local ws = window.workspace
  local ws_id = ws and ws.id
  local ws_name = ws and ws.name or ""
  if not ws_id or ws_name:sub(1, 8) == "special:" then
    return
  end

  local mine = window_key(window)
  local list = hl.get_windows()
  for i = 1, #list do
    local other = list[i]
    if other and not other.pinned and other.mapped ~= false and other.hidden ~= true and window_key(other) ~= mine then
      local ows = other.workspace
      if ows and ows.id == ws_id then
        schedule_move(other, false)
      end
    end
  end
end

local function enter_fullscreen(window)
  local key = window_key(window)
  generation[key] = (generation[key] or 0) + 1
  pending[key] = nil

  evict_others(window)
  schedule_move(window, true)
end

hl.on("window.fullscreen", function(window)
  if not window then
    return
  end

  -- Fullscreen state API sürüme göre biraz değişebildiği için
  -- hem boolean hem numeric durumları tolere ediyoruz.
  if is_fullscreen(window) then
    enter_fullscreen(window)
  elseif not on_own_workspace(window) then
    -- Hyprland drops the previous fullscreen window when another one on the
    -- same workspace is maximized. Finish that window's move without following.
    -- Geri dönüş şimdilik devre dışı: kendi uygulama workspace'inde kalır.
    schedule_move(window, false)
  end
end)
