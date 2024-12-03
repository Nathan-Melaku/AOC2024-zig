const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const q1answer = try countSafe(
        allocator,
        "2.input",
        false,
    );
    std.debug.print("safe reports = {d}\n", .{q1answer});

    const q2answer = try countSafe(
        allocator,
        "2.input",
        true,
    );
    std.debug.print("safe reports = {d}\n", .{q2answer});
}

fn isSafe(line: []i32) bool {
    var isAsc = true;
    var isDsc = true;
    var safe = true;

    var i: usize = 0;
    while (i < line.len - 1) : (i += 1) {
        const prev = line[i];
        const current = line[i + 1];
        const diff = prev - current;

        if (diff < 0) {
            isDsc = false;
        } else if (diff > 0) {
            isAsc = false;
        } else {
            isAsc = false;
            isDsc = false;
        }
        safe = safe and @abs(diff) <= 3;
    }

    return safe and (isAsc or isDsc);
}

// read the input file and construct the two arraylists
fn countSafe(
    allocator: Allocator,
    filename: []const u8,
    problem_dumper_enabled: bool,
) !u32 {
    // open the file
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());
    // accumulator variable
    var acc: u32 = 0;
    // read the first line
    var line = try reader.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 20);
    while (line) |current_line| {
        defer allocator.free(current_line);
        var seq = std.mem.splitSequence(u8, current_line, " ");

        var list = ArrayList(i32).init(allocator);
        defer list.deinit();

        while (seq.next()) |number| {
            const c = trimParseSigned(number) catch 0;
            list.append(c) catch return 0;
        }

        var safe = false;
        safe = isSafe(list.items);

        if (problem_dumper_enabled) {
            var i: usize = 0;
            inner: while (i < list.items.len) : (i += 1) {
                const new_arr = addSlices(
                    list.items[0..i],
                    list.items[i + 1 ..],
                    allocator,
                ) catch return 0;
                defer allocator.free(new_arr);

                safe = isSafe(new_arr);
                if (safe) break :inner;
            }
        }

        if (safe) {
            acc += 1;
        }

        // read the next line
        line = try reader.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 200);
    }
    return acc;
}

// heper func to concat two slices at runtime
fn addSlices(a: []i32, b: []i32, allocator: Allocator) ![]i32 {
    const len = a.len + b.len;
    var c = try allocator.alloc(i32, len);
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        c[i] = a[i];
    }
    i = 0;
    while (i < b.len) : (i += 1) {
        c[i + a.len] = b[i];
    }

    return c;
}

// helper method to trim a str containing a number and parse it to u32
pub fn trimParseSigned(str: []const u8) !i32 {
    const numStr = std.mem.trim(u8, str, " ");
    return try std.fmt.parseInt(i32, numStr, 10);
}
