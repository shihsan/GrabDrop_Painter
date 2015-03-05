//
//  PDViewController.m
//  PainterDemo
//
//  Created by LittleDoorBoard on 13/10/7.
//  Copyright (c) 2013年 tw.edu.nccu. All rights reserved.
//

#import "PDViewController.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#import "BLWebSocketsServer.h"
#import "libwebsockets.h"

#define VERTICAL 0
#define HORIZEN 1

int port = 8000;

@interface PDViewController ()
{
    CGPoint lastPoint;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat brush;
    CGFloat opacity;
    BOOL mouseSwiped;
    /* variables for socket */
    char buf[256];
    int sockfd;
    int z;
    socklen_t adr_clnt_len;
    struct sockaddr_in adr_inet;
    struct sockaddr_in adr_clnt;
    /* finger position */
    float x;
    float y;
    float mouse;
    NSInteger tap;
    NSInteger status;
    NSInteger orient;
    int step;
    int isSetting;
    float firstX;
    float firstY;
    float leftmost;
    float rightmost;
    
    /* variable received via socket */
    float fx; // corrected finger's x
    float fy; // corrected finger's y
    float fz; // corrected finger's z
    float px; // uncorrected palm's x
    float py; // uncorrected palm's y
    float pz; // uncorrected palm's z
    float lx_; // finger's x where the key tap is registered deteced by leap
    float ly_; // finger's y where the key tap is registered deteced by leap
    float ox; // uncorrected finger's x
    float oy; // uncorrected finger's y
    float v; // finger[0]'s velocity
    //NSInteger tap; // if tap triggered - 1 for YES, 0 for NO
    float pin; //for pinch
    NSInteger isIndex;
    
    float pre_px;   //previous palm's x
    float pre_py;   //previous palm's y
    float pre_pz;   //previous palm's z
    
    NSDate *startTime;
    NSTimer *timer;
    BOOL isTimerStart;
    float first_z;
    BOOL isPinchDone;
    
}
@end

@implementation PDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    [self setupEchoServer];
//    [self toggleServer];
    
    red = 0.0/255.0;
    green = 0.0/255.0;
    blue = 0.0/255.0;
    brush = 10.0;
    opacity = 1.0;
    
    [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
    [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
    
    /*-------------Socket Server-------------*/
    //    int sockfd;
    int len;
    //    int z;
    //    char buf[256];
    //    struct sockaddr_in adr_inet;
    //    struct sockaddr_in adr_clnt;
    //    socklen_t adr_clnt_len = sizeof(adr_clnt);
    adr_clnt_len = sizeof(adr_clnt);
    
    printf("等待 Client 端傳送資料...\n");
    
    bzero(&adr_inet, sizeof(adr_inet));
    adr_inet.sin_family = AF_INET;
    adr_inet.sin_addr.s_addr = inet_addr("0.0.0.0"); 
    adr_inet.sin_port = htons(port);
    
    len = sizeof(adr_clnt);
    
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    
    if (sockfd == -1) {
        perror("socket error");
        exit(1);
    }
    z = bind(sockfd,(struct sockaddr *)&adr_inet, sizeof(adr_inet));
    
    if (z == -1) {
        perror("bind error");
        exit(1);
    }
    /*-------------Socket Server-------------*/
    
    [NSThread detachNewThreadSelector:@selector(connectLeap) toTarget:self withObject:nil];
    
    status = '0';
    step = 1;
    isSetting = 1;
    isTimerStart = false;
    isPinchDone = false;
    
    [_WebView setHidden:YES];
    
//    [_GrabbingView setHidden:YES];
//    [_GrabLabel setHidden:YES];
    
    //Scroll view
//    _scrollview.delegate = self;
//    _scrollview.minimumZoomScale = 1.0;
//    _scrollview.maximumZoomScale = 2.0;
//    self.scrollview.contentSize = self.mainImage.image.size ;
//    self.mainImage.frame = CGRectMake(0, 0, self.mainImage.image.size.width, self.mainImage.image.size.height);
//    
//    [_scrollview setScrollEnabled:YES];
//    [_scrollview setShowsHorizontalScrollIndicator:YES];
//    [_scrollview setShowsVerticalScrollIndicator:YES];
}

- (void)connectLeap
{
    while(1) {
        
        z = (int)recvfrom(sockfd, buf, sizeof(buf), 0, (struct sockaddr*)&adr_clnt, &adr_clnt_len);
        //傳送資料的socketid,暫存器指標buf,sizeof(buf),一般設為0,接收端網路位址,sizeof(接收端網路位址);
        if (z < 0) {
            perror("recvfrom error");
            exit(1);
        }
        buf[z] = 0;
        //printf("%s", buf);
        
        NSString *string = [NSString stringWithUTF8String:buf];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        
        /*
        [scanner scanInteger:&status];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&(x)];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&(y)];
        [scanner scanString:@", " intoString:nil];
        [scanner scanInt:&(tap)];
        */
        
        
        [scanner scanInteger:&status];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&fz];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&fx];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&fy];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&pz];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&px];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&py];
        [scanner scanString:@", " intoString:nil];
        [scanner scanInteger:&(tap)];
        [scanner scanString:@", " intoString:nil];
        [scanner scanFloat:&pin];
        [scanner scanString:@", " intoString:nil];
        [scanner scanInteger:&(isIndex)];
        
        //pin = 0;
        x = fx;
        y = fy;
        
        
