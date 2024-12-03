const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Input = std.meta.Tuple(&.{ ArrayList(u32), ArrayList(u32) });
const stdout = std.io.getStdOut();

pub const InputError = error{MalformedInput};

pub fn main() !void {
    // get an allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    // read the input file and get the two columns from it.
    const input = try readInputParse(allocator);
    defer input[0].deinit();
    defer input[1].deinit();

    const firstCol = input[0].items;
    const secondCol = input[1].items;

    // solve the first question
    try firstQuestion(firstCol, secondCol);
    // solve the second question
    try secondQuestion(allocator, firstCol, secondCol);
}

// helper method to trim a str containing a number and parse it to u32
pub fn trimParseUnsigned(str: []const u8) !u32 {
    const numStr = std.mem.trim(u8, str, " ");
    return try std.fmt.parseUnsigned(u32, numStr, 10);
}

// read the input file and construct the two arraylists
fn readInputParse(allocator: Allocator) !Input {

    // two array lists to collect the numbers
    var firstList = ArrayList(u32).init(allocator);
    var secondList = ArrayList(u32).init(allocator);

    // open the file and pupulate the arraylists line by line
    const file = try std.fs.cwd().openFile("1.input", .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());

    var line = try reader.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 20);
    while (line) |current_line| {
        defer allocator.free(current_line);

        // split each line with 2 spaces
        var it = std.mem.splitSequence(u8, current_line, "  ");
        while (it.next()) |first| {
            const firstNum = try trimParseUnsigned(first);
            // append the first number
            try firstList.append(firstNum);
            if (it.next()) |second| {
                const secondNum = try trimParseUnsigned(second);
                // append the second number
                try secondList.append(secondNum);
            } else return InputError.MalformedInput;
        }

        // read the second line
        line = try reader.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', 20);
    }

    return .{
        firstList,
        secondList,
    };
}

// sort the arrays and accumulate the absolute value of the difference of
// the array elements starting from 0
fn firstQuestion(firstCol: []u32, secondCol: []u32) !void {
    std.mem.sort(u32, firstCol, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, secondCol, {}, comptime std.sort.asc(u32));
    var distance: u32 = 0;

    for (firstCol, secondCol) |fi, si| {
        var dif: u32 = undefined;
        if (fi >= si) {
            dif = fi - si;
        } else {
            dif = si - fi;
        }

        distance += dif;
    }

    try stdout.writer().print("Distance = {d}\n", .{distance});
}

fn secondQuestion(allocator: Allocator, firstCol: []u32, secondCol: []u32) !void {
    var similarity: u32 = 0;

    // iterate over the second col and construct a hasmap (num, number of occurence)
    var map = std.AutoArrayHashMap(u32, u32).init(allocator);
    defer map.deinit();

    for (secondCol) |num| {
        const v = map.get(num) orelse 0;
        try map.put(num, v + 1);
    }

    // iterate over the first array and increase the similarity
    for (firstCol) |num| {
        const v = map.get(num) orelse 0;
        similarity += (v * num);
    }

    try stdout.writer().print("Similarity = {d}\n", .{similarity});
}
