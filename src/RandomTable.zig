const std = @import("std");

pub fn RandomTable(comptime Item: type, comptime Weight: type) type {
    return struct {
        const Self = @This();

        items: std.ArrayList(Item),
        weights: std.ArrayList(Weight),
        total_weight: Weight,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .items = std.ArrayList(Item).init(allocator),
                .weights = std.ArrayList(Weight).init(allocator),
                .total_weight = 0,
            };
        }

        pub fn deinit(self: Self) void {
            self.items.deinit();
            self.weights.deinit();
        }

        pub fn add(self: *Self, item: Item, weight: Weight) !void {
            try self.items.append(item);
            try self.weights.append(weight);
            self.total_weight += weight;
        }

        pub fn get(self: Self, random: std.rand) Item {
            var accumulator = random.intRangeAtMost(Weight, 1, self.total_weight);

            for (self.items.items, 0..self.items.items.len) |item, i| {
                const weight = self.weights.items[i];

                if (accumulator <= weight) return item;
                accumulator -= weight;
            }

            unreachable;
        }
    };
}
