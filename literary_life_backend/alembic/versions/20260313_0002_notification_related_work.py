"""add related work id to notifications

Revision ID: 20260313_0002
Revises: 20260313_0001
Create Date: 2026-03-13 13:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260313_0002"
down_revision = "20260313_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "notifications",
        sa.Column("related_work_id", sa.Integer(), nullable=True),
    )
    op.create_foreign_key(
        "fk_notifications_related_work_id_literary_works",
        "notifications",
        "literary_works",
        ["related_work_id"],
        ["id"],
    )
    op.create_index(
        "ix_notifications_related_work_id",
        "notifications",
        ["related_work_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_notifications_related_work_id", table_name="notifications")
    op.drop_constraint(
        "fk_notifications_related_work_id_literary_works",
        "notifications",
        type_="foreignkey",
    )
    op.drop_column("notifications", "related_work_id")
