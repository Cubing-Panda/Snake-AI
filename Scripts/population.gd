extends RefCounted

var neural_network = preload("res://Scripts/neural_network.gd")

const POPULATION_SIZE = 50
const SURVIVORS = 10
var population = []
var fitness_scores = []
var food_scores = []
var move_scores = []

var current_network = 0
var games_per_network = 10
var games_completed = 0
var fitness_total = 0.0
var food_total = 0.0
var move_total = 0.0

var generation = 1

var best_ever_fitness = 0.0
var best_ever_network = null


func create_population():
	for i in range(0, POPULATION_SIZE):
		var ai = neural_network.new()
		ai.initialize()
		
		population.append(ai)
		fitness_scores.append(0.0)
		food_scores.append(0.0)
		move_scores.append(0.0)
		
		
func calculate_fitness(score: int, moves_survived: int):
	return score * 3000 + moves_survived


func set_fitness(index: int, fitness: float):
	fitness_scores[index] = fitness
	
	
func record_game(score: int, moves_survived: int):
	fitness_total += calculate_fitness(score, moves_survived)
	food_total += score
	move_total += moves_survived
	games_completed += 1
	
	
func finish_network_test():
	if games_completed >= games_per_network:
		set_fitness(current_network, fitness_total / games_per_network)
		food_scores[current_network] = food_total / games_per_network
		move_scores[current_network] = move_total / games_per_network
		
		if fitness_scores[current_network] > best_ever_fitness:
			best_ever_fitness = fitness_scores[current_network]
			best_ever_network = population[current_network].copy_network()
		
		fitness_total = 0.0
		food_total = 0.0
		move_total = 0.0
		games_completed = 0
		current_network += 1


func rank_population():
	var ranked_pop = []
	for i in range(0, POPULATION_SIZE):
		ranked_pop.append(i)
	
	ranked_pop.sort_custom(func(a, b): return fitness_scores[a] > fitness_scores[b])
	
	return ranked_pop
	
func select_survivors():
	var ranked = rank_population()
	var survivors = []
	for i in range(0, SURVIVORS):
		survivors.append(population[ranked[i]])
		
	return survivors
		
		
func create_next_gen():
	var survivors = select_survivors()
	var next_gen = []
	next_gen.append_array(survivors)
	
	for i in range(0, POPULATION_SIZE - SURVIVORS):
		var random = randi_range(0, SURVIVORS - 1)
		var copy = survivors[random].copy_network()
		copy.mutate()
		
		next_gen.append(copy)
	
	fitness_scores.clear()
	food_scores.clear()
	move_scores.clear()
	for i in range(0, POPULATION_SIZE):
		fitness_scores.append(0.0)
		food_scores.append(0.0)
		move_scores.append(0.0)
		
	current_network = 0
	games_completed = 0
	fitness_total = 0.0
	food_total = 0.0
	move_total = 0.0
	
	population = next_gen
	generation += 1
	
	
func gen_stats():
	var avg_fit = 0.0
	var best_fit = 0.0
	var avg_food = 0.0
	var avg_move = 0.0
	
	for i in range(0, POPULATION_SIZE):
		avg_fit += fitness_scores[i]
		if fitness_scores[i] > best_fit:
			best_fit = fitness_scores[i]
		
		avg_food += food_scores[i]
		avg_move += move_scores[i]
			
	return [avg_fit / POPULATION_SIZE, best_fit, avg_food / POPULATION_SIZE, avg_move / POPULATION_SIZE]
	
	
func save_population():
	var saved_pop = []
	
	for i in range(0, POPULATION_SIZE):
		saved_pop.append(population[i].save_data())
		
	return saved_pop
	
	
func save_all_data():
	return {
		"population": save_population(),
		"fitness_scores": fitness_scores.duplicate(),
		"food_scores": food_scores.duplicate(),
		"move_scores": move_scores.duplicate(),
		"current_network": current_network,
		"games_completed": games_completed,
		"fitness_total": fitness_total,
		"food_total": food_total,
		"move_total": move_total,
		"generation": generation,
		"best_ever_fitness": best_ever_fitness,
		"best_ever_network": best_ever_network.save_data() if best_ever_network != null else null
	}
	
	
