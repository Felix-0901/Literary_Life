"""initial schema

Revision ID: 20260313_0001
Revises:
Create Date: 2026-03-13 12:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260313_0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "quotes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("content", sa.String(length=1000), nullable=False),
        sa.Column("author", sa.String(length=100), nullable=False, server_default="佚名"),
        sa.Column("source", sa.String(length=200), nullable=False, server_default=""),
        sa.Column("category", sa.String(length=50), nullable=False, server_default="文學"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_quotes_id", "quotes", ["id"])

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("nickname", sa.String(length=50), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("user_code", sa.String(length=6), nullable=False),
        sa.Column("bio", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_users_id", "users", ["id"])
    op.create_index("ix_users_email", "users", ["email"], unique=True)
    op.create_index("ix_users_user_code", "users", ["user_code"], unique=True)

    op.create_table(
        "writing_cycles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("cycle_type", sa.Integer(), nullable=False, server_default="7"),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_writing_cycles_id", "writing_cycles", ["id"])
    op.create_index("ix_writing_cycles_user_id", "writing_cycles", ["user_id"])

    op.create_table(
        "inspiration_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("cycle_id", sa.Integer(), sa.ForeignKey("writing_cycles.id"), nullable=True),
        sa.Column("event_time", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.Column("location", sa.String(length=200), nullable=False, server_default=""),
        sa.Column("object_or_event", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("detail_text", sa.Text(), nullable=False, server_default=""),
        sa.Column("feeling", sa.String(length=200), nullable=False, server_default=""),
        sa.Column("keywords", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_inspiration_logs_id", "inspiration_logs", ["id"])
    op.create_index("ix_inspiration_logs_user_id", "inspiration_logs", ["user_id"])
    op.create_index("ix_inspiration_logs_cycle_id", "inspiration_logs", ["cycle_id"])

    op.create_table(
        "literary_works",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("cycle_id", sa.Integer(), sa.ForeignKey("writing_cycles.id"), nullable=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("genre", sa.String(length=50), nullable=False, server_default="散文"),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("visibility", sa.String(length=20), nullable=False, server_default="private"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_literary_works_id", "literary_works", ["id"])
    op.create_index("ix_literary_works_user_id", "literary_works", ["user_id"])
    op.create_index("ix_literary_works_cycle_id", "literary_works", ["cycle_id"])

    op.create_table(
        "friends",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("requester_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("addressee_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_friends_id", "friends", ["id"])
    op.create_index("ix_friends_requester_id", "friends", ["requester_id"])
    op.create_index("ix_friends_addressee_id", "friends", ["addressee_id"])

    op.create_table(
        "groups",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("invite_code", sa.String(length=10), nullable=False),
        sa.Column("owner_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_groups_id", "groups", ["id"])
    op.create_index("ix_groups_owner_id", "groups", ["owner_id"])
    op.create_index("ix_groups_invite_code", "groups", ["invite_code"], unique=True)

    op.create_table(
        "group_members",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("group_id", sa.Integer(), sa.ForeignKey("groups.id"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("role", sa.String(length=20), nullable=False, server_default="member"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_group_members_id", "group_members", ["id"])
    op.create_index("ix_group_members_group_id", "group_members", ["group_id"])
    op.create_index("ix_group_members_user_id", "group_members", ["user_id"])

    op.create_table(
        "work_shares",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("work_id", sa.Integer(), sa.ForeignKey("literary_works.id"), nullable=False),
        sa.Column("target_type", sa.String(length=20), nullable=False),
        sa.Column("target_id", sa.Integer(), nullable=True),
        sa.Column("message", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_work_shares_id", "work_shares", ["id"])
    op.create_index("ix_work_shares_work_id", "work_shares", ["work_id"])

    op.create_table(
        "responses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("work_id", sa.Integer(), sa.ForeignKey("literary_works.id"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_responses_id", "responses", ["id"])
    op.create_index("ix_responses_work_id", "responses", ["work_id"])
    op.create_index("ix_responses_user_id", "responses", ["user_id"])

    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("type", sa.String(length=50), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.String(length=500), nullable=False, server_default=""),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
    )
    op.create_index("ix_notifications_id", "notifications", ["id"])
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_notifications_user_id", table_name="notifications")
    op.drop_index("ix_notifications_id", table_name="notifications")
    op.drop_table("notifications")

    op.drop_index("ix_responses_user_id", table_name="responses")
    op.drop_index("ix_responses_work_id", table_name="responses")
    op.drop_index("ix_responses_id", table_name="responses")
    op.drop_table("responses")

    op.drop_index("ix_work_shares_work_id", table_name="work_shares")
    op.drop_index("ix_work_shares_id", table_name="work_shares")
    op.drop_table("work_shares")

    op.drop_index("ix_group_members_user_id", table_name="group_members")
    op.drop_index("ix_group_members_group_id", table_name="group_members")
    op.drop_index("ix_group_members_id", table_name="group_members")
    op.drop_table("group_members")

    op.drop_index("ix_groups_invite_code", table_name="groups")
    op.drop_index("ix_groups_owner_id", table_name="groups")
    op.drop_index("ix_groups_id", table_name="groups")
    op.drop_table("groups")

    op.drop_index("ix_friends_addressee_id", table_name="friends")
    op.drop_index("ix_friends_requester_id", table_name="friends")
    op.drop_index("ix_friends_id", table_name="friends")
    op.drop_table("friends")

    op.drop_index("ix_literary_works_cycle_id", table_name="literary_works")
    op.drop_index("ix_literary_works_user_id", table_name="literary_works")
    op.drop_index("ix_literary_works_id", table_name="literary_works")
    op.drop_table("literary_works")

    op.drop_index("ix_inspiration_logs_cycle_id", table_name="inspiration_logs")
    op.drop_index("ix_inspiration_logs_user_id", table_name="inspiration_logs")
    op.drop_index("ix_inspiration_logs_id", table_name="inspiration_logs")
    op.drop_table("inspiration_logs")

    op.drop_index("ix_writing_cycles_user_id", table_name="writing_cycles")
    op.drop_index("ix_writing_cycles_id", table_name="writing_cycles")
    op.drop_table("writing_cycles")

    op.drop_index("ix_users_user_code", table_name="users")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_id", table_name="users")
    op.drop_table("users")

    op.drop_index("ix_quotes_id", table_name="quotes")
    op.drop_table("quotes")
