#[compute]
#version 450

#extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable
#extension GL_EXT_shader_atomic_int64 : enable

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// never written to
// input copy of world data
layout(set = 0, binding = 0, std430) readonly buffer WorldDataBufferInput {
	int64_t data[];
}
world_data_buffer_input;

// output copy of world data
// assumed to start at the same state as world_data_buffer_input
layout(set = 1, binding = 1, std430) restrict buffer WorldDataBufferOutput {
	int64_t data[];
}
world_data_buffer_output;

// Array of: [size_x, size_y, size_z, NUM_DATA_ENTRIES]
layout(set = 2, binding = 2, std430) restrict buffer WorldSizeBuffer {
	int data[];
}
world_size_buffer;

// Some constants used in calculations
const int64_t antFoodCarry = 10;
const int64_t antFoodConsumption = 1;
const int64_t antFightStrength = 1;
const double antLeaveRatio = 0.8; // percent of ants that can leave a tile in a tick
const int64_t antQueenRatio = 10; // optimal ratio of ant:queen
const int64_t queenFoodConsumption = 2;
const int64_t queenAntProduction = 10;
const int64_t queenFightStrength = 2; 
const int64_t enemyFightStrength = 1;

// Some helper functions

// Returns -1 if invalid pos
int getIndex(ivec3 pos) {
	if (pos.x < 0 || pos.x >= world_size_buffer.data[0] 
		|| pos.y < 0 || pos.y >= world_size_buffer.data[1] 
		|| pos.z < 0 || pos.z >= world_size_buffer.data[2]) 
	{
		return -1;
	}
	return (pos.x * world_size_buffer.data[1] * world_size_buffer.data[2] * world_size_buffer.data[3])
		+ (pos.y * world_size_buffer.data[2] * world_size_buffer.data[3])
		+ (pos.z * world_size_buffer.data[3]);
}

void addNumAnts(int index, int64_t num_ants) { atomicAdd(world_data_buffer_output.data[index + 0], num_ants); }
int64_t getNumAnts(int index) { return world_data_buffer_input.data[index + 0]; }

void addNumFood(int index, int64_t num_food) { atomicAdd(world_data_buffer_output.data[index + 1], num_food); }
int64_t getNumFood(int index) { return world_data_buffer_input.data[index + 1]; }

void addNumQueens(int index, int64_t num_queens) { atomicAdd(world_data_buffer_output.data[index + 2], num_queens); }
int64_t getNumQueens(int index) { return world_data_buffer_input.data[index + 2]; }

void addNumEnemies(int index, int64_t num_enemies) { atomicAdd(world_data_buffer_output.data[index + 3], num_enemies); }
int64_t getNumEnemies(int index) { return world_data_buffer_input.data[index + 3]; }

#define INIT_DATA_VARS(index) \
	int64_t initNumAnts = getNumAnts(index); \
	int64_t initNumFood = getNumFood(index); \
	int64_t initNumQueens = getNumQueens(index); \
	int64_t initNumEnemies = getNumEnemies(index); \
	int64_t numAnts = initNumAnts, numFood = initNumFood, numQueens = initNumQueens, numEnemies = initNumEnemies;
#define CLAMP_DATA_VARS() \
	numAnts = max(0, numAnts); \
	numFood = max(0, numFood); \
	numQueens = max(0, numQueens); \
	numEnemies = max(0, numEnemies);
#define APPLY_DATA_VARS(index) \
	addNumAnts(index, numAnts - initNumAnts); \
	addNumFood(index, numFood - initNumFood); \
	addNumQueens(index, numQueens - initNumQueens); \
	addNumEnemies(index, numEnemies - initNumEnemies);


// Runs basic updates, i.e. ants eat food and fight
void baseUpdate(ivec3 pos) {
	int index = getIndex(pos);

	INIT_DATA_VARS(index);

	// Ants eat food, or die if not enough
	int64_t totalAntFoodConsumption = initNumAnts * antFoodConsumption;
	int64_t totalQueenFoodConsumption = initNumQueens * queenFoodConsumption;
	numFood -= totalAntFoodConsumption + totalQueenFoodConsumption;
	if (initNumFood - totalQueenFoodConsumption < 0) { numQueens = initNumFood; }
	if (initNumFood - totalAntFoodConsumption - totalQueenFoodConsumption < 0) { numAnts = initNumFood - totalQueenFoodConsumption; }

	// Queens make ants
	numAnts += queenAntProduction * initNumQueens;

	// Ants fight enemies
	numEnemies -= (initNumAnts * antFightStrength + initNumQueens * queenFightStrength) / enemyFightStrength;
	numAnts -= initNumEnemies * enemyFightStrength / antFightStrength;
	if (initNumAnts - (initNumEnemies * enemyFightStrength / antFightStrength) < 0) { 
		numQueens -= (initNumEnemies * enemyFightStrength - initNumAnts * antFightStrength) / queenFightStrength;
	}

	CLAMP_DATA_VARS();
	APPLY_DATA_VARS(index);
}