//        NSLog(@"\nsta:%d,isSet:%d,tap:%d,pin:%f", status,isSetting,tap,pin);
        
        //NSLog(@"%s", buf);
        
        if (isSetting){
            if(tap == 1){
                if (step == 1) {
                    [self performSelectorOnMainThread:@selector(setLeftmost) withObject:nil waitUntilDone:YES];
                }
                else if (step == 2) {
                    [self performSelectorOnMainThread:@selector(setRightmost) withObject:nil waitUntilDone:YES];
                }
            }
        } else {
            if(isIndex == 1){ //if it's index finger -> can select color & brush

                mouse = orient ? x : y;
                if (leftmost<mouse && mouse<rightmost) {
                    mouse = (320 * (mouse-leftmost))/(rightmost - leftmost);
                    [self performSelectorOnMainThread:@selector(moveMouse)  withObject:nil waitUntilDone:NO];
                }
            }
            
            [self performSelectorOnMainThread:@selector(manageMenu) withObject:nil waitUntilDone:NO];
            
            //若為pin，打開計時器，並記錄第一次pinch的z座標
            if(isIndex == 0 && pin > 0.5 && pin <= 1 && !isTimerStart && !isPinchDone){
                NSLog(@"pin\n");
                isTimerStart = true;
                startTime = [NSDate date];
                first_z = pz;
                NSLog(@"%f\n",first_z);
                
                //[self CheckForGrab];
//                [self SocketServer];
            }
            
            if(isTimerStart){
                
                // 跑2秒
//                while(((int)[startTime timeIntervalSinceNow] * -1) % 60 < 2){
                    //NSLog(@"bo %d",((int)[startTime timeIntervalSinceNow] * -1) % 60);
//                    NSLog(@"差：%f\n",pz);
//                    if(pz - first_z > 150){
//                        NSLog(@"YEAH~\n");
//                    }
//                }
                
                // 2秒內做完
                if(((int)[startTime timeIntervalSinceNow] * -1) % 60 < 2){
                    NSLog(@"pz：%f\n",pz);
                    isPinchDone = true;
                    
                    // Set Socket Server
                    if(pz - first_z > 100){
                        NSLog(@"Sending~\n");
//                        [_GrabbingView performSelectorOnMainThread:@selector(setHidden:) withObject:nil waitUntilDone:NO];
//                        [_GrabLabel performSelectorOnMainThread:@selector(setHidden:) withObject:nil waitUntilDone:NO];
                        
                        //[self setupEchoServer];
                        [self toggleServer];       //open
                        
                        // wait 3 more sec to send image
                        while(((int)[startTime timeIntervalSinceNow] * -1) % 60 < 5){
//                            NSLog(@"< 5 sec\n");
                        }
                        NSLog(@"push!!\n");
                        [self push];
                        //_GrabLabel.text = [NSString stringWithFormat:@"Sending..."];
//                        [self toggleServer];   //close
                        
                        // wait 3 more sec to insure that image is received by client
                        while(((int)[startTime timeIntervalSinceNow] * -1) % 60 < 10){
//                            NSLog(@"< 8 sec\n");
                        }
                        NSLog(@"Reset!\n");
                        //isPinchDone = false;
                        isTimerStart = false;
//                        [_GrabbingView removeFromSuperview];
//                        [_GrabLabel removeFromSuperview];
//                        [self closeGrabView];
//                        NSLog(@"KerKer!\n");
//                        [_GrabbingView performSelectorOnMainThread:@selector(setHidden:) withObject:self.view waitUntilDone:NO];
//                        [_GrabLabel performSelectorOnMainThread:@selector(setHidden:) withObject:self waitUntilDone:NO];
                    }
                    
                    // Set Socket Client
//                    else if(pz - first_z < -100){
//                        NSLog(@"Receiving~\n");
//                        [_WebView performSelectorOnMainThread:@selector(setHidden:) withObject:NO waitUntilDone:NO];
//                        NSURL *url = [NSURL URLWithString:@"http://shihsan.github.io/boboTest/"];
//                        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
//                        [_WebView loadRequest:requestObj];
//                        
//                        while(((int)[startTime timeIntervalSinceNow] * -1) % 60 < 15){
////                            NSLog(@"< 8 sec\n");
//                        }
//                        NSLog(@"Reset!\n");
//                        //isPinchDone = false;
//                        isTimerStart = false;
//                    }
                    
                }
                else if(((int)[startTime timeIntervalSinceNow] * -1) % 60 > 10){
                    NSLog(@"Reset!\n");
                    isTimerStart = false;
                    isPinchDone = false;
                }
            }
            
        }
        
        
        
