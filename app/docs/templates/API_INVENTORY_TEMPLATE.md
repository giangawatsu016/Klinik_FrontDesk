# API Inventory

This file lists all available services and their base URLs. For detailed Request/Response schemas, see specific `docs/features/[feature-name]/api.md`.

## Services

| Service | Base URL (Dev) | Description |
| :--- | :--- | :--- |
| **Auth Service** | `http://localhost:8001/api/v1` | Login, Register, Profile |
| **Doc Service** | `http://localhost:8002/api/v1` | Upload, OCR, Parsing |
| **Chat Service** | `http://localhost:8003/api/v1` | LLM Interaction, RAG |

## Endpoint Summary

### Auth
- `POST /auth/login`
- `POST /auth/refresh`

### Documents
- `POST /documents/upload`
- `GET /documents/{id}`

### Chat
- `POST /chat/completions` (Streaming)
