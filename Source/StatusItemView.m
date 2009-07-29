//
//  StatusItemView.m
//  SweetFM
//
//  Created by Q on 14.04.09.
//
//
//  Permission is hereby granted, free of charge, to any person 
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, 
//  merge, publish, distribute, sublicense, and/or sell copies of 
//  the Software, and to permit persons to whom the Software is 
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be 
//  included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
//  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CApp.h"
#import "StatusItemView.h"
#import "XLog.h"

@implementation StatusItemView

@synthesize statusItem;
@synthesize mainApplication;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      mainApplication = nil;
      statusItem = nil;
      menuImage = [NSImage imageNamed:@"statusbar-black"];
      menuAlternativeImage = [NSImage imageNamed:@"statusbar-white"];
      isMenuVisible = NO;
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
  XLog(@"Mouse Down");
  [mainApplication toggleApp];
}

- (void)rightMouseDown:(NSEvent *)event {
  [[self menu] setDelegate:self];
  [statusItem popUpStatusItemMenu:[self menu]];
  [self setNeedsDisplay:YES];
}

- (void)menuWillOpen:(NSMenu *)menu {
  XLog(@"Menu Will Open");
  isMenuVisible = YES;
  [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
  isMenuVisible = NO;
  [menu setDelegate:nil];
  [self setNeedsDisplay:YES];
}

- (void)dealloc {
  [statusItem release];
  [menuImage dealloc];
  [menuAlternativeImage dealloc];
  [super dealloc];
}

- (void)drawRect:(NSRect)rect {
  //
  // Draw status bar background, highlighted if the menu is showing
  //
  [statusItem drawStatusBarBackgroundInRect:[self bounds]
                              withHighlight:isMenuVisible];
  
  //
  // Draw our image
  //
  [[self foregroundImage] setFlipped:NO];
  NSPoint leftPoint = NSMakePoint(3, 0);
  [[self foregroundImage] compositeToPoint:leftPoint 
                          operation:NSCompositeSourceOver];
}

- (NSImage *)foregroundImage {
  if (!isMenuVisible)
  {
    return menuImage;
  }
  else
  {
    return menuAlternativeImage;
  }
}

@end
