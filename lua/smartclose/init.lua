local M = {}

local smartclose = require("smartclose.smartclose")

M.setup = function(opts)
	local default_options = {
		disable_default_keybinds = false,
		keybinds = {
			smartclose = "<leader>k",
			smartclose_force = "<leader>K",
		},
		actions = {
			close_all = {
				filetypes = {},
				buftypes = {},
				floating = true,
				empty = true,
			},
			ignore_all = {
				filetypes = {},
				buftypes = {},
			},
		},
	}

	if opts.disable_default_keybinds then
		default_options.keybinds = {}
	end

	opts = vim.tbl_deep_extend("force", default_options, opts)

	M.smartclose = function()
		smartclose.smartclose(false, opts.actions)
	end

	M.smartclose_force = function()
		smartclose.smartclose(true, opts.actions)
	end

	local mode = "n"
	local keymap_opts = { noremap = true, silent = true }

	for f, keybind in pairs(opts.keybinds) do
		local func = M[tostring(f)]
		if func ~= nil then
			vim.keymap.set(mode, keybind, func, keymap_opts)
		end
	end
end

return M
