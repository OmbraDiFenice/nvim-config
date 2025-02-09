global_var: str = "global var"
untyped_var = True

def global_func(x):
    x = 3
    print("global func")

    def inner_func(y, z):
        pass

class SomeClass:
    def __init__(self, param):
        self.param = param

    def method(self) -> int:
        global some_global
        retun 0

    def method2(self, param: bool) -> None:
        def inner_method2():
            inner_local_var = True
            pass

        local_var = "local var"

class AnotherClass:
    class_var = 4

class Subclass(SomeClass):
    pass

class MultiParentClass(SomeClass, AnotherClass):
    pass
