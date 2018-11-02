//
//  AnimView.swift
//  AnimViewTest
//
//  Created by MP-11 on 01/11/18.
//  Copyright © 2018 Jatin. All rights reserved.
//

import Foundation
import UIKit


extension FloatingPoint {
    var degreesToRadians: Self {
        return self * .pi / 180
    }
    var radiansToDegrees: Self {
        var deg = self * 180 / .pi
        deg = deg > 0 ? deg : deg + 360
        return deg
    }
}


struct JPViewConfig {

    var backgroundColor: UIColor = .darkGray
    var mainStrokeColor: UIColor = .gray
    var mainDotsColor: UIColor = .gray

    var numberOfDots: Int = 8
    var mainStrokeWidth: CGFloat = 1
    var spacingBetweenDotAndLine: CGFloat = 4
    var padding: CGFloat = 32
    var smallDotSize: CGFloat = 2
    var bigDotSize: CGFloat = 8
    var touchPadding: CGFloat = 30
    var movingDiff: CGFloat = 1
    var startPosition: CGFloat =  0
    var endPosition: CGFloat = CGFloat.pi*2

    var userStrokeColor: UIColor = .green
    var userStrokeShadowColor: UIColor = .red
    var userStrokeWidth: CGFloat = 1
    var userDotSize: CGFloat = 12
    var userDotColor: UIColor = .green
    var userDotShadowRadius: CGFloat = 8

}

struct JPArc {
    var startAngle: CGFloat
    var endAngle: CGFloat
}

struct JPPoint {
    var position: CGPoint
    var dotAngle: CGFloat
    var size: CGFloat

}

protocol JPViewModelDelegate: class {
    var centerPosition: CGPoint { get }
    var radius: CGFloat { get }
    var circumference: CGFloat { get }
    func angleForCircumference(circum: CGFloat) -> CGFloat
    func updateUserPath()
}

struct JPViewModel {

    var mainPathArcs: [JPArc] {
        return getMainPathArcs().arcs
    }

    var dotsPositions: [JPPoint] {
        return getMainPathArcs().dots
    }
    var lineDashPattern: [CGFloat] {
        return getMainPathArcs().dashPattern
    }

    var currentUserPosition: CGFloat = 0

    weak var delegate: JPViewModelDelegate?

    var userPositionAngle: CGFloat = 0

    var config: JPViewConfig = JPViewConfig()

    private func getMainPathArcs() -> (arcs: [JPArc], dots: [JPPoint], dashPattern: [CGFloat]) {
        var dots: [JPPoint] = []
        var arcs: [JPArc] = []
        var lineDashPattern: [CGFloat] = []

        guard let delegate = delegate else {
            return (arcs, dots, lineDashPattern)
        }

        let paddingAngle = delegate.angleForCircumference(circum: config.spacingBetweenDotAndLine)
        let smallDotAngle = delegate.angleForCircumference(circum: config.smallDotSize)
        let BigDotAngle = delegate.angleForCircumference(circum: config.bigDotSize)
        func halfDotAngle(at position: Int) -> CGFloat {
            return delegate.angleForCircumference(circum: (shouldShowBigDot(position: position) ? config.bigDotSize : config.smallDotSize) / 2)
        }

        var startAngle: CGFloat = config.startPosition
        for dotPosition in 0...config.numberOfDots {

            var arcAngle = delegate.angleForCircumference(circum: delegate.circumference / CGFloat(config.numberOfDots))

            // Dash Pattern design
            if dotPosition == 0 {
                lineDashPattern.append(circumference(for: halfDotAngle(at: dotPosition) + paddingAngle))
            }

            let dot = JPPoint(position: positionOnCircle(for: startAngle),
                              dotAngle: startAngle,
                              size: shouldShowBigDot(position: dotPosition)
                                ? config.bigDotSize
                                : config.smallDotSize)
            dots.append(dot)



            startAngle += halfDotAngle(at: dotPosition) + paddingAngle

            // substract starting padding and dot size
            arcAngle -= halfDotAngle(at: dotPosition) + paddingAngle

            // substract ending padding and dot size
            arcAngle -= halfDotAngle(at: dotPosition + 1) + paddingAngle

            lineDashPattern.append(circumference(for: arcAngle))
            lineDashPattern.append(circumference(for: (halfDotAngle(at: dotPosition + 1) * 2) + (paddingAngle * 2) ))

            arcAngle += startAngle

            arcs.append(JPArc(startAngle: startAngle, endAngle: arcAngle))

            // move start angle to next position
            startAngle = arcAngle
            startAngle += halfDotAngle(at: dotPosition + 1) + paddingAngle
        }
        return (arcs, dots, lineDashPattern)
    }

