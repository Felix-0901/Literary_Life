"""add work_type to literary_works

Revision ID: 20260422_0006
Revises: 20260321_0005
Create Date: 2026-04-22 00:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260422_0006"
down_revision = "20260321_0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "literary_works",
        sa.Column(
            "work_type",
            sa.String(length=20),
            nullable=False,
            server_default="literary",
        ),
    )
    op.create_index(
        "ix_literary_works_work_type",
        "literary_works",
        ["work_type"],
    )


def downgrade() -> None:
    op.drop_index("ix_literary_works_work_type", table_name="literary_works")
    op.drop_column("literary_works", "work_type")
