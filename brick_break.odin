package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "vendor:raylib"

HEIGHT :: 800
WIDTH :: 1200

PLAYER_HEIGHT :: 10
PLAYER_WIDTH :: 50
PLAYER_START_X :: WIDTH / 2 - PLAYER_WIDTH / 2
PLAYER_START_Y :: HEIGHT - 20
PLAYER_SPEED :: f32(6)

BALL_START_X :: PLAYER_START_X + PLAYER_WIDTH / 2 - 7.5
BALL_START_Y :: PLAYER_START_Y - 15
BALL_VELOCITY :: 3

BRICK_HEIGHT :: 40
BRICK_WIDTH :: 80

colors: [18]raylib.Color = {
	raylib.YELLOW,
	raylib.GOLD,
	raylib.ORANGE,
	raylib.PINK,
	raylib.RED,
	raylib.MAROON,
	raylib.GREEN,
	raylib.LIME,
	raylib.DARKGREEN,
	raylib.SKYBLUE,
	raylib.BLUE,
	raylib.DARKBLUE,
	raylib.PURPLE,
	raylib.VIOLET,
	raylib.DARKPURPLE,
	raylib.BEIGE,
	raylib.BROWN,
	raylib.DARKBROWN,
}

Brick :: struct {
	x:     f32,
	y:     f32,
	color: raylib.Color,
}

Ball :: struct {
	rec:      raylib.Rectangle,
	movement: raylib.Vector2,
}

State :: struct {
	rotation:    f32,
	ball:        Ball,
	ball_line:   [2]raylib.Vector2,
	player:      raylib.Rectangle,
	bricks:      [dynamic]Brick,
	game_over:   bool,
	game_start:  bool,
	game_paused: bool,
}

left_wall: raylib.Rectangle = raylib.Rectangle {
	x      = WIDTH * -1,
	y      = 0,
	height = HEIGHT,
	width  = WIDTH,
}

right_wall: raylib.Rectangle = raylib.Rectangle {
	x      = WIDTH,
	y      = 0,
	height = HEIGHT,
	width  = WIDTH,
}

ceiling: raylib.Rectangle = raylib.Rectangle {
	x      = 0,
	y      = HEIGHT * -1,
	height = HEIGHT,
	width  = WIDTH,
}

walls: []raylib.Rectangle = {left_wall, right_wall, ceiling}

main :: proc() {
	raylib.InitWindow(WIDTH, HEIGHT, "speed run")
	raylib.SetTargetFPS(60)

	state := State{}
	init_game_state(&state)

	for !raylib.WindowShouldClose() {

		if raylib.IsKeyPressed(raylib.KeyboardKey.P) {
			state.game_paused = !state.game_paused
		}

		if state.game_start &&
		   (raylib.IsKeyDown(raylib.KeyboardKey.RIGHT) ||
				   raylib.IsKeyDown(raylib.KeyboardKey.LEFT)) {
			state.game_start = false
			direction := f32(rand.int_max(90) + 45)
			angle := linalg.to_radians(direction)
			state.ball.movement.x = -BALL_VELOCITY * math.cos_f32(angle)
			state.ball.movement.y = -BALL_VELOCITY * math.sin_f32(angle)

			state.ball.movement.y = -5
		}

		if (state.game_over || state.game_paused) && raylib.IsKeyPressed(raylib.KeyboardKey.R) {
			init_game_state(&state)
		}

		if !state.game_over && !state.game_start && !state.game_paused {

			player_speed := raylib.Vector2{}
			if raylib.IsKeyDown(raylib.KeyboardKey.RIGHT) {
				player_speed.x = PLAYER_SPEED
				state.player.x += PLAYER_SPEED
			}

			if raylib.IsKeyDown(raylib.KeyboardKey.LEFT) {
				player_speed.x = -PLAYER_SPEED
				state.player.x -= PLAYER_SPEED
			}

			if (state.player.x < 0) {
				state.player.x = 0
			}

			if (state.player.x > WIDTH - PLAYER_WIDTH) {
				state.player.x = WIDTH - PLAYER_WIDTH
			}

			state.ball.rec.x += state.ball.movement.x
			state.ball.rec.y += state.ball.movement.y

			hit := false

			if raylib.CheckCollisionRecs(state.ball.rec, state.player) {
				set_ball_position_and_direction(&state.ball, state.player, player_speed)
				hit = true
			}

			if !hit {
				for i := 0; i < len(state.bricks); i += 1 {
					brick := state.bricks[i]
					brick_rec := raylib.Rectangle {
						x      = brick.x,
						y      = brick.y,
						height = BRICK_HEIGHT,
						width  = BRICK_WIDTH,
					}

					if raylib.CheckCollisionRecs(state.ball.rec, brick_rec) {
						set_ball_position_and_direction(&state.ball, brick_rec)
						unordered_remove(&state.bricks, i)

						hit = true
						break
					}
				}
			}

			if !hit {
				for i := 0; i < len(walls); i += 1 {
					if raylib.CheckCollisionRecs(state.ball.rec, walls[i]) {
						set_ball_position_and_direction(&state.ball, walls[i])
						hit = true
					}
				}

			}

			if state.ball.rec.y > HEIGHT {
				state.game_over = true
			}
		}

		draw(state)
	}

	raylib.CloseWindow()
}

