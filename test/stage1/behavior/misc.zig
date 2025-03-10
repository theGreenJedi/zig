const std = @import("std");
const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;
const mem = std.mem;
const builtin = @import("builtin");
const maxInt = std.math.maxInt;

// normal comment

/// this is a documentation comment
/// doc comment line 2
fn emptyFunctionWithComments() void {}

test "empty function with comments" {
    emptyFunctionWithComments();
}

comptime {
    @export("disabledExternFn", disabledExternFn, builtin.GlobalLinkage.Internal);
}

extern fn disabledExternFn() void {}

test "call disabled extern fn" {
    disabledExternFn();
}

test "@IntType builtin" {
    expect(@IntType(true, 8) == i8);
    expect(@IntType(true, 16) == i16);
    expect(@IntType(true, 32) == i32);
    expect(@IntType(true, 64) == i64);

    expect(@IntType(false, 8) == u8);
    expect(@IntType(false, 16) == u16);
    expect(@IntType(false, 32) == u32);
    expect(@IntType(false, 64) == u64);

    expect(i8.bit_count == 8);
    expect(i16.bit_count == 16);
    expect(i32.bit_count == 32);
    expect(i64.bit_count == 64);

    expect(i8.is_signed);
    expect(i16.is_signed);
    expect(i32.is_signed);
    expect(i64.is_signed);
    expect(isize.is_signed);

    expect(!u8.is_signed);
    expect(!u16.is_signed);
    expect(!u32.is_signed);
    expect(!u64.is_signed);
    expect(!usize.is_signed);
}

test "floating point primitive bit counts" {
    expect(f16.bit_count == 16);
    expect(f32.bit_count == 32);
    expect(f64.bit_count == 64);
}

test "short circuit" {
    testShortCircuit(false, true);
    comptime testShortCircuit(false, true);
}

fn testShortCircuit(f: bool, t: bool) void {
    var hit_1 = f;
    var hit_2 = f;
    var hit_3 = f;
    var hit_4 = f;

    if (t or x: {
        expect(f);
        break :x f;
    }) {
        hit_1 = t;
    }
    if (f or x: {
        hit_2 = t;
        break :x f;
    }) {
        expect(f);
    }

    if (t and x: {
        hit_3 = t;
        break :x f;
    }) {
        expect(f);
    }
    if (f and x: {
        expect(f);
        break :x f;
    }) {
        expect(f);
    } else {
        hit_4 = t;
    }
    expect(hit_1);
    expect(hit_2);
    expect(hit_3);
    expect(hit_4);
}

test "truncate" {
    expect(testTruncate(0x10fd) == 0xfd);
}
fn testTruncate(x: u32) u8 {
    return @truncate(u8, x);
}

fn first4KeysOfHomeRow() []const u8 {
    return "aoeu";
}

test "return string from function" {
    expect(mem.eql(u8, first4KeysOfHomeRow(), "aoeu"));
}

const g1: i32 = 1233 + 1;
var g2: i32 = 0;

test "global variables" {
    expect(g2 == 0);
    g2 = g1;
    expect(g2 == 1234);
}

test "memcpy and memset intrinsics" {
    var foo: [20]u8 = undefined;
    var bar: [20]u8 = undefined;

    @memset(foo[0..].ptr, 'A', foo.len);
    @memcpy(bar[0..].ptr, foo[0..].ptr, bar.len);

    if (bar[11] != 'A') unreachable;
}

test "builtin static eval" {
    const x: i32 = comptime x: {
        break :x 1 + 2 + 3;
    };
    expect(x == comptime 6);
}

test "slicing" {
    var array: [20]i32 = undefined;

    array[5] = 1234;

    var slice = array[5..10];

    if (slice.len != 5) unreachable;

    const ptr = &slice[0];
    if (ptr.* != 1234) unreachable;

    var slice_rest = array[10..];
    if (slice_rest.len != 10) unreachable;
}

test "constant equal function pointers" {
    const alias = emptyFn;
    expect(comptime x: {
        break :x emptyFn == alias;
    });
}

fn emptyFn() void {}

test "hex escape" {
    expect(mem.eql(u8, "\x68\x65\x6c\x6c\x6f", "hello"));
}

test "string concatenation" {
    expect(mem.eql(u8, "OK" ++ " IT " ++ "WORKED", "OK IT WORKED"));
}

test "array mult operator" {
    expect(mem.eql(u8, "ab" ** 5, "ababababab"));
}

test "string escapes" {
    expect(mem.eql(u8, "\"", "\x22"));
    expect(mem.eql(u8, "\'", "\x27"));
    expect(mem.eql(u8, "\n", "\x0a"));
    expect(mem.eql(u8, "\r", "\x0d"));
    expect(mem.eql(u8, "\t", "\x09"));
    expect(mem.eql(u8, "\\", "\x5c"));
    expect(mem.eql(u8, "\u1234\u0069", "\xe1\x88\xb4\x69"));
}

