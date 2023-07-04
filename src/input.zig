const std = @import("std");
const print = std.debug.print;

const stdin_file = std.io.getStdIn().reader();
var stdin_br = std.io.bufferedReader(stdin_file);
var stdin_reader = stdin_br.reader();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const gpa_allocator = gpa.allocator();
var arena = std.heap.ArenaAllocator.init(gpa_allocator);
const allocator = arena.allocator();

pub const String = std.ArrayList(u8);

// var buffer:

pub const ParseError = error{
    /// Result can't fit in type (for integers)
    Overflow,

    /// Input invalid
    InvalidCharacter,

    /// The string given was empty, and type is not nullable
    EmptyString,
};

pub fn readWord(comptime bufsize: comptime_int, buffer: anytype) (std.os.ReadError || error{ EndOfStream, StreamTooLong, NoSpaceLeft })![]u8 {
    _ = buffer;
    _ = bufsize;
    // var bufStream = std.io.fixedBufferStream(buffer: anytype)
}

pub fn readLine(comptime bufsize: comptime_int) (std.os.ReadError || error{ EndOfStream, StreamTooLong, NoSpaceLeft })![]u8 {
    const BFType = std.io.FixedBufferStream([]u8);

    const StaticState = struct {
        var buffer: [bufsize]u8 = .{0} ** bufsize; // Static buffer will never change
        var buffer_stream: ?BFType = null;
        var buffer_writer: ?BFType.Writer = null;
    };
    defer StaticState.buffer_stream.?.reset();
    if (StaticState.buffer_stream == null) {
        StaticState.buffer_stream = std.io.fixedBufferStream(&StaticState.buffer);
        StaticState.buffer_writer = StaticState.buffer_stream.?.writer();
    }
    try stdin_reader.streamUntilDelimiter(StaticState.buffer_writer.?, '\n', bufsize);

    const line = StaticState.buffer_stream.?.getWritten();
    return line; // Can leak memory from function since it is static
}

pub fn readAndParseLine(comptime parse_type: type, comptime bufsize: comptime_int) !parse_type {
    const line = try readLine(bufsize);
    const parse_function = getParseFunction(parse_type);
    return parse_function(line);
}

fn eqlCaseInsensitive(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) {
        return false;
    }
    if (a.ptr == b.ptr) {
        return true;
    }
    for (a, b) |a_elem, b_elem| {
        if (std.ascii.toLower(a_elem) != std.ascii.toLower(b_elem)) return false;
    }
    return true;
}
fn ParseReturnType(comptime parse_type: type, comptime out_pointer_type: type) type {
    if (std.meta.fields(out_pointer_type).len == 0) {
        return parse_type;
    } else {
        return void;
    }
}

