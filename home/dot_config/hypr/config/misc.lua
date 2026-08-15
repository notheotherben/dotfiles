hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        mfact = 0.76,
        focus_master_on_close = true
    },
    misc = {
        col = {
            splash = CACHYLGREEN,
        },
        middle_click_paste = false,
        enable_swallow = true,
        swallow_regex = "(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)",
        vrr = 2,
    },
    xwayland = {
        force_zero_scaling = true
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

-- Plugins are not persisted across restarts, so hyprpm has to reload them each session.
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload -n")
end)

-- Loading a plugin reparses the config, so this block only takes effect on that second pass.
if hl.plugin.hyprbars ~= nil then
    local maximize = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']]

    hl.config({
        plugin = {
            hyprbars = {
                enabled = false,
                bar_height = 24,
                bar_text_size = 10,
                bar_buttons_alignment = "left",
                bar_part_of_window = true,
                bar_precedence_over_border = true,
                icon_on_hover = true,
                on_double_click = maximize,
            },
        },
    })

    -- Rendered left to right in the order they are added, macOS style.
    local titlebarButtons = {
        { color = "rgb(ff5f57)", icon = "✕", action = [[hyprctl dispatch 'hl.dsp.window.close()']] },
        { color = "rgb(febc2e)", icon = "❐", action = [[hyprctl dispatch 'hl.dsp.window.float({ action = "toggle" })']] },
        { color = "rgb(28c840)", icon = "⤢", action = maximize },
    }
    for _, button in ipairs(titlebarButtons) do
        hl.plugin.hyprbars.add_button({
            bg_color = button.color,
            fg_color = "rgb(000000)",
            size = 11,
            icon = button.icon,
            action = button.action,
        })
    end
end
