//
//  DeviceOritation.m
//  WhaleyVR
//
//  Created by 曹江龙 on 16/9/21.
//  Copyright © 2016年 Snailvr. All rights reserved.
//

#import "DeviceOritation.h"

#define SENSOR_ORIENTATION [[UIApplication sharedApplication] statusBarOrientation]

@interface DeviceOritation ()

@property (assign, nonatomic, readwrite) BOOL isGyroscopeValid;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (assign, nonatomic) GLKVector3 originAngle;
@property (assign, nonatomic) GLKMatrix4 GLMatrixRestored;
@end

@implementation DeviceOritation

+ (DeviceOritation *)_sharedInstance{
    
    static DeviceOritation *sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DeviceOritation alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize{
    NSLog(@"初始化单例_motionManager");
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1 / 70.f;
    _motionManager.gyroUpdateInterval = 1 / 70.f;
    _motionManager.showsDeviceMovementDisplay = YES;
    
    if(![_motionManager isDeviceMotionAvailable]){
        NSLog(@"该设备不支持DeviceMotionMeasure");
        return;
    }
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    _isGyroscopeValid = NO;
    _GLMatrixRestored = GLKMatrix4Identity;
}

-(GLKMatrix4) getDeviceOrientationMatrix{
    if([_motionManager isDeviceMotionActive]){
        // arrangements of mappings of sensor axis to virtual axis (columns)
        // and combinations of 70 degree rotations (rows)
        GLKMatrix4 Rotation4Matrix;
        CMRotationMatrix a = _motionManager.deviceMotion.attitude.rotationMatrix;
        
        if(SENSOR_ORIENTATION == 4){
            Rotation4Matrix = GLKMatrix4Make( a.m21,-a.m11, a.m31, 0.0f,
                                             a.m23,-a.m13, a.m33, 0.0f,
                                             -a.m22, a.m12,-a.m32, 0.0f,
                                             0.0f , 0.0f , 0.0f , 1.0f);
            [self calculateOriginAttitude:Rotation4Matrix];
            return Rotation4Matrix;
        }if(SENSOR_ORIENTATION == 3){
            Rotation4Matrix = GLKMatrix4Make(-a.m21, a.m11, a.m31, 0.0f,
                                             -a.m23, a.m13, a.m33, 0.0f,
                                             a.m22,-a.m12,-a.m32, 0.0f,
                                             0.0f , 0.0f , 0.0f , 1.0f);
            [self calculateOriginAttitude:Rotation4Matrix];
            return Rotation4Matrix;
        }if(SENSOR_ORIENTATION == 2){
            Rotation4Matrix = GLKMatrix4Make(-a.m11,-a.m21, a.m31, 0.0f,
                                             -a.m13,-a.m23, a.m33, 0.0f,
                                             a.m12, a.m22,-a.m32, 0.0f,
                                             0.0f , 0.0f , 0.0f , 1.0f);
            [self calculateOriginAttitude:Rotation4Matrix];
            return Rotation4Matrix;
        }else{
            Rotation4Matrix = GLKMatrix4Make(a.m11, a.m21, a.m31, 0.0f,
                                             a.m13, a.m23, a.m33, 0.0f,
                                             -a.m12,-a.m22,-a.m32, 0.0f,
                                             0.0f , 0.0f , 0.0f , 1.0f);
            [self calculateOriginAttitude:Rotation4Matrix];
            return Rotation4Matrix;
        }
    }else{
        return GLKMatrix4Identity;
    }
}

- (void) calculateOriginAttitude: (GLKMatrix4)currentMatrix{
    if(_isGyroscopeValid == NO){
        if(currentMatrix.m20 != 0.f){//初始前几次陀螺仪数值可能为0,
            _isGyroscopeValid = YES;
        }
    }
}

-(BOOL) isGyroscopeValid{
    return _isGyroscopeValid;
}

-(GLKVector3) getOriginAttitude{
    //原始方向就是此数值，而无需每次获取第一次的方向值。
    _originAngle.v[0] = 1.f;
    _originAngle.v[2] = 0.f;
    return _originAngle;
}

-(GLKMatrix4) getDeviceOrientationMatrixFromQuaternion{
    if([_motionManager isDeviceMotionActive]){
        
        CMQuaternion a = _motionManager.deviceMotion.attitude.quaternion;
        GLKQuaternion q = GLKQuaternionMake((float)a.x, (float)a.y, (float)a.z, (float)a.w);
        
        if(SENSOR_ORIENTATION == 4){
            GLKQuaternion multiplier = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 0, 1, 0);
            q = GLKQuaternionMultiply(multiplier, q);
            return GLKMatrix4MakeWithQuaternion(GLKQuaternionMake(-q.y, q.x, q.z, q.w));
        }
        if(SENSOR_ORIENTATION == 3){
            GLKQuaternion multiplier = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 0, 1, 0);
            q = GLKQuaternionMultiply(multiplier, q);
            return GLKMatrix4MakeWithQuaternion(GLKQuaternionMake(q.y, -q.x, q.z, q.w));
        }
        if(SENSOR_ORIENTATION == 2){
            GLKQuaternion multiplier = GLKQuaternionMakeWithAngleAndAxis(M_PI_2, 1, 0, 0);
            q = GLKQuaternionMultiply(multiplier, q);
            return GLKMatrix4MakeWithQuaternion(GLKQuaternionMake(-q.x, -q.y, q.z, q.w));
        }
        GLKQuaternion multiplier = GLKQuaternionMakeWithAngleAndAxis(-M_PI_2, 1, 0, 0);
        q = GLKQuaternionMultiply(multiplier, q);
        return GLKMatrix4MakeWithQuaternion(GLKQuaternionMake(q.x, q.y, q.z, q.w));
    }
    else
        return GLKMatrix4Identity;
}

- (UIDeviceOrientation)getDeviceOritation{
    
    if([_motionManager isDeviceMotionActive]){
        
        double x = _motionManager.deviceMotion.gravity.x;
        double y = _motionManager.deviceMotion.gravity.y;
        if (fabs(y) >= fabs(x))
        {
            if (y >= 0){
                return UIDeviceOrientationPortraitUpsideDown;
            }
            else{
                 return UIDeviceOrientationPortrait;
            }
        }
        else
        {
            if (x >= 0){
                 return UIDeviceOrientationLandscapeRight;
            }
            else{
                 return UIDeviceOrientationLandscapeLeft;
            }
        }
    }
    return UIDeviceOrientationUnknown;
}

-(void) setFinalOrientationMatrix:(GLKMatrix4)matrix {
    _GLMatrixRestored = matrix;
}

-(GLKMatrix4) getFinalOrientationMatrix {
    return _GLMatrixRestored;
}

@end
