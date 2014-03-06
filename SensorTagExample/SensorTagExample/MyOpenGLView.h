//
//  MyOpenGLView.h
//  SensorTagExample
//
//  Created by Javier Alonso Nuñez on 16/05/13.
//
//

#import <Cocoa/Cocoa.h>

@interface MyOpenGLView : NSOpenGLView
{
    float rotX;
    float rotY;
    float rotZ;
    float R;
}

- (void) drawRect:(NSRect)dirtyRect;
- (void) rotate;
- (void) rotate:(float) rotaX rotaY:(float) rotaY rotaZ:(float) rotaZ;
- (void) resetGlView;

@end
