Shader "Custom/Geometry Vertex Tesselationless Grass Shader"
{

    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _ColorBottom("Color Bottom", Color) = (1,1,1,1)
        _ColorTip("Color Top", Color) = (1,1,1,1)
        _ExtrusionFactor("Extrusion Factor", Range(0, 2)) = 0.01
        _Subdivisions("Subdivisions in Grass", Range(1,5)) = 1
        _GrassThickness("Grass Thickness", Range(0,1)) = 0.2
        _AirVector("Air Direction", Vector) = (1,0,0)
        _Speed("Wind Speed", Range(0.1, 5)) = 1
        _AirForce("Air Strength", Range(0,2)) = 1
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            Cull Off
            LOD 100

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma geometry geom
                #pragma fragment frag
                // make fog work
                #pragma multi_compile_fog

                //#pragma surface 

                #include "UnityCG.cginc"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2g
                {
                    float2 uv : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    float4 vertex : SV_POSITION;
                    float3 normal : NORMAL;
                };

                struct g2f
                {
                    float2 uv : TEXCOORD0;
                    UNITY_FOG_COORDS(1)
                    float4 vertex : SV_POSITION;
                    float4 color : COLOR;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                float _ExtrusionFactor;
                float4 _ColorBottom;
                float4 _ColorTip;
                int _Subdivisions;
                float _GrassThickness;
                float3 _AirVector;
                float _Speed;
                float _AirForce;

                v2g vert(appdata v)
                {
                    v2g o;
                    o.vertex = v.vertex;
                    o.uv = v.uv;
                    o.normal = v.normal;
                    return o;
                }

                [maxvertexcount(99)]
                void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {

                    float3 movementFactor = (((sin(_Time * _Speed) + 1) / 2.5) * _AirForce + 0.2) * normalize(_AirVector);
                    
                        v2g vertArray[] = IN;
                        float4 barycenter = (vertArray[0].vertex + vertArray[1].vertex + vertArray[2].vertex) / 3;
                        float3 normal = (vertArray[0].normal + vertArray[1].normal + vertArray[2].normal) / 3;

                        g2f o;

                        for (int j = 0; j < _Subdivisions; j++) {
                            for (int i = 0; i < 3; i++) {
                                int next = (i + 1) % 3;
                                o.vertex = UnityObjectToClipPos(vertArray[i].vertex);
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * j / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                o.vertex = UnityObjectToClipPos(vertArray[i].vertex + normal * _ExtrusionFactor / (_Subdivisions + 1) + (barycenter - vertArray[i].vertex) * (1 - _GrassThickness) + float4(pow(_ExtrusionFactor * j / _Subdivisions, 2) * movementFactor, 0.0));
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * (j + 1) / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                o.vertex = UnityObjectToClipPos(vertArray[next].vertex);
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[next].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * j / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                triStream.RestartStrip();

                                o.vertex = UnityObjectToClipPos(vertArray[i].vertex + normal * _ExtrusionFactor / (_Subdivisions + 1) + (barycenter - vertArray[i].vertex) * (1 - _GrassThickness) + float4(pow(_ExtrusionFactor * j / _Subdivisions, 2) * movementFactor, 0.0));
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * (j + 1) / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                o.vertex = UnityObjectToClipPos(vertArray[next].vertex + normal * _ExtrusionFactor / (_Subdivisions + 1) + (barycenter - vertArray[next].vertex) * (1 - _GrassThickness) + float4(pow(_ExtrusionFactor * j / _Subdivisions, 2) * movementFactor, 0.0));
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * (j + 1) / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                o.vertex = UnityObjectToClipPos(vertArray[next].vertex);
                                UNITY_TRANSFER_FOG(o, o.vertex);
                                o.uv = TRANSFORM_TEX(vertArray[next].uv, _MainTex);
                                o.color = (_ColorTip - _ColorBottom) * j / (_Subdivisions + 1) + _ColorBottom;
                                triStream.Append(o);

                                triStream.RestartStrip();
                            }

                            for (int i = 0; i < 3; i++) {
                                vertArray[i].vertex = vertArray[i].vertex + float4(normal, 0.0) * _ExtrusionFactor / (_Subdivisions + 1) + (barycenter - vertArray[i].vertex) * (1 - _GrassThickness) + float4(pow(_ExtrusionFactor * j / _Subdivisions, 2) * movementFactor, 0.0);
                            }
                            barycenter = (vertArray[0].vertex + vertArray[1].vertex + vertArray[2].vertex) / 3;
                        }

                        for (int i = 0; i < 3; i++) {
                            int next = (i + 1) % 3;
                            o.vertex = UnityObjectToClipPos(vertArray[i].vertex);
                            UNITY_TRANSFER_FOG(o, o.vertex);
                            o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                            o.color = (_ColorTip - _ColorBottom) * _Subdivisions / (_Subdivisions + 1) + _ColorBottom;;
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(barycenter + normal * _ExtrusionFactor / (_Subdivisions + 1) + float4(pow(_ExtrusionFactor, 2) * movementFactor, 0.0));
                            UNITY_TRANSFER_FOG(o, o.vertex);
                            o.uv = TRANSFORM_TEX(vertArray[i].uv, _MainTex);
                            o.color = _ColorTip;
                            triStream.Append(o);

                            o.vertex = UnityObjectToClipPos(vertArray[next].vertex);
                            UNITY_TRANSFER_FOG(o, o.vertex);
                            o.uv = TRANSFORM_TEX(vertArray[next].uv, _MainTex);
                            o.color = (_ColorTip - _ColorBottom) * _Subdivisions / (_Subdivisions + 1) + _ColorBottom;;
                            triStream.Append(o);

                            triStream.RestartStrip();
                        }


                    
                }

                fixed4 frag(g2f i) : SV_Target
                {
                    // sample the texture
                    fixed4 col = tex2D(_MainTex, i.uv) * i.color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }

        }
}
