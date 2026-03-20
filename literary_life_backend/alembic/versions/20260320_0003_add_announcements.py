"""add announcements table

Revision ID: 20260320_0003
Revises: 20260313_0002
Create Date: 2026-03-20 00:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260320_0003"
down_revision = "20260313_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "announcements",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False, server_default=""),
        sa.Column("content", sa.Text(), nullable=False, server_default=""),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
    )
    op.create_index("ix_announcements_id", "announcements", ["id"])
    op.create_index("ix_announcements_is_active", "announcements", ["is_active"])
    op.create_index("ix_announcements_starts_at", "announcements", ["starts_at"])
    op.create_index("ix_announcements_ends_at", "announcements", ["ends_at"])
    op.create_index("ix_announcements_updated_at", "announcements", ["updated_at"])


def downgrade() -> None:
    op.drop_index("ix_announcements_updated_at", table_name="announcements")
    op.drop_index("ix_announcements_ends_at", table_name="announcements")
    op.drop_index("ix_announcements_starts_at", table_name="announcements")
    op.drop_index("ix_announcements_is_active", table_name="announcements")
    op.drop_index("ix_announcements_id", table_name="announcements")
    op.drop_table("announcements")

