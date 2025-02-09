local utils = require('basicIde.utils')
local smart_code_layout = require('basicIde.code_layout.smart_code_layout')
local default_settings = require('basicIde.project').default_settings

describe("Smart code layout", function ()
	local function check_layout_nodes(test_file, language, expected_nodes_text)
		local test_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_call(test_buf, function() vim.cmd.edit(test_file) end)

		local actual_nodes = smart_code_layout._parse_buffer(
			vim.treesitter.get_parser(test_buf):parse()[1],
			default_settings.code_layout.languages[language].queries,
			language,
			test_buf
		)

		local actual_nodes_text = smart_code_layout._populate_code_layout_buffer(
			actual_nodes,
			default_settings.code_layout.languages[language].node_types,
			default_settings.code_layout.indent_width
		)

		assert.are.equal(#expected_nodes_text, #actual_nodes)
		for i, actual_node in ipairs(actual_nodes) do
			assert.are.equal(utils.paths.trim(expected_nodes_text[i]), actual_node.formatted_text)
			assert.are.equal(expected_nodes_text[i], actual_nodes_text[i])
		end
	end

	it("extract right nodes for C++", function()
		local expected_nodes_text = {
			"template<typename T> struct TemplateStruct;",
			"  int a;",
			"  float b;",
			"struct Struct;",
			"  int a;",
			"  float b;",
			"template<typename T> void template_func_definition(T& t);",
			"template<> void template_func_definition<int>(int& x);",
			"template<typename T> void template_func_declaration(T x);",
			"int global_var;",
			"template<int X> int template_global_var;",
			"template<> int template_global_var<0>;",
			"#define DEFINED_VAR",
			"#define DEFINED_FUNC(x)",
			"namespace some_namespace;",
			"  double namespace_var;",
			"  template<typename T> class TemplateClass;",
			"    int x;",
			"    int y;",
			"    TemplateClass(int x);",
			"    TemplateClass(Struct s);",
			"    TemplateClass(const TemplateClass& c);",
			"    ~TemplateClass();",
			"    int get_x() const;",
			"    int get_y() const;",
			"    void a_private_method();",
			"    bool a_private_method_defined(int x);",
			"    void a_protected_method();",
			"    bool a_protected_method_defined(int x);",
			"    int explicitly_private_var;",
			"    int explicitly_private_var_defined;",
			"  namespace nested_namespace;",
			"    class Class: public TemplateClass<int>;",
			"      int get_x() const override;",
			"      int another_method();",
			"    enum Enum;",
			"    typedef int Typedef;",
			"    typedef enum EnumTypedef;",
			"    typedef struct StructTypedef;",
			"      int a;",
			"  template<typename T> void TemplateClass<T>::a_private_method();",
			"  template<typename T> int TemplateClass<T>::explicitly_private_var;",
			"  int nested_namespace::Class::another_method();",
		}

		check_layout_nodes("lua/basicIde/code_layout/tests/fixtures/test.cpp", "cpp", expected_nodes_text)
	end)

	it("extract right nodes for C", function()
		local expected_nodes_text = {
			"struct Struct;",
			"  int a;",
			"  float (*func_p)(int x, int y);",
			"float func_p(int x, int y);",
			"#define DEFINED_VAR",
			"#define DEFINED_FUNC(x)",
			"double global_var;",
			"int static_var;",
			"enum Enum;",
			"typedef int Typedef;",
			"typedef enum EnumTypedef;",
			"typedef struct StructTypedef;",
			"  int a;",
			"int another_function();",
			"int a_func_declaration(float x);",
		}

		check_layout_nodes("lua/basicIde/code_layout/tests/fixtures/test.c", "c", expected_nodes_text)
	end)

	it("extract right nodes for lua", function()
		local expected_nodes_text = {
			"F()",
			"  internal()",
			"    local_func()",
			"G(par)",
			"some_local(param1, param2)",
			"object",
			"  member",
			"  inline_function(x)",
			"    inner_inner_func()",
			"object.new(param1, param2)",
			"object:method()",
			"object.method2(self, param)",
			"Global_var",
		}

		check_layout_nodes("lua/basicIde/code_layout/tests/fixtures/test.lua", "lua", expected_nodes_text)
	end)

	it("extract right nodes for python", function()
		local expected_nodes_text = {
			"global_var: str",
			"untyped_var",
			"def global_func(x):",
			"  def inner_func(y, z):",
			"class SomeClass:",
			"  def __init__(self, param):",
			"  def method(self) -> int:",
			"  def method2(self, param: bool) -> None:",
			"    def inner_method2():",
			"class AnotherClass:",
			"class Subclass(SomeClass):",
			"class MultiParentClass(SomeClass, AnotherClass):",
		}

		check_layout_nodes("lua/basicIde/code_layout/tests/fixtures/test.py", "python", expected_nodes_text)
	end)
end)
