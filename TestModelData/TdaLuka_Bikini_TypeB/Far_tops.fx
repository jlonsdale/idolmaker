////////////////////////////////////////////////////////////////////////////////////////////////
//
//	�r�[�����t�@�[�V�F�[�_
//	�쐬�F�r�[���}��P
//
//	Tda Luka Bikini Type-B�̃r�L�j�g�b�v�p�ɐݒ�ς�
//	- Bikini3 or Bikini4 only
//	- Set for BikiniTop1
//
////////////////////////////////////////////////////////////////////////////////////////////////

// �p�����[�^�錾

//1�w�ӂ�̒���
float FarSize = 0.01;

//�ёw�̗ʁi�ʂ𑽂�����΂���قǏd���Ȃ�j
//int FAR_LENGTH = 50;
int FAR_LENGTH = 8;

//�т̈ړ���
//float FarMove = 0.02;
float FarMove = 0.01;

//�т̐F�ύX
float3 FarColor = float3(1,1,1);

//���{�̔Z��(0�Ő^�����A1�Ŗѐ�ƈꏏ�̐F�j
//float FarDepth = 0.8;
float FarDepth = 1.0;

//�n�[�t�����o�[�g�W��(��Toon�̎��̂݁j
float HLambParam = 0.5;

//�t�@�[�e�N�X�`���X�P�[��
//float FarTexScale = 2.0;
float FarTexScale = 1.0;

//---�t�@�[�}�b�v�e�N�X�`���ǂݍ���
//�t�@�[�̗ʃ}�b�v
texture FarAmountMapTex
<
	string ResourceName = "sph/far_AmountMap_Tops2.png";
>;
//�t�@�[�̌X���}�b�v
texture FarVectorMapTex
<
	string ResourceName = "sph/far_VectorMap.png";
>;
//��{��������G��Ȃ�
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
// �G�t�F�N�g�̐擪�ɒǉ�
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
// �� ExcellentShadow�V�X�e���@�������火

float X_SHADOWPOWER = 1.0;   //�A�N�Z�T���e�Z��
float PMD_SHADOWPOWER = 0.2; //���f���e�Z��


//�X�N���[���V���h�E�}�b�v�擾
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

// �X�N���[���T�C�Y
float2 ES_ViewportSize : VIEWPORTPIXELSIZE;
static float2 ES_ViewportOffset = (float2(0.5,0.5)/ES_ViewportSize);

bool Exist_ExcellentShadow : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;

float ShadowRate : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Tr"; >;


float3   ES_CameraPos1      : POSITION  < string Object = "Camera"; >;

float es_size0 : CONTROLOBJECT < string name = "ExcellentShadow.x"; string item = "Si"; >;
float4x4 es_mat1 : CONTROLOBJECT < string name = "ExcellentShadow.x"; >;
static float3 es_move1 = float3(es_mat1._41, es_mat1._42, es_mat1._43 );

//�J�����ƃV���h�E���S�̋���
static float CameraDistance1 = length(ES_CameraPos1 - es_move1);


// �� ExcellentShadow�V�X�e���@�����܂Ł�
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////




// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 ViewProjMatrix      : VIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
// ���C�g�F
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = min(1, MaterialAmbient * LightAmbient + MaterialEmmisive);
static float3 SpecularColor = MaterialSpecular * LightSpecular;

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
bool     spadd;    // �X�t�B�A�}�b�v���Z�����t���O
#define SKII1    1500
#define SKII2    8000
#define Toon     3

// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = LINEAR;
    MAXANISOTROPY = 16;
};

// �X�t�B�A�}�b�v�̃e�N�X�`��
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = ANISOTROPIC;
    MAGFILTER = ANISOTROPIC;
    MIPFILTER = LINEAR;
    MAXANISOTROPY = 16;
};

// MMD�{����sampler���㏑�����Ȃ����߂̋L�q�ł��B�폜�s�B
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

////////////////////////////////////////////////////////////////////////////////////////////////
// �֊s�`��

// ���_�V�F�[�_
float4 ColorRender_VS(float4 Pos : POSITION) : POSITION 
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 ColorRender_PS() : COLOR
{
    // �֊s�F�œh��Ԃ�
    return EdgeColor;
}

// �֊s�`��p�e�N�j�b�N
technique EdgeTec < string MMDPass = "edge"; > {

}


///////////////////////////////////////////////////////////////////////////////////////////////
// �e�i��Z���t�V���h�E�j�`��

// ���_�V�F�[�_
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 Shadow_PS() : COLOR
{
    // �A���r�G���g�F�œh��Ԃ�
    return float4(AmbientColor.rgb, 0.65f);
}

