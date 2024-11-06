#[compute]
#version 450

#extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
    int64_t data[];
}
my_data_buffer;

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    // my_data_buffer.data.length();
    my_data_buffer.data[gl_GlobalInvocationID.x] += my_data_buffer.data[gl_GlobalInvocationID.x - 1] - my_data_buffer.data[gl_GlobalInvocationID.x + 1];
}