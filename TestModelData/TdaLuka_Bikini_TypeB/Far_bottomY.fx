////////////////////////////////////////////////////////////////////////////////////////////////
//
//	ビーム式ファーシェーダ
//	作成：ビームマンP
//
//	Tda Luka Bikini Type-BのTバックビキニボトム用に設定済み
//	- Bikini3 or Bikini4 only
//	- Set for BikiniBottomY
//
////////////////////////////////////////////////////////////////////////////////////////////////

// パラメータ宣言

//1層辺りの長さ
float FarSize = 0.01;

//毛層の量（量を多くすればするほど重くなる）
//int FAR_LENGTH = 50;
int FAR_LENGTH = 8;

//毛の移動量
//float FarMove = 0.02;
float FarMove = 0.01;

//毛の色変更
float3 FarColor = float3(1,1,1);

//根本の濃さ(0で真っ黒、1で毛先と一緒の色）
//float FarDepth = 0.8;
float FarDepth = 1.0;

//ハーフランバート係数(非Toonの時のみ）
float HLambParam = 0.5;

//ファーテクスチャスケール
//float FarTexScale = 2.0;
float FarTexScale = 1.0;

//---ファーマップテクスチャ読み込み
//ファーの量マップ
texture FarAmountMapTex
<
	string ResourceName = "sph/far_AmountMap_BottomY2.png";
>;
//ファーの傾きマップ
texture FarVectorMapTex
<
	string ResourceName = "sph/far_VectorMap.png";
>;
//基本ここから触らない
float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "sceneorobject";
    string ScriptOrder = "standard";
> = 0.8;


int index;

sampler MapSamp = sampler_state
{
	Texture = (FarAmountMapTex);
	ADDRESSU = WRAP;
	ADDRESSV = WRAP;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = LINEAR;
	MAXANISOTROPY = 16;
};
sampler VecMapSamp = sampler_state
{
	Texture = (FarVectorMapTex);
	ADDRESSU = WRAP;
	ADDRESSV = WRAP;
	MINFILTER = ANISOTROPIC;
	MAGFILTER = ANISOTROPIC;
	MIPFILTER = LINEAR;
	MAXANISOTROPY = 16;
};
// エフェクトの先頭に追加
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// ■ ExcellentShadowシステム　ここから↓

float X_SHADOWPOWER = 1.0;   //アクセサリ影濃さ
float PMD_SHADOWPOWER = 0.2; //モデル影濃さ


//スクリーンシャドウマップ取得
shared texture2D ScreenShadowMapProcessed : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "D3DFMT_R32F";
>;
sampler2D ScreenShadowMapProcessedSamp = sampler_state {
    texture = <ScreenShadowMapProcessed>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

// スクリーンサイズ
float2 ES_ViewportSize : VIEWPORTPIXELSIZE;
static float2 ES_ViewportOffset = (float2(0.5,0.5)/ES_ViewportSize);

bool Exist_ExcellentShadow : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;

float ShadowRate : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Tr"; >;


float3   ES_CameraPos1      : POSITION  < string Object = "Camera"; >;

float es_size0 : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Si"; >;
float4x4 es_mat1 : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;
static float3 es_move1 = float3(es_mat1._41, es_mat1._42, es_mat1._43 );

//カメラとシャドウ中心の距離
static float CameraDistance1 = length(ES_CameraPos1 - es_move1);


// ■ ExcellentShadowシステム　ここまで↑
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////




// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 ViewProjMatrix      : VIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// マテリアル色
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
// ライト色
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = min(1, MaterialAmbient * LightAmbient + MaterialEmmisive);
static float3 SpecularColor = MaterialSpecular * LightSpecular;

bool     parthf;   // パースペクティブフラグ
bool     transp;   // 半透明フラグ
bool     spadd;    // スフィアマップ加算合成フラグ
#define SKII1    1500
#define SKII2    8000
#define Toon     3

// オブジェクトのテクスチャ
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = LINEAR;
    MAXANISOTROPY = 16;
};

// スフィアマップのテクスチャ
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = LINEAR;
    MAXANISOTROPY = 16;
};

