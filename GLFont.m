//
//  GLFont.m
//  TrenchBroom
//
//  Created by Kristian Duske on 02.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GLFont.h"
#import "GLFontChar.h"

@implementation GLFont

- (id)initWithFont:(NSFont *)theFont {
    if (theFont == nil)
        [NSException raise:NSInvalidArgumentException format:@"font must not be nil"];
    
    if (self = [super init]) {
        // see "Calculating Text Height" in help
        
        NSMutableString* charString = [[NSMutableString alloc] init];
        for (char c = 32; c < 127; c++)
            [charString appendFormat:@"%c", c];

        NSMutableDictionary* attrs = [[NSMutableDictionary alloc] init];
        [attrs setObject:[NSNumber numberWithFloat:2] forKey:NSKernAttributeName];
        
        NSAttributedString* attrCharString = [[NSAttributedString alloc] initWithString:charString attributes:attrs];
        [attrs release];
        [charString release];
        
        textStorage = [[NSTextStorage alloc] initWithAttributedString:attrCharString];
        textContainer = [[NSTextContainer alloc] init];
        layoutManager = [[NSLayoutManager alloc] init];
        
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        
        float width = 32;
        float height;
        do {
            width *= 2; // actually starting with 64
            [textContainer setContainerSize:NSMakeSize(width, FLT_MAX)];
            [layoutManager ensureLayoutForTextContainer:textContainer];
            height = [layoutManager usedRectForTextContainer:textContainer].size.height;
        } while (height > width);

        height = width;
        texSize = NSMakeSize(width, height);
        
        [textContainer setContainerSize:texSize];
        [layoutManager ensureLayoutForTextContainer:textContainer];
        
        NSGraphicsContext* context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
        NSImage* image = [[NSImage alloc] initWithSize:texSize];
        [image lockFocusFlipped:YES];
        
        [context setShouldAntialias:YES];

        // draw the texture upside down
        /*
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:0 yBy:height];
        [transform scaleXBy:1 yBy:-1];
        [transform concat];
        */ 
        
        NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
        [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:NSMakePoint(0, 0)];
        
        NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, texSize.width, texSize.height)];
        [image unlockFocus];
        [context restoreGraphicsState];

        NSBitmapImageRep* grayscale= [bitmap bitmapImageRepByConvertingToColorSpace:[NSColorSpace genericGrayColorSpace] renderingIntent:NSColorRenderingIntentDefault];
        NSLog(@"bitmap: %i, grayscale: %i", [bitmap bitsPerPixel], [grayscale bitsPerPixel]);
        
        NSData *data = [grayscale representationUsingType: NSPNGFileType properties: nil];
        [data writeToFile: @"/test.png" atomically: NO];

        glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT);
        glEnable(GL_TEXTURE_2D);
        glGenTextures(1, &texId);
        glBindTexture(GL_TEXTURE_2D, texId);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, texSize.width, texSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
        glPopAttrib();
        
        [bitmap release];
        [image release];
        
        chars = [[NSMutableArray alloc] init];
        for (int i = 0; i < [attrCharString length]; i++) {
            NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(i, 1) actualCharacterRange:NULL];
            NSRect bounds = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
            
            GLFontChar* glChar = [[GLFontChar alloc] initWithDimensions:bounds.size];
            [glChar calculateTexCoordsForTexSize:texSize charPos:bounds.origin];
            [chars addObject:glChar];
            [glChar release];
        }
        
        [attrCharString release];
        [textContainer setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    }    
    
    return self;
}

- (void)renderString:(NSString *)theString {
    glPushAttrib(GL_ENABLE_BIT | GL_TEXTURE_BIT | GL_COLOR_BUFFER_BIT);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, texId);
    
    glPolygonMode(GL_FRONT, GL_FILL);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);

    NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:theString];
    [textStorage setAttributedString:attrString];
    [attrString release];
    
    [layoutManager ensureLayoutForTextContainer:textContainer];
    NSPoint lastPos = NSMakePoint(0, 0);
    for (int i = 0; i < [theString length]; i++) {
        NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(i, 1) actualCharacterRange:NULL];
        NSRect bounds = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
        glTranslatef(bounds.origin.x - lastPos.x, bounds.origin.y - lastPos.y, 0);

        lastPos = bounds.origin;
        
        int c = [theString characterAtIndex:i];
        GLFontChar* gc = [chars objectAtIndex:c - 32];
        [gc render];
    }

    glPopAttrib();
}

- (void)dispose {
    if (texId != 0) {
        glDeleteTextures(1, &texId);
        texId = 0;
    }
}

- (void)dealloc {
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [super dealloc];
}

@end
