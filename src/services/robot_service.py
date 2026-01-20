from typing import Optional
from model.position_model import PositionModel
from model.positionJ_model import PositionJModel
from repository.position_repository import PositionRepository
from repository.positionJ_repository import PositionJRepository
from utils.robot_singleton import RobotSingletonRCP
from datetime import datetime

class RobotService:

    def __init__(self):
        self._repo = PositionRepository()
        self._repoJ = PositionJRepository()

    def get_current_pose(self) -> "PositionModel":
        robot = RobotSingletonRCP()
        result = robot.GetActualTCPPose()
        timestamp = datetime.now().isoformat()
        ip_result = robot.GetControllerIP()

        if isinstance(result, tuple):
            error, pose = result
            x, y, z, rx, ry, rz = pose
        else:
            error = result
            x = y = z = rx = ry = rz = 0.0

        config = -1
        result = robot.GetRobotCurJointsConfig()
        if(isinstance(result, tuple)): 
            error, data = result
            if(error == 0): config = data

        ip = ip_result[1] if isinstance(ip_result, tuple) else "0.0.0.0"

        return PositionModel(
                                id=None,
                                name='nome do ponto',
                                x=float(x),
                                y=float(y),
                                z=float(z),
                                rx=float(rx),
                                ry=float(ry),
                                rz=float(rz),
                                config=int(config),
                                created_at=timestamp
                            )
        
    def get_current_joint_pose(self) -> "PositionJModel":
        robot = RobotSingletonRCP()
        result = robot.GetActualJointPosDegree(0)  # 0 = todas as juntas
        timestamp = datetime.now().isoformat()
        ip_result = robot.GetControllerIP()

        if isinstance(result, tuple):
            error, joints = result
            if error == 0 and len(joints) >= 6:
                j1, j2, j3, j4, j5, j6 = joints[:6]
            else:
                j1 = j2 = j3 = j4 = j5 = j6 = 0.0
        else:
            j1 = j2 = j3 = j4 = j5 = j6 = 0.0

        config = -1
        result = robot.GetRobotCurJointsConfig()
        if(isinstance(result, tuple)): 
            error, data = result
            if(error == 0): config = data

        ip = ip_result[1] if isinstance(ip_result, tuple) else "0.0.0.0"

        return PositionJModel(
                                id=None,
                                name='nome do ponto',
                                j1=float(j1),
                                j2=float(j2),
                                j3=float(j3),
                                j4=float(j4),
                                j5=float(j5),
                                j6=float(j6),
                                config=int(config),
                                created_at=timestamp
                            )
        
    def get_sdk_version(self):
        robot = RobotSingletonRCP()
        return robot.GetSDKVersion()

    def save_current_pose(self, robotModel: PositionModel):
        robotModel.id = 1
        robotModel.name = "nome do ponto"
        self._repo.insert_pose(robotModel)
    
    def save_current_joint_pose(self, robotModel: PositionJModel):
        robotModel.id = 1
        robotModel.name = "nome do ponto"
        self._repoJ.insert_pose(robotModel)

    def move(self, points: PositionModel):
        
        robot = RobotSingletonRCP()
        timestamp = datetime.now().isoformat()
        ip_result = robot.GetControllerIP()

        print("Pontos recebidos para mover o robo:", points)
        print("IP do robo:", ip_result)
        print("Timestamp da operacao:", timestamp)
        print("Iniciando movimento...")

        desc_pos1 = [points.x, 
                     points.y, 
                     points.z, 
                     points.rx, 
                     points.ry, 
                     points.rz
                     ]
        
        config1 = points.config
        
        result = robot.GetInverseKin(desc_pos = desc_pos1, type = 0, config = config1)
        if(isinstance(result, tuple)):
            error, position = result
            if(error != 0): return False
            success = robot.MoveJ(joint_pos = position, tool = 1, user = 0, vel = 200)
            print("Movendo o robo para a posicao salva", success)
            return bool(success == 0)
    
    def move_joints(self, points: PositionJModel):
        
        robot = RobotSingletonRCP()
        timestamp = datetime.now().isoformat()
        ip_result = robot.GetControllerIP()

        joint_pos = [points.j1, 
                     points.j2, 
                     points.j3, 
                     points.j4, 
                     points.j5, 
                     points.j6
                     ]
        
        success = robot.MoveJ(joint_pos = joint_pos, tool = 1, user = 0, vel = 200)
        return bool(success == 0)