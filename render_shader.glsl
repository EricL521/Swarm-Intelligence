#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// never written to
// input copy of world data
layout(set = 0, binding = 0, std430) readonly buffer WorldDataBufferInput {
	int data[];
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
	float max_index_size;
	float pixels_per_index; 
	float ant_per_index_size;
	float queen_per_index_size;
	float enemy_per_index_size;
	float food_per_index_size;
} render_settings;

// texture used to blend the metaballs together
// only alpha channel is used
// texture should be 100x100
layout(set = 3, binding = 3, rgba32f) readonly uniform image2D blend_texture;

layout(set = 4, binding = 4, rgba32f) uniform image2D output_texture;

// the alpha value at which to show metaballs
#define METABALL_ALPHA 0.20

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

int getNumAnts(int index) { return world_data_buffer_input.data[index + 0]; }
int getNumFood(int index) { return world_data_buffer_input.data[index + 1]; }
int getNumQueens(int index) { return world_data_buffer_input.data[index + 2]; }
int getNumEnemies(int index) { return world_data_buffer_input.data[index + 3]; }

// perplexity code
vec4 blend(vec4 source, vec4 destination) {
	float srcAlpha = source.a;
	float dstAlpha = destination.a;
	float outAlpha = srcAlpha + dstAlpha * (1.0 - srcAlpha);

	vec3 srcColor = source.rgb * srcAlpha;
	vec3 dstColor = destination.rgb * dstAlpha * (1.0 - srcAlpha);

	vec3 outColor = (srcColor + dstColor) / max(outAlpha, 0.001);

	return vec4(outColor, outAlpha);
}

// The code we want to execute in each invocation
void main() {
	// default to black
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), color);

	ivec2 horizontal_pos = ivec2(gl_GlobalInvocationID.xy / render_settings.pixels_per_index) + render_settings.top_left_pos;
	int index = getIndex(ivec3(horizontal_pos.x, 0, horizontal_pos.y));
	if (index == -1) { return; }
	// debug grid
	// imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), vec4(horizontal_pos.x / 10.0, horizontal_pos.y / 10.0, 0.0, 1.0));

	// iterate through layers
	vec4 existing_color = vec4(0.0, 0.0, 0.0, 0.0);
	for (int i = min(world_size_buffer.data[2] - 1, render_settings.vertical_cutoff.y); i >= max(0, render_settings.vertical_cutoff.x); i --) {
		// check surrounding 3x3 grid
		vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
		float total_weighted_size = 0.0;
		float total_weight = 0.0;
		for (int x = -1; x <= 1; x++) {
			for (int y = -1; y <= 1; y++) {
				ivec3 test_pos = ivec3(horizontal_pos.x + x, i, horizontal_pos.y + y);
				int index = getIndex(test_pos);
				if (index == -1) {
					continue;
				}
				float ants_size = getNumAnts(index) / render_settings.ant_per_index_size;
				float food_size = getNumFood(index) / render_settings.food_per_index_size;
				float queens_size = getNumQueens(index) / render_settings.queen_per_index_size;
				float enemies_size = getNumEnemies(index) / render_settings.enemy_per_index_size;
				float index_size = (ants_size + food_size + queens_size + enemies_size);
				// normalize index_size to fit max_index_size
				index_size = render_settings.max_index_size * (1 + METABALL_ALPHA/2) * (1 - 1 / (1 + index_size));
				float size = index_size * render_settings.pixels_per_index;
				if (size <= 0) {
					continue;
				}

				vec2 test_pixel = (test_pos.xz - render_settings.top_left_pos + vec2(0.5, 0.5)) * render_settings.pixels_per_index;
				vec2 diff = (gl_GlobalInvocationID.xy - test_pixel) * render_settings.blend_texture_size;
				diff = (diff - render_settings.blend_texture_size / 2) / size + render_settings.blend_texture_size / 2;
				if (diff.x >= 0 && diff.x < render_settings.blend_texture_size.x && diff.y >= 0 && diff.y < render_settings.blend_texture_size.y) {
					float alpha = imageLoad(blend_texture, ivec2(diff)).a;
					if (alpha != 0) {
						// blend with existing color
						vec3 newRGB = vec3(enemies_size, ants_size + queens_size, food_size)/max(max(enemies_size, ants_size + queens_size), food_size);
						color = vec4((color.rgb*color.a + newRGB*alpha) / (color.a + alpha), mix(color.a, 1, alpha));
						// update weighted_avg_size
						total_weighted_size += size * alpha;
						total_weight += alpha;
					}
				}
			}
		}
		vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);
		if (color.a > METABALL_ALPHA) {
			final_color = vec4(color.rgb, 1.0);
		}
		else {
			float min_alpha = max(0, METABALL_ALPHA * (1 - 30/(total_weighted_size/total_weight)));
			if (color.a > min_alpha) {
				final_color = vec4(1.0, 1.0, 1.0, min(1.0, 0.6/METABALL_ALPHA * (color.a - min_alpha)/(METABALL_ALPHA - min_alpha)));
			}
		}

		if (final_color.a > 0) {
			// blend final_color with existing color using blend
			existing_color = blend(existing_color, final_color);

			imageStore(output_texture, ivec2(gl_GlobalInvocationID.xy), existing_color);
		}
		// if we have a solid color, we can stop, otherwise we have to render the layer below
		if (final_color.a == 1.0) {
			break;
		}
	}
}
