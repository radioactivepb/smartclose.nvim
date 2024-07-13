# 🤏 SmartClose.nvim
A Neovim plugin to smartly close things!
Terminals, buffers, windows, tabs, floating windows, even Neovim itself!

- [Features](#features)
 
- [Installation](#installation)

- [Options](#options)

- [Functions](#functions)

## Features
+ Ignore certain buftypes and/or filetypes
+ Close all of a particular buftype and/or filetype all at once
+ Close all floating windows in one fell swoop
+ Close terminals with ease
+ Close anything and everything with just one keybind!

## Installation
Minimal Lazy.nvim example (no keybinds, up to you to call the functions by hand)
```lua
{
    "radioactivepb/smartclose.nvim"
}
```
Lazy.nvim example with default opts (uses default keybinds, see [Options](#options) for details)
```lua
{
    "radioactivepb/smartclose.nvim",
    opts = {}
}
```
## Options
Many options are available for easy keybindings and close actions
```lua
{
    "radioactivepb/smartclose.nvim",
    -- All displayed options are the defaults
    -- Anything commented out is not default, rather an example
    opts = {
        -- By default, any keybinds you do not pass to opts.keybinds will be instantiated
        -- using their default keys (below) unless disable_default_keybinds is set to true
        disable_default_keybinds = false,
        -- All the keybinds displayed below are the default keybinds
        keybinds = {
            -- smart close
            smartclose = "<leader>k",
            -- smart close!
            smartclose_force = "<leader>K",
        },
        -- How should smart close work for you?
        actions = {
            -- Want smart close to close all of something, all at once? Put it here!
			close_all = {
				windows = {
					filetypes = {
                        -- List any and all filetypes here
                        -- "lua",
                        -- "markdown"
                    },
					buftypes = {
                        -- List any and all buftypes here
                        -- "terminal"
                    },
                    -- Close all floating windows when smart closing?
					floating = true,
				},
				buffers = {
					filetypes = {
                        -- List any and all filetypes here
                        -- "lua",
                    },
					buftypes = {
                        -- List any and all buftypes here
                        -- "terminal"
                    },
                    -- Close all empty buffers when smart closing?
					empty = true,
				},
			},
            -- Want smart close to ignore something? Put it here!
			ignore_all = {
				windows = {
					filetypes = {
                        -- List any and all filetypes here
                        -- "lua",
                        -- "markdown"
                    },
					buftypes = {
                        -- List any and all buftypes here
                        -- "terminal"
                    },
				},
				buffers = {
					filetypes = {
                        -- List any and all filetypes here
                        -- "lua",
                        -- "markdown"
                    },
					buftypes = {
                        -- List any and all buftypes here
                        -- "terminal"
                    },
                },
            },
        },
    }
}
```

## Functions
```lua
-- Smart close anything
require("smartclose").smartclose()
-- Force smart close anything
require("smartclose").smartclose_force()
```
