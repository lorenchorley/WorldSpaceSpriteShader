Shader "Sprites/WorldSpace-MoreTintOptions"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite", 2D) = "white" {}
		_OverlayTex("Overlay Texture", 2D) = "white" {}
		_TextureBlendRatio("Texture Blend Ratio [0, 1]", Float) = 0.5
		_Tint("Tint", Color) = (1,1,1,1)
		_TintBlendRatio("Tint Blend Ratio [0, 1]", Float) = 0.5
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
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
				float2 texcoord : TEXCOORD0;
				float2 texcoordWorld : TEXCOORD1;
			};

			v2f vert(appdata_t IN)
			{
				v2f OUT;

				OUT.texcoord = IN.texcoord;
				OUT.texcoordWorld = mul(unity_ObjectToWorld, IN.vertex);
				OUT.color = IN.color;

#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap(UnityObjectToClipPos(IN.vertex));
#else
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
#endif

				return OUT;
			}

			fixed4 _Tint;
			float _TintBlendRatio;
			float _TextureBlendRatio;
			sampler2D _MainTex;
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
				float textureblend = clamp(_TextureBlendRatio, 0.0, 1.0);
				float tintblend = clamp(_TintBlendRatio, 0.0, 1.0);

				fixed4 spriteColour = tex2D(_MainTex, IN.texcoord) * IN.color;
				float alpha = spriteColour.a;

				// Blend world space texture and sprite texture
				spriteColour = GetWorldSpaceTextureColour(IN.texcoordWorld) * textureblend + spriteColour * (1 - textureblend);

				// Blend texture and tint
				spriteColour = _Tint * tintblend + spriteColour * (1 - tintblend);

				// Reassert alpha and modify dropoffs
				spriteColour.a = alpha;
				spriteColour.rgb *= alpha;

				return spriteColour;
			}
			ENDCG
		}

	}

}
