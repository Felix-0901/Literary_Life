from __future__ import annotations

from app.models.notification import Notification
from app.services.ai_service import AIServiceError


def _register(client, email: str, nickname: str, password: str = "secret123") -> dict:
    response = client.post(
        "/api/auth/register",
        json={
            "nickname": nickname,
            "email": email,
            "password": password,
            "confirm_password": password,
        },
    )
    assert response.status_code == 201, response.text
    return response.json()


def _auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_auth_register_and_get_me(client):
    registered = _register(client, "alice@example.com", "Alice")

    me_response = client.get("/api/auth/me", headers=_auth_headers(registered["access_token"]))

    assert me_response.status_code == 200
    assert me_response.json()["email"] == "alice@example.com"


def test_private_work_is_blocked_until_published_and_responses_follow_visibility(client):
    author = _register(client, "author@example.com", "Author")
    viewer = _register(client, "viewer@example.com", "Viewer")

    work_response = client.post(
        "/api/works/",
        headers=_auth_headers(author["access_token"]),
        json={
            "title": "Only for me",
            "genre": "散文",
            "content": "secret content",
            "visibility": "private",
        },
    )
    assert work_response.status_code == 201
    work_id = work_response.json()["id"]

    denied_work = client.get(f"/api/works/{work_id}", headers=_auth_headers(viewer["access_token"]))
    denied_response = client.get(
        f"/api/responses/work/{work_id}",
        headers=_auth_headers(viewer["access_token"]),
    )

    assert denied_work.status_code == 403
    assert denied_response.status_code == 403

    publish_response = client.post(
        f"/api/works/{work_id}/publish",
        headers=_auth_headers(author["access_token"]),
    )
    assert publish_response.status_code == 200

    public_work = client.get(f"/api/works/{work_id}", headers=_auth_headers(viewer["access_token"]))
    response_create = client.post(
        "/api/responses/",
        headers=_auth_headers(viewer["access_token"]),
        json={"work_id": work_id, "content": "liked it"},
    )

    assert public_work.status_code == 200
    assert response_create.status_code == 201


def test_friend_and_group_shares_expand_targets_without_frontend_selection(client):
    alice = _register(client, "alice@example.com", "Alice")
    bob = _register(client, "bob@example.com", "Bob")

    request_response = client.post(
        "/api/friends/request",
        headers=_auth_headers(alice["access_token"]),
        json={"addressee_id": bob["user"]["id"]},
    )
    assert request_response.status_code == 201

    accept_response = client.put(
        f"/api/friends/{request_response.json()['id']}/accept",
        headers=_auth_headers(bob["access_token"]),
    )
    assert accept_response.status_code == 200

    work_response = client.post(
        "/api/works/",
        headers=_auth_headers(alice["access_token"]),
        json={
            "title": "Shared work",
            "genre": "散文",
            "content": "share me",
            "visibility": "private",
        },
    )
    assert work_response.status_code == 201
    work_id = work_response.json()["id"]

    friend_share = client.post(
        "/api/shares/",
        headers=_auth_headers(alice["access_token"]),
        json={"work_id": work_id, "target_type": "friend"},
    )
    assert friend_share.status_code == 201

    bob_shared_work = client.get(
        f"/api/works/{work_id}",
        headers=_auth_headers(bob["access_token"]),
    )
    assert bob_shared_work.status_code == 200

    feed_response = client.get("/api/shares/feed", headers=_auth_headers(bob["access_token"]))
    assert feed_response.status_code == 200
    assert any(item["work_id"] == work_id for item in feed_response.json())

    group_response = client.post(
        "/api/groups/",
        headers=_auth_headers(alice["access_token"]),
        json={"name": "Writers", "description": "group"},
    )
    assert group_response.status_code == 201
    invite_code = group_response.json()["invite_code"]
    group_id = group_response.json()["id"]

    join_response = client.post(
        "/api/groups/join",
        headers=_auth_headers(bob["access_token"]),
        json={"invite_code": invite_code},
    )
    assert join_response.status_code == 201

    group_share = client.post(
        "/api/shares/",
        headers=_auth_headers(alice["access_token"]),
        json={"work_id": work_id, "target_type": "group"},
    )
    assert group_share.status_code == 201

    group_works = client.get(
        f"/api/groups/{group_id}/works",
        headers=_auth_headers(bob["access_token"]),
    )

    assert group_works.status_code == 200
    assert any(item["id"] == work_id for item in group_works.json())

    group_feed = client.get("/api/shares/feed", headers=_auth_headers(bob["access_token"]))
    assert group_feed.status_code == 200
    assert any(item["work_id"] == work_id and item["target_type"] == "group" for item in group_feed.json())


