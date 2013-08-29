//
//  PaintingView.m
//  Paint
//
//  Created by Nguyen Van Kiet on 8/21/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import "PaintingView.h"
#import <GLKit/GLKit.h>
#import "PaintingStroke.h"

@interface PaintingView()
@end

@implementation PaintingView
@synthesize  location, prevLocation;
@synthesize vertexBuffersUndo, undoStrokes, vertexBuffersRedo,redoStrokes;


+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

-(id)initWithCoder:(NSCoder*)coder {
    
    self = [super initWithCoder:coder];
    if (self){
        
        [self setupLayer];
        
        [self setupContext];
        
        //Cleared buffer
		needsErase = YES;
        
        self.vertexBuffersUndo= [[NSMutableArray alloc] init];
        self.undoStrokes= [[NSMutableArray alloc] init];
        
        self.vertexBuffersRedo= [[NSMutableArray alloc] init];
        self.redoStrokes= [[NSMutableArray alloc] init];
    }
   
    return self;
}

-(void)layoutSubviews
{
    [EAGLContext setCurrentContext:context];
    
    if (!initialized){
        initialized= [self initGL];
    }
    
    if(needsErase){
        [self erase];
        needsErase = NO;
    }
}

-(void)setupContext{
    context= [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
         exit(1);
    }
}
- (void)setupLayer{
    eagLLayer= (CAEAGLLayer*)self.layer;
    eagLLayer.opaque= YES;
    
    eagLLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:YES], kEAGLDrawablePropertyRetainedBacking,//opengl will retain drawings between frames instead of cleaning every frame.
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

}

