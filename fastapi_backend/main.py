from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List
from pydantic import BaseModel
from sqlalchemy import Column, Integer, DateTime, Float

from database import SessionLocal, engine, Base

app = FastAPI()

# SQLAlchemy models
class MotionEvent(Base):
    __tablename__ = "motion_events"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, index=True)

class EnvironmentData(Base):
    __tablename__ = "environment_data"
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, index=True)
    temperature = Column(Float)
    humidity = Column(Float)

# Pydantic schemas
class MotionEventSchema(BaseModel):
    id: int
    timestamp: datetime

    class Config:
        orm_mode = True

class MotionEventCreate(BaseModel):
    timestamp: datetime

    class Config:
        orm_mode = True

class EnvironmentDataSchema(BaseModel):
    id: int
    timestamp: datetime
    temperature: float
    humidity: float

    class Config:
        orm_mode = True

class EnvironmentDataCreate(BaseModel):
    timestamp: datetime
    temperature: float
    humidity: float

    class Config:
        orm_mode = True

# Create tables
Base.metadata.create_all(bind=engine)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/db-check")
def db_check(db: Session = Depends(get_db)):
    try:
        db.execute("SELECT 1")
        return {"status": "Connected to PostgreSQL!"}
    except Exception as e:
        return {"error": str(e)}

# Motion Events Endpoints
@app.get("/motion-events", response_model=List[MotionEventSchema])
def get_motion_events(db: Session = Depends(get_db)):
    events = db.query(MotionEvent).all()
    return events

@app.post("/motion-events", response_model=MotionEventSchema)
def add_motion_event(event: MotionEventCreate, db: Session = Depends(get_db)):
    db_event = MotionEvent(timestamp=event.timestamp)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event

@app.delete("/motion-events/{event_id}", status_code=204)
def delete_motion_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(MotionEvent).filter(MotionEvent.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Motion event not found")
    db.delete(event)
    db.commit()
    return

# Environment Data Endpoints
@app.get("/environment-data", response_model=List[EnvironmentDataSchema])
def get_environment_data(db: Session = Depends(get_db)):
    data = db.query(EnvironmentData).order_by(EnvironmentData.timestamp.desc()).limit(100).all()
    return data

@app.post("/environment-data", response_model=EnvironmentDataSchema)
def add_environment_data(data: EnvironmentDataCreate, db: Session = Depends(get_db)):
    db_data = EnvironmentData(
        timestamp=data.timestamp,
        temperature=data.temperature,
        humidity=data.humidity
    )
    db.add(db_data)
    db.commit()
    db.refresh(db_data)
    return db_data

@app.get("/environment-data/latest", response_model=EnvironmentDataSchema)
def get_latest_environment_data(db: Session = Depends(get_db)):
    data = db.query(EnvironmentData).order_by(EnvironmentData.timestamp.desc()).first()
    if not data:
        raise HTTPException(status_code=404, detail="No environment data found")
    return data