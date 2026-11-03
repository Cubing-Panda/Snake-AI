extends Node2D

const GRID_SIZE = 20
const CELL_SIZE = 40

var snake = []
var direction = null
var food = null
var score = null
var game_over = null


var move_timer = 0.0
var move_interval = 0.2


var training_mode = true
var steps_per_frame = 500
var games_played = 0
var total_score = 0

var pop_script = preload("res://Scripts/population.gd")
var population_manager = pop_script.new()
var ai = null

const MAX_MOVES = 500
var moves_survived = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	direction = Vector2i.RIGHT
	score = 0
	game_over = false

	snake.append(Vector2i(10, 10)) # Head
	snake.append(Vector2i(9, 10))  # Body
	snake.append(Vector2i(8, 10))  # Tail
	
	spawn_food()
	
	if not training_mode:
		queue_redraw()
	
	if population_manager.load_from_file() == false:
		population_manager.create_population()
	
	if not training_mode and population_manager.best_ever_network != null:
		ai = population_manager.best_ever_network
	else:
		ai = population_manager.population[population_manager.current_network]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if game_over:
		if training_mode:
			#print("Network: " + str(population_manager.current_network) + " | Food: " + str(score) + " | Moves: " + str(moves_survived))
			total_score += score
			games_played += 1
			population_manager.record_game(score, moves_survived)
			population_manager.finish_network_test()
			
			if population_manager.current_network < population_manager.POPULATION_SIZE:
				ai = population_manager.population[population_manager.current_network]
			else:
				var gen_stats = population_manager.gen_stats()
				print("Average: " + str(gen_stats[0]))
				print("Best: " + str(gen_stats[1]))
				print("Food: " + str(gen_stats[2]))
				print("Moves: " + str(gen_stats[3]))
				print("Generation: " + str(population_manager.generation))
				population_manager.create_next_gen()
				ai = population_manager.population[population_manager.current_network]
				
			population_manager.save_to_file()
			reset_game()
		return
	
		
	if not training_mode:
		move_timer += delta

		if move_timer >= move_interval:
			move_timer = 0.0
		
			var action = ai.predict(get_inputs())
			ai_direction(action)
			move_snake()
	else:
		for i in range(0, steps_per_frame):
			var action = ai.predict(get_inputs())
			ai_direction(action)
			move_snake()
			if game_over:
				break
	
func spawn_food():
	var running = true
	while running:
		var cords = Vector2i(randi_range(0, GRID_SIZE - 1), randi_range(0, GRID_SIZE - 1))
		if snake.has(cords):
			continue
		food = cords
		running = false
		

func _draw() -> void:
	if training_mode:
		return
	
	for i in range(0, len(snake)):
		var snake_draw = Rect2(snake[i] * CELL_SIZE, Vector2(40, 40))
		draw_rect(snake_draw, Color("#39D353"))
		
	var food_draw = Rect2(food * CELL_SIZE, Vector2(40, 40))
	draw_rect(food_draw, Color("#FF4545"))
	
	for i in range(0, GRID_SIZE + 1):
		draw_line(Vector2(i * CELL_SIZE, 0), Vector2(i * CELL_SIZE, GRID_SIZE * CELL_SIZE), Color("#303030"))
	
	for i in range (0, GRID_SIZE + 1):
		draw_line(Vector2(0, i * CELL_SIZE), Vector2(GRID_SIZE * CELL_SIZE, i * CELL_SIZE), Color("#303030"))
	
	draw_string(
	ThemeDB.fallback_font,
	Vector2(20, 860),
	"Score: " + str(score),
	HORIZONTAL_ALIGNMENT_LEFT,
	-1,
	30,
	Color.WHITE
	)
	
	if game_over == true:
		var game_over_screen = Rect2(Vector2i(0, 0), Vector2i(800, 900))
		draw_rect(game_over_screen, Color(0.5, 0.5, 0.5, 0.5))
		
		draw_string(
		ThemeDB.fallback_font,
		Vector2(120, 300),
		"Game Over!",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		100,
		Color.WHITE
		)
		
		draw_string(
		ThemeDB.fallback_font,
		Vector2(200, 400),
		"Press R to Restart",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		50,
		Color.WHITE
		)
	
