from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Conexión a SQL Server usando Autenticación de Windows (Trusted_Connection=yes)
# Si tu servidor en SSMS tiene un nombre específico (ej: localhost\SQLEXPRESS), cámbialo en SERVER
SERVER = 'localhost'
DATABASE = 'nexus_energy_db'

DATABASE_URL = (
    f"mssql+pyodbc://@{SERVER}/{DATABASE}?"
    "driver=ODBC+Driver+17+for+SQL+Server&Trusted_Connection=yes"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()