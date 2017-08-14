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
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var informationContainerView: UIView!
    @IBOutlet weak var resultsPanelView: UIView!
    
    @IBOutlet weak var informationCenterYConstraint: NSLayoutConstraint!
    
    var gameNode: SCNNode!
    var cups = [SCNNode]()
    var ball: SCNNode!
    var ballInCup: Int!
    var cupsPermutation = Permutation([0, 1, 2])
    var state: GameState = .position {
        didSet {
            handleState()
        }
    }
    
    var record = 0 {
        didSet {
            DispatchQueue.main.async {
                self.recordLabel.text = " Record: \(self.record) "
            }
        }
    }
    var levelNumber = 1 {
        didSet {
            score = score + (levelNumber - oldValue) * 10
        }
    }
    
    var score = 0 {
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
    
    let debugMode = false
    
    lazy var successAudioSource: SCNAudioSource = {
        let sound = SCNAudioSource(fileNamed: "art.scnassets/sounds/success.wav")!
        sound.volume = 1
        sound.isPositional = true
        sound.shouldStream = false
        sound.load()
        return sound
    }()
    
    lazy var failAudioSource: SCNAudioSource = {
        let sound = SCNAudioSource(fileNamed: "art.scnassets/sounds/fail.mp3")!
        sound.volume = 1
        sound.isPositional = true
        sound.shouldStream = false
        sound.load()
        return sound
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadGame()
        // SceneVisualDebugger.sharedInstance.debugAxes(node: cups[0], recursively: false)
        registerGestureRecognizers()

        record = RecordStorage.shared.load()
        resultsPanelView.isHidden = true
        informationContainerView.alpha = 0
        toast(message: "Move device to find a plane", animated: true, duration: 2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
//        TODO: replace it new API ARWorldTrackingSessionConfiguration -> ARWorldTrackingConfiguration()
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scoreLabel.layer.cornerRadius = 4
        recordLabel.layer.cornerRadius = 4
        
        informationContainerView.layer.cornerRadius = 10
        informationContainerView.clipsToBounds = true
        
        switch state {
        case .start: fallthrough
        case .select: fallthrough
        case .next:
            self.informationCenterYConstraint.constant = self.view.frame.height/3
            self.view.layoutIfNeeded()
        default: break
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func loadGame() {
        let scene = SCNScene(named: "art.scnassets/game.scn")!
        
        gameNode = scene.rootNode.childNode(withName: "game", recursively: true)!
        gameNode.position = SCNVector3 (0, -0.1, -0.5)
        
        ball = scene.rootNode.childNode(withName: "ball", recursively: true)!
        for i in 0..<3 {
            if let cup = gameNode.childNode(withName: "cup\(i)", recursively: true) {
                cups.append(cup)
            } else {
                fatalError("No cup\(i) node in scene")
            }
        }
        
        ballInCup = Int(arc4random_uniform(UInt32(cups.count)))

        sceneView.scene = scene
        sceneView.delegate = self
        
        showDebuggingIfNeeded()
    }
    
    private func showDebuggingIfNeeded() {
        if debugMode {
            sceneView.showsStatistics = true
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            cups[0].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.red
            cups[1].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.green
            cups[2].childNode(withName: "innerCup", recursively: true)!.geometry?.materials[0].diffuse.contents = UIColor.blue
            gameNode.isHidden = false
            state = .start
        }
    }
    
    private func handleState() {
        switch state {
        case .inAction:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 0.0
            }
            self.toast(message: "")
        case .select:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.toast(message: "Choose a cup")
        case .start:
            DispatchQueue.main.async {
                self.resultsPanelView.isHidden = false
                self.informationCenterYConstraint.constant = self.view.frame.height/3
                self.view.layoutIfNeeded()
            }
            self.toast(message: "Tap to start", animated: true, duration: 0.3)
        case .next:
            DispatchQueue.main.async {
                self.informationContainerView.alpha = 1.0
            }
            self.toast(message: "Tap to continue")
        case .position: fallthrough
        default: break
        }
    }
    
    private func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedInSceneView))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tappedInSceneView(recognizer: UIGestureRecognizer) {
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
            let ballStartPosition = cups[ballInCup].convertPosition(SCNVector3(0, 0, 0), to: gameNode)
            let moveBall = SCNAction.move(to: ballStartPosition, duration: 0.5)
            let moveCupDown = SCNAction.moveBy(x: 0, y: -CGFloat(elevation), z: 0, duration: 0.5)
            
            cups[ballInCup].runAction(SCNAction.sequence([moveCupUp,
                                                          SCNAction.wait(duration: moveBall.duration),
                                                          moveCupDown])) {
                self.run()
            }
            ball.runAction(SCNAction.sequence([SCNAction.wait(duration: moveCupUp.duration),
                                               moveBall]))
            
        } else if state == .select {
            let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, options: [:])
            
            guard let hitResult = hitTestResult.first else {
                print("HitResult is empty")
                return
            }
            
            if let cup = hitResult.node.parent, let selectedCup = cups.index(of: cup) {
                let actualBallPosition = cupsPermutation[ballInCup]
                let selectedBallPosition = cupsPermutation[selectedCup]
                print ("actualBallPosition: \(actualBallPosition). selectedBallPosition: \(selectedBallPosition)")
                ball.position = cups[ballInCup].convertPosition(SCNVector3(0, 0, 0), to: self.gameNode)
                ball.isHidden = false
                let cupWithBall = cups[ballInCup]
                if selectedBallPosition == actualBallPosition {
                    state = .inAction
                    playAudioSource(successAudioSource)
                    let moveCupUp = SCNAction.moveBy(x: 0, y: CGFloat(0.075), z: 0, duration: 0.5)
                    cupWithBall.runAction(moveCupUp) {
                        self.levelNumber = self.levelNumber + 1
                        self.state = .next
                    }
                } else {
                    self.score = max(0, self.score - 5)
                    playAudioSource(failAudioSource)
                }
            }
        } else if state == .next {
            state = .inAction
            let cupWithBall = cups[ballInCup]
            let moveCupDown = SCNAction.moveBy(x: 0, y: -CGFloat(0.075), z: 0, duration: 0.5)
            cupWithBall.runAction(moveCupDown) {
                self.run()
            }
        }
    }
    
    private func run() {
        run(level: Level.generate(number: levelNumber)) {
            self.state = .select
        }
    }
    
    private func run(level: Level, completionHandler: @escaping () -> Void) {
        ball.isHidden = true
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
            if completionCounter == self.cups.count {
                self.cupsPermutation = Permutation.mult(self.cupsPermutation, levelStep.permutation)
                completionHandler()
            }
        }
        
        let invertedCupsPermutation = Permutation.invert(cupsPermutation)
        for index in 0..<cups.count {
            let cupAtIndex = cups[invertedCupsPermutation[index]]
            let action = SCNAction.permutate(index: index, with: levelStep, to: 0.11)
            cupAtIndex.runAction(action, completionHandler: proxyCompletionHandler)
        }
    }
    
    private func playAudioSource(_ audio: SCNAudioSource) {
        let action = SCNAction.playAudio(audio, waitForCompletion: false)
        sceneView.scene.rootNode.runAction(action)
    }

    private func toast(message: String, animated: Bool = false, duration: TimeInterval = 1.0) {
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
}

//MARK: ARSCNViewDelegate
extension GameViewContoller: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        self.toast(message: "Plane is detected. Tap to position,\nwhere you'd like to put the game.", animated: true)
    }
}
