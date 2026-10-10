from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


class Schema(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class Register(Schema):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    display_name: str = Field(default="", max_length=80)


class Login(Schema):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class EmailRequest(Schema):
    email: EmailStr


class TokenRequest(Schema):
    token: str = Field(min_length=20, max_length=200)


class Reset(TokenRequest):
    password: str = Field(min_length=12, max_length=128)


class ProfileUpdate(Schema):
    display_name: str = Field(max_length=80)
    alerts_enabled: bool
    retention_days: int = Field(ge=1, le=365)


class DeleteAccount(Schema):
    password: str = Field(min_length=1, max_length=128)


class ScanInput(Schema):
    allow_external_reputation: bool = False
    channel: Literal["sms", "email", "url", "voice", "call"]
    content: str = Field(min_length=1, max_length=20000)
    sender: EmailStr | None = None
    reply_to: EmailStr | None = None
    subject: str = Field(default="", max_length=300)
    attachment_names: list[str] = Field(default_factory=list, max_length=20)
    phone_number: str = Field(default="", max_length=32)

    @field_validator("content")
    @classmethod
    def not_blank(cls, value):
        if not value.strip():
            raise ValueError("Content must not be blank")
        return value

    @field_validator("attachment_names")
    @classmethod
    def filenames(cls, values):
        if any(len(v) > 200 for v in values):
            raise ValueError("Attachment name too long")
        return values


class FeedbackInput(Schema):
    verdict: Literal["correct", "false_positive", "missed_scam", "uncertain"]
    comment: str = Field(default="", max_length=1000)


class ReportInput(Schema):
    scan_id: str = Field(min_length=36, max_length=36)
    category: Literal["credentials", "payment", "impersonation", "investment", "other"]
    comment: str = Field(default="", max_length=1000)


class Moderation(Schema):
    status: Literal["reviewed", "dismissed", "escalated"]


class EvidenceResult(Schema):
    code: str
    title: str
    points: int = Field(ge=0, le=100)
    evidence: str


class ScanResult(Schema):
    id: str
    channel: Literal["sms", "email", "url", "voice", "call"]
    created_at: float
    score: int = Field(ge=0, le=100)
    risk_level: Literal["Safe", "Suspicious", "High Risk"]
    summary: str
    recommendations: list[str]
    score_explanation: str
    indicators: list[EvidenceResult]
    rule_version: str
    model_version: str | None = None
    model_signal: float | None = Field(default=None, ge=0, le=1)
    reputation: dict
    limitations: list[str]
    transcript: str | None = None
