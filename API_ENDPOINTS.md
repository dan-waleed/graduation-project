# HealthBridge API Guide

Base API path: `/api/`

Swagger and schema:
- Swagger UI: `/api/docs/swagger/`
- ReDoc: `/api/docs/redoc/`
- OpenAPI schema: `/api/schema/`

Authentication:
- `POST /api/auth/login/`
- `POST /api/auth/logout/`
- `GET /api/auth/me/`

Dashboard:
- `GET /api/dashboard/summary/`

Core resources:
- `GET|POST /api/users/`
- `GET|PATCH|DELETE /api/users/{id}/`
- `GET|POST /api/employees/`
- `GET|PATCH|DELETE /api/employees/{id}/`
- `GET|POST /api/doctors/`
- `GET|PATCH|DELETE /api/doctors/{id}/`
- `GET|POST /api/insurance-officers/`
- `GET|PATCH|DELETE /api/insurance-officers/{id}/`
- `GET|POST /api/providers/`
- `GET|PATCH|DELETE /api/providers/{id}/`
- `GET|POST /api/pharmacies/`
- `GET|PATCH|DELETE /api/pharmacies/{id}/`
- `GET|POST /api/pharmacists/`
- `GET|PATCH|DELETE /api/pharmacists/{id}/`
- `GET|POST /api/medical-services/`
- `GET|PATCH|DELETE /api/medical-services/{id}/`
- `GET|POST /api/provider-service-prices/`
- `GET|PATCH|DELETE /api/provider-service-prices/{id}/`
- `GET|POST /api/dependents/`
- `GET|PATCH|DELETE /api/dependents/{id}/`
- `GET|POST /api/medications/`
- `GET|PATCH|DELETE /api/medications/{id}/`
- `GET|POST /api/prescriptions/`
- `GET|PATCH|DELETE /api/prescriptions/{id}/`
- `GET /api/prescriptions/{id}/qr-code/`
- `GET|POST /api/insurance/`
- `GET|PATCH|DELETE /api/insurance/{id}/`
- `GET|POST /api/dispenses/`
- `GET|PATCH|DELETE /api/dispenses/{id}/`
- `GET|POST /api/notifications/`
- `GET|PATCH|DELETE /api/notifications/{id}/`
- `GET|POST /api/audit-logs/`
- `GET|PATCH|DELETE /api/audit-logs/{id}/`

Current supported roles:
- `Admin`
- `Doctor`
- `Employee`
- `Pharmacist`
- `InsuranceOfficer`

Notes:
- Creating a second `Admin` user is blocked by the API.
- Insurance requests are auto-approved when created, and insurance staff now review requests instead of changing decisions.
