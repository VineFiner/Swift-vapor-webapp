//
//  JSONContainer.swift
//  App
//
//  Created by mac on 2018/10/5.
//

import Foundation
import Vapor

enum ResponseStatus: UInt, Content {
    case ok = 0 // 请求成功
    case noContent = 204
    
    var desc: String {
        switch self {
        case .ok:
            return "请求成功"
        default:
            return "请求失败"
        }
    }
}

struct Empty: Content {
}

struct JSONContainer<D: Content>: Content {
    private var status: ResponseStatus
    private var message: String
    private var data: D?
    
    static var successEmpty: JSONContainer<Empty> {
        return JSONContainer<Empty>()
    }
    
    init(data:D? = nil) {
        self.status = .ok
        self.message = self.status.desc
        self.data = data
    }
    
    init(data: D) {
        self.status = .ok
        self.message = status.desc
        self.data = data
    }
}

extension Future where T: Content {
    func makeJson(on request: Request) throws -> Future<Response> {
        return try self.map { data in
            return JSONContainer(data: data)
        }.encode(for: request)
    }
}
