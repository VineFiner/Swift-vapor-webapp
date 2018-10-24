//
//  PageContext.swift
//  App
//
//  Created by mac on 2018/9/17.
//

import Foundation
import Vapor

struct PageContext : Content {
    
    var has_next: Bool = false
    var has_previous: Bool = false
    
    var item_count: NSInteger  // 这里是数据个数
    var page_index: NSInteger  // 当前页
    var page_size: NSInteger   // 页面间隔
    var page_count: NSInteger // 总页数
    
    // 当前偏移
    var range: Range<Int> {
        if item_count == 0 || page_index > item_count {
            return 0..<0
        }else {
            let start = page_size * (page_index - 1)
            let end = start + page_size
            return start..<end
        }
    }

    init(item_count: NSInteger, page_index: Int = 1, page_size: Int = 10) {
        self.item_count = item_count
        self.page_size = page_size

        self.page_count = (item_count / page_size) + (item_count % page_size > 0 ? 1 : 0)
        if item_count == 0 || page_index > item_count {
            self.page_index = 1
        }else {
            self.page_index = page_index
        }
        self.has_next = self.page_index < self.page_count
        self.has_previous = self.page_index > 1
    }
}
