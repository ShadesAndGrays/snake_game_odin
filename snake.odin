package snake

import r1 "vendor:raylib"
import "core:math"
import "core:fmt"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
Vec2i :: [2]int
CANVAS_SIZE  :: GRID_WIDTH *CELL_SIZE
TICK_RATE :: 0.13
move_direction: Vec2i
tick_timer:f32 = TICK_RATE
MAX_SNAKE_LENGTH :: GRID_WIDTH*GRID_WIDTH
SNAKE_STARTING_LENGTH :: 3

snake: [MAX_SNAKE_LENGTH]Vec2i
snake_length:int
game_over: bool

food_pos:Vec2i
high_score: int

place_food :: proc(){
    occupied:[GRID_WIDTH][GRID_WIDTH] bool
    for i in 0..<snake_length{
        occupied[snake[i].x][snake[i].y] = true
    }
    free_cells := make ([dynamic]Vec2i,context.temp_allocator)
    for x in 0..<GRID_WIDTH{
        for y in 0..<GRID_WIDTH{
            if !occupied[x][y]{
                append(&free_cells,Vec2i{x,y})
            }
        }
    }
    if len(free_cells) > 0{
        random_cell_index := r1.GetRandomValue(0,i32(len(free_cells)-1))
        food_pos = free_cells[random_cell_index]
    }

}

restart :: proc(){

    if high_score < snake_length - SNAKE_STARTING_LENGTH{
        high_score = snake_length - SNAKE_STARTING_LENGTH
    }
    snake_length = SNAKE_STARTING_LENGTH

    start_head_position :Vec2i = {GRID_WIDTH/2,GRID_WIDTH/2}
    for i:= 0; i < snake_length; i +=1{
    snake[i] = start_head_position - {0,i};
    }
    game_over = false
    move_direction = {0,1}

}

main ::proc(){
    r1.SetConfigFlags({.VSYNC_HINT})
    r1.InitWindow(WINDOW_SIZE,WINDOW_SIZE,"Snake")
    r1.InitAudioDevice()

    restart()
    food_sprite := r1.LoadTexture("assets/food.png")
    head_sprite := r1.LoadTexture("assets/head.png")
    body_sprite := r1.LoadTexture("assets/body.png")
    taile_sprite := r1.LoadTexture("assets/tail.png")

    eat_sound := r1.LoadSound("assets/eat.wav")
    crash_sound := r1.LoadSound("assets/crash.wav")
    place_food()

    camera := r1.Camera2D{
        zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
    }

    for !r1.WindowShouldClose(){
        if r1.IsKeyDown(.UP) && move_direction.y != 1{
            move_direction = {0,-1} 

        }else if r1.IsKeyDown(.DOWN) && move_direction.y != -1{
            move_direction = {0,1} 

        }else if r1.IsKeyDown(.LEFT) && move_direction.x != 1{
            move_direction = {-1,0} 

        }else if r1.IsKeyDown(.RIGHT) && move_direction.x != -1{
            move_direction = {1,0} 
        }

        if game_over{
            if r1.IsKeyDown(.ENTER){
                restart()
            }

        }else{
            tick_timer -= r1.GetFrameTime()
        }

        if tick_timer <= 0 {
            next_part_pos := snake[0]
            snake[0] += move_direction 

            if snake[0].x < 0{
                snake[0].x = GRID_WIDTH-1
            } else if snake[0].x >= GRID_WIDTH{
                snake[0].x = 0 
            } 
            if snake[0].y < 0{
                snake[0].y = GRID_WIDTH-1 
            } else if snake[0].y >= GRID_WIDTH{
                snake[0].y = 0 
            }

            if snake[0] == food_pos{
                snake_length += 1
                r1.PlaySound(eat_sound)
                place_food()
            }

            for i in 1..<snake_length{
                cur_pos := snake[i] 
                if cur_pos == snake[0]{
                    game_over  = true
                    r1.PlaySound(crash_sound)
                }
                snake[i] = next_part_pos
                next_part_pos = cur_pos
            }

            tick_timer = TICK_RATE + tick_timer
        }


        r1.BeginDrawing()
        r1.ClearBackground(r1.RAYWHITE)
        r1.BeginMode2D(camera)

        r1.DrawTextureV(food_sprite,{f32(food_pos.x),f32(food_pos.y)}*CELL_SIZE,r1.WHITE)

        for i := 0; i < snake_length; i+=1{
            part_sprite := body_sprite
            dir :Vec2i

            if i == 0{
                part_sprite = head_sprite
                dir = snake[i] - snake[i+1]
            } else if i == snake_length -1{
                part_sprite = taile_sprite
                dir = snake[i-1] - snake[i]
            } else {
                dir = snake[i-1] - snake[i]
            }
        rot := math.atan2(f32(dir.y),f32(dir.x)) * math.DEG_PER_RAD
        source := r1.Rectangle{
            0,0,
            f32(part_sprite.width),
            f32(part_sprite.width)
        }
        dest := r1.Rectangle{
            f32(snake[i].x)*CELL_SIZE + 0.5 * CELL_SIZE,
            f32(snake[i].y)*CELL_SIZE + 0.5 * CELL_SIZE,
                CELL_SIZE,
                CELL_SIZE
        }
        // r1.DrawTextureEx(part_sprite,{f32(snake[i].x),f32(snake[i].y)}*CELL_SIZE,rot,1,r1.WHITE)
        r1.DrawTexturePro(
            part_sprite,
            source,
            dest,
            {CELL_SIZE,CELL_SIZE} * 0.5,
            rot,
            r1.WHITE
            )
        }

        score := snake_length - 3
        score_str := fmt.ctprintf("Score: %v",score)
        r1.DrawText(score_str,4,CANVAS_SIZE - 14,10,r1.BLACK)

        if game_over{
            r1.DrawText("Game Over",4,4,25,r1.RED);
            r1.DrawText("Press enter to restart",4,30,15,r1.BLACK);
            if high_score < score{
               high_score_str := fmt.ctprintf("High Score:: %v",score)
               r1.DrawText("New High Score",4,70,30,r1.BLACK);
               r1.DrawText(high_score_str,4,100,30,r1.BLACK);
            }else{
               high_score_str := fmt.ctprintf("High Score:: %v",high_score)
               r1.DrawText(high_score_str,4,70,30,r1.BLACK);
            }

        }

        r1.EndMode2D()
        r1.EndDrawing()

        free_all(context.temp_allocator)
    }
    r1.UnloadTexture(head_sprite)
    r1.UnloadTexture(food_sprite)
    r1.UnloadTexture(body_sprite)
    r1.UnloadTexture(taile_sprite)


    r1.CloseWindow()
    r1.CloseAudioDevice()

}
