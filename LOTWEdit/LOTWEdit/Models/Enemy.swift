//
//  Enemy.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/6/25.
//

struct Enemy {
    var spriteIndex: UInt8
    var drawAttribute: UInt8
    var posX: UInt8
    var posY: UInt8
    var hitPoints: UInt8
    var damage: UInt8
    var deathSprite: UInt8
    var animationStyle: UInt8
    var behaviorType: UInt8
    var speed: UInt8
    var additionalData: [UInt8]
    
    init(data: [UInt8]) {
        if data.count >= 16 {
            self.spriteIndex = data[0]
            self.drawAttribute = data[1]
            self.posX = data[2]
            self.posY = data[3]
            self.hitPoints = data[4]
            self.damage = data[5]
            self.deathSprite = data[6]
            self.animationStyle = data[7]
            self.behaviorType = data[8]
            self.speed = data[9]
            self.additionalData = Array(data[10..<16])
        } else {
            self.spriteIndex = 0
            self.drawAttribute = 0
            self.posX = 0
            self.posY = 0
            self.hitPoints = 0
            self.damage = 0
            self.deathSprite = 0
            self.animationStyle = 0
            self.behaviorType = 0
            self.speed = 0
            self.additionalData = [0, 0, 0, 0, 0, 0]
        }
    }
}
