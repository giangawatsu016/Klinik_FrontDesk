from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta
from .. import models, schemas, database, auth_utils
from ..limiter import limiter

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

from sqlalchemy import func

@router.post("/login", response_model=schemas.Token)
@limiter.limit("60/minute")
async def login_for_access_token(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    # Case-insensitive username lookup
    user = db.query(models.User).filter(func.lower(models.User.username) == func.lower(form_data.username)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check Bypass Settings
    bypass_admin = db.query(models.AppConfig).filter(models.AppConfig.key == "bypass_login_admin").first()
    bypass_staff = db.query(models.AppConfig).filter(models.AppConfig.key == "bypass_login_staff").first()
    
    print(f"[DEBUG_LOGIN] User: {user.username}, Role: {user.role}")
    if bypass_admin: print(f"[DEBUG_LOGIN] Admin Bypass Config: {bypass_admin.value}")
    if bypass_staff: print(f"[DEBUG_LOGIN] Staff Bypass Config: {bypass_staff.value}")

    is_bypass = False
    
    # Helper to check if value is "true" (case-insensitive, string)
    def is_true(val):
        return str(val).lower() in ["true", "1", "yes"]

    user_role = user.role.lower()
    
    # Check Admin (handle "admin" or "administrator")
    if user_role in ["admin", "administrator"] and bypass_admin and is_true(bypass_admin.value):
        is_bypass = True
    # Check Staff (handle "staff")
    elif user_role == "staff" and bypass_staff and is_true(bypass_staff.value):
        is_bypass = True
    
    print(f"[DEBUG_LOGIN] Is Bypass Allowed: {is_bypass}")

    if not is_bypass:
        if not auth_utils.verify_password(form_data.password, user.password_hash):
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
    access_token_expires = timedelta(minutes=auth_utils.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth_utils.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    hashed_password = auth_utils.get_password_hash(user.password)
    new_user = models.User(
        username=user.username,
        password_hash=hashed_password,
        full_name=user.full_name,
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.get("/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(auth_utils.get_current_user)):
    return current_user
