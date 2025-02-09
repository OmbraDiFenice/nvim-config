struct Struct {
	int a;
	float (*func_p)(int x, int y);
};

float func_p(int x, int y) {
	return x + y;
}

#define DEFINED_VAR 4

#define DEFINED_FUNC(x) { \
	x *= 4; \
  x += 3; \
}

double global_var = 50.2;

static const int static_var = 10;

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

int another_function() {
	return 9;
}

int a_func_declaration(float x);