def test_friend_request_creates_pending_item_and_notifications(client):
    alice = _register(client, "alice_friend@example.com", "Alice")
    bob = _register(client, "bob_friend@example.com", "Bob")

    request_response = client.post(
        "/api/friends/request",
        headers=_auth_headers(alice["access_token"]),
        json={"addressee_id": bob["user"]["id"]},
    )
    assert request_response.status_code == 201

    pending_response = client.get(
        "/api/friends/pending",
        headers=_auth_headers(bob["access_token"]),
    )
    assert pending_response.status_code == 200
    assert len(pending_response.json()) == 1
    assert pending_response.json()[0]["requester_id"] == alice["user"]["id"]
    assert pending_response.json()[0]["addressee_id"] == bob["user"]["id"]
    assert pending_response.json()[0]["friend_nickname"] == "Alice"

    bob_notifications = client.get(
        "/api/notifications/",
        headers=_auth_headers(bob["access_token"]),
    )
    assert bob_notifications.status_code == 200
    assert bob_notifications.json()[0]["type"] == "friend_request"

    accept_response = client.put(
        f"/api/friends/{request_response.json()['id']}/accept",
        headers=_auth_headers(bob["access_token"]),
    )
    assert accept_response.status_code == 200

    alice_notifications = client.get(
        "/api/notifications/",
        headers=_auth_headers(alice["access_token"]),
    )
    assert alice_notifications.status_code == 200
    assert alice_notifications.json()[0]["type"] == "friend_accepted"


def test_friend_share_targets_selected_friends_and_creates_article_notifications(client):
    alice = _register(client, "alice_share@example.com", "Alice")
    bob = _register(client, "bob_share@example.com", "Bob")
    clara = _register(client, "clara_share@example.com", "Clara")

    for friend in (bob, clara):
        request_response = client.post(
            "/api/friends/request",
            headers=_auth_headers(alice["access_token"]),
            json={"addressee_id": friend["user"]["id"]},
        )
        assert request_response.status_code == 201
        accept_response = client.put(
            f"/api/friends/{request_response.json()['id']}/accept",
            headers=_auth_headers(friend["access_token"]),
        )
        assert accept_response.status_code == 200

    work_response = client.post(
        "/api/works/",
        headers=_auth_headers(alice["access_token"]),
        json={
            "title": "Shared only with Bob",
            "genre": "散文",
            "content": "private share",
            "visibility": "private",
        },
    )
    assert work_response.status_code == 201
    work_id = work_response.json()["id"]

    share_response = client.post(
        "/api/shares/",
        headers=_auth_headers(alice["access_token"]),
        json={
            "work_id": work_id,
            "target_type": "friend",
            "target_ids": [bob["user"]["id"]],
        },
    )
    assert share_response.status_code == 201

    bob_notifications = client.get(
        "/api/notifications/",
        headers=_auth_headers(bob["access_token"]),
    )
    assert bob_notifications.status_code == 200
    assert any(
        item["type"] == "share" and item["related_work_id"] == work_id
        for item in bob_notifications.json()
    )

    clara_notifications = client.get(
        "/api/notifications/",
        headers=_auth_headers(clara["access_token"]),
    )
    assert clara_notifications.status_code == 200
    assert all(item["type"] != "share" for item in clara_notifications.json())

    feed_response = client.get("/api/shares/feed", headers=_auth_headers(bob["access_token"]))
    assert feed_response.status_code == 200
    assert any(item["work_id"] == work_id for item in feed_response.json())

    bob_work = client.get(f"/api/works/{work_id}", headers=_auth_headers(bob["access_token"]))
    clara_work = client.get(f"/api/works/{work_id}", headers=_auth_headers(clara["access_token"]))

    assert bob_work.status_code == 200
    assert clara_work.status_code == 403


def test_unpublish_removes_public_access_but_keeps_direct_shares(client):
    alice = _register(client, "author_unpublish@example.com", "Alice")
    bob = _register(client, "friend_unpublish@example.com", "Bob")
    viewer = _register(client, "viewer_unpublish@example.com", "Viewer")

    request_response = client.post(
        "/api/friends/request",
        headers=_auth_headers(alice["access_token"]),
        json={"addressee_id": bob["user"]["id"]},
    )
    assert request_response.status_code == 201
    accept_response = client.put(
        f"/api/friends/{request_response.json()['id']}/accept",
        headers=_auth_headers(bob["access_token"]),
    )
    assert accept_response.status_code == 200

    work_response = client.post(
        "/api/works/",
        headers=_auth_headers(alice["access_token"]),
        json={
            "title": "Published then shared",
            "genre": "散文",
            "content": "share survives unpublish",
            "visibility": "private",
        },
    )
    assert work_response.status_code == 201
    work_id = work_response.json()["id"]

    publish_response = client.post(
        f"/api/works/{work_id}/publish",
        headers=_auth_headers(alice["access_token"]),
    )
    assert publish_response.status_code == 200

    share_response = client.post(
        "/api/shares/",
        headers=_auth_headers(alice["access_token"]),
        json={
            "work_id": work_id,
            "target_type": "friend",
            "target_ids": [bob["user"]["id"]],
        },
    )
    assert share_response.status_code == 201

    unpublish_response = client.post(
        f"/api/works/{work_id}/unpublish",
        headers=_auth_headers(alice["access_token"]),
    )
    assert unpublish_response.status_code == 200

    bob_work = client.get(f"/api/works/{work_id}", headers=_auth_headers(bob["access_token"]))
    viewer_work = client.get(
        f"/api/works/{work_id}",
        headers=_auth_headers(viewer["access_token"]),
    )

    assert bob_work.status_code == 200
    assert viewer_work.status_code == 403