// �e�`��p�e�N�j�b�N
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_3_0 Shadow_VS();
        PixelShader  = compile ps_3_0 Shadow_PS();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EOFF�j

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // �ˉe�ϊ����W
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
    float3 Normal     : TEXCOORD2;   // �@��
    float3 Eye        : TEXCOORD3;   // �J�����Ƃ̑��Έʒu
    float2 SpTex      : TEXCOORD4;   // �X�t�B�A�}�b�v�e�N�X�`�����W
    float3 WPos		  : TEXCOORD5;	 //���[���h���W
    float4 Color      : COLOR0;      // �f�B�t���[�Y�F
};

// ���_�V�F�[�_
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
        
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix ).rgb;
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
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
    
    
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, ViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - Pos.xyz;
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;

    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    return Out;
}
// �s�N�Z���V�F�[�_
float4 Basic_PS(VS_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR0
{

    // �X�y�L�����F�v�Z
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    float4 Color = IN.Color;
    
    
    
    if ( useTexture ) {
        // �e�N�X�`���K�p
        Color *= tex2D( ObjTexSampler, IN.Tex );
    }
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�K�p
        if(spadd) Color.rgb += tex2D(ObjSphareSampler,IN.SpTex).rgb;
        else      Color.rgb *= tex2D(ObjSphareSampler,IN.SpTex).rgb;
    }
    
    if ( useToon ) {
        // �g�D�[���K�p
        float LightNormal = dot( IN.Normal, -LightDirection );
        Color.rgb *= lerp(MaterialToon, float3(1,1,1), saturate(LightNormal * 16 + 0.5));
    }
    
    // �X�y�L�����K�p
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
    
    
    // �X�y�L�����F�v�Z
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

    //�т̐F�ύX
    Color.rgb *= FarColor;
    
    
    if ( useTexture ) {
        // �e�N�X�`���K�p
        Color *= tex2D( ObjTexSampler, IN.Tex+add );
    }
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�K�p
        if(spadd) Color.rgb += tex2D(ObjSphareSampler,IN.SpTex).rgb;
        else      Color.rgb *= tex2D(ObjSphareSampler,IN.SpTex).rgb;
    }
    
    if ( useToon ) {
        // �g�D�[���K�p
        float LightNormal = dot( IN.Normal, -LightDirection );
        Color.rgb *= lerp(MaterialToon, float3(1,1,1), saturate(LightNormal * 16 + 0.5));
    }
    
    // �X�y�L�����K�p
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


// �I�u�W�F�N�g�`��p�e�N�j�b�N�i�A�N�Z�T���p�j
// �s�v�Ȃ��͍̂폜��
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

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
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
// �Z���t�V���h�E�pZ�l�v���b�g

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // �ˉe�ϊ����W
    float4 ShadowMapTex : TEXCOORD0;    // Z�o�b�t�@�e�N�X�`��
};