//        if(pin > 0.8 && pin <= 1){
//            NSLog(@"\nhere comes pinch\n");
//            [self performSelectorOnMainThread:@selector(moveImg) withObject:nil waitUntilDone:YES];
//        }
        
//        if(pre_px != px)
//            pre_px = px;
//        if(pre_py != py)
//            pre_py = py;
//        if(pre_pz != pz)
//            pre_pz = pz;
        

    }
}

//-(void)closeGrabView{
////    [_GrabbingView setHidden:YES];
////    [_GrabLabel setHidden:YES];
//    NSLog(@"Reset123!\n");
//    [UIView animateWithDuration:0.1
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         [_GrabbingView  setHidden:YES];
//                         [_GrabLabel setHidden:YES];
//                     }
//                     completion:^(BOOL finished) {
//                     }
//     ];
//}


- (void)viewDidDisappear:(BOOL)animated
{
    close(sockfd);
    exit(0);
}

- (void)setLeftmost
{
    firstX = x;
    firstY = y;
    step = 2;
    _stepLabel.text = @"step 2";
    _instrLabel.text = @"Tap to set RIGHTMOST point";
}

- (void)setRightmost
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [_settingView removeFromSuperview];
                         [_stepLabel removeFromSuperview];
                         [_instrLabel removeFromSuperview];
                     }
                     completion:^(BOOL finished) {
                         if ((x-firstX) > (y-firstY)) {
                             leftmost = firstX;
                             rightmost = x;
                             orient = HORIZEN;
                         } else {
                             leftmost = firstY;
                             rightmost = y;
                             orient = VERTICAL;
                         }
                         step = 0;
                         isSetting = 0;
                     }];
}

- (void)resetColorMenu
{
    [_color_1 setFrame:CGRectMake(8, 0, 44, 44)];
    [_color_2 setFrame:CGRectMake(60, 0, 44, 44)];
    [_color_3 setFrame:CGRectMake(112, 0, 44, 44)];
    [_color_4 setFrame:CGRectMake(164, 0, 44, 44)];
    [_color_5 setFrame:CGRectMake(216, 0, 44, 44)];
    [_color_6 setFrame:CGRectMake(268, 0, 44, 44)];
}

- (void)resetBrushMenu
{
    [_brush_1 setFrame:CGRectMake(8, 0, 44, 44)];
    [_brush_2 setFrame:CGRectMake(60, 0, 44, 44)];
    [_brush_3 setFrame:CGRectMake(112, 0, 44, 44)];
    [_brush_4 setFrame:CGRectMake(164, 0, 44, 44)];
    [_brush_5 setFrame:CGRectMake(216, 0, 44, 44)];
    [_brush_6 setFrame:CGRectMake(268, 0, 44, 44)];
}