// MMD本来のsamplerを上書きしないための記述です。削除不可。
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

////////////////////////////////////////////////////////////////////////////////////////////////
// 輪郭描画

// 頂点シェーダ
float4 ColorRender_VS(float4 Pos : POSITION) : POSITION 
{
    // カメラ視点のワールドビュー射影変換
    return mul( Pos, WorldViewProjMatrix );
}

// ピクセルシェーダ
float4 ColorRender_PS() : COLOR
{
    // 輪郭色で塗りつぶし
    return EdgeColor;
}

// 輪郭描画用テクニック
technique EdgeTec < string MMDPass = "edge"; > {

}


///////////////////////////////////////////////////////////////////////////////////////////////
// 影（非セルフシャドウ）描画

// 頂点シェーダ
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // カメラ視点のワールドビュー射影変換
    return mul( Pos, WorldViewProjMatrix );
}

// ピクセルシェーダ
float4 Shadow_PS() : COLOR
{
    // アンビエント色で塗りつぶし
    return float4(AmbientColor.rgb, 0.65f);
}

// 影描画用テクニック
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_3_0 Shadow_VS();
        PixelShader  = compile ps_3_0 Shadow_PS();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
// オブジェクト描画（セルフシャドウOFF）

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // 射影変換座標
    float2 Tex        : TEXCOORD1;   // テクスチャ
    float3 Normal     : TEXCOORD2;   // 法線
    float3 Eye        : TEXCOORD3;   // カメラとの相対位置
    float2 SpTex      : TEXCOORD4;   // スフィアマップテクスチャ座標
    float3 WPos		  : TEXCOORD5;	 //ワールド座標
    float4 Color      : COLOR0;      // ディフューズ色
};

