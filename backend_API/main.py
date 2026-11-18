from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from sqlalchemy.exc import IntegrityError
from pwdlib import PasswordHash
#from database import Base, engine, obtener_sesion
from database import obtener_sesion
from models import Usuario, Blog, Comentario, Valoracion
from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    UploadFile,
    File,
    Form,
)
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import shutil
import uuid
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    BlogCrear,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
    ValoracionCrear,
    ValoracionRespuesta,
    ValoracionResumen,
)

password_hash = PasswordHash.recommended()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(
    title="API de aplicación móvil",
    lifespan=lifespan,
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

@app.get("/")
def inicio():
    return {"mensaje": "API funcionando correctamente"}
# Permitir la comunicación con Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/login", response_model=UsuarioRespuesta)
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    usuario = db.scalar(
        select(Usuario).where(Usuario.mail == correo)
    )

    # Se utiliza el mismo mensaje para no revelar
    # si el correo está registrado.
    if usuario is None or not password_hash.verify(
        datos.password,
        usuario.pass_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    # Devuelve únicamente los datos públicos del usuario.
    return usuario

# Endpoints existentes:
# @app.get("/usuarios")
# @app.post("/usuarios")
# etc.

# USUARIOS

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Usuario).order_by(Usuario.id_usr)
    ).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
):
    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=datos.tip_usu,
    )

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario
@app.put(
    "/usuarios/{usuario_id}",
    response_model=UsuarioRespuesta,
)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr
    #usuario.tip_usu = datos.tip_usu

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    db.delete(usuario)
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}

# BLOG

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Blog).order_by(Blog.id_blog)
    ).all()


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    titulo: str = Form(...),
    descripcion: str = Form(...),
    imagen: UploadFile = File(...),
    db: Session = Depends(obtener_sesion),
):
    extension = Path(imagen.filename or "").suffix.lower()

    if extension not in [".jpg", ".jpeg", ".png", ".webp"]:
        await imagen.close()
        raise HTTPException(
            status_code=400,
            detail="Formato de imagen no permitido",
        )

    nombre_archivo = f"{uuid.uuid4().hex}{extension}"
    ruta_archivo = UPLOAD_DIR / nombre_archivo

    ruta_publica = f"/uploads/{nombre_archivo}"

    try:
        with ruta_archivo.open("wb") as destino:
            shutil.copyfileobj(imagen.file, destino)

        titulo_limpio = titulo.strip()
        descripcion_limpia = descripcion.strip()

        if not titulo_limpio or not descripcion_limpia:
            raise HTTPException(
                status_code=422,
                detail="El título y la descripción son obligatorios",
            )

        publicacion = Blog(
            titulo=titulo_limpio,
            descripcion=descripcion_limpia,
            img=ruta_publica,
            tags=None,
        )

        db.add(publicacion)
        db.commit()
        db.refresh(publicacion)

        return publicacion

    except Exception:
        db.rollback()

        if ruta_archivo.exists():
            ruta_archivo.unlink()

        raise

    finally:
        await imagen.close()

@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion
# COMENTARIOS

@app.get(
    "/comentarios",
    response_model=list[ComentarioRespuesta],
)
def listar_comentarios(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Comentario).order_by(Comentario.id_com)
    ).all()


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
):
    if not datos.comentario.strip():
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    if db.get(Usuario, datos.usr_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=datos.comentario.strip(),
        usr_id=datos.usr_id,
        blog_id=datos.blog_id,
        estatus=1,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo

# VALORACIONES

@app.post(
    "/valoraciones",
    response_model=ValoracionRespuesta,
)
def crear_valoracion(
    datos: ValoracionCrear,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, datos.id_usr)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    publicacion = db.get(Blog, datos.id_blog)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    valoracion = db.scalar(
        select(Valoracion).where(
            Valoracion.id_blog == datos.id_blog,
            Valoracion.id_usr == datos.id_usr,
        )
    )

    if valoracion is not None:
        valoracion.puntuacion = datos.puntuacion

    else:
        valoracion = Valoracion(
            id_blog=datos.id_blog,
            id_usr=datos.id_usr,
            puntuacion=datos.puntuacion,
        )

        db.add(valoracion)

    try:
        db.commit()
        db.refresh(valoracion)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="No se pudo registrar la valoración",
        )

    return valoracion

@app.get(
    "/blog/{blog_id}/valoraciones",
    response_model=ValoracionResumen,
)
def obtener_valoraciones(
    blog_id: int,
    id_usr: int | None = None,
    db: Session = Depends(obtener_sesion),
):
    
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    resultado = db.execute(
        select(
            func.avg(Valoracion.puntuacion),
            func.count(Valoracion.id_val),
        ).where(
            Valoracion.id_blog == blog_id
        )
    ).one()

    promedio, total = resultado

    mi_puntuacion = None

    if id_usr is not None:
        valoracion = db.scalar(
            select(Valoracion).where(
                Valoracion.id_blog == blog_id,
                Valoracion.id_usr == id_usr,
            )
        )

        if valoracion is not None:
            mi_puntuacion = valoracion.puntuacion

    return {
        "promedio": round(float(promedio), 2) if promedio is not None else 0,
        "total": total,
        "mi_puntuacion": mi_puntuacion,
    }
