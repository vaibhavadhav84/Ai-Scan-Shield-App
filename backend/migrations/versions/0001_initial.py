"""Initial user-owned metadata schema. Schema frozen in this revision."""

import sqlalchemy as sa
from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("email", sa.String(254), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(512), nullable=False),
        sa.Column("display_name", sa.String(80), nullable=False),
        sa.Column("verified", sa.Boolean, nullable=False),
        sa.Column("admin", sa.Boolean, nullable=False),
        sa.Column("alerts_enabled", sa.Boolean, nullable=False),
        sa.Column("retention_days", sa.Integer, nullable=False),
        sa.Column("created_at", sa.Float, nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_table(
        "sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("access_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("refresh_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("access_expires", sa.Float, nullable=False),
        sa.Column("refresh_expires", sa.Float, nullable=False),
        sa.Column("created_at", sa.Float, nullable=False),
    )
    for field in ["user_id", "access_hash", "refresh_hash"]:
        op.create_index(f"ix_sessions_{field}", "sessions", [field])
    op.create_table(
        "action_tokens",
        sa.Column("token_hash", sa.String(64), primary_key=True),
        sa.Column(
            "user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("purpose", sa.String(20), nullable=False),
        sa.Column("expires_at", sa.Float, nullable=False),
    )
    op.create_index("ix_action_tokens_user_id", "action_tokens", ["user_id"])
    op.create_table(
        "scans",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id", sa.String(36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("channel", sa.String(12), nullable=False),
        sa.Column("score", sa.Integer, nullable=False),
        sa.Column("risk_level", sa.String(16), nullable=False),
        sa.Column("result", sa.JSON, nullable=False),
        sa.Column("created_at", sa.Float, nullable=False),
    )
    for field in ["user_id", "channel", "risk_level", "created_at"]:
        op.create_index(f"ix_scans_{field}", "scans", [field])
    for table, columns in {
        "feedback": [
            sa.Column("verdict", sa.String(24), nullable=False),
            sa.Column("comment", sa.String(1000), nullable=False),
        ],
        "reports": [
            sa.Column("category", sa.String(30), nullable=False),
            sa.Column("comment", sa.String(1000), nullable=False),
            sa.Column("status", sa.String(20), nullable=False),
            sa.Column("created_at", sa.Float, nullable=False),
        ],
        "alerts": [
            sa.Column("read", sa.Boolean, nullable=False),
            sa.Column("severity", sa.String(16), nullable=False),
            sa.Column("created_at", sa.Float, nullable=False),
        ],
    }.items():
        op.create_table(
            table,
            sa.Column("id", sa.String(36), primary_key=True),
            sa.Column(
                "user_id",
                sa.String(36),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "scan_id",
                sa.String(36),
                sa.ForeignKey("scans.id", ondelete="CASCADE"),
                nullable=False,
            ),
            *columns,
            sa.UniqueConstraint("scan_id")
            if table == "alerts"
            else sa.UniqueConstraint("scan_id", "user_id"),
        )
    op.create_index("ix_reports_user_id", "reports", ["user_id"])
    op.create_index("ix_alerts_user_id", "alerts", ["user_id"])
    op.create_table(
        "rate_buckets",
        sa.Column("key", sa.String(64), primary_key=True),
        sa.Column("window", sa.Integer, primary_key=True),
        sa.Column("count", sa.Integer, nullable=False),
    )
    op.create_table(
        "audit_events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("actor_id", sa.String(36)),
        sa.Column("action", sa.String(50), nullable=False),
        sa.Column("target_id", sa.String(36)),
        sa.Column("created_at", sa.Float, nullable=False),
    )


def downgrade():
    for table in [
        "audit_events",
        "rate_buckets",
        "alerts",
        "reports",
        "feedback",
        "scans",
        "action_tokens",
        "sessions",
        "users",
    ]:
        op.drop_table(table)