- (void)moveMouse
{
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_colorMouse setFrame:CGRectMake(mouse, 18, 8, 8)];
                         [_brushMouse setFrame:CGRectMake(mouse, 18, 8, 8)];
                     }
                     completion:^(BOOL finished) {
                         switch (status) {
                             case 1:
                                 [self setColor];
                                 break;
                             case 2:
                                 [self setBrush];
                                 break;
//                             case 3:
//                                 if(pin > 0.8 && pin <= 1){
//                                     [self moveImg];
//                                 }
//                                 break;
                             default:
                                 break;
                         }
                     }];
    
}

- (void)setColor
{
    if (tap == 1) {
    // yellow
    if (8<=mouse && mouse<=52) {
        red = 255.0/255.0;
        green = 255.0/255.0;
        blue = 0.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_color_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_color_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_color_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_color_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    // green
    else if (60<=mouse && mouse<=104) {
        red = 0.0/255.0;
        green = 255.0/255.0;
        blue = 0.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_color_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_color_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_color_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_color_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    // blue
    else if (112<=mouse && mouse<=156) {
        red = 0.0/255.0;
        green = 0.0/255.0;
        blue = 255.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_color_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_color_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_color_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_color_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    // red
    else if (164<=mouse && mouse<=208) {
        red = 255.0/255.0;
        green = 0.0/255.0;
        blue = 0.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_color_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_color_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_color_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_color_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    // black
    else if (216<=mouse && mouse<=260) {
        red = 0.0/255.0;
        green = 0.0/255.0;
        blue = 0.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_color_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_color_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_color_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_color_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];

    }
    // white
    else if (268<=mouse && mouse<=312) {
        red = 255.0/255.0;
        green = 255.0/255.0;
        blue = 255.0/255.0;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_color_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_color_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_color_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_color_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_color_5 setFrame:CGRectMake(216, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    }
}

- (void)setBrush
{
    NSInteger tag = 0;
    if (tap == 1) {
    if (8<=mouse && mouse<=52) {
        tag = 1;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_brush_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_brush_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_brush_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_brush_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    else if (60<=mouse && mouse<=104) {
        tag = 2;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_brush_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_brush_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_brush_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_brush_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    else if (112<=mouse && mouse<=156) {
        tag = 3;
        [UIView animateWithDuration:0.2
                              delay:0.2
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_brush_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_brush_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_brush_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_brush_6 setFrame:CGRectMake(268, -44, 44, 44)];                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    else if (164<=mouse && mouse<=208) {
        tag = 4;
        [UIView animateWithDuration:0.2
                              delay:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_brush_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_brush_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_brush_5 setFrame:CGRectMake(216, -44, 44, 44)];
                             [_brush_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    else if (216<=mouse && mouse<=260) {
        tag = 5;
        [UIView animateWithDuration:0.2
                              delay:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_brush_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_brush_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_brush_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_brush_6 setFrame:CGRectMake(268, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    else if (268<=mouse && mouse<=312) {
        tag = 6;
        [UIView animateWithDuration:0.2
                              delay:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [_brush_1 setFrame:CGRectMake(8, -44, 44, 44)];
                             [_brush_2 setFrame:CGRectMake(60, -44, 44, 44)];
                             [_brush_3 setFrame:CGRectMake(112, -44, 44, 44)];
                             [_brush_4 setFrame:CGRectMake(164, -44, 44, 44)];
                             [_brush_5 setFrame:CGRectMake(216, -44, 44, 44)];
                         }
                         completion:^(BOOL finished) {
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                         }];
    }
    brush = tag * 7;
    }
}

- (void)manageMenu
{
    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if (!status || status == 3 || isIndex == 0) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                             [self resetBrushMenu];
                             [self resetColorMenu];
                         }
                         else if (status == 1) {
                             [_colorView setFrame:CGRectMake(0, 0, 320, 54)];//appear
                             [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
                             [self resetBrushMenu];
                         }
                         else if (status == 2) {
                             [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
                             [_brushView setFrame:CGRectMake(0, 0, 320, 54)];//appear
                             [self resetColorMenu];
                         }
                     }
                     completion:nil];
}

//- (void)dismissMenu
//{
//    [UIView animateWithDuration:0.2
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
//                         [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
//                     }
//                     completion:nil];
//}
//
//- (void)chooseColor
//{
//    [UIView animateWithDuration:0.2
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         [_colorView setFrame:CGRectMake(0, 0, 320, 54)];
//                         [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
//                     }
//                     completion:nil];
//}
//
//- (void)chooseBrush
//{
//    [UIView animateWithDuration:0.2
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         [_brushView setFrame:CGRectMake(0, 0, 320, 54)];
//                         [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
//                     }
//                     completion:nil];
//}

#pragma mark - paint
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    mouseSwiped = NO;
    UITouch *touch = [touches anyObject];
    lastPoint = [touch locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    mouseSwiped = YES;
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    UIGraphicsBeginImageContext(self.view.frame.size);
    [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(),kCGBlendModeNormal);
    
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
    [self.tempDrawImage setAlpha:opacity];
    UIGraphicsEndImageContext();
    
    lastPoint = currentPoint;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if(!mouseSwiped) {
        UIGraphicsBeginImageContext(self.view.frame.size);
        [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        CGContextFlush(UIGraphicsGetCurrentContext());
        self.tempDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContext(self.mainImage.frame.size);
    [self.mainImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempDrawImage.image drawInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:opacity];
    self.mainImage.image = UIGraphicsGetImageFromCurrentImageContext();
    self.tempDrawImage.image = nil;
    UIGraphicsEndImageContext();
}

//- (IBAction)colorChoosed:(id)sender
//{
//    switch ([sender tag]) {
//        case 1: // yellow
//            red = 255.0/255.0;
//            green = 255.0/255.0;
//            blue = 0.0/255.0;
//            break;
//        case 2: // green
//            red = 0.0/255.0;
//            green = 255.0/255.0;
//            blue = 0.0/255.0;
//            break;
//        case 3: // blue
//            red = 0.0/255.0;
//            green = 0.0/255.0;
//            blue = 255.0/255.0;
//            break;
//        case 4: // red
//            red = 255.0/255.0;
//            green = 0.0/255.0;
//            blue = 0.0/255.0;
//            break;
//        case 5: // black
//            red = 0.0/255.0;
//            green = 0.0/255.0;
//            blue = 0.0/255.0;
//            break;
//        case 6: // white
//            red = 255.0/255.0;
//            green = 255.0/255.0;
//            blue = 255.0/255.0;
//        default:
//            break;
//    }
//}
//
//- (IBAction)brushChoosed:(id)sender
//{
//    brush = [sender tag] * 7;
//}
//
//- (IBAction)dismissView:(id)sender
//{
//    switch ([sender tag]) {
//        case 0: // color view
//        {[UIView animateWithDuration:0.2
//                                  delay:0
//                                options:UIViewAnimationOptionCurveEaseInOut
//                             animations:^{
//                                 [_colorView setFrame:CGRectMake(0, -54, 320, 54)];
//                             }
//                          completion:nil];}
//            break;
//        case 1: // brush view
//        {[UIView animateWithDuration:0.2
//                                  delay:0
//                                options:UIViewAnimationOptionCurveEaseInOut
//                             animations:^{
//                                 [_brushView setFrame:CGRectMake(0, -54, 320, 54)];
//                             }
//                          completion:nil];}
//            break;
//        default:
//            break;
//    }
//}


#pragma mark - pinch
-(void)moveImg
{
//    [UIView animateWithDuration:0.5f
//                     animations:^{
//                         //Move the image view according to px , py
//                         NSLog(@"pinch!!");
//                         self.mainImage.frame =
//                         CGRectMake(self.mainImage.frame.origin.x+px-pre_px,
//                                    self.mainImage.frame.origin.y+py-pre_py,
//                                    self.mainImage.frame.size.width,
//                                    self.mainImage.frame.size.height);
//                     }];
    
//    //for ZOOMING
//    if(pz-pre_pz > 1)
//        [UIView animateWithDuration:0.5f
//                         animations:^{
//                             _scrollview.zoomScale += 0.01f;
//                         }];
//    else if(pz-pre_pz < -1)
//        [UIView animateWithDuration:0.5f
//                         animations:^{
//                             _scrollview.zoomScale -= 0.01f;
//                         }];
    

}


//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView {
//    return self.mainImage;
//}

//-------------Socket Server Set up---------------------------------------------
//-(void)socket_setup:(int)port{
//    
//    int sockfd;
//    int w;
//    socklen_t adr_clnt_len;
//    // struct sockaddr_in adr_inet;
//    struct sockaddr_in adr_clnt;
//    adr_clnt_len = sizeof(adr_clnt);
//    int len;
//    
//    // Open a socket
//    sd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
//    if (sd<=0) {
//        perror("Error: Could not open socket");
//    }
//    
//    
//    // Set socket options
//    // Enable broadcast
//    int broadcastEnable=1;
//    ret=setsockopt(sd, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));
//    if (ret) {
//        perror("Error: Could not open set socket to broadcast mode");
//        close(sd);
//    }
//    
//    // Since we don't call bind() here, the system decides on the port for us, which is what we want.
//    
//    // Configure the port and ip we want to send to
//    // Make an endpoint
//    memset(&broadcastAddr, 0, sizeof broadcastAddr);
//    broadcastAddr.sin_family = AF_INET;
//    inet_pton(AF_INET, "127.0.0.1", &broadcastAddr.sin_addr); /*ios 模擬器（自己）127.0.0.1*//*（在device上測試時）用device上的IP*/
//    // Set the self broadcast IP address
//    broadcastAddr.sin_port = htons(port); // Set port 8000
//    
//}
////------------------Socket Server Set up end----------------------------------

#pragma mark SocketServer
-(void)SocketServer{
    int listenfd = 0;
    char sendBuff[8000];//1025];
    int connfd = 0;
    struct sockaddr_in serv_addr;
    
//    int numrv;
    
    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    printf("socket retrieve success\n");
    
    memset(&serv_addr, '0', sizeof(serv_addr));
    memset(sendBuff, '0', sizeof(sendBuff));
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(5000);
    printf("Listen port 5000\n");
    
    bind(listenfd, (struct sockaddr*)&serv_addr,sizeof(serv_addr));
    
    if(listen(listenfd, 10) == -1){
        printf("Failed to listen\n");
//        return -1;
    }
    
    
    //while(1)
    //{
        
        connfd = accept(listenfd, (struct sockaddr*)NULL ,NULL); // accept awaiting request
        
        strcpy(sendBuff, "Message from server");
//        write(connfd, sendBuff, strlen(sendBuff));

        NSData *dataImage = [[NSData alloc] init];
        dataImage = UIImageJPEGRepresentation(self.mainImage.image , 1.0);
        NSString *stringImage = [dataImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        const char *stringbuf = [stringImage cStringUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"%s",stringbuf);
    
        write(connfd, stringbuf, strlen(stringbuf));
    
        close(connfd);
        sleep(1);
        
    //}
    
}
/*
- (void)loadDataFromServerWithURL:(NSURL *)url
{
    NSString * host = [url host];
    NSNumber * port = [url port];
    
    // Create socket
    //
    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == socketFileDescriptor) {
        NSLog(@"Failed to create socket.");
        return;
    }
    
    // Get IP address from host
    //
    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
    if (NULL == remoteHostEnt) {
        close(socketFileDescriptor);
        
//        [self networkFailedWithErrorMessage:@"Unable to resolve the hostname of the warehouse server."];
        return;
    }
    
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    
    // Set the socket parameters
    //
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET;
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons([port intValue]);
    
    // Connect the socket
    //
    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (-1 == ret) {
        close(socketFileDescriptor);
        
        NSString * errorInfo = [NSString stringWithFormat:@" >> Failed to connect to %@:%@", host, port];
//        [self networkFailedWithErrorMessage:errorInfo];
        return;
    }
    
    NSLog(@" >> Successfully connected to %@:%@", host, port);
    
    NSMutableData * data = [[NSMutableData alloc] init];
    BOOL waitingForData = YES;
    
    // Continually receive data until we reach the end of the data
    //
    int maxCount = 5;   // just for test.
    int i = 0;
    while (waitingForData && i < maxCount) {
        const char * buffer[1024];
        int length = sizeof(buffer);
        
        // Read a buffer's amount of data from the socket; the number of bytes read is returned
        //
        int result = recv(socketFileDescriptor, &buffer, length, 0);
        if (result > 0) {
            [data appendBytes:buffer length:result];
        }
        else {
            // if we didn't get any data, stop the receive loop
            //
            waitingForData = NO;
        }
        
        ++i;
    }
    
    // Close the socket
    //
    close(socketFileDescriptor);
    
//    [self networkSucceedWithData:data];
}*/
- (IBAction)Send:(id)sender {
//    [self SocketServer];
//    [self setupEchoServer];
//    [self toggleServer];
    [self push];
}




#pragma mark Websocket
- (void)setupEchoServer {
    NSLog(@"\nhi\n");
    [[BLWebSocketsServer sharedInstance] setHandleRequestBlock:^NSData *(NSData *requestData) {
        NSLog(@"\nsetupEchoServer\n");
        return requestData;
    }];
}

- (void)toggleServer{
    /* If the server is running */
    if ([BLWebSocketsServer sharedInstance].isRunning) {
        /* The server is stopped */
        //        [self stopPushing];
        [[BLWebSocketsServer sharedInstance] stopWithCompletionBlock:^ {
            NSLog(@"\nServer stopped\n");
        }];
    }
    /* If it is not running */
    else {
        /* The server is started */
        [[BLWebSocketsServer sharedInstance] startListeningOnPort:5000 withProtocolName:@"echo-protocol" andCompletionBlock:^(NSError *error) {
            NSLog(@"\nServer started\n");
            //            [self startPushing];
            //Push a message to every connected clients
//                        [self push];
            //            pushTimer = [NSTimer scheduledTimerWithTimeInterval:pushInterval target:self selector:@selector(push) userInfo:nil repeats:YES];
            
        }];
    }
}

-(void)push
{
    NSLog(@"Push!\n");
    //Convert UIImage to base64 string
    NSData *dataImage = [[NSData alloc] init];
    dataImage = UIImageJPEGRepresentation(self.mainImage.image,1.0 );//UIImagePNGRepresentation(self.mainImage.image);
    NSString *stringImage = [dataImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    //NSLog(@"%@",stringImage);
    [[BLWebSocketsServer sharedInstance] pushToAll:[stringImage dataUsingEncoding:NSUTF8StringEncoding]];
    
    //NSLog(@"\npush: %@\n",UIImageJPEGRepresentation(_ShowImage.image,1.0 ));
    
    //    [[BLWebSocketsServer sharedInstance] pushToAll:[@"Server is sending Message." dataUsingEncoding:NSUTF8StringEncoding]];
    //    NSLog(@"\npush:%@\n",[@"Server is sending Message." dataUsingEncoding:NSUTF8StringEncoding]);
    
    //Close the server after sending
    //[self toggleServer];
}

#pragma mark - Timer
- (void)initTimer
{
    startTime = [NSDate date];
    [self update];
}

- (void)start
{
    [self initTimer];
    
    // 每隔一秒呼叫 update 方法
    timer = [NSTimer scheduledTimerWithTimeInterval:1      // 相隔一秒
                                             target:self
                                           selector:@selector(update)
                                           userInfo:nil    // 不傳入參數
                                            repeats:YES];
}

/*
 * 停止計時，要移除觸發計時器
 */
- (void)stop
{
    // 移除觸發計時器時務必要先使用 isValid 方法確認是否可以移除
    // 再呼叫 invalidate 停止繼續觸發
    bool isValid = [timer isValid];
    
    if(isValid) {
        [timer invalidate];
    }
}

/*
 * 計算時間，並在格式化後顯示於視窗上
 */
- (void)update
{
    NSTimeInterval currentTime = [startTime timeIntervalSinceNow] * -1;
    //int min = (int)currentTime / 60;
    int sec = (int)currentTime % 60;
    //NSString *nowTimeString = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    NSLog(@"update(sec) : %01d",sec);
    if(sec == 3){
        NSLog(@"update(sec) : STOP\n");
        [self stop];
    }
    
}

-(void)CheckForGrab{
    isTimerStart = 1;
    startTime = [NSDate date];
    
    // 若時間在2秒以內，執行while
    while(((int)[startTime timeIntervalSinceNow] * -1)% 60 < 2){
        NSLog(@"bo");
    }
    
//    isTimerStart = 0;
//    [self stop];

}

- (IBAction)Timer:(id)sender {
    startTime = [NSDate date];
//    [self start];
    
    // 若時間在5秒以內，執行while
    while(((int)[startTime timeIntervalSinceNow] * -1)% 60 < 5){
        NSLog(@"bo");
    }
}

- (IBAction)Stop:(id)sender {
    NSTimeInterval currentTime = [startTime timeIntervalSinceNow] * -1;
    int sec = (int)currentTime % 60;
    NSLog(@"update(sec) : %01d",sec);
    [self stop];
}

@end
