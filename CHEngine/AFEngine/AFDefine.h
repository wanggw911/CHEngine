//
//  CHDefine.h
//  CHEngine
//
//  Created by GuowenWang on 2017/12/22.
//  Copyright © 2017年 GuowenWang. All rights reserved.
//

#ifndef CHDefine_h
#define CHDefine_h


//  打印
#ifdef DEBUG
#define AFEngineLog(s, ... ) printf("class: 【%p %s:(%d)】 method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String] )
#else
#define AFEngineLog(s, ... )
#endif

//  网络状态发生改变的通知
#define kNotification_NetReachabilityChanged    @"kNotification_NetReachabilityChanged"


#endif /* CHDefine_h */
