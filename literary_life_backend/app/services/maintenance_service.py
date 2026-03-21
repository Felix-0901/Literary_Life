from datetime import datetime, timezone

from sqlalchemy import or_, desc
from sqlalchemy.orm import Session

from app.models.maintenance import MaintenanceConfig


def get_active_maintenance(db: Session) -> MaintenanceConfig | None:
    now = datetime.now(timezone.utc)
    return (
        db.query(MaintenanceConfig)
        .filter(MaintenanceConfig.is_active.is_(True))
        .filter(or_(MaintenanceConfig.starts_at.is_(None), MaintenanceConfig.starts_at <= now))
        .filter(or_(MaintenanceConfig.ends_at.is_(None), MaintenanceConfig.ends_at >= now))
        .order_by(desc(MaintenanceConfig.updated_at), desc(MaintenanceConfig.created_at))
        .first()
    )

