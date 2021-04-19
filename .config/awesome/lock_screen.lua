-- Disclaimer:
-- This lock screen was not designed with security in mind. There is
-- no guarantee that it will protect you against someone that wants to
-- gain access to your computer.
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local helpers = require("helpers")


local lock_screen_symbol = "" 
local lock_screen_fail_symbol = ""
local lock_screen_custom_password = "fifa11cool"
local lock_animation_icon = wibox.widget {
    -- Set forced size to prevent flickering when the icon rotates
    forced_height = dpi(80),
    forced_width = dpi(80),
    font = "icomoon 40",
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox(lock_screen_symbol)
}

-- A dummy textbox needed to get user input.
-- It will not be visible anywhere.
local some_textbox = wibox.widget.textbox()

-- Create the lock screen wibox
-- Set the type to "splash" and set all "splash" windows to be blurred in your
-- compositor configuration file
lock_screen_box = wibox({visible = false, ontop = true, type = "splash", screen = screen.primary})
awful.placement.maximize(lock_screen_box)

lock_screen_box.bg = beautiful.lock_screen_bg or beautiful.exit_screen_bg or beautiful.wibar_bg or "#111111"
lock_screen_box.fg = beautiful.lock_screen_fg or beautiful.exit_screen_fg or beautiful.wibar_fg or "#FEFEFE"

-- Add lockscreen to each screen
awful.screen.connect_for_each_screen(function(s)
    if s == screen.primary then
        s.mylockscreen = lock_screen_box
    else
        s.mylockscreen = helpers.screen_mask(s, beautiful.lock_screen_bg or beautiful.exit_screen_bg or x.background)
    end
end)

local function set_visibility(v)
    for s in screen do
        s.mylockscreen.visible = v
    end
end

-- Items
local day_of_the_week = wibox.widget {
    -- Fancy font
    font = "DejaVu Sans Bold 80",
    -- font = "Space Craft 50",
    -- font = "Razed Galerie 70",
    -- font = "A-15-BIT 70",
    -- font = "Kill The Noise 90",
    -- Set forced width in order to keep it from getting cut off
    forced_width = dpi(1000),
    align = "center",
    valign = "center",
    widget = wibox.widget.textclock("%A")
}

local month = wibox.widget {
    font = "DejaVu Sans Book 100",
    align = "center",
    valign = "center",
    widget = wibox.widget.textclock("%B %d")
}

--widgets locations
--month.point = {x=200,y=100}
--day_of_the_week.point = {x=200,y=200}

local function update_month()
    month.markup = month.text:upper()
end

update_month()
month:connect_signal("widget::redraw_needed", function ()
    update_month()
end)


-- Month + Day of the week stacked on top of each other
local fancy_date = wibox.widget {
    month,
    day_of_the_week,
    -- Set forced width in order to keep it from getting cut off
    forced_width = dpi(1000),
    layout = wibox.layout.stack
}

local time = {
        {
            font = "DejaVu Sans bold 30",
            widget = wibox.widget.textclock("%H:")
        },
        {
            font = "DejaVu Sans bold 30",
            widget = wibox.widget.textclock("%M")
        },
        spacing = dpi(2),
        layout = wibox.layout.fixed.horizontal
}

-- Lock animation
local lock_animation_widget_rotate = wibox.container.rotate()

local arc = function()
    return function(cr, width, height)
        gears.shape.arc(cr, width, height, dpi(5), 0, math.pi/2, true, true)
    end
end

local full_arc = function()
    return function(cr, width, height)
        gears.shape.arc(cr, width, height, dpi(5), 0, math.pi*2+0.1, true, true)
    end
end

local lock_animation_arc = wibox.widget {
    shape = arc(),
    bg = "#00000000",
    forced_width = dpi(100),
    forced_height = dpi(100),
    widget = wibox.container.background
}

local lock_animation_widget = {
  {
    lock_animation_icon,
    widget = lock_animation_arc
  },
  widget = lock_animation_widget_rotate
}

-- Lock helper functions
local characters_entered = 0
local function reset()
    characters_entered = 0;
    lock_animation_icon.text = lock_screen_symbol
    lock_animation_widget_rotate.direction = "north"
    lock_animation_arc.bg = "#00000000"
end

local function fail()
    characters_entered = 0;
    lock_animation_icon.text = lock_screen_fail_symbol
    lock_animation_widget_rotate.direction = "north"
    lock_animation_arc.bg = "#C51C1C"
    lock_animation_arc.shape = full_arc()
end

local function auth(pass)
    return pass == lock_screen_custom_password
