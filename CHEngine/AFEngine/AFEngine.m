//
//  AFEngine.m
//  AFEngine
//
//  Created by GuowenWang on 2017/12/22.
//  Copyright © 2017年 GuowenWang. All rights reserved.
//

#import "AFEngine.h"

@interface AFEngine ()
@property (nonatomic, strong, readwrite) AFHTTPSessionManager *httpSessionManager;
@end

@implementation AFEngine

+ (instancetype)shared {
    static AFEngine *_sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedEngine = [[self alloc] init];
    });
    return _sharedEngine;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isShowRequestLog = YES;
        _timeoutInterval = 5;
        
        //网络通知
        [self networkReachabilityMonitor];
    }
    return self;
}

- (void)networkReachabilityMonitor {
    /**
     AFNetworkReachabilityStatusUnknown          = -1,  // 未知
     AFNetworkReachabilityStatusNotReachable     = 0,   // 无连接
     AFNetworkReachabilityStatusReachableViaWWAN = 1,   // 3G/4G
     AFNetworkReachabilityStatusReachableViaWiFi = 2,   // WiFi
     */
    // 检测网络状态的变化
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // 网络变化时的回调方法
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        AFEngineLog(@"\n⚠️⚠️⚠️⚠️⚠️网络状态发生改变：%@\n\n---", [self stringOfNetStatus:status]);
        
        // 网络状态通知：
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_NetReachabilityChanged object:@(status)];
    }];
}

- (NSString *)stringOfNetStatus:(AFNetworkReachabilityStatus)status {
    switch (status) {
        case AFNetworkReachabilityStatusUnknown:
            return @"Unknown 未知网络";
            break;
        case AFNetworkReachabilityStatusNotReachable:
            return @"NotReachable 断开连接";
            break;
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return @"ReachableViaWWAN 移动网络";
            break;
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return @"ReachableViaWiFi WiFi网络";
            break;
        default:
            return @"";
            break;
    }
}

#pragma mark -

- (AFHTTPSessionManager *)httpSessionManager {
    if (!_httpSessionManager || ![[AFEngine shared].baseURLString isEqualToString:_httpSessionManager.baseURL.absoluteString]) {
        _httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[AFEngine shared].baseURLString]];
        
        
        // 设置http请求
        _httpSessionManager.requestSerializer.timeoutInterval = self.timeoutInterval;
        [_httpSessionManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        // 设置http响应
        _httpSessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json",@"multipart/form-data",@"text/html", nil];
        // 设置Https证书
        if (self.securityCerName) {
            _httpSessionManager.securityPolicy = [self securityPolicy];
        }
        
        
        //默认配置
        //self.requestSerializer = [AFHTTPRequestSerializer serializer];
        //self.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return _httpSessionManager;
}

- (AFSecurityPolicy *)securityPolicy {
    
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:self.securityCerName ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    // AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    /**
     allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
     如果是需要验证自建证书，需要设置为YES
     */
    securityPolicy.allowInvalidCertificates = YES;
    
    /**
     validatesDomainName 是否需要验证域名，默认为YES；
     假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
     置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。
     因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
     如置为NO，建议自己添加对应域名的校验逻辑。
     
     请求header添加的参数：platform、deviceName、deviceOS、appVersion
     */
    securityPolicy.validatesDomainName = NO;
    securityPolicy.pinnedCertificates = [NSSet setWithObjects:certData, nil];
    
    return securityPolicy;
}

#pragma mark - Instance

- (NSURLSessionDataTask *)GET:(NSString *)method
                   parameters:(id)parameters
                      success:(CHSusscessBlock)success
                      failure:(CHFailureBlock)failure {
    
    // 添加通用参数
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    [params addEntriesFromDictionary:self.requestParams];
    [params addEntriesFromDictionary:parameters];
    // 打印请求数据
    [self logWithType:@"GET" method:method params:parameters];
    
    NSURLSessionDataTask *task = [self.httpSessionManager GET:method parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //---处理接口返回参数
        if (self.customDealWithResponse) {
            self.customDealWithResponse(responseObject, success, failure);
        }
        else {
            !success ?: success(task, responseObject);
        }
        //---
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        //---错误处理
        [AFEngine errorLogWithTask:task error:error];
        !failure?: failure(task, error);
        //---
        
    }];
    return task;
}