func move_snake():
	var new_head = snake[0] + direction
	if new_head.x < 0:
		game_over = true
		if not training_mode:
			queue_redraw()
		return
	elif new_head.x >= GRID_SIZE:
		game_over = true
		if not training_mode:
			queue_redraw()
		return
	elif new_head.y < 0:
		game_over = true
		if not training_mode:
			queue_redraw()
		return
	elif new_head.y >= GRID_SIZE:
		game_over = true
		if not training_mode:
			queue_redraw()
		return
	elif new_head == food:
		if snake.has(new_head):
			game_over = true
			if not training_mode:
				queue_redraw()
			return
	else:
		if snake.slice(0, -1).has(new_head):
			game_over = true
			if not training_mode:
				queue_redraw()
			return
	
	snake.insert(0, new_head)
	moves_survived += 1
	
	
		
	if snake[0] != food:
		snake.remove_at(-1)
	else:
		score += 1
		spawn_food()
	
	if not training_mode:
		queue_redraw()
	
	if moves_survived >= MAX_MOVES:
		game_over = true
		if not training_mode:
			queue_redraw()
		return
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and game_over == true:
		get_tree().reload_current_scene()
		
func danger_check(check_dir: Vector2i) -> float:
	var next_cell = snake[0] + check_dir

	# Check walls
	if next_cell.x < 0 or next_cell.x >= GRID_SIZE:
		return 1.0
	if next_cell.y < 0 or next_cell.y >= GRID_SIZE:
		return 1.0

	# Check the snake
	if next_cell == food:
		return float(snake.has(next_cell))
	else:
		return float(snake.slice(0, -1).has(next_cell))
		

func get_danger_sensors() -> Array:
	var left_dir = Vector2i(direction.y, -direction.x)
	var right_dir = Vector2i(-direction.y, direction.x)
	
	return [
		danger_check(direction),
		danger_check(left_dir),
		danger_check(right_dir)
		]


func get_vision_inputs():
	var right_dir = Vector2i(-direction.y, direction.x)
	var forward_right = direction + right_dir
	var right = right_dir
	var backward_right = -direction + right_dir
	var backward = -direction
	var backward_left = -direction - right_dir
	var left = -right_dir
	var forward_left = direction - right_dir
	
	return [
		scan_direction(direction),
		scan_direction(forward_right),
		scan_direction(right),
		scan_direction(backward_right),
		scan_direction(backward),
		scan_direction(backward_left),
		scan_direction(left),
		scan_direction(forward_left)
		]
func get_food_direction() -> Vector2:
	var difference = food - snake[0]
	var normalized = Vector2(difference) / (GRID_SIZE - 1)
	return normalized

func get_direction_inputs() -> Array:
	return [
		float(direction == Vector2i.UP),
		float(direction == Vector2i.DOWN),
		float(direction == Vector2i.LEFT),
		float(direction == Vector2i.RIGHT)
		]
		
		
func get_inputs() -> Array:
	var food_dir = get_food_direction()
	var facing = get_direction_inputs()
	var scan = get_vision_inputs()

	return [
		food_dir.x,
		food_dir.y,
		facing[0],
		facing[1],
		facing[2],
		facing[3],
		scan[0],
		scan[1],
		scan[2],
		scan[3],
		scan[4],
		scan[5],
		scan[6],
		scan[7]
		]
	
func ai_direction(choice: int):
	if choice == 0:
		pass
	elif choice == 1:
		direction = Vector2i(direction.y, -direction.x)
	else:
		direction = Vector2i(-direction.y, direction.x)
		
		
func reset_game():
	direction = Vector2i.RIGHT
	score = 0
	game_over = false
	move_timer = 0.0
	moves_survived = 0
	
	snake.clear()

	snake.append(Vector2i(10, 10)) # Head
	snake.append(Vector2i(9, 10))  # Body
	snake.append(Vector2i(8, 10))  # Tail
	
	spawn_food()
	

func scan_direction(dir: Vector2i):
	var distance = 1
	while true:
		var cell_check = snake[0] + (dir * distance)
		
		if cell_check.x < 0 or cell_check.x >= GRID_SIZE:
			return float(distance) / GRID_SIZE
		if cell_check.y < 0 or cell_check.y >= GRID_SIZE:
			return float(distance) / GRID_SIZE

		# Check the snake
		if cell_check == food:
			if snake.has(cell_check):
				return float(distance) / GRID_SIZE
		else:
			if snake.slice(0, -1).has(cell_check):
				return float(distance) / GRID_SIZE
		
		distance += 1
			
			
