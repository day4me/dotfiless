local wibox = require("wibox")
local helper = require("helper")

local root_bg = {}

function root_bg:init(args)
  self.color = args.color or M.x.on_surface
  self.shape = args.shape or helper.rrect(10)
  self.w = wibox.widget {
    bg = self.color .. "00",
    shape = self.shape,
    widget = wibox.container.background
  }
end

-- opacity state
-- https://material.io/design/color/dark-theme.html#states
function root_bg:signals()
  self.w:connect_signal("mouse::enter", function()
    self.w.bg = self.color .. "0A" -- 4%
  end)
  self.w:connect_signal("mouse::leave", function()
    self.w.bg = self.color .. "00"
  end)
  self.w:connect_signal("button::press", function()
    self.w.bg = self.color .. "1F" -- 12%
  end)
  self.w:connect_signal("button::release", function()
    self.w.bg = self.color .. "00"
  end)
end

return root_bg