import time

def test_republish_article_moves_to_top_of_feed(client):
    alice = _register(client, "alice_republish@example.com", "Alice")
    bob = _register(client, "bob_republish@example.com", "Bob")

    # 1. Create and publish an article
    work_resp = client.post(
        "/api/works/",
        headers=_auth_headers(alice["access_token"]),
        json={"title": "Original Title", "content": "Original Content", "genre": "散文"}
    )
    work_id = work_resp.json()["id"]
    client.post(f"/api/works/{work_id}/publish", headers=_auth_headers(alice["access_token"]))

    time.sleep(0.1)  # Ensure different timestamp

    # 2. Create another article and publish it so it's at the top
    new_work_resp = client.post(
        "/api/works/",
        headers=_auth_headers(alice["access_token"]),
        json={"title": "Latest Title", "content": "Latest Content", "genre": "散文"}
    )
    new_work_id = new_work_resp.json()["id"]
    client.post(f"/api/works/{new_work_id}/publish", headers=_auth_headers(alice["access_token"]))

    # Verify original is NOT at the top
    feed = client.get("/api/shares/feed", headers=_auth_headers(bob["access_token"])).json()
    assert feed[0]["work_id"] == new_work_id
    assert feed[1]["work_id"] == work_id

    time.sleep(0.1)  # Ensure different timestamp

    # 3. Unpublish and Re-publish original
    client.post(f"/api/works/{work_id}/unpublish", headers=_auth_headers(alice["access_token"]))
    client.post(f"/api/works/{work_id}/publish", headers=_auth_headers(alice["access_token"]))

    # 4. Verify it's now at the top
    feed = client.get("/api/shares/feed", headers=_auth_headers(bob["access_token"])).json()
    assert feed[0]["work_id"] == work_id
    assert feed[0]["work_title"] == "Original Title"
    assert feed[1]["work_id"] == new_work_id


def test_notification_endpoints_mark_items_read(client, db_session):
    user = _register(client, "notify@example.com", "Notify")
    notification = Notification(
        user_id=user["user"]["id"],
        type="response",
        title="有新的回應",
        body="Someone responded",
    )
    db_session.add(notification)
    db_session.commit()
    db_session.refresh(notification)

    mark_one = client.put(
        f"/api/notifications/{notification.id}/read",
        headers=_auth_headers(user["access_token"]),
    )
    assert mark_one.status_code == 200

    notification.is_read = False
    db_session.add(notification)
    db_session.commit()

    mark_all = client.put(
        "/api/notifications/read-all",
        headers=_auth_headers(user["access_token"]),
    )
    assert mark_all.status_code == 200

    notifications = client.get("/api/notifications/", headers=_auth_headers(user["access_token"]))
    assert notifications.status_code == 200
    assert notifications.json()[0]["is_read"] is True


def test_ai_router_returns_502_when_upstream_fails(client, monkeypatch):
    user = _register(client, "ai@example.com", "AI User")

    async def _raise_failure(
        help_type: str,
        context: str,
        *,
        work_type: str = "literary",
        genre: str | None = None,
    ) -> str:
        raise AIServiceError("ai offline")

    monkeypatch.setattr("app.routers.ai.get_writing_help", _raise_failure)

    response = client.post(
        "/api/ai/help",
        headers=_auth_headers(user["access_token"]),
        json={"help_type": "title", "context": "draft"},
    )

    assert response.status_code == 502
    assert response.json()["detail"] == "ai offline"


def test_ai_generate_draft_requires_inspirations(client):
    user = _register(client, "draft@example.com", "Draft User")

    response = client.post(
        "/api/ai/generate-draft",
        headers=_auth_headers(user["access_token"]),
        json={"work_type": "life", "genre": "生活", "inspirations": []},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "請至少提供一筆靈感"


def test_ai_generate_draft_returns_502_when_upstream_fails(client, monkeypatch):
    user = _register(client, "draft_ai@example.com", "Draft AI User")

    async def _raise_failure(
        inspirations: list[dict],
        *,
        work_type: str = "literary",
        genre: str | None = None,
    ) -> dict:
        raise AIServiceError("draft offline")

    monkeypatch.setattr(
        "app.routers.ai.generate_draft_from_inspirations",
        _raise_failure,
    )

    response = client.post(
        "/api/ai/generate-draft",
        headers=_auth_headers(user["access_token"]),
        json={
            "work_type": "literary",
            "genre": "散文",
            "inspirations": [
                {
                    "event_time": "2026-04-23T10:00:00",
                    "location": "台北",
                    "object_or_event": "下雨",
                    "detail_text": "傍晚在騎樓看雨",
                    "feeling": "安靜",
                    "keywords": "雨, 傍晚",
                }
            ],
        },
    )

    assert response.status_code == 502
    assert response.json()["detail"] == "draft offline"


def test_healthz_reports_service_status(client):
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