int64_t getFoodDemand(int index) {
	return (antFoodConsumption * getNumAnts(index)) + (5 * queenFoodConsumption * getNumQueens(index));
}
int64_t getAntDemand(int index) {
	int64_t numAnts = getNumAnts(index);
	int64_t numFood = getNumFood(index);
	int64_t numQueens = getNumQueens(index);

	return max(0, (numQueens * antQueenRatio) 
		+ (numAnts * getNumEnemies(index) * enemyFightStrength / (1 + numQueens * queenFightStrength + numAnts * antFightStrength))
		+ (10 * numFood - (numAnts * antFoodConsumption + numQueens * queenFoodConsumption))
	);
}
// Runs after basic update
void moveAnts(ivec3 pos) {
	int index = getIndex(pos);

	INIT_DATA_VARS(index);

	// Try to spread food evenly, depending on food demand
	// Also try to spread ants evenly, depending on ant demand
	int64_t totalFoodAntsLeaving = 0, totalNotFoodAntsLeaving = 0;
	int64_t foodAntsLeaving[27], notFoodAntsLeaving[27];
	for (int i = -1; i <= 1; i ++) {
		for (int j = -1; j <= 1; j ++) {
			for (int k = -1; k <= 1; k ++) {
				int neighborIndex = getIndex(pos + ivec3(i, j, k));
				// only do calculations if valid pos, and not current pos
				if (neighborIndex != -1 && neighborIndex != index) {
					int64_t localFoodAntsLeaving = 0, localNotFoodAntsLeaving = 0;
					if (getFoodDemand(index) + getFoodDemand(neighborIndex) != 0) {
						int64_t assignedFood = (initNumFood + getNumFood(neighborIndex)) * getFoodDemand(neighborIndex) / (getFoodDemand(index) + getFoodDemand(neighborIndex));
						// if neighbor has less than assigned food, some of our ants move there, carrying food
						// otherwise, some of their ants will move here, carrying food
						if (getNumFood(neighborIndex) < assignedFood) {
							localFoodAntsLeaving = min(int64_t(antLeaveRatio * initNumAnts), (assignedFood - getNumFood(neighborIndex)) / antFoodCarry);
							int64_t localFoodLeaving = min(initNumFood / antFoodCarry * antFoodCarry, localFoodAntsLeaving * antFoodCarry);
							localFoodAntsLeaving = localFoodLeaving / antFoodCarry;
						}
					}
					
					// some ants also follow ant demand
					if (getAntDemand(index) + getAntDemand(neighborIndex) != 0) {
						int64_t assignedAnts = (initNumAnts + getNumAnts(neighborIndex)) * getAntDemand(neighborIndex) / (getAntDemand(index) + getAntDemand(neighborIndex));
						if (getNumAnts(neighborIndex) < assignedAnts) {
							localNotFoodAntsLeaving = min(int64_t(antLeaveRatio * initNumAnts), assignedAnts - getNumAnts(neighborIndex) + localFoodAntsLeaving) - localFoodAntsLeaving;
						}
					}

					totalFoodAntsLeaving += localFoodAntsLeaving;
					totalNotFoodAntsLeaving += localNotFoodAntsLeaving;
					foodAntsLeaving[(i + 1) * 3 * 3 + (j + 1) * 3 + k + 1] = localFoodAntsLeaving;
					notFoodAntsLeaving[(i + 1) * 3 * 3 + (j + 1) * 3 + k + 1] = localNotFoodAntsLeaving;
				}
			}
		}
	}
	// Calculate scalars
	double foodAntLeavingScalar = 1;
	if (totalFoodAntsLeaving != 0) foodAntLeavingScalar = min(1.0lf, min(antLeaveRatio * initNumAnts / totalFoodAntsLeaving, 1.0lf * (initNumFood / antFoodCarry) / totalFoodAntsLeaving));
	double notFoodAntLeavingScalar = 1;
	if (totalNotFoodAntsLeaving != 0) notFoodAntLeavingScalar = clamp(antLeaveRatio * (initNumAnts - totalFoodAntsLeaving) / totalNotFoodAntsLeaving, 0.0lf, 1.0lf);
	// Run through neighbors again to apply
	for (int i = -1; i <= 1; i ++) {
		for (int j = -1; j <= 1; j ++) {
			for (int k = -1; k <= 1; k ++) {
				int neighborIndex = getIndex(pos + ivec3(i, j, k));
				// only run if valid pos, and not current pos
				if (neighborIndex != -1 && neighborIndex != index) {
					int64_t localFoodAntsLeaving = foodAntsLeaving[(i + 1) * 3 * 3 + (j + 1) * 3 + k + 1];
					int64_t localNotFoodAntsLeaving = notFoodAntsLeaving[(i + 1) * 3 * 3 + (j + 1) * 3 + k + 1];

					int64_t localAntsLeaving = int64_t(foodAntLeavingScalar * localFoodAntsLeaving) + int64_t(notFoodAntLeavingScalar * localNotFoodAntsLeaving);
					int64_t localFoodLeaving = int64_t(foodAntLeavingScalar * localFoodAntsLeaving) * antFoodCarry;

					// Apply changes (NOTE: local changes applied in bulk at end)
					addNumAnts(neighborIndex, localAntsLeaving);
					addNumFood(neighborIndex, localFoodLeaving);
					numAnts -= localAntsLeaving;
					numFood -= localFoodLeaving;
				}
			}
		}
	}

	APPLY_DATA_VARS(index);
}
// The code we want to execute in each invocation
void main() {
	// gl_GlobalInvocationID uniquely identifies this invocation across all work groups
	ivec3 pos = ivec3(gl_GlobalInvocationID.xyz);
	
	baseUpdate(pos);
	moveAnts(pos);

	int index = getIndex(pos);
	addNumFood(index, 3);
}
