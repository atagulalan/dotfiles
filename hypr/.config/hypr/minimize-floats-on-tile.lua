-- When a tiled window becomes active, shelf floating windows on that workspace
-- into special:omarchy-minimized (same shelf as SUPER+M / window-controls).

local MINIMIZE_WS = "special:omarchy-minimized"
local busy = false

local function window_address(window)
  local addr = window and window.address
  if not addr or addr == "" then
    return nil
  end
  addr = tostring(addr)
  if addr:sub(1, 2) ~= "0x" then
    addr = "0x" .. addr
  end
  return addr
end

local function workspace_id(window)
  local ws = window and window.workspace
  return ws and ws.id or nil
end

local function is_special_workspace(window)
  local ws = window and window.workspace
  local name = ws and ws.name
  return type(name) == "string" and name:sub(1, 8) == "special:"
end

local function should_shelf(win, focused_addr, focused_ws)
  if not win or win.mapped == false or win.hidden == true then
    return false
  end
  if not win.floating or win.pinned then
    return false
  end
  if window_address(win) == focused_addr then
    return false
  end
  if workspace_id(win) ~= focused_ws then
    return false
  end
  if is_special_workspace(win) then
    return false
  end
  return true
end

hl.on("window.active", function(window)
  if busy or not window or window.floating or is_special_workspace(window) then
    return
  end

  local focused_addr = window_address(window)
  local focused_ws = workspace_id(window)
  if not focused_addr or not focused_ws then
    return
  end

  local to_shelf = {}
  local list = hl.get_windows()
  for i = 1, #list do
    if should_shelf(list[i], focused_addr, focused_ws) then
      to_shelf[#to_shelf + 1] = list[i]
    end
  end
  if #to_shelf == 0 then
    return
  end

  busy = true
  for i = 1, #to_shelf do
    hl.dispatch(hl.dsp.window.move({
      workspace = MINIMIZE_WS,
      window = to_shelf[i],
      follow = false,
    }))
  end
  hl.timer(function()
    busy = false
  end, { timeout = 50, type = "oneshot" })
end)
