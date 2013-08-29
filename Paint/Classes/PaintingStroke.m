//
//  PaintingStroke.m
//  Paint
//
//  Created by Nguyen Van Kiet on 8/28/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import "PaintingStroke.h"

@implementation PaintingStroke
@synthesize numVBOs, brushColor, brushSize;

-(id)init{
    self= [super init];
    if (self) {
        brushColor= [[NSMutableArray alloc] init];
    }
    return self;
}

@end
