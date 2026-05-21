# Manual Test Checklist

This checklist matches the current supported roles only:
- `Admin`
- `Doctor`
- `Employee`
- `Pharmacist`
- `InsuranceOfficer`

Important rule:
- Do not create a second admin. Keep one admin account only.

## Admin
- Log in with the existing admin account.
- Open user management and confirm only these roles are available when creating users:
  `Doctor`, `Employee`, `Pharmacist`, `InsuranceOfficer`
- Confirm `Admin` is not available in the create screen.
- Open the existing admin record and confirm its role cannot be changed.
- Create one doctor, one employee, one pharmacist, and one insurance officer.
- Disable and re-enable a non-admin user.
- Open Swagger at `/api/docs/swagger/` and confirm the endpoints load.

## Doctor
- Log in as doctor.
- Search for an employee.
- Create a prescription with medication items.
- Create a prescription that requires insurance.
- Create an insurance request for that prescription.
- Confirm the insurance request is immediately `Approved`.
- Confirm the prescription status becomes `Approved`.

## Employee
- Log in as employee.
- Confirm only the employee's own prescriptions are visible.
- Open prescription details.
- Open QR code for a prescription.
- Review dependents.
- Confirm notifications open the correct prescription.

## Pharmacist
- Log in as pharmacist.
- Search for an approved prescription.
- Complete a dispense.
- Confirm the prescription status becomes `Dispensed`.
- Try to dispense a rejected prescription and confirm it is blocked.

## Insurance Officer
- Log in as insurance officer.
- Open the list of insurance requests.
- Confirm requests can be viewed.
- Confirm the review screen is read-only and shows the request as already approved.
- Confirm there are no working approve/reject/update actions in the normal flow.

## Regression
- Confirm old role dashboards for `Laboratory`, `ImagingCenter`, and `MedicalCenter` are no longer reachable from normal navigation.
- Confirm demo logins exist only for admin, doctor, employee, pharmacist, and insurance officer.
