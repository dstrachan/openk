const value_mod = @import("../../value.zig");
const Value = value_mod.Value;

const vm_mod = @import("../vm.zig");
const runTest = vm_mod.runTest;

test "match boolean" {
    try runTest("1b~0b", .{ .boolean = false });
    try runTest("1b~`boolean$()", .{ .boolean = false });
    try runTest("1b~00000b", .{ .boolean = false });

    try runTest("1~0b", .{ .boolean = false });
    try runTest("1~`boolean$()", .{ .boolean = false });
    try runTest("1~00000b", .{ .boolean = false });

    try runTest("1f~0b", .{ .boolean = false });
    try runTest("1f~`boolean$()", .{ .boolean = false });
    try runTest("1f~00000b", .{ .boolean = false });

    try runTest("\"a\"~0b", .{ .boolean = false });
    try runTest("\"a\"~`boolean$()", .{ .boolean = false });
    try runTest("\"a\"~00000b", .{ .boolean = false });

    try runTest("`symbol~0b", .{ .boolean = false });
    try runTest("`symbol~`boolean$()", .{ .boolean = false });
    try runTest("`symbol~00000b", .{ .boolean = false });

    try runTest("()~0b", .{ .boolean = false });
    try runTest("(1b;2)~0b", .{ .boolean = false });
    try runTest("(1b;2;3f)~0b", .{ .boolean = false });
    try runTest("(1b;2;3f;(0b;1))~0b", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0b", .{ .boolean = false });
    try runTest("()~`boolean$()", .{ .boolean = false });
    try runTest("()~010b", .{ .boolean = false });
    try runTest("(1b;2)~`boolean$()", .{ .boolean = false });
    try runTest("(1b;2)~01b", .{ .boolean = false });
    try runTest("(1b;2;3f)~010b", .{ .boolean = false });
    try runTest("(1b;2;3f)~0101b", .{ .boolean = false });
    try runTest("(1b;2;3f;\"a\")~0101b", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0101b", .{ .boolean = false });

    try runTest("(`boolean$())~0b", .{ .boolean = false });
    try runTest("11111b~0b", .{ .boolean = false });
    try runTest("(`boolean$())~`boolean$()", .{ .boolean = true });
    try runTest("11111b~`boolean$()", .{ .boolean = false });
    try runTest("11111b~00000b", .{ .boolean = false });
    try runTest("11111b~000000b", .{ .boolean = false });

    try runTest("(`int$())~0b", .{ .boolean = false });
    try runTest("5 4 3 2 1~0b", .{ .boolean = false });
    try runTest("(`int$())~`boolean$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~`boolean$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~00000b", .{ .boolean = false });
    try runTest("5 4 3 2 1~000000b", .{ .boolean = false });

    try runTest("(`float$())~0b", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0b", .{ .boolean = false });
    try runTest("(`float$())~`boolean$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~`boolean$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~00000b", .{ .boolean = false });
    try runTest("5 4 3 2 1f~000000b", .{ .boolean = false });

    try runTest("\"\"~0b", .{ .boolean = false });
    try runTest("\"abcde\"~0b", .{ .boolean = false });
    try runTest("\"\"~`boolean$()", .{ .boolean = false });
    try runTest("\"abcde\"~`boolean$()", .{ .boolean = false });
    try runTest("\"abcde\"~00000b", .{ .boolean = false });
    try runTest("\"abcde\"~000000b", .{ .boolean = false });

    try runTest("(`$())~0b", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0b", .{ .boolean = false });
    try runTest("(`$())~`boolean$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~`boolean$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~00000b", .{ .boolean = false });
    try runTest("`a`b`c`d`e~000000b", .{ .boolean = false });

    try runTest("(()!())~0b", .{ .boolean = false });
    try runTest("(()!())~`boolean$()", .{ .boolean = false });
    try runTest("(()!())~01b", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0b", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`boolean$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~01b", .{ .boolean = false });
    try runTest("(`a`b!1 2)~010b", .{ .boolean = false });

    try runTest("(+`a`b!())~0b", .{ .boolean = false });
    try runTest("(+`a`b!())~`boolean$()", .{ .boolean = false });
    try runTest("(+`a`b!())~010b", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~0b", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~`boolean$()", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~010b", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0b", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,`symbol))~0b", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~`boolean$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~01b", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~010b", .{ .boolean = false });
}

test "match int" {
    try runTest("1b~0", .{ .boolean = false });
    try runTest("1b~`int$()", .{ .boolean = false });
    try runTest("1b~0 1 2 3 4", .{ .boolean = false });

    try runTest("1~0", .{ .boolean = false });
    try runTest("1~`int$()", .{ .boolean = false });
    try runTest("1~0 1 2 3 4", .{ .boolean = false });

    try runTest("1f~0", .{ .boolean = false });
    try runTest("1f~`int$()", .{ .boolean = false });
    try runTest("1f~0 1 2 3 4", .{ .boolean = false });

    try runTest("\"a\"~0", .{ .boolean = false });
    try runTest("\"a\"~`int$()", .{ .boolean = false });
    try runTest("\"a\"~0 1 2 3 4", .{ .boolean = false });

    try runTest("`symbol~0", .{ .boolean = false });
    try runTest("`symbol~`int$()", .{ .boolean = false });
    try runTest("`symbol~0 1 2 3 4", .{ .boolean = false });

    try runTest("()~0", .{ .boolean = false });
    try runTest("(1b;2)~0", .{ .boolean = false });
    try runTest("(1b;2;3f)~0", .{ .boolean = false });
    try runTest("(1b;2;3f;(0b;1))~0", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0", .{ .boolean = false });
    try runTest("()~`int$()", .{ .boolean = false });
    try runTest("()~0 1 2", .{ .boolean = false });
    try runTest("(1b;2)~`int$()", .{ .boolean = false });
    try runTest("(1b;2)~0 1", .{ .boolean = false });
    try runTest("(1b;2;3f)~0 1 2", .{ .boolean = false });
    try runTest("(1b;2;3f)~0 1 2 3", .{ .boolean = false });
    try runTest("(1b;2;3f;\"a\")~0 1 2 3", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0 1 2 3", .{ .boolean = false });

    try runTest("(`boolean$())~0", .{ .boolean = false });
    try runTest("11111b~0", .{ .boolean = false });
    try runTest("(`boolean$())~`int$()", .{ .boolean = false });
    try runTest("11111b~`int$()", .{ .boolean = false });
    try runTest("11111b~0 1 2 3 4", .{ .boolean = false });
    try runTest("11111b~0 1 2 3 4 5", .{ .boolean = false });

    try runTest("(`int$())~0", .{ .boolean = false });
    try runTest("5 4 3 2 1~0", .{ .boolean = false });
    try runTest("(`int$())~`int$()", .{ .boolean = true });
    try runTest("5 4 3 2 1~`int$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~0 1 2 3 4", .{ .boolean = false });
    try runTest("5 4 3 2 1~0 1 2 3 4 5", .{ .boolean = false });

    try runTest("(`float$())~0", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0", .{ .boolean = false });
    try runTest("(`float$())~`int$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~`int$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0 1 2 3 4", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0 1 2 3 4 5", .{ .boolean = false });

    try runTest("\"\"~0", .{ .boolean = false });
    try runTest("\"abcde\"~0", .{ .boolean = false });
    try runTest("\"\"~`int$()", .{ .boolean = false });
    try runTest("\"abcde\"~`int$()", .{ .boolean = false });
    try runTest("\"abcde\"~0 1 2 3 4", .{ .boolean = false });
    try runTest("\"abcde\"~0 1 2 3 4 5", .{ .boolean = false });

    try runTest("(`$())~0", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0", .{ .boolean = false });
    try runTest("(`$())~`int$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~`int$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0 1 2 3 4", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0 1 2 3 4 5", .{ .boolean = false });

    try runTest("(()!())~0", .{ .boolean = false });
    try runTest("(()!())~`int$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`int$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0 1", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0 1 2", .{ .boolean = false });

    try runTest("(+`a`b!())~0", .{ .boolean = false });
    try runTest("(+`a`b!())~`int$()", .{ .boolean = false });
    try runTest("(+`a`b!())~0 1", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~0", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~`int$()", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~0 1", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,`symbol))~0", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~`int$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0 1", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0 1 2", .{ .boolean = false });
}

test "match float" {
    try runTest("1b~0f", .{ .boolean = false });
    try runTest("1b~`float$()", .{ .boolean = false });
    try runTest("1b~0 1 2 3 4f", .{ .boolean = false });

    try runTest("1~0f", .{ .boolean = false });
    try runTest("1~`float$()", .{ .boolean = false });
    try runTest("1~0 1 2 3 4f", .{ .boolean = false });

    try runTest("1f~0f", .{ .boolean = false });
    try runTest("1f~`float$()", .{ .boolean = false });
    try runTest("1f~0 1 2 3 4f", .{ .boolean = false });

    try runTest("\"a\"~0f", .{ .boolean = false });
    try runTest("\"a\"~`float$()", .{ .boolean = false });
    try runTest("\"a\"~0 1 2 3 4f", .{ .boolean = false });

    try runTest("`symbol~0f", .{ .boolean = false });
    try runTest("`symbol~`float$()", .{ .boolean = false });
    try runTest("`symbol~0 1 2 3 4f", .{ .boolean = false });

    try runTest("()~0f", .{ .boolean = false });
    try runTest("(1b;2)~0f", .{ .boolean = false });
    try runTest("(1b;2;3f)~0f", .{ .boolean = false });
    try runTest("(1b;2;3f;(0b;1))~0f", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0f", .{ .boolean = false });
    try runTest("()~`float$()", .{ .boolean = false });
    try runTest("()~0 1 2f", .{ .boolean = false });
    try runTest("(1b;2)~`float$()", .{ .boolean = false });
    try runTest("(1b;2)~0 1f", .{ .boolean = false });
    try runTest("(1b;2;3f)~0 1 2f", .{ .boolean = false });
    try runTest("(1b;2;3f)~0 1 2 3f", .{ .boolean = false });
    try runTest("(1b;2;3f;\"a\")~0 1 2 3f", .{ .boolean = false });
    try runTest("(1b;2;3f;`symbol)~0 1 2 3f", .{ .boolean = false });

    try runTest("(`boolean$())~0f", .{ .boolean = false });
    try runTest("11111b~0f", .{ .boolean = false });
    try runTest("(`boolean$())~`float$()", .{ .boolean = false });
    try runTest("11111b~`float$()", .{ .boolean = false });
    try runTest("11111b~0 1 2 3 4f", .{ .boolean = false });
    try runTest("11111b~0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`int$())~0f", .{ .boolean = false });
    try runTest("5 4 3 2 1~0f", .{ .boolean = false });
    try runTest("(`int$())~`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~0 1 2 3 4f", .{ .boolean = false });
    try runTest("5 4 3 2 1~0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`float$())~0f", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0f", .{ .boolean = false });
    try runTest("(`float$())~`float$()", .{ .boolean = true });
    try runTest("5 4 3 2 1f~`float$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0 1 2 3 4f", .{ .boolean = false });
    try runTest("5 4 3 2 1f~0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("\"\"~0f", .{ .boolean = false });
    try runTest("\"abcde\"~0f", .{ .boolean = false });
    try runTest("\"\"~`float$()", .{ .boolean = false });
    try runTest("\"abcde\"~`float$()", .{ .boolean = false });
    try runTest("\"abcde\"~0 1 2 3 4f", .{ .boolean = false });
    try runTest("\"abcde\"~0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(`$())~0f", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0f", .{ .boolean = false });
    try runTest("(`$())~`float$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~`float$()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0 1 2 3 4f", .{ .boolean = false });
    try runTest("`a`b`c`d`e~0 1 2 3 4 5f", .{ .boolean = false });

    try runTest("(()!())~0f", .{ .boolean = false });
    try runTest("(()!())~`float$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0f", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`float$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0 1f", .{ .boolean = false });
    try runTest("(`a`b!1 2)~0 1 2f", .{ .boolean = false });

    try runTest("(+`a`b!())~0f", .{ .boolean = false });
    try runTest("(+`a`b!())~`float$()", .{ .boolean = false });
    try runTest("(+`a`b!())~0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~0f", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~`float$()", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,`symbol))~0f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~`float$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0 1f", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~0 1 2f", .{ .boolean = false });
}

test "match char" {
    try runTest("1b~\"a\"", .{ .boolean = false });
    try runTest("1b~\"\"", .{ .boolean = false });
    try runTest("1b~\"abcde\"", .{ .boolean = false });

    try runTest("1~\"a\"", .{ .boolean = false });
    try runTest("1~\"\"", .{ .boolean = false });
    try runTest("1~\"abcde\"", .{ .boolean = false });

    try runTest("1f~\"a\"", .{ .boolean = false });
    try runTest("1f~\"\"", .{ .boolean = false });
    try runTest("1f~\"abcde\"", .{ .boolean = false });

    try runTest("\"1\"~\"a\"", .{ .boolean = false });
    try runTest("\"1\"~\"\"", .{ .boolean = false });
    try runTest("\"1\"~\"abcde\"", .{ .boolean = false });

    try runTest("`symbol~\"a\"", .{ .boolean = false });
    try runTest("`symbol~\"\"", .{ .boolean = false });
    try runTest("`symbol~\"abcde\"", .{ .boolean = false });

    try runTest("()~\"a\"", .{ .boolean = false });
    try runTest("()~\"\"", .{ .boolean = false });
    try runTest("()~\"abcde\"", .{ .boolean = false });

    try runTest("10011b~\"a\"", .{ .boolean = false });
    try runTest("10011b~\"\"", .{ .boolean = false });
    try runTest("10011b~\"abcde\"", .{ .boolean = false });

    try runTest("5 4 3 2 1~\"a\"", .{ .boolean = false });
    try runTest("5 4 3 2 1~\"\"", .{ .boolean = false });
    try runTest("5 4 3 2 1~\"abcde\"", .{ .boolean = false });

    try runTest("5 4 3 2 1f~\"a\"", .{ .boolean = false });
    try runTest("5 4 3 2 1f~\"\"", .{ .boolean = false });
    try runTest("5 4 3 2 1f~\"abcde\"", .{ .boolean = false });

    try runTest("\"54321\"~\"a\"", .{ .boolean = false });
    try runTest("\"54321\"~\"\"", .{ .boolean = false });
    try runTest("\"54321\"~\"abcde\"", .{ .boolean = false });

    try runTest("`a`b`c`d`e~\"a\"", .{ .boolean = false });
    try runTest("`a`b`c`d`e~\"\"", .{ .boolean = false });
    try runTest("`a`b`c`d`e~\"abcde\"", .{ .boolean = false });

    try runTest("(`a`b!1 2)~\"a\"", .{ .boolean = false });
    try runTest("(`a`b!1 2)~\"\"", .{ .boolean = false });
    try runTest("(`a`b!1 2)~\"ab\"", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))~\"a\"", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~\"\"", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~\"ab\"", .{ .boolean = false });
}

test "match symbol" {
    try runTest("1b~`symbol", .{ .boolean = false });
    try runTest("1b~`$()", .{ .boolean = false });
    try runTest("1b~`a`b`c`d`e", .{ .boolean = false });

    try runTest("1~`symbol", .{ .boolean = false });
    try runTest("1~`$()", .{ .boolean = false });
    try runTest("1~`a`b`c`d`e", .{ .boolean = false });

    try runTest("1f~`symbol", .{ .boolean = false });
    try runTest("1f~`$()", .{ .boolean = false });
    try runTest("1f~`a`b`c`d`e", .{ .boolean = false });

    try runTest("\"a\"~`symbol", .{ .boolean = false });
    try runTest("\"a\"~`$()", .{ .boolean = false });
    try runTest("\"a\"~`a`b`c`d`e", .{ .boolean = false });

    try runTest("`symbol~`a", .{ .boolean = false });
    try runTest("`symbol~`$()", .{ .boolean = false });
    try runTest("`symbol~`a`b`c`d`e", .{ .boolean = false });

    try runTest("()~`symbol", .{ .boolean = false });
    try runTest("()~`$()", .{ .boolean = false });
    try runTest("()~`a`b`c`d`e", .{ .boolean = false });

    try runTest("10011b~`symbol", .{ .boolean = false });
    try runTest("10011b~`$()", .{ .boolean = false });
    try runTest("10011b~`a`b`c`d`e", .{ .boolean = false });

    try runTest("5 4 3 2 1~`symbol", .{ .boolean = false });
    try runTest("5 4 3 2 1~`$()", .{ .boolean = false });
    try runTest("5 4 3 2 1~`a`b`c`d`e", .{ .boolean = false });

    try runTest("5 4 3 2 1f~`symbol", .{ .boolean = false });
    try runTest("5 4 3 2 1f~`$()", .{ .boolean = false });
    try runTest("5 4 3 2 1f~`a`b`c`d`e", .{ .boolean = false });

    try runTest("\"54321\"~`symbol", .{ .boolean = false });
    try runTest("\"54321\"~`$()", .{ .boolean = false });
    try runTest("\"54321\"~`a`b`c`d`e", .{ .boolean = false });

    try runTest("`5`4`3`2`1~`symbol", .{ .boolean = false });
    try runTest("`5`4`3`2`1~`$()", .{ .boolean = false });
    try runTest("`5`4`3`2`1~`a`b`c`d`e", .{ .boolean = false });

    try runTest("(`a`b!1 2)~`symbol", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`$()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`a`b", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))~`symbol", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~`$()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~`a`b", .{ .boolean = false });
}

test "match list" {
    try runTest("1b~()", .{ .boolean = false });
    try runTest("1b~(0b;1;0N;0W;-0W)", .{ .boolean = false });
    try runTest("1b~(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1b~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1b~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("1~()", .{ .boolean = false });
    try runTest("1~(0b;1;0N;0W;-0W)", .{ .boolean = false });
    try runTest("1~(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("1f~()", .{ .boolean = false });
    try runTest("1f~(0b;1;0N;0W;-0W;1f;0n;0w;-0w)", .{ .boolean = false });
    try runTest("1f~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("1f~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("\"a\"~()", .{ .boolean = false });

    try runTest("`symbol~()", .{ .boolean = false });

    try runTest("()~()", .{ .boolean = true });
    try runTest("(0N;0n)~()", .{ .boolean = false });
    try runTest("()~(0N;0n)", .{ .boolean = false });
    try runTest("(1b;2)~(1b;2)", .{ .boolean = true });
    try runTest("(1b;2f)~(2f;1b)", .{ .boolean = false });
    try runTest("(2;3f)~(2;3f)", .{ .boolean = true });
    try runTest("(1b;(2;3f))~(0N;(0n;0N))", .{ .boolean = false });
    try runTest("(0b;1;2;3;4;5;6;7;8;9)~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("(0b;1;2;3;4;5;6;7;8;9)~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`boolean$())~()", .{ .boolean = false });
    try runTest("010b~()", .{ .boolean = false });
    try runTest("01b~(0b;0N)", .{ .boolean = false });
    try runTest("010b~(0b;0N;0n)", .{ .boolean = false });
    try runTest("0101010101b~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0101010101b~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`int$())~()", .{ .boolean = false });
    try runTest("0 1 2~()", .{ .boolean = false });
    try runTest("0 1~(0b;0N)", .{ .boolean = false });
    try runTest("0 1 2~(0b;0N;0n)", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9~(\"a\";-0w;0w;0n;1f;-0W;0W;0N;1;0b)", .{ .boolean = false });

    try runTest("(`float$())~()", .{ .boolean = false });
    try runTest("0 1 2f~()", .{ .boolean = false });
    try runTest("0 1 2f~(0b;0N;0n)", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9f~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });
    try runTest("0 1 2 3 4 5 6 7 8 9f~(0b;1;0N;0W;-0W;1f;0n;0w;-0w;\"a\")", .{ .boolean = false });

    try runTest("\"\"~()", .{ .boolean = false });
    try runTest("\"abcde\"~()", .{ .boolean = false });

    try runTest("(`$())~()", .{ .boolean = false });
    try runTest("`a`b`c`d`e~()", .{ .boolean = false });

    try runTest("(()!())~()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~(1;2f)", .{ .boolean = false });
    try runTest("(`a`b!1 2)~(0b;1;2f)", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))~()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~(1;2f)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~(0b;1;2f)", .{ .boolean = false });
}

test "match dictionary" {
    try runTest("1b~()!()", .{ .boolean = false });
    try runTest("1b~(`int$())!()", .{ .boolean = false });
    try runTest("1b~(`int$())!`float$()", .{ .boolean = false });
    try runTest("1b~`a`b!1 2", .{ .boolean = false });

    try runTest("1~()!()", .{ .boolean = false });
    try runTest("1~(`int$())!()", .{ .boolean = false });
    try runTest("1~(`int$())!`float$()", .{ .boolean = false });
    try runTest("1~`a`b!1 2", .{ .boolean = false });

    try runTest("1f~()!()", .{ .boolean = false });
    try runTest("1f~(`int$())!()", .{ .boolean = false });
    try runTest("1f~(`int$())!`float$()", .{ .boolean = false });
    try runTest("1f~`a`b!1 2", .{ .boolean = false });

    try runTest("\"a\"~`a`b!1 2", .{ .boolean = false });

    try runTest("`symbol~`a`b!1 2", .{ .boolean = false });

    try runTest("()~()!()", .{ .boolean = false });
    try runTest("()~(`int$())!()", .{ .boolean = false });
    try runTest("()~(`int$())!`float$()", .{ .boolean = false });
    try runTest("()~`a`b!1 2", .{ .boolean = false });
    try runTest("(1;2f)~`a`b!1 2", .{ .boolean = false });
    try runTest("(0b;1;2f)~`a`b!1 2", .{ .boolean = false });

    try runTest("(`boolean$())~()!()", .{ .boolean = false });
    try runTest("(`boolean$())~(`int$())!()", .{ .boolean = false });
    try runTest("(`boolean$())~(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`boolean$())~`a`b!1 2", .{ .boolean = false });
    try runTest("10b~`a`b!1 2", .{ .boolean = false });
    try runTest("101b~`a`b!1 2", .{ .boolean = false });

    try runTest("(`int$())~()!()", .{ .boolean = false });
    try runTest("(`int$())~(`int$())!()", .{ .boolean = false });
    try runTest("(`int$())~(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`int$())~`a`b!1 2", .{ .boolean = false });
    try runTest("1 2~`a`b!1 2", .{ .boolean = false });
    try runTest("1 2 3~`a`b!1 2", .{ .boolean = false });

    try runTest("(`float$())~()!()", .{ .boolean = false });
    try runTest("(`float$())~(`int$())!()", .{ .boolean = false });
    try runTest("(`float$())~(`int$())!`float$()", .{ .boolean = false });
    try runTest("(`float$())~`a`b!1 2", .{ .boolean = false });
    try runTest("1 2f~`a`b!1 2", .{ .boolean = false });
    try runTest("1 2 3f~`a`b!1 2", .{ .boolean = false });

    try runTest("\"\"~`a`b!1 2", .{ .boolean = false });
    try runTest("\"12\"~`a`b!1 2", .{ .boolean = false });
    try runTest("\"123\"~`a`b!1 2", .{ .boolean = false });

    try runTest("(`$())~`a`b!1 2", .{ .boolean = false });
    try runTest("`5`4~`a`b!1 2", .{ .boolean = false });
    try runTest("`5`4`3~`a`b!1 2", .{ .boolean = false });

    try runTest("(()!())~()!()", .{ .boolean = true });
    try runTest("(()!())~(`int$())!()", .{ .boolean = false });
    try runTest("(()!())~(`int$())!(`float$())", .{ .boolean = false });
    try runTest("((`int$())!())~()!()", .{ .boolean = false });
    try runTest("((`int$())!())~(`int$())!()", .{ .boolean = true });
    try runTest("((`int$())!())~(`int$())!(`float$())", .{ .boolean = false });
    try runTest("((`int$())!`float$())~()!()", .{ .boolean = false });
    try runTest("((`int$())!`float$())~(`int$())!()", .{ .boolean = false });
    try runTest("((`int$())!`float$())~(`int$())!(`float$())", .{ .boolean = true });
    try runTest("(()!())~`a`b!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)~()!()", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`a`b!1 2", .{ .boolean = true });
    try runTest("(`b`a!1 2)~`a`b!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`b`a!1 2", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`c`d!1 2", .{ .boolean = false });
    try runTest("(`a`b!0N 0W)~`c`d!0N 0W", .{ .boolean = false });
    try runTest("(`a`b!1 2)~`a`b!(1;\"2\")", .{ .boolean = false });

    try runTest("(+`a`b!(,1;,2))~`a`b!1 2", .{ .boolean = false });
}

test "match table" {
    try runTest("1b~+`a`b!()", .{ .boolean = false });
    try runTest("1b~+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1b~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("1~+`a`b!()", .{ .boolean = false });
    try runTest("1~+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("1f~+`a`b!()", .{ .boolean = false });
    try runTest("1f~+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("1f~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("\"a\"~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("`symbol~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("()~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(1;2f)~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(0b;1;2f)~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`boolean$())~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("10b~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("101b~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`int$())~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2 3~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`float$())~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2f~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("1 2 3f~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("\"\"~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("\"12\"~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("\"123\"~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`$())~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("`5`4~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("`5`4`3~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(`a`b!1 2)~+`a`b!(,1;,2)", .{ .boolean = false });

    try runTest("(+`a`b!())~+`a`b!()", .{ .boolean = true });
    try runTest("(+`a`b!())~+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("(+`a`b!())~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~+`a`b!()", .{ .boolean = false });
    try runTest("(+`a`b!(`int$();`float$()))~+`a`b!(`int$();`float$())", .{ .boolean = true });
    try runTest("(+`a`b!(`int$();`float$()))~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b!()", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b!(`int$();`float$())", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b!(,1;,2)", .{ .boolean = true });
    try runTest("(+`b`a!(,1;,2))~+`a`b!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`b`a!(,1;,2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b!(,1;,`symbol)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b!(1 1;2 2)", .{ .boolean = false });
    try runTest("(+`a`b!(,1;,2))~+`a`b`c!(,1;,2;,3)", .{ .boolean = false });
    try runTest("(+`a`b`c!(,1;,2;,3))~+`a`b!(,1;,2)", .{ .boolean = false });
}
