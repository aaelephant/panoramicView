//
//  DeviceOritation.h
//  WhaleyVR
//
//  Created by 曹江龙 on 16/9/21.
//  Copyright © 2016年 Snailvr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <GLKit/GLKit.h>

@interface DeviceOritation : NSObject

+ (DeviceOritation *)_sharedInstance;

-(GLKMatrix4) getDeviceOrientationMatrix;
-(GLKMatrix4) getDeviceOrientationMatrixFromQuaternion;
-(BOOL) isGyroscopeValid;
-(GLKVector3) getOriginAttitude;
-(UIDeviceOrientation) getDeviceOritation;
-(void) setFinalOrientationMatrix:(GLKMatrix4)matrix;
-(GLKMatrix4) getFinalOrientationMatrix;

@end