    func positionOnCircle(for angle: CGFloat) -> CGPoint {
        guard let delegate = delegate else {
            return CGPoint.zero
        }
        let xPos = delegate.centerPosition.x + delegate.radius * cos(angle)
        let yPos = delegate.centerPosition.y + delegate.radius * sin(angle)
        return CGPoint(x: xPos, y: yPos)
    }


    func shouldShowBigDot(position: Int) -> Bool {
        return position % 2 == 0
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }

    func circumference(for angle: CGFloat) -> CGFloat {
        return angle * delegate!.radius
    }
}

class AnimView: UIView {

    // iVars
    var userPath: UIBezierPath = UIBezierPath()
    var userShapeLayer = CAShapeLayer()
    var touchPath: UIBezierPath = UIBezierPath()
    var internalTouchPath: UIBezierPath = UIBezierPath()

    var dotsLayers: [CAShapeLayer] = []

    var userDotPath = UIBezierPath()
    var userDotLayer = CAShapeLayer()

    var panGesture: UIPanGestureRecognizer?
    var model = JPViewModel()

    // lazy vars
    lazy var centerPosition = {
        return CGPoint(x: self.bounds.size.width / 2,
                       y: self.bounds.size.height / 2)
    }()

    lazy var radius: CGFloat = {
        return (self.bounds.size.width / 2) - model.config.padding
    }()

    lazy var circumference: CGFloat = {
        return 2 * CGFloat.pi * radius
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        model.delegate = self

        panGesture = UIPanGestureRecognizer(target: self,
                                            action: #selector(didPan(gesture:)))
        self.addGestureRecognizer(panGesture!)
    }

    @objc func didPan(gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: self)
        switch gesture.state {
        case .began:

            break
        case .cancelled:

            break
        case .changed:

            let t = touchPath.cgPath.contains(position,
                                              using: CGPathFillRule.winding,
                                              transform: CGAffineTransform.identity)
            let t2 = internalTouchPath.cgPath.contains(position,
                                                       using: CGPathFillRule.winding,
                                                       transform: CGAffineTransform.identity)
            if t && !t2 {

                var deg = atan2(position.y - centerPosition.y, position.x - centerPosition.x)

                let endStroke = deg.radiansToDegrees
                deg = endStroke.degreesToRadians

                setDotsColor(using: deg)

                let pos = model.positionOnCircle(for: deg)

                userDotLayer.actions = ["position": NSNull()]
                userDotLayer.position = pos
                userShapeLayer.actions = ["strokeEnd": NSNull()]
                userShapeLayer.strokeEnd = endStroke/360/2

            }

            break
        case .ended:
            break
        case .possible:
            break
        case .failed:
            break
        }
    }

    func setDotsColor(using degree: CGFloat) {
        for (index,dot) in model.dotsPositions.enumerated() {
            if dot.dotAngle < degree {
                dotsLayers[index].fillColor = model.config.userDotColor.cgColor
                dotsLayers[index].strokeColor = model.config.userDotColor.cgColor
            } else {
                dotsLayers[index].fillColor = model.config.mainDotsColor.cgColor
                dotsLayers[index].strokeColor = model.config.mainDotsColor.cgColor
            }
        }
    }

    func drawTouchPath() {
        internalTouchPath = UIBezierPath(arcCenter: centerPosition,
                                         radius: radius - model.config.touchPadding,
                                         startAngle: model.config.startPosition,
                                         endAngle: model.config.endPosition,
                                         clockwise: true)

        touchPath = UIBezierPath(arcCenter: centerPosition,
                                 radius: radius + model.config.touchPadding,
                                 startAngle: model.config.startPosition,
                                 endAngle: model.config.endPosition,
                                 clockwise: true)
        UIColor.clear.setStroke()
        touchPath.lineWidth = 1
        internalTouchPath.lineWidth = 1
        internalTouchPath.stroke()
        touchPath.stroke()
    }

