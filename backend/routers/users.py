from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..services.frappe_service import frappe_client
from .. import models, schemas, database, auth_utils

router = APIRouter(
    prefix="/users",
    tags=["users"]
)

# Role Constants
ROLE_SUPER_ADMIN = "Super Admin"
ROLE_ADMIN = "Administrator"
ROLE_STAFF = "Staff"

def get_current_active_user(current_user: models.User = Depends(auth_utils.get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

def check_permission(actor: models.User, target_role: str, action: str):
    """
    Enforce the logic:
    Super Admin: Can manage Admin and Staff.
    Administrator: Can manage Staff.
    Staff: Cannot manage anyone.
    """
    if actor.role == ROLE_SUPER_ADMIN:
        if target_role == ROLE_SUPER_ADMIN and action != "read":
             return True
        return True
    
    if actor.role == ROLE_ADMIN:
        if target_role == ROLE_ADMIN or target_role == ROLE_SUPER_ADMIN:
            return False
        if target_role == ROLE_STAFF:
            return True
        return False
        
    if actor.role == ROLE_STAFF:
        return False
        
    return False

@router.get("/", response_model=List[schemas.User])
def read_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    if current_user.role not in [ROLE_SUPER_ADMIN, ROLE_ADMIN]:
         raise HTTPException(status_code=403, detail="Not authorized to view users")
    
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=schemas.User)
def create_user(
    user: schemas.UserCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    # Permission Check
    if not check_permission(current_user, user.role, "create"):
        raise HTTPException(status_code=403, detail="Not authorized to create this role")

    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # Check Email Uniqueness if provided
    if user.email:
         exist_email = db.query(models.User).filter(models.User.email == user.email).first()
         if exist_email:
             raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = auth_utils.get_password_hash(user.password)
    new_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        full_name=user.full_name,
        role=user.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Sync to ERPNext
    if user.email:
        # Split name
        parts = user.full_name.split(" ", 1)
        first_name = parts[0]
        last_name = parts[1] if len(parts) > 1 else ""
        
        # Background task or direct? Direct for feedback.
        frappe_client.create_user(user.email, first_name, last_name, user.role)
        
    return new_user

@router.put("/{user_id}", response_model=schemas.User)
def update_user(
    user_id: int,
    user_update: schemas.UserUpdate, # Changed from UserCreate
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    target_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Permission Check
    if not check_permission(current_user, target_user.role, "update"):
        raise HTTPException(status_code=403, detail="Not authorized to update this user")

    # Additional Check: Administrator cannot update Admin/Super Admin
    if current_user.role == ROLE_ADMIN and target_user.role in [ROLE_SUPER_ADMIN, ROLE_ADMIN]:
         raise HTTPException(status_code=403, detail="Administrator cannot edit Admin/Super Admin")
    
    # Update Fields
    # Only update username if allowed
    if user_update.username is not None and user_update.username != target_user.username:
        # Check uniqueness
        exist = db.query(models.User).filter(models.User.username == user_update.username).first()
        if exist:
             raise HTTPException(status_code=400, detail="Username already taken")
        target_user.username = user_update.username
    
    # Update Email
    old_email = target_user.email
    if user_update.email is not None and user_update.email != target_user.email:
         exist_email = db.query(models.User).filter(models.User.email == user_update.email).first()
         if exist_email:
             raise HTTPException(status_code=400, detail="Email already taken")
         target_user.email = user_update.email

    if user_update.full_name:
        target_user.full_name = user_update.full_name
    
    if user_update.role:
        target_user.role = user_update.role
    
    # If password provided
    if user_update.password:
        target_user.password_hash = auth_utils.get_password_hash(user_update.password)
        
    db.commit()
    db.refresh(target_user)

    # Sync to ERPNext (Update)
    # If email changed, we technically "Rename" in ERPNext? 
    # Or just update the *other* fields for the *current* email?
    # ERPNext User name = email. Rename is complex.
    # For now, we only sync Non-Email updates to the `target_user.email`.
    # If email changed, we might lose sync or need to recreate.
    # Assumption: Email doesn't change often.
    
    if target_user.email:
        data = {}
        if user_update.full_name:
             parts = user_update.full_name.split(" ", 1)
             data["first_name"] = parts[0]
             if len(parts) > 1: data["last_name"] = parts[1]
             
        if data:
             frappe_client.update_erp_user(target_user.email, data)
             
    return target_user

@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_active_user)
):
    target_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Permission Check
    if not check_permission(current_user, target_user.role, "delete"):
         raise HTTPException(status_code=403, detail="Not authorized to delete this user")
    
    email_to_delete = target_user.email     
    db.delete(target_user)
    db.commit()
    
    # Sync delete
    if email_to_delete:
         frappe_client.delete_erp_user(email_to_delete)
         
    return {"message": "User deleted successfully"}
