require 'cairo'

def rel_rectangle(ctx, w, h)
    cur_x, cur_y = ctx.current_point
    ctx.rectangle(cur_x, cur_y, w, h)
end

class Cairo::Context
    alias :old_save :save
    def save(&block)
        point = self.current_point
        res = self.old_save(&block)
        self.move_to(point[0], point[1])
        return res
    end
end

PACKET_MARGIN_RATIO = 0.5
def line_with_packet(ctx, colors, length, height)
    if !colors.is_a?(Array)
        colors = [colors]
    end
    line_end_point = nil

    ctx.save do
        # power line
        ctx.save do
            ctx.set_source_rgb(0,0,0) # black
            ctx.rel_line_to(length, 0)
            line_end_point = ctx.current_point
            ctx.stroke
        end

        # packets
        packet_height = height
        packet_width = height
        left_line = packet_width * 1
        right_line = packet_width * 1
        packet_count = ((length - left_line - right_line) / (packet_width * (1 + PACKET_MARGIN_RATIO))).floor

        ctx.rel_move_to(left_line, -height)
        for i in 1..packet_count
            color = colors[i%colors.size]
            ctx.save do
                ctx.set_source_rgb(color.r, color.g, color.b)
                rel_rectangle(ctx, packet_width, packet_height)
                ctx.fill
            end

            ctx.save do
                ctx.set_source_rgb(0,0,0) # black
                rel_rectangle(ctx, packet_width, packet_height)
                ctx.stroke
            end

            dx = packet_width * (1 + PACKET_MARGIN_RATIO)
            ctx.rel_move_to(dx, 0.0)
        end
    end

    return line_end_point
end

def line_with_packet_absolute(ctx, colors, start, sink, height)
    ctx.save do
        dx = (sink.x - start.x)
        dy = (sink.y - start.y)
        length = Math.sqrt(dx**2 + dy**2)
        theta = Math.atan(dy/dx)
        ctx.move_to(start.x, start.y)
        ctx.rotate(theta)
        line_with_packet(ctx, colors, length, height)
    end
end

SOURCE_WIDTH_RATIO = 1.5
def source_or_consumer(ctx, color, start, height)
    width = height * SOURCE_WIDTH_RATIO
    ctx.save do
        ctx.set_source_rgb(color.r, color.g, color.b)
        ctx.rectangle(start.x - width/2, start.y - height/2, width, height)
        ctx.fill
    end

    ctx.save do
        ctx.set_source_rgb(0,0,0)
        ctx.rectangle(start.x - width/2, start.y - height/2, width, height)
        ctx.stroke
    end

    yield
end

def source(ctx, color, start, height)
    source_or_consumer(ctx, color, start, height) do
        ctx.save do
            fp = start.up(height).left(height * SOURCE_WIDTH_RATIO).up(10).left(20)
            ctx.move_to(fp.x, fp.y)
            ctx.set_source_rgb(0,0,0)
            ctx.set_font_size(20)
            ctx.show_text("Source".encode('utf-8'))
        end
    end
end

def consumer(ctx, color, start, height)
    source_or_consumer(ctx, color, start, height) do
        ctx.save do
            fp = start.up(height).left(height * SOURCE_WIDTH_RATIO).up(10)#.left(40)
            ctx.move_to(fp.x, fp.y)
            ctx.set_source_rgb(0,0,0)
            ctx.set_font_size(20)
            ctx.show_text("Load".encode('utf-8'))
        end
    end
end

def router(ctx, start, height)
    ctx.save do
        width = height
        ctx.translate(start.x - width/2, start.y - height/2)
        ctx.set_source_rgb(0,0,0)
        ctx.rectangle(0, 0, width, height)
        ctx.stroke
    end
end

Point = Struct.new(:x, :y) do
    def rel(dx, dy)
        self.class.new(x+dx, y+dy)
    end

    def up(l); rel(0, -l/2) end
    def down(l); rel(0, l/2) end
    def right(l); rel(l/2, 0) end
    def left(l); rel(-l/2, 0) end
