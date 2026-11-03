extends RefCounted

const INPUT_SIZE = 14
const HIDDEN_SIZE = 12
const OUTPUT_SIZE = 3

var input_hidden_weights = []
var hidden_biases = []
var hidden_output_weights = []
var output_biases = []

const MUTATION_RATE = 0.1
const MUTATION_STRENGTH = 0.1

func initialize():
	# Generates Random Input to Hidden Weights
	for i in range(0, INPUT_SIZE * HIDDEN_SIZE):
		input_hidden_weights.append(randf_range(-1.0, 1.0))
	
	# Generates Random Hidden Biases
	for i in range(0, HIDDEN_SIZE):
		hidden_biases.append(randf_range(-1.0, 1.0))
		
	# Generates Random Hidden to Output Weights
	for i in range(0, HIDDEN_SIZE * OUTPUT_SIZE):
		hidden_output_weights.append(randf_range(-1.0, 1.0))
		
	# Generates Random Output Biases
	for i in range(0, OUTPUT_SIZE):
		output_biases.append(randf_range(-1.0, 1.0))
		
func hidden_layer_calc(inputs: Array):
	var hidden_outputs = []
	
	for i in range(0, HIDDEN_SIZE):
		var start_index = i * INPUT_SIZE
		var weighted_sum = 0.0
		
		for j in range(0, INPUT_SIZE):
			weighted_sum += inputs[j] * input_hidden_weights[start_index + j]
			
		weighted_sum += hidden_biases[i]
		if weighted_sum > 0:
			hidden_outputs.append(weighted_sum)
		else:
			hidden_outputs.append(0.0)
	
	return hidden_outputs
	
func output_layer_calc(hidden_outputs: Array):
	var outputs = []
	
	for i in range(0, OUTPUT_SIZE):
		var start_index = i * HIDDEN_SIZE
		var weighted_sum = 0.0
		
		for j in range(0, HIDDEN_SIZE):
			weighted_sum += hidden_outputs[j] * hidden_output_weights[start_index + j]
			
		weighted_sum += output_biases[i]
		
		outputs.append(weighted_sum)
		
	return outputs
	
func choice(outputs: Array):
	var highest = outputs.max()
	return outputs.find(highest)
	
func predict(inputs: Array):
	var hidden_outputs = hidden_layer_calc(inputs)
	var outputs = output_layer_calc(hidden_outputs)
	var output = choice(outputs)
	
	return output


func copy_network():
	var neural_network = preload("res://Scripts/neural_network.gd")
	var ai = neural_network.new()
	
	ai.input_hidden_weights = input_hidden_weights.duplicate()
	ai.hidden_biases = hidden_biases.duplicate()
	ai.hidden_output_weights = hidden_output_weights.duplicate()
	ai.output_biases = output_biases.duplicate()
	
	return ai
	
	
func mutate():
	for i in range(0, INPUT_SIZE * HIDDEN_SIZE):
		if randf_range(0, 1) < MUTATION_RATE:
			input_hidden_weights[i] += randf_range(-MUTATION_STRENGTH, MUTATION_STRENGTH)
	
	for i in range(0, HIDDEN_SIZE):
		if randf_range(0, 1) < MUTATION_RATE:
			hidden_biases[i] += randf_range(-MUTATION_STRENGTH, MUTATION_STRENGTH)
	
	for i in range(0, HIDDEN_SIZE * OUTPUT_SIZE):
		if randf_range(0, 1) < MUTATION_RATE:
			hidden_output_weights[i] += randf_range(-MUTATION_STRENGTH, MUTATION_STRENGTH)
			
	for i in range(0, OUTPUT_SIZE):
		if randf_range(0, 1) < MUTATION_RATE:
			output_biases[i] += randf_range(-MUTATION_STRENGTH, MUTATION_STRENGTH)


func save_data():
	return {
		"input_hidden_weights": input_hidden_weights,
		"hidden_biases": hidden_biases,
		"hidden_output_weights": hidden_output_weights,
		"output_biases": output_biases
	}
	
	
func load_data(dict: Dictionary):
	
	input_hidden_weights = dict["input_hidden_weights"].duplicate()
	hidden_biases = dict["hidden_biases"].duplicate()
	hidden_output_weights = dict["hidden_output_weights"].duplicate()
	output_biases = dict["output_biases"].duplicate()
	
