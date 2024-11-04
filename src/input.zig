const std = @import("std");
const print = std.debug.print;
const File = std.fs.File;
const expectEqual = std.testing.expectEqual;

// pub const Reader = io.Reader(File, ReadError, File.read);

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

    /// The buffer array is the wrong size for the inputted string
    SizeMismatch,

    /// The declaration given in the parse struct is invalid
    InvalidDecl,
};

pub fn readWord(comptime bufsize: comptime_int, buffer: anytype) (std.os.ReadError || error{ EndOfStream, StreamTooLong, NoSpaceLeft })![]u8 {
    _ = buffer;
    _ = bufsize;
    // var bufStream = std.io.fixedBufferStream(buffer: anytype)
}

const FileBrType = std.io.BufferedReader(4096, File.Reader);
fn getFileOrStdin() !FileBrType.Reader {
    const StaticState = struct {
        // var input_file_reader: ?File.Reader = null;
        var file_br: ?FileBrType = null;
        var file_reader: ?FileBrType.Reader = null;

        var isatty: ?bool = null;
    };
    if (StaticState.isatty == null) {
        StaticState.isatty = std.io.getStdIn().isTty();
        if (StaticState.isatty.?) { // No input given through stdin
            var buf = std.mem.zeroes([100:0]u8);
            const problem_number = @import("main.zig").problem_number;
            var buf_stream = std.io.fixedBufferStream(&buf);
            std.fmt.format(buf_stream.writer(), "{:0>2}.txt", .{problem_number}) catch unreachable;
            print("Loading input file: {s}.\n", .{buf_stream.getWritten()});
            const input_file_reader = (try (try std.fs.cwd().openDir("inputs", .{})).openFile(buf_stream.getWritten(), .{})).reader();
            StaticState.file_br = std.io.bufferedReader(input_file_reader);
            StaticState.file_reader = StaticState.file_br.?.reader();
        } else { // Use stdin instead
            print("Loading input from stdin.\n", .{});
            const input_file_reader = std.io.getStdIn().reader();
            StaticState.file_br = std.io.bufferedReader(input_file_reader);
            StaticState.file_reader = StaticState.file_br.?.reader();
        }
    }

    return StaticState.file_reader.?;
}

pub fn readLine(comptime bufsize: comptime_int) ![]u8 {
    const BFType = std.io.FixedBufferStream([]u8);

    const StaticState = struct {
        var buffer: [bufsize]u8 = std.mem.zeroes([bufsize]u8); // Static buffer will never change
        var buffer_stream: ?BFType = null;
        var buffer_writer: ?BFType.Writer = null;
    };

    defer StaticState.buffer_stream.?.reset();

    if (StaticState.buffer_stream == null) {
        StaticState.buffer_stream = std.io.fixedBufferStream(&StaticState.buffer);
        StaticState.buffer_writer = StaticState.buffer_stream.?.writer();
    }

    // if (StaticState.isatty) {
    //     try StaticState.file_reader.?.streamUntilDelimiter(StaticState.buffer_writer.?, '\n', bufsize);
    // } else {
    //     try stdin_reader.streamUntilDelimiter(StaticState.buffer_writer.?, '\n', bufsize);
    // }
    const file_reader = try getFileOrStdin();
    file_reader.streamUntilDelimiter(StaticState.buffer_writer.?, '\n', bufsize) catch |err| switch (err) {
        error.EndOfStream => {}, // Can happen after having read the final line if it doesn't end with \n. We check below.
        else => return err,
    };

    const line = StaticState.buffer_stream.?.getWritten();
    if (line.len == 0)
        return error.EndOfStream;
    return line; // Can leak memory from function since it is static

}

