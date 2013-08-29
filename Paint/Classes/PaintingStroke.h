//
//  PaintingStroke.h
//  Paint
//
//  Created by Nguyen Van Kiet on 8/28/13.
//  Copyright (c) 2013 Nguyen Van Kiet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PaintingStroke : NSObject

@property (nonatomic) int numVBOs;
@property (nonatomic, strong) NSMutableArray *brushColor;
@property (nonatomic) float brushSize;

@end