test "multiline string" {
    const s1 =
        \\one
        \\two)
        \\three
    ;
    const s2 = "one\ntwo)\nthree";
    expect(mem.eql(u8, s1, s2));
}

test "multiline C string" {
    const s1 =
        c\\one
        c\\two)
        c\\three
    ;
    const s2 = c"one\ntwo)\nthree";
    expect(std.cstr.cmp(s1, s2) == 0);
}

test "type equality" {
    expect(*const u8 != *u8);
}

const global_a: i32 = 1234;
const global_b: *const i32 = &global_a;
const global_c: *const f32 = @ptrCast(*const f32, global_b);
test "compile time global reinterpret" {
    const d = @ptrCast(*const i32, global_c);
    expect(d.* == 1234);
}

test "explicit cast maybe pointers" {
    const a: ?*i32 = undefined;
    const b: ?*f32 = @ptrCast(?*f32, a);
}

test "generic malloc free" {
    const a = memAlloc(u8, 10) catch unreachable;
    memFree(u8, a);
}
var some_mem: [100]u8 = undefined;
fn memAlloc(comptime T: type, n: usize) anyerror![]T {
    return @ptrCast([*]T, &some_mem[0])[0..n];
}
fn memFree(comptime T: type, memory: []T) void {}

test "cast undefined" {
    const array: [100]u8 = undefined;
    const slice = ([]const u8)(array);
    testCastUndefined(slice);
}
fn testCastUndefined(x: []const u8) void {}

test "cast small unsigned to larger signed" {
    expect(castSmallUnsignedToLargerSigned1(200) == i16(200));
    expect(castSmallUnsignedToLargerSigned2(9999) == i64(9999));
}
fn castSmallUnsignedToLargerSigned1(x: u8) i16 {
    return x;
}
fn castSmallUnsignedToLargerSigned2(x: u16) i64 {
    return x;
}

test "implicit cast after unreachable" {
    expect(outer() == 1234);
}
fn inner() i32 {
    return 1234;
}
fn outer() i64 {
    return inner();
}

test "pointer dereferencing" {
    var x = i32(3);
    const y = &x;

    y.* += 1;

    expect(x == 4);
    expect(y.* == 4);
}

test "call result of if else expression" {
    expect(mem.eql(u8, f2(true), "a"));
    expect(mem.eql(u8, f2(false), "b"));
}
fn f2(x: bool) []const u8 {
    return (if (x) fA else fB)();
}
fn fA() []const u8 {
    return "a";
}
fn fB() []const u8 {
    return "b";
}

test "const expression eval handling of variables" {
    var x = true;
    while (x) {
        x = false;
    }
}

test "constant enum initialization with differing sizes" {
    test3_1(test3_foo);
    test3_2(test3_bar);
}
const Test3Foo = union(enum) {
    One: void,
    Two: f32,
    Three: Test3Point,
};
const Test3Point = struct {
    x: i32,
    y: i32,
};
const test3_foo = Test3Foo{
    .Three = Test3Point{
        .x = 3,
        .y = 4,
    },
};
const test3_bar = Test3Foo{ .Two = 13 };
fn test3_1(f: Test3Foo) void {
    switch (f) {
        Test3Foo.Three => |pt| {
            expect(pt.x == 3);
            expect(pt.y == 4);
        },
        else => unreachable,
    }
}
fn test3_2(f: Test3Foo) void {
    switch (f) {
        Test3Foo.Two => |x| {
            expect(x == 13);
        },
        else => unreachable,
    }
}

test "character literals" {
    expect('\'' == single_quote);
}
const single_quote = '\'';

test "take address of parameter" {
    testTakeAddressOfParameter(12.34);
}
fn testTakeAddressOfParameter(f: f32) void {
    const f_ptr = &f;
    expect(f_ptr.* == 12.34);
}

test "pointer comparison" {
    const a = ([]const u8)("a");
    const b = &a;
    expect(ptrEql(b, b));
}
fn ptrEql(a: *const []const u8, b: *const []const u8) bool {
    return a == b;
}

test "C string concatenation" {
    const a = c"OK" ++ c" IT " ++ c"WORKED";
    const b = c"OK IT WORKED";

    const len = mem.len(u8, b);
    const len_with_null = len + 1;
    {
        var i: u32 = 0;
        while (i < len_with_null) : (i += 1) {
            expect(a[i] == b[i]);
        }
    }
    expect(a[len] == 0);
    expect(b[len] == 0);
}

