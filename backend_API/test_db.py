from database import engine

try:
    with engine.connect() as connection:
        print(" Connect: La conexión a la base de datos fue exitosa.")
except Exception as e:
    print(" Error de conexión:")
    print(e)