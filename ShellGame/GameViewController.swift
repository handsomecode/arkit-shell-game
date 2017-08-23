//
// Copyright © 2017 Handsome.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
/////////////////////////////////////////////////////////////////////////////

import Foundation
import ARKit

enum GameState: Int {
    case position = 0
    case start
    case inAction
    case select
    case next
}

class GameViewContoller: UIViewController {
    @IBOutlet private weak var sceneView: ARSCNView!
    @IBOutlet private weak var scoreLabel: UILabel!
    @IBOutlet private weak var recordLabel: UILabel!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var informationContainerView: UIView!
    @IBOutlet private weak var resultsPanelView: UIView!
    @IBOutlet private weak var informationCenterYConstraint: NSLayoutConstraint!
    
    private let cupsNumber = 3
    private var cupsPermutation = Permutation([0, 1, 2])
    
    private var state: GameState = .position {
        didSet {
            handleGameState()
        }
    }
    
    private var record = 0 {
        didSet {
            DispatchQueue.main.async {
                self.recordLabel.text = " Record: \(self.record) "
            }
        }
    }
    
    private var levelNumber = 1 {
        didSet {
            score = score + (levelNumber - oldValue) * 10
        }
    }
    
    private var score = 0 {
        didSet {
            DispatchQueue.main.async {
                self.scoreLabel.text = " Score: \(self.score) "
                if self.record < self.score {
                    self.record = self.score
                    RecordStorage.shared.save(record: self.record)
                }
            }
        }
    }
    
    private lazy var scene: SCNScene = {
        guard let scene = SCNScene(named: "art.scnassets/game.scn") else {
            preconditionFailure("Game scene not found")
        }
        return scene
    }()
    
    private lazy var gameNode: SCNNode = {
        guard let node = scene.rootNode.childNode(withName: "game", recursively: true) else {
            preconditionFailure("Game node not found")
        }
        node.position = SCNVector3 (0, -0.1, -0.5)
        return node
    }()
    
    private lazy var ballNode: SCNNode = {
        guard let node = scene.rootNode.childNode(withName: "ball", recursively: true) else {
            preconditionFailure("Ball node not found")
        }
        return node
    }()
    
