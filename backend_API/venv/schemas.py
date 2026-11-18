from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=128)
    dir_usr: str 
    tip_usu: int = 1


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str 
    tip_usu: int

    model_config = ConfigDict(from_attributes=True)


class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    desc: str 
    img: str 
    tags: str 

    model_config = ConfigDict(from_attributes=True)


class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1)
    usr_id: int
    blog_id: int


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int

    model_config = ConfigDict(from_attributes=True)