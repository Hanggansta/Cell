// ----------------------------------------------------------------------------
// calculation without bit-operators. This might be required for certain
// glsl versions or ES/WebGL versions that don't support bit-operators yet.
// VanDerCorpus with base 2 equals hammersley's second value.
float VanDerCorpus(uint n, uint base)
{
    float invBase = 1.0 / float(base);
    float denom   = 1.0;
    float result  = 0.0;

    // NOTE(Joey): do this for all 32 bits; doesn't work with
    // while loop. This produces a lot of wasted cycles but
    // difficult to do otherwise in ES 2.0.
    for(int i = 0; i < 32; ++i)
    {
        if(n > 0)
        {
            denom   = mod(float(n), 2.0);
            result += denom * invBase;
            invBase = invBase / 2.0;
            n       = int(float(n) / 2.0);
        }
    }

    return result;
}
// ----------------------------------------------------------------------------
// http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
// efficient VanDerCorpus calculation.
float RadicalInverse_VdC(uint bits) 
{
     bits = (bits << 16u) | (bits >> 16u);
     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
     return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}
// ----------------------------------------------------------------------------
vec2 Hammersley(uint i, uint N)
{
	return vec2(float(i)/float(N), RadicalInverse_VdC(i));
}
// ----------------------------------------------------------------------------
vec2 HammersleyNoBitOps(uint i, uint N)
{
	return vec2(float(i)/float(N), VanDerCorpus(i, 2));
}
// ----------------------------------------------------------------------------
vec3 SampleHemisphereUniform(vec2 Xi)
{
	float phi = Xi.y * 2.0 * PI;
	float cosTheta = sqrt(1.0 - Xi.x);
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	
	return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}
// ----------------------------------------------------------------------------
vec3 SampleHemisphereCos(vec2 Xi)
{
	float phi = Xi.y * 2.0 * PI;
	float cosTheta = 1.0 - Xi.x;
	float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	
	return vec3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
}
// ----------------------------------------------------------------------------
vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness)
{
	float a = roughness*roughness;
	
	float phi = 2.0 * PI * Xi.x;
	float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
	float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
	
	// NOTE(Joey): from spherical coordinates to cartesian coordinates - halfway vector
	vec3 H;
	H.x = cos(phi) * sinTheta;
	H.y = sin(phi) * sinTheta;
	H.z = cosTheta;
	
	// NOTE(Joey): from tangent-space H vector to world-space sample vector
	vec3 up          = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 tangent   = normalize(cross(up, N));
	vec3 bitangent = cross(N, tangent);
	
	vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
	return normalize(sampleVec);
}
// ----------------------------------------------------------------------------
const vec2 invAtan = vec2(0.1591,0.3183);
vec2 SampleSphericalMap(vec3 v)
{
    vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
    uv *= invAtan;
    uv += 0.5;
    return uv;
}