test "cast slice to u8 slice" {
    expect(@sizeOf(i32) == 4);
    var big_thing_array = [_]i32{ 1, 2, 3, 4 };
    const big_thing_slice: []i32 = big_thing_array[0..];
    const bytes = @sliceToBytes(big_thing_slice);
    expect(bytes.len == 4 * 4);
    bytes[4] = 0;
    bytes[5] = 0;
    bytes[6] = 0;
    bytes[7] = 0;
    expect(big_thing_slice[1] == 0);
    const big_thing_again = @bytesToSlice(i32, bytes);
    expect(big_thing_again[2] == 3);
    big_thing_again[2] = -1;
    expect(bytes[8] == maxInt(u8));
    expect(bytes[9] == maxInt(u8));
    expect(bytes[10] == maxInt(u8));
    expect(bytes[11] == maxInt(u8));
}

test "pointer to void return type" {
    testPointerToVoidReturnType() catch unreachable;
}
fn testPointerToVoidReturnType() anyerror!void {
    const a = testPointerToVoidReturnType2();
    return a.*;
}
const test_pointer_to_void_return_type_x = void{};
fn testPointerToVoidReturnType2() *const void {
    return &test_pointer_to_void_return_type_x;
}

test "non const ptr to aliased type" {
    const int = i32;
    expect(?*int == ?*i32);
}

test "array 2D const double ptr" {
    const rect_2d_vertexes = [_][1]f32{
        [_]f32{1.0},
        [_]f32{2.0},
    };
    testArray2DConstDoublePtr(&rect_2d_vertexes[0][0]);
}

fn testArray2DConstDoublePtr(ptr: *const f32) void {
    const ptr2 = @ptrCast([*]const f32, ptr);
    expect(ptr2[0] == 1.0);
    expect(ptr2[1] == 2.0);
}

const Tid = builtin.TypeId;
const AStruct = struct {
    x: i32,
};
const AnEnum = enum {
    One,
    Two,
};
const AUnionEnum = union(enum) {
    One: i32,
    Two: void,
};
const AUnion = union {
    One: void,
    Two: void,
};

test "@typeId" {
    comptime {
        expect(@typeId(type) == Tid.Type);
        expect(@typeId(void) == Tid.Void);
        expect(@typeId(bool) == Tid.Bool);
        expect(@typeId(noreturn) == Tid.NoReturn);
        expect(@typeId(i8) == Tid.Int);
        expect(@typeId(u8) == Tid.Int);
        expect(@typeId(i64) == Tid.Int);
        expect(@typeId(u64) == Tid.Int);
        expect(@typeId(f32) == Tid.Float);
        expect(@typeId(f64) == Tid.Float);
        expect(@typeId(*f32) == Tid.Pointer);
        expect(@typeId([2]u8) == Tid.Array);
        expect(@typeId(AStruct) == Tid.Struct);
        expect(@typeId(@typeOf(1)) == Tid.ComptimeInt);
        expect(@typeId(@typeOf(1.0)) == Tid.ComptimeFloat);
        expect(@typeId(@typeOf(undefined)) == Tid.Undefined);
        expect(@typeId(@typeOf(null)) == Tid.Null);
        expect(@typeId(?i32) == Tid.Optional);
        expect(@typeId(anyerror!i32) == Tid.ErrorUnion);
        expect(@typeId(anyerror) == Tid.ErrorSet);
        expect(@typeId(AnEnum) == Tid.Enum);
        expect(@typeId(@typeOf(AUnionEnum.One)) == Tid.Enum);
        expect(@typeId(AUnionEnum) == Tid.Union);
        expect(@typeId(AUnion) == Tid.Union);
        expect(@typeId(fn () void) == Tid.Fn);
        expect(@typeId(@typeOf(builtin)) == Tid.Type);
        // TODO bound fn
        // TODO arg tuple
        // TODO opaque
    }
}

test "@typeName" {
    const Struct = struct {};
    const Union = union {
        unused: u8,
    };
    const Enum = enum {
        Unused,
    };
    comptime {
        expect(mem.eql(u8, @typeName(i64), "i64"));
        expect(mem.eql(u8, @typeName(*usize), "*usize"));
        // https://github.com/ziglang/zig/issues/675
        expectEqualSlices(u8, "behavior.misc.TypeFromFn(u8)", @typeName(TypeFromFn(u8)));
        expect(mem.eql(u8, @typeName(Struct), "Struct"));
        expect(mem.eql(u8, @typeName(Union), "Union"));
        expect(mem.eql(u8, @typeName(Enum), "Enum"));
    }
}

fn TypeFromFn(comptime T: type) type {
    return struct {};
}

test "double implicit cast in same expression" {
    var x = i32(u16(nine()));
    expect(x == 9);
}
fn nine() u8 {
    return 9;
}

test "global variable initialized to global variable array element" {
    expect(global_ptr == &gdt[0]);
}
const GDTEntry = struct {
    field: i32,
};
var gdt = [_]GDTEntry{
    GDTEntry{ .field = 1 },
    GDTEntry{ .field = 2 },
};
var global_ptr = &gdt[0];

