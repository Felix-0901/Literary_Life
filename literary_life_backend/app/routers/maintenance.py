from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.maintenance import MaintenanceStatusResponse
from app.services.maintenance_service import get_active_maintenance

router = APIRouter(prefix="/api/maintenance", tags=["維護"])


@router.get("/active", response_model=MaintenanceStatusResponse)
def get_maintenance_status(db: Session = Depends(get_db)):
    maintenance = get_active_maintenance(db)
    if not maintenance:
        return MaintenanceStatusResponse(is_active=False)
    return maintenance