// 頂点シェーダ
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
        
    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // カメラとの相対位置
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix ).rgb;
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // テクスチャ座標
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // スフィアマップテクスチャ座標
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    return Out;
}
VS_OUTPUT BasicFar_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon,int myIndex : _INDEX)
{

    float fi = index;
    float ffl = FAR_LENGTH;
    fi = fi/ffl;
    
    VS_OUTPUT Out = (VS_OUTPUT)0;
    
    index += 1;
    
    Pos = mul(Pos,WorldMatrix);
    
    FarSize *= length(WorldMatrix[1])*1;
    Pos.xyz += normalize( mul( Normal, (float3x3)WorldMatrix ) )*index*FarSize;;
    
    Out.WPos = Pos;
    
    
    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, ViewProjMatrix );
    
    // カメラとの相対位置
    Out.Eye = CameraPosition - Pos.xyz;
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;

    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // テクスチャ座標
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // スフィアマップテクスチャ座標
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    return Out;
}
// ピクセルシェーダ
float4 Basic_PS(VS_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR0
{

    // スペキュラ色計算
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    float4 Color = IN.Color;
    
    
    
    if ( useTexture ) {
        // テクスチャ適用
        Color *= tex2D( ObjTexSampler, IN.Tex );
    }
    if ( useSphereMap ) {
        // スフィアマップ適用
        if(spadd) Color.rgb += tex2D(ObjSphareSampler,IN.SpTex).rgb;
        else      Color.rgb *= tex2D(ObjSphareSampler,IN.SpTex).rgb;
    }
    
    if ( useToon ) {
        // トゥーン適用
        float LightNormal = dot( IN.Normal, -LightDirection );
        Color.rgb *= lerp(MaterialToon, float3(1,1,1), saturate(LightNormal * 16 + 0.5));
    }
    
    // スペキュラ適用
    Color.rgb += Specular;
    
    return Color;
}

float time : TIME;

float4 BasicFar_PS(VS_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR0
{
    float fi = index;
    float ffl = FAR_LENGTH;
    fi = fi/ffl;
    
    float2 add = (tex2D(VecMapSamp,IN.Tex*FarTexScale).rg*2-1)*fi;
    
    //add.x += cos(time)*0.02*pow(fi,2);
    //add.y += sin(time)*0.02*pow(fi,2);
    
    add *= FarMove;
    
    float3 F_Eye = CameraPosition - IN.WPos.xyz;
    
    
    // スペキュラ色計算
    float3 HalfVector = normalize( normalize(F_Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    
    float d = 1-pow(saturate(dot(normalize(IN.Normal),normalize(F_Eye))),2);
    
    Specular *= d;
    
    float4 Color = IN.Color;
    
    float lambA = HLambParam;
    float lambB = 1-HLambParam;
    
    if(!useToon)
    {
	    Color.rgb = max(0,dot( normalize(IN.Normal), -LightDirection )*lambA+lambB) * DiffuseColor.rgb;
	}

    //毛の色変更
    Color.rgb *= FarColor;
    
    
    if ( useTexture ) {
        // テクスチャ適用
        Color *= tex2D( ObjTexSampler, IN.Tex+add );
    }
    if ( useSphereMap ) {
        // スフィアマップ適用
        if(spadd) Color.rgb += tex2D(ObjSphareSampler,IN.SpTex).rgb;
        else      Color.rgb *= tex2D(ObjSphareSampler,IN.SpTex).rgb;
    }
    
    if ( useToon ) {
        // トゥーン適用
        float LightNormal = dot( IN.Normal, -LightDirection );
        Color.rgb *= lerp(MaterialToon, float3(1,1,1), saturate(LightNormal * 16 + 0.5));
    }
    
    // スペキュラ適用
    Color.rgb += Specular;
    Color.rgb *= lerp(fi,1,FarDepth);
    
    Color.a *= tex2D(MapSamp,IN.Tex*FarTexScale+add).r;
    Color.a *= 1-fi;
    
    return Color;
}

#define SCRIPT string Script = "RenderColorTarget0=;"\
"RenderDepthStencilTarget=;"\
\
"ClearSetColor=ClearColor;"\
"ClearSetDepth=ClearDepth;"\
\
"RenderColorTarget0=;"\
"RenderDepthStencilTarget=;"\
"Pass=DrawObject;"\
"LoopByCount=FAR_LENGTH;"\
"LoopGetIndex=index;"\
"Pass=DrawFar;"\
"LoopEnd=;"\
;


#define FARBLENDOP \
BLENDOP = ADD;\
SRCBLEND = SRCALPHA;\
DESTBLEND = INVSRCALPHA;\
ZWRITEENABLE = FALSE;\
CULLMODE = NONE;\

float4 ClearColor = {0,0,0,1};
float ClearDepth  = 1.0;


// オブジェクト描画用テクニック（アクセサリ用）
// 不要なものは削除可
technique MainTec0 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = false; SCRIPT>{
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, false, false);
        PixelShader  = compile ps_3_0 Basic_PS(false, false, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, false, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, false, false);
    }
}

technique MainTec1 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, false, false);
        PixelShader  = compile ps_3_0 Basic_PS(true, false, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, false, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, false, false);
    }
}

technique MainTec2 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, true, false);
        PixelShader  = compile ps_3_0 Basic_PS(false, true, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, true, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, true, false);
    }
}

technique MainTec3 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, true, false);
        PixelShader  = compile ps_3_0 Basic_PS(true, true, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, true, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, true, false);
    }
}

// オブジェクト描画用テクニック（PMDモデル用）
technique MainTec4 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, false, true);
        PixelShader  = compile ps_3_0 Basic_PS(false, false, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, false, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, false, true);
    }
}

technique MainTec5 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, false, true);
        PixelShader  = compile ps_3_0 Basic_PS(true, false, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, false, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, false, true);
    }
}

technique MainTec6 < string MMDPass = "object"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(false, true, true);
        PixelShader  = compile ps_3_0 Basic_PS(false, true, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, true, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, true, true);
    }
}

technique MainTec7 < string MMDPass = "object"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS(true, true, true);
        PixelShader  = compile ps_3_0 Basic_PS(true, true, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, true, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, true, true);
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// セルフシャドウ用Z値プロット

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // 射影変換座標
    float4 ShadowMapTex : TEXCOORD0;    // Zバッファテクスチャ
};