func save_to_file():
	var main_path = ProjectSettings.globalize_path("user://snake_ai_save.json")
	var backup_path = ProjectSettings.globalize_path("user://snake_ai_save_backup.json")
	var temp_path = ProjectSettings.globalize_path("user://snake_ai_save_temp.json")
	
	var save = JSON.stringify(save_all_data())
	var temp_file = FileAccess.open("user://snake_ai_save_temp.json", FileAccess.WRITE)
	
	if temp_file:
		temp_file.store_string(save)
		temp_file.flush()
		var save_error = temp_file.get_error()
		temp_file.close()

		if save_error != OK:
			print("Temporary save failed!")
			return
	
	else:
		print("Saving Error Occurred!")
		return
		
	if FileAccess.file_exists(backup_path):
		var remove_error = DirAccess.remove_absolute(backup_path)

		if remove_error != OK:
			print("Could not remove old backup!")
			return
		
	if FileAccess.file_exists(main_path):
		var rename_error = DirAccess.rename_absolute(main_path, backup_path)
		
		if rename_error != OK:
			print("Could not Rename old main")
			return
	
	if FileAccess.file_exists(temp_path):
		var rename_error = DirAccess.rename_absolute(temp_path, main_path)
		
		if rename_error != OK:
			print("Could not Install new save. Attempting to reinstall backup")
			
			if FileAccess.file_exists(backup_path):
				var move_error = DirAccess.rename_absolute(backup_path, main_path)

				if move_error != OK:
					print("Everything has failed. It's the end of the WORLD!!!")
					return
			
		
func load_from_file():
	var file = null
	
	if FileAccess.file_exists("user://snake_ai_save.json"):
		file = FileAccess.open("user://snake_ai_save.json", FileAccess.READ)
	else: 
		if FileAccess.file_exists("user://snake_ai_save_backup.json"):
			file = FileAccess.open("user://snake_ai_save_backup.json", FileAccess.READ)
		

	
	if file:
		var content = file.get_as_text()
		file.close()
		
		var data = JSON.parse_string(content)
		
		if data == null:
			return false
		else:
			if not data is Dictionary:
				return false
			if not "population" in data:
				return false
			if not "fitness_scores" in data:
				return false
			if not "food_scores" in data:
				return false
			if not "move_scores" in data:
				return false
			if not "current_network" in data:
				return false
			if not "games_completed" in data:
				return false
			if not "fitness_total" in data:
				return false
			if not "food_total" in data:
				return false
			if not "move_total" in data:
				return false
			if not "generation" in data:
				return false
			if not len(data["population"]) == POPULATION_SIZE:
				return false
			if not len(data["fitness_scores"]) == POPULATION_SIZE:
				return false
			if not len(data["food_scores"]) == POPULATION_SIZE:
				return false
			if not len(data["move_scores"]) == POPULATION_SIZE:
				return false
			
				
			population.clear()
			for i in range(0, POPULATION_SIZE):
				var ai = neural_network.new()
				ai.load_data(data["population"][i])
				population.append(ai)
				
			fitness_scores = data["fitness_scores"]
			food_scores = data["food_scores"]
			move_scores = data["move_scores"]
			current_network = data["current_network"]
			games_completed = data["games_completed"]
			fitness_total = data["fitness_total"]
			food_total = data["food_total"]
			move_total = data["move_total"]
			generation = data["generation"]
			if "best_ever_fitness" in data:
				best_ever_fitness = data["best_ever_fitness"]
			if "best_ever_network" in data and data["best_ever_network"] != null:
				best_ever_network = neural_network.new()
				best_ever_network.load_data(data["best_ever_network"])
			
			
			return true
			
	else:
		return false