inti_bricks :: proc(bricks: ^[dynamic]Brick) {
	clear(bricks)

	colori := 0
	for y := BRICK_HEIGHT; y < HEIGHT / 2; y += BRICK_HEIGHT * 2 {
		for x := BRICK_WIDTH; x < WIDTH; x += BRICK_WIDTH * 2 {
			colori += 1
			if (colori > len(colors) - 1) {
				colori = 0
			}
			append(bricks, Brick{x = f32(x), y = f32(y), color = colors[colori]})
		}
	}
}

init_game_state :: proc(state: ^State) {
	inti_bricks(&state.bricks)
	state.game_start = true
	state.game_over = false
	state.player = raylib.Rectangle {
		x      = PLAYER_START_X,
		y      = PLAYER_START_Y,
		height = PLAYER_HEIGHT,
		width  = PLAYER_WIDTH,
	}
	state.ball = Ball {
		rec = raylib.Rectangle{x = BALL_START_X, y = BALL_START_Y, height = 15, width = 15},
		movement = raylib.Vector2{0, 0},
	}
}

draw :: proc(state: State) {

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.WHITE)

	raylib.DrawRectangleRec(state.ball.rec, raylib.RED)

	raylib.DrawRectangleRec(state.player, raylib.BLUE)

	for i := 0; i < len(state.bricks); i += 1 {

		brick := state.bricks[i]

		raylib.DrawRectangle(i32(brick.x), i32(brick.y), BRICK_WIDTH, BRICK_HEIGHT, brick.color)
	}

	if state.game_over {
		text := cstring("Game Over! R to Reset")
		textWidth := raylib.MeasureText(text, 20)
		raylib.DrawText(text, WIDTH / 2 - textWidth / 2, HEIGHT / 2 - 10, 20, raylib.BLACK)
	}

	if state.game_paused {
		text := cstring("Paused, R to reset")
		textWidth := raylib.MeasureText(text, 20)
		raylib.DrawText(text, WIDTH / 2 - textWidth / 2, HEIGHT / 2 - 10, 20, raylib.BLACK)
	}

	raylib.DrawLineV(state.ball_line[0], state.ball_line[1], raylib.GREEN)

	raylib.EndDrawing()
}


set_ball_position_and_direction :: proc(
	ball: ^Ball,
	rectangle: raylib.Rectangle,
	speed: raylib.Vector2 = raylib.Vector2{},
) {
	overlap := raylib.GetCollisionRec(ball.rec, rectangle)
	if overlap.width < overlap.height {
		if ball.movement.x > 0 {
			ball.rec.x -= overlap.width
		} else {
			ball.rec.x += overlap.width
		}

		ball.movement.x *= -1
	} else {
		if ball.movement.y > 0 {
			ball.rec.y -= overlap.height
		} else {
			ball.rec.y += overlap.height
		}

		ball.movement.y *= -1
	}
}
