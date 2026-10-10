import ipaddress
import re
import unicodedata
from urllib.parse import unquote, urlsplit, urlunsplit

RULE_VERSION = "rules-1.0"


def normalize(text):
    return " ".join(unicodedata.normalize("NFKC", text).split())


def evidence(code, title, points, detail):
    return {"code": code, "title": title, "points": points, "evidence": detail}


def parse_url(value):
    if len(value) > 4096 or any(c.isspace() or ord(c) < 32 for c in value):
        raise ValueError("URL contains whitespace, control characters or is too long")
    parts = urlsplit(value)
    if parts.scheme.lower() not in {"http", "https"} or not parts.hostname:
        raise ValueError("Enter a complete http:// or https:// URL")
    if "\\" in value or "%" in parts.hostname:
        raise ValueError("Ambiguous URL host")
    try:
        host = parts.hostname.encode("idna").decode("ascii").lower().rstrip(".")
        port = parts.port
        try:
            ipaddress.ip_address(host)
        except ValueError:
            if len(host) > 253 or not re.fullmatch(r"[a-z0-9.-]+", host):
                raise ValueError("Invalid hostname") from None
            if any(
                not label or len(label) > 63 or label.startswith("-") or label.endswith("-")
                for label in host.split(".")
            ):
                raise ValueError("Invalid hostname") from None
    except (UnicodeError, ValueError) as exc:
        raise ValueError("Invalid hostname or port") from exc
    netloc = f"[{host}]" if ":" in host else host
    if port:
        netloc += f":{port}"
    clean = urlunsplit((parts.scheme.lower(), netloc, parts.path or "/", parts.query, ""))
    return parts, host, clean


def url_indicators(value):
    parts, host, clean = parse_url(value)
    items = []

    def add(c, t, p, d):
        items.append(evidence(c, t, p, d))

    if parts.username is not None:
        add(
            "url_credentials",
            "Misleading user information in URL",
            35,
            "User information appears before the actual destination hostname.",
        )
    try:
        address = ipaddress.ip_address(host)
        add("url_ip", "Numeric destination", 20, "Destination is an IP address, not a domain.")
        if not address.is_global:
            add(
                "url_private",
                "Internal network address",
                65,
                "Destination is private, loopback, reserved or link-local. It was not fetched.",
            )
    except ValueError:
        if host == "localhost" or host.endswith((".localhost", ".local", ".internal")):
            add("url_private", "Internal destination", 65, "Local hostname; not fetched.")
    if "xn--" in host:
        add(
            "url_idn",
            "Internationalized domain",
            15,
            "Punycode hostname requires visual verification; it may be legitimate.",
        )
    if host.count(".") >= 4:
        add(
            "url_subdomains",
            "Many hostname segments",
            10,
            "Multiple subdomains can conceal the actual registrable domain.",
        )
    if parts.scheme == "http":
        add("url_http", "Unencrypted link", 10, "HTTP does not encrypt transport.")
    if len(value) > 180 or len(re.findall(r"%[0-9a-fA-F]{2}", value)) > 8:
        add(
            "url_obscured",
            "Complex or heavily encoded URL",
            10,
            "URL length or encoding makes inspection difficult.",
        )
    path = unquote(parts.path + "?" + parts.query).lower()
    if re.search(r"(?:https?://|redirect=|returnurl=|next=https)", path):
        add(
            "url_redirect",
            "Embedded destination",
            15,
            "An embedded URL or redirect parameter is present; no redirects were followed.",
        )
    if re.search(r"(?:verify|login|password|wallet|account)", path) and (
        "xn--" in host or host.count("-") >= 2 or host.count(".") >= 4
    ):
        add(
            "url_sensitive",
            "Sensitive action with unusual hostname",
            25,
            "Sensitive path appears together with an unusual destination structure.",
        )
    return items, clean


def text_indicators(text):
    text = normalize(text).lower()
    items = []

    def add(c, t, p, d):
        items.append(evidence(c, t, p, d))

    # Match requests, not words alone. Exclude common protective instructions.
    segments = re.split(r"[.!?;\n]+", text)
    actionable = " ".join(
        s
        for s in segments
        if not re.search(r"\b(never|do not|don't|won't|will not|should not|avoid)\b", s)
    )
    if re.search(
        r"\b(?:share|send|tell|provide|give|enter|confirm|reply).{0,60}"
        r"\b(?:otp|one.time (?:password|code)|verification code|password|pin|cvv)\b",
        actionable,
    ):
        add(
            "credential_request",
            "Request for confidential credentials",
            50,
            "A request verb is associated with an OTP, password, PIN or security code.",
        )
    payment = bool(
        re.search(
            r"\b(?:pay|send money|transfer|deposit|payment|wire|buy gift cards)\b", actionable
        )
    )
    pressure = bool(
        re.search(
            r"\b(?:urgent|immediately|within \d+|final warning|"
            r"suspend|blocked|arrest|last chance|act now)\b",
            actionable,
        )
    )
    reward = bool(
        re.search(
            r"\b(?:prize|lottery|guaranteed return|risk.free|refund|"
            r"registration fee|processing fee|job offer)\b",
            actionable,
        )
    )
    if payment and (pressure or reward):
        add(
            "coercive_payment",
            "Payment request with pressure or promised reward",
            40,
            "Payment language occurs together with urgency or a reward/fee claim.",
        )
    if pressure and (items or re.search(r"https?://|\b(?:bank|police|government)\b", actionable)):
        add(
            "pressure",
            "Urgency paired with a sensitive action",
            25,
            "Pressure language occurs with a sensitive request or claimed authority.",
        )
    if re.search(
        r"\b(?:install|download|open).{0,50}\b(?:anydesk|teamviewer|"
        r"remote access|screen sharing)\b",
        actionable,
    ):
        add(
            "remote_access",
            "Remote access installation request",
            55,
            "A request to install or open a remote access application is present.",
        )
    if reward and re.search(r"\b(?:guaranteed|risk.free|double your|won|winner)\b", actionable):
        add(
            "reward_claim",
            "Unverifiable reward or investment claim",
            25,
            "Reward language appears with a guaranteed-return or winner claim.",
        )
    for value in re.findall(r"https?://[^\s<>\"']+", text)[:20]:
        try:
            signals, _ = url_indicators(value.rstrip(".,;!?)"))
            items.extend(signals)
        except ValueError:
            add("malformed_link", "Malformed link", 10, "A link could not be safely parsed.")
    return items


def email_indicators(sender, reply_to, attachments):
    items = []
    if (
        sender
        and reply_to
        and sender.rsplit("@", 1)[1].lower() != reply_to.rsplit("@", 1)[1].lower()
    ):
        items.append(
            evidence(
                "reply_mismatch",
                "Different reply-to domain",
                20,
                "Sender and reply-to domains differ; legitimate services may do this.",
            )
        )
    if any(
        re.search(r"\.(exe|scr|js|vbs|bat|cmd|ps1|msi|hta|docm|xlsm)$", name.lower())
        for name in attachments
    ):
        items.append(
            evidence(
                "risky_attachment",
                "Executable or macro-capable attachment",
                30,
                "Attachment filename suggests executable content; nothing was opened.",
            )
        )
    return items