- (NSURLSessionDataTask *)POST:(NSString *)method
                    parameters:(id)parameters
                       success:(CHSusscessBlock)success
                       failure:(CHFailureBlock)failure {
    
    // 添加通用参数
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:1];
    [params addEntriesFromDictionary:self.requestParams];
    [params addEntriesFromDictionary:parameters];
    // 打印请求数据
    [self logWithType:@"POST" method:method params:parameters];
    
    NSURLSessionDataTask *task = [self.httpSessionManager POST:method parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //---处理接口返回参数
        if (self.customDealWithResponse) {
            self.customDealWithResponse(responseObject, success, failure);
        }
        else {
            !success ?: success(task, responseObject);
        }
        //---
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        //---错误处理
        [AFEngine errorLogWithTask:task error:error];
        !failure?: failure(task, error);
        //---
        
    }];
    return task;
}

#pragma mark - Class

+ (NSURLSessionDataTask *)GET:(NSString *)URLString
                    parameters:(id)parameters
                       success:(CHSusscessBlock)success
                       failure:(CHFailureBlock)failure {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:URLString]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json",@"multipart/form-data",@"text/html", nil];
    
    // 打印请求数据
    [AFEngine logWithUrl:URLString type:@"GET" params:parameters];
    
    NSURLSessionDataTask *task = [manager GET:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        !success ?: success(task, responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [AFEngine errorLogWithTask:task error:error];
        !failure?: failure(task, error);
    }];
    return task;
}

+ (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                       success:(CHSusscessBlock)success
                       failure:(CHFailureBlock)failure {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:URLString]];
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    manager.requestSerializer.timeoutInterval = 10;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", @"text/javascript", @"text/json",@"multipart/form-data",@"text/html", nil];
    
    // 打印请求数据
    [AFEngine logWithUrl:URLString type:@"POST" params:parameters];
    
    NSURLSessionDataTask *task = [manager POST:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        !success ?: success(task, responseObject);
    
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [AFEngine errorLogWithTask:task error:error];
        !failure?: failure(task, error);
    }];
    return task;
}

#pragma mark - Log

- (void)logWithType:(NSString *)type method:(NSString *)method params:(NSDictionary *)params {
    if (!self.isShowRequestLog) {
        return;
    }
    
    NSDictionary *header = [AFEngine shared].httpSessionManager.requestSerializer.HTTPRequestHeaders;
    AFEngineLog(@"---\n\n\n  Url: %@\n  method: %@\n  type: %@\n  params: %@\n%@\n\n\n---end", [AFEngine shared].baseURLString, method, type, params, header);
}

+ (void)logWithUrl:(NSString *)url type:(NSString *)type params:(NSDictionary *)params {
    if (![AFEngine shared].isShowRequestLog) {
        return;
    }
    
    AFEngineLog(@"---start\n\n\n  Url: %@\n  type: %@\n  params: %@\n\n\n---end", url, type, params);
}

+ (void)errorLogWithTask:(NSURLSessionDataTask *)task error:(NSError *)error {
    NSString *requestUrl = [task.originalRequest.URL absoluteString];
    NSString *type = task.originalRequest.HTTPMethod;
    NSDictionary *header = task.originalRequest.allHTTPHeaderFields;
    NSString *requestParamsString = [[NSString alloc] initWithData:task.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
    NSDictionary *params = [AFEngine dictionaryWith:requestParamsString];
    
    NSDictionary *errorInfoDict = @{@"url"    : requestUrl ? requestUrl : @"",
                                    @"type"   : type ? type : @"",
                                    @"header" : header ? header : @"",
                                    @"params" : params ? params : @"",
                                    @"error"  : error ? error : @""};
    AFEngineLog(@"⚠️⚠️⚠️⚠️⚠️接口发起请求报错：\n---start\n\n\n  %@  \n\n\n---end", errorInfoDict);
}

+ (NSDictionary *)dictionaryWith:(NSString *)paramsString {
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithCapacity:1];
    
    NSArray *paramsArray = [paramsString componentsSeparatedByString:@"&"];
    for (NSString *paramString in paramsArray) {
        NSArray *params = [paramString componentsSeparatedByString:@"="];
        if (params.count != 2) {
            continue;
        }
        [paramDict setValue:params[0] forKey:params[1]];
    }

    return paramDict;
}

#pragma mark - Getter

- (AFNetworkReachabilityStatus)networkReachabilityStatus {
    return [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

- (NSMutableDictionary *)requestParams {
    if (!_requestParams) {
        _requestParams = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    return _requestParams;
}

- (NSMutableDictionary *)requestHeaderParams {
    if (!_requestHeaderParams) {
        _requestHeaderParams = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    return _requestHeaderParams;
}

@end
