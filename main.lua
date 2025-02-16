function love.load()
    math.randomseed(os.time())
    
    -- Stałe gry
    BLOCK_SIZE = 30
    GRID_WIDTH = 10
    GRID_HEIGHT = 20
    GRID_OFFSET_X = 100
    GRID_OFFSET_Y = 50
    
    -- Kolory
    colors = {
        {0.27, 0.82, 0.95}, -- cyan (I)
        {0.92, 0.84, 0.14}, -- yellow (O)
        {0.58, 0.29, 0.79}, -- purple (T)
        {0.92, 0.47, 0.13}  -- orange (L)
    }
    
    -- Definicje tetromino
    shapes = {
        { -- I
            {{1, 1, 1, 1}},
            color = 1
        },
        { -- O
            {{1, 1}, {1, 1}},
            color = 2
        },
        { -- T
            {{0, 1, 0}, {1, 1, 1}},
            color = 3
        },
        { -- L
            {{1, 0}, {1, 0}, {1, 1}},
            color = 4
        }
    }
    
    -- Inicjalizacja gry
    function new_game()
        grid = {}
        for y = 1, GRID_HEIGHT do
            grid[y] = {}
            for x = 1, GRID_WIDTH do
                grid[y][x] = 0
            end
        end
        
        score = 0
        game_over = false
        spawn_piece()
        next_piece = get_random_piece()
    end
    
    function get_random_piece()
        local shape = shapes[math.random(#shapes)]
        return {
            shape = shape[1],
            color = colors[shape.color],
            rotation = 1
        }
    end
    
    function spawn_piece()
        current_piece = next_piece or get_random_piece()
        next_piece = get_random_piece()
        current_piece.x = math.floor(GRID_WIDTH/2 - #current_piece.shape[1]/2)
        current_piece.y = 1
        
        if check_collision(current_piece.x, current_piece.y, current_piece.shape) then
            game_over = true
        end
    end
    
    function rotate(piece)
        local new_shape = {}
        for y = 1, #piece.shape[1] do
            new_shape[y] = {}
            for x = 1, #piece.shape do
                new_shape[y][x] = piece.shape[#piece.shape - x + 1][y]
            end
        end
        return new_shape
    end
    
    function check_collision(x, y, shape)
        for py = 1, #shape do
            for px = 1, #shape[py] do
                if shape[py][px] ~= 0 then
                    local gx = x + px - 1
                    local gy = y + py - 1
                    if gx < 1 or gx > GRID_WIDTH or gy > GRID_HEIGHT then
                        return true
                    end
                    if gy >= 1 and grid[gy][gx] ~= 0 then
                        return true
                    end
                end
            end
        end
        return false
    end
    
    function merge_piece()
        for y = 1, #current_piece.shape do
            for x = 1, #current_piece.shape[y] do
                if current_piece.shape[y][x] ~= 0 then
                    local gy = current_piece.y + y - 1
                    local gx = current_piece.x + x - 1
                    if gy >= 1 then
                        grid[gy][gx] = current_piece.color
                    end
                end
            end
        end
    end
    
    function check_lines()
        local lines = 0
        for y = GRID_HEIGHT, 1, -1 do
            local full = true
            for x = 1, GRID_WIDTH do
                if grid[y][x] == 0 then
                    full = false
                    break
                end
            end
            
            if full then
                table.remove(grid, y)
                table.insert(grid, 1, {})
                for x = 1, GRID_WIDTH do
                    grid[1][x] = 0
                end
                lines = lines + 1
                y = y + 1
            end
        end
        
        if lines > 0 then
            score = score + lines * 100
        end
    end
    
    -- Sterowanie
    function love.keypressed(key)
        if game_over then
            new_game()
            return
        end
        
        if key == "left" then
            if not check_collision(current_piece.x - 1, current_piece.y, current_piece.shape) then
                current_piece.x = current_piece.x - 1
            end
        elseif key == "right" then
            if not check_collision(current_piece.x + 1, current_piece.y, current_piece.shape) then
                current_piece.x = current_piece.x + 1
            end
        elseif key == "down" then
            if not check_collision(current_piece.x, current_piece.y + 1, current_piece.shape) then
                current_piece.y = current_piece.y + 1
            end
        elseif key == "up" then
            local rotated = rotate(current_piece)
            if not check_collision(current_piece.x, current_piece.y, rotated) then
                current_piece.shape = rotated
            end
        elseif key == "space" then
            while not check_collision(current_piece.x, current_piece.y + 1, current_piece.shape) do
                current_piece.y = current_piece.y + 1
            end
            merge_piece()
            check_lines()
            spawn_piece()
        end
    end
    
    -- Automatyczne opadanie
    local fall_timer = 0
    function love.update(dt)
        if game_over then return end
        
        fall_timer = fall_timer + dt
        if fall_timer > 0.5 then
            if not check_collision(current_piece.x, current_piece.y + 1, current_piece.shape) then
                current_piece.y = current_piece.y + 1
            else
                merge_piece()
                check_lines()
                spawn_piece()
            end
            fall_timer = 0
        end
    end
    
    -- Rysowanie
    function love.draw()
        -- Siatka
        for y = 1, GRID_HEIGHT do
            for x = 1, GRID_WIDTH do
                if grid[y][x] ~= 0 then
                    love.graphics.setColor(grid[y][x])
                    love.graphics.rectangle("fill", 
                        (x-1)*BLOCK_SIZE + GRID_OFFSET_X,
                        (y-1)*BLOCK_SIZE + GRID_OFFSET_Y,
                        BLOCK_SIZE-1, BLOCK_SIZE-1)
                end
            end
        end
        
        -- Aktualny klocek
        love.graphics.setColor(current_piece.color)
        for y = 1, #current_piece.shape do
            for x = 1, #current_piece.shape[y] do
                if current_piece.shape[y][x] ~= 0 then
                    love.graphics.rectangle("fill",
                        (current_piece.x + x - 2)*BLOCK_SIZE + GRID_OFFSET_X,
                        (current_piece.y + y - 2)*BLOCK_SIZE + GRID_OFFSET_Y,
                        BLOCK_SIZE-1, BLOCK_SIZE-1)
                end
            end
        end
        
        -- Następny klocek
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Następny:", 450, 100)
        for y = 1, #next_piece.shape do
            for x = 1, #next_piece.shape[y] do
                if next_piece.shape[y][x] ~= 0 then
                    love.graphics.setColor(next_piece.color)
                    love.graphics.rectangle("fill",
                        450 + (x-1)*BLOCK_SIZE,
                        150 + (y-1)*BLOCK_SIZE,
                        BLOCK_SIZE-1, BLOCK_SIZE-1)
                end
            end
        end
        
        -- Wynik
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Wynik: "..score, 450, 300)
        
        -- Game Over
        if game_over then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("GAME OVER", 300, 300)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Naciśnij dowolny klawisz", 250, 350)
        end
    end
    
    new_game()
end