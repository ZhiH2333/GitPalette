//
//  GitProcessRunner.swift
//  GitPalette
//
//  在指定仓库目录异步执行 git 子进程。
//

import Foundation

/// git 进程输出。
struct GitProcessResult: Equatable, Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}

/// 封装 Process + Pipe 执行 git。
enum GitProcessRunner {
    private static let gitExecutablePath: String = "/usr/bin/git"
    private static let timeoutSeconds: TimeInterval = 30

    /// 在仓库目录执行 git 参数数组（不经过 shell）。
    static func executeRun(
        repositoryPath: String,
        arguments: [String]
    ) async throws -> GitProcessResult {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result: GitProcessResult = try executeRunSync(
                        repositoryPath: repositoryPath,
                        arguments: arguments
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 同步执行（仅在后台队列调用）。先读管道再等待退出，避免管道填满死锁。
    private static func executeRunSync(
        repositoryPath: String,
        arguments: [String]
    ) throws -> GitProcessResult {
        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: gitExecutablePath)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)
        let stdoutPipe: Pipe = Pipe()
        let stderrPipe: Pipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        let lock: NSLock = NSLock()
        var stdoutData: Data = Data()
        var stderrData: Data = Data()
        let group: DispatchGroup = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let data: Data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            lock.lock()
            stdoutData = data
            lock.unlock()
            group.leave()
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let data: Data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            lock.lock()
            stderrData = data
            lock.unlock()
            group.leave()
        }
        do {
            try process.run()
        } catch {
            throw GitCommandError.processLaunchFailed(error.localizedDescription)
        }
        let deadline: Date = Date().addingTimeInterval(timeoutSeconds)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if process.isRunning {
            process.terminate()
            let killDeadline: Date = Date().addingTimeInterval(2)
            while process.isRunning && Date() < killDeadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            group.wait()
            throw GitCommandError.processLaunchFailed("timed out")
        }
        group.wait()
        lock.lock()
        let stdout: String = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr: String = String(data: stderrData, encoding: .utf8) ?? ""
        lock.unlock()
        return GitProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }
}