-(void)erase{
    
    [self.vertexBuffersUndo removeAllObjects];
    [self.undoStrokes removeAllObjects];
    
    [self.vertexBuffersRedo removeAllObjects];
    [self.redoStrokes removeAllObjects];
    
    //Clear the buffer
    glClearColor(1.0, 1.0, 1.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    //Display the buffer
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

-(BOOL)initGL{
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    //Create a Vertex Buffer Object
    glGenBuffers(1, &vboId);
    
    brushTexture = [self textureFromName:@"Particle.png"];
    
    [self setupShaders];
   
    //Enable blending
    glEnable(GL_BLEND);

    //Specify pixel arithmetic
    glBlendFunc(GL_ONE,
                GL_ONE_MINUS_SRC_ALPHA);
    
    return YES;
}

- (void)setupRenderBuffer{
     glGenRenderbuffers(1, &viewRenderbuffer);
     glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    
    //Allocate some storage for the render buffer
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
}

- (void)setupFrameBuffer {
    glGenFramebuffers(1, &viewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    
    //Attach the render buffer you created earlier to the frame buffer’s GL_COLOR_ATTACHMENT0 slot.
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGRect bounds= [self bounds];
    UITouch *touch= [[event touchesForView:self] anyObject];
    
    location= [touch locationInView:self];
    location.y = bounds.size.height - location.y;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGRect bounds= [self bounds];
    UITouch *touch= [[event touchesForView:self] anyObject];
    
    if (firstTouch) {
		firstTouch = NO;
		prevLocation = [touch previousLocationInView:self];
		prevLocation.y = bounds.size.height - prevLocation.y;
	} else {
		location = [touch locationInView:self];
	    location.y = bounds.size.height - location.y;
        
		prevLocation = [touch previousLocationInView:self];
		prevLocation.y = bounds.size.height - prevLocation.y;
	}
    
	[self renderLineFromPoint:prevLocation toPoint:location];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGRect bounds= [self bounds];
    UITouch *touch= [[event touchesForView:self] anyObject];
    
    if (firstTouch) {
		firstTouch = NO;
		prevLocation = [touch previousLocationInView:self];
		prevLocation.y = bounds.size.height - prevLocation.y;
        
		[self renderLineFromPoint:prevLocation toPoint:location];
	}
    
    PaintingStroke *stroke= [[PaintingStroke alloc] init];
    stroke.numVBOs= [vertexBuffersUndo count];
    stroke.brushSize= brushSize;
    
    NSLog(@"Num VBOs: %d", stroke.numVBOs);
    
    //Save brush color & size
    for (int i = 0; i< 4; i++) {
        NSNumber *color= [NSNumber numberWithFloat:brushColor[i]];
        [stroke.brushColor addObject:color];
    }
   
    NSLog(@"R: %f, G: %f, B: %f", [stroke.brushColor[0] floatValue], [stroke.brushColor[1] floatValue], [stroke.brushColor[2] floatValue]);
    
    [self.undoStrokes addObject:stroke];
    
    if (self.redoStrokes.count > 0){
        [self.vertexBuffersRedo removeAllObjects];
        [self.redoStrokes removeAllObjects];
    }
}

-(void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end{
    
    static GLfloat *vertexBuffer = NULL;
	static NSUInteger vertexMax = 64;
	NSUInteger vertexCount = 0, count, i;
	
	[EAGLContext setCurrentContext:context];
    
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	//Convert locations from Points to Pixels
	CGFloat scale = self.contentScaleFactor;
	start.x *= scale;
	start.y *= scale;
	end.x *= scale;
	end.y *= scale;
	
	//Allocate vertex array buffer
	if(vertexBuffer == NULL)
		vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
	
	//Add points to the buffer so there are drawing points every X pixels
    //=> Gets the number of points on the line we will draw
	count = MAX(ceilf(sqrtf((end.x - start.x) * (end.x - start.x) + (end.y - start.y) * (end.y - start.y)) / kBrushPixelStep), 1);
    
    //Builds the points into the vertex array
	for(i = 0; i < count; i++) {
        
		if(vertexCount == vertexMax) {
			vertexMax = 2 * vertexMax;
			vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
		}
        
		vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i / (GLfloat)count);
		vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i / (GLfloat)count);
        
		vertexCount += 1;
	}
    
	//Load vertex data to the Vertex Buffer Object
	glBindBuffer(GL_ARRAY_BUFFER, vboId);
    
    //Creates and initializes a buffer object's data store.
	glBufferData(GL_ARRAY_BUFFER,
                 vertexCount* 2* sizeof(GLfloat),//size in bytes of the buffer object's new data store.
                                   vertexBuffer,
                                GL_DYNAMIC_DRAW);
	
    //Enable or disable a generic vertex attribute array
    glEnableVertexAttribArray(0);
    
    //Define an array of generic vertex attribute data
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
                    
	//Draw
    glUseProgram(programShader);
    
    //Render primitives from array data
	glDrawArrays(GL_POINTS, 0, vertexCount);
	
    //Store VBO to Undo
    NSData *data= [NSData dataWithBytes:vertexBuffer length:vertexCount* 2* sizeof(GLfloat)];
    [self.vertexBuffersUndo addObject:data];
    
	//Display the buffer
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)undoPaint{
    
    if (self.undoStrokes.count< 1) {
        return;
    }
    
    [EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER, viewFramebuffer);
	glClearColor(1.0, 1.0, 1.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
    //Remove last stroke
    PaintingStroke *lastStroke= [self.undoStrokes lastObject];
    [self.redoStrokes addObject:lastStroke];
    [self.undoStrokes removeLastObject];
    
    PaintingStroke *prevLastStroke= [self.undoStrokes lastObject];
    int numVBOs;
    if ([self.undoStrokes count] > 0) {
        numVBOs= lastStroke.numVBOs- prevLastStroke.numVBOs;
    }else{
        numVBOs= lastStroke.numVBOs;
    }

    int iStart= prevLastStroke.numVBOs;
    for (int i = 0; i < numVBOs; i++)
    {
        if (iStart>= self.vertexBuffersUndo.count) {
            break;
        }
        NSData *vertexBuffer= [self.vertexBuffersUndo objectAtIndex:iStart];
        [self.vertexBuffersRedo addObject:vertexBuffer];
        
        [self.vertexBuffersUndo removeObjectAtIndex:iStart];
    }
    
    NSLog(@"Num remaing vbos: %d", self.vertexBuffersUndo.count);
    
    //Render remaining vbos
    iStart= 0;
    int iEnd= 0;
    for (int i= 0; i< self.undoStrokes.count; i++) {
        
        PaintingStroke *paintingStroke= [self.undoStrokes objectAtIndex:i];
        
        //Set brush color vs size
        CGFloat tmpbrushColor[4];
        for (int j= 0; j< 4; j++) {
            tmpbrushColor[j]= [[paintingStroke.brushColor objectAtIndex:j] floatValue];
        }
        
        NSLog(@"R: %f, G: %f, B: %f", [paintingStroke.brushColor[0] floatValue], [paintingStroke.brushColor[1] floatValue], [paintingStroke.brushColor[2] floatValue]);
        
        glUniform4fv(uniformLocations[UNIFORM_VERTEX_COLOR], 1, tmpbrushColor);
        glUniform1f(uniformLocations[UNIFORM_POINT_SIZE], paintingStroke.brushSize);
        
        //Render
        iEnd= iStart + paintingStroke.numVBOs;
        for (int k= iStart; k< iEnd; k++)
        {
            if (k>= self.vertexBuffersUndo.count) {
                break;
            }
                            
            NSData *vertexBuffer=  [self.vertexBuffersUndo objectAtIndex:k];
            
            [self setupVBO:vertexBuffer];
        }
        
        iStart= paintingStroke.numVBOs;
    }
        
	//Display the buffer
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)setupVBO:(NSData*)vertexBuffer{
    
    NSUInteger count = vertexBuffer.length / (sizeof(GL_FLOAT) * 2);
    //glVertexPointer(2, GL_FLOAT, 0, vertexBuffer.bytes);
    
    //Load vertex data to the Vertex Buffer Object
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    
    //Creates and initializes a buffer object's data store.
    glBufferData(GL_ARRAY_BUFFER,
                 count* 2* sizeof(GLfloat),//size in bytes of the buffer object's new data store.
                 vertexBuffer.bytes,
                 GL_DYNAMIC_DRAW);
    
    //Enable or disable a generic vertex attribute array
    glEnableVertexAttribArray(0);
    //Define an array of generic vertex attribute data
    glVertexAttribPointer(0, //Specifies the index of the generic vertex attribute to be modified.
                          2, //Specifies the number of components per generic vertex attribute
                          GL_FLOAT,
                          GL_FALSE,
                          0,//Specifies the byte offset between consecutive generic vertex attributes
                          0);//Specifies a pointer to the first component of the first generic vertex attribute in the array
    
    glUseProgram(programShader);
    
    glDrawArrays(GL_POINTS, 0, count);
}

- (void)redoPaint{
    
    if (self.redoStrokes.count < 1) {
        return;
    }
    
    [EAGLContext setCurrentContext:context];
	
	// Clear the buffer
	glBindFramebufferOES(GL_FRAMEBUFFER, viewFramebuffer);
	glClearColor(1.0, 1.0, 1.0, 0.0);
	glClear(GL_COLOR_BUFFER_BIT);
    
    //Add last stroke 
    PaintingStroke *prevLastStroke;
    if ([self.undoStrokes count] > 0) {
        prevLastStroke=[self.undoStrokes lastObject];
    }
    PaintingStroke *nextStroke= [self.redoStrokes lastObject];
    [self.undoStrokes addObject:nextStroke];
    [self.redoStrokes removeLastObject];
    
    int numVBOs= nextStroke.numVBOs- prevLastStroke.numVBOs;
    int iStart= self.vertexBuffersRedo.count- numVBOs;
    for (int i = 0; i < numVBOs; i++)
    {
        if (iStart>= self.vertexBuffersRedo.count) {
            break;
        }
        NSData *vertexBuffer= [self.vertexBuffersRedo objectAtIndex:iStart];
        [self.vertexBuffersUndo addObject:vertexBuffer];
        
        [self.vertexBuffersRedo removeObjectAtIndex:iStart];
    }
    
     NSLog(@"Num remaing vbos: %d", self.vertexBuffersRedo.count);
    
    //Render remaining vbos
    iStart= 0;
    int iEnd= 0;
    for (int i= 0; i< self.undoStrokes.count; i++) {
        
        PaintingStroke *paintingStroke= [self.undoStrokes objectAtIndex:i];
        
        //Set brush color vs size
        CGFloat tmpbrushColor[4];
        for (int j= 0; j< 4; j++) {
            tmpbrushColor[j]= [[paintingStroke.brushColor objectAtIndex:j] floatValue];
        }
        
        NSLog(@"R: %f, G: %f, B: %f", [paintingStroke.brushColor[0] floatValue], [paintingStroke.brushColor[1] floatValue], [paintingStroke.brushColor[2] floatValue]);
        
        glUniform4fv(uniformLocations[UNIFORM_VERTEX_COLOR], 1, tmpbrushColor);
        glUniform1f(uniformLocations[UNIFORM_POINT_SIZE], paintingStroke.brushSize);
        
        //Render
        iEnd= iStart + paintingStroke.numVBOs;

        // Render remaining vbos
        for (int k= iStart; k< iEnd; k++)
        {
            if (k>= self.vertexBuffersUndo.count) {
                break;
            }
            NSData *vertexBuffer=  [self.vertexBuffersUndo objectAtIndex:k];
            
            [self setupVBO:vertexBuffer];
        }
        
        iStart= paintingStroke.numVBOs;
    }
    
	//Display the buffer
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)setBrushWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue opacity:(CGFloat)opacity pointSize: (float)pointSize
{
    brushOpacity= opacity;
    brushSize= pointSize;
    
	// Update the brush color
    brushColor[0] = red * brushOpacity;
    brushColor[1] = green * brushOpacity;
    brushColor[2] = blue * brushOpacity;
    brushColor[3] = brushOpacity;
    
    if (initialized) {
        glUseProgram(programShader);
        
        //specify the value of a uniform variable for the current program object
        glUniform4fv(uniformLocations[UNIFORM_VERTEX_COLOR],
                     1,
                     brushColor);
        
        glUniform1f(uniformLocations[UNIFORM_POINT_SIZE], brushSize);
    }
}

-(UIImage*)convertOpenglESViewToImage{
    
    GLubyte *buffer = (GLubyte *) malloc(backingWidth * backingHeight * 4);
    GLubyte *buffer2 = (GLubyte *) malloc(backingWidth * backingHeight * 4);
    glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE,
                 (GLvoid *)buffer);
    
    for (int y=0; y<backingHeight; y++) {
        for (int x=0; x<backingWidth*4; x++) {
            buffer2[y * 4 * backingWidth + x] =
            buffer[(backingHeight - y - 1) * backingWidth * 4 + x];
        }
    }
    
    CGDataProviderRef provider;
    provider = CGDataProviderCreateWithData(NULL, buffer2,
                                            backingWidth * backingHeight * 4,
                                            myProviderReleaseData);
    //set up for CGImage creation
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * backingWidth;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    
    // Use this to retain alpha
    //CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(backingWidth, backingHeight,
                                        bitsPerComponent, bitsPerPixel,
                                        bytesPerRow, colorSpaceRef,
                                        bitmapInfo, provider,
                                        NULL, NO,
                                        renderingIntent);
    //this contains our final image.
    UIImage *newUIImage = [UIImage imageWithCGImage:imageRef];
    
    return newUIImage;
}

static void myProviderReleaseData (void *info,const void *data,size_t size)
{
    free((void*)data);
}

//Create a texture from an image
- (TextureInfo)textureFromName:(NSString *)name
{
    CGImageRef		brushImage;
	CGContextRef	brushContext;
	GLubyte			*brushData;
	size_t			width, height;
    GLuint          texId;
    TextureInfo   texture;
    
    brushImage = [UIImage imageNamed:name].CGImage;
    
    width = CGImageGetWidth(brushImage);
    height = CGImageGetHeight(brushImage);
    
    if(brushImage) {
        brushData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
        //Create the context
        brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
        //Draw the  image to the context.
        CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), brushImage);
        CGContextRelease(brushContext);
        
        //Use OpenGL ES to generate a name for the texture.
        glGenTextures(1, &texId);
        //Bind the texture name.
        glBindTexture(GL_TEXTURE_2D, texId);
        
        //Set the texture parameters to use a minifying filter and a linear filer (weighted average)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        //Specify a 2D texture image, providing the a pointer to the image data in memory
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
        
        //Release  the image data
        free(brushData);
        
        texture.id = texId;
        texture.width = width;
        texture.height = height;
    }
    
    return texture;
}


