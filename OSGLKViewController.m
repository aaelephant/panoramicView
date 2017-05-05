//
//  OSGLKViewController.m
//  OpenGLES_Draw_Sphere
//
//  Created by xu jie on 16/9/25.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "OSGLKViewController.h"

#import <OpenGLES/ES2/gl.h>
#import "OSSphere.h"
#import "DeviceOritation.h"

@interface OSGLKViewController (){
    GLfloat   *_vertexData; // 顶点数据
    GLfloat   *_texCoords;  // 纹理坐标
    GLushort  *_indices;    // 顶点索引
    GLint    _numVetex;   // 顶点数量
    GLuint   _vertexBuffer; // 顶点内存标识
    GLuint  _texCoordsBuffer;// 纹理坐标内存标识
    GLuint  _numIndices;
    GLuint _uniformViewProjectionMatrix;
}
@property(nonatomic,strong)GLKBaseEffect *baseEffect;
@end

@implementation OSGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化
    [self setUp];
    // 创建顶点坐标
    [self createSphereData];
    // 载入顶点数据到GPU
    [self loadVertexData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-----------------------------------------------------------
#pragma mark -
#pragma mark - 初始化代码
//-----------------------------------------------------------
-(void)setUp{
    GLKView *glkView = (GLKView*)self.view;
    glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;// 设置深度缓冲区格式
    // 创建管理上下文
    glkView.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    // 设置当前上下文
    [EAGLContext setCurrentContext:glkView.context];
    
    // 配置渲染器
    self.baseEffect = [[GLKBaseEffect alloc]init];
    
    // 将我们的地图照片加载到渲染其中
    GLKTextureInfo *textureInfo =
    [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:@"PanoramaLaunchImage.jpg"].CGImage options:nil error:nil];
    self.baseEffect.texture2d0.target = textureInfo.target;
    self.baseEffect.texture2d0.name = textureInfo.name;
    
    
    
  
 
}

//-----------------------------------------------------------
#pragma mark -
#pragma mark - 加载顶点数据
//-----------------------------------------------------------

-(void)loadVertexData{
    
    // 加载顶点坐标数据
    glGenBuffers(1, &_vertexBuffer); // 申请内存
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer); // 将命名的缓冲对象绑定到指定的类型上去
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*_numVetex*3,_vertexData, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);  // 绑定到位置上
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), NULL);
    
    // 加载顶点索引数据
    GLuint _indexBuffer;
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, _numIndices*sizeof(GLushort), _indices, GL_STATIC_DRAW);
    

    glGenBuffers(1, &_uniformViewProjectionMatrix);
    
    // 加载纹理坐标
    glGenBuffers(1, &_texCoordsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _texCoordsBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*_numVetex*2, _texCoords, GL_DYNAMIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(GLfloat), NULL);
    
}

//-----------------------------------------------------------
#pragma mark -
#pragma mark - 生成顶点数据
//-----------------------------------------------------------

- (void)createSphereData{
   _numIndices = generateSphere(200, 1.0, &(_vertexData), &(_texCoords), &_indices, &_numVetex);
//    _numIndices = generateSquare(&(_vertexData), &_indices, &(_texCoords), &_numVetex);
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    // 清除颜色缓冲区
    glClearColor(1.0, 0, 1.0, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    // 绘制之前必须调用这个方法
    [self.baseEffect prepareToDraw];
  
    
    static int i =1;
//    if (i < _numIndices-2000){
//        i = i+1000;
//    }else{
        i = _numIndices;
//    }
    // 设置世界坐标和视角
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    //    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(110.0f), aspect, 0.1f, 200.0f);
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.01f, 0.0f, -1.0f, 0.0f);
    //陀螺仪数据
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
        modelViewMatrix = GLKMatrix4Multiply([[DeviceOritation _sharedInstance] getDeviceOrientationMatrix], modelViewMatrix);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, - M_PI_2, 0.0f, 1.0f, 0.0f);
    
    modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, viewMatrix);
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    
//    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
//    glEnable(GL_BLEND);
//    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);// 开启透明度融合，是的透明处与深度更深的像素融合，否则显示黑色。
    
    glViewport(0, 0, self.view.bounds.size.width*[[UIScreen mainScreen] scale], self.view.bounds.size.height*[[UIScreen mainScreen] scale]);
    
    self.baseEffect.transform.projectionMatrix = projectionMatrix;
    
//    glUniformMatrix4fv(_uniformViewProjectionMatrix, 1, GL_FALSE, modelViewProjectionMatrix.m);
    
    // 设置模型坐标
    //    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, -1.0f, -6.5f);
    self.baseEffect.transform.modelviewMatrix =  modelViewMatrix;
    // 以画单独三角形的方式 开始绘制
    glDrawElements(GL_TRIANGLE_STRIP, i,GL_UNSIGNED_SHORT, NULL);
    
}

-(void)update{
//     self.baseEffect.transform.modelviewMatrix = GLKMatrix4Rotate(self.baseEffect.transform.modelviewMatrix, 0.1, 0, 1, 0);
}






@end
