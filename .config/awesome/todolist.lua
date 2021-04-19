local wibox = require("wibox")
local gtable = require("gears.table")
local awful = require("awful")
local beautiful = require("beautiful")
local naughty = require("naughty")
local button = require("button")
local ufont = require("font")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local io = {
  open = io.open,
  lines = io.lines
}

local todo_width =370
local todo_height = 250

-- Minimal TodoList
local todo_textbox = wibox.widget.textbox() -- to store the prompt
local history_file = os.getenv("HOME").."/.todoslist"
local todo_max = 4
local todo_list = wibox.layout.fixed.vertical()
local remove_todo

local w = wibox.widget {
    fg = "#ffffff",
    widget = wibox.container.background
}

local function update_history()
  local lines = {}
  -- ensure the file exist
  local history = io.open(history_file, "r")
  if history == nil then return end
  history:close()

  todo_list:reset()
  for line in io.lines(history_file) do
    table.insert(lines, line)
  end

  for k,v in pairs(lines) do
    if k > todo_max or not v then return end
    local f = function() remove_todo(v) end -- serve to store the actual line
    local b = wibox.widget {
    {
      {
        {
          ufont.button(""),
          {
            ufont.body_2(v),
            widget = wibox.container.margin,
          },
          spacing = dpi(8),
          layout = wibox.layout.fixed.horizontal,
        },
        widget = w,
      },
      widget = wibox.container.background
    },
    widget = wibox.container.background,
  }
b:buttons(awful.util.table.join(
  awful.button({ }, 1, function() f() end)
))
todo_list:add(b)
end

for i=1, #lines do
	naughty.notify{ title = "test", text = lines[i] }
end
end

remove_todo = function(line)
  local line = string.gsub(line, "/", "\\/") -- if contain slash
  local command = "sh -c '[ -f "..history_file.." ] && sed -i \"/"..line.."/d\" "..history_file.."'"
  awful.spawn.easy_async_with_shell(command, function()
    update_history()
  end)
end

local function exec_prompt()
  awful.prompt.run {
    prompt = " > ",
    fg = "#ffffff", 
    font = "DejaVu Sans 10",
    history_path = history_file,
    textbox = todo_textbox,
    exe_callback = function(input)
      if not input or #input == 0 then return end
      update_history()
    end
  }
end

local todo_new = wibox.widget {
    image  = beautiful.awesome_icon,
    resize = false,
    widget = wibox.widget.imagebox
}
todo_new:buttons(awful.util.table.join(
  awful.button({ }, 1, function() exec_prompt() end)
))
local todo_widget = wibox.widget {
  {
    {
      todo_list,
      left = 20,
      right = 20,
      top = 14,
      widget = wibox.container.margin
    },
    nil,
    {
      todo_textbox,
      {
        todo_new,
        bottom = 12,
        widget = wibox.container.margin
      },
      layout = wibox.layout.fixed.vertical
    },
    spacing = dpi(10),
    expand = "none",
    layout = wibox.layout.align.vertical
  },
  bg = '#555555',
  forced_height = todo_height - 20,
  forced_width = todo_width - 20,
  widget = wibox.container.background
}

local td = wibox({visible=false, ontop = true, type = "normal", height=400,width=400})

td:setup {
todo_widget,
layout = wibox.layout.manual
}

function todo_show()
td.visible = not td.visible
update_history() -- init once the todo
end
