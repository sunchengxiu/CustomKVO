//
//  ViewController.m
//  CustomKVO
//
//  Created by 孙承秀 on 2018/5/23.
//  Copyright © 2018年 孙承秀. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+RCKVO.h"
@interface Message : NSObject

@property (nonatomic, copy) NSString *text;

@end

@implementation Message
-(void)setText:(NSString *)text{
    NSLog(@"走我了");
}

@end
@interface ViewController ()
/**
 message
 */
@property(nonatomic , strong)Message *message;

/**
 btn
 */
@property(nonatomic , strong)UIButton *btn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.message = [[Message alloc] init];
    self.btn  = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 50, 50)];
    [self.btn setBackgroundColor:[UIColor redColor]];
    [self.view addSubview:self.btn];
    [self.btn addTarget:self action:@selector(change) forControlEvents:UIControlEventTouchUpInside];
    [self.message rc_addObserver:self forKey:NSStringFromSelector(@selector(text)) withBlock:^(id observerObject, id key, id oldValue, id newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.btn setTitle:newValue forState:UIControlStateNormal];
        });
    }];
}
- (void)change{
    NSArray *arr = @[@"123",@"456",@"789",@"qwe"];
    NSUInteger index = arc4random_uniform((u_int32_t)arr.count);
    self.message.text = arr[index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
