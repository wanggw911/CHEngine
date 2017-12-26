//
//  AFEngine.h
//  AFEngine
//
//  Created by GuowenWang on 2017/12/22.
//  Copyright © 2017年 GuowenWang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFDefine.h"
#import "AFNetworking.h"

typedef void(^CHSusscessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void(^CHFailureBlock)(NSURLSessionDataTask *task, NSError *error);

@interface AFEngine : NSObject

/**
 HTTPSessionManager
 */
@property (nonatomic, strong, readonly) AFHTTPSessionManager *httpSessionManager;

/**
 当前网络状态
 */
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;

/**
 基础网络请求地址
 */
@property (nonatomic, copy) NSString *baseURLString;

/**
 设置请求超时的时间
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 https证书路径
 */
@property (nonatomic, copy) NSString *securityCerName;

/**
 请求添加的参数：如用户登录，可以添加 uid、token
 */
@property (nonatomic, strong) NSMutableDictionary *requestParams;

/**
 请求header添加的参数：platform、deviceName、deviceOS、appVersion
 */
@property (nonatomic, strong) NSMutableDictionary *requestHeaderParams;

/**
 是否打印请求日志：default：YES
 */
@property (nonatomic, assign) BOOL isShowRequestLog;

/**
 自定义处理
 比如设置 code == 0 或者 status == 0 才属于接口请求成功，然后才进行后面的操作
 截取token失效，等其他异常情况
 */
@property (nonatomic, copy) void (^customDealWithResponse)(id responseObject, CHSusscessBlock success, CHFailureBlock failure);

#pragma mark -

+ (instancetype)shared;

#pragma mark - Instance

- (NSURLSessionDataTask *)GET:(NSString *)method
                   parameters:(id)parameters
                      success:(CHSusscessBlock)success
                      failure:(CHFailureBlock)failure;

- (NSURLSessionDataTask *)POST:(NSString *)method
                    parameters:(id)parameters
                       success:(CHSusscessBlock)success
                       failure:(CHFailureBlock)failure;

#pragma mark - Class

+ (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(id)parameters
                      success:(CHSusscessBlock)success
                      failure:(CHFailureBlock)failure;

+ (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                       success:(CHSusscessBlock)success
                       failure:(CHFailureBlock)failure;

@end