// 頂点シェーダ
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION )
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ライトの目線によるワールドビュー射影変換をする
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // テクスチャ座標を頂点に合わせる
    Out.ShadowMapTex = Out.Pos;

    return Out;
}

// ピクセルシェーダ
float4 ZValuePlot_PS( float4 ShadowMapTex : TEXCOORD0 ) : COLOR
{
    // R色成分にZ値を記録する
    return float4(ShadowMapTex.z/ShadowMapTex.w,0,0,1);
}

// Z値プロット用テクニック
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 ZValuePlot_VS();
        PixelShader  = compile ps_3_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// オブジェクト描画（セルフシャドウON）

// シャドウバッファのサンプラ。"register(s0)"なのはMMDがs0を使っているから
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // 射影変換座標
    float4 ZCalcTex : TEXCOORD0;    // Z値
    float2 Tex      : TEXCOORD1;    // テクスチャ
    float3 Normal   : TEXCOORD2;    // 法線
    float3 Eye      : TEXCOORD3;    // カメラとの相対位置
    float2 SpTex    : TEXCOORD4;    // スフィアマップテクスチャ座標
    float3 WPos		: TEXCOORD5;	 //ワールド座標
    float4 Color    : COLOR0;       // ディフューズ色
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ■ ExcellentShadowシステム　ここから↓
    
    float4 ScreenTex : TEXCOORD6;   // スクリーン座標
    
    // ■ ExcellentShadowシステム　ここまで↑
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // BufferShadow_OUTPUT構造体のメンバに追加
    // エラーが出るときはTEXCOORD5をTEXCOORD6などにしてみる
    
};

// 頂点シェーダ
BufferShadow_OUTPUT BufferShadow_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;
    
    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // カメラとの相対位置
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix ).rgb;
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ライト視点によるワールドビュー射影変換
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // テクスチャ座標
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // スフィアマップテクスチャ座標
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ■ ExcellentShadowシステム　ここから↓
    
    //スクリーン座標取得
    Out.ScreenTex = Out.Pos;
    
    //超遠景におけるちらつき防止
    Out.Pos.z -= max(0, (int)((CameraDistance1 - 6000) * 0.05));
    
    // ■ ExcellentShadowシステム　ここまで↑
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ↓の「return Out;」の直前に追加
    
    return Out;
}
BufferShadow_OUTPUT BufferShadowFar_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon, int myindex: _INDEX)
{
    float fi = index;
    float ffl = FAR_LENGTH;
    fi = fi/ffl;
    
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;

    index += 1;
    
    Pos = mul(Pos,WorldMatrix);
        
    FarSize *= length(WorldMatrix[1])*1;
    Pos.xyz += normalize( mul( Normal, (float3x3)WorldMatrix ) )*index*FarSize;
    
    Out.WPos = Pos;
    
    
    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, ViewProjMatrix );
    
    // カメラとの相対位置
    Out.Eye = CameraPosition - Pos.rgb;
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ライト視点によるワールドビュー射影変換
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // テクスチャ座標
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // スフィアマップテクスチャ座標
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ■ ExcellentShadowシステム　ここから↓
    
    //スクリーン座標取得
    Out.ScreenTex = Out.Pos;
    
    //超遠景におけるちらつき防止
    Out.Pos.z -= max(0, (int)((CameraDistance1 - 6000) * 0.05));
    
    // ■ ExcellentShadowシステム　ここまで↑
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ↓の「return Out;」の直前に追加
    
    return Out;
}

