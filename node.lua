gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

util.resource_loader{
    "fontregular.ttf",
    "fontbold.ttf",
    "cryptocoins.ttf",
}

local json = require "json"

local background_image = resource.load_image("background.png")
local row_color = resource.create_colored_texture(1, 1, 1, 0.1)
local process_bar_color = resource.create_colored_texture(1, 1, 1, 1)

local CONFIG = json.decode(resource.load_file("config.json"))
local ROWS = json.decode(resource.load_file("prices.json"))
local SETTINGS = json.decode(resource.load_file("settings.json"))
local COINS = json.decode(resource.load_file("cryptocoins.json"))

-- loading resources should only be done when necessary
util.json_watch("config.json", function(data)
    CONFIG = data
    background_image = resource.load_image(data.background_image.asset_name)
    row_color = resource.create_colored_texture(data.row_color.r, data.row_color.g, data.row_color.b, data.row_opacity/100)
end)

util.json_watch("prices.json", function(data)
    ROWS = data
end)

util.json_watch("settings.json", function(data)
    SETTINGS = data
end)

function roundToNthDecimal(num, n)
  local mult = 10^(n or 0)
  return math.floor(num * mult + 0.5) / mult
end

function toNumber(number)
    return number+0
end

function textPositionFromLeft(text, size, spacing)
    if spacing < 0 then
        return WIDTH-SETTINGS.block_margin_right-SETTINGS.block_padding_right-fontbold:width(text, size)
    else
        return SETTINGS.block_margin_left+SETTINGS.block_padding_left+spacing
    end
end

function drawTitles()
    for index, column in pairs(SETTINGS.header_columns) do
        title_left_position = textPositionFromLeft(column.text, SETTINGS.header_text_size, column.spacing)
        fontbold:write(title_left_position, SETTINGS.header_margin_top, column.text, SETTINGS.header_text_size, CONFIG.title_color.r, CONFIG.title_color.g, CONFIG.title_color.b, CONFIG.title_color.a)
    end
end

function drawRowBackground(index)
    local position_top = SETTINGS.block_top_start+SETTINGS.block_height*(index-1)+SETTINGS.block_margin_top*(index-1)
    row_color:draw(SETTINGS.block_margin_left, position_top, WIDTH-SETTINGS.block_margin_right, position_top+SETTINGS.block_height, 1)
end

function drawSimpleCell(text, row, column, color)
    local color = color or CONFIG.text_color
    local position_left = textPositionFromLeft(text, SETTINGS.block_text_size, column.spacing)
    local position_top = (SETTINGS.block_top_start+SETTINGS.block_height*(row-1)+SETTINGS.block_margin_top*(row-1)+SETTINGS.block_height/2)-SETTINGS.block_text_size/2
    fontregular:write(position_left, position_top, text, SETTINGS.block_text_size, color.r, color.g, color.b, color.a)
end

function drawMultilineCell(lines, row, column, color)
    local color = color or CONFIG.text_color
    local total_height = #lines*SETTINGS.block_text_size
    local position_top_start = (SETTINGS.block_top_start+SETTINGS.block_height*(row-1)+SETTINGS.block_margin_top*(row-1)+SETTINGS.block_height/2)-total_height/2

    for index, line in pairs(lines) do
        local position_left = textPositionFromLeft(line, SETTINGS.block_text_size, column.spacing)
        local position_top = position_top_start+SETTINGS.block_text_size*(index-1)
        fontregular:write(position_left, position_top, line, SETTINGS.block_text_size, color.r, color.g, color.b, color.a)
    end
end

function drawIcon(symbol, row, column, color)
    local color = color or CONFIG.text_color
    local char = COINS[symbol]

    if char == nil then
        return
    end

    local position_top = (SETTINGS.block_top_start+SETTINGS.block_height*(row-1)+SETTINGS.block_margin_top*(row-1)+SETTINGS.block_height/2)-SETTINGS.block_text_size/2
    local position_left = SETTINGS.block_margin_left+SETTINGS.block_padding_left+column.spacing
    cryptocoins:write(position_left, position_top, char, SETTINGS.block_text_size, color.r, color.g, color.b, color.a)
end

function drawBoldCell(text, row, column, color)
    local color = color or CONFIG.text_color
    local position_left = textPositionFromLeft(text, SETTINGS.block_large_text_size, column.spacing)
    local position_top = (SETTINGS.block_top_start+SETTINGS.block_height*(row-1)+SETTINGS.block_margin_top*(row-1)+SETTINGS.block_height/2)-SETTINGS.block_large_text_size/2
    fontbold:write(position_left, position_top, text, SETTINGS.block_large_text_size, color.r, color.g, color.b, color.a)
end

function drawRows()
    for index, row in pairs(ROWS) do
        drawRowBackground(index)
        drawSimpleCell(row.rank, index, SETTINGS.header_columns[1])
        drawIcon(row.symbol, index, SETTINGS.header_columns[2])
        drawSimpleCell(row.symbol.."/EUR", index, SETTINGS.header_columns[3])
        drawMultilineCell({"1h: "..row.percent_change_1h, "1d: "..row.percent_change_24h, "7d: "..row.percent_change_7d}, index, SETTINGS.header_columns[4])

        if toNumber(row.percent_change_1h) > 0 then
            drawBoldCell(roundToNthDecimal(row.price_eur, 2), index, SETTINGS.header_columns[5], SETTINGS.up_trend_color)
        else
            drawBoldCell(roundToNthDecimal(row.price_eur, 2), index, SETTINGS.header_columns[5], SETTINGS.down_trend_color)
        end
    end
end

function node.render()
    gl.clear(0, 0, 0, 1)

    -- draw background
    background_image:draw(0, 0, WIDTH, HEIGHT)

    -- content
    drawTitles()
    drawRows()


    --[=====[
    -- draw blocks
    for i = 0,block_count-1,1
    do
        block_top = block_padding_top+i*block_height+i*block_spacing
        text_top = block_top+block_height/2-text_size/2
        price = roundToNthDecimal(blocks[i+1][1]["price_eur"], 2)

        price_width = fontbold:width(price, 80)
        price_x = WIDTH-block_padding_right-price_width-50

        block:draw(block_padding_left, block_top, WIDTH-block_padding_right, block_top+block_height, 1)
        fontregular:write(block_padding_left+50, text_top, blocks[i+1][1]["rank"], text_size, 1, 1, 1, 1)
        fontregular:write(400, text_top, blocks[i+1][1]["symbol"].."/EUR", text_size, 1, 1, 1, 1)

        fontregular:write(950, block_top+25, "1h: "..blocks[i+1][1]["percent_change_1h"], 50, 1, 1, 1, 1)
        fontregular:write(950, block_top+75, "1d: "..blocks[i+1][1]["percent_change_24h"], 50, 1, 1, 1, 1)
        fontregular:write(950, block_top+125, "7d: "..blocks[i+1][1]["percent_change_7d"], 50, 1, 1, 1, 1)


        if tonumber(blocks[i+1][1]["percent_change_1h"]) > 0 then
            fontbold:write(price_x, block_top+block_height/2-40, price, 80, 0.55, 1, 0.5, 1)
        else
            fontbold:write(price_x, block_top+block_height/2-40, price, 80, 1, 0.5, 0.5, 1)
        end

        unix_time = os.time(os.date("!*t"))
        last_updated = blocks[i+1][1]["last_updated"]
        time_diff = unix_time-last_updated
        bar_width = 300-time_diff
        if tonumber(bar_width) > 0 then
            update_bar:draw(400, text_top+text_size, 400+bar_width, text_top+text_size+3, 1)
        end


    end
    --]=====]

end
