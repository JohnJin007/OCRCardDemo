//
//  RootTableViewController.m
//  OCRCardDemo
//
//  Created by lx on 2017/12/11.
//  Copyright © 2017年 pingan. All rights reserved.
//

#import "RootTableViewController.h"
#import <AipOcrSdk/AipOcrSdk.h>
#import <objc/runtime.h>

@interface RootTableViewController ()

@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *actionList;

@property (nonatomic, strong)  UIViewController * vc;

@end

@implementation RootTableViewController
{
    // 默认的识别成功的回调
    void (^_successHandler)(id);
    // 默认的识别失败的回调
    void (^_failHandler)(NSError *);
}
#pragma mark -- life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //     授权方法1：在此处填写App的Api Key/Secret Key
    //    [[AipOcrService shardService] authWithAK:@"WjSlaGqHwiRlLICcCPB2NQad" andSK:@"nXChafB0GK2XV0zVEpNi8iX45gzvFPR2"];
    
    // 授权方法2（更安全）： 下载授权文件，添加至资源
    NSString *licenseFile = [[NSBundle mainBundle] pathForResource:@"OCRCardDemo" ofType:@"license"];
    NSData *licenseFileData = [NSData dataWithContentsOfFile:licenseFile];
    if(!licenseFileData) {
        [[[UIAlertView alloc] initWithTitle:@"授权失败" message:@"授权文件不存在" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    }
    [[AipOcrService shardService] authWithLicenseFileData:licenseFileData];
    
     [self configureData];
     [self configCallback];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.actionList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSArray *actions = self.actionList[indexPath.row];
    cell = [tableView dequeueReusableCellWithIdentifier:@"DemoActionCell" forIndexPath:indexPath];
    cell.textLabel.text = actions[0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SEL funSel = NSSelectorFromString(self.actionList[indexPath.row][1]);
    if (funSel) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:funSel];
#pragma clang diagnostic pop
    }
    
}

#pragma mark -- private method

- (void)configureData {
    
    NSMutableArray *tempArray = [NSMutableArray array];
    
    [tempArray addObject:@[@"身份证正面拍照识别", @"idcardOCROnlineFront"]];
    [tempArray addObject:@[@"身份证反面拍照识别", @"idcardOCROnlineBack"]];
    [tempArray addObject:@[@"身份证正面(嵌入式质量控制+云端识别)", @"localIdcardOCROnlineFront"]];
    [tempArray addObject:@[@"身份证反面(嵌入式质量控制+云端识别)", @"localIdcardOCROnlineBack"]];
    [tempArray addObject:@[@"银行卡正面拍照识别", @"bankCardOCROnline"]];
    
    self.actionList = [NSArray arrayWithArray:tempArray];
}

- (void)configCallback {
    __weak typeof(self) weakSelf = self;
    // 这是默认的识别成功的回调
    _successHandler = ^(id result){
        NSLog(@"%@", result);
        NSString *title = @"识别结果";
        NSMutableString *message = [NSMutableString string];
        
        if(result[@"words_result"]){
            if([result[@"words_result"] isKindOfClass:[NSDictionary class]]){
                [result[@"words_result"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
                        [message appendFormat:@"%@: %@\n", key, obj[@"words"]];
                    }else{
                        [message appendFormat:@"%@: %@\n", key, obj];
                    }
                    
                }];
            }else if([result[@"words_result"] isKindOfClass:[NSArray class]]){
                for(NSDictionary *obj in result[@"words_result"]){
                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
                        [message appendFormat:@"%@\n", obj[@"words"]];
                    }else{
                        [message appendFormat:@"%@\n", obj];
                    }
                    
                }
            }
            
        }else{
            [message appendFormat:@"%@", result];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"识别成功" message:message delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
            [weakSelf.vc dismissViewControllerAnimated:YES completion:nil];
        }];
    };
    
    _failHandler = ^(NSError *error){
        NSLog(@"%@", error);
        NSString *msg = [NSString stringWithFormat:@"%li:%@", (long)[error code], [error localizedDescription]];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [weakSelf.vc dismissViewControllerAnimated:YES completion:nil];
            UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"识别失败" message:msg delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
        }];
    };
}

#pragma mark -- public method
//身份证正面识别
- (void)idcardOCROnlineFront {
    
    _vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeIdCardFont
                                 andImageHandler:^(UIImage *image) {
                                     
                                     [[AipOcrService shardService] detectIdCardFrontFromImage:image
                                                                                  withOptions:nil
                                                                               successHandler:_successHandler
                                                                                  failHandler:_failHandler];
                                 }];
    
    [self presentViewController:_vc animated:YES completion:nil];
    
}
//身份证反面识别
- (void)idcardOCROnlineBack{
    
    _vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeIdCardBack
                                 andImageHandler:^(UIImage *image) {
                                     
                                     [[AipOcrService shardService] detectIdCardBackFromImage:image
                                                                                 withOptions:nil
                                                                              successHandler:_successHandler
                                                                                 failHandler:_failHandler];
                                 }];
    [self presentViewController:_vc animated:YES completion:nil];
}
//身份证正面(嵌入式质量控制+云端识别)
- (void)localIdcardOCROnlineFront {
    
    _vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeLocalIdCardFont
                                 andImageHandler:^(UIImage *image) {
                                     
                                     [[AipOcrService shardService] detectIdCardFrontFromImage:image
                                                                                  withOptions:nil
                                                                               successHandler:^(id result){
                                                                                   _successHandler(result);
                                                                                   // 这里可以存入相册
                                                                                   //UIImageWriteToSavedPhotosAlbum(image, nil, nil, (__bridge void *)self);
                                                                               }
                                                                                  failHandler:_failHandler];
                                 }];
    [self presentViewController:_vc animated:YES completion:nil];
}

//身份证反面(嵌入式质量控制+云端识别)
- (void)localIdcardOCROnlineBack{
    _vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeLocalIdCardBack
                                 andImageHandler:^(UIImage *image) {
                                     
                                     [[AipOcrService shardService] detectIdCardBackFromImage:image
                                                                                 withOptions:nil
                                                                              successHandler:^(id result){
                                                                                  _successHandler(result);
                                                                                  // 这里可以存入相册
                                                                                  // UIImageWriteToSavedPhotosAlbum(image, nil, nil, (__bridge void *)self);
                                                                              }
                                                                                 failHandler:_failHandler];
                                 }];
    [self presentViewController:_vc animated:YES completion:nil];
}

//银行卡正面识别
- (void)bankCardOCROnline{
    
    _vc =
    [AipCaptureCardVC ViewControllerWithCardType:CardTypeBankCard
                                 andImageHandler:^(UIImage *image) {
                                     
                                     [[AipOcrService shardService] detectBankCardFromImage:image
                                                                            successHandler:_successHandler
                                                                               failHandler:_failHandler];
                                     
                                 }];
    [self presentViewController:_vc animated:YES completion:nil];
    
}

@end
