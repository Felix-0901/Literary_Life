"""work metadata and inspiration links

Revision ID: 20260321_0005
Revises: 20260321_0004
Create Date: 2026-03-21 00:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260321_0005"
down_revision = "20260321_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "literary_works",
        sa.Column("completed_cycle_id", sa.Integer(), sa.ForeignKey("writing_cycles.id"), nullable=True),
    )
    op.add_column(
        "literary_works",
        sa.Column("hashtags", sa.String(length=1000), nullable=False, server_default=""),
    )
    op.create_index("ix_literary_works_completed_cycle_id", "literary_works", ["completed_cycle_id"])

    op.create_table(
        "work_inspiration_links",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column(
            "work_id",
            sa.Integer(),
            sa.ForeignKey("literary_works.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "inspiration_id",
            sa.Integer(),
            sa.ForeignKey("inspiration_logs.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.UniqueConstraint("work_id", "inspiration_id", name="uq_work_inspiration"),
    )
    op.create_index("ix_work_inspiration_links_id", "work_inspiration_links", ["id"])
    op.create_index("ix_work_inspiration_links_work_id", "work_inspiration_links", ["work_id"])
    op.create_index("ix_work_inspiration_links_inspiration_id", "work_inspiration_links", ["inspiration_id"])


def downgrade() -> None:
    op.drop_index("ix_work_inspiration_links_inspiration_id", table_name="work_inspiration_links")
    op.drop_index("ix_work_inspiration_links_work_id", table_name="work_inspiration_links")
    op.drop_index("ix_work_inspiration_links_id", table_name="work_inspiration_links")
    op.drop_table("work_inspiration_links")

    op.drop_index("ix_literary_works_completed_cycle_id", table_name="literary_works")
    op.drop_column("literary_works", "hashtags")
    op.drop_column("literary_works", "completed_cycle_id")
