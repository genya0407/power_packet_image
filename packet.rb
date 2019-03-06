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
        if !height.nil?
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

def line_absolute(ctx, start, sink)
    ctx.save do
        dx = (sink.x - start.x)
        dy = (sink.y - start.y)
        length = Math.sqrt(dx**2 + dy**2)
        theta = Math.atan(dy/dx)
        ctx.move_to(start.x, start.y)
        ctx.rotate(theta)
        ctx.set_source_rgb(0,0,0)
        ctx.rel_line_to(length, 0)
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

def router_with_text(ctx, start, height)
    width = height
    ctx.save do
        ctx.translate(start.x - width/2, start.y - height/2)
        ctx.set_source_rgb(0,0,0)
        ctx.rectangle(0, 0, width, height)
        ctx.stroke
    end
    ctx.save do
        ctx.translate(start.x - width/2, start.y - 15)
        ctx.set_source_rgb(0,0,0)
        ctx.set_font_size(15)
        ctx.show_text("Router".encode('utf-8'))
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
