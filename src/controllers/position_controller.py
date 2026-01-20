from PySide6.QtCore import QObject, Slot, Signal
from repository.position_repository import PositionRepository
from repository.positionJ_repository import PositionJRepository
from model.position_model import PositionModel
from model.positionJ_model import PositionJModel
from services.robot_service import RobotService

_SERVICE = RobotService()

class PositionController(QObject):
    posesLoaded = Signal(list)
    currentPoseLoaded = Signal(dict)
    currentJointPoseLoaded = Signal(dict)

    def __init__(self):
        super().__init__()
        self.repo = PositionRepository()
        self.repoJ = PositionJRepository()
    
    @Slot()
    def get_current_pose(self): 
        position_model = _SERVICE.get_current_pose()
        if position_model:
            self.currentPoseLoaded.emit(position_model.as_dict())
    
    @Slot()
    def get_current_joint_pose(self): 
        position_model = _SERVICE.get_current_joint_pose()
        if position_model:
            self.currentJointPoseLoaded.emit(position_model.as_dict())

    @Slot(str, float, float, float, float, float, float)
    def move_j(self, name, x, y, z, rx, ry, rz): 
        points = PositionModel(
            id=None,
            name=name,
            x=x,
            y=y,
            z=z,
            rx=rx,
            ry=ry,
            rz=rz
        )

        _SERVICE.move(points)
    
    @Slot(str, float, float, float, float, float, float)
    def move_joints(self, name, j1, j2, j3, j4, j5, j6): 
        points = PositionJModel(
            id=None,
            name=name,
            j1=j1,
            j2=j2,
            j3=j3,
            j4=j4,
            j5=j5,
            j6=j6
        )

        _SERVICE.move_joints(points)

    @Slot()
    def load_poses(self):
        cartesian_poses = self.repo.get_all_poses()
        joint_poses = self.repoJ.get_all_poses()
        
        # Combina ambas as listas e adiciona um campo 'type' para identificar
        all_poses = []
        for pose in cartesian_poses:
            pose_dict = pose.as_dict()
            pose_dict['type'] = 'cartesian'
            all_poses.append(pose_dict)
        
        for pose in joint_poses:
            pose_dict = pose.as_dict()
            pose_dict['type'] = 'joint'
            all_poses.append(pose_dict)
        
        self.posesLoaded.emit(all_poses)

    @Slot()
    def delete_all_poses(self):
        self.repo.delete_all_poses()
        self.repoJ.delete_all_poses()
        self.load_poses()

    @Slot(str)
    def delete_pose(self, name):
        # Tenta deletar de ambos os repositórios (pode não existir em um deles)
        try:
            self.repo.delete_pose(name)
        except:
            pass
        try:
            self.repoJ.delete_pose(name)
        except:
            pass
        self.load_poses()
    
    @Slot(str, str)
    def delete_pose_by_type(self, name, pose_type):
        if pose_type == "joint":
            self.repoJ.delete_pose(name)
        else:
            self.repo.delete_pose(name)
        self.load_poses()

    @Slot(str, float, float, float, float, float, float)
    def save_pose(self, name, x, y, z, rx, ry, rz): 
        print(f"[POSITION_CONTROLLER] SALVAR - Tipo: CARTESIANO")
        print(f"[POSITION_CONTROLLER] Nome: {name}, X: {x}, Y: {y}, Z: {z}, RX: {rx}, RY: {ry}, RZ: {rz}")
        poses = self.repo.get_all_poses()  
        for p in poses:
            if p.name == name:
                print(f"[POSITION_CONTROLLER] AVISO: Posição '{name}' já existe (cartesiano), não será salva")
                return
            
        pose = PositionModel(
            id=None,
            name=name,
            x=x,
            y=y,
            z=z,
            rx=rx,
            ry=ry,
            rz=rz,
            created_at=None
        )
        self.repo.insert_pose(pose)
        print(f"[POSITION_CONTROLLER] Posição cartesiana '{name}' salva com sucesso")
        self.load_poses()
    
    @Slot(str, float, float, float, float, float, float)
    def save_joint_pose(self, name, j1, j2, j3, j4, j5, j6): 
        print(f"[POSITION_CONTROLLER] SALVAR - Tipo: JUNTAS")
        print(f"[POSITION_CONTROLLER] Nome: {name}, J1: {j1}, J2: {j2}, J3: {j3}, J4: {j4}, J5: {j5}, J6: {j6}")
        poses = self.repoJ.get_all_poses()  
        for p in poses:
            if p.name == name:
                print(f"[POSITION_CONTROLLER] AVISO: Posição '{name}' já existe (juntas), não será salva")
                return
            
        pose = PositionJModel(
            id=None,
            name=name,
            j1=j1,
            j2=j2,
            j3=j3,
            j4=j4,
            j5=j5,
            j6=j6,
            created_at=None
        )
        self.repoJ.insert_pose(pose)
        print(f"[POSITION_CONTROLLER] Posição de juntas '{name}' salva com sucesso")
        self.load_poses()

    @Slot( str, str, float, float, float, float, float, float)
    def update_pose(self,actualName, name, x, y, z, rx, ry, rz):
        print(f"[POSITION_CONTROLLER] ATUALIZAR - Tipo: CARTESIANO")
        print(f"[POSITION_CONTROLLER] Nome atual: {actualName}, Novo nome: {name}")
        print(f"[POSITION_CONTROLLER] Valores: X: {x}, Y: {y}, Z: {z}, RX: {rx}, RY: {ry}, RZ: {rz}")

        if actualName != name:
            poses = self.repo.get_all_poses()  
            for p in poses:
                if p.name == name:
                    print(f"[POSITION_CONTROLLER] AVISO: Nome '{name}' já existe (cartesiano), não será atualizado")
                    return
                
        pose = PositionModel(
            id=None,
            name=name,
            x=x, 
            y=y, 
            z=z,
            rx=rx, 
            ry=ry, 
            rz=rz
        )
        self.repo.update_pose(pose, actualName)
        print(f"[POSITION_CONTROLLER] Posição cartesiana '{actualName}' atualizada para '{name}' com sucesso")
        self.load_poses()
    
    @Slot( str, str, float, float, float, float, float, float)
    def update_joint_pose(self, actualName, name, j1, j2, j3, j4, j5, j6):
        print(f"[POSITION_CONTROLLER] ATUALIZAR - Tipo: JUNTAS")
        print(f"[POSITION_CONTROLLER] Nome atual: {actualName}, Novo nome: {name}")
        print(f"[POSITION_CONTROLLER] Valores: J1: {j1}, J2: {j2}, J3: {j3}, J4: {j4}, J5: {j5}, J6: {j6}")

        if actualName != name:
            poses = self.repoJ.get_all_poses()  
            for p in poses:
                if p.name == name:
                    print(f"[POSITION_CONTROLLER] AVISO: Nome '{name}' já existe (juntas), não será atualizado")
                    return
                
        pose = PositionJModel(
            id=None,
            name=name,
            j1=j1, 
            j2=j2, 
            j3=j3,
            j4=j4, 
            j5=j5, 
            j6=j6
        )
        self.repoJ.update_pose(pose, actualName)
        print(f"[POSITION_CONTROLLER] Posição de juntas '{actualName}' atualizada para '{name}' com sucesso")
        self.load_poses()

