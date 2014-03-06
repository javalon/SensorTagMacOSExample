//
//  MyOpenGLView.m
//  SensorTagExample
//
//  Created by Javier Alonso Nuñez on 16/05/13.
//
//

#import "MyOpenGLView.h"
#include <OpenGL/gl.h>

@implementation MyOpenGLView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        rotX=0;
    }
    
    return self;
}


static void drawAnObject()
{
    glColor3f(.40f, 0.85f, 0.35f);
    glBegin(GL_TRIANGLES);
    {
        glVertex3f(0.0, 0.6, 0.0);
        glVertex3f(-0.2, -0.3, 0.0);
        glVertex3f(0.2, -0.3, 0.0);
    }
    glEnd();
}

- (void)drawRect:(NSRect)dirtyRect
{
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    glLoadIdentity();
    
    /*
    float Arx = acosf(rotX/R)*180.0/M_PI;
    float Ary = acosf(rotY/R)*180.0/M_PI;
    float Arz = acosf(rotZ/R)*180.0/M_PI;*/
    
    
    float yquad = - atan2f(rotX/R, rotZ/R)*180.0/M_PI;
    float rquad = - atan2f(rotY/R, rotZ/R)*180.0/M_PI;
    
    glRotatef(yquad, 1, 0, 0);
    glRotatef(rquad, 0, 1, 0);
    //glRotatef(Arz, 0, 0, 1);
    drawAnObject();
    glFlush();
}

-(void) rotate{
    rotX+=1;
    [self drawRect:[self bounds]];
}

-(void) rotate:(float) rotaX rotaY:(float)rotaY rotaZ:(float)rotaZ
{
    rotX = rotaX;
    rotY = rotaY;
    rotZ = rotaZ;
    R = sqrtf(powf(rotX, 2.0)+powf(rotY, 2.0)+powf(rotZ, 2.0));
    [self drawRect:[self bounds]];
}

- (void) resetGlView
{
    rotX=0;
    [self drawRect:[self bounds]];
}

@end
