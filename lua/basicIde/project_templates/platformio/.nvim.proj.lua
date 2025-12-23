---@diagnostic disable: unused-local, missing-fields
---@type ProjectSettings
return {
	project_languages = {"c", "cpp"},
	loader = {
		virtual_environment = "${env:HOME}/.platformio/penv",
		environment = {
			PATH = "${env:HOME}/.platformio/penv/bin:${env:PATH}",
			COMPILATIONDB_INCLUDE_TOOLCHAIN = "True", -- generate compile_commands.json with pio run --target compiledb
		},
	},
	debugging = {
		external_scripts = {
			{
				keymap = "<F9>",
				name = "PlatformIO compile",
				command = { "pio" },
				args = { "run" },
				open_console_on_start = true,
			},
			{
				keymap = "<S-F9>",
				name = "PlatformIO compile and upload",
				command = { "pio" },
				args = { "run", "--target", "upload" },
				open_console_on_start = true,
			},
			{
				keymap = "<F10>",
				name = "PlatformIO serial monitor",
				command = { "pio" },
				args = { "device", "monitor" },
				open_console_on_start = true,
			},
			{
				keymap = "<F8>",
				name = "PlatformIO compiledb",
				command = { "pio" },
				args = { "run", "--target", "compiledb" },
			},
		},
	},
}
