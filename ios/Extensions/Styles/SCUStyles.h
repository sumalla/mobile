//
//  SCUStyles.h
//
// This file was auto-generated using the style-js tool.
// Do not directly modify this file!
//

@import UIKit;

@interface SCUColors : NSObject
+ (SCUColors *)shared;

// General Colors
@property BOOL invert;
@property (readonly, atomic) UIColor *color01;
@property (readonly, atomic) UIColor *color02;
@property (readonly, atomic) UIColor *color03;
@property (readonly, atomic) UIColor *color03shade01;
@property (readonly, atomic) UIColor *color03shade02;
@property (readonly, atomic) UIColor *color03shade03;
@property (readonly, atomic) UIColor *color03shade04;
@property (readonly, atomic) UIColor *color03shade05;
@property (readonly, atomic) UIColor *color03shade06;
@property (readonly, atomic) UIColor *color03shade07;
@property (readonly, atomic) UIColor *color03shade08;
@property (readonly, atomic) UIColor *color04;
@property (readonly, atomic) UIColor *color05;
@property (readonly, atomic) UIColor *color06;
@property (readonly, atomic) UIColor *color07;
@property (readonly, atomic) UIColor *color08;
@property (readonly, atomic) UIColor *color09;
@property (readonly, atomic) UIColor *color10;
@property (readonly, atomic) UIColor *color11;
@property (readonly, atomic) UIColor *color12;
@property (readonly, atomic) UIColor *color13;
@property (readonly, atomic) UIColor *color14;
@property (readonly, atomic) UIColor *color15;


@end

@protocol SCUDimensProtocol

@property (readonly) CGFloat h1;
@property (readonly) CGFloat h10;
@property (readonly) CGFloat h11;
@property (readonly) CGFloat h12;
@property (readonly) CGFloat h2;
@property (readonly) CGFloat h3;
@property (readonly) CGFloat h4;
@property (readonly) CGFloat h5;
@property (readonly) CGFloat h6;
@property (readonly) CGFloat h7;
@property (readonly) CGFloat h8;
@property (readonly) CGFloat h9;
@property (readonly) CGFloat padding1;
@property (readonly) CGFloat padding10;
@property (readonly) CGFloat padding11;
@property (readonly) CGFloat padding13;
@property (readonly) CGFloat padding14;
@property (readonly) CGFloat padding15;
@property (readonly) CGFloat padding16;
@property (readonly) CGFloat padding17;
@property (readonly) CGFloat padding18;
@property (readonly) CGFloat padding19;
@property (readonly) CGFloat padding2;
@property (readonly) CGFloat padding20;
@property (readonly) CGFloat padding3;
@property (readonly) CGFloat padding4;
@property (readonly) CGFloat padding5;
@property (readonly) CGFloat padding6;
@property (readonly) CGFloat padding7;
@property (readonly) CGFloat padding8;
@property (readonly) CGFloat padding9;
// global
@property (readonly) CGFloat globalMargin1;
@property (readonly) CGFloat globalMargin2;


@end

/**
 *  Dimensions and font sizes to be used with compact form factors.
 */
@interface SCUCompactDimens : NSObject <SCUDimensProtocol>

@end

/**
 *  Dimensions and font sizes to be used with regular form factors.
 */
@interface SCURegularDimens : NSObject <SCUDimensProtocol>

@end

/**
 *  SCUDimens contains all of the dimensions and font sizes specified by the design team.
 */
@interface SCUDimens : NSObject

+ (SCUDimens *)dimens;

@property (readonly) SCUCompactDimens *compact;
@property (readonly) SCURegularDimens *regular;

@end