// ピクセルシェーダ
float4 BufferShadow_PS(BufferShadow_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR
{
    // スペキュラ色計算
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    
    float4 Color = IN.Color;
    float4 ShadowColor = float4(AmbientColor, Color.a);  // 影の色
    if ( useTexture ) {
        // テクスチャ適用
        float4 TexColor = tex2D( ObjTexSampler, IN.Tex );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }
    if ( useSphereMap ) {
        // スフィアマップ適用
        float4 TexColor = tex2D(ObjSphareSampler,IN.SpTex);
        if(spadd) {
            Color.rgb += TexColor.rgb;
            ShadowColor.rgb += TexColor.rgb;
        } else {
            Color.rgb *= TexColor.rgb;
            ShadowColor.rgb *= TexColor.rgb;
        }
    }
    // スペキュラ適用
    Color.rgb += Specular;
    
    
    
    // テクスチャ座標に変換
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x) * 0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y) * 0.5f;
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ■ ExcellentShadowシステム　ここから↓
    
    if(Exist_ExcellentShadow){
        
        IN.ScreenTex.xyz /= IN.ScreenTex.w;
        float2 TransScreenTex;
        TransScreenTex.x = (1.0f + IN.ScreenTex.x) * 0.5f;
        TransScreenTex.y = (1.0f - IN.ScreenTex.y) * 0.5f;
        float4 SadowMapVal = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex + ES_ViewportOffset).r;
        
        if ( useToon ) {
            // トゥーン適用
            SadowMapVal = min(saturate(dot(IN.Normal, -LightDirection) * Toon), SadowMapVal);
            ShadowColor.rgb *= MaterialToon;
            
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * PMD_SHADOWPOWER);
        }else{
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * X_SHADOWPOWER);
        }
        
        Color = lerp(ShadowColor, Color, SadowMapVal);
        
        return Color;
        
    } else 
    
    // ■ ExcellentShadowシステム　ここまで↑
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ↓の「if」の直前に追加
    
    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
        // シャドウバッファ外
        return Color;
        
    } else {
        float comp;
        float dist = IN.ZCalcTex.z - tex2D(DefSampler,TransTexCoord).r;
        
        if(parthf) {
            // セルフシャドウ mode2
            comp = 1 - saturate(max(dist, 0.0f)* SKII2 * TransTexCoord.y - 0.3f);
        } else {
            // セルフシャドウ mode1
            comp = 1 - saturate(max(dist, 0.0f) * SKII1 - 0.3f);
        }
        if ( useToon ) {
            // トゥーン適用
            comp = min(saturate(dot(IN.Normal, -LightDirection) * Toon), comp);
            ShadowColor.rgb *= MaterialToon;
        }
        
        float4 ans = lerp(ShadowColor, Color, comp);
        if( transp ) ans.a = 0.5f;
        
        return ans;
    }
    
    
}
float4 BufferShadowFar_PS(BufferShadow_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR
{
    float fi = index;
    float ffl = FAR_LENGTH;
    fi = fi/ffl;
    
    float2 add = (tex2D(VecMapSamp,IN.Tex*FarTexScale).rg*2-1)*fi;
    
    //add.x += cos(time)*0.02*pow(fi,2);
    //add.y += sin(time)*0.02*pow(fi,2);
    
    add *= FarMove;
    
    float3 F_Eye = CameraPosition - IN.WPos.xyz;
    
    
    // スペキュラ色計算
    float3 HalfVector = normalize( normalize(F_Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    
    float d = 1-pow(saturate(dot(normalize(IN.Normal),normalize(F_Eye))),2);
    
    Specular *= d;
    
    float4 Color = IN.Color;
    
    float lambA = HLambParam;
    float lambB = 1-HLambParam;
    
    
    float4 ShadowColor = float4(AmbientColor, Color.a);  // 影の色
    
    if(!useToon)
    {
	    float3 Dif = max(0,dot( normalize(IN.Normal), -LightDirection )*lambA+lambB) * DiffuseColor.rgb;
	    Color.rgb *= Dif;
    	ShadowColor.rgb *= Dif;
	}

    //毛の色変更
    Color.rgb *= FarColor;
    ShadowColor.rgb *= FarColor;
    
    if ( useTexture ) {
        // テクスチャ適用
        float4 TexColor = tex2D( ObjTexSampler, IN.Tex+add );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }
    if ( useSphereMap ) {
        // スフィアマップ適用
        float4 TexColor = tex2D(ObjSphareSampler,IN.SpTex);
        if(spadd) {
            Color.rgb += TexColor.rgb;
            ShadowColor.rgb += TexColor.rgb;
        } else {
            Color.rgb *= TexColor.rgb;
            ShadowColor.rgb *= TexColor.rgb;
        }
    }
    // スペキュラ適用
    Color.rgb += Specular;
    
    Color.rgb *= lerp(fi,1,FarDepth);
    ShadowColor.rgb *= lerp(fi,1,FarDepth);

	float far = tex2D(MapSamp,IN.Tex*FarTexScale+add).r;
    Color.a *= far;
    ShadowColor.a *= far;
    
    Color.a *= 1-fi;
    ShadowColor.a *= 1-fi;
    // テクスチャ座標に変換
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x) * 0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y) * 0.5f;
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ■ ExcellentShadowシステム　ここから↓
    
    if(Exist_ExcellentShadow){
        
        IN.ScreenTex.xyz /= IN.ScreenTex.w;
        float2 TransScreenTex;
        TransScreenTex.x = (1.0f + IN.ScreenTex.x) * 0.5f;
        TransScreenTex.y = (1.0f - IN.ScreenTex.y) * 0.5f;
        float4 SadowMapVal = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex + ES_ViewportOffset).r;
        
        if ( useToon ) {
            // トゥーン適用
            SadowMapVal = min(saturate(dot(IN.Normal, -LightDirection) * Toon), SadowMapVal);
            ShadowColor.rgb *= MaterialToon;
            
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * PMD_SHADOWPOWER);
        }else{
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * X_SHADOWPOWER);
        }
        
        Color = lerp(ShadowColor, Color, SadowMapVal);
        
        return Color;
        
    } else 
    
    // ■ ExcellentShadowシステム　ここまで↑
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ↓の「if」の直前に追加
    
    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
        // シャドウバッファ外
        return Color;
        
    } else {
        float comp;
        float dist = IN.ZCalcTex.z - tex2D(DefSampler,TransTexCoord).r;
        
        if(parthf) {
            // セルフシャドウ mode2
            comp = 1 - saturate(max(dist, 0.0f)* SKII2 * TransTexCoord.y - 0.3f);
        } else {
            // セルフシャドウ mode1
            comp = 1 - saturate(max(dist, 0.0f) * SKII1 - 0.3f);
        }
        if ( useToon ) {
            // トゥーン適用
            comp = min(saturate(dot(IN.Normal, -LightDirection) * Toon), comp);
            ShadowColor.rgb *= MaterialToon;
        }
        
        float4 ans = lerp(ShadowColor, Color, comp);
        if( transp ) ans.a = 0.5f;
        
        return ans;
    }
    
    
}
// オブジェクト描画用テクニック（アクセサリ用）
technique MainTecBS0  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, false, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, false, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, false, false);
    }
}

