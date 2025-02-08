template<typename T>
struct TemplateStruct {
	int a;
	float b = 0;
};

struct Struct {
	int a;
	float b = 0;
};

template<typename T>
void template_func_definition(T& t) {
	int x;
}

template<>
void template_func_definition<int>(int& x) {}

template<typename T>
void template_func_declaration(T x);

int global_var;

template<int X>
int template_global_var;

template<>
int template_global_var<0> = 0;

#define DEFINED_VAR 4

#define DEFINED_FUNC(x) { \
	x *= 4; \
  x += 3; \
}

namespace some_namespace {
	double namespace_var = 50.2;

	template<typename T>
	class TemplateClass {
		int x;
		int y = 5;

		public:
			TemplateClass(int x) : x(x) {}
			TemplateClass(Struct s);
			TemplateClass(const TemplateClass& c) = delete;
			~TemplateClass();

			virtual int get_x() const { return x; }
			int get_y() const;

		private:
			void a_private_method();
			bool a_private_method_defined(int x) { return x; }

		protected:
			void a_protected_method();
			bool a_protected_method_defined(int x) { return x; }

		private:
			static int explicitly_private_var;
			int explicitly_private_var_defined = 3;
	};

	namespace nested_namespace {
		class Class : public TemplateClass<int> {
			public:
				int get_x() const override { return TemplateClass<int>::get_x() * 2; }
				int another_method();
		};

		enum Enum {
			VALUE
		};

		typedef int Typedef;
		typedef enum {
			SOMETHING,
		} EnumTypedef;

		typedef struct {
			int a;
		} StructTypedef;
	}

	template<typename T>
	void TemplateClass<T>::a_private_method() {
		int local_variable = 5;
	}

	template<typename T>
	int TemplateClass<T>::explicitly_private_var = 4;

	int nested_namespace::Class::another_method() {
		return 9;
	}
}