// can't really run this test but we can make sure it has no compile error
// and generates code
const vram = @intToPtr([*]volatile u8, 0x20000000)[0..0x8000];
export fn writeToVRam() void {
    vram[0] = 'X';
}

const OpaqueA = @OpaqueType();
const OpaqueB = @OpaqueType();
test "@OpaqueType" {
    expect(*OpaqueA != *OpaqueB);
    expect(mem.eql(u8, @typeName(OpaqueA), "OpaqueA"));
    expect(mem.eql(u8, @typeName(OpaqueB), "OpaqueB"));
}

test "variable is allowed to be a pointer to an opaque type" {
    var x: i32 = 1234;
    _ = hereIsAnOpaqueType(@ptrCast(*OpaqueA, &x));
}
fn hereIsAnOpaqueType(ptr: *OpaqueA) *OpaqueA {
    var a = ptr;
    return a;
}

test "comptime if inside runtime while which unconditionally breaks" {
    testComptimeIfInsideRuntimeWhileWhichUnconditionallyBreaks(true);
    comptime testComptimeIfInsideRuntimeWhileWhichUnconditionallyBreaks(true);
}
fn testComptimeIfInsideRuntimeWhileWhichUnconditionallyBreaks(cond: bool) void {
    while (cond) {
        if (false) {}
        break;
    }
}

test "implicit comptime while" {
    while (false) {
        @compileError("bad");
    }
}

fn fnThatClosesOverLocalConst() type {
    const c = 1;
    return struct {
        fn g() i32 {
            return c;
        }
    };
}

test "function closes over local const" {
    const x = fnThatClosesOverLocalConst().g();
    expect(x == 1);
}

test "cold function" {
    thisIsAColdFn();
    comptime thisIsAColdFn();
}

fn thisIsAColdFn() void {
    @setCold(true);
}

const PackedStruct = packed struct {
    a: u8,
    b: u8,
};
const PackedUnion = packed union {
    a: u8,
    b: u32,
};
const PackedEnum = packed enum {
    A,
    B,
};

test "packed struct, enum, union parameters in extern function" {
    testPackedStuff(&(PackedStruct{
        .a = 1,
        .b = 2,
    }), &(PackedUnion{ .a = 1 }), PackedEnum.A);
}

export fn testPackedStuff(a: *const PackedStruct, b: *const PackedUnion, c: PackedEnum) void {}

test "slicing zero length array" {
    const s1 = ""[0..];
    const s2 = ([_]u32{})[0..];
    expect(s1.len == 0);
    expect(s2.len == 0);
    expect(mem.eql(u8, s1, ""));
    expect(mem.eql(u32, s2, [_]u32{}));
}

const addr1 = @ptrCast(*const u8, emptyFn);
test "comptime cast fn to ptr" {
    const addr2 = @ptrCast(*const u8, emptyFn);
    comptime expect(addr1 == addr2);
}

test "equality compare fn ptrs" {
    var a = emptyFn;
    expect(a == a);
}

test "self reference through fn ptr field" {
    const S = struct {
        const A = struct {
            f: fn (A) u8,
        };

        fn foo(a: A) u8 {
            return 12;
        }
    };
    var a: S.A = undefined;
    a.f = S.foo;
    expect(a.f(a) == 12);
}

test "volatile load and store" {
    var number: i32 = 1234;
    const ptr = (*volatile i32)(&number);
    ptr.* += 1;
    expect(ptr.* == 1235);
}

test "slice string literal has type []const u8" {
    comptime {
        expect(@typeOf("aoeu"[0..]) == []const u8);
        const array = [_]i32{ 1, 2, 3, 4 };
        expect(@typeOf(array[0..]) == []const i32);
    }
}

test "pointer child field" {
    expect((*u32).Child == u32);
}

test "struct inside function" {
    testStructInFn();
    comptime testStructInFn();
}

fn testStructInFn() void {
    const BlockKind = u32;

    const Block = struct {
        kind: BlockKind,
    };

    var block = Block{ .kind = 1234 };

    block.kind += 1;

    expect(block.kind == 1235);
}

test "fn call returning scalar optional in equality expression" {
    expect(getNull() == null);
}

fn getNull() ?*i32 {
    return null;
}

test "thread local variable" {
    const S = struct {
        threadlocal var t: i32 = 1234;
    };
    S.t += 1;
    expect(S.t == 1235);
}

test "unicode escape in character literal" {
    var a: u24 = '\U01f4a9';
    expect(a == 128169);
}

test "result location zero sized array inside struct field implicit cast to slice" {
    const E = struct {
        entries: []u32,
    };
    var foo = E{ .entries = [_]u32{} };
    expect(foo.entries.len == 0);
}
