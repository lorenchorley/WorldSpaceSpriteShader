Shader "Sprites/WorldSpace"
{
	Properties
	{
		_OverlayTex("Overlay Texture", 2D) = "white" {}
		[PerRendererData] _MaskTex("Shape Texture", 2D) = "white" {}
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
		_Color("Tint", Color) = (1,1,1,1)
		_BlendRatio("Tint Blend Ratio [0, 1]", Float) = 0.5
	}

	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Cull Off
		Lighting Off
		ZWrite Off  
		Blend One OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile _ PIXELSNAP_ON
			#pragma multi_compile _ SHOWFULLIMAGE_ON
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc" 

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord  : TEXCOORD0;
			};

			v2f vert(appdata_t IN)
			{
				v2f OUT;

				OUT.texcoord = mul(unity_ObjectToWorld, IN.vertex);
				OUT.color = IN.color;

#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap(UnityObjectToClipPos(IN.vertex));
#else
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
#endif

				return OUT;
			}

			fixed4 _Color;
			float _BlendRatio;
			sampler2D _OverlayTex;
			float4 _OverlayTex_ST; // Tiling (x, y) and offset (z, w)

			fixed4 GetWorldSpaceTextureColour(float2 uv)
			{
				float width = _OverlayTex_ST.x;
				if (width < 0)
					width = -width;

				float x = uv.x + _OverlayTex_ST.z;
				if (x < 0)
					x = 1 - fmod(-x, width) / width;
				else
					x = fmod(x, width) / width;

				float height = _OverlayTex_ST.y;
				if (height < 0)
					height = -height;

				float y = uv.y + _OverlayTex_ST.w;
				if (y < 0)
					y = 1 - fmod(-y, height) / height;
				else
					y = fmod(y, height) / height;

				return tex2D(_OverlayTex, float2(x, y));
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 spriteColor = GetWorldSpaceTextureColour(IN.texcoord) * IN.color;
				spriteColor.rgb *= spriteColor.a;

				float blend = clamp(_BlendRatio, 0.0, 1.0);

				return _Color * blend + spriteColor * (1 - blend);
			}
			ENDCG
		}

	}

}
