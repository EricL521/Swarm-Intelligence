#[compute]
#version 450

#extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// A binding to the data buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer WorldDataBuffer {
    int64_t data[];
}
world_data_buffer;

// Array of: [size_x, size_y, size_z, NUM_DATA_ENTRIES]
layout(set = 1, binding = 1, std430) restrict buffer WorldSizeBuffer {
    int data[];
}
world_size_buffer;

// Some constants used in calculations
const int64_t antFoodCarry = 10;
const int64_t antFoodConsumption = 1;
const int64_t antFightStrength = 1;
const int64_t antQueenRatio = 10; // optimal ratio of ant:queen
const int64_t queenFoodConsumption = 2;
const int64_t queenAntProduction = 1;
const int64_t queenFightStrength = 2; 
const int64_t enemyFightStrength = 1;

// Some helper functions
int getIndex(ivec3 pos) {
    return (pos.x * world_size_buffer.data[1] * world_size_buffer.data[2] * world_size_buffer.data[3])
        + (pos.y * world_size_buffer.data[2] * world_size_buffer.data[3])
        + (pos.z * world_size_buffer.data[3]);
}

void setNumAnts(int index, int64_t num_ants) { world_data_buffer.data[index + 0] = num_ants; }
int64_t getNumAnts(int index) { return world_data_buffer.data[index + 0]; }

void setNumFood(int index, int64_t num_food) { world_data_buffer.data[index + 1] = num_food; }
int64_t getNumFood(int index) { return world_data_buffer.data[index + 1]; }

void setNumQueens(int index, int64_t num_queens) { world_data_buffer.data[index + 2] = num_queens; }
int64_t getNumQueens(int index) { return world_data_buffer.data[index + 2]; }

void setNumEnemies(int index, int64_t num_enemies) { world_data_buffer.data[index + 3] = num_enemies; }
int64_t getNumEnemies(int index) { return world_data_buffer.data[index + 3]; }

// NOTE: All functions should ONLY change the current position

// Runs basic updates, i.e. ants eat food and fight
void baseUpdate(ivec3 pos) {
    int index = getIndex(pos);

    // Get and store values before changing
    int64_t numAnts = getNumAnts(index);
    int64_t numFood = getNumFood(index);
    int64_t numQueens = getNumQueens(index);
    int64_t numEnemies = getNumEnemies(index);

    // Ants eat food, or die if not enough
    int64_t totalAntFoodConsumption = numAnts * antFoodConsumption;
    int64_t totalQueenFoodConsumption = numQueens * queenFoodConsumption;
    setNumFood(index, max(0, numFood - totalAntFoodConsumption - totalQueenFoodConsumption));
    if (numFood - totalQueenFoodConsumption < 0) { setNumQueens(index, numFood); }
    if (numFood - totalAntFoodConsumption - totalQueenFoodConsumption < 0) { setNumAnts(index, max(0, numFood - totalQueenFoodConsumption)); }
    // Update values
    numAnts = getNumAnts(index);
    numFood = getNumFood(index);
    numQueens = getNumQueens(index);

    // Queens make ants
    setNumAnts(index, numAnts + (queenAntProduction * numQueens));
    // Update values
    numAnts = getNumAnts(index);

    // Ants fight enemies
    setNumEnemies(index, max(0, numEnemies - ((numAnts * antFightStrength + numQueens * queenFightStrength) / enemyFightStrength)));
    setNumAnts(index, max(0, numAnts - (numEnemies * enemyFightStrength / antFightStrength)));
    if (numAnts - (numEnemies * enemyFightStrength / antFightStrength) < 0) { 
        setNumQueens(index, max(0, numQueens - ((numEnemies * enemyFightStrength - numAnts * antFightStrength) / queenFightStrength)));
    }
}

int64_t getFoodDemand(int index) {
    return (antFoodConsumption * getNumAnts(index)) + (queenFoodConsumption * getNumQueens(index));
}
int64_t getAntDemand(int index) {
    int64_t numAnts = getNumAnts(index);
    int64_t numFood = getNumFood(index);
    int64_t numQueens = getNumQueens(index);

    return (numQueens * antQueenRatio) 
        + (numAnts * getNumEnemies(index) * enemyFightStrength / (1 + numQueens * queenFightStrength + numAnts * antFightStrength))
        + (numFood / (1 + numAnts * antFoodConsumption + numQueens * queenFoodConsumption));
}
// Runs after basic update
// Note that this function needes to be symmetrical
// i.e. if running code on this datapoint adds ants, another data point should subtract ants
void moveAnts(ivec3 pos) {
    int index = getIndex(pos);

    // Get and store values before changing
    int64_t numAnts = getNumAnts(index);
    int64_t numFood = getNumFood(index);
    int64_t numQueens = getNumQueens(index);
    int64_t numEnemies = getNumEnemies(index);

    // Try to spread food evenly, depending on food demand
    // Also try to spread ants evenly, depending on ant demand 
    int64_t totalAntChange = 0;
    int64_t totalFoodChange = 0;
    for (int i = -1; i <= 1; i ++) {
        for (int j = -1; j <= 1; j ++) {
            for (int k = -1; k <= 1; k ++) {
                if (i == 0 && j == 0 && k == 0) { continue; }
                // only do calculations if we are not at the current position
                int neighborIndex = getIndex(pos + ivec3(i, j, k));
                int64_t assignedFood = int64_t((numFood + getNumFood(neighborIndex)) / (1.0lf + getFoodDemand(index) / getFoodDemand(neighborIndex)) / 26.0lf);
                // if neighbor has less than assigned food, some of our ants move there, carrying food
                // otherwise, some of their ants will move here, carrying food
                totalAntChange += (getNumFood(neighborIndex) - assignedFood) / antFoodCarry / 26; 
                totalFoodChange += (getNumFood(neighborIndex) - assignedFood) / 26;

                // some ants also follow ant demand
                int64_t assignedAnts = int64_t((numAnts + getNumAnts(neighborIndex)) / (1.0lf + getAntDemand(index) / getAntDemand(neighborIndex)));
                totalAntChange += (getNumAnts(neighborIndex) - assignedAnts) / 26;

                // clamp totalAntChange and totalFoodChange to make sure no negative numbers
                totalAntChange = clamp(totalAntChange, - numAnts / 26, getNumAnts(neighborIndex) / 26);
                totalFoodChange = clamp(totalAntChange, - numFood / 26, getNumFood(neighborIndex) / 26);
            }
        }
    }
    setNumAnts(index, numAnts + totalAntChange);
    setNumFood(index, numFood + totalFoodChange);
}
// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID uniquely identifies this invocation across all work groups
    ivec3 pos = ivec3(gl_GlobalInvocationID.xyz);
    
    baseUpdate(pos);
    moveAnts(pos);

    int index = getIndex(pos);
    setNumFood(index, getNumFood(index) + 10);
}
