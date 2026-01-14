from apscheduler.schedulers.background import BackgroundScheduler
from sqlalchemy.orm import Session
from .database import SessionLocal
from .models import PatientQueue
from datetime import datetime
import logging

# Configure Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def cleanup_queues():
    """
    Background job to clean up old queues.
    Runs daily to mark queues from previous days as 'Completed'.
    """
    logger.info("Running Daily Queue Cleanup...")
    db: Session = SessionLocal()
    try:
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Find active queues that are older than today
        old_queues = db.query(PatientQueue).filter(
            PatientQueue.status.in_(["Waiting", "In Consultation"]),
            PatientQueue.appointmentTime < today_start
        ).all()
        
        count = 0
        for q in old_queues:
            q.status = "Completed"
            count += 1
            
        if count > 0:
            db.commit()
            logger.info(f"Cleaned up {count} old queue entries.")
        else:
            logger.info("No old queues found to clean up.")
            
    except Exception as e:
        logger.error(f"Error during queue cleanup: {e}")
        db.rollback()
    finally:
        db.close()

# Initialize Scheduler
scheduler = BackgroundScheduler()

# Add Job: Run every day at 00:00 (Midnight)
scheduler.add_job(cleanup_queues, 'cron', hour=0, minute=0)

def start_scheduler():
    logger.info("Starting Background Scheduler...")
    try:
        scheduler.start()
    except Exception as e:
        logger.error(f"Failed to start scheduler: {e}")

def shutdown_scheduler():
    logger.info("Shutting down Background Scheduler...")
    try:
        scheduler.shutdown()
    except Exception as e:
        logger.error(f"Failed to shutdown scheduler: {e}")