end
Color = Struct.new(:r, :g, :b)

packet_color1 = Color.new(0.5, 0  , 0)
packet_color2 = Color.new(0  , 0.5, 0)
packet_height = 10
node_height = 30
width = 500
height = 300

format = Cairo::FORMAT_ARGB32
surface = Cairo::ImageSurface.new(format, width, height + 50)
ctx = Cairo::Context.new(surface)

ctx.fill do
    ctx.set_source_rgb(1,1,1)
    ctx.rectangle(0.0, 0.0, width, height + 50) # background
end

ctx.save do
    ctx.set_source_rgb(0,0,0)
    ctx.move_to(width/5*2 - 30, 40)
    ctx.set_font_size(20)
    ctx.show_text("Router network")
end

ctx.translate(0, 50)

s1 = Point.new(50, height/10*2)
s2 = Point.new(50, height/10*8)
source(ctx, packet_color1, s1, node_height)
source(ctx, packet_color2, s2, node_height)

c1 = Point.new(width-50, height/10*2)
c2 = Point.new(width-50, height/10*8)
consumer(ctx, packet_color2, c1, node_height)
consumer(ctx, packet_color1, c2, node_height)

ctx.save do
    node_width = node_height * SOURCE_WIDTH_RATIO
    ctx.move_to(s1.x + node_width/2, s1.y)
    ctx.rotate(Math::PI/4)
    line_with_packet(ctx, packet_color1, 120, packet_height)
end

line_end_point = nil
ctx.save do
    node_width = node_height * SOURCE_WIDTH_RATIO
    ctx.move_to(s2.x + node_width/2, s2.y)
    ctx.rotate(-Math::PI/4)
    line_end_point = line_with_packet(ctx, packet_color2, 120, packet_height)
    ctx.move_to(line_end_point[0], line_end_point[1])
    ctx.rotate(Math::PI/4)
    line_end_point = ctx.current_point
end

ctx.save do
    ctx.translate(width/2, height/2)

    ctx.save do
        ctx.stroke do
            ctx.set_source_rgb(0,0,0)
            ctx.arc(0, 0, height * 0.9 / 2, 0, 2*Math::PI)
            ctx.set_dash([5.0, 5.0])
        end
    end
end

ctx.save do
    power_line_end = Point.new(line_end_point[0] + node_height/2, height/2)

    pt1 = power_line_end
    router(ctx, pt1, node_height)
    pt2 = Point.new(pt1.x + width/10*1.5, pt1.y - height/5).left(20)
    router(ctx, pt2, node_height)
    pt3 = Point.new(pt1.x + width/10 * 2, pt1.y + height/5).left(20)
    router(ctx, pt3, node_height)
    pt4 = Point.new(pt2.x + width/10*2, pt2.y).left(20)
    router(ctx, pt4, node_height)

    line_with_packet_absolute(
        ctx, [packet_color1, packet_color2],
        pt1.rel(0, -node_height/2), pt2.rel(-node_height/2, 0), packet_height)
    line_with_packet_absolute(
        ctx, [packet_color2, packet_color1],
        pt1.rel(node_height/2, 0), pt3.rel(-node_height/2, 0), packet_height)
    line_with_packet_absolute(
        ctx, packet_color2,
        pt2.rel(node_height/2, 0), pt4.rel(-node_height/2, 0), packet_height)
    line_with_packet_absolute(
        ctx, packet_color1,
        pt2.down(node_height), pt3.up(node_height), packet_height
    )
    line_with_packet_absolute(
        ctx, packet_color2,
        pt3.up(node_height), pt4.down(node_height), packet_height
    )
    line_with_packet_absolute(
        ctx, packet_color1,
        pt3.rel(node_height/2, 0), c2.rel(-node_height * SOURCE_WIDTH_RATIO / 2, 0), packet_height
    )
    line_with_packet_absolute(
        ctx, packet_color2,
        pt4.rel(node_height/2, 0), c1.rel(-node_height * SOURCE_WIDTH_RATIO / 2, 0), packet_height
    )
end

surface.write_to_png("power_packet.png");