fn getParseFunction(comptime parse_type: type, comptime out_pointer: anytype) (fn ([]const u8) ParseError!ParseReturnType(parse_type, @TypeOf(out_pointer))) {
    const parse_return_type = ParseReturnType(parse_type, @TypeOf(out_pointer));
    const parse_type_struct: std.builtin.Type = @typeInfo(parse_type);
    const Ret = ParseError!parse_return_type;
    const InnerRet = ParseError!void;

    const parse_function = comptime switch (parse_type_struct) {
        .Struct => blk: {
            const type_name = @typeName(parse_type);
            if (!std.mem.eql(u8, type_name, "array_list.ArrayListAligned(u8,null)")) {
                @compileError("Didn't recognize type " ++ type_name);
            }
            break :blk struct {
                fn parse(inp: []const u8, out: *parse_type) InnerRet {
                    var string = std.ArrayList(u8).initCapacity(allocator, inp.len) catch unreachable;
                    string.appendSlice(inp) catch unreachable;
                    out.* = string;
                }
            }.parse;
        },
        .Float => struct {
            fn parse(buf: []const u8, out: *parse_type) InnerRet {
                out.* = try std.fmt.parseFloat(parse_type, buf);
            }
        }.parse,
        .Int => |t| struct {
            fn parse(buf: []const u8, out: *parse_type) InnerRet {
                const base_func = comptime switch (t.signedness) {
                    .signed => std.fmt.parseInt,
                    .unsigned => std.fmt.parseUnsigned,
                };
                out.* = try base_func(parse_type, buf, 10);
            }
        }.parse,
        .Bool => struct {
            fn parse(buf: []const u8, out: *parse_type) InnerRet {
                if (eqlCaseInsensitive(buf, "true") or std.mem.eql(u8, buf, "1")) {
                    out.* = true;
                    return;
                }
                if (eqlCaseInsensitive(buf, "false") or std.mem.eql(u8, buf, "0")) {
                    out.* = false;
                    return;
                }
                return ParseError.InvalidCharacter;
            }
        }.parse,
        .Optional => |optional| {
            const childParseFunction = getParseFunction(optional.child);
            const optionalParseFunction = struct {
                fn parseFunc(buf: []const u8, out: *parse_type) InnerRet {
                    // This will never return a ParseError, but instead return null
                    out.* = try childParseFunction(buf) catch |err| switch (err) {
                        error.EmptyString => null,
                        else => err,
                    };
                }
            }.parseFunc;
            return optionalParseFunction;
        },
        else => {
            @compileError("Unrecognized type: " ++ @typeName(parse_type));
        },
    };

    const Static = struct {
        var x: parse_return_type = undefined;
    };
    const out_p = comptime if (parse_return_type == void)
        out_pointer.@"0"
    else blk: {
        break :blk &Static.x;
    };

    // Prepend a check for empty strings
    const final_parse_function = struct {
        fn parse(buf: []const u8) Ret {
            if (buf.len == 0) {
                return error.EmptyString;
            }
            _ = try parse_function(buf, out_p);
            if (parse_return_type == void) {
                return;
            } else {
                return out_p.*;
            }
        }
    }.parse;

    return final_parse_function;
}

pub fn readAll(alloc: std.mem.Allocator) !std.ArrayList(u8) {
    _ = alloc;
    var buffer = std.ArrayList(u8).init(allocator);
    // const reader = std.io.getStdIn().reader();
    try stdin_reader.readAllArrayList(&buffer, 100000);
    return buffer;
}

fn combineParsers(comptime types: []type) !types {
    for (types) |t| {
        _ = t;
    }
}

pub fn parseLineTo(comptime T: type, type_config: *T, line: []const u8) !*T {
    var split_string = std.mem.splitScalar(u8, line, ' ');

    const fields = std.meta.fields(T);
    print("{}", .{type_config.*.some_bool});

    inline for (fields, 0..) |f, i| {
        if (split_string.next()) |s| {
            const field_name = f.name;
            print("{s}: {s}\n", .{ field_name, s });
            const parseFunction = getParseFunction(f.type);
            const parsed = try parseFunction(s);
            _ = parsed;
            var tc = type_config.*;
            _ = tc;
            // @field(tc, field_name) = parsed;
        } else {
            std.log.err("Found only {} strings after splitting, but expected {}.", .{ i, fields.len });
            return error.StreamTooLong;
        }
    }
    return type_config;
}

// pub fn parseLines(comptime lineParser: )

// test "parsing" {
//     var allocator = std.testing.allocator;

//     const inp = "132";
//     const parsed = parseOrBlank(i32)(inp) orelse 0;
//     try std.testing.expectEqual(@as(i32, 132), parsed);

//     const lines = "10\n20\n\n100";
//     const result = parseLines(lines, parseOrBlank(i32), allocator);
//     defer result.deinit();
//     var expectedResult = std.ArrayList(?i32).init(allocator);
//     defer expectedResult.deinit();
//     try expectedResult.appendSlice(&[_]?i32{ 10, 20, null, 100 });
//     try std.testing.expectEqualDeep(expectedResult, result);
// }

