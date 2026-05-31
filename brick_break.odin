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
PLAYER_SPEED :: f32(10)

BALL_START_X :: PLAYER_START_X + PLAYER_WIDTH / 2 - 7.5
BALL_START_Y :: PLAYER_START_Y - 15
BALL_VELOCITY :: 7

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
			// direction := f32(rand.int_max(90) + 45)
			direction := f32(rand.int_max(90) + 89)
			angle := linalg.to_radians(direction)
			state.ball.movement.x = -BALL_VELOCITY * math.cos_f32(angle)
			state.ball.movement.y = -BALL_VELOCITY * math.sin_f32(angle)

			state.ball.movement.y = -5
		}

		if state.game_over && raylib.IsKeyPressed(raylib.KeyboardKey.R) {
			init_game_state(&state)
		}

		if !state.game_over && !state.game_start && !state.game_paused {
			if raylib.IsKeyDown(raylib.KeyboardKey.RIGHT) {
				state.player.x += PLAYER_SPEED
			}

			if raylib.IsKeyDown(raylib.KeyboardKey.LEFT) {
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

			if raylib.CheckCollisionRecs(state.ball.rec, right_wall) ||
			   raylib.CheckCollisionRecs(state.ball.rec, left_wall) {
				state.ball.movement.x *= -1
			}

			if raylib.CheckCollisionRecs(state.ball.rec, ceiling) {
				state.ball.movement.y *= -1
			}

			// this is wrong.... when you hit the side jank happens
			if raylib.CheckCollisionRecs(state.ball.rec, state.player) {
				state.ball.movement.y *= -1
			}

			for i := 0; i < len(state.bricks); i += 1 {
				brick := state.bricks[i]
				brick_rec := raylib.Rectangle {
					x      = brick.x,
					y      = brick.y,
					height = BRICK_HEIGHT,
					width  = BRICK_WIDTH,
				}

				ball_copy := state.ball.rec

				// move the ball back to where it was pre collision
				ball_copy.x += state.ball.movement.x * -1
				ball_copy.y += state.ball.movement.y * -1

				ball_center := raylib.Vector2 {
					ball_copy.x + ball_copy.width / 2,
					ball_copy.y + ball_copy.height / 2,
				}

				dest := ball_center
				dest.x += state.ball.movement.x * 50
				dest.y += state.ball.movement.y * 50

				state.ball_line[0] = ball_center
				state.ball_line[1] = dest

				if raylib.CheckCollisionRecs(state.ball.rec, brick_rec) {
					top_left := raylib.Vector2{brick.x, brick.y}
					top_right := raylib.Vector2{brick.x + BRICK_HEIGHT, brick.y}
					bottom_left := raylib.Vector2{brick.x, brick.y + BRICK_HEIGHT}
					bottom_right := raylib.Vector2{brick.x + BRICK_WIDTH, brick.y + BRICK_HEIGHT}

					collision_bottom := raylib.Vector2{}
					raylib.CheckCollisionLines(
						ball_center,
						dest,
						bottom_left,
						bottom_right,
						&collision_bottom,
					)

					collision_top := raylib.Vector2{}
					raylib.CheckCollisionLines(
						ball_center,
						dest,
						top_left,
						top_right,
						&collision_top,
					)

					collision_left := raylib.Vector2{}
					raylib.CheckCollisionLines(
						ball_center,
						dest,
						top_left,
						bottom_left,
						&collision_left,
					)

					collision_right := raylib.Vector2{}
					raylib.CheckCollisionLines(
						ball_center,
						dest,
						top_right,
						bottom_right,
						&collision_right,
					)

					fmt.println(
						"what did he hit?",
						collision_left,
						collision_right,
						collision_bottom,
						collision_top,
					)

					if (collision_bottom.x != 0 && collision_bottom.y != 0) ||
					   (collision_top.x != 0 && collision_top.y != 0) {
						state.ball.movement.y *= -1
					}

					if (collision_right.x != 0 && collision_right.y != 0) ||
					   (collision_left.x != 0 && collision_left.y != 0) {
						state.ball.movement.x *= -1
					}

					unordered_remove(&state.bricks, i)
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
	for y := BRICK_HEIGHT * 2; y < HEIGHT / 2; y += BRICK_HEIGHT * 2 {
		for x := BRICK_WIDTH * 2; x < WIDTH; x += BRICK_WIDTH * 2 {
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
		text := cstring("Game Over!")
		textWidth := raylib.MeasureText(text, 20)
		raylib.DrawText(text, WIDTH / 2 - textWidth / 2, HEIGHT / 2 - 10, 20, raylib.BLACK)
	}

	if state.game_paused {
		text := cstring("Pause")
		textWidth := raylib.MeasureText(text, 20)
		raylib.DrawText(text, WIDTH / 2 - textWidth / 2, HEIGHT / 2 - 10, 20, raylib.BLACK)
	}

	raylib.DrawLineV(state.ball_line[0], state.ball_line[1], raylib.GREEN)

	raylib.EndDrawing()
}