// ���_�V�F�[�_
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION )
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ���C�g�̖ڐ��ɂ�郏�[���h�r���[�ˉe�ϊ�������
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // �e�N�X�`�����W�𒸓_�ɍ��킹��
    Out.ShadowMapTex = Out.Pos;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 ZValuePlot_PS( float4 ShadowMapTex : TEXCOORD0 ) : COLOR
{
    // R�F������Z�l���L�^����
    return float4(ShadowMapTex.z/ShadowMapTex.w,0,0,1);
}

// Z�l�v���b�g�p�e�N�j�b�N
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 ZValuePlot_VS();
        PixelShader  = compile ps_3_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EON�j

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // �ˉe�ϊ����W
    float4 ZCalcTex : TEXCOORD0;    // Z�l
    float2 Tex      : TEXCOORD1;    // �e�N�X�`��
    float3 Normal   : TEXCOORD2;    // �@��
    float3 Eye      : TEXCOORD3;    // �J�����Ƃ̑��Έʒu
    float2 SpTex    : TEXCOORD4;    // �X�t�B�A�}�b�v�e�N�X�`�����W
    float3 WPos		: TEXCOORD5;	 //���[���h���W
    float4 Color    : COLOR0;       // �f�B�t���[�Y�F
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // �� ExcellentShadow�V�X�e���@�������火
    
    float4 ScreenTex : TEXCOORD6;   // �X�N���[�����W
    
    // �� ExcellentShadow�V�X�e���@�����܂Ł�
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // BufferShadow_OUTPUT�\���̂̃����o�ɒǉ�
    // �G���[���o��Ƃ���TEXCOORD5��TEXCOORD6�Ȃǂɂ��Ă݂�
    
};

// ���_�V�F�[�_
BufferShadow_OUTPUT BufferShadow_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;
    
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix ).rgb;
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // �� ExcellentShadow�V�X�e���@�������火
    
    //�X�N���[�����W�擾
    Out.ScreenTex = Out.Pos;
    
    //�����i�ɂ����邿����h�~
    Out.Pos.z -= max(0, (int)((CameraDistance1 - 6000) * 0.05));
    
    // �� ExcellentShadow�V�X�e���@�����܂Ł�
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ���́ureturn Out;�v�̒��O�ɒǉ�
    
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
    
    
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, ViewProjMatrix );
    
    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - Pos.rgb;
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );
    
    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    if ( !useToon ) {
        Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    }
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );
    
    // �e�N�X�`�����W
    Out.Tex = Tex;
    
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�e�N�X�`�����W
        float2 NormalWV = mul( Out.Normal, (float3x3)ViewMatrix ).xy;
        Out.SpTex.x = NormalWV.x * 0.5f + 0.5f;
        Out.SpTex.y = NormalWV.y * -0.5f + 0.5f;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // �� ExcellentShadow�V�X�e���@�������火
    
    //�X�N���[�����W�擾
    Out.ScreenTex = Out.Pos;
    
    //�����i�ɂ����邿����h�~
    Out.Pos.z -= max(0, (int)((CameraDistance1 - 6000) * 0.05));
    
    // �� ExcellentShadow�V�X�e���@�����܂Ł�
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ���́ureturn Out;�v�̒��O�ɒǉ�
    
    return Out;
}

// �s�N�Z���V�F�[�_
float4 BufferShadow_PS(BufferShadow_OUTPUT IN, uniform bool useTexture, uniform bool useSphereMap, uniform bool useToon) : COLOR
{
    // �X�y�L�����F�v�Z
    float3 HalfVector = normalize( normalize(IN.Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    
    float4 Color = IN.Color;
    float4 ShadowColor = float4(AmbientColor, Color.a);  // �e�̐F
    if ( useTexture ) {
        // �e�N�X�`���K�p
        float4 TexColor = tex2D( ObjTexSampler, IN.Tex );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�K�p
        float4 TexColor = tex2D(ObjSphareSampler,IN.SpTex);
        if(spadd) {
            Color.rgb += TexColor.rgb;
            ShadowColor.rgb += TexColor.rgb;
        } else {
            Color.rgb *= TexColor.rgb;
            ShadowColor.rgb *= TexColor.rgb;
        }
    }
    // �X�y�L�����K�p
    Color.rgb += Specular;
    
    
    
    // �e�N�X�`�����W�ɕϊ�
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x) * 0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y) * 0.5f;
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // �� ExcellentShadow�V�X�e���@�������火
    
    if(Exist_ExcellentShadow){
        
        IN.ScreenTex.xyz /= IN.ScreenTex.w;
        float2 TransScreenTex;
        TransScreenTex.x = (1.0f + IN.ScreenTex.x) * 0.5f;
        TransScreenTex.y = (1.0f - IN.ScreenTex.y) * 0.5f;
        float4 SadowMapVal = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex + ES_ViewportOffset).r;
        
        if ( useToon ) {
            // �g�D�[���K�p
            SadowMapVal = min(saturate(dot(IN.Normal, -LightDirection) * Toon), SadowMapVal);
            ShadowColor.rgb *= MaterialToon;
            
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * PMD_SHADOWPOWER);
        }else{
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * X_SHADOWPOWER);
        }
        
        Color = lerp(ShadowColor, Color, SadowMapVal);
        
        return Color;
        
    } else 
    
    // �� ExcellentShadow�V�X�e���@�����܂Ł�
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ���́uif�v�̒��O�ɒǉ�
    
    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
        // �V���h�E�o�b�t�@�O
        return Color;
        
    } else {
        float comp;
        float dist = IN.ZCalcTex.z - tex2D(DefSampler,TransTexCoord).r;
        
        if(parthf) {
            // �Z���t�V���h�E mode2
            comp = 1 - saturate(max(dist, 0.0f)* SKII2 * TransTexCoord.y - 0.3f);
        } else {
            // �Z���t�V���h�E mode1
            comp = 1 - saturate(max(dist, 0.0f) * SKII1 - 0.3f);
        }
        if ( useToon ) {
            // �g�D�[���K�p
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
    
    
    // �X�y�L�����F�v�Z
    float3 HalfVector = normalize( normalize(F_Eye) + -LightDirection );
    float3 Specular = pow( max(0,dot( HalfVector, normalize(IN.Normal) )), SpecularPower ) * SpecularColor;
    
    float d = 1-pow(saturate(dot(normalize(IN.Normal),normalize(F_Eye))),2);
    
    Specular *= d;
    
    float4 Color = IN.Color;
    
    float lambA = HLambParam;
    float lambB = 1-HLambParam;
    
    
    float4 ShadowColor = float4(AmbientColor, Color.a);  // �e�̐F
    
    if(!useToon)
    {
	    float3 Dif = max(0,dot( normalize(IN.Normal), -LightDirection )*lambA+lambB) * DiffuseColor.rgb;
	    Color.rgb *= Dif;
    	ShadowColor.rgb *= Dif;
	}

    //�т̐F�ύX
    Color.rgb *= FarColor;
    ShadowColor.rgb *= FarColor;
    
    if ( useTexture ) {
        // �e�N�X�`���K�p
        float4 TexColor = tex2D( ObjTexSampler, IN.Tex+add );
        Color *= TexColor;
        ShadowColor *= TexColor;
    }
    if ( useSphereMap ) {
        // �X�t�B�A�}�b�v�K�p
        float4 TexColor = tex2D(ObjSphareSampler,IN.SpTex);
        if(spadd) {
            Color.rgb += TexColor.rgb;
            ShadowColor.rgb += TexColor.rgb;
        } else {
            Color.rgb *= TexColor.rgb;
            ShadowColor.rgb *= TexColor.rgb;
        }
    }
    // �X�y�L�����K�p
    Color.rgb += Specular;
    
    Color.rgb *= lerp(fi,1,FarDepth);
    ShadowColor.rgb *= lerp(fi,1,FarDepth);

	float far = tex2D(MapSamp,IN.Tex*FarTexScale+add).r;
    Color.a *= far;
    ShadowColor.a *= far;
    
    Color.a *= 1-fi;
    ShadowColor.a *= 1-fi;
    // �e�N�X�`�����W�ɕϊ�
    IN.ZCalcTex /= IN.ZCalcTex.w;
    float2 TransTexCoord;
    TransTexCoord.x = (1.0f + IN.ZCalcTex.x) * 0.5f;
    TransTexCoord.y = (1.0f - IN.ZCalcTex.y) * 0.5f;
    
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // �� ExcellentShadow�V�X�e���@�������火
    
    if(Exist_ExcellentShadow){
        
        IN.ScreenTex.xyz /= IN.ScreenTex.w;
        float2 TransScreenTex;
        TransScreenTex.x = (1.0f + IN.ScreenTex.x) * 0.5f;
        TransScreenTex.y = (1.0f - IN.ScreenTex.y) * 0.5f;
        float4 SadowMapVal = tex2D(ScreenShadowMapProcessedSamp, TransScreenTex + ES_ViewportOffset).r;
        
        if ( useToon ) {
            // �g�D�[���K�p
            SadowMapVal = min(saturate(dot(IN.Normal, -LightDirection) * Toon), SadowMapVal);
            ShadowColor.rgb *= MaterialToon;
            
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * PMD_SHADOWPOWER);
        }else{
            ShadowColor.rgb *= (1 - (1 - ShadowRate) * X_SHADOWPOWER);
        }
        
        Color = lerp(ShadowColor, Color, SadowMapVal);
        
        return Color;
        
    } else 
    
    // �� ExcellentShadow�V�X�e���@�����܂Ł�
    /////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    // ���́uif�v�̒��O�ɒǉ�
    
    if( any( saturate(TransTexCoord) != TransTexCoord ) ) {
        // �V���h�E�o�b�t�@�O
        return Color;
        
    } else {
        float comp;
        float dist = IN.ZCalcTex.z - tex2D(DefSampler,TransTexCoord).r;
        
        if(parthf) {
            // �Z���t�V���h�E mode2
            comp = 1 - saturate(max(dist, 0.0f)* SKII2 * TransTexCoord.y - 0.3f);
        } else {
            // �Z���t�V���h�E mode1
            comp = 1 - saturate(max(dist, 0.0f) * SKII1 - 0.3f);
        }
        if ( useToon ) {
            // �g�D�[���K�p
            comp = min(saturate(dot(IN.Normal, -LightDirection) * Toon), comp);
            ShadowColor.rgb *= MaterialToon;
        }
        
        float4 ans = lerp(ShadowColor, Color, comp);
        if( transp ) ans.a = 0.5f;
        
        return ans;
    }
    
    
}
// �I�u�W�F�N�g�`��p�e�N�j�b�N�i�A�N�Z�T���p�j
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

// �I�u�W�F�N�g�`��p�e�N�j�b�N�iPMD���f���p�j
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