end

local animation_colors = {
    -- Rainbow sequence =)
    "#F37F97",
    "#C574DD",
    "#8897F4",
    "#79E6F3",
    "#5ADECD",
    "#F2A272",
}

local animation_directions = {"north", "west", "south", "east"}

-- Function that "animates" every key press
local function key_animation(char_inserted)
    local color
    local direction = animation_directions[(characters_entered % 4) + 1]
    if char_inserted then
        color = animation_colors[(characters_entered % 6) + 1]
        lock_animation_icon.text = lock_screen_symbol
	--naughty.notify{ title = "keyanima", text = "test"}
    else
        if characters_entered == 0 then
            reset()
        else
            color = "#FDFDFD55"
        end
    end
    
    lock_animation_arc.shape = arc()
    lock_animation_arc.bg = color
    lock_animation_widget_rotate.direction = direction
end

-- Get input from user
local function grab_password()
    awful.prompt.run {
        hooks = {
            -- Custom escape behaviour: Do not cancel input with Escape
            -- Instead, this will just clear any input received so far.
            {{ }, 'Escape',
                function(_)
                    reset()
                    grab_password()
                end
            },
            -- Fix for Control+Delete crashing the keygrabber
            {{ 'Control' }, 'r', function ()
                reset()
                grab_password()
            end},
	    {{ 'Control', 'Mod1' }, 'r', function ()
                reset()
                grab_password()
            end},
	    {{ 'Control', 'Mod4' }, 'r', function ()
                reset()
                grab_password()
            end},
	    {{ 'Control', 'Shift' }, 'r', function ()
                reset()
                grab_password()
            end}
        },
        keypressed_callback  = function(mod, key, cmd)
            -- Only count single character keys (thus preventing
            -- "Shift", "Escape", etc from triggering the animation)
            if #key == 1 then
                characters_entered = characters_entered + 1
                key_animation(true)
            elseif key == "BackSpace" then
                if characters_entered > 0 then
                    characters_entered = characters_entered - 1
                end
                key_animation(false)
	    elseif key == "XF86AudioMute" then
		awful.spawn.with_shell("pactl set-sink-mute 0 toggle")
	    elseif key == "XF86AudioRaiseVolume" then
		awful.spawn.with_shell("pactl set-sink-mute 0 0 && pactl set-sink-volume 0 +5%")
	    elseif key == "XF86AudioLowerVolume" then
		awful.spawn.with_shell("pactl set-sink-mute 0 0 && pactl set-sink-volume 0 -5%")
		--naughty.notify{title = 'You pressed:', text = key}
            end

            -- Debug
            --naughty.notify { title = 'You pressed:', text = key }
        end,
        exe_callback = function(input)
            -- Check input
            if auth(input) then
                -- YAY
                reset()
                set_visibility(false)
            else
                -- NAY
                fail()
                grab_password()
            end
        end,
        textbox = some_textbox,
    }
end

function lock_show()
    set_visibility(true) 
    grab_password()
end

--test
--
--

--lock_screen_box:setup {
--  -- Horizontal centering
--  nil,
--  lock_animation_widget,
--  expand = "none",
--  layout = wibox.layout.align.horizontal
--}


-- Item placement
lock_screen_box:setup {
    -- Horizontal centering
    nil,
    {
        -- Vertical centering
        nil,
        {
            {
                {
                    {
                        month,
                        day_of_the_week,
                        layout = wibox.layout.align.vertical
                    },
                    {
                        nil,
                        {
                            -- Small circle
                            {
                                forced_height = dpi(5),
                                forced_width = dpi(5),
                                shape = gears.shape.circle,
                                bg = "#F2A272",
                                widget = wibox.container.background
                            },
                            time,
                            -- Small circle
                            {
                                forced_height = dpi(5),
                                forced_width = dpi(5),
                                shape = gears.shape.circle,
                                bg = "#F2A272",
                                widget = wibox.container.background
                            },
                            spacing = dpi(4),
                            layout = wibox.layout.fixed.horizontal
                        },
                        expand = "none",
                        layout = wibox.layout.align.horizontal
                    },
                    spacing = dpi(20),
                    -- spacing = dpi(10),
                    layout = wibox.layout.fixed.vertical
                },
                lock_animation_widget,
                spacing = dpi(40),
                layout = wibox.layout.fixed.vertical

            },
            bottom = dpi(60),
            widget = wibox.container.margin
        },
        expand = "none",
        layout = wibox.layout.align.vertical
    },
    expand = "none",
    layout = wibox.layout.align.horizontal
}