technique MainTecBS1  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, false, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, false, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, false, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, false, false);
    }
}

technique MainTecBS2  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, true, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, true, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, true, false);
    }
}

technique MainTecBS3  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = false; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, true, false);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, true, false);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, true, false);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, true, false);
    }
}

// オブジェクト描画用テクニック（PMDモデル用）
technique MainTecBS4  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = false; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, false, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(false, false, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(false, false, true);
    }
}

technique MainTecBS5  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = false; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, false, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, false, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BufferShadowFar_VS(true, false, true);
        PixelShader  = compile ps_3_0 BufferShadowFar_PS(true, false, true);
    }
}

technique MainTecBS6  < string MMDPass = "object_ss"; bool UseTexture = false; bool UseSphereMap = true; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(false, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(false, true, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BufferShadowFar_VS(false, true, true);
        PixelShader  = compile ps_3_0 BufferShadowFar_PS(false, true, true);
    }
}

technique MainTecBS7  < string MMDPass = "object_ss"; bool UseTexture = true; bool UseSphereMap = true; bool UseToon = true; SCRIPT> {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS(true, true, true);
        PixelShader  = compile ps_3_0 BufferShadow_PS(true, true, true);
    }
    pass DrawFar {
    	FARBLENDOP
        VertexShader = compile vs_3_0 BasicFar_VS(true, true, true);
        PixelShader  = compile ps_3_0 BasicFar_PS(true, true, true);
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
