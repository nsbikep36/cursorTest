import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isSoundEnabled = true
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        let soundNames = [
            "select",
            "match",
            "swap",
            "bomb",
            "rainbow",
            "shuffle",
            "levelComplete",
            "gameOver"
        ]
        
        for soundName in soundNames {
            createSyntheticSound(for: soundName)
        }
    }
    
    private func createSyntheticSound(for name: String) {
        // 由于我们不能包含真实的音频文件，这里创建合成音效
        // 在实际应用中，你应该使用真实的音频文件
        
        let frequency: Float
        let duration: TimeInterval
        
        switch name {
        case "select":
            frequency = 800
            duration = 0.1
        case "match":
            frequency = 1200
            duration = 0.3
        case "swap":
            frequency = 600
            duration = 0.2
        case "bomb":
            frequency = 400
            duration = 0.5
        case "rainbow":
            frequency = 1500
            duration = 0.4
        case "shuffle":
            frequency = 700
            duration = 0.6
        case "levelComplete":
            frequency = 1000
            duration = 1.0
        case "gameOver":
            frequency = 300
            duration = 0.8
        default:
            frequency = 800
            duration = 0.2
        }
        
        if let audioBuffer = createToneBuffer(frequency: frequency, duration: duration) {
            do {
                let player = try AVAudioPlayer(data: audioBuffer)
                player.prepareToPlay()
                audioPlayers[name] = player
            } catch {
                print("Failed to create audio player for \(name): \(error)")
            }
        }
    }
    
    private func createToneBuffer(frequency: Float, duration: TimeInterval) -> Data? {
        let sampleRate: Float = 44100
        let samples = Int(sampleRate * Float(duration))
        
        var audioData = Data()
        
        for i in 0..<samples {
            let time = Float(i) / sampleRate
            let amplitude: Float = 0.3
            let value = sin(2.0 * Float.pi * frequency * time) * amplitude
            
            // 应用淡入淡出效果
            let fadeTime: Float = 0.05
            let fadeSamples = Int(fadeTime * sampleRate)
            
            var finalValue = value
            if i < fadeSamples {
                finalValue *= Float(i) / Float(fadeSamples)
            } else if i > samples - fadeSamples {
                finalValue *= Float(samples - i) / Float(fadeSamples)
            }
            
            // 转换为16位PCM
            let sample = Int16(finalValue * Float(Int16.max))
            var sampleData = Data()
            sampleData.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
            audioData.append(sampleData)
        }
        
        // 创建WAV头部
        let header = createWAVHeader(
            sampleRate: Int(sampleRate),
            channels: 1,
            bitsPerSample: 16,
            dataSize: audioData.count
        )
        
        var wavData = Data()
        wavData.append(header)
        wavData.append(audioData)
        
        return wavData
    }
    
    private func createWAVHeader(sampleRate: Int, channels: Int, bitsPerSample: Int, dataSize: Int) -> Data {
        var header = Data()
        
        // RIFF头
        header.append("RIFF".data(using: .ascii)!)
        let fileSize = 36 + dataSize
        header.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt子块
        header.append("fmt ".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        
        let byteRate = sampleRate * channels * bitsPerSample / 8
        header.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        
        let blockAlign = channels * bitsPerSample / 8
        header.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })
        
        // data子块
        header.append("data".data(using: .ascii)!)
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        
        return header
    }
    
    func playSound(_ soundName: String) {
        guard isSoundEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self,
                  let player = self.audioPlayers[soundName] else { return }
            
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
            
            player.play()
        }
    }
    
    func playBackgroundMusic() {
        guard isSoundEnabled else { return }
        
        // 在实际应用中，这里应该播放背景音乐文件
        // 由于我们使用的是合成音效，这里暂时留空
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
        
        if !isSoundEnabled {
            stopAllSounds()
        }
    }
    
    private func stopAllSounds() {
        for (_, player) in audioPlayers {
            if player.isPlaying {
                player.stop()
            }
        }
        stopBackgroundMusic()
    }
    
    // 为游戏逻辑提供的便捷方法
    func playSelectSound() {
        playSound("select")
    }
    
    func playMatchSound() {
        playSound("match")
    }
    
    func playSwapSound() {
        playSound("swap")
    }
    
    func playBombSound() {
        playSound("bomb")
    }
    
    func playRainbowSound() {
        playSound("rainbow")
    }
    
    func playShuffleSound() {
        playSound("shuffle")
    }
    
    func playLevelCompleteSound() {
        playSound("levelComplete")
    }
    
    func playGameOverSound() {
        playSound("gameOver")
    }
}