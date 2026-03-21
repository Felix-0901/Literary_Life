"""add maintenance configs table

Revision ID: 20260321_0004
Revises: 20260320_0003
Create Date: 2026-03-21 00:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260321_0004"
down_revision = "20260320_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "maintenance_configs",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("message", sa.Text(), nullable=False, server_default=""),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_maintenance_configs_id", "maintenance_configs", ["id"])
    op.create_index("ix_maintenance_configs_is_active", "maintenance_configs", ["is_active"])
    op.create_index("ix_maintenance_configs_starts_at", "maintenance_configs", ["starts_at"])
    op.create_index("ix_maintenance_configs_ends_at", "maintenance_configs", ["ends_at"])
    op.create_index("ix_maintenance_configs_updated_at", "maintenance_configs", ["updated_at"])


def downgrade() -> None:
    op.drop_index("ix_maintenance_configs_updated_at", table_name="maintenance_configs")
    op.drop_index("ix_maintenance_configs_ends_at", table_name="maintenance_configs")
    op.drop_index("ix_maintenance_configs_starts_at", table_name="maintenance_configs")
    op.drop_index("ix_maintenance_configs_is_active", table_name="maintenance_configs")
    op.drop_index("ix_maintenance_configs_id", table_name="maintenance_configs")
    op.drop_table("maintenance_configs")

