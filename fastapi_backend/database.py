from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Use the full external URL from Render
DATABASE_URL = "postgresql://tasks_database_a73m_user:Vy1NQSFpOzjoqz7aeESPs7er4o0icuWy@dpg-d04ou3p5pdvs73aa2jqg-a.oregon-postgres.render.com/tasks_database_a73m"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