    private lazy var cupsNodes = findCupsNodes(in: gameNode)
    private lazy var indexOfCupWithBall = Int(arc4random_uniform(UInt32(cupsNumber)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene = scene
        sceneView.delegate = self
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedInSceneView)))
        
        resultsPanelView.isHidden = true
        informationContainerView.alpha = 0
        
        record = RecordStorage.shared.load()
        
        showMessage("Move device to find a plane", animated: true, duration: 2)
        showDebuggingIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scoreLabel.roundCorners(radius: 4)
        recordLabel.roundCorners(radius: 4)
        informationContainerView.roundCorners(radius: 10)
        
        updatePositionOfInformationView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func handleGameState() {
        switch state {
        case .inAction:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 0.0
            }
            self.showMessage("")
        case .select:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.showMessage("Choose a cup")
        case .start:
            DispatchQueue.main.async {
                self.resultsPanelView.isHidden = false
                self.informationCenterYConstraint.constant = self.view.frame.height/3
                self.view.layoutIfNeeded()
            }
            self.showMessage("Tap to start", animated: true, duration: 0.3)
        case .next:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.showMessage("Tap to continue")
        case .position: fallthrough
        default: break
        }
    }
    
    @objc private func tappedInSceneView(recognizer: UIGestureRecognizer) {
        if state == .position {
            let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            guard let hitResult = hitTestResult.first else {
                print("HitResult is empty")
                return
            }

            gameNode.transform = SCNMatrix4(hitResult.worldTransform)
            let camera = self.sceneView.pointOfView!
            gameNode.rotation = SCNVector4(0, 1, 0, camera.rotation.y)
            gameNode.isHidden = false
            
            let configuration = ARWorldTrackingSessionConfiguration()
            sceneView.session.run(configuration)
            
            state = .start
        } else if state == .start {
            state = .inAction
            let elevation = 0.075
            let moveCupUp = SCNAction.moveBy(x: 0, y: CGFloat(elevation), z: 0, duration: 0.5)
            let ballStartPosition = cupsNodes[indexOfCupWithBall].convertPosition(SCNVector3(0, 0, 0), to: gameNode)
            let moveBall = SCNAction.move(to: ballStartPosition, duration: 0.5)
            let moveCupDown = SCNAction.moveBy(x: 0, y: -CGFloat(elevation), z: 0, duration: 0.5)
            
            cupsNodes[indexOfCupWithBall].runAction(SCNAction.sequence([moveCupUp,
                                                          SCNAction.wait(duration: moveBall.duration),
                                                          moveCupDown])) {
                self.run()
            }
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: moveCupUp.duration),
                                                   moveBall]))
            
        } else if state == .select {
            let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
            
            guard let hitResult = hitTestResult.first else {
                print("HitResult is empty")
                return
            }
            
            if let cup = hitResult.node.parent, let selectedCup = cupsNodes.index(of: cup) {
                let actualBallPosition = cupsPermutation[indexOfCupWithBall]
                let selectedBallPosition = cupsPermutation[selectedCup]
                print ("actualBallPosition: \(actualBallPosition). selectedBallPosition: \(selectedBallPosition)")
                ballNode.position = cupsNodes[indexOfCupWithBall].convertPosition(SCNVector3(0, 0, 0), to: self.gameNode)
                ballNode.isHidden = false
                let cupWithBall = cupsNodes[indexOfCupWithBall]
                if selectedBallPosition == actualBallPosition {
                    state = .inAction
                    AudioPlayer.shared.playSound(.success, on: sceneView.scene.rootNode)
                    let moveCupUp = SCNAction.moveBy(x: 0, y: CGFloat(0.075), z: 0, duration: 0.5)
                    cupWithBall.runAction(moveCupUp) {
                        self.levelNumber = self.levelNumber + 1
                        self.state = .next
                    }
                } else {
                    self.score = max(0, self.score - 5)
                    AudioPlayer.shared.playSound(.fail, on: sceneView.scene.rootNode)
                }
            }
        } else if state == .next {
            state = .inAction
            let cupWithBall = cupsNodes[indexOfCupWithBall]
            let moveCupDown = SCNAction.moveBy(x: 0, y: -CGFloat(0.075), z: 0, duration: 0.5)
            cupWithBall.runAction(moveCupDown) {
                self.run()
            }
        }
    }
    
    private func run() {
        ballNode.isHidden = true
        run(level: Level.generate(number: levelNumber)) {
            self.state = .select
        }
    }
    
    private func run(level: Level, completionHandler: @escaping () -> Void) {
        var stepToRun = 0
        
        var innerCompletionHandler = {}
        innerCompletionHandler = {
            stepToRun = stepToRun + 1
            if stepToRun < level.steps.count {
                self.run(levelStep: level.steps[stepToRun], completionHandler: innerCompletionHandler)
            } else {
                completionHandler()
            }
        }
        run(levelStep: level.steps[stepToRun], completionHandler: innerCompletionHandler)
    }
    
    private func run(levelStep: LevelStep, completionHandler: @escaping() -> Void){
        var completionCounter = 0
        let proxyCompletionHandler = {
            completionCounter = completionCounter + 1
            if completionCounter == self.cupsNodes.count {
                self.cupsPermutation = Permutation.mult(self.cupsPermutation, levelStep.permutation)
                completionHandler()
            }
        }
        
        let invertedCupsPermutation = Permutation.invert(cupsPermutation)
        for index in 0..<cupsNodes.count {
            let cupAtIndex = cupsNodes[invertedCupsPermutation[index]]
            let action = SCNAction.permutate(index: index, with: levelStep, to: 0.11)
            cupAtIndex.runAction(action, completionHandler: proxyCompletionHandler)
        }
    }
}


//MARK: ARSCNViewDelegate
extension GameViewContoller: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        self.showMessage("Plane is detected. Tap to position,\nwhere you'd like to put the game.", animated: true)
    }
}


//MARK: Helpers
extension GameViewContoller {
    private func showDebuggingIfNeeded() {
        #if DEBUG_ARKIT
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            cupsNodes[0].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.red
            cupsNodes[1].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.green
            cupsNodes[2].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.blue
            gameNode.isHidden = false
            state = .start
        #endif
    }
    
    private func findCupsNodes(in rootNode: SCNNode) -> [SCNNode] {
        var cupsNodes = [SCNNode]()
        for i in 0..<cupsNumber {
            guard let cupNode = rootNode.childNode(withName: "cup\(i)", recursively: true) else {
                preconditionFailure("No cup\(i) node in scene")
            }
            cupsNodes.append(cupNode)
        }
        return cupsNodes
    }
    
    private func showMessage(_ message: String, animated: Bool = false, duration: TimeInterval = 1.0) {
        DispatchQueue.main.async {
            if animated {
                UIView.animate(withDuration: duration, animations: {
                    self.informationLabel.alpha = 0.0
                    self.informationContainerView.alpha = 0.0
                }) { _ in
                    self.informationLabel.text = message
                    self.informationLabel.alpha = 0.0
                    self.informationContainerView.alpha = 0.0
                    UIView.animate(withDuration: duration, animations: {
                        self.informationLabel.alpha = 1.0
                        self.informationContainerView.alpha = 1.0
                    })
                }
            } else {
                self.informationLabel.text = message
            }
        }
    }
    
    private func updatePositionOfInformationView() {
        switch state {
        case .start: fallthrough
        case .select: fallthrough
        case .next:
            self.informationCenterYConstraint.constant = self.view.frame.height/3
            self.view.layoutIfNeeded()
        default: break
        }
    }
}
