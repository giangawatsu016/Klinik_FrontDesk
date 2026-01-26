from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import models, schemas, database
import json

router = APIRouter(
    prefix="/config",
    tags=["Config"]
)

@router.get("/{key}", response_model=schemas.AppConfig)
def get_config(key: str, db: Session = Depends(database.get_db)):
    config = db.query(models.AppConfig).filter(models.AppConfig.key == key).first()
    if not config:
        # Default empty config if not found
        return schemas.AppConfig(key=key, value="[]")
    return config

@router.post("/", response_model=schemas.AppConfig)
def set_config(config: schemas.AppConfig, db: Session = Depends(database.get_db)):
    db_config = db.query(models.AppConfig).filter(models.AppConfig.key == config.key).first()
    if db_config:
        db_config.value = config.value
    else:
        db_config = models.AppConfig(key=config.key, value=config.value)
        db.add(db_config)
    
    db.commit()
    db.refresh(db_config)
    return db_config
