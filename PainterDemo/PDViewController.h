//
//  PDViewController.h
//  PainterDemo
//
//  Created by LittleDoorBoard on 13/10/7.
//  Copyright (c) 2013年 tw.edu.nccu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDViewController : UIViewController{
    UIView *GrabbingView;
}
//@property (strong, nonatomic) IBOutlet UIScrollView *scrollview;

@property (strong, nonatomic) IBOutlet UIView *colorView;
@property (strong, nonatomic) IBOutlet UIView *brushView;
@property (strong, nonatomic) IBOutlet UIImageView *mainImage;
@property (strong, nonatomic) IBOutlet UIImageView *tempDrawImage;
@property (strong, nonatomic) IBOutlet UIButton *colorMouse;
@property (strong, nonatomic) IBOutlet UIButton *brushMouse;

@property (strong, nonatomic) IBOutlet UIButton *color_1;
@property (strong, nonatomic) IBOutlet UIButton *color_2;
@property (strong, nonatomic) IBOutlet UIButton *color_3;
@property (strong, nonatomic) IBOutlet UIButton *color_4;
@property (strong, nonatomic) IBOutlet UIButton *color_5;
@property (strong, nonatomic) IBOutlet UIButton *color_6;

@property (strong, nonatomic) IBOutlet UIButton *brush_1;
@property (strong, nonatomic) IBOutlet UIButton *brush_2;
@property (strong, nonatomic) IBOutlet UIButton *brush_3;
@property (strong, nonatomic) IBOutlet UIButton *brush_4;
@property (strong, nonatomic) IBOutlet UIButton *brush_5;
@property (strong, nonatomic) IBOutlet UIButton *brush_6;

@property (strong, nonatomic) IBOutlet UIView *settingView;
@property (strong, nonatomic) IBOutlet UILabel *stepLabel;
@property (strong, nonatomic) IBOutlet UILabel *instrLabel;

@property (weak, nonatomic) IBOutlet UIWebView *WebView;


- (IBAction)Send:(id)sender;
- (IBAction)Timer:(id)sender;
- (IBAction)Stop:(id)sender;

@end
