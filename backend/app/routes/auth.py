from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app import crud
from app.database import get_db
from app.schemas import (
    LoginRequest,
    LoginResponse,
    RegisterRequest,
    UserResponse,
)


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/auth",
    tags=["Autenticación"],
)


# ============================================================
# PASSWORD HASHING
# ============================================================

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

def hash_password(
    password: str,
) -> str:
    """
    Convierte una contraseña normal en un hash.
    """

    return pwd_context.hash(
        password,
    )


def verify_password(
    plain_password: str,
    password_hash: str,
) -> bool:
    """
    Verifica una contraseña contra su hash.
    """

    return pwd_context.verify(
        plain_password,
        password_hash,
    )


# ============================================================
# REGISTRO
# ============================================================

@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    request: RegisterRequest,
    db: Session = Depends(get_db),
):
    """
    Registra un nuevo usuario.
    """

    email = request.email.strip().lower()

    existing_user = crud.get_user_by_email(
        db,
        email,
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El correo electrónico ya está registrado.",
        )

    password_hash = hash_password(
        request.password,
    )

    user = crud.create_user(
        db,
        nombre=request.nombre.strip(),
        email=email,
        password_hash=password_hash,
    )

    return user


# ============================================================
# LOGIN
# ============================================================

@router.post(
    "/login",
    response_model=LoginResponse,
)
def login(
    request: LoginRequest,
    db: Session = Depends(get_db),
):
    """
    Autentica un usuario.
    """

    email = request.email.strip().lower()

    user = crud.get_user_by_email(
        db,
        email,
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos.",
        )

    password_valid = verify_password(
        request.password,
        user.password_hash,
    )

    if not password_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos.",
        )

    return {
        "message": "Inicio de sesión exitoso.",
        "user": user,
    }


# ============================================================
# OBTENER USUARIO POR ID
# ============================================================

@router.get(
    "/users/{user_id}",
    response_model=UserResponse,
)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
):
    """
    Obtiene un usuario por ID.

    Esta ruta es principalmente útil durante el desarrollo
    y las pruebas del prototipo.
    """

    user = crud.get_user_by_id(
        db,
        user_id,
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado.",
        )

    return user