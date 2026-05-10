# HealthBridge Employee-Centered Refactor

## Overview

HealthBridge is now modeled around the insured `University Employee` as the primary covered actor instead of `Patient`.

- Main insured actor: `University Employee`
- Covered family members: `Beneficiary / Dependent`
- Medical order owner field: `employeeId`
- Optional covered family member field: `beneficiaryId`

In Arabic UI and documentation:

- `الموظف الجامعي` replaces `المريض`
- `اسم الموظف` replaces `اسم المريض`
- `اسم المستفيد` is shown when the service is requested for a covered family member
- When needed, both `اسم الموظف صاحب التأمين` and `اسم المستفيد` are displayed

## Main Actors

The system supports the following actors:

1. `Admin`
2. `Doctor`
3. `University Employee`
4. `Insurance Officer`
5. `Pharmacist`
6. `Laboratory`
7. `Medical Imaging Center`
8. `Medical Center`

## Updated Domain Model

### Core insured entities

- `Employee`
  - linked to `User`
  - holds insurance identity and university employee information
- `Dependent`
  - linked to `Employee`
  - represents covered beneficiaries such as wife, husband, son, and daughter

### Provider entities

- `Provider`
  - `providerName`
  - `providerType`
  - `city`
  - `address`
  - `phone`
  - `latitude`
  - `longitude`
  - `googleMapsUrl`
  - `workingHours`
  - `contractStatus`

- `Doctor`
  - doctor profile
  - specialty
  - clinic address
  - consultation price
  - provider location
  - contract status

- `Pharmacy`
- `Laboratory`
- `MedicalImagingCenter`
- `MedicalCenter`

### Service entities

- `MedicalService`
  - `serviceName`
  - `serviceType`
  - `defaultPrice`
  - `requiresInsuranceApproval`
  - `coveragePercentage`
  - `employeeShare`
  - `description`

- `ProviderServicePrice`
  - `providerId`
  - `serviceId`
  - `price`
  - `coveragePercentage`
  - `coveredAmountLimit`
  - `employeeShare`
  - `isAvailable`
  - `requiresPreApproval`

### Medical order entity

The current implementation extends the existing prescription workflow into a broader `medical order` model.

- owner: `employeeId`
- optional beneficiary: `beneficiaryId`
- service provider: `providerId`
- medical service: `serviceId`
- order type: `serviceType`
- pricing and coverage fields:
  - `finalPrice`
  - `coveragePercentage`
  - `coveredAmount`
  - `employeeShare`
- execution fields:
  - `performedAt`
  - `providerNotes`
  - `reportAttachmentUrl`

## Supported Medical Order Types

1. Medication order
2. Lab test order
3. Imaging order
4. Medical procedure order
5. Consultation order

## Order Status Lifecycle

The unified status set is:

- `Draft`
- `Sent`
- `PendingEmployeeSelection`
- `PendingInsuranceApproval`
- `Approved`
- `Rejected`
- `Dispensed`
- `Performed`
- `Cancelled`
- `Expired`

## Main Use Cases

### Employee mobile app

- View prescriptions and medical orders
- View QR code
- Choose provider:
  - pharmacy
  - lab
  - imaging center
  - doctor
  - medical center
- See provider:
  - address
  - phone
  - map link
  - price
  - insurance coverage
  - expected employee payment
- Track order status
- Receive notifications

### Doctor app

- Search employee or beneficiary
- Create medication, lab, imaging, procedure, or consultation order
- Add diagnosis and instructions
- Send order to employee
- Send order to insurance when pre-approval is needed
- Follow status updates

### Laboratory

- Login
- View lab requests
- Scan QR code
- Verify insurance approval
- Mark request as performed
- Enter final price
- Upload result or notes

### Medical Imaging Center

- Login
- View assigned imaging requests
- Scan QR code
- Verify employee or beneficiary and insurance status
- Accept or reject
- Mark performed
- Enter final price
- Upload imaging report
- Add notes

### Insurance Office

- Review coverage requests
- View:
  - employee
  - beneficiary
  - doctor
  - provider
  - service
  - price
  - coverage percentage
  - covered amount
  - employee share
- Approve, reject, or request modification
- Generate reports by employee, provider, service type, and total cost

### Admin dashboard

- Manage users and roles
- Manage doctors, pharmacies, labs, imaging centers, and medical centers
- Manage services
- Manage provider-specific pricing and coverage rules
- Activate and deactivate contracted providers
- View statistics and audit logs

## Functional Requirements

1. The system shall authenticate all actors securely.
2. The system shall support employee and beneficiary coverage.
3. The system shall support multi-type medical orders, not medication only.
4. The system shall support QR code verification for orders.
5. The system shall support insurance approval workflows.
6. The system shall support provider selection by the employee.
7. The system shall support provider-specific prices and coverage rules.
8. The system shall support notifications for all major status changes.
9. The system shall preserve audit logs for sensitive actions.

## Non-Functional Requirements

1. Security and access control by role
2. Reliable audit logging
3. Mobile-friendly interfaces
4. Clear Arabic terminology for Palestinian university insurance context
5. Extensible backend schema for additional provider types and services
6. Consistent QR-based verification workflow across providers

## Context Diagram Description

HealthBridge acts as the central platform between:

- University employee
- Beneficiary
- Doctor
- Pharmacy
- Laboratory
- Imaging center
- Medical center
- Insurance office
- Admin

The platform manages authentication, medical orders, insurance approvals, provider selection, notifications, QR verification, execution updates, and reporting.

## Class Diagram Description

Primary relationships:

- `User 1..1 -> Employee`
- `Employee 1..* -> Dependent`
- `Doctor 1..* -> Prescription`
- `Employee 1..* -> Prescription`
- `Dependent 0..* -> Prescription`
- `Provider 1..* -> ProviderServicePrice`
- `MedicalService 1..* -> ProviderServicePrice`
- `Prescription 0..1 -> InsuranceRequest`
- `Prescription 0..* -> Dispense`

## Implementation Notes

- Existing prescription, QR, notification, insurance approval, and statistics flows were preserved and extended.
- Legacy patient-oriented API naming can be temporarily kept as compatibility aliases during migration, while the primary business naming is now employee-oriented.
