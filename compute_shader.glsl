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


int getIndex(ivec3 pos) {
    return (pos.x * world_size_buffer.data[1] * world_size_buffer.data[2] * world_size_buffer.data[3])
        + (pos.y * world_size_buffer.data[2] * world_size_buffer.data[3])
        + (pos.z * world_size_buffer.data[3]);
}

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID uniquely identifies this invocation across all work groups
    int index = getIndex(ivec3(gl_GlobalInvocationID.xyz));
    world_data_buffer.data[index] = 1;

}
