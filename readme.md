# Valkyrie

## Syntax
### Comments
```c
// single line comment
/* multiline comment */
```

### Numbers
```c
// integers
1
1_000
0x1
0b1
// floats
1.0
1f
1_000.0
1e4
1.5e3
```

### Strings
```c
"string"
```

### Constants (boolean + null)
```js
true
false
null
```

### Symbols
```c
// literal
:sym
// as map key
sym: value
// interpolated
:(some_var)
(some_var): value
```

### Vectors
```js
[1,2,3]
[1..3] // [1, 2, 3]
[1...3] // [1, 2]
```

### Maps
```js
{a: 1, b: 2}
// interpolated
x = "a"
{(a): 1, b: 2} // {a: 1, b: 2}
```

### Regex
```js
/pattern/
```

### Identifiers
```js
CONSTANT

variable
two_words
structMember

DataType
```

### Unary operators
```c
!true // false

// abs/negation
x = 1
+x // 1
-x // -1

// post-inc/dec
x = 3
x++ // 3
x // 4
x-- // 4
x // 3

// pre-inc/dec
x = 5
++x // 6
--x // 5
```

### Binary operators
```js
null && 3 // false
10 && 6 // 6
null || 7 // 7

1 == 1 // true
6 != 3 // true

4 < 8 // true
6 <= 7 // true
3 > 1 // true
9 >= 9 // true

10 & 3 // 2
7 | 4 // 7
6 ^ 2 // 4
1 << 4 // 16
0xff >> 6 // 3
```

### Assignment
```js
x = 2 // 2
y ||= 5 // 5
y = 1;y ||= 5 // 1
z &&= 3 // null
z = 2;z &&= 3 // 3

a, b = 1, 2 // [1, 2]
a, b, c = *[1..3] // [1, 2, 3]
a, _, b = [1..3] // [1, 3]
a, *b = [1..3] // [1, 2, 3]; a = 1, b = [2, 3]
a, b = [1..3] // [1, 2]
*a, b = [1..3] // [1, 2, 3]; a = [1, 2], b = 3
```

### Pattern matching
```js
"test" =~ /t/ // true
"test" =~ /(t)/ // ["t", "t"]
["hi", "hello"] =~ /([aeiou])/ // [["i"], ["e", "o"]]
{a: "hi", b: "hello"} =~ /([aeiou])/ // {a: ["i"], b: ["e", "o"]}
{a: 1, b: 2, c: 3} =~ [:a, :c] // [1, 3]
// everything else falls back to equality
```

### Conditionals & loops
```js
if false { 1 } else if null { 2 } else { 3 } // 3
1 if false else 2 // 2
if false do 1 else 2 // 2

for i = 0;i < 4;i++ { i } // [0, 1, 2, 3]
for i = 0;i < 4;i++ do i // [0, 1, 2, 3]

foreach i =~ [0..3] { i * i } // [0, 1, 4, 9]
foreach i =~ [0..3] do i * i // [0, 1, 4, 9]
i*i foreach i =~ [0..3] // [0, 1, 4, 9]

i = 0;while i < 4 { i++ } // [0, 1, 2, 3]
i = 0;i++ while i < 4 // [0, 1, 2, 3]

/* control statements */
return
return a, b

break
break a, b

yield
yield a, b

next
next a, b
```

### Functions
```go
// no args
fn test{
	10 // implicitly returns last line
}
test() == 10 // true

// return type hint (null negates implicit return)
fn test : Null{
	10 // is not returned
}
test() // null

// unnamed arg
fn square(n){
	n * n
}
square(4) // 16

// argument default
fn square(n = 0){
	n * n
}
square() // 0

// argument type hint + default
fn square(n : Int=0) : Int{
	n * n
}
square(5) // 25

// named arg
fn recip(:n) : Float{
	1 / n
}
recip(n: 4) // 0.25

// named arg + type hint + default
fn recip(n: 1 : Int) : Float{
	1 / n
}
recip() // 1.0

// variadic args (collected as vector)
fn sum(*i : Float=[]) : Float{
	t=0
	t+=n foreach n =~ i
	t
}
sum(1,3,5) // 9

// keyword args (collected as map)
fn vowels(**kws){
	kws =~ [:a, :e, :i, :o, :u]
}
vowels(a: 1,c: 2,e: 3) // {a: 1, e: 3}

// anonymous functions
fn(:x : Int){
	x * 2
}(x: 3) // 6
```

### Types & structs
```go
// type alias
type Weight Float

// anonymous struct
struct {
	x : Int
}

// struct type
type Point struct {
	x, y : Int
}

// static type method
fn Point#new(x : Int, y : Int){
	Point { x, y }
}

// instance method
fn Point::move(x : Int, y : Int){
	self->x += x
	self->y += y
	self
}
```

### Namespaces
```cpp
// definition
namespace Stuff{
	fn test{
		3.14
	}
}

// usage
Stuff::test() // 3.14
```

### Exception handling
```js
try{
	// something that causes an error
}rescue e : TypeError{
	// catch TypeError exceptions
}rescue RangeError{
	// catch RangeError exceptions
}rescue{
	// catch other exceptions
}ensure{
	// do something after either block (optional)
}
```

### Code loading & pragmas
```c
// require files in top-level namespace
require "file1", "file2"

// require file to namespace "name"
require name: "file"

// use pragma "pragma"
use "pragma"
```
