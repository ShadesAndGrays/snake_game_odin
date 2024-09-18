package snake

import r1 "vendor:raylib"
import "core:math"
import "core:math/linalg"
import "core:fmt"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
Vec2i :: [2]int
Vec2f :: [2]f32
CANVAS_SIZE  :: GRID_WIDTH *CELL_SIZE
TICK_RATE :: 0.13
move_direction: Vec2i
tick_timer:f32 = TICK_RATE
MAX_SNAKE_LENGTH :: GRID_WIDTH*GRID_WIDTH
SNAKE_STARTING_LENGTH :: 3

snake: [MAX_SNAKE_LENGTH]Vec2i
snake_smooth: [MAX_SNAKE_LENGTH]Vec2f
snake_length:int
game_over: bool

food_pos:Vec2i
high_score: int

shake_timer:f32 
SHAKE_DURATION :: 2.0

place_food :: proc(){

    occupied:[GRID_WIDTH][GRID_WIDTH] bool
    for i in 0..<snake_length{
        snake_remaped := linalg.clamp(snake[i],Vec2i{0,0},Vec2i{GRID_WIDTH,GRID_WIDTH})
        occupied[snake_remaped.x][snake_remaped.y] = true
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
    snake_smooth[i] = {f32(snake[i].x),f32(snake[i].y)} 
    }
    game_over = false
    move_direction = {0,1}

}

start_shake :: proc(shake_time:f32){
    shake_timer = shake_time
}

update_shake :: proc(camera:^r1.Camera2D){
    if shake_timer <= 0{
        camera.offset = {0,0}
    }else{
    shake_timer -= TICK_RATE;
    camera.offset = { f32(r1.GetRandomValue(0,10)) ,f32(r1.GetRandomValue(1,10)) }
    }

}
main ::proc(){
    r1.SetConfigFlags({.VSYNC_HINT})
    r1.InitWindow(WINDOW_SIZE,WINDOW_SIZE,"Snake")
    r1.InitAudioDevice()
    game_pad:i32

    restart()
    food_sprite := r1.LoadTexture("assets/food.png")
    head_sprite := r1.LoadTexture("assets/head.png")
    body_sprite := r1.LoadTexture("assets/body.png")
    taile_sprite := r1.LoadTexture("assets/tail.png")

    eat_sound := r1.LoadSound("assets/eat.wav")
    crash_sound := r1.LoadSound("assets/crash.wav")
    r1.SetSoundVolume(eat_sound,1.5)
    r1.SetSoundVolume(crash_sound,1.5)

    game_music := r1.LoadMusicStream("music/Joshua McLean - Mountain Trials.mp3")
    game_music.looping = true
    r1.SetMusicVolume(game_music,0.4)
    r1.PlayMusicStream(game_music)


    place_food()

    camera := r1.Camera2D{
        zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
    }

    for !r1.WindowShouldClose(){

        r1.UpdateMusicStream(game_music)
        if (r1.IsKeyDown(.UP) || r1.IsGamepadButtonDown(game_pad,.RIGHT_FACE_UP)) && move_direction.y != 1{
            move_direction = {0,-1} 

        }else if (r1.IsKeyDown(.DOWN) || r1.IsGamepadButtonDown(game_pad,.RIGHT_FACE_DOWN) ) && move_direction.y != -1{
            move_direction = {0,1} 

        }else if (r1.IsKeyDown(.LEFT) || r1.IsGamepadButtonDown(game_pad,.RIGHT_FACE_LEFT) ) && move_direction.x != 1{
            move_direction = {-1,0} 

        }else if (r1.IsKeyDown(.RIGHT) || r1.IsGamepadButtonDown(game_pad,.RIGHT_FACE_RIGHT) ) && move_direction.x != -1{
            move_direction = {1,0} 
        }

        if game_over{

            r1.SetMusicPitch(game_music,0.4)
            if r1.IsKeyDown(.ENTER) || r1.IsGamepadButtonDown(game_pad,.RIGHT_TRIGGER_2){
                restart()
                r1.SetMusicPitch(game_music,1.0)
            }

        }else{
            tick_timer -= r1.GetFrameTime()
        }

        if tick_timer <= 0 {
            next_part_pos := snake[0]
            snake[0] += move_direction 

            if snake_smooth[0].x < -0.5{
                snake[0].x = GRID_WIDTH-1
                snake_smooth[0].x =  GRID_WIDTH-0.5 
            } else if snake_smooth[0].x > GRID_WIDTH-0.5{
                snake[0].x = 0 
                snake_smooth[0].x = -0.5 
            } 
            if snake_smooth[0].y < -0.5{
                snake[0].y = GRID_WIDTH-1 
                snake_smooth[0].y = GRID_WIDTH-0.5 
            } else if snake_smooth[0].y > GRID_WIDTH-0.5{
                snake[0].y = 0 
                snake_smooth[0].y = -0.5 
            }

            if snake[0] == food_pos{
                snake_length += 1
                r1.PlaySound(eat_sound)
                place_food()
            }

            for i in 1..<snake_length{
                cur_pos := snake[i] 
                if cur_pos == snake[0]{
                    game_over = true
                    start_shake(2.0)
                    r1.PlaySound(crash_sound)
                }
                snake[i] = next_part_pos
                if r1.Vector2Distance(
                    {f32(snake[i].x),f32(snake[i].y)},
                    {f32(cur_pos.x),f32(cur_pos.y)}
                    ) > 1{
                    snake_smooth[i] = {f32(snake[i].x),f32(snake[i].y)}

                }

                next_part_pos = cur_pos
            }

            tick_timer = TICK_RATE + tick_timer
        }
        for i in 0..<snake_length{
            new_pos :Vec2f= {f32(snake[i].x),f32(snake[i].y)}
            snake_smooth[i] = linalg.lerp(snake_smooth[i],new_pos,TICK_RATE)
        }

        update_shake(&camera)

        r1.BeginDrawing()
        r1.ClearBackground(r1.RAYWHITE)
        r1.BeginMode2D(camera)

        r1.DrawTextureV(food_sprite,{f32(food_pos.x),f32(food_pos.y)}*CELL_SIZE,r1.WHITE)

        for i := 0; i < snake_length; i+=1{
            part_sprite := body_sprite
            dir :Vec2f

            if i == 0{
                part_sprite = head_sprite
                dir = snake_smooth[i] - snake_smooth[i+1]
            } else if i == snake_length -1{
                part_sprite = taile_sprite
                dir = snake_smooth[i-1] - snake_smooth[i]
            } else {
                dir = snake_smooth[i-1] - snake_smooth[i]
            }
        rot := math.atan2(dir.y,dir.x) * math.DEG_PER_RAD
        source := r1.Rectangle{
            0,0,
            f32(part_sprite.width),
            f32(part_sprite.width)
        }
        dest := r1.Rectangle{
            snake_smooth[i].x*CELL_SIZE + 0.5 * CELL_SIZE,
            snake_smooth[i].y*CELL_SIZE + 0.5 * CELL_SIZE,
                CELL_SIZE,
                CELL_SIZE
        }
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
