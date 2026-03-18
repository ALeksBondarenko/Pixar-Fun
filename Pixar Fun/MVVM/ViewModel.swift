//
//  ViewModel.swift
//  Pixar Fan
//
//  Created by Александр Бондаренко on 29.12.2025.
//

import Foundation
import Combine

class ViewModel: ObservableObject {
    
    private var tasks: [Task<Void, Never>] = []
    
    func addTask(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async -> Void
    ) {
        let task = Task(priority: priority) {
            await operation()
        }
        
        tasks.append(task)
    }
    
    func cancelAllTasks() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    deinit {
        cancelAllTasks()
    }
}
