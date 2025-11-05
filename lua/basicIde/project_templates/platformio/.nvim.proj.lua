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
}
