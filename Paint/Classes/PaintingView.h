//
//  PaintingView.h
//  Paint
//
//  Created by Nguyen Van Kiet on 8/21/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#define kBrushOpacity		1.0
#define kBrushPixelStep		1
#define kBrushScale			2

enum {
	UNIFORM_MVP,
    UNIFORM_POINT_SIZE,
    UNIFORM_VERTEX_COLOR,
    UNIFORM_TEXTURE,
	NUM_UNIFORMS
};

//Texture
typedef struct {
    GLuint id;
    GLsizei width, height;
} TextureInfo;


@interface PaintingView : UIView{
    CAEAGLLayer *eagLLayer;
    EAGLContext *context;
    
    GLuint programShader;
    GLuint viewRenderbuffer,viewFramebuffer;
    
    Boolean initialized;
    Boolean	firstTouch;
    Boolean needsErase;
    
    //Buffer Objects
    GLuint vboId;
    
    TextureInfo brushTexture;
    CGFloat brushColor[4];
    CGFloat brushOpacity;
    CGFloat brushSize;
    
    GLint uniformLocations[4];
    
    //The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
    
    Boolean firstLine;
}

//Undo data
@property (nonatomic, strong) NSMutableArray *vertexBuffersUndo;
@property (nonatomic, strong) NSMutableArray *undoStrokes;

//Redo data
@property (nonatomic, strong) NSMutableArray *vertexBuffersRedo;
@property (nonatomic, strong) NSMutableArray *redoStrokes;

@property(nonatomic) CGPoint location;
@property(nonatomic) CGPoint prevLocation;

-(void)erase;
-(void)undoPaint;
-(void)redoPaint;
- (void)setBrushWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue opacity:(CGFloat)opacity pointSize: (float)pointSize;
-(UIImage*)convertOpenglESViewToImage;

@end