fn make_static(comptime x: anytype) *@TypeOf(x) {
    const S = struct {
        var inner: @TypeOf(x) = x;
    };
    return &S.inner;
}

test "integer parsing" {
    const inp = "132";
    const parseFunction = getParseFunction(i32, .{});
    const parsed = try parseFunction(inp);
    try std.testing.expectEqual(parsed, @as(i32, 132));
}

test "float parsing" {
    const inp = "1.529";
    const parsed = comptime make_static(@as(f32, undefined));
    // const Static = struct {
    //     var parsed: f32 = undefined;
    // };
    const parseFunction = getParseFunction(f32, .{parsed});
    _ = try parseFunction(inp);
    try std.testing.expectEqual(parsed.*, @as(f32, 1.529));
}

// test "optional parsing" {
//     const should_exist = "1500";
//     const should_not_exist = "";
//     const parseFunction = comptime getParseFunction(?i64);
//     var parsed_should_exist: ?i64 = undefined;
//     _ = try parseFunction(should_exist, &parsed_should_exist);
//     var parsed_should_not_exist: ?i64 = undefined;
//     _ = try parseFunction(should_not_exist, &parsed_should_not_exist);

//     try std.testing.expectEqual(@as(?i64, 1500), parsed_should_exist);
//     try std.testing.expectEqual(@as(?i64, null), parsed_should_not_exist);
// }

// test "casting to optional" {
//     const number: i64 = std.fmt.parseInt(i64, "64", 10) catch 0;
//     const casted: ?i64 = @as(?i64, number);

//     // const parseFunction = comptime getParseFunction(i64);

//     const errornumber: ParseError!i64 = 100;
//     const parsed_errornumber: ParseError!i64 = getParseFunction(i64)("64");

//     const errornumber_casted: ParseError!?i64 = errornumber;
//     const parsed_errornumber_casted: ParseError!?i64 = if (parsed_errornumber) |res| res else |err| err;

//     std.log.warn("", .{});
//     std.log.warn("Casted into {any}", .{casted});
//     std.log.warn("Casted into {any}", .{errornumber_casted});
//     std.log.warn("Casted into {any}", .{parsed_errornumber_casted});
// }

// test "correct error types" {
//     const normal_input = "132";
//     const empty_string = "";
//     const wrong_character = "14xg033";

//     const data = .{ normal_input, empty_string, wrong_character };
//     const types = .{ i64, ?i64 };
//     // var results
//     var results = std.ArrayList(ParseError!?i64).init(std.testing.allocator);
//     defer results.deinit();
//     inline for (types) |t| {
//         inline for (data) |d| {
//             const result = getParseFunction(t)(d);
//             const res: ParseError!?i64 = if (result) |res| res else |err| err;
//             try results.append(res);
//         }
//     }

//     const expected_results = [6]ParseError!?i64{ 132, error.EmptyString, error.InvalidCharacter, 132, null, error.InvalidCharacter };
//     // try std.testing.expectEqual(results.items, expected_result);
//     for (results.items, expected_results) |r, e| {
//         try std.testing.expectEqual(r, e);
//     }
// }

// test "noop parsing" {
//     const input_text = "hello there!";
//     const parse_function = getParseFunction(String);
//     const parsed = try parse_function(input_text);

//     try std.testing.expectEqualStrings(input_text, parsed.items);
// }

// test "arbitrary parsing" {
//     const toParse = "false 500 helloworld";
//     var parse_struct = .{
//         .some_bool = @as(bool, undefined),
//         .some_u32 = @as(u32, undefined),
//         .some_string = @as(*const [100]u8, &[_]u8{
//             undefined,
//         } ** 100),
//     };
//     // @compileLog(.{@TypeOf(parseType1)});
//     // @compileLog(.{parseType1});
//     _ = try parseLineTo(@TypeOf(parse_struct), &parse_struct, toParse);
// }
