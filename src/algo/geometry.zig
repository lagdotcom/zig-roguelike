pub fn get_distance(ax: i16, ay: i16, bx: i16, by: i16) i16 {
    const x_dist = @abs(ax - bx);
    const x_dist2 = x_dist * x_dist;

    const y_dist = @abs(ay - by);
    const y_dist2 = y_dist * y_dist;

    return @intFromFloat(@sqrt(@as(f16, @floatFromInt(y_dist2 + x_dist2))));
}