    func drawUserPath() {
        print("drawinggg")
        guard let first = model.dotsPositions.first else {
            return
        }
        userPath.move(to: first.position)
        userPath.addArc(withCenter: centerPosition,
                        radius: radius,
                        startAngle: model.config.startPosition,
                        endAngle: model.config.endPosition,
                        clockwise: true)

        userShapeLayer.path = userPath.cgPath

        model.config.userStrokeColor.setStroke()
        userPath.lineWidth = model.config.userStrokeWidth
        userShapeLayer.fillColor = nil
        userShapeLayer.strokeColor = model.config.userStrokeColor.cgColor
        userShapeLayer.lineWidth = model.config.userStrokeWidth

        for (index, lineDash) in model.lineDashPattern.enumerated() {
            if index == 0 {
                userShapeLayer.lineDashPhase = -lineDash
            } else {
                if userShapeLayer.lineDashPattern == nil {
                    userShapeLayer.lineDashPattern = [NSNumber(value: Float(lineDash))]
                } else {
                    userShapeLayer.lineDashPattern?.append(NSNumber(value: Float(lineDash)))
                }
            }
        }

        userShapeLayer.strokeStart = 0
        userShapeLayer.strokeEnd = 0
        layer.addSublayer(userShapeLayer)
    }

    override func draw(_ rect: CGRect) {

        backgroundColor = model.config.backgroundColor
        self.transform = CGAffineTransform(rotationAngle: CGFloat(Double(-90) * .pi/180))
        drawDots()
        drawMainPath()
        drawTouchPath()
        drawUserPath()
        drawUserDot()
    }

    // MARK: Helper methods

    func angleForCircumference(circum: CGFloat) -> CGFloat {
        return ((CGFloat.pi * 2)/circumference)*circum
    }

    func setConfiguration(config: JPViewConfig) {
        model.config = config
        setNeedsDisplay()
    }

    func drawMainPath() {
        for arc in model.mainPathArcs {
            let temp = UIBezierPath(arcCenter: centerPosition,
                                    radius: radius,
                                    startAngle: arc.startAngle,
                                    endAngle: arc.endAngle,
                                    clockwise: true)
            model.config.mainStrokeColor.setStroke()
            temp.lineWidth = model.config.mainStrokeWidth
            temp.stroke()
        }
    }

    func drawDots() {

        for layer in dotsLayers {
            layer.removeFromSuperlayer()
        }
        dotsLayers.removeAll()
        for dot in model.dotsPositions {
            let dotLayer = CAShapeLayer()
            let temp = UIBezierPath(arcCenter: dot.position,
                                    radius: dot.size / 2,
                                    startAngle: model.config.startPosition,
                                    endAngle: model.config.endPosition,
                                    clockwise: true)
            dotLayer.path = temp.cgPath
            dotLayer.fillColor = model.config.mainDotsColor.cgColor
            dotLayer.strokeColor = model.config.mainDotsColor.cgColor
            dotLayer.lineWidth = model.config.mainStrokeWidth
            layer.insertSublayer(dotLayer, below: userDotLayer)
            dotsLayers.append(dotLayer)
        }
    }

    func drawUserDot() {
        if let firstPosition = model.dotsPositions.first {

            userDotPath = UIBezierPath(arcCenter: CGPoint.zero,
                                       radius: model.config.userDotSize/2,
                                       startAngle: model.config.startPosition,
                                       endAngle: model.config.endPosition,
                                       clockwise: true)

            userDotPath.close()
            userDotLayer.path = userDotPath.cgPath
            userDotLayer.strokeColor = model.config.userDotColor.cgColor
            userDotLayer.fillColor = model.config.userDotColor.cgColor
            userDotLayer.position = firstPosition.position
            userDotLayer.shadowRadius = model.config.userDotShadowRadius
            userDotLayer.shadowOpacity = 1
            userDotLayer.shadowOffset = CGSize.zero
            userDotLayer.shadowColor = UIColor.green.cgColor

            if userDotLayer.superlayer == nil {
                layer.addSublayer(userDotLayer)
            }
        }
    }
}

extension AnimView: JPViewModelDelegate {
    func updateUserPath() {
        setNeedsDisplay()
    }
}
