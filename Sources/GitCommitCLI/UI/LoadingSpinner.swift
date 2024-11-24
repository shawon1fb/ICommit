import Foundation

@available(macOS 14.0, *)
actor LoadingSpinner {
    private var isAnimating = false
    private let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    private var currentFrame = 0
    private var currentTask: Task<Void, Never>?
    private var message: String = ""
    
    func start(message: String) async {
        self.message = message
        
        // If already animating, just update the message
        guard !isAnimating else {
            return
        }
        
        // Cancel any existing task
        await stopAnimation()
        
        isAnimating = true
        
        // Clear the current line before starting new animation
        print("\r\u{1B}[K", terminator: "")
        fflush(stdout)
        
        let task = Task { [self] in
            while await self.checkIsAnimating() {
                // Clear the line before printing new frame
                let currentMessage = await self.getMessage()
                let frame = await self.nextFrame()
                print("\r\u{1B}[K\(currentMessage) \(frame)", terminator: "")
                fflush(stdout)
                
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch {
                    await self.stopAnimation()
                    break
                }
            }
            
            // Clear the line when animation stops
            print("\r\u{1B}[K", terminator: "")
            fflush(stdout)
        }
        
        currentTask = task
    }
    
    private func getMessage() async-> String {
        return message
    }
    
    private func checkIsAnimating()async -> Bool {
        return isAnimating && !Task.isCancelled
    }
    
    private func nextFrame() async-> String {
        let frame = frames[currentFrame]
        currentFrame = (currentFrame + 1) % frames.count
        return frame
    }
    
    private func stopAnimation()async {
        isAnimating = false
        currentTask?.cancel()
        currentTask = nil
        
        // Clear the line
        print("\r\u{1B}[K", terminator: "")
        fflush(stdout)
    }
    
    func stop() async {
        await stopAnimation()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}
