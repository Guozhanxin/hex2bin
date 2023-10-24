/// hex2bin
/// Author:  @flyboy
/// Ref: https://blog.csdn.net/lone5moon/article/details/117792834
///
const std = @import("std");

const RecType = enum(u8) {
    data = '0',
    end_of_file = '1',
    ext_seg_addr = '2',
    start_seg_addr = '3',
    ext_linear_addr = '4',
    entry = '5',
};

const BUF_SIZE = 1024;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    std.log.debug("arg: {s},{d}\n", .{ args[1], args.len });

    var input_file: []u8 = undefined;
    if (args.len > 1) {
        input_file = args[1];
    } else {
        std.debug.print("{s}\n", .{"Usage: ./hex2bin xxx.hex"});
        return;
    }
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var addr_offset: u32 = 0;
    var addr: u32 = 0;
    var next_addr: u32 = 0;
    var bin_file: std.fs.File = undefined;
    var file_is_opened: bool = false;
    var buf: [BUF_SIZE]u8 = undefined;
    var out_buf: [BUF_SIZE]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        switch (line[8]) {
            @intFromEnum(RecType.data) => {
                var bin_buf: []u8 = undefined;
                bin_buf = try std.fmt.hexToBytes(&out_buf, line[9 .. line.len - 3]);

                var addr_buf: [BUF_SIZE]u8 = undefined;
                var addr_list: []u8 = undefined;
                addr_list = try std.fmt.hexToBytes(&addr_buf, line[3..7]);

                addr = addr_offset + try parseU32(line[3..7]);
                if ((file_is_opened == false) or (addr != next_addr)) {
                    std.log.debug("{s}\n", .{"addr error!"});
                    var file_name_buf: [512]u8 = undefined;
                    var file_name = try std.fmt.bufPrint(&file_name_buf, "{s}_0x{x}.bin", .{ "rtthread", addr });
                    std.debug.print("=> {s}\n", .{file_name});
                    //open file and write bin data to rtthread.bin
                    bin_file = try std.fs.cwd().createFile(file_name, .{});
                    file_is_opened = true;
                }

                const write_size: u32 = @intCast(try bin_file.write(bin_buf));
                next_addr = addr + write_size;

                std.log.debug("0x{X:0>8}", .{addr});
                std.log.debug("addr:{x}, {X}\n", .{
                    std.fmt.fmtSliceHexLower(addr_list), std.fmt.fmtSliceHexUpper(bin_buf),
                });
            },
            @intFromEnum(RecType.end_of_file) => {
                std.log.debug("{s}\n", .{"end file"});
            },
            @intFromEnum(RecType.ext_seg_addr) => {
                var tmp: u32 = try parseU32(line[9 .. line.len - 3]);
                addr_offset = tmp << 4;
                std.log.debug("ext_seg_addr: {s}, addr_offset: {x}\n", .{ line[9 .. line.len - 3], addr_offset });
                if (addr == 0) {
                    next_addr = addr_offset;
                }
            },
            @intFromEnum(RecType.start_seg_addr) => {
                std.log.debug("start_seg_addr: {s}\n", .{line[9 .. line.len - 3]});
            },
            @intFromEnum(RecType.ext_linear_addr) => {
                var tmp: u32 = try parseU32(line[9 .. line.len - 3]);
                addr_offset = tmp << 16;
                std.log.debug("ext_linear_addr: {s}, addr_offset: {x}\n", .{ line[9 .. line.len - 3], addr_offset });
                if (addr == 0) {
                    next_addr = addr_offset;
                }
            },
            @intFromEnum(RecType.entry) => {
                std.log.debug("entry: {s}\n", .{line[9 .. line.len - 3]});
            },
            else => {
                std.log.debug("{s}", .{"6"});
            },
        }
    }
}

fn parseU32(input: []u8) !u32 {
    var tmp: u32 = 0;
    for (input) |c| {
        const digit = try std.fmt.charToDigit(c, 16);
        tmp = tmp * 16 + @as(u32, digit);
    }
    return tmp;
}