pub fn readAndParseLine(comptime parse_type: type, comptime bufsize: comptime_int) !parse_type {
    const line = try readLine(bufsize);
    const parsed = try parseLineTo(parse_type, line);
    return parsed;
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

fn getParseFunction(comptime parse_type: type) fn ([]const u8) ParseError!parse_type {
    const parse_type_struct: std.builtin.Type = @typeInfo(parse_type);
    // @compileLog(parse_type);
    const Ret = ParseError!parse_type;

    const parse_function = comptime switch (parse_type_struct) {
        // .Struct => blk: {
        //     const type_name = @typeName(parse_type);
        //     if (!std.mem.eql(u8, type_name, "array_list.ArrayListAligned(u8,null)")) {
        //         @compileError("Didn't recognize type " ++ type_name);
        //     }
        //     break :blk struct {
        //         fn parse(inp: []const u8) Ret {
        //             var string = std.ArrayList(u8).initCapacity(allocator, inp.len) catch unreachable;
        //             string.appendSlice(inp) catch unreachable;
        //             return string;
        //         }
        //     }.parse;
        // },
        .float => struct {
            fn parseFunc(buf: []const u8) Ret {
                return std.fmt.parseFloat(parse_type, buf);
            }
        }.parseFunc,
        .int => |t| struct {
            fn parseFunc(buf: []const u8) Ret {
                const base_func = comptime switch (t.signedness) {
                    .signed => std.fmt.parseInt,
                    .unsigned => std.fmt.parseUnsigned,
                };
                return base_func(parse_type, buf, 10);
            }
        }.parseFunc,
        .bool => struct {
            fn parseFunc(buf: []const u8) Ret {
                if (eqlCaseInsensitive(buf, "true") or std.mem.eql(u8, buf, "1")) {
                    return true;
                }
                if (eqlCaseInsensitive(buf, "false") or std.mem.eql(u8, buf, "0")) {
                    return true;
                }
                return ParseError.InvalidCharacter;
            }
        }.parseFunc,
        .array => { // String or array
            return struct {
                fn parseFunc(buf: []const u8) Ret {
                    if (parse_type_struct.array.sentinel == null) {
                        var result: parse_type = undefined;
                        if (buf.len != parse_type_struct.array.len) {
                            return error.SizeMismatch;
                        }
                        @memcpy(&result, buf);
                        return result;
                    }
                    // Loading a variable-length zero-terminated string, need to initialize with zeros
                    var result: parse_type = std.mem.zeroes(parse_type);
                    @memcpy(result[0..buf.len], buf);
                    return result;
                }
            }.parseFunc;
        },
        .@"enum" => |en| {
            return struct {
                fn parseFunc(buf: []const u8) Ret {
                    inline for (en.fields) |field| {
                        const field_value = field.value;
                        if (std.mem.eql(u8, field.name, buf[0..field.name.len])) {
                            return @enumFromInt(field_value);
                        }
                    }
                    unreachable;
                }
            }.parseFunc;
        },
        .@"union" => |un| {
            return struct {
                fn parseFunc(buf: []const u8) Ret {
                    var it = std.mem.splitScalar(u8, buf, ' ');
                    const discriminator = it.next().?;
                    inline for (un.fields) |field| {
                        if (std.mem.eql(u8, field.name, discriminator[0..field.name.len])) {
                            const payload: field.type = if (@sizeOf(field.type) != 0) try getParseFunction(field.type)(it.next().?) else {};
                            // const en = std.meta.stringToEnum(un.tag_type.?, field.name).?;
                            const instance = @unionInit(parse_type, field.name, payload);
                            // @compileLog(@sizeOf(un.tag_type.?));
                            return instance;
                        }
                    }
                    unreachable;
                }
            }.parseFunc;
        },
        .optional => |optional| {
            const childParseFunction = getParseFunction(optional.child);
            const optionalParseFunction = struct {
                fn parseFunc(buf: []const u8) Ret {
                    // This will never return a ParseError, but instead return null
                    return childParseFunction(buf) catch |err| switch (err) {
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

    // Prepend a check for empty strings
    const final_parse_function = struct {
        fn parse(buf: []const u8) Ret {
            if (buf.len == 0) {
                return error.EmptyString;
            }
            const result = try parse_function(buf);
            return result;
        }
    }.parse;

    return final_parse_function;
}

pub fn readAll(alloc: std.mem.Allocator) !std.ArrayList(u8) {
    _ = alloc;
    const buffer = std.ArrayList(u8).init(allocator);
    // const reader = std.io.getStdIn().reader();
    // try stdin_reader.readAllArrayList(&buffer, 100000);
    return buffer;
}

fn parseLineAsArray(comptime arr_type: type, line: []const u8) !arr_type {
    const type_info: std.builtin.Type = @typeInfo(arr_type);
    switch (type_info) {
        .array => |arr| {
            const T = arr.child;
            const len = arr.len;

            var split_iterator = std.mem.splitScalar(T, line, ' ');
            var result: arr_type = std.mem.zeroes(arr_type);
            var i: usize = 0;
            while (split_iterator.next()) |v| : (i += 1) {
                if (i >= len) {
                    return error.StreamTooLong;
                }
                result[i] = try getParseFunction(T)(v);
            }
            if (i > len) {
                return error.ArrayLongerThanStream;
            }
            return result;
        },
        else => @compileError("Only supports array types"),
    }
}

const InOrderIndex = struct {
    slice: []const usize,

    const Self = @This();

    pub fn init(slice: []const u8) Self {
        return .{ .slice = slice };
    }

    pub fn hasIndex(self: *Self, index: usize) bool {
        while (self.slice.len > 0 and self.slice[0] < index) {
            self.slice = self.slice[1..self.slice.len];
        }
        return self.slice.len > 0 and self.slice[0] == index;
    }
};

fn rangeOfLength(comptime n: comptime_int) [n]usize {
    var range = std.mem.zeroes([n]usize);
    for (0..n) |i| {
        range[i] = i;
    }
    return range;
}

fn ParseInfo(comptime T: type) type {
    const n_fields = std.meta.fields(T).len;
    return struct {
        delimiter: u8,
        indices: [n_fields]usize,
    };
}
fn validateParseStruct(comptime T: type) !ParseInfo(T) {
    const decls = comptime std.meta.declarations(T);
    // @compileLog(.{@typeInfo(T).Struct});
    const valid_decls = [_][]const u8{ "delimiter", "indices" };
    inline for (decls) |decl| {
        comptime var valid = false;
        inline for (valid_decls) |vdecl| {
            comptime if (std.mem.eql(u8, decl.name, vdecl)) {
                valid = true;
            };
            // @compileLog(.{valid});
        }
        if (!valid) {
            continue;
            // @compileError("Declaration " ++ decl.name ++ " is not in the set of valid declarations");
            // std.log.err("Declaration {s} is not in the set of valid declarations", .{decl.name});
            // return ParseError.InvalidDecl;
        }
        // @compileLog(.{decl});
        // if (!decl.is_pub) {
        //     @compileError("Declaration " ++ decl.name ++ " must be public");
        //     // std.log.err("Declaration {s} must be public", .{decl.name});
        //     // return ParseError.InvalidDecl;
        // }
    }
    const delimiter = if (@hasDecl(T, "delimiter")) T.delimiter else ' ';
    const indices = if (@hasDecl(T, "indices")) T.indices else rangeOfLength(std.meta.fields(T).len);
    return ParseInfo(T){ .indices = indices, .delimiter = delimiter };
}

pub fn parseLineTo(comptime T: type, line: []const u8) !T {
    const type_info: std.builtin.Type = @typeInfo(T);

    switch (type_info) {
        .@"struct" => {},
        else => return getParseFunction(T)(line),
    }

    const fields = std.meta.fields(T);

    // Figure out information like optional delimiter and
    const parse_info = try validateParseStruct(T);

    var split_iterator = std.mem.splitScalar(u8, line, parse_info.delimiter);
    // std.log.warn("line: {s}, '{c}', indices: {any}, decls: {any}, {any}", .{ line, parse_info.delimiter, parse_info.indices, std.meta.declarations(T), @hasDecl(T, "indices") });

    var result: T = undefined;
    var split_idx: isize = -1;
    var current_string: []const u8 = undefined;
    inline for (fields, parse_info.indices) |f, field_idx| {
        while (split_idx < field_idx) {
            current_string = split_iterator.next() orelse return error.SizeMismatch;
            split_idx += 1;
            // std.log.warn("split_idx: {}, field_idx: {}\n", .{ split_idx, field_idx });
        }
        const field_name = f.name;
        // std.log.warn("Res {s}: {s}\n", .{ field_name, current_string });
        const parsed = try parseLineTo(f.type, current_string);
        @field(result, field_name) = parsed;
    }
    return result;
}

// pub fn parseLines(comptime lineParser: )

test "basic parsing" {
    const to_parse = "132";
    const parsed = try parseLineTo(i32, to_parse);
    try expectEqual(parsed, @as(i32, 132));
}

test "optional parsing" {
    const inp = "132";
    const not_parsable = "";

    const parsed = parseLineTo(?i32, inp);
    const not_parsed = parseLineTo(?i32, not_parsable);

    try expectEqual(parsed, @as(?i32, 132));
    try expectEqual(not_parsed, @as(?i32, null));
}

test "correct error types" {
    const normal_input = "132";
    const empty_string = "";
    const wrong_character = "14xg033";

    const data = .{ normal_input, empty_string, wrong_character };
    const types = .{ i64, ?i64 };
    // var results
    var results = std.ArrayList(ParseError!?i64).init(std.testing.allocator);
    defer results.deinit();
    inline for (types) |t| {
        inline for (data) |d| {
            const result = getParseFunction(t)(d);
            const res: ParseError!?i64 = if (result) |res| res else |err| err;
            try results.append(res);
        }
    }

    const expected_results = [6]ParseError!?i64{ 132, error.EmptyString, error.InvalidCharacter, 132, null, error.InvalidCharacter };
    // try std.testing.expectEqual(results.items, expected_result);
    for (results.items, expected_results) |r, e| {
        try std.testing.expectEqual(r, e);
    }
}

test "arbitrary struct parsing" {
    // Parsing in this way allows for all the relevant parsing parameters to be defined in a single
    // local struct definition, rather than being passed as parameters.
    // For instance, the string buffer sizes can be defined very easily.
    const toParse = "false 500 helloworld!grr";
    const ParseStruct = struct {
        pub const delimiter = ' ';
        some_bool: bool,
        some_u32: u32,
        two_strings: struct {
            pub const delimiter = '!';
            string1: [100:0]u8,
            string2: [100:0]u8,
        },
    };

    const arr: [10]u8 = std.mem.zeroes([10]u8);
    _ = arr;

    const result: ParseStruct = try parseLineTo(ParseStruct, toParse);
    std.log.warn("{s}test", .{result.two_strings.string2});
}

test "arbitrary struct parsing with indices" {
    const toParse = "move 1 from 5 to 2";
    const ParseStruct = struct {
        pub const delimiter = ' ';
        pub const indices: [3]usize = .{ 1, 3, 5 };
        first: u32,
        second: u32,
        third: u32,
    };

    const parsed = try parseLineTo(ParseStruct, toParse);
    std.log.warn("{any}", .{parsed});
}

test "enum parsing" {
    const E = enum {
        U,
        D,
    };
    const parsed1 = try parseLineTo(E, "U");
    const parsed2 = try parseLineTo(E, "D");
    try std.testing.expectEqual(parsed1, E.U);
    try std.testing.expectEqual(parsed2, E.D);
}

test "union(enum) parsing" {
    const U = union(enum) {
        addx: isize,
        noop,
    };
    // @compileLog(@sizeOf(@typeInfo(U).Union.fields[0].type));
    const parsed1 = try parseLineTo(U, "noop");
    const parsed2 = try parseLineTo(U, "addx -11");

    try std.testing.expectEqual(parsed1, U.noop);
    try std.testing.expectEqual(parsed2, U{ .addx = -11 });
}

test "fails parsing with non-pub indices" {
    const toParse = "false;500";
    const ParseStruct = struct {
        b: bool,
        i: i32,
        const delimiter = ';';
    };
    const attemptParse = try parseLineTo(ParseStruct, toParse);
    std.log.warn("{?} {?}", .{ attemptParse.b, attemptParse.i });
    // try std.testing.expectError(expected_error: anyerror, actual_error_union: anytype)
}
