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

// Array of: [size_x, size_y, size_z, NUM_DATA_ENTRIES]
layout(set = 1, binding = 1, std430) restrict buffer WorldSizeBuffer {
	int data[];
}
world_size_buffer;

// NOTE: output_resolution should be the same as gl_GlobalInvocationID size
layout(set = 2, binding = 2) uniform RenderSettings {
	ivec2 blend_texture_size;
	ivec2 top_left_pos;
	ivec2 output_resolution;
	// <bottom cutoff index, vertical cutoff index>, inclusive
	ivec2 vertical_cutoff;
	// used to determine size of circles
	int pixels_per_index; 
	int ant_per_index_size;
	int queen_per_index_size;
	int enemy_per_index_size;
	int food_per_index_size;
} render_settings;

// texture used to blend the metaballs together
// only alpha channel is used
// texture should be 100x100
layout(set = 3, binding = 3, rgba32f) readonly uniform image2D blend_texture;

layout(set = 4, binding = 4, rgba32f) writeonly uniform image2D output_texture;

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

int64_t getNumAnts(int index) { return world_data_buffer_input.data[index + 0]; }
int64_t getNumFood(int index) { return world_data_buffer_input.data[index + 1]; }
int64_t getNumQueens(int index) { return world_data_buffer_input.data[index + 2]; }
int64_t getNumEnemies(int index) { return world_data_buffer_input.data[index + 3]; }

// The code we want to execute in each invocation
void main() {
	ivec2 horizontal_pos = ivec2(gl_GlobalInvocationID.xy / render_settings.pixels_per_index) + render_settings.top_left_pos;
	int index = getIndex(ivec3(horizontal_pos.x, 0, horizontal_pos.y));
	
	// default to transparent black
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	// vec4 new_color = imageLoad(blend_texture, ivec2(1.0 * gl_GlobalInvocationID.xy / render_settings.output_resolution * render_settings.blend_texture_size));
	// color = vec4((color.rgb*color.a + new_color.rgb*new_color.a) / (color.a + new_color.a), mix(color.a, 1, new_color.a));
	imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), color);

	if (index == -1) { return; }


	color = vec4(vec3(getNumAnts(index), 0, getNumQueens(index)) / 10.0, 1.0);
	// color = vec4(horizontal_pos.x / 50.0, 0, horizontal_pos.y / 50.0, 1.0);
	imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), color);
	return;

	// iterate through layers
	for (int i = render_settings.vertical_cutoff.y; i >= render_settings.vertical_cutoff.x; i --) {
		if (i < 0 || i >= world_size_buffer.data[2]) {
			continue;
		}

		// check surrounding 3x3 grid
		vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				ivec3 test_pos = ivec3(horizontal_pos.x + x, i, horizontal_pos.y + y);
				int index = getIndex(test_pos);
				if (index == -1) {
					continue;
				}
				float ants_size = float(getNumAnts(index) / render_settings.ant_per_index_size);
				float food_size = float(getNumFood(index) / render_settings.food_per_index_size);
				float queens_size = float(getNumQueens(index) / render_settings.queen_per_index_size);
				float enemies_size = float(getNumEnemies(index) / render_settings.enemy_per_index_size);
				float size = render_settings.pixels_per_index * (ants_size + food_size + queens_size + enemies_size);
				if (size <= 0) {
					continue;
				}

				vec2 test_pixel = (test_pos.xy - render_settings.top_left_pos) * render_settings.pixels_per_index;
				vec2 diff = (gl_GlobalInvocationID.xy - test_pixel) / size;
				float alpha = 0.0;
				if (diff.x >= 0 && diff.x < render_settings.blend_texture_size.x && diff.y >= 0 && diff.y < render_settings.blend_texture_size.y) {
					alpha = imageLoad(blend_texture, render_settings.blend_texture_size/2 + ivec2(diff)).a;
				}
				// blend with existing color
				color = vec4((color.rgb*color.a + vec3(enemies_size, ants_size + queens_size, food_size)*alpha) / (color.a + alpha), mix(color.a, 1, alpha));
			}
		}
		if (color.a > 0.0) {
			imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), color);
			break; // only render the first non-transparent layer
		}
	}
}