-(BOOL)setupShaders{
    
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    const GLchar *uniformName[4] = {
        "MVP", "pointSize", "vertexColor", "texture",
    };
    
    //Create shader program.
    programShader= glCreateProgram();
    
    //Create and compile vertex shader.
    vertShaderPathname= [[NSBundle mainBundle] pathForResource:@"point" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    //Create and compile fragment shader
    fragShaderPathname= [[NSBundle mainBundle] pathForResource:@"point" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    //Attach vertex shader,fragment shader to program.
    glAttachShader(programShader, vertShader);
    glAttachShader(programShader, fragShader);
    
    //Associate a generic vertex attribute index with a named attribute variable
    glBindAttribLocation(programShader, 0, "inVertex");
    
    //Link a program with all currently attached shaders
    glLinkProgram(programShader);
    GLint linkSuccess;
    glGetProgramiv(programShader, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess== GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programShader, sizeof(messages), 0, &messages[0]);
        return NO;
    }
    
    for (int i = 0; i < NUM_UNIFORMS; i++)
       uniformLocations[i] = glGetUniformLocation(programShader, uniformName[i]);
        
    //Tell OpenGL to actually use this program when given vertex info.
    glUseProgram(programShader);
    
    //Pass data to shader program
    
    //Set constant/initalize uniforms
    glUniform1i(uniformLocations[UNIFORM_TEXTURE], 0);
    
    //Viewing matrices
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(uniformLocations[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    glUniform1f(uniformLocations[UNIFORM_POINT_SIZE], brushSize);
    
    glUniform4fv(uniformLocations[UNIFORM_VERTEX_COLOR], 1, brushColor);
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
        
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

@end
