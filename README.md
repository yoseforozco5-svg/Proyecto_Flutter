# Hak n You

## Instalación paso a paso
### 1. Clonar el repositorio

Abre una terminal y ejecuta:

```bash
git clone URL_DEL_REPOSITORIO
```

Accede a la carpeta del proyecto:

```bash
cd Proyecto_Flutter
```

### 2. Configurar la base de datos

1. Abre XAMPP Control Panel.
2. Inicia los servicios Apache y MySQL.
3. Accede a phpMyAdmin desde `http://localhost/phpmyadmin/`.
4. Crea la base de datos que utiliza el proyecto.
5. Selecciona la base de datos e importa el archivo `.sql` ubicado en la carpeta `database/`.

Verifica que las tablas se hayan creado correctamente.

### 3. Configurar el backend (FastAPI)

Abre una terminal y accede a la carpeta del backend:

```bash
cd backend_API
```

Crea un entorno virtual:

```bash
python -m venv .venv
```

Activa el entorno virtual en Windows:

```powershell
.venv\Scripts\activate
```

Instala las dependencias:

```bash
pip install -r requirements.txt
```

Configura la conexión a la base de datos en el archivo correspondiente (`database.py`).

Inicia el servidor:

```bash
uvicorn main:app --reload
```

La API estará disponible en:

```text
http://127.0.0.1:8000
```

La documentación de los endpoints se puede consultar en:

```text
http://127.0.0.1:8000/docs
```

### 4. Configurar el frontend (Flutter)

Abre otra terminal y accede a la carpeta del frontend:

```bash
cd frontend
```

Instala las dependencias:

```bash
flutter pub get
```

Verifica que la URL de conexión a FastAPI en los servicios de Flutter corresponda a la dirección del servidor.

Ejecuta la aplicación:

```bash
flutter run
```

## Uso de la aplicación

1. Inicia los servicios de XAMPP.
2. Ejecuta el backend de FastAPI.
3. Inicia la aplicación Flutter.
4. Registra una cuenta o inicia sesión.
5. Explora las publicaciones disponibles.
6. Selecciona una publicación para consultar su contenido.
7. Registra o modifica tu valoración mediante las estrellas.
8. Accede al mapa desde el botón correspondiente.
9. Si ingresas como administrador, podrás acceder a las opciones administrativas disponibles.

Credenciales de usuario comun:
correo: irving@gmail
contraseña: 12345678

Credenciales de administrador:
correo: admin@gmail
contraseña: admin12345
