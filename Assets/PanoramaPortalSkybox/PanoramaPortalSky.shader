Shader "VRChat/Panorama Portal Sky (Equirectangular)"
{
    Properties
    {
        [NoScaleOffset] _PanoramaTex ("360 Panorama (Equirectangular)", 2D) = "gray" {}
        _EnvironmentExtent ("Virtual Sky Half Size", Float) = 50.0
        _YawDegrees ("Panorama Y Rotation", Range(-180, 180)) = 0
        _Exposure ("Exposure", Range(0, 8)) = 1
        [Toggle] _FlipVertical ("Flip Panorama Vertically", Float) = 0
        [Toggle] _RenderFromOutside ("Render From Outside", Float) = 0
        _PortalBounds ("Portal Bounds (Local Half Extents)", Vector) = (0.5, 0.5, 0.5, 0)
    }

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "VRCFallback" = "Unlit" }

        // Both sides are drawn so the effect also works on meshes without reversed inner faces.
        Cull Off
        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            sampler2D _PanoramaTex;
            float _EnvironmentExtent;
            float _YawDegrees;
            float _Exposure;
            float _FlipVertical;
            float _RenderFromOutside;
            float4 _PortalBounds;

            struct AppData
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Interpolators
            {
                float4 position : SV_POSITION;
                float3 objectPosition : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Interpolators Vert(AppData input)
            {
                Interpolators output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.position = UnityObjectToClipPos(input.vertex);
                output.objectPosition = input.vertex.xyz;
                return output;
            }

            float3 ActiveCameraWorldPosition()
            {
                #if defined(USING_STEREO_MATRICES)
                    return unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
                #else
                    return _WorldSpaceCameraPos;
                #endif
            }

            float IsInsidePortal(float3 positionInObjectSpace)
            {
                float3 bounds = max(abs(_PortalBounds.xyz), 0.0001);
                float3 withinBounds = step(abs(positionInObjectSpace), bounds);
                return withinBounds.x * withinBounds.y * withinBounds.z;
            }

            // Finds the forward intersection with a cube centered on the portal.
            // This is an analytic ray/box test, so it does not need a ray-march loop.
            float3 FindVirtualSkyPoint(float3 rayOrigin, float3 rayDirection)
            {
                float halfSize = max(_EnvironmentExtent, 0.001);
                float3 directionSign = lerp(-1.0, 1.0, step(0.0, rayDirection));
                float3 safeDirection = directionSign * max(abs(rayDirection), 0.00001);
                float3 exitPlane = directionSign * halfSize;
                float3 distances = (exitPlane - rayOrigin) / safeDirection;
                float distanceToExit = min(distances.x, min(distances.y, distances.z));
                return rayOrigin + rayDirection * max(distanceToExit, 0.0);
            }

            float3 RotateAroundY(float3 direction, float degrees)
            {
                float angleRadians = degrees * (UNITY_PI / 180.0);
                float sine = sin(angleRadians);
                float cosine = cos(angleRadians);
                return float3(
                    direction.x * cosine - direction.z * sine,
                    direction.y,
                    direction.x * sine + direction.z * cosine
                );
            }

            float2 DirectionToEquirectangularUV(float3 direction)
            {
                const float INV_TWO_PI = 0.15915494309;
                const float INV_PI = 0.31830988618;
                float longitude = atan2(direction.x, -direction.z);
                float latitude = asin(clamp(direction.y, -1.0, 1.0));
                return float2(longitude * INV_TWO_PI + 0.5, latitude * INV_PI + 0.5);
            }

            half4 Frag(Interpolators input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float3 cameraInObjectSpace = mul(unity_WorldToObject, float4(ActiveCameraWorldPosition(), 1.0)).xyz;

                if (_RenderFromOutside < 0.5 && IsInsidePortal(cameraInObjectSpace) < 0.5)
                    discard;

                float3 rayDirection = normalize(input.objectPosition - cameraInObjectSpace);
                float3 skyPoint = FindVirtualSkyPoint(cameraInObjectSpace, rayDirection);
                float3 panoramaDirection = normalize(skyPoint);
                panoramaDirection = RotateAroundY(panoramaDirection, _YawDegrees);

                float2 uv = DirectionToEquirectangularUV(panoramaDirection);
                uv.x = frac(uv.x);
                uv.y = lerp(uv.y, 1.0 - uv.y, saturate(_FlipVertical));

                half3 colour = tex2D(_PanoramaTex, uv).rgb * _Exposure;
                return half4(colour, 1.0);
            }
            ENDCG
        }
    }
}
